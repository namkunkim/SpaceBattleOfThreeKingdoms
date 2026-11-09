import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
SCOPES = ["core/battle", "scripts", "scenes", "hud", "input", "view"]
QUERY = r"restore_completed\(|capture_completed\(|start_operation\(|OperationAdapter|BattleSim.new|AutoResolver|WorldLink|wait_to_finish"
IDS = {"RAW_HOST", "LEGACY_WORKER", "LIMITED_WORKER", "LIMITED_REPLAY", "OWNER_PUBLIC", "PRODUCT_JOIN"}
PAIRS = {("RAW_HOST", "LIMITED_WORKER"), ("LEGACY_WORKER", "LIMITED_WORKER"),
         ("LIMITED_REPLAY", "LIMITED_WORKER"), ("OWNER_PUBLIC", "OWNER_PUBLIC")}
FIXED = ["tmp/p03-parallel-state-20261108/owner-thread-paths/PLAN.md",
         "tmp/p03-inchat-cn/REVIEW-PLAN.md",
         "docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md"]


def cmd(args, allow=(0,)):
    proc = subprocess.run(args, cwd=ROOT, capture_output=True)
    if proc.returncode not in allow or proc.stderr:
        raise RuntimeError(f"{args}: {proc.returncode}, {proc.stderr!r}")
    return proc.stdout.decode("utf-8")


def snapshot():
    paths = sorted(cmd(["rg", "--files", *SCOPES, "-g", "*.gd", "-g", "*.tscn"]).splitlines())
    paths = [Path(path).as_posix() for path in paths]
    if len(paths) != len(set(paths)):
        raise ValueError("duplicate paths")
    files = {p: hashlib.sha256((ROOT / p).read_bytes()).hexdigest() for p in paths + FIXED}
    search = cmd(["rg", "-n", "--color", "never", "-g", "*.gd", "-g", "*.tscn", QUERY, *SCOPES], (0, 1))
    return {"head": cmd(["git", "rev-parse", "HEAD"]).strip(), "files": files,
            "production_count": len(paths), "query": QUERY, "scopes": SCOPES,
            "search": "\n".join(sorted(search.splitlines()))}


def validate(data, frozen):
    rows = data["rows"]
    pairs = data["pairs"]
    if len(rows) != 6 or {r["id"] for r in rows} != IDS:
        return 1
    if len(pairs) != 4 or {tuple(p["pair"]) for p in pairs} != PAIRS:
        return 1
    for row in rows + pairs:
        if any(not row[key].strip() for key in ("owner", "thread", "mutable", "lock", "end", "condition")):
            return 1
        if row["status"] not in {"CURRENT_SOURCE", "NOT_FOUND_IN_SCOPE", "UNVERIFIED"}:
            return 1
        if not row["anchors"]:
            return 1
        for path, literal in row["anchors"]:
            if path not in frozen["files"] or literal not in (ROOT / path).read_text(encoding="utf-8"):
                print(f"missing anchor: {path}: {literal}", file=sys.stderr)
                return 2
    if any(row["same_owner_product_race"] is not False for row in pairs):
        return 1
    print("PASS: 6 routes, 4 comparisons, anchored scope")
    return 0


def main():
    if sys.argv[1] == "snapshot":
        print(json.dumps(snapshot(), ensure_ascii=True, indent=2))
        return 0
    frozen = json.loads(Path(sys.argv[2]).read_bytes())
    data = json.loads(Path(sys.argv[1]).read_bytes())
    if snapshot() != frozen:
        print("source scope drift", file=sys.stderr)
        return 2
    return validate(data, frozen)


if __name__ == "__main__":
    sys.exit(main())
