"""Synthetic ordering and frozen-byte mutations. Does not launch Godot."""
import hashlib
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from c_side1_bound_v5 import require_absence, sample_keys, verified_sources

keys=list(dict.fromkeys(k[:4] for k in sample_keys()))
certificate=frozenset(keys)
captures=[dict(lane=lane,instance=instance,seed=seed,case=case,phase=phase,side=1,records=[])
          for lane,instance,seed,case in keys for phase in (case,case+" repaired")]
require_absence(captures,certificate)
print("accepted canonical ordered 160 synthetic captures")

def reject(label,fn):
    try:fn()
    except (ValueError,FileNotFoundError) as e:print("rejected",label,str(e))
    else:raise AssertionError(label)

reject("all captures reversed",lambda:require_absence(captures[::-1],certificate))
reject("adjacent phases swapped",lambda:require_absence([captures[1],captures[0],*captures[2:]],certificate))
reject("phase label substitution",lambda:require_absence([dict(captures[0],phase=captures[1]["phase"]),*captures[1:]],certificate))
reject("lane block permutation",lambda:require_absence(captures[80:]+captures[:80],certificate))
reject("same count duplicate",lambda:require_absence([captures[0],captures[0],*captures[2:]],certificate))
reject("omitted capture",lambda:require_absence(captures[:-1],certificate))
with TemporaryDirectory(dir=Path(__file__).resolve().parent) as tmp:
    root=Path(tmp)
    source=root/"fixture.gd"
    source.write_bytes(b"frozen source")
    hashes={source.name:hashlib.sha256(source.read_bytes()).hexdigest()}
    digest=hashlib.sha256(json.dumps(hashes,sort_keys=True,separators=(",",":")).encode()).hexdigest()
    manifest=root/"source.json"
    manifest.write_text(json.dumps({"fixture_sources":hashes,"fixture_provenance_digest":digest}),encoding="utf8")
    assert verified_sources(root,manifest)==digest
    print("accepted unchanged synthetic frozen bytes")
    source.write_bytes(b"changed bytes")
    reject("stale claimed fixture SHA",lambda:verified_sources(root,manifest))
    source.unlink()
    reject("missing frozen input",lambda:verified_sources(root,manifest))

