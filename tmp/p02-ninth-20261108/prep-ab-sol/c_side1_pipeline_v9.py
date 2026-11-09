"""Fail-closed synthetic semantics pipeline for one C detection fixture."""
import hashlib
import json
from pathlib import Path

from c_side1_bound_v4 import fields, integer
from c_side1_chain_v6 import valid_sha
from c_side1_semantics_v8 import (bind_capture, bind_wrong_control, decode, inspect_live,
    inspect_packet, mapping, typed, value_at, verify_fixture_identity, verify_source_stability)
from legacy_autoresolve_oracle import need, unique

PHASES=("first","wrong-position-control","repaired")

def approved_context(pin_path, approved_pin_sha256, seed, case):
    valid_sha(approved_pin_sha256,"independently approved fixture pin SHA")
    raw=Path(pin_path).read_bytes()
    need(hashlib.sha256(raw).hexdigest()==approved_pin_sha256,"fixture pin not approved")
    pin=json.loads(raw,object_pairs_hook=unique)
    fields(pin,("seed","case","context_hex"),"fixture pin")
    integer(seed,"independent fixture seed")
    integer(pin["seed"],"pinned seed",seed)
    need(type(case) is str and case in ("estimated","lost") and pin["case"]==case,"pinned case")
    context=mapping(decode(pin["context_hex"]))
    integer(typed(context["seed"],2,"context seed"),"typed context seed",seed)
    roster=typed(context["roster"],28,"independent fixture roster")
    # _detection selects a.st.fleets[1].id. Derive ID from the pinned roster.
    need(len(roster)>=2,"pinned fixture lacks original selection slot")
    selected=mapping(roster[1],("id","side","faction"))
    need(typed(selected["side"],2,"selected side")==1,"pinned selected fleet is not opposing")
    return pin["context_hex"],typed(selected["id"],2,"selected contact ID")

def external(projection):
    return {k:v for k,v in projection.items() if k!="contacts"}

def check_case(capture, pin_path, approved_pin_sha256, *, seed, case):
    context_hex,contact_id=approved_context(pin_path,approved_pin_sha256,seed,case)
    fields(capture,("reported_contact_id","source_first","source_repaired","phases"),"case capture")
    integer(capture["reported_contact_id"],"fixture-selected contact ID",contact_id)
    fields(capture["phases"],PHASES,"restore phases")
    first=capture["phases"]["first"]
    wrong=capture["phases"]["wrong-position-control"]
    repaired=capture["phases"]["repaired"]
    for name in PHASES:
        phase=capture["phases"][name]
        fields(phase,("packet_hex","target_before","target_after","result","records"),name)
        fields(phase["result"],("ok",),"actual restore result")
        need(phase["result"]["ok"] is True,"restore did not return true")
        verify_fixture_identity(phase["packet_hex"],context_hex)
    original=first["packet_hex"]
    _,context,books=inspect_packet(original)
    selected=value_at(books[0],contact_id,2)
    need(typed(value_at(selected,"state"),4,"fixture contact state")==case,"fixture contact state drift")
    source,_=bind_capture(original,capture["source_first"],[])
    verify_source_stability(original,capture["source_first"],repaired["packet_hex"],capture["source_repaired"])
    previous=None
    for name in PHASES:
        phase=capture["phases"][name]
        before,books,_=inspect_live(phase["target_before"],context,[])
        after,_=bind_capture(phase["packet_hex"],phase["target_after"],phase["records"])
        need(external(before)==external(after)==external(source),f"{name}: target external-state mutation")
        if previous is None:
            need(not books[0][2],"first target was not independently cleared")
        else:
            need(previous==before,f"{name}: target state changed between restore phases")
        previous=after
    bind_wrong_control(original,wrong["packet_hex"],capture["source_first"],wrong["target_after"],contact_id)

