"""Read-only verification and reproducibility metadata for three closed Godot caches."""
import hashlib
import json
import runpy
import sys
from pathlib import Path
from zipfile import ZipFile

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
DELIVERY = BASE / "delivery-precloseout"
ARCHIVE = DELIVERY / "P02-WORLD-RETURN-REJECT-DELIVERY-20261109.zip"
MANIFEST = DELIVERY / "manifest.json"
CACHES = {
    "attempt-01/before/project/.godot": (334714604, "3e68183a148b6e2eaeaebb51b8943c25b4fe834fbbfd1df335a9a179de81bd72"),
    "attempt-02/before/project/.godot": (334714600, "b19a7b28ac492b36e8b6c39b9ff3a7c5d128e187aa8adfc541d84e1c37e1b344"),
    "attempt-02/after/project/.godot": (334714585, "ff072d6b0a2a15c6b16a61e93ba904b1e1d461e9d3ce208e806a4cb84895f5b9"),
}


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def evidence():
    expected_archive = "2b94ac408ca45061c985c3a58ca508de70bf7fff926c6ca249d14dc62bb4ddb4"
    expected_manifest = "c044040e1485a6dd51798f314773fca9d28e9d7975ea9b03d8c6d81202260d66"
    assert sha(ARCHIVE) == expected_archive and sha(MANIFEST) == expected_manifest
    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))["entries"]
    assert len(entries) == 168
    assert all(sha(ROOT / name) == entry["sha256"] for name, entry in entries.items())
    with ZipFile(ARCHIVE) as archive:
        assert archive.testzip() is None
    runner = runpy.run_path(str(BASE / "run-reviewed-return-v2.py"))
    manifest = runner["read"](BASE / "ATTEMPT-02-EXECUTION-REVIEW-ONLY.json")
    preservation = runner["read"](DELIVERY / "preservation.json")
    manifest["source_map"]["scripts/world_link.gd"] = preservation["world_link_sha256"]
    for row in manifest["baseline"]["files"]:
        if row["path"] == "scripts/world_link.gd":
            row["sha256"] = preservation["world_link_sha256"]
        if row["path"].endswith("/P02-PROGRESS-CHECKLIST.md"):
            row["sha256"] = preservation["progress_after_sha256"]
    runner["verify"](manifest)
    assert all(sha(ROOT / path) == digest for path, digest in preservation["old_zip_html_sha256"].items())
    return {
        "zip_sha256": expected_archive, "manifest_sha256": expected_manifest,
        "payload_paths_verified": len(entries), "source_paths_verified": len(manifest["source_map"]),
        "baseline_paths_verified": len(manifest["baseline"]["files"]),
        "old_zip_html_paths_verified": len(preservation["old_zip_html_sha256"]),
        "closeout_sha256": sha(BASE / "REVIEW-CLOSEOUT-INDEPENDENT.md"),
    }


def inventory(name):
    path = BASE / name
    assert path.resolve() == path and path.is_dir()
    rows = sorted((p.relative_to(path).as_posix(), p.stat().st_size, sha(p)) for p in path.rglob("*") if p.is_file())
    total = sum(row[1] for row in rows)
    digest = hashlib.sha256(json.dumps(rows, ensure_ascii=False, separators=(",", ":")).encode()).hexdigest()
    assert len(rows) == 1336 and (total, digest) == CACHES[name], (name, len(rows), total, digest)
    return {"path": str(path), "files": len(rows), "bytes": total, "inventory_sha256": digest, "inventory": rows}


if sys.argv[1:] == ["preflight"]:
    print(json.dumps({"evidence": evidence(), "caches": [inventory(name) for name in CACHES]}, ensure_ascii=True))
elif sys.argv[1:] == ["postflight"]:
    assert all(not (BASE / name).exists() for name in CACHES)
    print(json.dumps(evidence()))
else:
    assert len(sys.argv) == 2 and sys.argv[1] in CACHES
    print(json.dumps(inventory(sys.argv[1]), ensure_ascii=True))
