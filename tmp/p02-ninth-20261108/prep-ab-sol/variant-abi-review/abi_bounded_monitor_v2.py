"""Review-only ABI bounded pipe monitor; requires independently provided OS launcher."""
import json
import os
import threading
import time
from pathlib import Path

if __name__=="__main__":
    raise SystemExit("ABI execution disabled: no independently approved OS confinement/owned launcher adapter")

from abi_oracle_v2 import OutputLimit, verify
from legacy_autoresolve_oracle import need

def atomic_journal(path, row):
    # Each record is separately flushed outside the engine project.
    with Path(path).open("ab",buffering=0) as sink:
        sink.write((json.dumps(row,separators=(",",":"))+"\n").encode("utf8"))
        os.fsync(sink.fileno())

def read_pipe(pipe,destination,limit,errors):
    try:
        with destination.open("xb",buffering=0) as sink:
            while not limit.exceeded.is_set():
                data=pipe.read1(16384)
                if not data:
                    break
                retained=limit.accept(data)
                if retained:
                    sink.write(retained)
            os.fsync(sink.fileno())
    except Exception as error:
        errors.append(f"{type(error).__name__}: {error}")
    finally:
        pipe.close()

def collect(child, owner, logs, started, journal):
    """The launcher supplies an already barrier-assigned, OS-confined owned process."""
    out,err=(logs/name for name in ("stdout.txt","stderr.txt"))
    limit=OutputLimit()
    errors=[]
    readers=[threading.Thread(target=read_pipe,args=(pipe,path,limit,errors),daemon=True)
             for pipe,path in ((child.stdout,out),(child.stderr,err))]
    deadline=started+20
    interruption=None
    for thread in readers:
        thread.start()
    try:
        while True:
            if limit.exceeded.is_set():
                interruption="output-limit"
                break
            if errors:
                interruption="capture-failed"
                break
            if time.monotonic()>=deadline:
                interruption="timeout"
                break
            owner.observe_owned_engine_handles()
            if child.poll() is not None and not any(t.is_alive() for t in readers):
                break
            time.sleep(.01)
    except BaseException as exc:
        interruption=f"monitor-{type(exc).__name__}"
        raise
    finally:
        cleanup_deadline=time.monotonic()+5
        # Journal failure cannot bypass owned cleanup.
        try:
            atomic_journal(journal,{"event":"before-drain","interruption":interruption,"retained":limit.total})
        finally:
            owner.drain_and_confirm(cleanup_deadline)
            for thread in readers:
                thread.join(max(0,cleanup_deadline-time.monotonic()))
    need(not any(t.is_alive() for t in readers) and not errors,"output flush/capture failed")
    need(not limit.exceeded.is_set(),"streaming output cap")
    verify(out.read_bytes(),err.read_bytes(),child.returncode,interruption)
    atomic_journal(journal,{"event":"verified","exit":child.returncode,"retained":limit.total})


