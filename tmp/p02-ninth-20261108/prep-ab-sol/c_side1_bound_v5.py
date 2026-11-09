"""Review-only C certificate with ordered captures and verified source bytes."""
import hashlib
import json
from pathlib import Path

from c_side1_bound_v4 import case_key, certify as certify_v4, fields, integer, sample_keys
from legacy_autoresolve_oracle import need, unique

def verified_sources(root, source_manifest):
    manifest=json.loads(Path(source_manifest).read_bytes(),object_pairs_hook=unique)
    expected=manifest["fixture_sources"]
    need(type(expected) is dict and bool(expected),"fixture source manifest")
    root=Path(root).resolve(strict=True)
    hashes={}
    for relative,expected_hash in expected.items():
        path=Path(relative)
        need(not path.is_absolute() and ".." not in path.parts,"fixture source relative path")
        file=(root/path).resolve(strict=True)
        need(file.is_relative_to(root) and file.is_file(),"fixture source escapes root")
        digest=hashlib.sha256(file.read_bytes()).hexdigest()
        need(digest==expected_hash,f"fixture source drift: {relative}")
        hashes[relative]=digest
    canonical=json.dumps(hashes,sort_keys=True,separators=(",",":")).encode()
    fixture_digest=hashlib.sha256(canonical).hexdigest()
    need(fixture_digest==manifest["fixture_provenance_digest"],"fixture source manifest digest")
    return fixture_digest

def certify(doc, root, source_manifest):
    return certify_v4(doc,verified_sources(root,source_manifest))

def require_absence(captures,certificate):
    need(type(captures) is list and type(certificate) is frozenset,"certificate and capture types")
    instances=list(dict.fromkeys(k[:4] for k in sample_keys()))
    need(certificate==frozenset(instances),"incomplete or absent certificate")
    ordered=[(*key,phase) for key in instances for phase in (key[3],key[3]+" repaired")]
    need(len(captures)==len(ordered),"incomplete ordered capture sequence")
    for index,(r,expected) in enumerate(zip(captures,ordered)):
        fields(r,("lane","instance","seed","case","phase","side","records"),"contact capture")
        key=(*case_key(r),r["phase"])
        need(type(r["phase"]) is str and key==expected,f"capture {index}: ordered phase or instance mismatch")
        integer(r["side"],"contact capture side",1)
        need(type(r["records"]) is list and not r["records"],"independently excluded opposing record")
