"""Enumerate canonical protected paths using Windows extended-length I/O."""
import hashlib
import os
from pathlib import Path
import stat

PREFIX = "\\\\?\\"


def extended(path):
    return Path(PREFIX + str(path))


def inventory(roots):
    found = {}

    def on_error(error):
        raise error

    for root in roots:
        for component in (root, *root.parents):
            if extended(component).lstat().st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
                raise ValueError(f"protected reparse point: {component}")
        if not extended(root).is_dir():
            raise ValueError(f"missing protected root: {root}")
        for folder, dirs, files in os.walk(extended(root), onerror=on_error, followlinks=False):
            found[folder.removeprefix(PREFIX)] = {"type": "directory"}
            for name in sorted(dirs + files):
                path = Path(folder) / name
                key = str(path).removeprefix(PREFIX)
                before = path.lstat()
                if before.st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
                    raise ValueError(f"protected reparse point: {key}")
                if stat.S_ISDIR(before.st_mode):
                    found[key] = {"type": "directory"}
                elif stat.S_ISREG(before.st_mode):
                    with path.open("rb") as stream:
                        content = hashlib.file_digest(stream, "sha256").hexdigest()
                    after = path.stat()
                    if (before.st_size, before.st_mtime_ns) != (after.st_size, after.st_mtime_ns):
                        raise ValueError(f"file changed during inventory: {key}")
                    found[key] = {"type": "file", "bytes": before.st_size, "sha256": content}
                else:
                    raise ValueError(f"unexpected protected file type: {key}")
    return found
