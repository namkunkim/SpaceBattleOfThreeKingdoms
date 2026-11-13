extends SceneTree

const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")

var _fails := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(ok: bool, message: String) -> bool:
	if not ok:
		_fails += 1
		push_error("AUTO_MAP_FAIL " + message)
	return ok

func _frames() -> void:
	for i in 8:
		await process_frame

func _run() -> void:
	change_scene_to_file("res://scenes/WorldMap.tscn")
	await _frames()
	await _verify_map(current_scene as WorldMapScreen)
	print("FIRST_OPERATION_AUTO_MAP_%s failures=%d" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)

func _verify_map(map: WorldMapScreen) -> void:
	map.open_card()
	map.canvas.jump_to("z2")
	await _frames()
	var front := map._card.find_child("FirstOperationAuto_front", true, false) as Button
	var flank := map._card.find_child("FirstOperationAuto_flank", true, false) as Button
	var enabled := OS.get_cmdline_user_args().has("--pc-first-operation-dev")
	if not _check((front != null and flank != null) == enabled, "automatic buttons require development flag"):
		return
	if not enabled:
		map._start_operation_auto("front")
		_check(map.state == "browse" and map._operation_worker == null, "legacy map rejects direct automatic invocation")
		return
	var original_size := root.size
	for size: Vector2i in [Vector2i(1600, 900), Vector2i(1920, 1030)]:
		root.size = size
		await _frames()
		_check(root.get_visible_rect().encloses(front.get_global_rect())
			and root.get_visible_rect().encloses(flank.get_global_rect()), "both automatic actions fit %s" % size)
	root.size = original_size
	await _frames()
	var link := root.get_node("WorldLink")
	var prior := map.make_brief(99)
	var pending := BattleOutcome.new()
	link.brief = prior
	link.outcome = pending
	map.brief = prior

	front.pressed.emit()
	var cancelled_worker: RefCounted = map._operation_worker
	if not _check(cancelled_worker != null and map.state == "resolve" and map._resolve.visible and map.canvas.input_lock, "real map button starts worker"):
		return
	flank.pressed.emit()
	_check(map._operation_worker == cancelled_worker, "duplicate map action does not replace worker")
	map.find_child("CancelAutoResolve", true, false).pressed.emit()
	await _wait_worker(map)
	_check(current_scene == map and map.state == "browse" and map._card.visible and not map.canvas.input_lock
		and map.brief == prior and map.outcome == null and link.outcome == pending
		and cancelled_worker.poll().status == "idle", "cancel and join restore original card and pending outcome")

	var lock_path := Ledger.SLOT_PATH + Ledger.LOCK_SUFFIX
	var retry := map.find_child("RetryAutoSettlement", true, false) as Button
	for route in ["front", "flank"]:
		if route == "flank":
			_check(DirAccess.make_dir_absolute(lock_path) == OK, "hold settlement slot for completed worker")
		(front if route == "front" else flank).pressed.emit()
		var worker: RefCounted = map._operation_worker
		if not _check(worker != null and map.brief.operation_request().mode == "direct", "auto worker receives direct request"):
			return
		var progress := await _wait_worker(map)
		var expected_kind := "objective_success" if route == "front" else "withdrawal_success"
		var expected_reason := "objective_conditions_met" if route == "front" else "withdrawal_conditions_met"
		var expected_time := 548.7 if route == "front" else 215.1
		var pending_id := ""
		if route == "flank":
			pending_id = _exercise_settlement_retry(map, retry, lock_path)
		var outcome := map.outcome
		if not _check(outcome != null and current_scene == map and map.state == "result" and map._result.visible
				and outcome.kind == expected_kind and outcome.reason == expected_reason and outcome.mode == "auto"
				and is_equal_approx(outcome.t_s, expected_time) and map.outcome.settlement_id == outcome.settlement_id
				and not outcome.settlement_id.is_empty() and progress > 0, "automatic route publishes its joined settlement"):
			return
		if route == "flank":
			_check(outcome.settlement_id == pending_id, "successful retry publishes original id")
			var committed := FileAccess.get_file_as_bytes(Ledger.SLOT_PATH)
			retry.pressed.emit()
			_check(not retry.visible and FileAccess.get_file_as_bytes(Ledger.SLOT_PATH) == committed,
				"stale retry signal cannot publish twice")
		await _frames()
		_check(map.outcome == outcome and worker.poll().status == "idle" and link.outcome == pending,
			"no second publication or WorldLink outcome consumption")
		print("FIRST_OPERATION_AUTO_MAP_ROUTE %s %s %s time=%.1f" % [route, outcome.kind, outcome.reason, outcome.t_s])
		if route == "front":
			map._result_to_world()
			map.open_card()
			map.canvas.jump_to("z2")
			await _frames()

	var displayed := map.outcome
	map._start_operation_auto("unsupported")
	await _wait_worker(map)
	_check(map.state == "result" and map._result.visible and map.outcome == displayed and not map.canvas.input_lock
		and map._chip_label.text.begins_with("unsupported_route"), "worker failure restores displayed result")
	map._result_to_world()
	map.open_card()
	map.canvas.jump_to("z2")
	front.pressed.emit()
	var exiting: RefCounted = map._operation_worker
	change_scene_to_file("res://scenes/WorldMap.tscn")
	await _frames()
	_check(exiting != null and exiting.poll().status == "idle" and exiting._thread == null,
		"leaving the actual map scene cancels and joins worker")
	await _exercise_pending_cancel_and_exit(current_scene as WorldMapScreen, lock_path)


func _exercise_settlement_retry(map: WorldMapScreen, retry: Button, lock_path: String) -> String:
	var pending := map._operation_auto_pending
	var previous := map.outcome
	var path := Ledger.SLOT_PATH
	var original := FileAccess.get_file_as_bytes(path)
	if not _check(pending != null and retry.is_visible_in_tree() and map.canvas.input_lock
			and map.state == "resolve" and map._operation_auto_save_error.begins_with("settlement_slot_busy"),
			"busy worker preserves its terminal result and exposes retry"):
		DirAccess.remove_absolute(lock_path)
		return ""
	var id := pending.settlement_id
	retry.pressed.emit()
	_check(map._operation_auto_pending == pending and map.outcome == previous
		and FileAccess.get_file_as_bytes(path) == original, "repeated busy preserves the same object and prior result")
	_check(DirAccess.remove_absolute(lock_path) == OK, "release competing writer fixture")
	_check(FileAccess.open(path, FileAccess.WRITE).store_string("broken"), "persistent storage error fixture")
	retry.pressed.emit()
	_check(map._operation_auto_pending == pending and map.outcome == previous and retry.visible
		and map._operation_auto_save_error.begins_with("invalid_envelope")
		and FileAccess.get_file_as_string(path) == "broken", "persistent error keeps pending result and prior map state")
	_check(FileAccess.open(path, FileAccess.WRITE).store_buffer(original), "restore valid ledger fixture")
	retry.pressed.emit()
	return id


func _exercise_pending_cancel_and_exit(map: WorldMapScreen, lock_path: String) -> void:
	var bytes := FileAccess.get_file_as_bytes(Ledger.SLOT_PATH)
	var prior := map.outcome
	var brief := map.brief
	var previous_state := map.state
	var previous_result_visible := map._result.visible
	for leave in [false, true]:
		_check(DirAccess.make_dir_absolute(lock_path) == OK, "hold slot for cancellation fixture")
		map._start_operation_auto("flank")
		await _wait_worker(map)
		_check(map._operation_auto_pending != null, "joined worker awaits publication")
		if leave:
			change_scene_to_file("res://scenes/WorldMap.tscn")
			await _frames()
		else:
			map.find_child("CancelAutoResolve", true, false).pressed.emit()
			_check(map.state == previous_state and map.brief == brief and map.outcome == prior
				and map._result.visible == previous_result_visible
				and map._operation_auto_pending == null and not map.canvas.input_lock
				and not map._resolve.visible, "cancel pending result restores previous map state")
		_check(DirAccess.remove_absolute(lock_path) == OK, "release cancellation lock")
		_check(FileAccess.get_file_as_bytes(Ledger.SLOT_PATH) == bytes, "cancel or scene exit does not publish pending result")


func _wait_worker(map: WorldMapScreen) -> int:
	var latest := 0
	var deadline := Time.get_ticks_msec() + 45000
	while map._operation_worker != null and Time.get_ticks_msec() < deadline:
		latest = int(map._operation_auto_progress.tick)
		await process_frame
	_check(map._operation_worker == null, "map worker joined within test limit")
	return latest

