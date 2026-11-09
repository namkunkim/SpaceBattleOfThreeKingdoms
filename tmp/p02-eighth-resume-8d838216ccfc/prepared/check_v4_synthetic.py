"""V4 non-product checks. Writes only v4-synthetic."""
from copy import deepcopy
from decimal import Decimal
import json
import os
from pathlib import Path
import sys
import time
from unittest.mock import patch

sys.dont_write_bytecode = True
from owned_job_v3 import OwnedJob, run
from world_product_v4 import CANCEL, POST_RESULT, assess, read_rows

HERE = Path(__file__).resolve().parent
K4 = HERE.parents[1] / "p02-eighth-20261108/gate-k4"

def main():
    dest = HERE / "v4-synthetic"
    dest.mkdir()
    results = {}
    def check(name, value):
        results[name] = bool(value)
        if not value:
            raise AssertionError(name)
    def dump(path, data):
        path.write_text(json.dumps(data,ensure_ascii=False,default=float),encoding="utf-8")

    for case in ("complete","cancel"):
        paths = [K4 / f"{lane}-world-{case}/result.json" for lane in ("before","after")]
        historical = [read_rows(p) for p in paths]
        ids = list(historical[0])
        check(case+"-history-missing-new-lifecycle-rejected",bool(assess(paths,case=="cancel",ids)))
        temp = []
        for lane,data in zip(("before","after"),historical):
            vals = list(data.values())
            for row in vals:
                if row["assertion"] == "cancel-join":
                    row["details"] = CANCEL
                if row["assertion"] == "poll-idempotent":
                    row["details"] = POST_RESULT
            path = dest / f"{case}-{lane}.json"
            dump(path,vals)
            temp.append(path)
        check(case+"-augmented-synthetic-accepted",not assess(temp,case=="cancel",ids))
        mutation = deepcopy(vals)
        selected = "cancel-join" if case=="cancel" else "result-join"
        for row in mutation:
            if row["assertion"] == selected:
                if case=="cancel":
                    row["details"]["show_count"] = 1
                else:
                    row["details"]["outcome"]["loss_pct"]["alliance"] = 39.0
        bad = dest / f"{case}-mutated.json"
        dump(bad,mutation)
        check(case+"-mismatch-rejected",bool(assess([temp[0],bad],case=="cancel",ids)))

    marker = dest / "orphan-write"
    code = "import pathlib,sys,time;time.sleep(2);pathlib.Path(sys.argv[1]).touch()"
    parent = "import os,subprocess,sys;p=subprocess.Popen(sys.argv[1:]);print('OWNED_CHILD',p.pid,flush=True);os._exit(42)"
    argv = [sys.executable,"-I","-B","-c",parent,sys.executable,"-I","-B","-c",code,str(marker)]
    with (dest/"abnormal.out").open("xb") as out,(dest/"abnormal.err").open("xb") as err:
        result = run(argv,dest,os.environ.copy(),out,err,time.monotonic()+5,3)
    results["abnormal"] = result
    check("abnormal-owned-child-started","OWNED_CHILD" in (dest/"abnormal.out").read_text())
    check("abnormal-job-drained",result["interruption"] == "descendants-outlived-broker" and result["active_at_join"]==0 and result["exit"]==42)
    time.sleep(2.1)
    check("abnormal-child-marker-absent",not marker.exists())

    released = []
    with patch.object(OwnedJob,"attach",side_effect=PermissionError("synthetic nested Job refusal")):
        with (dest/"refusal.out").open("xb") as out,(dest/"refusal.err").open("xb") as err:
            try:
                run(argv,dest,os.environ.copy(),out,err,time.monotonic()+5,3,on_start=released.append)
            except PermissionError:
                results["simulated-assignment-refusal"] = True
    check("simulated-refusal-launch-not-released",results.get("simulated-assignment-refusal") and not released and not (dest/"refusal.out").stat().st_size)
    dump(dest/"results.json",results)
    print(json.dumps(results,ensure_ascii=False))

if __name__ == "__main__":
    main()
