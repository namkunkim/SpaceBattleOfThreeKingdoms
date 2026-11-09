"""Check an owned Job's successful lane receipt. Unknown identities remain audit limits."""
import hashlib
from pathlib import Path
import sys


def check(events):
    def of(kind):
        return [row[3:] for row in events if row[2] == kind]

    assert not of("supervisor_error") and not of("cleanup_request") and not of("cleanup_snapshot_error")
    root, = of("member")
    assert root[0].isdigit() and root[1].isdigit()
    assert root[3] == "AB1824F85BFD8E0E4128182C000C4003A3E042245B2967848D089B2A04B22424"
    assert of("resume") == [[root[0]]] and of("exit") == [["0"]]
    assert of("root_cleanup") == [["True", "True", "0", "0", "True"]]
    assert of("cleanup") == [["0"]]
    stages = of("job_snapshot")
    assert stages[0][0] == "before_resume" and root[0] in stages[0][1].split(",")
    assert stages[-1] == ["cleanup", ""]
    assert sum(stage == "root_signaled" for stage, _ in stages) == 1
    observed = of("owned_identity")
    retained = [f"{row[0]}:{row[1]}" for row in observed]
    assert len(retained) == len(set(retained)) and all(row[2] == "confirmed" for row in observed)
    closed = of("owned_cleanup")
    assert sorted(row[0] for row in closed) == sorted(retained)
    assert all(row[1] == "0" for row in closed)
    windows = of("window")
    assert all(row[0] == "1" and row[3] == root[0] and row[9:] == [root[1], root[3], "member"] for row in windows)


if __name__ == "__main__":
    stem = Path(sys.argv[1])
    check([line.split("\t") for line in stem.with_suffix(".os.tsv").read_text(encoding="utf-8").splitlines()])
    log = stem.with_suffix(".log")
    observed = stem.with_suffix(".log.sha256").read_text(encoding="utf-8").strip().lower()
    assert hashlib.sha256(log.read_bytes()).hexdigest() == observed
