extends SceneTree

const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const SLOT := "user://settlement-regression.save"
const FIRST := "red-cliffs-first-operation-dev-v1/11111111111111111111111111111111/settlement"
const SECOND := "red-cliffs-first-operation-dev-v1/22222222222222222222222222222222/settlement"
const THIRD := "red-cliffs-first-operation-dev-v1/33333333333333333333333333333333/settlement"
class RejectingLink extends "res://scripts/world_link.gd":
	var requested_error := ERR_CANT_OPEN

	func _request_scene(_path: String) -> Error:
		return requested_error


var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := _outcome(FIRST, "withdrawal_success", "withdrawal_conditions_met", "direct", 215100)
	var second := _outcome(SECOND, "objective_success", "objective_conditions_met", "auto", 548700)
	var args := OS.get_cmdline_user_args()
	if "--seed-map" in args:
		_seed_map(first, second)
		_finish("MAP_SAVE")
		return
	if "--verify-map" in args:
		await _verify_map(first, second)
		_finish("MAP_REOPEN")
		return
	var reopening := "--verify-restart" in args
	if reopening:
		_check(_matches(Ledger.restore_latest(SLOT), second), "fresh process restores exact latest settlement")
		var original := FileAccess.get_file_as_bytes(SLOT)
		var duplicate := Ledger.consume(first, SLOT)
		_check(_matches(duplicate, second) and duplicate.get("applied") == false, "older duplicate does not roll back latest")
		_check(FileAccess.get_file_as_bytes(SLOT) == original, "older duplicate leaves ledger bytes intact")
		first.reason = "conflicting_reason"
		_check(Ledger.consume(first, SLOT).get("error") == "settlement_id_conflict"
			and _matches(Ledger.restore_latest(SLOT), second), "conflicting old id preserves latest")
	else:
		_check(Ledger.restore_latest(SLOT) == {"ok": true, "outcome": null}, "empty ledger")
		var first_commit := Ledger.consume(first, SLOT)
		_check(_matches(first_commit, first) and first_commit.get("applied") == true, "commit first settlement")
		var duplicate := Ledger.consume(first, SLOT)
		_check(_matches(duplicate, first) and duplicate.get("applied") == false, "exact duplicate")
		var second_commit := Ledger.consume(second, SLOT)
		_check(_matches(second_commit, second) and second_commit.get("applied") == true, "commit next settlement")
		_check(_matches(Ledger.restore_latest(SLOT), second), "restore latest settlement")
		_failure_cases(first, second)
	_finish("REOPEN" if reopening else "SAVE")


func _finish(lane: String) -> void:
	print("FIRST_OPERATION_SETTLEMENT %s %d/%d" % [lane, checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _seed_map(first: BattleOutcome, second: BattleOutcome) -> void:
	var rejecting := RejectingLink.new()
	var brief := BattleBrief.new()
	brief.select_first_operation_dev("flank")
	rejecting.brief = brief
	var pending := BattleOutcome.new()
	rejecting.outcome = pending
	_check(rejecting.back_to_world(first) == ERR_CANT_OPEN and rejecting.brief == brief and rejecting.outcome == pending,
		"scene rejection keeps the active route and previous outcome")
	_check(_matches(Ledger.restore_latest(), first), "accepted settlement survives scene rejection")
	var committed := FileAccess.get_file_as_bytes(Ledger.SLOT_PATH)
	rejecting.requested_error = OK
	_check(rejecting.back_to_world(first) == OK and rejecting.brief == null
		and rejecting.outcome.to_dict() == first.to_dict() and FileAccess.get_file_as_bytes(Ledger.SLOT_PATH) == committed,
		"same id retries scene handoff without rewriting the committed settlement")
	rejecting.free()
	var link := root.get_node("WorldLink")
	link.brief = brief
	_check(link.back_to_world(first) == OK, "direct return hands off to the actual map")
	_check(_matches(link.publish_operation_settlement(second), second), "shared WorldLink publisher advances latest")


func _verify_map(first: BattleOutcome, second: BattleOutcome) -> void:
	change_scene_to_file("res://scenes/WorldMap.tscn")
	for frame in 8:
		await process_frame
	var map := current_scene as WorldMapScreen
	_check(map != null and map.state == "result" and map._result.visible
		and map.outcome.to_dict() == second.to_dict()
		and map._res_labels.src.text == second.settlement_id and map._res_labels.ending.text == second.reason,
		"fresh map renders durable settlement ID and reason")
	var link := root.get_node("WorldLink")
	var duplicate: Dictionary = link.publish_operation_settlement(first)
	_check(_matches(duplicate, second) and duplicate.get("applied") == false, "old direct retry preserves latest auto settlement")
	var brief := BattleBrief.new()
	link.brief = brief
	var pending := BattleOutcome.new()
	link.outcome = pending
	first.reason = "conflicting_reason"
	_check(link.back_to_world(first) != OK and current_scene == map and link.brief == brief
		and link.outcome == pending and map.outcome.to_dict() == second.to_dict(), "rejected return preserves scene and routing state")


func _failure_cases(first: BattleOutcome, second: BattleOutcome) -> void:
	var third := _outcome(THIRD, "failure", "time_limit", "auto", 1200000)
	var original := FileAccess.get_file_as_bytes(SLOT)
	var locked := SLOT + Ledger.LOCK_SUFFIX
	_check(DirAccess.make_dir_absolute(locked) == OK, "held lock fixture")
	_check(Ledger.consume(third, SLOT).get("error") == "settlement_slot_busy"
		and Ledger.restore_latest(SLOT).get("error") == "settlement_slot_busy"
		and FileAccess.get_file_as_bytes(SLOT) == original and DirAccess.dir_exists_absolute(locked),
		"held lock fails closed and preserves the published ledger")
	_check(DirAccess.remove_absolute(locked) == OK, "fixture owner releases lock")
	var retry := Ledger.consume(second, SLOT)
	_check(_matches(retry, second) and retry.get("applied") == false
		and FileAccess.get_file_as_bytes(SLOT) == original, "retry after release sees the committed ledger")
	var block := "user://settlement-blocked"
	_check(DirAccess.make_dir_absolute(block) == OK, "blocked publication fixture")
	_check(not Ledger.consume(third, block).ok and FileAccess.get_file_as_bytes(SLOT) == original,
		"write failure leaves the good ledger untouched")
	var corrupt := "user://settlement-corrupt.save"
	_check(FileAccess.open(corrupt, FileAccess.WRITE).store_string("broken"), "corrupt envelope fixture")
	_check(not Ledger.consume(third, corrupt).ok and not Ledger.restore_latest(corrupt).ok
		and FileAccess.get_file_as_string(corrupt) == "broken", "invalid envelope is never overwritten")
	var pending := "user://settlement-interrupted.save"
	_check(_matches(Ledger.consume(first, pending), first), "interrupted publication setup")
	_check(DirAccess.rename_absolute(pending, pending + Store.PREVIOUS) == OK, "simulate interruption before publish")
	_check(_matches(Ledger.restore_latest(pending), first), "recover previous committed ledger")
	_check(_matches(Ledger.consume(second, pending), second), "commit after recovery")
	var duplicate := Ledger.consume(first, pending)
	_check(_matches(duplicate, second) and duplicate.get("applied") == false, "recovery preserves prior consumption history")


func _outcome(id: String, kind: String, reason: String, mode: String, clock_ms: int) -> BattleOutcome:
	var outcome := BattleOutcome.new()
	outcome.settlement_id = id
	outcome.kind = kind
	outcome.reason = reason
	outcome.win = kind != "failure"
	outcome.t_s = clock_ms / 1000.0
	outcome.seed = 208
	outcome.mode = mode
	outcome.difficulty = "standard"
	return outcome


func _matches(result: Dictionary, expected: BattleOutcome) -> bool:
	return result.ok and result.outcome != null and result.outcome.to_dict() == expected.to_dict()


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("SETTLEMENT_FAIL ", label)
