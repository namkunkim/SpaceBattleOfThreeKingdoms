class_name BattleBrief
extends RefCounted

# 천하 지도 → 전장 계약(docs/battle-core/WORLD-MAP-LINK.md §3).
# 전장은 이것만 받는다. anchor·edge_labels는 표시용이라 규칙에 영향이 없다.
# 같은 Brief(seed·difficulty·mode)면 같은 전투가 된다(결정성, tests/world_link.gd).

const PROFILE_DEF := "res://data/profiles/red_cliffs_rt.json"
const SCENARIO := "res://data/scenarios/red_cliffs_208_realtime.json"
const MODES := ["direct", "auto"]

var scenario_id := "RED-CLIFFS-208-RT"
var seed := 0
var difficulty := "표준"
var mode := "direct"
var whatif_cards: Array = []   # M9(계략) 전까지 비어 있다. 카드 ID는 realtime_rules.what_if_cards
var anchor := {"system": "SYS-13", "region": "RGN-04", "body": "BODY-RGN-04-01"}
var edge_labels := {}

static func difficulties() -> Array:
	var scn := ProfileLoader.read_json(SCENARIO)
	return scn.get("difficulty_order", ["입문", "표준", "상급", "극한"])

static func difficulty_note(name: String) -> String:
	var scn := ProfileLoader.read_json(SCENARIO)
	return str(scn.get("difficulty_profiles", {}).get(name, {}).get("note", ""))

static func what_if_cards() -> Array:
	var scn := ProfileLoader.read_json(SCENARIO)
	return scn.get("realtime_rules", {}).get("what_if_cards", [])

func validate() -> String:
	if not MODES.has(mode):
		return "알 수 없는 지휘 방식: %s" % mode
	if not difficulties().has(difficulty):
		return "알 수 없는 난이도: %s" % difficulty
	if not whatif_cards.is_empty():
		return "what-if 카드는 M9 이후에 쓸 수 있다"
	return ""

# BattleSim이 받는 프로필. 실패하면 빈 사전.
func profile() -> Dictionary:
	return ScenarioProfile.load_profile(PROFILE_DEF, difficulty)

func to_dict() -> Dictionary:
	return {"scenario_id": scenario_id, "seed": seed, "difficulty": difficulty, "mode": mode,
		"whatif_cards": whatif_cards.duplicate(), "anchor": anchor.duplicate(), "edge_labels": edge_labels.duplicate()}

static func from_dict(d: Dictionary) -> BattleBrief:
	var b := BattleBrief.new()
	b.scenario_id = str(d.get("scenario_id", b.scenario_id))
	b.seed = int(d.get("seed", 0))
	b.difficulty = str(d.get("difficulty", b.difficulty))
	b.mode = str(d.get("mode", b.mode))
	b.whatif_cards = (d.get("whatif_cards", []) as Array).duplicate()
	b.anchor = (d.get("anchor", b.anchor) as Dictionary).duplicate()
	b.edge_labels = (d.get("edge_labels", {}) as Dictionary).duplicate()
	return b
