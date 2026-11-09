"""Static/synthetic runner checks without a Windows Job or child executable."""
import importlib.util
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from abi_owned_runner_v3 import load, safe_scratch, sha

here=Path(__file__).resolve().parent
manifest=here/"ABI-OWNED-RUNNER-v3-MANIFEST.json"
m=load(manifest,sha(manifest))
assert m["status"]=="REVIEW_ONLY_NON_EXECUTABLE"
assert m["outer_hard_seconds"]>m["inner_engine_seconds"]+m["owned_drain_seconds"]
assert len(m["stage_inputs"])==2 and all(sha(p)==s for p,s in m["hashes"].items())
assert all(sha(p)==s for p,s in m["protected_hashes"].items())
print("approved-byte/manifest shape matches frozen inputs; still review-only")

def reject(name,callback):
    try:callback()
    except ValueError as e:print("rejected",name,str(e))
    else:raise AssertionError(name)

reject("wrong independent SHA",lambda:load(manifest,"0"*64))
with TemporaryDirectory(dir=here) as folder:
    root=Path(folder)
    (root/"allowed").write_bytes(b"owned")
    safe_scratch(root,{"allowed"})
    (root/"extra").write_bytes(b"owned")
    reject("unexpected scratch write",lambda:safe_scratch(root,{"allowed"}))
print("no process or Job created")
