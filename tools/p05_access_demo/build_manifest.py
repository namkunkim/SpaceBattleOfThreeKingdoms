"""Build the isolated P05 demo input from the reviewed offline probes."""

import contextlib
import io
import json
from pathlib import Path
import runpy
import sys


DESIGN = Path(__file__).resolve().parents[2] / "docs/battle-core/pc-campaign-design"


def build():
    access = runpy.run_path(str(DESIGN / "p05_map_access_validation_20261109.py"))
    capture = io.StringIO()
    with contextlib.redirect_stdout(capture):
        access["main"]()
    result = json.loads(capture.getvalue())
    envelope = runpy.run_path(str(DESIGN / "p05_formation_envelope_probe_20261109.py"))
    radii = {
        name: entry["max_transition_order_independent"]
        for name, entry in envelope["measure"]().items()
    }
    return {
        "schema": "p05-access-demo-v1",
        "envelope": "p05-layout-disks-v1",
        "space": "effective",
        "nodes": access["NODES"],
        "world": [access["WIDTH"], access["HEIGHT"]],
        "edge": access["EDGE"],
        "corridor": access["HALF_CORRIDOR"],
        "offset": access["PAIR_OFFSET"],
        "radii": radii,
        "regions": {key: access[key] for key in ("E_DEPLOY", "E_EXIT", "SUPPLY", "R_DEPLOY", "C_GOAL")},
        "witness": result,
    }


if __name__ == "__main__":
    Path(sys.argv[1]).write_text(json.dumps(build(), indent=2), encoding="utf-8")
