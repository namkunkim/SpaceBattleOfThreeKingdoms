"""Generate review-only B observation overlay. Expected labels remain offline."""
from difflib import unified_diff
from hashlib import sha256
import json
from pathlib import Path

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[2]
DEST=HERE/"b-semantic-review"
PATHS=("tests/world_link.gd","scenes/WorldMap.tscn","view/world/world_map_screen.gd",
       "hud/ui_kit/deck_screens.gd","scripts/world/battle_brief.gd",
       "data/scenarios/red_cliffs_208_realtime.json","input/touch/touch_metrics.gd")
HELPER='''
func _k6_b_observe(where: String, device: int, ordinal: int, b: BaseButton) -> void:
	var stages := {"Z0":"Z0", "카드":"card", "전장 결과":"battle-result", "결과 카드":"world-result"}
	print("K6_B_SEMANTIC ", JSON.stringify({"stage":stages[where], "device":device,
		"ordinal":ordinal, "path":str(b.get_path()), "label":str(b.get("text")),
		"visible":b.is_visible_in_tree(), "enabled":not b.disabled}))
'''
old=('		for b in btns:\n' + '			var short := minf')
new=('		var k6_ordinal := 0\n' + '		for b in btns:\n' +
     '			_k6_b_observe(where, i, k6_ordinal, b)\n' + '			k6_ordinal += 1\n' + '			var short := minf')
if __name__=="__main__":
    DEST.mkdir(exist_ok=False)
    sources={name:(ROOT/name).read_bytes() for name in PATHS}
    prior=sources[PATHS[0]].decode("utf8").replace("\r\n","\n")
    if prior.count(old)!=1:
        raise ValueError("WorldLink capture source drift")
    changed=prior.replace(old,new)+HELPER
    source_out=DEST/"world_link.gd"
    source_out.write_bytes(changed.encode("utf8"))
    diff=DEST/"world_link.diff"
    diff.write_bytes("".join(unified_diff(prior.splitlines(keepends=True),changed.splitlines(keepends=True),"source","overlay")).encode("utf8"))
    digest=lambda p:sha256(p.read_bytes()).hexdigest()
    report=dict(status="REVIEW_ONLY_NON_EXECUTABLE", sources={k:sha256(v).hexdigest() for k,v in sources.items()},overlay_sha256=digest(source_out),diff_sha256=digest(diff),semantic_oracle_sha256=digest(HERE/"b_semantic_oracle.py"))
    (DEST/"SHA.json").write_bytes((json.dumps(report,indent=2)+"\n").encode("utf8"))
