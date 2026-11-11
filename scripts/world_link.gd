extends Node

# 천하 지도 ↔ 전장 장면 전환(autoload "WorldLink", docs/battle-core/WORLD-MAP-LINK.md §3).

const Product := preload("res://scripts/first_operation_source_reference.gd")
const OperationHost := preload("res://scripts/first_operation_host.gd")
const Settlements := preload("res://scripts/first_operation_settlement_store.gd")
const DurableO07 := preload("res://scripts/o07_supply_owner.gd")
const WORLD_SCENE := "res://scenes/WorldMap.tscn"
const BATTLE_SCENE := "res://scenes/FleetBattle3D.tscn"

var brief: BattleBrief = null       # 진행 중인 전투의 명세. 천하 지도에서 들어오지 않은 전투면 null
var outcome: BattleOutcome = null   # 천하 지도가 아직 보여 주지 않은 결과
var last_difficulty := "표준"
var last_mode := "direct"

enum ReturnReason { NORMAL, INITIAL_PREPARE_FAILED }

var _sortie_origin := {}
var _map_restore := {}
var _previous_pending_outcome: BattleOutcome
var _prepared_restore: RefCounted
var _settlement_boot_checked := false
var _entry_restore := false

func take_entry_restore() -> bool:
	var pending := _entry_restore
	_entry_restore = false
	return pending

func routed() -> bool:
	return brief != null

func go_battle(b: BattleBrief, map_origin: Dictionary = {}, prepared_restore: RefCounted = null) -> Error:
	var request := b.operation_request()
	if not request.is_empty():
		if request.get("capability") == Product.CAPABILITY:
			if request != Product.REQUEST or b.seed != Product.REQUEST.seed or b.difficulty != "표준" \
					or b.mode != "direct" or b.scenario_id != "RED-CLIFFS-208-RT" or not b.whatif_cards.is_empty():
				return ERR_UNAVAILABLE
		elif not OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG) \
				or request.get("capability") != BattleBrief.FIRST_OPERATION_DEV_REQUEST.capability \
				or request.get("route_id") not in ["front", "flank"]:
			return ERR_UNAVAILABLE
	var previous_brief := brief
	var previous_outcome := outcome
	var previous_difficulty := last_difficulty
	var previous_mode := last_mode
	brief = b
	outcome = null
	last_difficulty = b.difficulty
	last_mode = b.mode
	var error := _request_scene(BATTLE_SCENE)
	if error != OK:
		brief = previous_brief
		outcome = previous_outcome
		last_difficulty = previous_difficulty
		last_mode = previous_mode
	else:
		_settlement_boot_checked = true
		_sortie_origin = map_origin
		_prepared_restore = prepared_restore
		_previous_pending_outcome = previous_outcome
		_map_restore = {}
	return error

# 전장에서 천하로 돌아온다. o가 null이면 전투를 끝내지 않고 나온 것이다.
func back_to_world(o: BattleOutcome, reason := ReturnReason.NORMAL) -> Error:
	# Product candidate outcomes return to the map without using the dev ledger.
	var product_operation := brief != null and brief.operation_request() == Product.REQUEST
	if o != null and not o.settlement_id.is_empty() and not product_operation:
		var published := publish_operation_settlement(o)
		if not published.ok:
			push_warning("WORLD_SETTLEMENT_REJECTED %s" % published.error)
			return ERR_CANT_CREATE
		if not published.applied:
			o = published.outcome
	var previous_brief := brief
	var previous_outcome := outcome
	outcome = o
	brief = null
	var restore_entry := reason == ReturnReason.INITIAL_PREPARE_FAILED and bool(_sortie_origin.get("entry", false))
	var error := _request_scene("res://scenes/entry/EntryBoot.tscn" if restore_entry else WORLD_SCENE)
	if error != OK:
		brief = previous_brief
		outcome = previous_outcome
		push_warning("WORLD_RETURN_REJECTED error=%d" % error)
	else:
		_entry_restore = restore_entry
		if restore_entry:
			outcome = _previous_pending_outcome
		elif reason == ReturnReason.INITIAL_PREPARE_FAILED and not _sortie_origin.is_empty():
			_map_restore = _sortie_origin
			outcome = _previous_pending_outcome
			last_difficulty = _sortie_origin.difficulty
			last_mode = _sortie_origin.mode
		_sortie_origin = {}
		_previous_pending_outcome = null
	return error

func publish_operation_settlement(o: BattleOutcome) -> Dictionary:
	if not OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG):
		return {"ok": false, "error": "settlement_capability_disabled", "path": "settlement"}
	var result := Settlements.consume(o)
	if result.ok:
		_settlement_boot_checked = true
	return result

func restore_operation_settlement() -> Dictionary:
	if _settlement_boot_checked:
		return {"ok": true, "outcome": null}
	var args := OS.get_cmdline_user_args()
	var path := Settlements.SLOT_PATH
	if not args.has(BattleBrief.FIRST_OPERATION_DEV_ARG):
		if args.has(DurableO07.HOST_ARG) or not OperationHost.product_save_supported():
			return {"ok": true, "outcome": null}
		path = Settlements.PRODUCT_SLOT_PATH
	# Recover the stored display result without consuming the settlement again.
	var restored := Settlements.restore_latest(path)
	if restored.ok:
		_settlement_boot_checked = true
		if path == Settlements.PRODUCT_SLOT_PATH and restored.outcome != null:
			restored.outcome.is_product_operation = true
	return restored

func show_native_o07_settlement(verified: BattleOutcome) -> Error:
	if not DurableO07.HOST_ARG in OS.get_cmdline_user_args() or verified == null or verified.mode != "o07_native":
		return ERR_UNAVAILABLE
	var previous := outcome
	outcome = verified
	var error := _request_scene(WORLD_SCENE)
	if error != OK:
		outcome = previous
	return error

func restore_native_o07_settlement() -> Dictionary:
	if not DurableO07.HOST_ARG in OS.get_cmdline_user_args():
		return {"ok": true, "outcome": null}
	return DurableO07.read_terminal_outcome(DurableO07.HOST_SLOT)

func _request_scene(path: String) -> Error:
	return get_tree().change_scene_to_file(path)

func take_prepared_restore() -> RefCounted:
	var candidate := _prepared_restore
	_prepared_restore = null
	return candidate

func take_map_restore() -> Dictionary:
	var restore := _map_restore
	_map_restore = {}
	return restore

# 천하 지도가 결과를 한 번 가져간다.
func take_outcome() -> BattleOutcome:
	var o := outcome
	outcome = null
	return o
