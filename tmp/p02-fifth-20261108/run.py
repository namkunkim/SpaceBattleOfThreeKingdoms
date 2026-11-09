from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib, json, os, shutil, subprocess, sys, time

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
CACHE = ".godot/global_script_class_cache.cfg"
UID = ".godot/uid_cache.bin"
PRODUCT = ("scripts/world/battle_outcome.gd", "scripts/world/auto_resolver.gd")
COMMON = "tmp/p02-fifth-20261108/"
OWN = tuple(COMMON + name for name in ("product-outcome-common.gd", "fixture.gd"))
SUITES = (OWN[0], "tests/world_link.gd", "tests/p02_worker_adapter.gd", "tests/p02_headless_adapter.gd")
NATIVE_OUT = "tmp/p02-first-integration-20261105/attempt1-observations.json"
MARKERS = ("FIFTH_COMMON rows=18", "WORLD_LINK_PASS", "P02_WORKER_CHECKS", "P02_ADAPTER_PASS", "FIFTH_BOUNDARY rows=7")
BASE = json.loads((OUT / "baseline.json").read_bytes())

def sha(path):
    with path.open("rb") as f:
        return hashlib.file_digest(f, "sha256").hexdigest()

def git(*args):
    return subprocess.check_output(["git", *args], env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"})

def record(path):
    return {"bytes": path.stat().st_size, "sha256": sha(path)}

def dump(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf8")

def inventory(root, paths):
    with ThreadPoolExecutor(12) as pool:
        return dict(zip(paths, pool.map(lambda p: record(root / p) if (root / p).is_file() else None, paths)))

def identity():
    for key, args in [("branch", ("branch", "--show-current")), ("head", ("rev-parse", "HEAD")), ("index", ("ls-files", "--stage", "-z")), ("tracked", ("ls-files", "--cached", "-z"))]:
        assert git(*args) == (OUT / (key + ".raw")).read_bytes(), key
    assert record(ROOT / ".git/index")["sha256"] == BASE["index_start"]["sha256"]
    for path, value in BASE["runtime"].items():
        assert sha(Path(path)) == value["sha256"], path

def workspace(label):
    identity()
    inv = inventory(ROOT, sorted(BASE["paths"]))
    drift = {p: {"before": v, "now": inv[p]} for p, v in BASE["paths"].items() if inv[p] != {"bytes": v.get("bytes"), "sha256": v.get("sha256")}}
    new = [p for p in git("ls-files", "--others", "--exclude-standard", "-z").decode().split("\0") if p and p not in inv and not p.startswith(COMMON)]
    dump(OUT / (label + "-workspace.json"), {"drift": drift, "new": new, "paths": len(inv)})
    return drift, new

def prepare():
    workspace("precopy")
    directories = ("assets", "core", "data", "hud", "input", "scenes", "scripts", "tests", "view", ".godot/imported")
    paths = {"project.godot", CACHE, UID, ".godot/scene_groups_cache.cfg", *OWN}
    for directory in directories:
        paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT / directory).rglob("*") if p.is_file())
    paths = sorted(paths)
    before = inventory(ROOT, paths)
    for p in PRODUCT:
        assert before[p]["sha256"] == BASE["paths"][p]["sha256"], p
        shutil.copyfile(ROOT / p, OUT / (Path(p).name + ".before.txt"))
    assert shutil.disk_usage(ROOT).free > 2 * sum(v["bytes"] for v in before.values())
    for stage in ("before", "after"):
        project = OUT / ("project-" + stage)
        project.mkdir()
        for p in paths:
            target = project / p
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / p, target)
        (project / NATIVE_OUT).parent.mkdir(parents=True, exist_ok=True)
        assert inventory(project, paths) == before
    assert inventory(ROOT, paths) == before
    dump(OUT / "inputs-before.json", before)
    dump(OUT / "engine.json", {"path": str(ENGINE), "sha256": sha(ENGINE), "version": subprocess.check_output([str(ENGINE), "--version"]).decode().strip()})
    workspace("pre-run")

def run(stage, label):
    identity()
    project = OUT / ("project-" + stage)
    expected = json.loads((OUT / "inputs-before.json").read_bytes())
    suites = SUITES
    if stage == "after":
        for p in PRODUCT:
            expected[p] = record(ROOT / p)
            shutil.copyfile(ROOT / p, project / p)
        boundary = COMMON + "product-outcome-boundary.gd"
        shutil.copyfile(ROOT / boundary, project / boundary)
        expected[boundary] = record(ROOT / boundary)
        suites += (boundary,)
    assert inventory(project, sorted(expected)) == expected
    assert all(record(ROOT / p) == expected[p] for p in expected)
    evidence = OUT / label
    evidence.mkdir()
    dump(evidence / "inputs.json", expected)

    def execute(item):
        index, suite = item
        dirname = evidence / Path(suite).stem
        dirname.mkdir()
        roaming = dirname / "roaming"
        local = dirname / "local"
        roaming.mkdir()
        local.mkdir()
        envkeys = {"APPDATA": str(roaming), "LOCALAPPDATA": str(local), "XDG_DATA_HOME": str(roaming)}
        args = [str(ENGINE), "--headless", "--path", str(project), "--script", "res://" + suite, "--", str(dirname / "result.json")]
        start = time.monotonic()
        try:
            run = subprocess.run(args, env={**os.environ, **envkeys}, capture_output=True, timeout=240)
            stdout, stderr, exitcode, timeout = run.stdout, run.stderr, run.returncode, False
        except subprocess.TimeoutExpired as e:
            stdout, stderr, exitcode, timeout = e.stdout or b"", e.stderr or b"", None, True
        (dirname / "stdout").write_bytes(stdout)
        (dirname / "stderr").write_bytes(stderr)
        marker = MARKERS[index].encode()
        result = {"args": args, "env": envkeys, "limit_seconds": 240, "seconds": time.monotonic() - start, "exit": exitcode, "timeout": timeout,
                  "marker": marker in stdout, "script_error": b"SCRIPT ERROR" in stderr, "stdout": sha(dirname / "stdout"), "stderr": sha(dirname / "stderr")}
        if index in (0, 4) and (dirname / "result.json").is_file():
            result["result_sha256"] = sha(dirname / "result.json")
            result["guard"] = json.loads((dirname / "result.json").read_bytes()).get("guard")
        if index == 3 and (project / NATIVE_OUT).is_file():
            shutil.copyfile(project / NATIVE_OUT, dirname / "observations.json")
            result["result_sha256"] = sha(dirname / "observations.json")
        dump(dirname / "process.json", result)
        return result

    with ThreadPoolExecutor(4) as pool:
        results = list(pool.map(execute, enumerate(suites)))
    dump(evidence / "processes.json", results)
    assert inventory(project, sorted(expected)) == expected
    assert all(record(ROOT / p) == expected[p] for p in expected)
    workspace(label)
    assert all(r["exit"] == 0 and r["marker"] and not r["script_error"] for r in results), [(i, r["exit"], r["marker"], r["script_error"]) for i,r in enumerate(results)]
    guard = results[0]["guard"]
    assert Path(guard["project"]).resolve() == project.resolve()
    assert Path(guard["user"]).is_relative_to(evidence)
    assert guard["classes"] == ["res://" + p for p in PRODUCT]
    print(label, "PASS", [r["seconds"] for r in results])

if sys.argv[1] == "prepare":
    prepare()
else:
    run(sys.argv[1], sys.argv[2])
