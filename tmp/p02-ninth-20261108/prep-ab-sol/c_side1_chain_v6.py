"""Review-only validation for frozen source receipts and original C event order."""
import hashlib
import json
import re
from pathlib import Path

from c_side1_bound_v4 import HORIZONS, LANES, fields, integer
from c_side1_bound_v5 import verified_sources
from legacy_autoresolve_oracle import need, unique
from qc_capture_streams import SERVICE_SEEDS

def digest(data):
    return hashlib.sha256(data).hexdigest()

def valid_sha(value, label):
    need(type(value) is str and re.fullmatch(r"[0-9a-f]{64}",value) is not None,label)

def pinned_inputs(root, manifest, approved_sha256):
    valid_sha(approved_sha256,"independently approved manifest SHA")
    path=Path(manifest)
    need(digest(path.read_bytes())==approved_sha256,"unapproved manifest bytes")
    result=verified_sources(root,path)
    need(digest(path.read_bytes())==approved_sha256,"manifest drift during source verification")
    return result

def confirm_envelope(before, after, approved_sha256, approved_closure_digest):
    for receipt in (before,after):
        fields(receipt,("stage","manifest_sha256","closure_digest"),"launcher source receipt")
        valid_sha(receipt["manifest_sha256"],"source receipt manifest SHA")
        valid_sha(receipt["closure_digest"],"source receipt closure digest")
    need(before["stage"]=="before-spawn" and after["stage"]=="after-join","launcher source receipt order")
    need(before["manifest_sha256"]==after["manifest_sha256"]==approved_sha256,"launcher manifest pin")
    valid_sha(approved_closure_digest,"approved closure digest")
    need(before["closure_digest"]==after["closure_digest"]==approved_closure_digest,"before/after source drift")

def plan(seed, case):
    final=HORIZONS[case]
    a,b="native-source","restore-target"
    yield "initial",a,"fixture",0
    yield "initial",b,"fixture",0
    for role in (a,b):
        for tick in (1,11):
            yield "eval",role,"before-relocate",tick
    for role in (a,b):
        yield "relocate",role,"fixture",20
    for role in (a,b):
        for tick in range(21,final+1,10):
            yield "eval",role,"after-relocate",tick
    for phase in (case,case+" repaired"):
        yield "capture",a,phase,final
        yield "restore-request",b,phase,final
        yield "restore-success",b,phase,final
        yield "capture",b,phase,final
        if phase==case:
            yield "restore-request",b,"wrong-position-control",final
            yield "restore-success",b,"wrong-position-control",final
    # Eval after this marker is outside the certificate horizon, not a skipped pre-restore event.
    yield "scope-end",a,"before-suffix",final
    yield "scope-end",b,"before-suffix",final

def check_events(events):
    need(type(events) is list,"raw ordered event array")
    index=0
    identities={}
    claimed=set()
    last_stream_ordinal={}
    for lane in LANES:
        for seed in SERVICE_SEEDS:
            for case in HORIZONS:
                for event,actor,phase,tick in plan(seed,case):
                    need(index<len(events),"missing raw ordered event")
                    row=events[index]
                    fields(row,("ordinal","stream_ordinal","lane","seed","case","event","actor","phase","tick","sim_id","raw_line_sha256"),"raw receipt")
                    integer(row["ordinal"],"canonical merged ordinal",index)
                    local=last_stream_ordinal.get(lane,-1)+1
                    integer(row["stream_ordinal"],"original stream ordinal",local)
                    last_stream_ordinal[lane]=local
                    integer(row["seed"],"event seed",seed)
                    integer(row["tick"],"event tick",tick)
                    need((row["lane"],row["case"],row["event"],row["actor"],row["phase"])==(lane,case,event,actor,phase),
                         f"receipt {index}: raw causal order")
                    sim_id=integer(row["sim_id"],"sim instance ID")
                    need(sim_id>0,"sim instance ID range")
                    key=(lane,seed,case,actor)
                    if event=="initial":
                        need((lane,sim_id) not in claimed,"simulation identity reused")
                        claimed.add((lane,sim_id))
                        identities[key]=sim_id
                    need(identities.get(key)==sim_id,"cross-instance receipt")
                    valid_sha(row["raw_line_sha256"],"raw receipt line SHA")
                    index+=1
    need(index==len(events),"unexpected or duplicate raw events")
    return identities


def read_original_streams(lane_files, approved_output_hashes):
    """Read exact source-file order and preserve raw line evidence."""
    need(tuple(lane_files)==tuple(approved_output_hashes)==LANES,"ordered launcher stream lanes")
    receipts=[]
    for lane in LANES:
        valid_sha(approved_output_hashes[lane],"launcher raw stream SHA")
        data=Path(lane_files[lane]).read_bytes()
        need(digest(data)==approved_output_hashes[lane],"raw stream drift")
        need(data.endswith(b"\n"),"raw stream not flushed through final line")
        for line in data.splitlines(keepends=True):
            row=json.loads(line,object_pairs_hook=unique)
            need(type(row) is dict and row.get("lane")==lane,"raw lane identity")
            need("ordinal" not in row and "raw_line_sha256" not in row,"producer cannot stamp merged evidence")
            receipts.append(dict(row,ordinal=len(receipts),raw_line_sha256=digest(line)))
    return receipts
