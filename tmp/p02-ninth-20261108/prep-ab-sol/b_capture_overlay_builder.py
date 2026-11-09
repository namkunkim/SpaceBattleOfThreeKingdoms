"""Review-only WorldLink overlay with constructor-based button expectations."""
from difflib import unified_diff
from hashlib import sha256
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
DEST = Path(__file__).resolve().parent / "b-capture-review"
PATHS = ("tests/world_link.gd", "view/world/world_map_screen.gd",
         "hud/ui_kit/deck_screens.gd", "scripts/world/battle_brief.gd",
         "data/scenarios/red_cliffs_208_realtime.json", "input/touch/touch_metrics.gd")
HELPER = '''
func _k6_b_expected(s: Node, where: String) -> Array:
	if where == "전장 결과":
		var title: Button = s.title_btn
		return [title, title.get_parent().get_child(1)]
	var w := s as WorldMapScreen
	var nodes: Array = [w._crumbs["z0"], w._crumbs["z2"], w._crumbs["z3"]]
	match where:
		"Z0":
			# CTA's HBox contains the label followed by the action.
			nodes.append(w._cta.get_child(0).get_child(1))
		"카드":
			# Fixed scenario and constructor order, not derived from _buttons.
			for difficulty in ["입문", "표준", "상급", "극한"]:
				nodes.append(w._diff_btns[difficulty])
			nodes.append(w._mode_btns["direct"])
			nodes.append(w._mode_btns["auto"])
			nodes.append(w._card.get_child(0).get_child(-1))
		"결과 카드":
			var actions: Node = w._result.get_child(0).get_child(-1)
			for i in 3:
				nodes.append(actions.get_child(i))
		_:
			push_error("K6_B unknown stage: " + where)
	return nodes

func _k6_b_stream(stream: String, where: String, nodes: Array) -> void:
	var stages := {"Z0": "Z0", "카드": "card", "전장 결과": "battle-result", "결과 카드": "world-result"}
	var rows: Array = []
	for device in 3:
		for node in nodes:
			if not node is BaseButton or not node.is_visible_in_tree() or node.disabled:
				push_error("K6_B invalid constructor target: " + where)
				return
			rows.append({"path": str(node.get_path()), "device": device})
	print("K6_CAPTURE ", stream, " ", JSON.stringify({"stage": stages[where], "buttons": rows}))
'''
def overlay(text):
    old = "\t_buttons(s, btns)\n\tfor i in TouchMetrics.TOUCH_DEVICES:"
    if text.count(old) != 1:
        raise ValueError("unexpected WorldLink source")
    new = ('\t_buttons(s, btns)\n'
           '\t_k6_b_stream("b-expected", where, _k6_b_expected(s, where))\n'
           '\t_k6_b_stream("b-live", where, btns)\n'
           '\tfor i in TouchMetrics.TOUCH_DEVICES:')
    return text.replace(old, new) + HELPER

def main():
    DEST.mkdir(exist_ok=False)
    raw = [(ROOT / p).read_bytes() for p in PATHS]
    scenario = json.loads(raw[4])
    if scenario.get("difficulty_order", ["입문","표준","상급","극한"]) != ["입문","표준","상급","극한"]:
        raise ValueError("difficulty fixture drift")
    original = raw[0].decode("utf8").replace("\r\n", "\n")
    changed = overlay(original)
    (DEST / "world_link.gd").write_bytes(changed.encode("utf8"))
    delta = "".join(unified_diff(original.splitlines(keepends=True), changed.splitlines(keepends=True), "source/tests/world_link.gd", "overlay/tests/world_link.gd"))
    (DEST / "world_link.diff").write_bytes(delta.encode("utf8"))
    result = {
        "status": "REVIEW_ONLY_NON_EXECUTABLE",
        "sources": {p: sha256(b).hexdigest() for p,b in zip(PATHS, raw)},
        "overlay_sha256": sha256(changed.encode("utf8")).hexdigest(),
        "normalized_diff_sha256": sha256(delta.encode("utf8")).hexdigest(),
        "constructor_paths_expected_per_stage": [4,10,2,6],
        "devices": 3,
        "expected_total_assertions_including_static": 109,
    }
    (DEST / "SHA.json").write_bytes((json.dumps(result,indent=2)+"\n").encode("utf8"))

if __name__ == "__main__":
    main()
