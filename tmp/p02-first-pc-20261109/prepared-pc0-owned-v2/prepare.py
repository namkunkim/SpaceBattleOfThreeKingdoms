"""Freeze tracked HEAD inputs and a three-file diagnostic overlay. No engine invocation."""
import difflib
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
HEAD = "0be09755b70378286105972f35ac5b7031715664"
ENGINE = Path("C:/Tools/Godot")
HASHES = {
    "Godot_v4.7.2-stable_win64.exe": "ab1824f85bfd8e0e4128182c000c4003a3e042245b2967848d089b2a04b22424",
    "Godot_v4.7.2-stable_win64_console.exe": "c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643",
}
ROOTS = ("assets/", "core/", "data/", "hud/", "input/", "scenes/", "scripts/", "view/")
RUN = HERE.parent / "run-02"


def git(*args):
    return subprocess.check_output(["git", "-C", str(ROOT), *args])


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def blob(name):
    return git("show", f"{HEAD}:{name}")


def replace(text, anchor, insert):
    assert text.count(anchor) == 1, anchor
    return text.replace(anchor, insert)


def overlay():
    path = "scripts/battle_trace.gd"
    trace = blob(path).decode()
    trace = replace(trace, '\tlast_ui = ""\n', '\tlast_ui = ""\n\tpc0_reset()\n')
    trace = replace(trace, '\tvar row := {"v": 1', '\tif kind in ["command_request", "command_applied", "command_blocked"]:\n\t\tdata = pc0_command(host, data)\n\tvar row := {"v": 1')
    trace = replace(trace, '\tvar key := JSON.stringify(ui)', '\tpc0_sample(host, ui)\n\tvar key := JSON.stringify(ui)')
    trace += "\n" + (HERE / "trace-reader.gd.txt").read_text(encoding="utf-8")

    world_path = "view/world/world_map_screen.gd"
    world = blob(world_path).decode()
    seed = '\tb.seed = seed if seed >= 0 else randi() % 1000000\n'
    world = replace(world, seed, seed + '\tif seed < 0:\n\t\tb.seed = 777\n')
    show = 'func _show_result(o: BattleOutcome) -> void:\n'
    world = replace(world, show, show + '\tWorldLink.pc0_record("show_result_enter", o, {"scene": scene_file_path})\n')
    end = '\t\t\tcanvas.set_region_owners(world.outcome_owners.get(o.kind, _initial_owners()), true))\n'
    world = replace(world, end, end + '''\tWorldLink.pc0_record("show_result_display", o, {"state": state, "visible": _result.visible,
		"title": _res_labels.title.text, "ending": _res_labels.ending.text,
		"time": _res_labels.time.text, "loss_a": _res_labels.loss_a.text,
		"loss_f": _res_labels.loss_f.text, "eyebrow": _res_labels.eyebrow.text,
		"regions": _res_labels.regions.text})
''')

    link_path = "scripts/world_link.gd"
    link = blob(link_path).decode()
    link += '''
func _ready() -> void:
	pc0_record("clock_anchor", null)
'''
    publish = '\tget_tree().change_scene_to_file(WORLD_SCENE)\n'
    link = replace(link, publish, '\tpc0_record("publish", o)\n' + publish)
    take = '\treturn o\n'
    link = replace(link, take, '\tpc0_record("consume", o)\n' + take)
    link += '''
func pc0_record(kind: String, value: BattleOutcome, display := {}) -> void:
	var row := {"kind": kind, "mono_ms": Time.get_ticks_msec(), "utc_s": Time.get_unix_time_from_system(),
		"pid": OS.get_process_id(), "brief_null": brief == null,
		"queue_null": outcome == null, "payload": value.to_dict() if value else null,
		"display": display, "project": ProjectSettings.globalize_path("res://"),
		"user": ProjectSettings.globalize_path("user://")}
	print("PC0_LINK ", JSON.stringify(row))
'''
    return {path: trace, world_path: world, link_path: link}


def paths():
    return [p for p in git("ls-tree", "-r", "--name-only", "-z", HEAD).decode().split("\0")
            if p == "project.godot" or p.startswith(ROOTS)]


def git_state():
    baseline = json.loads((HERE.parent / "BASELINE.json").read_text(encoding="utf-8-sig"))
    result = {"head": git("rev-parse", "HEAD").decode().strip(),
              "branch": git("branch", "--show-current").decode().strip(),
              "index_sha": digest(Path(git("rev-parse", "--path-format=absolute", "--git-path", "index").decode().strip()).read_bytes()),
              "stage": git("diff", "--cached", "--name-only").decode().strip()}
    assert result["head"] == baseline["head"] and result["branch"] == baseline["branch"]
    assert result["index_sha"] == baseline["index_sha"].lower() and result["stage"] == baseline["stage"]
    result["protected"] = {}
    for record in baseline["inputs"]:
        name = record["path"]
        if name != "project.godot":
            actual = digest((ROOT / name).read_bytes())
            assert actual == record["sha256"].lower(), name
            result["protected"][name] = actual
    worker = "tests/p02_worker_adapter.gd"
    result["protected"][worker] = digest((ROOT / worker).read_bytes())
    result["protected"]["project.godot"] = digest((ROOT / "project.godot").read_bytes())
    return result


def freeze():
    assert not RUN.exists()
    before = git_state()
    for exe, expected in HASHES.items():
        assert digest((ENGINE / exe).read_bytes()) == expected, exe
    # Archive without git worktree/index writes. Git object IDs are listed separately.
    files = paths()
    file_set = set(files)
    source_rows = []
    missing = set()
    generated = set()
    provenance = set()
    overlay_map = overlay()
    patch = []
    for name in files:
        raw = blob(name)
        cooked = overlay_map[name].encode() if name in overlay_map else raw
        if name in overlay_map:
            patch.extend(difflib.unified_diff(raw.decode().splitlines(keepends=True),
                cooked.decode().splitlines(keepends=True), "a/" + name, "b/" + name))
        source_rows.append({"name": name, "sha256_head": digest(raw), "sha256_project": digest(cooked),
                            "bytes": len(cooked)})
        if name.endswith((".gd", ".tscn", ".tres", ".json", ".import", ".godot", ".cfg")):
            for token in re.findall(rb'res://([^"\s<>]+)', raw):
                target = token.decode("utf-8", errors="replace").rstrip("),.;")
                if target.startswith(".godot/") and name.endswith(".import"):
                    generated.add((name, target))
                    continue
                if "#" in target:
                    target = target.split("#", 1)[0]
                if name == "data/scenarios/base/red-cliffs-sensor-ew-rules.json" and target == "data/characters.json":
                    assert '"character_source": "res://data/characters.json#stats.' in raw.decode()
                    provenance.add((name, target))
                    continue
                if target == "assets/ships/silhouette/%d.png":
                    assert all(target % i in file_set for i in range(7))
                    continue
                if target and target not in file_set and not any(f.startswith(target.rstrip("/") + "/") for f in files):
                    missing.add((name, target))
    assert git_state() == before
    (HERE / "overlay.patch").write_bytes("".join(patch).encode())
    manifest = {"git": before, "engines": HASHES, "head": HEAD, "run": RUN.as_posix(),
                "source": source_rows, "generated_import_refs": sorted(generated),
                "nonruntime_provenance_refs": sorted(provenance),
                "unresolved_literal_refs": sorted(missing)}
    (HERE / "source-manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    freeze()
