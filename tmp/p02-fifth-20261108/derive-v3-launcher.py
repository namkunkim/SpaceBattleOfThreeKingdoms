from pathlib import Path

out = Path(__file__).resolve().parent
v3 = out / "v3"
source = (out / "run.py").read_text(encoding="utf8")
source = source.replace("OUT = Path(__file__).resolve().parent", "OUT = Path(__file__).resolve().parent.parent\nV3 = OUT / 'v3'")
start = source.index("OWN = ")
end = source.index("BASE = ", start)
source = source[:start] + """V3_REL = COMMON + "v3/"
RETURNING = V3_REL + "returning-settings.cfg"
BOUNDARY = V3_REL + "product-outcome-boundary.gd"
OWN = tuple(V3_REL + name for name in ("product-outcome-common.gd", "fixture.gd",
    "world_link-path-probe.gd", "p02_worker_adapter-path-probe.gd", "p02_headless_adapter-path-probe.gd", "returning-settings.cfg"))
SUITES = (("product-outcome-common", OWN[0]), ("world-link-clean", OWN[2]), ("world-link-returning", OWN[2]),
          ("p02_worker_adapter", OWN[3]), ("p02_headless_adapter", OWN[4]))
NATIVE_OUT = "tmp/p02-first-integration-20261105/attempt1-observations.json"
MARKERS = ("FIFTH_COMMON rows=18", "WORLD_LINK_FAIL 1", "WORLD_LINK_PASS", "P02_WORKER_CHECKS", "P02_ADAPTER_PASS", "FIFTH_BOUNDARY rows=7")
""" + source[end:]
source = source.replace('import hashlib, json, os, shutil', 'import hashlib, json, os, re, shutil')
source = source.replace('OUT / ("project-" + stage)', 'V3 / ("project-" + stage)')
source = source.replace('OUT / "inputs-before.json"', 'V3 / "inputs-before.json"')
source = source.replace('OUT / "engine.json"', 'V3 / "engine.json"')
source = source.replace('shutil.copyfile(ROOT / p, OUT / (Path(p).name + ".before.txt"))', 'assert record(OUT / (Path(p).name + ".before.txt")) == before[p]')
source = source.replace('workspace("precopy")', 'workspace("v3-precopy")')
source = source.replace('workspace("pre-run")', 'workspace("v3-pre-run")')
source = source.replace('    assert shutil.disk_usage', '''    additional = [Path(__file__), ROOT / BOUNDARY, OUT / "PLAN-V3.md", OUT / "REVIEW-PLAN-V3-INDEPENDENT.md"]
    dump(V3 / "fixed-proof-inputs.json", {str(p): record(p) for p in additional})
    assert record(ROOT / RETURNING)["sha256"] == "c8b752aba9f5015889c00c5a45db9fef916af2a1e1be3e68d49b8121b2db721b"
    assert shutil.disk_usage''')
source = source.replace('    expected = json.loads', '''    for path, value in json.loads((V3 / "fixed-proof-inputs.json").read_bytes()).items():
        assert record(Path(path)) == value, path
    expected = json.loads''')
source = source.replace('        boundary = COMMON + "product-outcome-boundary.gd"\n        shutil.copyfile(ROOT / boundary, project / boundary)\n        expected[boundary] = record(ROOT / boundary)\n        suites += (boundary,)', '''        frozen = json.loads((V3 / "oracle-freeze.json").read_bytes())
        for path, value in frozen.items():
            assert record(Path(path)) == value, path
        shutil.copyfile(ROOT / BOUNDARY, project / BOUNDARY)
        expected[BOUNDARY] = record(ROOT / BOUNDARY)
        suites += (("product-outcome-boundary", BOUNDARY),)''')
source = source.replace('        index, suite = item\n        dirname = evidence / Path(suite).stem', '        index, (name, suite) = item\n        dirname = evidence / name')
source = source.replace('        start = time.monotonic()', '''        userdata = roaming / "Godot/app_userdata/SpaceBattleOfThreeKingdoms"
        userdata.mkdir(parents=True)
        if index == 2:
            shutil.copyfile(ROOT / RETURNING, userdata / "settings.cfg")
        user_start = {p.name: record(p) for p in userdata.iterdir()}
        dump(dirname / "user-start.json", user_start)
        start = time.monotonic()''')
source = source.replace('"script_error": b"SCRIPT ERROR" in stderr,', '"script_error": b"SCRIPT ERROR" in stderr, "name": name, "user_start": user_start,')
source = source.replace('if index in (0, 4)', 'if index in (0, 5)').replace('if index == 3 and', 'if index == 4 and')
source = source.replace('        dump(dirname / "process.json", result)', '''        observed = re.search(rb"^FIFTH_USER (.+)$", stdout, re.M)
        if observed is not None:
            result["user_probe"] = json.loads(observed[1])
        elif index == 0 and result.get("guard"):
            result["user_probe"] = {"dir": result["guard"]["user"], "initial_files": ["settings.cfg"] if result["guard"]["settings_at_start"] else []}
        result["expected_user"] = str(userdata)
        result["user_end"] = {p.relative_to(userdata).as_posix(): record(p) for p in userdata.rglob("*") if p.is_file()}
        dump(dirname / "process.json", result)''')
source = source.replace('ThreadPoolExecutor(4)', 'ThreadPoolExecutor(3)')
start = source.index("    assert all(r[\"exit\"]")
end = source.index('\nif sys.argv[1]', start)
source = source[:start] + """    for i, r in enumerate(results):
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
""" + source[end:]
(v3 / "run.py").write_text(source, encoding="utf8")
