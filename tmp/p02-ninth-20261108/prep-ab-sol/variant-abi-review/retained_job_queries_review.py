"""Review-only Win32 query adapter. No process creation or global PID enumeration."""
import ctypes as c
from ctypes import wintypes as w

class RetainedJobQueries:
    def __init__(self,owned_job_handle):
        self.job=owned_job_handle
        dll=c.WinDLL("kernel32",use_last_error=True)
        def api(name,result,*types):
            fn=getattr(dll,name)
            fn.restype=result
            fn.argtypes=types
            return fn
        self._member=api("IsProcessInJob",w.BOOL,w.HANDLE,w.HANDLE,c.POINTER(w.BOOL))
        self._pid=api("GetProcessId",w.DWORD,w.HANDLE)
        self._times=api("GetProcessTimes",w.BOOL,w.HANDLE,*(c.POINTER(w.FILETIME),)*4)
        self._image=api("QueryFullProcessImageNameW",w.BOOL,w.HANDLE,w.DWORD,w.LPWSTR,c.POINTER(w.DWORD))
        self._wait=api("WaitForSingleObject",w.DWORD,w.HANDLE,w.DWORD)

    def in_job(self,handle):
        yes=w.BOOL()
        if not self._member(handle,self.job,c.byref(yes)):
            raise c.WinError(c.get_last_error())
        return bool(yes.value)

    def pid(self,handle):
        pid=self._pid(handle)
        if not pid:
            raise c.WinError(c.get_last_error())
        return pid

    def creation_time(self,handle):
        times=(w.FILETIME*4)()
        if not self._times(handle,*(c.byref(times[i]) for i in range(4))):
            raise c.WinError(c.get_last_error())
        return (times[0].dwHighDateTime<<32)|times[0].dwLowDateTime

    def image(self,handle):
        path=c.create_unicode_buffer(32768)
        size=w.DWORD(len(path))
        if not self._image(handle,0,path,c.byref(size)):
            raise c.WinError(c.get_last_error())
        if not 0<size.value<len(path) or len(path.value.encode("utf-16-le"))//2!=size.value:
            raise ValueError("incomplete image path")
        return path.value

    def signalled(self,handle):
        outcome=self._wait(handle,0)
        if outcome not in (0,258):
            raise c.WinError(c.get_last_error())
        return outcome==0

