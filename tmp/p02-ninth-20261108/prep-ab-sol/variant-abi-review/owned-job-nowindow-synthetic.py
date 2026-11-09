"""Mock-only broker and retained HANDLE tests. No subprocess or Win32 call."""
from io import BytesIO
import ctypes as c
from ctypes import wintypes as w
import json
from types import SimpleNamespace
from unittest.mock import patch

import owned_job_python_nowindow_candidate as broker
import diagnostic_owner_nowindow_candidate as diagnostics

payload=[r"C:\Python314\python.exe","-I","-B","harmless.py"]
source=(json.dumps(payload)+"\n").encode()
with patch.object(broker.sys,"stdin",SimpleNamespace(buffer=BytesIO(source))), patch.object(broker.subprocess,"call",return_value=0) as call:
    assert broker.broker()==0
    call.assert_called_once_with(payload,stdin=broker.subprocess.DEVNULL,creationflags=broker.subprocess.CREATE_NO_WINDOW)
with patch.object(broker.sys,"stdin",SimpleNamespace(buffer=BytesIO(source[:-1]))), patch.object(broker.subprocess,"call") as call:
    assert broker.broker()==123
    call.assert_not_called()
print("mocked broker: sole console flag, unchanged DEVNULL stdin and inherited stdout/stderr, intact inert EOF")

closed=[]
class Job:
    handle=7
    def query(self,_,kind,raw,size,_unused):
        assert kind==3 and size>=16
        counts=(w.DWORD*2).from_buffer(raw)
        counts[:]=[1,1]
        (c.c_size_t*1).from_buffer(raw,8)[0]=41
        return True
    def close(self,handle):
        closed.append(handle)
    def active(self):
        return 0
    def drain(self,proc,deadline):
        assert proc is owned.broker
        owned.wait=lambda h,_:0
owned=diagnostics.DiagnosticOwner.__new__(diagnostics.DiagnosticOwner)
owned.job=Job()
owned.procs={}
owned.broker=object()
owned.allowed={r"c:\python314\python.exe"}
owned.queries=SimpleNamespace(signalled=lambda _:False,pid=lambda _:41,creation_time=lambda _:123,
                              image=lambda _:r"C:\Synthetic\unexpected.exe")
owned.open=lambda *args:57
owned.check_member=lambda handle:None
owned.wait=lambda *args:258
record=[]
owned.report_first=lambda *args,**kw:record.append(args)
with patch.object(diagnostics,"existing_comparison",return_value=r"c:\synthetic\unexpected.exe"):
    try:
        owned.observe_owned_engine_handles()
    except ValueError as error:
        assert str(error)=="unexpected owned image"
    else:
        raise AssertionError("allowlist bypass")
assert owned.procs[41][0]==57 and not closed and record[0][3]=="unexpected-owned-image"
owned.drain_and_confirm(1.0)
owned.close()
assert closed==[57,7]
print("mocked mismatch remained rejected and its owned HANDLE survived until drain verification")
print("synthetic only")
