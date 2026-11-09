"""Exit preservation and independent P02 trace evidence. No engine entry point."""
import hashlib
import json
from pathlib import Path
import re
import stat
from datetime import datetime

from extended_inventory import extended, inventory
from preservation_preflight import TRACE_PARENTS, protection_failures, validate_path

TRACE_NAME = re.compile(r"battle-(\d{4}-\d\d-\d\dT\d\d-\d\d-\d\d)-(\d+)-(\d+)\.jsonl")


def document(path):
    return json.loads(extended(path).read_text(encoding="utf-8-sig"))


def sha(path):
    with extended(path).open("rb") as handle:
        return hashlib.file_digest(handle, "sha256").hexdigest()


def freeze(roots):
    rows = {}
    for root in roots:
        metadata = extended(root).lstat()
        if metadata.st_file_attributes & stat.FILE_ATTRIBUTE_REPARSE_POINT:
            raise ValueError(f"protected reparse point: {root}")
        if stat.S_ISREG(metadata.st_mode):
            record = {"type": "file", "bytes": metadata.st_size, "sha256": sha(root)}
            final = extended(root).stat()
            if (metadata.st_size, metadata.st_mtime_ns) != (final.st_size, final.st_mtime_ns):
                raise ValueError(f"file changed during inventory: {root}")
            current = {str(root): record}
        else:
            current = inventory([root])
        for path, record in current.items():
            if path in rows and rows[path] != record:
                raise ValueError(f"inconsistent overlapping inventories: {path}")
            rows[path] = record
    return rows


def trace_evidence(path, record, own_dir, own_pids, opened_at, closed_at, trace_parents=TRACE_PARENTS):
    """Accept only an independent P02 record and matching trace start within the window."""
    match = TRACE_NAME.fullmatch(path.name)
    if path.parent not in trace_parents or not match or not own_pids:
        return None
    stamp, pid, _ = match.groups()
    pid = int(pid)
    when = datetime.strptime(stamp, "%Y-%m-%dT%H-%M-%S")
    if pid <= 0 or pid in own_pids or not opened_at.replace(microsecond=0) <= when <= closed_at:
        return None
    mode = path.parent.parents[4]
    command_path = mode / "command.json"
    process_path = mode / "process.json"
    log = path.parent.parent / "logs/godot.log"
    try:
        for evidence_path in (command_path, process_path, log, path):
            validate_path(evidence_path)
        command = document(command_path)
        process = document(process_path)
        env = command["env"]
        args = command["args"]
        relative = str(path.relative_to(path.parent.parent))
        expected = process["user_after"][relative]
        if process.get("engine_pid") != pid:
            return None
        if relative in command["user_before"] or expected != record["sha256"]:
            return None
        if Path(env["APPDATA"]) != mode / "roaming" or Path(env["LOCALAPPDATA"]) != mode / "local":
            return None
        candidate = Path(args[args.index("--path") + 1])
        if not candidate.is_relative_to(mode.parent.parent) or candidate.is_relative_to(own_dir):
            return None
        log_lines = extended(log).read_text(encoding="utf-8", errors="strict").splitlines()
        if f"[TRACE] {path.as_posix()}" not in log_lines:
            return None
        with extended(path).open(encoding="utf-8") as handle:
            first = json.loads(handle.readline())
        if first["kind"] != "session_start" or datetime.fromisoformat(first["wall_time"]) != when:
            return None
        evidence = {str(item): sha(item) for item in (command_path, process_path, log)}
        if sha(path) != expected:
            return None
    except (OSError, ValueError, KeyError, IndexError, TypeError):
        return None
    return {"engine_pid_from_trace": pid, "wall_time": when.isoformat(),
            "records": evidence, "trace_sha256": expected,
            "pid_attested_by": str(process_path)}


def audit_exit(roots, before, own_dir, own_pids, opened_at, closed_at):
    after = freeze(roots)
    attributable = {}
    for name in after.keys() - before.keys():
        path = Path(name)
        if after[name]["type"] == "file":
            proof = trace_evidence(path, after[name], own_dir, own_pids, opened_at, closed_at)
            if proof:
                attributable[name] = proof
    failures, permitted = protection_failures(before, after, attributable, own_dir)
    return after, failures, permitted
