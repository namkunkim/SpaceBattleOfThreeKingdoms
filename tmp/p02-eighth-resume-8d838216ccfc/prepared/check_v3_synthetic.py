"""Synthetic assessment and Windows containment checks. No product execution."""
import json
import os
from pathlib import Path
import subprocess
import sys
import time

sys.dont_write_bytecode = True
from assessment_v3 import CLEAN_DEVIATION, compare_assertions, compare_raw, validate_assertions
from owned_job_v3 import run

def require(name, condition, results):
    results[name] = bool(condition)
    if not condition:
        raise AssertionError(name)

def main():
    base = Path(__file__).resolve().parent / "v3-synthetic"
    base.mkdir()
    results = {}
    spec = {"kind":"probe-assertions","ids":["first","second"]}
    check = lambda records: validate_assertions(spec,records,0)
    require("clean-assertions", not check([("first",True),("second",True)]),results)
    require("zero-exit-false-rejected", bool(check([("first",True),("second",False)])),results)
    require("zero-exit-missing-rejected", bool(check([("first",True)])),results)
    require("zero-exit-duplicate-rejected", bool(check([("first",True),("first",True),("second",True)])),results)
    require("typed-false-is-not-string", bool(check([("first","true"),("second",True)])),results)
    suite = {"kind":"suite-assertions","count":2,"allowed_failure":CLEAN_DEVIATION}
    deviation = [("ordinary",True),(CLEAN_DEVIATION,False)]
    stderr = "ERROR: TEST_FAIL " + CLEAN_DEVIATION
    require("exact-clean-deviation", not validate_assertions(suite,deviation,1,stderr),results)
    require("clean-second-failure-rejected", bool(validate_assertions(suite,[("ordinary",False),deviation[1]],1,stderr)),results)
    require("clean-missing-raw-diagnostic-rejected", bool(validate_assertions(suite,deviation,1,"")),results)
    require("unfrozen-suite-count-rejected", bool(validate_assertions({"kind":"suite-assertions"},[("a",True)],0)),results)
    require("ordered-suite-drift-rejected", bool(compare_assertions([("a",True),("b",True)],[("b",True),("a",True)])),results)
    original = base / "raw-original.gdvar"
    changed = base / "raw-changed.gdvar"
    original.write_bytes(b"terminal [1, Vector2(0, 1)]\n")
    changed.write_bytes(b"terminal [1.0, Vector2(0, 1)]\n")
    require("raw-typed-drift-rejected", bool(compare_raw([original,changed],["terminal"])),results)
    require("raw-absent-rejected", bool(compare_raw([original,changed],["brief"])),results)
    witness = subprocess.Popen([sys.executable,"-I","-B","-c","import time; time.sleep(5)"],
                               cwd=base,creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        for case in ("normal","timeout","stop","preflight-stop"):
            marker = base / (case + "-descendant-done")
            code = "import pathlib,sys,time; time.sleep(2); pathlib.Path(sys.argv[1]).touch()"
            parent = "import subprocess,sys; p=subprocess.Popen(sys.argv[1:]); print('OWNED_CHILD',p.pid,flush=True); sys.exit(p.wait())"
            argv = [sys.executable,"-I","-B","-c",parent,sys.executable,"-I","-B","-c",code,str(marker)]
            if case == "normal":
                argv = [sys.executable,"-I","-B","-c","print('synthetic-normal')"]
            start = time.monotonic()
            with (base/(case+".out")).open("xb") as out,(base/(case+".err")).open("xb") as err:
                r = run(argv,base,os.environ.copy(),out,err,start + (0.8 if case == "timeout" else 3),3,
                        lambda: case == "preflight-stop" or (case == "stop" and time.monotonic()-start > 0.8))
            results[case] = r
            require(case + "-job-joined",r["active_at_join"] == 0,results)
            if case == "normal":
                require("normal-success",r["exit"] == 0 and r["interruption"] is None,results)
            else:
                require(case + "-interrupted",r["interruption"] is not None,results)
            if case in ("timeout","stop"):
                require(case + "-started-owned-descendant","OWNED_CHILD" in (base/(case+".out")).read_text(),results)
        require("unowned-witness-still-running",witness.poll() is None,results)
        time.sleep(2.05)
        for case in ("timeout","stop","preflight-stop"):
            require(case + "-no-descendant-completion-marker",not (base/(case+"-descendant-done")).exists(),results)
    finally:
        witness.wait(timeout=7)
        (base/"results.json").write_text(json.dumps(results,indent=2),encoding="utf-8")
    print(json.dumps(results,ensure_ascii=False))

if __name__ == "__main__":
    main()
