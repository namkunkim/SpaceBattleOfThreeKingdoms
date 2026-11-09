"""Diagnostic-only owner candidate with the original Path.resolve allow decision."""
import ctypes as c
from ctypes import wintypes as w
import json
import os
from pathlib import Path
import sys

from abi_owned_runner_v3 import Owner
from legacy_autoresolve_oracle import need
from owned_image_diagnostics_review import normalized
from retained_job_queries_review import RetainedJobQueries

MAX_PATH_CHARS=768
MAX_RECORD_BYTES=14000

def existing_comparison(path):
    # Identical to Owner.observe_owned_engine_handles() in the approved v3 source.
    return os.path.normcase(str(Path(path).resolve()))

def diagnostic_record(stage,pid,creation,raw,allowlist,kind,resolve=existing_comparison):
    need(len(allowlist)==1,"unchanged Python-only image allowlist")
    for path in (raw,*allowlist):
        need(type(path) is str and len(path)<=MAX_PATH_CHARS,"diagnostic path pre-cap; evidence incomplete")
    data={"kind":kind,"stage":stage,"pid":pid,"creation_time":creation,"member_before":True,"member_after":True,
          "image_raw":raw,"image_lexical":normalized(raw),"allowed_resolved":sorted(allowlist)}
    try:
        resolved=resolve(raw)
        need(type(resolved) is str and len(resolved)<=MAX_PATH_CHARS,"resolved diagnostic path pre-cap")
        data["image_resolved"]=resolved
    except Exception as exc:
        data["resolve_error"]=type(exc).__name__
    return data

def encoded_upper_bound(value,depth=0):
    need(depth<=4,"diagnostic frame depth")
    if type(value) is str:
        need(len(value)<=MAX_RECORD_BYTES,"diagnostic encoded cap")
        return 2+sum(12 if ord(ch)>65535 else 6 if ord(ch)<32 or ord(ch)>126
                     else 2 if ch in ('"',chr(92)) else 1 for ch in value)
    if value is None or type(value) is bool:
        return 5
    if type(value) is int:
        need(value.bit_length()<=64,"diagnostic integer width")
        return 21
    if type(value) in (list,tuple):
        need(len(value)<=8,"diagnostic list count")
        return 2+sum(1+encoded_upper_bound(item,depth+1) for item in value)
    need(type(value) is dict and len(value)<=32 and all(type(k) is str for k in value),"diagnostic object shape")
    return 2+sum(2+encoded_upper_bound(k,depth+1)+encoded_upper_bound(v,depth+1) for k,v in value.items())

def encode_record(value):
    need(15+encoded_upper_bound(value)<=MAX_RECORD_BYTES,"diagnostic encoded cap before serialization")
    # Bounding input paths precedes serialization, and the encoded bytes are checked too.
    line=("P02_JOB_DIAG "+json.dumps(value,ensure_ascii=True,separators=(",",":"))+"\n").encode("ascii")
    need(len(line)<=MAX_RECORD_BYTES,"diagnostic encoded cap")
    return line

def publish(value):
    sys.stderr.buffer.write(encode_record(value))
    sys.stderr.buffer.flush()

class DiagnosticOwner(Owner):
    def __init__(self,module,allowed,required):
        super().__init__(module,allowed,required)
        self.queries=RetainedJobQueries(self.job.handle)
        self.first=None
        self.stage="job-observation"

    def report_first(self,pid,created,raw,kind,resolve):
        try:
            self.first=diagnostic_record(self.stage,pid,created,raw,tuple(self.allowed),kind,resolve)
            publish(self.first)
        except Exception:
            # Recording may fail, but it cannot turn a mismatch into success or replace it.
            self.first={"kind":kind,"diagnostic_complete":False}
            try:
                publish(self.first)
            except Exception:
                pass

    def observe_owned_engine_handles(self):
        raw=c.create_string_buffer(8+64*c.sizeof(c.c_size_t))
        need(self.job.query(self.job.handle,3,raw,len(raw),None),"Job process list")
        assigned,count=(w.DWORD*2).from_buffer(raw)
        need(count<=64 and assigned==count,"incomplete Job member list")
        for pid in (c.c_size_t*count).from_buffer(raw,8):
            if pid in self.procs:
                need(not self.queries.signalled(self.procs[pid][0]),"PID reused inside Job")
                continue
            handle=self.open(0x101000,False,pid)
            need(bool(handle),"owned PID did not yield a retained handle")
            retained=False
            try:
                self.check_member(handle)
                need(not self.queries.signalled(handle) and self.queries.pid(handle)==pid,"short or changed owned process")
                created=self.queries.creation_time(handle)
                image_raw=self.queries.image(handle)
                self.check_member(handle)
                need(not self.queries.signalled(handle) and self.queries.pid(handle)==pid
                     and self.queries.creation_time(handle)==created,"owned image identity changed")
                try:
                    image=existing_comparison(image_raw)
                except Exception as exc:
                    self.report_first(pid,created,image_raw,"owned-image-resolve-failure",
                                      resolve=lambda _: (_ for _ in ()).throw(exc))
                    raise
                if image not in self.allowed:
                    self.procs[pid]=(handle,image,created)
                    retained=True
                    self.report_first(pid,created,image_raw,"unexpected-owned-image",resolve=lambda _:image)
                    raise ValueError("unexpected owned image")
                self.procs[pid]=(handle,image,created)
            except BaseException:
                if not retained:
                    self.job.close(handle)
                raise
