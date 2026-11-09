"""Join exact C v4 raw capture rows with the independent v9 semantic gate."""
import hashlib
import re

from c_raw_overlay_mapping_v2 import evidence
from c_raw_overlay_mapping import phase_ids
from c_side1_bound_v4 import HORIZONS
from c_side1_semantics_v8 import decode,mapping,typed
from c_side1_pipeline_v9 import check_case
from legacy_autoresolve_oracle import need
from qc_capture_streams import SERVICE_SEEDS

RESTORE_EVENTS=("source-before","restore-request","restore-result","source-after")
PHASE_INDEX={0:"first",2:"wrong-position-control",3:"repaired"}

def packet_bytes(raw_hex,expected):
    need(type(raw_hex) is str and 8<=len(raw_hex)<=2_000_000 and len(raw_hex)%2==0
         and re.fullmatch(r"[0-9a-f]+",raw_hex) is not None,"packet raw hex")
    observed=hashlib.sha256(bytes.fromhex(raw_hex)).hexdigest()
    need(type(expected) is str and observed==expected,"packet raw byte SHA mismatch")
    return raw_hex

def live_bytes(value,row):
    raw=typed(value,4,"original live hex")
    snapshot=mapping(decode(raw))
    receipt=mapping(snapshot["receipt_metadata"],("ordinal","mono_ns"))
    need(typed(receipt["ordinal"],2,"live receipt ordinal")==row["stream_ordinal"],"cross-receipt live state")
    moment=typed(receipt["mono_ns"],2,"live receipt ns")
    need(0<moment<=row["mono_ns"] and moment%1000==0,"live time range")
    return raw

def collect_case(rows,seed,case):
    selected=[r for r in rows if r["seed"]==seed and r["case"]==case and r["event"] in RESTORE_EVENTS]
    need(len(selected)==20,"five actual restore call receipts")
    merged={"phases":{}}
    for i,phase in enumerate(phase_ids(case)):
        source_before,request,result,source_after=selected[4*i:4*i+4]
        events=(source_before,request,result,source_after)
        need(tuple(x["event"] for x in events)==RESTORE_EVENTS and all(x["phase"]==phase for x in events),"restore event order")
        payloads=[mapping(decode(x["payload_hex"])) for x in events]
        a,b,c,z=payloads
        key=typed(a["request_id"],4,"request id")
        need(key==f"{request['sim_id']}/{phase}" and all(typed(p["request_id"],4,"request id")==key for p in payloads),
             "wrong restore receipt request id")
        before_packet=packet_bytes(typed(b["packet_raw"],4,"raw packet"),typed(b["packet_raw_sha256"],4,"raw packet SHA"))
        after_packet=packet_bytes(typed(c["packet_raw"],4,"raw packet"),typed(c["packet_raw_sha256"],4,"raw packet SHA"))
        need(before_packet==after_packet and decode(before_packet)==b["packet"]==c["packet"],"restore packet changed or raw mismatch")
        need(a["state"]==z["state"],"restore changed source _all")
        need(mapping(b["state"])["outside"]==mapping(c["state"])["outside"],"restore changed target outside")
        if phase.endswith("/repeat"):
            need(b["state"]==c["state"],"repeat altered target _all")
        need(mapping(c["result"],("ok",))["ok"]==(1,(),True),"actual restore not successful")
        live=[live_bytes(p["live_raw"],row) for p,row in zip(payloads,events)]
        if i in PHASE_INDEX:
            target=mapping(decode(live[2]))
            books=typed(target["contacts"],28,"live contact books")
            need(len(books)==2,"two live contact books")
            records=list(typed(books[1],27,"decoded side 1 records"))
            merged["phases"][PHASE_INDEX[i]]={"packet_hex":before_packet,"target_before":live[1],
                "target_after":live[2],"result":{"ok":True},"records":records}
        if i in (0,3):
            merged["source_first" if i==0 else "source_repaired"]=live[0]
    return merged

def verify_lane(raw_path,receipt,approved_producer_sha,pins):
    """Each pin and its SHA comes from outside the candidate run."""
    cases=[(seed,case) for seed in SERVICE_SEEDS for case in HORIZONS]
    need(tuple(pins)==tuple(cases),"complete independent fixture pins")
    rows=evidence(raw_path,receipt,approved_producer_sha)
    for seed,case in cases:
        pin=pins[seed,case]
        capture=collect_case(rows,seed,case)
        source=mapping(decode(capture["source_first"]))
        roster=typed(source["roster"],28,"original source roster")
        need(len(roster)>=2,"source selected roster slot absent")
        capture["reported_contact_id"]=typed(mapping(roster[1])["id"],2,"source selected contact ID")
        check_case(capture,pin["path"],pin["approved_sha256"],seed=seed,case=case)
    return len(cases)*5
