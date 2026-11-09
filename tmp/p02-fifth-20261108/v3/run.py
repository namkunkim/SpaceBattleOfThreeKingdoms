from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import hashlib, json, os, re, shutil, subprocess, sys, time

ROOT = Path.cwd()
OUT = Path(__file__).resolve().parent.parent
V3 = OUT / 'v3'
ENGINE = Path("C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe")
CACHE = ".godot/global_script_class_cache.cfg"
UID = ".godot/uid_cache.bin"
PRODUCT = ("scripts/world/battle_outcome.gd", "scripts/world/auto_resolver.gd")
COMMON = "tmp/p02-fifth-20261108/"
V3_REL = COMMON + "v3/"
RETURNING = V3_REL + "returning-settings.cfg"
BOUNDARY = V3_REL + "product-outcome-boundary.gd"
OWN = tuple(V3_REL + name for name in ("product-outcome-common.gd", "fixture.gd",
    "world_link-path-probe.gd", "p02_worker_adapter-path-probe.gd", "p02_headless_adapter-path-probe.gd", "returning-settings.cfg"))
SUITES = (("product-outcome-common", OWN[0]), ("world-link-clean", OWN[2]), ("world-link-returning", OWN[2]),
          ("p02_worker_adapter", OWN[3]), ("p02_headless_adapter", OWN[4]))
NATIVE_OUT = "tmp/p02-first-integration-20261105/attempt1-observations.json"
MARKERS = ("FIFTH_COMMON rows=18", "WORLD_LINK_FAIL 1", "WORLD_LINK_PASS", "P02_WORKER_CHECKS", "P02_ADAPTER_PASS", "FIFTH_BOUNDARY rows=7")
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
    workspace("v3-precopy")
    directories = ("assets", "core", "data", "hud", "input", "scenes", "scripts", "tests", "view", ".godot/imported")
    paths = {"project.godot", CACHE, UID, ".godot/scene_groups_cache.cfg", *OWN}
    for directory in directories:
        paths.update(p.relative_to(ROOT).as_posix() for p in (ROOT / directory).rglob("*") if p.is_file())
    paths = sorted(paths)
    before = inventory(ROOT, paths)
    for p in PRODUCT:
        assert before[p]["sha256"] == BASE["paths"][p]["sha256"], p
        assert record(OUT / (Path(p).name + ".before.txt")) == before[p]
    additional = [Path(__file__), ROOT / BOUNDARY, OUT / "PLAN-V3.md", OUT / "REVIEW-PLAN-V3-INDEPENDENT.md"]
    dump(V3 / "fixed-proof-inputs.json", {str(p): record(p) for p in additional})
    assert record(ROOT / RETURNING)["sha256"] == "c8b752aba9f5015889c00c5a45db9fef916af2a1e1be3e68d49b8121b2db721b"
    assert shutil.disk_usage(ROOT).free > 2 * sum(v["bytes"] for v in before.values())
    for stage in ("before", "after"):
        project = V3 / ("project-" + stage)
        project.mkdir()
        for p in paths:
            target = project / p
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / p, target)
        (project / NATIVE_OUT).parent.mkdir(parents=True, exist_ok=True)
        assert inventory(project, paths) == before
    assert inventory(ROOT, paths) == before
    dump(V3 / "inputs-before.json", before)
    dump(V3 / "engine.json", {"path": str(ENGINE), "sha256": sha(ENGINE), "version": subprocess.check_output([str(ENGINE), "--version"]).decode().strip()})
    workspace("v3-pre-run")

def run(stage, label):
    identity()
    project = V3 / ("project-" + stage)
    for path, value in json.loads((V3 / "fixed-proof-inputs.json").read_bytes()).items():
        assert record(Path(path)) == value, path
    expected = json.loads((V3 / "inputs-before.json").read_bytes())
    suites = SUITES
    if stage == "after":
        for p in PRODUCT:
            expected[p] = record(ROOT / p)
            shutil.copyfile(ROOT / p, project / p)
        frozen = json.loads((V3 / "oracle-freeze.json").read_bytes())
        for path, value in frozen.items():
            assert record(Path(path)) == value, path
        shutil.copyfile(ROOT / BOUNDARY, project / BOUNDARY)
        expected[BOUNDARY] = record(ROOT / BOUNDARY)
        suites += (("product-outcome-boundary", BOUNDARY),)
    assert inventory(project, sorted(expected)) == expected
    assert all(record(ROOT / p) == expected[p] for p in expected)
    evidence = OUT / label
    evidence.mkdir()
    dump(evidence / "inputs.json", expected)

    def execute(item):
        index, (name, suite) = item
        dirname = evidence / name
        dirname.mkdir()
        roaming = dirname / "roaming"
        local = dirname / "local"
        roaming.mkdir()
        local.mkdir()
        envkeys = {"APPDATA": str(roaming), "LOCALAPPDATA": str(local), "XDG_DATA_HOME": str(roaming)}
        args = [str(ENGINE), "--headless", "--path", str(project), "--script", "res://" + suite, "--", str(dirname / "result.json")]
        userdata = roaming / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
        userdata.mkdir(parents=True)
        if index == 2:
            shutil.copyfile(ROOT / RETURNING, userdata / "settings.cfg")
        user_start = {p.name: record(p) for p in userdata.iterdir()}
        dump(dirname / "user-start.json", user_start)
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
                  "marker": marker in stdout, "script_error": b"SCRIPT ERROR" in stderr, "name": name, "user_start": user_start, "stdout": sha(dirname / "stdout"), "stderr": sha(dirname / "stderr")}
        if index in (0, 5) and (dirname / "result.json").is_file():
            result["result_sha256"] = sha(dirname / "result.json")
            result["guard"] = json.loads((dirname / "result.json").read_bytes()).get("guard")
        if index == 4 and (project / NATIVE_OUT).is_file():
            shutil.copyfile(project / NATIVE_OUT, dirname / "observations.json")
            result["result_sha256"] = sha(dirname / "observations.json")
        observed = re.search(rb"^FIFTH_USER (.+)$", stdout, re.M)
        if observed is not None:
            result["user_probe"] = json.loads(observed[1])
        elif index == 0 and result.get("guard"):
            result["user_probe"] = {"dir": result["guard"]["user"], "initial_files": ["settings.cfg"] if result["guard"]["settings_at_start"] else []}
        result["expected_user"] = str(userdata)
        result["user_end"] = {p.relative_to(userdata).as_posix(): record(p) for p in userdata.rglob("*") if p.is_file()}
        dump(dirname / "process.json", result)
        return result

    with ThreadPoolExecutor(3) as pool:
        results = list(pool.map(execute, enumerate(suites)))
    dump(evidence / "processes.json", results)
    assert inventory(project, sorted(expected)) == expected
    assert all(record(ROOT / p) == expected[p] for p in expected)
    workspace(label)
    for i, r in enumerate(results):
        assert r["exit"] == (1 if i == 1 else 0) and r["marker"] and not r["script_error"] and not r["timeout"], (i, r)
        probe = r["user_probe"]
        assert Path(probe["dir"]).resolve() == Path(r["expected_user"]).resolve()
        assert probe["initial_files"] == (["settings.cfg"] if i == 2 else []), (i, probe)
        if i == 2:
            assert probe["settings_sha"] == r["user_start"]["settings.cfg"]["sha256"] == r["user_end"]["settings.cfg"]["sha256"]
    clean = (evidence / "world-link-clean/stderr").read_text(encoding="utf8")
    assert clean.count("TEST_FAIL") == 1 and "TEST_FAIL 천하에서 오면 브리핑부터 (prologue)" in clean
    assert "_round_trip (res://tests/world_link.gd:239)" in clean
    guard = results[0]["guard"]
    assert Path(guard["project"]).resolve() == project.resolve()
    assert Path(guard["user"]).is_relative_to(evidence)
    assert guard["classes"] == ["res://" + p for p in PRODUCT]
    common = evidence / "product-outcome-common/result.json"
    observed = json.loads(common.read_bytes())
    assert observed["failures"] == 0 and sorted(observed["rows"]) == [f"A{i:02d}" for i in range(1, 19)]
    assert observed["rows"]["A03"]["tick"] == 10 and observed["rows"]["A03"]["consumed"]
    assert len(observed["rows"]["A03"]["transitions"]) == 5
    assert observed["profile"]["profile_source_sha"] == expected["data/profiles/red_cliffs_rt.json"]["sha256"]
    if stage == "before":
        oracle = V3 / "original-outcome-oracle.json"
        assert not oracle.exists()
        shutil.copyfile(common, oracle)
        freeze = [oracle, common, evidence / "inputs.json", evidence / "processes.json",
                  V3 / "fixed-proof-inputs.json", V3 / "engine.json", OUT / (label + "-workspace.json")]
        dump(V3 / "oracle-freeze.json", {str(p): record(p) for p in freeze})
    print(label, "PASS_REQUIRED", [r["seconds"] for r in results])

if sys.argv[1] == "prepare":
    prepare()
else:
    run(sys.argv[1], sys.argv[2])
