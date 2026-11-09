"""Review-only nested Windows Job launcher for the minimal nonproduct ABI probe."""
import ctypes as c
from ctypes import wintypes as w
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys
import time

HERE=Path(__file__).resolve().parent
sys.path.insert(0,str(HERE))
from abi_bounded_monitor_v2 import atomic_journal, collect
from legacy_autoresolve_oracle import need, unique

def sha(path):
    with Path(path).open("rb") as src:
        return hashlib.file_digest(src,"sha256").hexdigest()

def load(path,approved):
    data=Path(path).read_bytes()
    need(hashlib.sha256(data).hexdigest()==approved,"independent manifest SHA")
    return json.loads(data,object_pairs_hook=unique)

def import_job(path):
    spec=importlib.util.spec_from_file_location("abi_v5_owned_job",path)
    module=importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module

class Owner:
    def __init__(self,module,allowed,required):
        self.job=module.OwnedJob()
        self.allowed={os.path.normcase(str(Path(p).resolve())) for p in allowed}
        self.required=os.path.normcase(str(Path(required).resolve()))
        self.procs={}
        self.broker=None
        dll=c.WinDLL("kernel32",use_last_error=True)
        def api(name,result,*types):
            f=getattr(dll,name)
            f.restype=result
            f.argtypes=types
            return f
        self.open=api("OpenProcess",w.HANDLE,w.DWORD,w.BOOL,w.DWORD)
        self.member=api("IsProcessInJob",w.BOOL,w.HANDLE,w.HANDLE,c.POINTER(w.BOOL))
        self.times=api("GetProcessTimes",w.BOOL,w.HANDLE,*(c.POINTER(w.FILETIME),)*4)
        self.image=api("QueryFullProcessImageNameW",w.BOOL,w.HANDLE,w.DWORD,w.LPWSTR,c.POINTER(w.DWORD))
        self.wait=api("WaitForSingleObject",w.DWORD,w.HANDLE,w.DWORD)

    def check_member(self,handle):
        yes=w.BOOL()
        need(self.member(handle,self.job.handle,c.byref(yes)) and yes.value,"exact HANDLE is not in owned Job")

    def observe_owned_engine_handles(self):
        # QueryInformationJobObject class 3, bounded process list. Any overflow fails.
        raw=c.create_string_buffer(8+64*c.sizeof(c.c_size_t))
        need(self.job.query(self.job.handle,3,raw,len(raw),None),"Job process list")
        assigned,count=(w.DWORD*2).from_buffer(raw)
        need(count<=64 and assigned==count,"incomplete Job member list")
        pids=(c.c_size_t*count).from_buffer(raw,8)
        for pid in pids:
            if pid in self.procs:
                need(self.wait(self.procs[pid][0],0)==258,"PID reused inside Job")
                continue
            handle=self.open(0x101000,False,pid) # SYNCHRONIZE | QUERY_LIMITED_INFORMATION
            need(bool(handle),"owned PID did not yield a retained handle")
            try:
                self.check_member(handle)
                stamps=(w.FILETIME*4)()
                need(self.times(handle,*(c.byref(stamps[i]) for i in range(4))),"process creation time")
                buffer=c.create_unicode_buffer(32768)
                size=w.DWORD(len(buffer))
                need(self.image(handle,0,buffer,c.byref(size)),"process image")
                image=os.path.normcase(str(Path(buffer.value).resolve()))
                need(image in self.allowed,"unexpected owned image")
                created=(stamps[0].dwHighDateTime<<32)|stamps[0].dwLowDateTime
                self.procs[pid]=(handle,image,created)
            except BaseException:
                self.job.close(handle)
                raise

    def drain_and_confirm(self,deadline):
        if self.broker is None:
            return
        self.job.drain(self.broker,deadline)
        need(self.job.active()==0,"owned job still active")
        need(all(self.wait(handle,0)==0 for handle,_,_ in self.procs.values()),"owned process handle still active")

    def evidence(self):
        need(any(image==self.required for _,image,_ in self.procs.values()),"required engine image not observed")
        return [{"pid":pid,"image":image,"creation_time":created,"retained_signalled":self.wait(handle,0)==0}
                for pid,(handle,image,created) in self.procs.items()]

    def close(self):
        for handle,_,_ in self.procs.values():
            self.job.close(handle)
        self.job.close(self.job.handle)

def release(owner,broker_argv,payload,cwd,env,stdout,stderr):
    proc=subprocess.Popen(broker_argv,cwd=cwd,env=env,stdin=subprocess.PIPE,
                          stdout=stdout,stderr=stderr,creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        owner.job.attach(proc)
        owner.broker=proc
        owner.check_member(int(proc._handle))
        owner.observe_owned_engine_handles()
        data=(json.dumps(payload,ensure_ascii=True)+"\n").encode("ascii")
        need(len(data)<4096,"broker barrier payload length")
        proc.stdin.write(data)
        proc.stdin.close()
        return proc
    except BaseException:
        if not proc.stdin.closed:
            proc.stdin.close() # EOF, no command released
        if owner.broker is None:
            proc.wait(timeout=2)
        raise

def verify_inputs(m):
    need(all(sha(p)==expected for p,expected in m["hashes"].items()),"frozen ABI source/executable drift")
    need(all(sha(p)==expected for p,expected in m["protected_hashes"].items()),"protected source drift")

def safe_scratch(root,allowed):
    # Bounded observational audit, not an OS path enforcement mechanism.
    for path in root.rglob("*"):
        stat=path.lstat()
        need(not getattr(stat,"st_file_attributes",0)&0x400,"scratch contains reparse point")
        need(path.relative_to(root).as_posix() in allowed,"unexpected scratch path")

def controller(m):
    verify_inputs(m)
    root=Path(m["scratch"])
    project=root/"project"
    project.mkdir(exist_ok=False)
    for source,relative in m["stage_inputs"].items():
        dest=project/relative
        dest.write_bytes(Path(source).read_bytes())
        need(sha(dest)==m["hashes"][source],"staged probe bytes")
    for value in m["scratch_directories"]:
        (root/value).mkdir(exist_ok=True)
    module=import_job(m["v5_broker"])
    owner=Owner(module,m["images"],m["engine_argv"][0])
    try:
        started=time.monotonic()
        proc=release(owner,m["broker_argv"],m["engine_argv"],project,m["env"],subprocess.PIPE,subprocess.PIPE)
        collect(proc,owner,root/"logs",started,root/"logs/inner.jsonl")
        atomic_journal(root/"logs/inner.jsonl",{"event":"engine-handles","members":owner.evidence(),
            "stdout_sha256":sha(root/"logs/stdout.txt"),"stderr_sha256":sha(root/"logs/stderr.txt")})
        verify_inputs(m)
        safe_scratch(root,set(m["allowed_scratch_paths"]))
    finally:
        try:
            owner.drain_and_confirm(time.monotonic()+5)
        finally:
            owner.close()

def supervisor(m,manifest_path,approved_sha256):
    verify_inputs(m)
    root=Path(m["scratch"])
    root.mkdir(exist_ok=False)
    need(root.resolve()==root,"scratch path is not canonical")
    logs=root/"logs"
    logs.mkdir()
    module=import_job(m["v5_broker"])
    owner=Owner(module,m["images"],m["engine_argv"][0])
    deadline=time.monotonic()+m["outer_hard_seconds"]
    reason="setup-or-controller-failure"
    try:
        # Controller results are in bounded engine pipes and a separate journal.
        command=[v.replace("{manifest}",manifest_path).replace("{approval_sha256}",approved_sha256)
                 for v in m["controller_argv_template"]]
        proc=release(owner,m["broker_argv"],command,root,m["env"],
                     subprocess.DEVNULL,subprocess.DEVNULL)
        while proc.poll() is None:
            need(time.monotonic()<deadline,"outer hard deadline")
            owner.observe_owned_engine_handles()
            time.sleep(.01)
        need(proc.returncode==0,"controller exit")
        need(owner.job.active()==0,"descendants remained after normal controller exit")
        reason=None
    finally:
        try:
            owner.drain_and_confirm(time.monotonic()+5)
            # After the bounded owned drain. This fsync does not hold the owned engine alive.
            if reason is None:
                owner.evidence()
            atomic_journal(logs/"outer.jsonl",{"event":"owned-drain","failure":reason,
                "members":[{"pid":pid,"image":image,"creation_time":created,
                            "retained_signalled":owner.wait(handle,0)==0}
                           for pid,(handle,image,created) in owner.procs.items()]})
        finally:
            owner.close()
    verify_inputs(m)

def main():
    need(len(sys.argv)==4,"role, manifest path, approved SHA required")
    role,path,pin=sys.argv[1:]
    m=load(path,pin)
    need(m["status"]=="INDEPENDENTLY_APPROVED_NONPRODUCT_ABI","review-only manifest")
    need(role in ("supervisor","controller"),"launcher role")
    if role=="supervisor":
        supervisor(m,path,pin)
    else:
        controller(m)

if __name__=="__main__":
    main()
