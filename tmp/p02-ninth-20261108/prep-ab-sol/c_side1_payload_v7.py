"""Synthetic-only payload binding for C evidence. Never launches a process."""
import json
from pathlib import Path

from c_side1_bound_v4 import case_key, certify, fields, integer
from c_side1_chain_v6 import check_events, digest, valid_sha
from legacy_autoresolve_oracle import need, same, unique

IDENTITY=("run_id","process_pid","process_created","producer_sha256")
BASE=("stream_ordinal","lane","seed","case","event","actor","phase","tick","sim_id")
EXTRA=("identity","mono_ns","payload")

def exact_identity(value, expected):
    fields(value,IDENTITY,"launcher process identity")
    need(type(value["run_id"]) is str and bool(value["run_id"]),"run identity")
    need(integer(value["process_pid"],"owned PID")>0,"owned PID range")
    need(integer(value["process_created"],"process creation")>0,"process creation range")
    valid_sha(value["producer_sha256"],"approved producer SHA")
    same(value,expected)

def load_streams(lane_paths, owned):
    events=[]
    need(tuple(lane_paths)==tuple(owned)==("before","after"),"ordered launcher lanes")
    for lane,path in lane_paths.items():
        receipt=owned[lane]
        fields(receipt,("identity","raw_sha256"),"launcher raw receipt")
        data=Path(path).read_bytes()
        need(data.endswith(b"\n") and digest(data)==receipt["raw_sha256"],"original stream flush/hash")
        for line in data.splitlines(keepends=True):
            row=json.loads(line,object_pairs_hook=unique)
            fields(row,(*BASE,*EXTRA),"raw payload receipt")
            need(row["lane"]==lane,"source lane")
            exact_identity(row["identity"],receipt["identity"])
            events.append(dict(row,ordinal=len(events),raw_line_sha256=digest(line)))
    return events

def unique_map(records,key_of,where):
    mapped={}
    for r in records:
        key=key_of(r)
        need(key not in mapped,f"{where}: duplicate key")
        mapped[key]=r
    return mapped

def verify_bytes(payload,label):
    hex_bytes=payload[f"{label}_hex"]
    need(type(hex_bytes) is str and bool(hex_bytes) and len(hex_bytes)%2==0
         and all(c in "0123456789abcdef" for c in hex_bytes),f"{label} raw byte encoding")
    need(digest(bytes.fromhex(hex_bytes))==payload[f"{label}_sha256"],f"{label} bytes/hash disagreement")

def check(events,witness,approved_fixture_digest,owned):
    certify(witness,approved_fixture_digest)
    geometry=witness["evaluations"]
    initial=witness["initial"]
    geometry_index=unique_map(geometry,lambda r:(*case_key(r),integer(r["tick"],"witness tick")),"geometry")
    initial_index=unique_map(initial,case_key,"initial")
    seen_eval=set()
    seen_initial=set()
    phase_state={}
    case_packets={}
    source_states={}
    last_mono={}
    timeline=[{k:v for k,v in row.items() if k not in EXTRA} for row in events]
    check_events(timeline)
    need(tuple(owned)==("before","after"),"ordered launcher lanes")
    need(owned["before"]["identity"]["run_id"]!=owned["after"]["identity"]["run_id"],"distinct lane runs")
    for r in events:
        lane=r["lane"]
        exact_identity(r["identity"],owned[lane]["identity"])
        moment=integer(r["mono_ns"],"monotonic timestamp")
        need(moment>last_mono.get(lane,0),"monotonic receipt regression")
        last_mono[lane]=moment
        p=r["payload"]
        group=(lane,r["seed"],r["case"])
        who=(lane,r["actor"],r["seed"],r["case"])
        phase=(*group,r["phase"])
        event=r["event"]
        if event=="eval":
            fields(p,("authoritative_tick","geometry"),"pre-eval payload")
            integer(p["authoritative_tick"],"authoritative tick",r["tick"])
            key=(*who,r["tick"])
            need(key in geometry_index,"missing geometric witness")
            same(p["geometry"],geometry_index[key])
            seen_eval.add(key)
        elif event=="initial":
            fields(p,("initial",),"initial payload")
            need(who in initial_index,"missing initial witness")
            same(p["initial"],initial_index[who])
            seen_initial.add(who)
        elif event=="relocate":
            fields(p,("target_fleet_id","position"),"fixture relocation payload")
            integer(p["target_fleet_id"],"relocated fleet ID",2)
            same(p["position"],[1500,450])
        elif event=="capture":
            fields(p,("packet_sha256","packet_hex","sim_state_sha256","sim_state_hex","side","records"),"capture payload")
            valid_sha(p["packet_sha256"],"capture packet")
            valid_sha(p["sim_state_sha256"],"capture sim state")
            verify_bytes(p,"packet")
            verify_bytes(p,"sim_state")
            integer(p["side"],"capture side",1)
            same(p["records"],[])
            if r["actor"]=="native-source":
                prior=source_states.setdefault(group,p["sim_state_sha256"])
                need(p["sim_state_sha256"]==prior,"source changed between restore phases")
                phase_state[phase]={"packet":p["packet_sha256"]}
                case_packets.setdefault(group,p["packet_sha256"])
            else:
                expected=phase_state.get(phase,{})
                need(p["packet_sha256"]==expected.get("packet"),"captured wrong packet")
                need(p["sim_state_sha256"]==expected.get("result_state"),"target state drift after restore")
        elif event=="restore-request":
            fields(p,("packet_sha256","packet_hex","request_id"),"request payload")
            valid_sha(p["packet_sha256"],"requested packet")
            verify_bytes(p,"packet")
            need(type(p["request_id"]) is str and bool(p["request_id"]),"request identity")
            if r["phase"]=="wrong-position-control":
                need(p["packet_sha256"]!=case_packets[group],"wrong-position control packet unchanged")
                phase_state[phase]={"packet":p["packet_sha256"]}
            expected=phase_state[phase]
            need(p["packet_sha256"]==expected["packet"],"request packet replacement")
            need(p["request_id"]==f"{lane}/{r['seed']}/{r['case']}/{r['phase']}","request phase identity")
            expected["request_id"]=p["request_id"]
        elif event=="restore-success":
            fields(p,("packet_sha256","request_id","result","sim_state_sha256","sim_state_hex"),"actual result payload")
            expected=phase_state[phase]
            need(p["packet_sha256"]==expected["packet"] and p["request_id"]==expected["request_id"],"result not bound to request")
            fields(p["result"],("ok",),"restore result")
            need(p["result"]["ok"] is True,"restore actual result false or mistyped")
            valid_sha(p["sim_state_sha256"],"restored sim state")
            verify_bytes(p,"sim_state")
            expected["result_state"]=p["sim_state_sha256"]
        else:
            fields(p,(),"scope-end payload")
    need(seen_eval==geometry_index.keys() and seen_initial==initial_index.keys(),"extraneous witness rows")

