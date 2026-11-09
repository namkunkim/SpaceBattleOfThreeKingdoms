"""Synthetic-only payload binding mutations, no engine launch."""
from copy import deepcopy
from pathlib import Path
import json
from tempfile import TemporaryDirectory

from c_side1_bound_v4 import HORIZONS, LANES
from c_side1_chain_v6 import digest, plan
from c_side1_payload_v7 import check,load_streams
from qc_capture_streams import SERVICE_SEEDS

SHA="f"*64
witness=dict(fixture_sha256=SHA, config=dict(estimated_threshold=15,distance_units_per_point=25,
    period_ticks=10,sensor_shp_02=1,intellect_bonus=12,ship_points_div=1),initial=[],evaluations=[])
def blob(label,raw):
    data=raw.encode()
    return {label+"_hex":data.hex(),label+"_sha256":digest(data)}

def rows(lane,identity):
    raw=[]
    for index,(seed,case) in enumerate((s,c) for s in SERVICE_SEEDS for c in HORIZONS):
        for event,actor,phase,tick in plan(seed,case):
            row=dict(stream_ordinal=len(raw),lane=lane,seed=seed,case=case,event=event,actor=actor,phase=phase,
                     tick=tick,sim_id=2*index+1+(actor=="restore-target"),identity=identity,mono_ns=len(raw)+1)
            common=dict(lane=lane,instance=actor,seed=seed,case=case,tick=tick)
            packet=blob("packet",phase)
            state=blob("sim_state","source" if actor=="native-source" else phase)
            request=f"{lane}/{seed}/{case}/{phase}"
            if event=="eval":
                geometry=dict(common,evaluating_side=1,ally=dict(id=1,side=0,position=[400,450],form_offsets=[[0,0]],alive=True),
                              foe=dict(id=2,side=1,position=[500,450],form_offsets=[[0,0]],alive=True),
                              equipment="",intellect=70,formation="FRM-01",live_shp_02=4,other_live_ships=0,
                              view_radius=0,terrain_sensor_bp=0,formation_sensor_bp=0,chain=False,skills=False,
                              ew_lower_bound=0,conceal_lower_bound=0)
                witness["evaluations"].append(geometry)
                payload=dict(authoritative_tick=tick,geometry=geometry)
            elif event=="initial":
                initial=dict(common,side1_contacts=[])
                witness["initial"].append(initial)
                payload=dict(initial=initial)
            elif event=="capture":
                payload=dict(**packet,**state,side=1,records=[])
            elif event=="restore-request":
                payload=dict(**packet,request_id=request)
            elif event=="restore-success":
                payload=dict(packet_sha256=packet["packet_sha256"],request_id=request,result=dict(ok=True),**state)
            elif event=="relocate":
                payload=dict(target_fleet_id=2,position=[1500,450])
            else:
                payload={}
            raw.append(dict(row,payload=payload))
    return raw

def order(r):
    return LANES.index(r["lane"]),("native-source","restore-target").index(r["instance"]),r["seed"],tuple(HORIZONS).index(r["case"]),r["tick"]

def reject(name,callback):
    try:callback()
    except ValueError as e:print("rejected",name,str(e))
    else:raise AssertionError(name)

with TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
    files={}
    owned={}
    for index,lane in enumerate(LANES):
        identity=dict(run_id=f"run-{lane}",process_pid=400+index,process_created=500+index,producer_sha256="a"*64)
        raw="".join(json.dumps(r)+"\n" for r in rows(lane,identity)).encode()
        path=Path(folder)/(lane+".jsonl")
        path.write_bytes(raw)
        files[lane]=path
        owned[lane]=dict(identity=identity,raw_sha256=digest(raw))
    events=load_streams(files,owned)
    witness["initial"].sort(key=order)
    witness["evaluations"].sort(key=order)
    check(events,witness,SHA,owned)
    print("accepted synthetic ordered 9600 payload events and geometry")
    def mutate(name,predicate,edit):
        i=next(i for i,r in enumerate(events) if predicate(r))
        bad=deepcopy(events[i])
        edit(bad)
        reject(name,lambda:check([*events[:i],bad,*events[i+1:]],witness,SHA,owned))
    success=lambda r:r["event"]=="restore-success"
    restore=lambda r:r["event"]=="restore-request"
    evaluate=lambda r:r["event"]=="eval"
    mutate("same-tick fake success with false actual result",success,lambda r:r["payload"].update(result={"ok":False}))
    mutate("same-tick success with wrong request identity",success,lambda r:r["payload"].update(request_id="fake"))
    mutate("packet replaced with matching new hash",restore,lambda r:r["payload"].update(blob("packet","substitute")))
    mutate("packet bytes altered without hash",restore,lambda r:r["payload"].update(packet_hex="aa"))
    mutate("geometry event contradicts independent witness",evaluate,lambda r:r["payload"]["geometry"]["ally"].update(position=[401,450]))
    mutate("authoritative tick does not match",evaluate,lambda r:r["payload"].update(authoritative_tick=2))
    mutate("monotonic timestamp reused",evaluate,lambda r:r.update(mono_ns=2))
    mutate("process restarted under reused sim ID",evaluate,lambda r:r["identity"].update(process_created=999))
    mutate("duplicate sim ID across instances",lambda r:r["event"]=="initial" and r["actor"]=="restore-target",lambda r:r.update(sim_id=1))
    mutate("post-result target state mutated",lambda r:r["event"]=="capture" and r["actor"]=="restore-target",
           lambda r:r["payload"].update(blob("sim_state","changed")))
    print("synthetic only, no actual producer or engine")
