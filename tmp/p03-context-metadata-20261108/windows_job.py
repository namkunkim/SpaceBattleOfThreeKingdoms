"""Isolate one suspended Windows launcher and the children it starts."""

import ctypes as c
from ctypes import wintypes as w

CREATE_SUSPENDED = 4


class BasicLimits(c.Structure):
    _fields_ = [("process_time", c.c_longlong), ("job_time", c.c_longlong), ("flags", w.DWORD),
                ("min_working_set", c.c_size_t), ("max_working_set", c.c_size_t),
                ("active_limit", w.DWORD), ("affinity", c.c_size_t),
                ("priority", w.DWORD), ("scheduling", w.DWORD)]


class ExtendedLimits(c.Structure):
    _fields_ = [("basic", BasicLimits), ("io", c.c_ulonglong * 6),
                ("process_memory_limit", c.c_size_t), ("job_memory_limit", c.c_size_t),
                ("peak_process_memory", c.c_size_t), ("peak_job_memory", c.c_size_t)]


class Accounting(c.Structure):
    _fields_ = [("times", c.c_longlong * 4), ("faults", w.DWORD), ("total", w.DWORD),
                ("active", w.DWORD), ("terminated", w.DWORD)]


class ThreadEntry(c.Structure):
    _fields_ = [("size", w.DWORD), ("usage", w.DWORD), ("thread", w.DWORD), ("owner", w.DWORD),
                ("base_priority", w.LONG), ("delta_priority", w.LONG), ("flags", w.DWORD)]


kernel = c.WinDLL("kernel32", use_last_error=True)


def bind(name, result, *args):
    method = getattr(kernel, name)
    method.restype, method.argtypes = result, args
    return method


create_job = bind("CreateJobObjectW", w.HANDLE, c.c_void_p, w.LPCWSTR)
set_job = bind("SetInformationJobObject", w.BOOL, w.HANDLE, c.c_int, c.c_void_p, w.DWORD)
query_job = bind("QueryInformationJobObject", w.BOOL, w.HANDLE, c.c_int, c.c_void_p, w.DWORD, c.c_void_p)
assign_job = bind("AssignProcessToJobObject", w.BOOL, w.HANDLE, w.HANDLE)
terminate_job = bind("TerminateJobObject", w.BOOL, w.HANDLE, w.UINT)
close = bind("CloseHandle", w.BOOL, w.HANDLE)
open_process = bind("OpenProcess", w.HANDLE, w.DWORD, w.BOOL, w.DWORD)
open_thread = bind("OpenThread", w.HANDLE, w.DWORD, w.BOOL, w.DWORD)
resume_thread = bind("ResumeThread", w.DWORD, w.HANDLE)
snapshot_threads = bind("CreateToolhelp32Snapshot", w.HANDLE, w.DWORD, w.DWORD)
first_thread = bind("Thread32First", w.BOOL, w.HANDLE, c.POINTER(ThreadEntry))
next_thread = bind("Thread32Next", w.BOOL, w.HANDLE, c.POINTER(ThreadEntry))


def require(value, action):
    if not value:
        raise OSError(c.get_last_error(), action)
    return value


def thread_for(pid):
    snapshot = snapshot_threads(4, 0)  # TH32CS_SNAPTHREAD
    require(snapshot and snapshot != c.c_void_p(-1).value, "CreateToolhelp32Snapshot")
    try:
        entry = ThreadEntry()
        entry.size = c.sizeof(entry)
        require(first_thread(snapshot, c.byref(entry)), "Thread32First")
        matches = []
        while True:
            if entry.owner == pid:
                matches.append(entry.thread)
            entry.size = c.sizeof(entry)
            if not next_thread(snapshot, c.byref(entry)):
                if c.get_last_error() != 18:  # ERROR_NO_MORE_FILES
                    require(False, "Thread32Next")
                break
        if len(matches) != 1:
            raise OSError(f"expected one suspended launcher thread, got {len(matches)}")
        return matches[0]
    finally:
        close(snapshot)


class LauncherJob:
    def __enter__(self):
        self.handle = require(create_job(None, None), "CreateJobObjectW")
        limits = ExtendedLimits()
        limits.basic.flags = 0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        if not set_job(self.handle, 9, c.byref(limits), c.sizeof(limits)):
            error = c.get_last_error()
            close(self.handle)
            raise OSError(error, "SetInformationJobObject(KILL_ON_JOB_CLOSE)")
        self.assigned = False
        return self

    def __exit__(self, exc_type, exc, traceback):
        close(self.handle)

    def assign_and_resume(self, pid):
        process = require(open_process(0x101, False, pid), "OpenProcess(SET_QUOTA|TERMINATE)")
        try:
            require(assign_job(self.handle, process), "AssignProcessToJobObject")
            self.assigned = True
        finally:
            close(process)
        tid = thread_for(pid)
        thread = require(open_thread(2, False, tid), "OpenThread(SUSPEND_RESUME)")
        try:
            previous = resume_thread(thread)
            if previous != 1:
                raise OSError(c.get_last_error() if previous == 0xFFFFFFFF else 0, f"ResumeThread previous={previous}")
        finally:
            close(thread)
        return tid

    def terminate(self):
        ok = bool(terminate_job(self.handle, 124))
        return {"ok": ok, "win32_error": None if ok else c.get_last_error()}

    def accounting(self):
        info = Accounting()
        require(query_job(self.handle, 1, c.byref(info), c.sizeof(info), None), "QueryInformationJobObject")
        return {"active": info.active, "total": info.total, "terminated": info.terminated}
