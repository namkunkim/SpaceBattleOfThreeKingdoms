"""Assign an inert broker to a private Windows Job before releasing its launch barrier."""
import ctypes as c
from ctypes import wintypes as w
from contextlib import contextmanager
import json
import os
from pathlib import Path
import subprocess
import sys
import time

class BasicLimits(c.Structure):
    _fields_ = [("PerProcessUserTimeLimit", c.c_longlong), ("PerJobUserTimeLimit", c.c_longlong),
                ("LimitFlags", w.DWORD), ("MinimumWorkingSetSize", c.c_size_t),
                ("MaximumWorkingSetSize", c.c_size_t), ("ActiveProcessLimit", w.DWORD),
                ("Affinity", c.c_size_t), ("PriorityClass", w.DWORD), ("SchedulingClass", w.DWORD)]

class ExtendedLimits(c.Structure):
    _fields_ = [("BasicLimitInformation", BasicLimits), ("IoInfo", c.c_ulonglong * 6),
                ("ProcessMemoryLimit", c.c_size_t), ("JobMemoryLimit", c.c_size_t),
                ("PeakProcessMemoryUsed", c.c_size_t), ("PeakJobMemoryUsed", c.c_size_t)]

class Accounting(c.Structure):
    _fields_ = [("Times", c.c_longlong * 4), ("TotalPageFaultCount", w.DWORD),
                ("TotalProcesses", w.DWORD), ("ActiveProcesses", w.DWORD), ("TotalTerminatedProcesses", w.DWORD)]

def broker():
    raw = sys.stdin.buffer.readline(131072)
    if not raw.endswith(b"\n"):
        return 123
    argv = json.loads(raw)
    if not argv or not Path(argv[0]).is_absolute():
        return 124
    # Inherits the Job and output streams. No breakaway flag is set.
    return subprocess.call(argv, stdin=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW)

class OwnedJob:
    def __init__(self):
        dll = c.WinDLL("kernel32", use_last_error=True)
        def api(name, result, *args):
            fn = getattr(dll, name)
            fn.restype = result
            fn.argtypes = args
            return fn
        self.close = api("CloseHandle", w.BOOL, w.HANDLE)
        create = api("CreateJobObjectW", w.HANDLE, c.c_void_p, w.LPCWSTR)
        self.assign = api("AssignProcessToJobObject", w.BOOL, w.HANDLE, w.HANDLE)
        self.terminate = api("TerminateJobObject", w.BOOL, w.HANDLE, w.UINT)
        self.query = api("QueryInformationJobObject", w.BOOL, w.HANDLE, c.c_int, c.c_void_p, w.DWORD, c.c_void_p)
        configure = api("SetInformationJobObject", w.BOOL, w.HANDLE, c.c_int, c.c_void_p, w.DWORD)
        self.handle = create(None, None)
        if not self.handle:
            raise c.WinError(c.get_last_error())
        limits = ExtendedLimits()
        # KILL_ON_JOB_CLOSE, without either breakaway limit flag.
        limits.BasicLimitInformation.LimitFlags = 0x2000
        if not configure(self.handle, 9, c.byref(limits), c.sizeof(limits)):
            error = c.get_last_error()
            self.close(self.handle)
            raise c.WinError(error)

    def active(self):
        info = Accounting()
        if not self.query(self.handle, 1, c.byref(info), c.sizeof(info), None):
            raise c.WinError(c.get_last_error())
        return info.ActiveProcesses

    def attach(self, process):
        # Popen still owns the exact live process HANDLE. No PID lookup.
        if not self.assign(self.handle, int(process._handle)):
            raise c.WinError(c.get_last_error())

    def drain(self, process, deadline):
        if self.active() and not self.terminate(self.handle, 125):
            raise c.WinError(c.get_last_error())
        while self.active():
            if time.monotonic() >= deadline:
                raise TimeoutError("owned Job did not drain")
            time.sleep(0.02)
        process.wait(timeout=max(0, deadline - time.monotonic()))

def run(argv, cwd, env, stdout, stderr, deadline, cleanup_seconds, stop=lambda: False, on_start=lambda pid: None):
    if os.name != "nt":
        raise RuntimeError("Windows Job Object is required")
    job = OwnedJob()
    process = None
    attached = False
    reason = None
    leaked_descendants = False
    try:
        if stop() or time.monotonic() >= deadline:
            return {"exit": None, "interruption": "stop-or-deadline-before-launch", "active_at_join": 0}
        process = subprocess.Popen([sys.executable, "-I", "-B", str(Path(__file__).resolve()), "--broker"],
                                   cwd=cwd, env=env, stdin=subprocess.PIPE, stdout=stdout, stderr=stderr,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        job.attach(process)
        attached = True
        on_start(process.pid)
        if stop() or time.monotonic() >= deadline:
            reason = "stop-or-deadline-before-release"
        else:
            message = json.dumps(argv, ensure_ascii=True).encode("ascii") + b"\n"
            if len(message) >= 131072:
                raise ValueError("broker command line too large")
            process.stdin.write(message)
            process.stdin.flush()
            while process.poll() is None:
                if stop() or time.monotonic() >= deadline:
                    reason = "stop" if stop() else "timeout"
                    break
                time.sleep(0.05)
            if reason is None:
                leaked_descendants = job.active() != 0
                if leaked_descendants:
                    reason = "descendants-outlived-broker"
    finally:
        try:
            if process is not None:
                process.stdin.close()
                if attached:
                    job.drain(process, time.monotonic() + cleanup_seconds)
                else:
                    # EOF to our inert broker is the only action on an unassigned process.
                    process.wait(timeout=cleanup_seconds)
        finally:
            job.close(job.handle)
    return {"exit": process.returncode, "interruption": reason, "active_at_join": 0,
            "broker_pid": process.pid, "descendants_outlived_broker": leaked_descendants}

if __name__ == "__main__":
    if sys.argv[1:] != ["--broker"]:
        raise SystemExit(124)
    raise SystemExit(broker())
