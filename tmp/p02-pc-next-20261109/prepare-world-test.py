"""Stage the exact existing WorldLink test additions without running Godot."""
from pathlib import Path
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[1]
SOURCE = ROOT / "tests/world_link.gd"


def insert_once(source, old, new):
    if source.count(old) != 1:
        raise ValueError(f"Expected one test anchor: {old!r}")
    return source.replace(old, new, 1)


def patched_text():
    text = SOURCE.read_text(encoding="utf-8-sig")
    text = insert_once(text, "func _run() -> void:\n\t_data()", """func _run() -> void:
	if OS.get_cmdline_user_args().has("--direct-reject"):
		await _pc_reject()
		print("PC_DIRECT_REJECT_DONE ", fails)
		quit(0 if fails == 0 else 1)
		return
	if OS.get_cmdline_user_args().has("--direct-round-trip"):
		if not _pc_paths_match():
			quit(2)
			return
		await _round_trip(true)
		print("PC_DIRECT_ROUND_TRIP_DONE ", fails)
		quit(0 if fails == 0 else 1)
		return
	_data()""")
    text = insert_once(text, "func _round_trip() -> void:", "func _round_trip(pc_verify := false) -> void:")
    text = insert_once(text, """	s._skip.emit_signal("pressed")
	await _frames(8)
	var battle := current_scene""", """	var battle_entries := [0]
	var observe := func():
		if current_scene != null and current_scene.name == "FleetBattle3D":
			battle_entries[0] += 1
	if pc_verify:
		scene_changed.connect(observe)
	var outbound := s.brief
	var skip := s._skip
	skip.emit_signal("pressed")
	if pc_verify:
		_pc_check("C1", not s.is_inside_tree() and current_scene == null)
		skip.emit_signal("pressed")
	await _frames(8)
	if pc_verify:
		scene_changed.disconnect(observe)
		_pc_check("C2", battle_entries[0] == 1)
	var battle := current_scene""")
    text = insert_once(text, "\tvar deck = battle.presentation.hud", """	if pc_verify:
		_pc_check("C3", link.brief == outbound and outbound.seed == 777 and outbound.difficulty == "표준" and outbound.mode == "direct" and battle.battle_seed == 777)
	var deck = battle.presentation.hud""")
    text = insert_once(text, '\t_check(not link.routed() and link.outcome == null, "결과는 한 번만 넘긴다")', '''	_check(not link.routed() and link.outcome == null, "결과는 한 번만 넘긴다")
	if pc_verify:
		_pc_check("C4", w.outcome != null and link.take_outcome() == null and w.outcome.seed == 777)''')
    return text.rstrip() + "\n\n\n" + (BASE / "world-link-cases.gd.txt").read_text(encoding="utf-8-sig")


if __name__ == "__main__":
    target = Path(sys.argv[1]).resolve()
    if target.parent != BASE or target.name != "world-link-prepared.gd.txt":
        raise ValueError("Only the new evidence draft may be written")
    with target.open("x", encoding="utf-8", newline="\n") as f:
        f.write(patched_text())
