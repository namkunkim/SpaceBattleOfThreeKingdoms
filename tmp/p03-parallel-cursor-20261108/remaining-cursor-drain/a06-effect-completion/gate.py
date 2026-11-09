import hashlib
import json
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
NAMES = [
    "nominal", "marker_first_interruption", "effect_first_interruption",
    "projection_only", "wrong_context", "rollback_countermodel",
]
DOCS = ROOT / "docs/battle-core/pc-campaign-design"
PATHS = [
    *[HERE / name for name in ("PLAN.md", "receiver.py", "expected.json", "probe.py", "gate.py")],
    *[DOCS / name for name in ("H2-DECISION.md", "D04-STATE.md", "I01-ACCEPTANCE-PREREG-20261026.md")],
    HERE.parent / "REVIEW-5B-ATTEMPT-05-TERRA.md",
    HERE.parent / "a06-outcome-ownership/OUTCOME-OWNERSHIP-LEDGER.md",
    Path(sys.executable).resolve(),
]


def snapshot():
    return {str(path): {"sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
                        "bytes": path.stat().st_size} for path in PATHS}


def save(path, value):
    with path.open("x", encoding="utf-8") as stream:
        json.dump(value, stream, indent=2, ensure_ascii=False)
        stream.write("\n")


out = HERE / "attempt-01"
out.mkdir()
before = snapshot()
save(out / "input-before.json", before)
command = [sys.executable, "-B", str(HERE / "probe.py")]
with (out / "stdout.bin").open("xb") as stdout, (out / "stderr.bin").open("xb") as stderr:
    try:
        run = subprocess.run(command, cwd=HERE, stdout=stdout, stderr=stderr, timeout=10)
    except subprocess.TimeoutExpired:
        save(out / "run.json", {"timeout": True, "actual_exit": None, "gate_passed": False})
        raise SystemExit(2)
after = snapshot()
save(out / "input-after.json", after)
stdout = (out / "stdout.bin").read_text(encoding="utf-8").splitlines()
markers = []
for case in NAMES:
    markers.append(f"CASE_START {case}")
    markers.extend(f"CHECK {case}:{n} PASS" for n in range(1, 4))
    markers.append(f"CASE_END {case}")
actual = [line.split(" ", 3)[:3] for line in stdout]
expected = [line.split(" ", 3) for line in markers]
passed = (actual == expected and before == after and run.returncode == 0
          and not (out / "stderr.bin").stat().st_size)
save(out / "run.json", {"actual_exit": run.returncode, "gate_passed": passed,
                       "checks": sum(line.startswith("CHECK ") for line in stdout),
                       "exact_markers": actual == expected, "stable_inputs": len(before) if before == after else 0,
                       "argv": command, "godot_executed": False})
print((out / "run.json").read_text(encoding="utf-8"), end="")
sys.exit(not passed)
