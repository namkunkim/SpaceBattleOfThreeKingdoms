"""Package only the cursor/drain execution and closeout evidence."""
import hashlib
import json
from pathlib import Path
import zlib
import zipfile

HERE = Path(__file__).resolve().parent
ROOT = HERE.parent
ZIP = HERE / "P03-CURSOR-DRAIN-ATTEMPT-05.zip"
FILES = [
    "PLAN.md", "PLAN-PRESERVATION-REVISION.md", "PLAN-LONGPATH-EXIT-INTEGRATION.md",
    "REVIEW-PLAN-TERRA.md", "REVIEW-PLAN-TERRA-V2.md",
    "REVIEW-PRESERVATION-REVISION-TERRA.md", "REVIEW-PRESERVATION-REVISION-V2-TERRA.md",
    "REVIEW-ZERO-TRACE-PREFLIGHT-TERRA.md", "REVIEW-INTEGRATED-GATE-TERRA.md",
    "REVIEW-LONGPATH-INTEGRATION-TERRA.md",
    "probe.gd", "launch.py", "launch_preserved.py", "windows_job.py",
    "preservation_preflight.py", "preservation_exit.py", "extended_inventory.py",
    "READ-INPUT-SHA256.json", "RESULT-HANDOFF.md", "RESULT-HANDOFF-ATTEMPT-03.md",
    "RESULT-HANDOFF-ATTEMPT-05.md", "ATTEMPT-05-5A-AUDIT.json",
    "REVIEW-ATTEMPT-02-TERRA.md", "REVIEW-ATTEMPT-03-CLOSEOUT-TERRA.md",
    "REVIEW-5B-ATTEMPT-05-TERRA.md", "RESUME-PREFLIGHT.json",
    "RESUME-PROBE-DELTA.json", "RESUME04-PREFLIGHT.json", "RESUME04-STATUS-WARN-1.txt",
    "RESUME04-STATUS-WARN-2.txt", "ZERO-TRACE-ATTEMPT05-PREFLIGHT.json",
    "P02-PID-EVIDENCE-AUDIT.json", "RESULT-P02-PID-BLOCKER.md", "PRESERVATION.json",
    "RESULT-LONGPATH-AUDIT.md", "LONGPATH-EXTENDED-COMPARISON.json",
    "PRESERVATION-INTEGRATED-V3-SYNTHETIC.json", "PRESERVATION-EXIT-SYNTHETIC.json",
    "attempt-05-closeout/CLOSEOUT-HANDOFF.md", "attempt-05-closeout/package.py",
]
FILES += [path.relative_to(ROOT).as_posix()
          for number in range(1, 6)
          for path in (ROOT / f"attempt-{number:02}").rglob("*") if path.is_file()]


def describe(content):
    return {"bytes": len(content), "sha256": hashlib.sha256(content).hexdigest(),
            "crc32": f"{zlib.crc32(content):08x}"}


def write_json(path, data):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(data, stream, indent=2, ensure_ascii=False)
        stream.write("\n")


assert len(FILES) == len(set(FILES))
manifest = {}
with zipfile.ZipFile(ZIP, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
    for name in sorted(FILES):
        source = ROOT / name
        assert source.resolve() == source and source.is_file(), name
        content = source.read_bytes()
        manifest[name] = describe(content)
        archive.writestr(name, content)

with zipfile.ZipFile(ZIP) as archive:
    entries = archive.infolist()
    assert len(entries) == len(manifest) and set(archive.namelist()) == set(manifest)
    assert archive.testzip() is None
    for entry in entries:
        expected = manifest[entry.filename]
        assert describe(archive.read(entry)) == expected
        assert describe((ROOT / entry.filename).read_bytes()) == expected
        assert f"{entry.CRC:08x}" == expected["crc32"]
        assert entry.file_size == expected["bytes"]
write_json(HERE / "EVIDENCE-MANIFEST.json", manifest)
result = {
    "zip": ZIP.name, **describe(ZIP.read_bytes()), "entries": len(manifest),
    "exact_original_rechecks": len(manifest), "duplicate_entries": 0,
    "crc_failures": 0, "godot_reexecuted": False,
}
write_json(HERE / "ZIP-VERIFICATION.json", result)
print(json.dumps(result))
