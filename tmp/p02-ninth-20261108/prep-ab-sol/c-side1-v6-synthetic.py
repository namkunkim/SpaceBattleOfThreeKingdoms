"""Synthetic causal-order and frozen-manifest checks. Does not run Godot."""
import hashlib
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from c_side1_chain_v6 import (check_events, confirm_envelope, pinned_inputs, plan, read_original_streams)
from c_side1_bound_v4 import HORIZONS, LANES
from qc_capture_streams import SERVICE_SEEDS

def sha(value):
    return hashlib.sha256(value).hexdigest()

def reject(name,operation):
    try:operation()
    except ValueError as e:print("rejected",name,str(e))
    else:raise AssertionError(name)

with TemporaryDirectory(dir=Path(__file__).resolve().parent) as folder:
    root=Path(folder)
    files={}
    hashes={}
    for lane in LANES:
        rows=[]
        for index,(seed,case) in enumerate((s,c) for s in SERVICE_SEEDS for c in HORIZONS):
            for event,actor,phase,tick in plan(seed,case):
                rows.append(dict(stream_ordinal=len(rows),lane=lane,seed=seed,case=case,event=event,actor=actor,phase=phase,tick=tick,
                                 sim_id=2*index+1+(actor=="restore-target")))
        payload="".join(json.dumps(r)+"\n" for r in rows).encode()
        files[lane]=root/(lane+".jsonl")
        files[lane].write_bytes(payload)
        hashes[lane]=sha(payload)
    raw=read_original_streams(files,hashes)
    check_events(raw)
    print("accepted synthetic",len(raw),"raw receipts")
    def swapped(events, i, j):
        copy=[dict(r) for r in events]
        for k in ("event","actor","phase","tick","sim_id"):
            copy[i][k],copy[j][k]=copy[j][k],copy[i][k]
        return copy
    reject("source and target eval interleaved differently",lambda:check_events(swapped(raw,3,4)))
    first_request=next(i for i,r in enumerate(raw) if r["event"]=="restore-request")
    reject("restore result before request",lambda:check_events(swapped(raw,first_request,first_request+1)))
    reject("instance swapped under intact ordinals",lambda:check_events([*raw[:2],dict(raw[2],sim_id=2),*raw[3:]]))
    reject("missing raw receipt",lambda:check_events(raw[:-1]))
    p=files["before"]
    p.write_bytes(p.read_bytes()+b"{}\n")
    reject("raw log changed after launcher receipt",lambda:read_original_streams(files,hashes))
    file=root/"fixture.gd"
    manifest=root/"source.json"
    def write_pair(body):
        file.write_bytes(body)
        entry={file.name:sha(body)}
        closure=sha(json.dumps(entry,sort_keys=True,separators=(",",":")).encode())
        raw_manifest=json.dumps({"fixture_sources":entry,"fixture_provenance_digest":closure}).encode()
        manifest.write_bytes(raw_manifest)
        return sha(raw_manifest),closure
    approved,closure=write_pair(b"approved")
    assert pinned_inputs(root,manifest,approved)==closure
    pre=dict(stage="before-spawn",manifest_sha256=approved,closure_digest=closure)
    post=dict(pre,stage="after-join")
    confirm_envelope(pre,post,approved,closure)
    replaced,replaced_closure=write_pair(b"replacement")
    reject("files and manifest jointly replaced",lambda:pinned_inputs(root,manifest,approved))
    reject("matched but unapproved closure",lambda:confirm_envelope(dict(pre,closure_digest=replaced_closure),
           dict(post,closure_digest=replaced_closure),approved,closure))
    reject("after closure drift",lambda:confirm_envelope(pre,dict(post,closure_digest=replaced_closure),approved,closure))
    reject("approval receipt replaced",lambda:confirm_envelope(dict(pre,manifest_sha256=replaced),post,approved,closure))
    print("synthetic only")
