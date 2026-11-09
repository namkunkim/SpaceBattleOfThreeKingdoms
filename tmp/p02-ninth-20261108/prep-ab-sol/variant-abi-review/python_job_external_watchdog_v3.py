"""External watchdog for the review-only Python Job qualification."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import threading
import time

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from abi_owned_runner_v3 import Owner,import_job,load,verify_inputs
from abi_bounded_monitor_v2 import atomic_journal
from legacy_autoresolve_oracle import need
from python_job_diagnostics_v3 import BoundedDiagnostics
from python_job_qualification_v3 import command

def bounded_task(operation,seconds,label):
    errors=[]
    def work():
        try:
            operation()
        except BaseException as exc:
            errors.append(exc)
    thread=threading.Thread(target=work,daemon=True)
    thread.start()
    thread.join(seconds)
    need(not thread.is_alive(),f"{label} deadline")
    if errors:
        raise errors[0]

def start_inert(m,ready,cancel,state):
    owner=None
    proc=None
    try:
        owner=Owner(import_job(m["v5_broker"]),[m["python"]],m["python"])
        proc=subprocess.Popen(m["broker_argv"],cwd=Path(m["scratch"]).parent,env=m["env"],stdin=subprocess.PIPE,
                              stdout=subprocess.PIPE,stderr=subprocess.PIPE,creationflags=subprocess.CREATE_NO_WINDOW)
        owner.job.attach(proc)
        owner.broker=proc
        owner.check_member(int(proc._handle))
        owner.observe_owned_engine_handles()
        state.update(owner=owner,proc=proc)
    except BaseException as exc:
        state["error"]=exc
    finally:
        if cancel.is_set() or "error" in state:
            if proc is not None and not proc.stdin.closed:
                proc.stdin.close() # No barrier write: EOF leaves broker inert.
            if owner is not None:
                try:
                    if owner.broker is not None:
                        owner.drain_and_confirm(time.monotonic()+m["drain_seconds"])
                    elif proc is not None:
                        proc.wait(timeout=m["drain_seconds"])
                finally:
                    owner.close()
        ready.set()

def run(m,manifest,pin):
    verify_inputs(m)
    root=Path(m["scratch"])
    outside=Path(m["guard_journal"])
    prefix=outside.with_suffix("")
    need(not root.exists() and not outside.exists()
         and all(not prefix.with_suffix(f".{name}.txt").exists() for name in ("stdout","stderr")),
         "fresh qualification scratch and journal")
    ready=threading.Event()
    cancel=threading.Event()
    state={}
    end=time.monotonic()+m["global_seconds"]
    threading.Thread(target=start_inert,args=(m,ready,cancel,state),daemon=True).start()
    if not ready.wait(m["bootstrap_seconds"]):
        cancel.set()
        bounded_task(lambda:atomic_journal(outside,{"event":"bootstrap-timeout","barrier_released":False}),
                     m["journal_seconds"],"bootstrap journal")
        raise ValueError("watchdog bootstrap timeout; no payload barrier release")
    if "error" in state:
        raise state["error"]
    owner,proc=state["owner"],state["proc"]
    diagnostics=BoundedDiagnostics(m["diagnostic_cap_bytes"])
    diagnostics.attach(proc)
    phase="global-before-release"
    error=None
    drained=False
    output_complete=False
    def open_barrier():
        payload=command(m["supervisor_argv_template"],manifest,pin,"all")
        data=(json.dumps(payload,ensure_ascii=True)+"\n").encode("ascii")
        need(len(data)<4096,"external barrier length")
        proc.stdin.write(data)
        proc.stdin.close()
    try:
        bounded_task(open_barrier,m["bootstrap_seconds"],"global barrier")
        phase="global-running"
        while proc.poll() is None:
            need(time.monotonic()<end,"global hard deadline")
            need(not diagnostics.limit.exceeded.is_set() and not diagnostics.errors,"supervisor diagnostics")
            time.sleep(.01)
        need(proc.returncode==0 and owner.job.active()==0,"supervisor exit or descendants remained")
    except BaseException as exc:
        error=f"{type(exc).__name__}: {exc}"
        raise
    finally:
        try:
            # First close the global job on stop. This reaches all nested owned descendants.
            cleanup=time.monotonic()+m["drain_seconds"]
            bounded_task(lambda:owner.drain_and_confirm(cleanup),m["drain_seconds"],"global owned drain")
            drained=True
            output_complete=diagnostics.finish(cleanup)
        finally:
            # On a stuck drain, process exit closes the non-inherited job handle.
            # Do not race an explicit CloseHandle against the blocked worker.
            if drained:
                owner.close()
            def record():
                prefix=outside.with_suffix("")
                evidence={}
                for name,buffer in zip(("stdout","stderr"),diagnostics.output):
                    raw=bytes(buffer)
                    target=prefix.with_suffix(f".{name}.txt")
                    with target.open("xb") as f:
                        f.write(raw)
                        f.flush()
                        os.fsync(f.fileno())
                    evidence[name]=hashlib.sha256(raw).hexdigest()
                atomic_journal(outside,{"event":"external-watchdog","phase":phase,"error":error,
                    "owned_drained":drained,"output_complete":drained and output_complete,
                    "exit":proc.returncode,"output_sha256":evidence})
            bounded_task(record,m["journal_seconds"],"external final journal")
    need(output_complete,"supervisor output incomplete")
    verify_inputs(m)

if __name__=="__main__":
    need(len(sys.argv)==3,"manifest path and independent approval SHA required")
    path,pin=sys.argv[1:]
    manifest=load(path,pin)
    need(manifest["status"]=="INDEPENDENTLY_APPROVED_NONPRODUCT_PYTHON_JOB","review-only manifest")
    run(manifest,path,pin)
