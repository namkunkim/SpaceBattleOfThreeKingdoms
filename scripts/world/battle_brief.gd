class_name BattleBrief
extends RefCounted

# 천하 지도 → 전장 계약(docs/battle-core/WORLD-MAP-LINK.md §3).
# 전장은 이것만 받는다. anchor·edge_labels는 표시용이라 규칙에 영향이 없다.
# 같은 Brief(seed·difficulty·mode)면 같은 전투가 된다(결정성, tests/world_link.gd).

const PROFILE_DEF := "res://data/profiles/red_cliffs_rt.json"
const SCENARIO := "res://data/scenarios/red_cliffs_208_realtime.json"
const MODES := ["direct", "auto"]

# Mirrors the development composition root without loading its unfinished backend.
const Product := preload("res://scripts/first_operation_source_reference.gd")
const FIRST_OPERATION_V2_CAPABILITY := "pc/first-operation/2"
const FIRST_OPERATION_DEV_ARG := "--pc-first-operation-dev"
const FIRST_OPERATION_DEV_REQUEST := {
	"capability": "pc/first-operation-dev/1",
	"definition_id": "red-cliffs-first-operation-dev-v1",
	"definition_version": 1,
	"roster_id": "red-cliffs-dev-roster-v1",
	"seed": 208,
	"difficulty": "standard",
	"mode": "direct",
}

var scenario_id := "RED-CLIFFS-208-RT"
var seed := 0
var difficulty := "표준"
var mode := "direct"
var whatif_cards: Array = []   # M9(계략) 전까지 비어 있다. 카드 ID는 realtime_rules.what_if_cards
var anchor := {"system": "SYS-13", "region": "RGN-04", "body": "BODY-RGN-04-01"}
var edge_labels := {}

# Transient handoff. The legacy Brief serializer is used for legacy replays.
var _operation_request := {}

func select_first_operation_dev(route_id: String) -> void:
	_operation_request = FIRST_OPERATION_DEV_REQUEST.duplicate()
	_operation_request.route_id = route_id
	_operation_request.make_read_only()
	seed = _operation_request.seed
	mode = _operation_request.mode

func select_first_operation_product() -> void:
	_operation_request = Product.REQUEST
	seed = Product.REQUEST.seed
	difficulty = "표준"
	mode = Product.REQUEST.mode

func select_first_operation_v2() -> void:
	select_first_operation_product()
	_operation_request = _operation_request.duplicate()
	_operation_request.capability = FIRST_OPERATION_V2_CAPABILITY
	_operation_request.make_read_only()

func operation_route() -> String:
	if _operation_request.get("capability") in [Product.CAPABILITY, FIRST_OPERATION_V2_CAPABILITY]:
		return Product.ROUTE
	return _operation_request.get("route_id", "")

func operation_request() -> Dictionary:
	return _operation_request

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

# BattleSim이 받는 프로필(세 세력 자동 편성, Q83). 실패하면 빈 사전.
func profile() -> Dictionary:
	return Organization.load_auto(PROFILE_DEF, difficulty)

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
