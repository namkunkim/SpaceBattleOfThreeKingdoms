"""Read-only window observation. This module has no activation or input API."""
import argparse
import ctypes as ct
from ctypes import wintypes as w
import hashlib
import json
import time
from pathlib import Path

def digest(path):
    with open(path, "rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()

def inspect(hwnd, point=None):
    user = ct.WinDLL("user32", use_last_error=True)
    kernel = ct.WinDLL("kernel32", use_last_error=True)

    def fn(dll, name, restype, *args):
        f = getattr(dll, name)
        f.argtypes = args
        f.restype = restype
        return f

    get_foreground = fn(user, "GetForegroundWindow", w.HWND)
    get_ids = fn(user, "GetWindowThreadProcessId", w.DWORD, w.HWND, ct.POINTER(w.DWORD))
    rect = fn(user, "GetWindowRect", w.BOOL, w.HWND, ct.POINTER(w.RECT))
    client = fn(user, "GetClientRect", w.BOOL, w.HWND, ct.POINTER(w.RECT))
    convert = fn(user, "ClientToScreen", w.BOOL, w.HWND, ct.POINTER(w.POINT))
    get_title = fn(user, "GetWindowTextW", ct.c_int, w.HWND, w.LPWSTR, ct.c_int)
    dpi = fn(user, "GetDpiForWindow", w.UINT, w.HWND)
    exists = fn(user, "IsWindow", w.BOOL, w.HWND)
    begin = get_foreground()
    hwnd = hwnd or begin
    if not exists(hwnd):
        raise RuntimeError("target HWND is absent")
    pid, r, c, t = w.DWORD(), w.RECT(), w.RECT(), ct.create_unicode_buffer(512)
    tid = get_ids(hwnd, ct.byref(pid))
    if not (tid and rect(hwnd, ct.byref(r)) and client(hwnd, ct.byref(c)) and get_title(hwnd, t, len(t))):
        raise RuntimeError("incomplete window observation")
    a, b = w.POINT(c.left, c.top), w.POINT(c.right, c.bottom)
    if not (convert(hwnd, ct.byref(a)) and convert(hwnd, ct.byref(b))):
        raise RuntimeError("client conversion failed")
    matches = []
    callback_type = ct.WINFUNCTYPE(w.BOOL, w.HWND, w.LPARAM)

    @callback_type
    def enumerate_title(handle, _):
        buf = ct.create_unicode_buffer(512)
        if get_title(handle, buf, len(buf)) and buf.value == t.value:
            matches.append(handle)
        return True

    enum_windows = fn(user, "EnumWindows", w.BOOL, callback_type, w.LPARAM)
    if not enum_windows(enumerate_title, 0):
        raise RuntimeError("could not enumerate title uniqueness")
    hit = None
    if point:
        window_at = fn(user, "WindowFromPoint", w.HWND, w.POINT)
        get_ancestor = fn(user, "GetAncestor", w.HWND, w.HWND, w.UINT)
        raw = window_at(w.POINT(*point))
        hit = {"point": point, "hwnd": raw, "root": get_ancestor(raw, 2) if raw else None,
               "in_client": a.x <= point[0] < b.x and a.y <= point[1] < b.y}
    handle = fn(kernel, "OpenProcess", w.HANDLE, w.DWORD, w.BOOL, w.DWORD)(0x1000, False, pid.value)
    if not handle:
        raise RuntimeError("owner process query failed")
    try:
        times = [w.FILETIME() for _ in range(4)]
        get_times = fn(kernel, "GetProcessTimes", w.BOOL, w.HANDLE, *([ct.POINTER(w.FILETIME)] * 4))
        query = fn(kernel, "QueryFullProcessImageNameW", w.BOOL, w.HANDLE, w.DWORD, w.LPWSTR, ct.POINTER(w.DWORD))
        image = ct.create_unicode_buffer(32768)
        size = w.DWORD(len(image))
        if not (get_times(handle, *(ct.byref(t) for t in times)) and query(handle, 0, image, ct.byref(size))):
            raise RuntimeError("owner process identity incomplete")
        creation = (times[0].dwHighDateTime << 32) | times[0].dwLowDateTime
        path = Path(image.value)
        sha = digest(path)
    finally:
        fn(kernel, "CloseHandle", w.BOOL, w.HANDLE)(handle)
    return {"epoch_ns": time.time_ns(), "hwnd": hwnd, "pid": pid.value, "tid": tid,
            "title": t.value, "same_title_hwnds": matches, "creation_filetime": creation,
            "executable": str(path), "sha256": sha, "dpi": dpi(hwnd),
            "window_rect": [r.left, r.top, r.right, r.bottom],
            "client_screen": [a.x, a.y, b.x, b.y], "foreground_begin": begin,
            "foreground_end": get_foreground(), "hit": hit}

if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--hwnd", type=lambda s: int(s, 0))
    ap.add_argument("--point", type=int, nargs=2)
    args = ap.parse_args()
    print(json.dumps(inspect(args.hwnd, args.point), ensure_ascii=True))
