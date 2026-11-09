"""No subprocess, native Job, or engine is launched by these tests."""
from io import BytesIO
import threading
import time
from types import SimpleNamespace

from python_job_diagnostics_v3 import BoundedDiagnostics
from python_job_external_watchdog_v3 import bounded_task

def reject(name,callback):
    try:callback()
    except ValueError as exc:print("rejected",name,str(exc))
    else:raise AssertionError(name)

finished=threading.Event()
bounded_task(finished.set,.5,"short stage")
assert finished.is_set()
for stage in ("bootstrap","barrier","owned drain","final journal"):
    reject(stage+" hang",lambda:bounded_task(lambda:time.sleep(.15),.01,stage))

clean=BoundedDiagnostics(16)
clean.attach(SimpleNamespace(stdout=BytesIO(b"ok"),stderr=BytesIO(b"failure reason")))
assert clean.finish(time.monotonic()+.5)
assert clean.output[0]==b"ok" and clean.output[1]==b"failure reason"
print("accepted bounded controller diagnostics including stderr")
overflow=BoundedDiagnostics(16)
overflow.attach(SimpleNamespace(stdout=BytesIO(b"x"*10),stderr=BytesIO(b"y"*10)))
assert not overflow.finish(time.monotonic()+.5)
assert sum(map(len,overflow.output))==16 and overflow.limit.exceeded.is_set()
print("rejected combined diagnostics overflow and retained exactly 16 bytes")
print("synthetic only; no process or Windows Job")
