"""Exercise receipt gates with fabricated records and audit native ordering statically."""
from copy import deepcopy
from pathlib import Path
import sys

sys.dont_write_bytecode = True
from verify_job import check

ROOT_HASH = "AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424"


def fixture():
    return [["0", "UTC", *row.split("|")] for row in [
        f"member|101|123|engine.exe|{ROOT_HASH}",
        "job_snapshot|before_resume|101",
        "resume|101",
        "job_snapshot|running|101,202,303",
        "owned_identity|202|125|confirmed|unknown.exe|not-collected",
        "member_unavailable|303|membership_unconfirmed",
        "job_notice|6|303",
        f"window|1|1101|1101|101|1|1|1600|900|96|123|{ROOT_HASH}|member",
        "exit|0",
        "job_snapshot|root_signaled|202",
        "job_snapshot|drain|",
        "root_cleanup|True|True|0|0|True",
        "job_snapshot|cleanup|",
        "owned_cleanup|202:125|0|0",
        "cleanup|0",
    ]]


def row(events, kind):
    record, = [r for r in events if r[2] == kind]
    return record


def reject(events, label):
    try:
        check(events)
    except (AssertionError, ValueError):
        print("PASS rejected", label)
        return
    raise AssertionError("Unexpected receipt accepted: " + label)


def main():
    normal = fixture()
    check(normal)
    print("PASS root exit with multiple members, unknown identity and finite drain")
    for kind, index, value, label in [
        ("exit", 3, "125", "root failure"),
        ("root_cleanup", 5, "258", "root HANDLE unsignaled"),
        ("cleanup", 3, "1", "Job active nonzero"),
        ("owned_cleanup", 4, "258", "retained member HANDLE unsignaled"),
        ("owned_cleanup", 3, "202:999", "reused PID with unrecorded creation time"),
        ("owned_identity", 7, "claimed-hash", "child image SHA claimed"),
        ("window", 6, "202", "nonroot GUI owner"),
        ("window", 12, "999", "wrong root creation time"),
    ]:
        modified = deepcopy(normal)
        row(modified, kind)[index] = value
        reject(modified, label)
    reject(normal + [["1", "UTC", "supervisor_error", "TimeoutException"]], "deadline failure")
    reject([r for r in normal if r[2] != "resume"], "assign failed with no resume")
    reject(normal + [["1", "UTC", "cleanup_request", "terminate_job"]], "forced termination")
    source = Path(__file__).with_name("Pc0Job.cs").read_text(encoding="utf-8")
    launch = source[source.index("public static uint Run"):]
    checks = ["Check(CreateProcess(", "Check(AssignProcessToJobObject(", "Member(p.Handle, job)",
              "Root image identity mismatch", '"before_resume"', "ResumeThread(p.Thread)"]
    assert [launch.index(step) for step in checks] == sorted(launch.index(step) for step in checks)
    assert "OpenProcess(0x00101000, false, pid)" in source
    assert source.index("IsProcessInJob(process, job, out member)") < source.index("retained.Add(identity")
    assert "TerminateProcess(p.Handle, 126)" in launch and "TerminateJobObject(job, 125)" in launch
    assert "now + 10000" in source and "Environment.TickCount64 + 10000" in source
    assert "WaitForSingleObject(identity.Value.Handle" in launch
    assert "Active(job) != 1" not in source
    assert "Suspended," in launch and "IntPtr.Zero, false, Suspended" in launch
    print("PASS static assign-before-resume, PID membership, HANDLE scope and watchdog bounds")
    snapshot = source[source.index("static void Snapshot("):source.index("static long Deadline(")]
    assert "HashImage(" not in snapshot and "File.Open" not in snapshot
    assert launch.count("HashImage(") == 1
    assert launch.index("HashImage(") < launch.index("ResumeThread(p.Thread)")
    assert launch.index("PC0 deadline or controller abort") < launch.index('"running", retained')
    print("PASS static child image paths are never opened or hashed by the watchdog")


if __name__ == "__main__":
    main()
