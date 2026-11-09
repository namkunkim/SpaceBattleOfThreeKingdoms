"""Extract historical markers without promoting them to K6 outcomes."""
import hashlib
import json
from pathlib import Path
import re

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TMP = ROOT / "tmp"
EIGHTH = TMP / "p02-eighth-20261108"
SUITES = {
    "p02_headless_adapter": (r"P02_ADAPTER_(PASS|FAIL).*?checks=(\d+)", ["p02-third-20261108/attempt2/headless-api.engine.log"]),
    "p02_replay_adapter": (r"P02_REPLAY_(PASS|FAIL).*?assertions=(\d+)", ["p02-third-20261108/attempt2/replay-api.engine.log"]),
    "i01b_private_state": (r"I01B_P2C_PRIVATE_STATE_(PASS|FAIL).*?checks=(\d+)", ["i01b-active-replace-20261102/regression-i01b_private_state-engine.log"]),
    "i01b_service_state": (r"I01B_P2B_SERVICE_STATE_(PASS|FAIL).*?checks=(\d+)", ["i01b-p2c-resume-20261101/attempt5-regression-i01b_service_state-engine.log"]),
    "i01b_active_replace": (r"I01B_ACTIVE_REPLACE_(PASS|FAIL).*?checks=(\d+)", ["i01b-active-replace-20261102/attempt2-engine.log"]),
    "world-clean": (r"WORLD_LINK_(PASS|FAIL)(?: (\d+))?", []),
    "world-returning": (r"WORLD_LINK_(PASS|FAIL)(?: (\d+))?", ["p02-third-20261108/attempt2/world-link.engine.log"]),
}
def identity(path):
    b = path.read_bytes()
    return {"path":str(path), "bytes":len(b), "sha256":hashlib.sha256(b).hexdigest()}

def main():
    eighth = {}
    for gate in ("gate-k3","gate-k4"):
        logs = sorted(p for p in (EIGHTH/gate).rglob("*") if p.is_file() and p.name in ("stdout","stderr","godot.log"))
        eighth[gate] = {"lanes":sorted(p.name for p in (EIGHTH/gate).iterdir() if p.is_dir()),"logs":[identity(p) for p in logs]}
    observations = {}
    for name,(pattern,earlier) in SUITES.items():
        paths = [TMP/p for p in earlier]
        paths += [p for lane in ("before","after") for p in (EIGHTH/"gate-k1"/f"{lane}-{name}").rglob("godot.log")]
        records = []
        for p in paths:
            matches = []
            for n,line in enumerate(p.read_text(encoding="utf-8-sig").splitlines(),1):
                match = re.search(pattern,line)
                if match:
                    matches.append({"line":n,"raw":line,"status":match[1],
                                    "value":int(match[2]) if match[2] else None,
                                    "quantity":"failed_assertions" if name.startswith("world-") else "executed_assertions"})
            records.append(identity(p) | {"matches":matches})
        observations[name] = records
    with (HERE/"SUITE-HISTORY-V4.json").open("x",encoding="utf-8") as f:
        json.dump({"gate_k3_k4":eighth,"observations":observations,
                   "decision":"K3/K4 contained no selected suites. K1 and earlier are historical only. None freeze the exact K6 denominators."},
                  f,ensure_ascii=False,indent=2)
if __name__ == "__main__":
    main()
