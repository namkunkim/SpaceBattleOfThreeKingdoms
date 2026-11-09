"""Review-only owned Python qualification: normal, timeout, cap, outer stall."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import threading
import time
from ctypes import byref
from ctypes import wintypes as w

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from abi_owned_runner_v3 import Owner, import_job, load, release, safe_scratch, sha, verify_inputs
from abi_bounded_monitor_v2 import atomic_journal,read_pipe
from abi_oracle_v2 import OutputLimit
from python_job_diagnostics_v3 import BoundedDiagnostics
from legacy_autoresolve_oracle import need

def command(template,manifest,pin,case):
    return [s.replace("{manifest}",manifest).replace("{approval_sha256}",pin).replace("{case}",case)
            for s in template]

def marker(path,case):
    line=path.read_bytes().split(b"\n",1)[0].decode("ascii")
    parts=line.split(" ")
    need(len(parts)==3 and parts[:2]==["OWNED_TEST",case] and parts[2].isdigit(),"payload marker")
    return int(parts[2])

def controller(m,case):
    verify_inputs(m)
    scratch=Path(m["scratch"])/case
    owned=Owner(import_job(m["v5_broker"]),[m["python"]],m["python"])
    sink=scratch/"inner.jsonl"
    if case=="journal-negative":
        sink.mkdir() # Owned path collision forces a durable journal error after drain.
    proc=None
    threads=[]
    failure="exception"
    reason=None
    try:
        limit=OutputLimit(m["cap_bytes"])
        errors=[]
        start=time.monotonic()
        proc=release(owned,m["broker_argv"],[*m["payload_argv"],case],scratch,m["env"],
                     subprocess.PIPE,subprocess.PIPE)
        for stream,name in ((proc.stdout,"stdout.txt"),(proc.stderr,"stderr.txt")):
            thread=threading.Thread(target=read_pipe,args=(stream,scratch/name,limit,errors),daemon=True)
            thread.start()
            threads.append(thread)
        if case=="outer-stall":
            # Deliberate controller stall while a nested owned child is live.
            atomic_journal(sink,{"event":"controller-stall-started"})
            time.sleep(30)
            raise RuntimeError("outer watchdog did not stop controller")
        while True:
            owned.observe_owned_engine_handles()
            if limit.exceeded.is_set():
                reason="output-cap"
                break
            if errors:
                raise ValueError("pipe failure")
            if time.monotonic()-start>=m["inner_seconds"]:
                reason="timeout"
                break
            if proc.poll() is not None and not any(thread.is_alive() for thread in threads):
                break
            time.sleep(.01)
        if case=="observation-negative":
            # Inject loss of the receipt, not a claim of actual Windows lost observation.
            need(False,"synthetic missing payload observation")
        failure=None
    finally:
        try:
            deadline=time.monotonic()+m["drain_seconds"]
            owned.drain_and_confirm(deadline)
            for thread in threads:
                thread.join(max(0,deadline-time.monotonic()))
            need(not any(t.is_alive() for t in threads),"bounded pipe drain")
            pid=marker(scratch/"stdout.txt",case)
            need(proc is not None and pid!=proc.pid and pid in owned.procs,"actual payload HANDLE not retained")
            atomic_journal(sink,{"event":"inner-drained","reason":reason,"failure":failure,
                "payload_pid":pid,"exit":proc.returncode,"retained":limit.total,
                "members":owned.evidence(),"stdout_sha256":sha(scratch/"stdout.txt"),
                "stderr_sha256":sha(scratch/"stderr.txt")})
        finally:
            owned.close()
    need(reason==m["expected"][case]["inner_reason"],"wrong inner outcome")
    if reason is None:
        need(proc.returncode==0,"normal payload exit")

def assert_outside(owner,sentinel):
    in_job=w.BOOL()
    need(owner.member(int(sentinel._handle),owner.job.handle,byref(in_job)) and not in_job.value,"sentinel is in test Job")
    need(sentinel.poll() is None,"sentinel failed to remain alive")

def supervisor(m,manifest,pin):
    verify_inputs(m)
    root=Path(m["scratch"])
    root.mkdir(exist_ok=False)
    for name in m["scratch_directories"]:
        (root/name).mkdir()
    need(root.resolve()==root,"scratch is not canonical")
    sentinel=subprocess.Popen([*m["payload_argv"],"sentinel"],cwd=root,env=m["env"],
                              stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,
                              creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        for case,expected in m["expected"].items():
            scratch=root/case
            scratch.mkdir(exist_ok=False)
            owner=Owner(import_job(m["v5_broker"]),[m["python"]],m["python"])
            reason=None
            proc=None
            diagnostics=BoundedDiagnostics(m["diagnostic_cap_bytes"])
            stage="case-before-release"
            outer=scratch/"outer.jsonl"
            try:
                assert_outside(owner,sentinel)
                atomic_journal(outer,{"event":"case-start","stage":stage})
                deadline=time.monotonic()+expected["outer_seconds"]
                proc=release(owner,m["broker_argv"],command(m["controller_argv_template"],manifest,pin,case),
                             scratch,m["env"],subprocess.PIPE,subprocess.PIPE)
                stage="case-running"
                diagnostics.attach(proc)
                while proc.poll() is None:
                    if time.monotonic()>=deadline:
                        reason="outer-timeout"
                        break
                    if diagnostics.limit.exceeded.is_set() or diagnostics.errors:
                        reason="controller-diagnostics-failed"
                        break
                    owner.observe_owned_engine_handles()
                    time.sleep(.01)
                assert_outside(owner,sentinel)
            finally:
                try:
                    cleanup_deadline=time.monotonic()+m["drain_seconds"]
                    drained=False
                    try:
                        owner.drain_and_confirm(cleanup_deadline)
                        drained=True
                    finally:
                        atomic_journal(outer,{"event":"owned-cleanup","stage":stage,"drained":drained,
                            "reason":reason,"exit":proc.returncode if proc else None})
                    assert_outside(owner,sentinel)
                    capture_ok=diagnostics.finish(cleanup_deadline)
                    for stream,buffer in zip(("stdout","stderr"),diagnostics.output):
                        with (scratch/f"controller-{stream}.txt").open("xb") as output:
                            output.write(buffer)
                    stdout=scratch/"stdout.txt"
                    pid=marker(stdout,case) if stdout.is_file() else None
                    receipt=(scratch/"inner.jsonl").is_file()
                    atomic_journal(outer,{"event":"outside-evidence","stage":stage,
                        "controller_pipe_complete":capture_ok,"inner_receipt":receipt,
                        "payload_pid":pid,"payload_observed":pid in owner.procs,
                        "members":[{"pid":item,"image":img,"creation_time":t,
                                    "retained_signalled":owner.wait(handle,0)==0}
                                   for item,(handle,img,t) in owner.procs.items()],
                        "controller_stdout_sha256":sha(scratch/"controller-stdout.txt"),
                        "controller_stderr_sha256":sha(scratch/"controller-stderr.txt")})
                    need(capture_ok,"bounded controller diagnostics failed")
                    need(pid in owner.procs,"payload not observed in outer Job")
                finally:
                    owner.close()
            need(reason==expected["outer_reason"] and proc.returncode==expected["outer_exit"],"outer verdict")
            sink=scratch/"inner.jsonl"
            if case=="journal-negative":
                need(sink.is_dir(),"journal collision was not observed")
            else:
                lines=[json.loads(line) for line in sink.read_text(encoding="utf8").splitlines()]
                if case=="outer-stall":
                    need(lines==[{"event":"controller-stall-started"}],"stall did not reach reviewed checkpoint")
                else:
                    need(len(lines)==1 and lines[0]["event"]=="inner-drained","inner receipt absent")
                    row=lines[0]
                    need(row["reason"]==expected["inner_reason"] and row["payload_pid"]==pid,"inner exit/owned PID")
                    need(row["stdout_sha256"]==sha(scratch/"stdout.txt") and row["stderr_sha256"]==sha(scratch/"stderr.txt"),"raw pipe hashes")
                    need(row["failure"]==expected["inner_failure"],"inner failure receipt")
                    if case=="output-cap":
                        need(row["retained"]==m["cap_bytes"],"output cap retained byte count")
            safe_scratch(scratch,{"inner.jsonl","outer.jsonl","stdout.txt","stderr.txt","controller-stdout.txt","controller-stderr.txt"})
        verify_inputs(m)
    finally:
        try:
            out,err=sentinel.communicate(b"x",timeout=2)
            need(sentinel.returncode==0 and not err and out.startswith(b"OWNED_TEST sentinel "),"sentinel normal exit")
            atomic_journal(root/"sentinel.jsonl",{"pid":sentinel.pid,"normal_exit":sentinel.returncode,
                "stdout_sha256":hashlib.sha256(out).hexdigest()})
        except subprocess.TimeoutExpired:
            # Exact Popen process created above and never part of either case Job.
            sentinel.kill()
            sentinel.wait(timeout=2)
            raise

def main():
    need(len(sys.argv)==5,"role manifest SHA case required")
    role,path,pin,case=sys.argv[1:]
    m=load(path,pin)
    need(m["status"]=="INDEPENDENTLY_APPROVED_NONPRODUCT_PYTHON_JOB","review-only manifest")
    if role=="supervisor":
        need(case=="all","supervisor case")
        supervisor(m,path,pin)
    else:
        need(role=="controller" and case in m["expected"],"controller case")
        controller(m,case)

if __name__=="__main__":
    main()
