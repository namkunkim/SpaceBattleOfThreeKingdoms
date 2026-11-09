import json, hashlib, sys, shutil
from pathlib import Path
from datetime import datetime, UTC
from freeze import BASE, ROOT, read, sha, git

audit = read(BASE / "CLOSEOUT-AUDIT.json")
receipt = read(BASE / "DELIVERY-RECEIPT.json")
archive = BASE / "P02-WORLD-RETURN-NOTICE-DELIVERY-20261109.zip"
inventory = BASE / "DELIVERY-MANIFEST.json"
review = BASE / "REVIEW-CLOSEOUT-INDEPENDENT.md"
progress = ROOT / "docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md"
project = BASE / "attempt-01/project"
cache = project / ".godot"
preflight = BASE / "CACHE-CLEANUP-PREFLIGHT.json"
manifest = read(BASE / "EXECUTION-REVIEW-ONLY.json")
apply = read(BASE / "APPLY-RESULT.json")
assert git("rev-parse","HEAD") == apply["head"]
assert sha(ROOT/git("rev-parse","--git-path","index")) == apply["index_sha256"]
assert sha(archive) == receipt["zip_sha256"] and sha(inventory) == receipt["inventory_sha256"]
for name, digest in manifest["source_map"].items():
    assert sha(ROOT / name) == apply["after"].get(name, digest), name
for name, digest in audit["protected_evidence_old_zip_html_sha256"].items():
    assert sha(ROOT / name) == digest, name

def checked_files(path):
    for entry in path.rglob("*"):
        st = entry.lstat()
        assert not st.st_file_attributes & 1024, entry
        if entry.is_file():
            yield entry

mode, = sys.argv[1:]
before_utc = datetime.now(UTC).isoformat()
protected = {p.relative_to(BASE).as_posix(): sha(p) for p in checked_files(BASE / "attempt-01") if not p.is_relative_to(cache)}
original_cache = ROOT / ".godot"
original_sample = {p.relative_to(original_cache).as_posix(): [p.stat().st_size, p.stat().st_mtime_ns] for p in checked_files(original_cache)}
if mode == "preflight":
    assert sha(progress) == audit["progress_after_sha256"]
    assert cache.resolve() == cache and cache.is_dir()
    assert all(not p.lstat().st_file_attributes & 1024 for p in (cache, *cache.parents))
    rows = sorted([p.relative_to(cache).as_posix(), p.stat().st_size, sha(p)] for p in checked_files(cache))
    encoded = json.dumps(rows, ensure_ascii=False, separators=(",",":")).encode()
    digest = hashlib.sha256(encoded).hexdigest()
    assert len(rows) == 1336 and sum(r[1] for r in rows) == 334714454 and digest == "65181402f268de376480fe5fbad8761e2e8b7a0fb9910fb646cd84c6fa92491c"
    with preflight.open("x",encoding="utf-8") as stream:
        json.dump(dict(utc=before_utc, resolved_path=str(cache), files=len(rows), bytes=sum(r[1] for r in rows), inventory_sha256=digest, inventory=rows, protected_attempt_files=protected, original_cache_stat_sample=original_sample, free_bytes=shutil.disk_usage(BASE).free, review_sha256=sha(review)),stream,ensure_ascii=False,indent=2)
elif mode == "postflight":
    assert not cache.exists()
    pre = read(preflight)
    assert pre["protected_attempt_files"] == protected
    assert pre["original_cache_stat_sample"] == original_sample
    assert pre["review_sha256"] == sha(review)
    assert sha(progress) == audit["progress_after_sha256"]
    free = shutil.disk_usage(BASE).free
    result = dict(utc=before_utc, deleted_path=str(cache), deleted_files=pre["files"], deleted_bytes=pre["bytes"], inventory_sha256=pre["inventory_sha256"], free_before_bytes=pre["free_bytes"], free_after_bytes=free, observed_free_delta_bytes=free-pre["free_bytes"], protected_attempt_paths=len(protected), original_cache_stat_paths=len(original_sample), requires_reimport=True)
    with (BASE/"CACHE-CLEANUP-RESULT.json").open("x",encoding="utf-8") as stream:
        json.dump(result,stream,indent=2)
    print(result)
else:
    raise ValueError(mode)
