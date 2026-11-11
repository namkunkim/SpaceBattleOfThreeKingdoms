extends SceneTree

const Codec := preload("res://scripts/first_operation_replay_codec.gd")
var _checks := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file("res://scenes/WorldMap.tscn")
	await _frames()
	var map := current_scene as WorldMapScreen
	map.open_card()
	await _frames()
	var watch := map._card.find_child("WatchReplay", true, false) as Button
	var enabled := OS.get_cmdline_user_args().has("--pc-first-operation-dev")
	_check((watch != null) == enabled, "watch opt-in")
	if enabled:
		await _development(map, watch)
	print("FIRST_OPERATION_REPLAY_MAP %d/%d" % [_checks - _failed, _checks])
	quit(0 if _failed == 0 else 1)


func _development(map: WorldMapScreen, watch: Button) -> void:
	var original_size := root.size
	for size: Vector2i in [Vector2i(1600, 900), Vector2i(1920, 1030)]:
		root.size = size
		await _frames()
		var fits := true
		for action in ["ResumeSavedBattle", "ImportBattle", "WatchReplay"]:
			var button := map._card.find_child(action, true, false) as Button
			fits = fits and button != null and button.is_visible_in_tree() and root.get_visible_rect().encloses(button.get_global_rect())
		_check(fits and map._card.get_global_rect().end.x <= root.get_visible_rect().end.x,
			"browse card right edge and three actions fit %s" % size)
	root.size = original_size
	await _frames()
	var link := root.get_node("WorldLink")
	var old_lock := map.canvas.input_lock
	watch.grab_focus()
	watch.pressed.emit()
	_check(map._replay_dialog != null and map._replay_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE,
		"watch opens file picker")
	map.back()
	_check(map._replay_dialog == null and map.state == "browse" and map._card.visible and not link.routed(),
		"cancel keeps browse card and WorldLink")
	var path := ProjectSettings.globalize_path("user://").path_join("host-flank.pcopreplay")
	var corrupt := ProjectSettings.globalize_path("user://").path_join("damaged.pcopreplay")
	var file := FileAccess.open(corrupt, FileAccess.WRITE)
	file.store_string("damaged")
	file.close()
	watch.pressed.emit()
	map._replay_dialog.file_selected.emit(corrupt)
	_check(map._replay_overlay == null and map.state == "browse" and map._card.visible and map.hud.visible
		and map.canvas.input_lock == old_lock and not link.routed()
		and map._chip_label.text.begins_with("replay_invalid_json"), "damaged replay leaves browse state")
	map.find_child("FirstOperationDev_flank", true, false).pressed.emit()
	map._skip.pressed.emit()
	await _frames()
	var host := current_scene.get_node_or_null("FirstOperationHost")
	if not _check(host != null and host.operation_owner != null, "actual dev host"):
		return
	host._start.pressed.emit()
	host.set_process(false)
	host._commands[1].pressed.emit()
	for i in 1364:
		host.step_operation()
	host.find_child("Operation_withdraw", true, false).pressed.emit()
	for i in 516:
		host.step_operation()
	host.find_child("Operation_finalize_withdrawal", true, false).pressed.emit()
	host.step_operation()
	var outcome: BattleOutcome = host.settlement
	if not _check(outcome != null and outcome.kind == "withdrawal_success", "real host settles"):
		return
	var export_button := host.find_child("ExportReplay", true, false) as Button
	_check(export_button != null and export_button.visible, "export on real host")
	export_button.pressed.emit()
	if not _check(host._file_dialog != null, "export picker"):
		return
	host._file_dialog.file_selected.emit(path)
	var exported := Codec.read(path)
	if not _check(exported.ok and exported.bundle.expected_settlement.id == outcome.settlement_id,
		"same host-written file and settlement"):
		return
	var hash := FileAccess.get_sha256(path)
	host._return.pressed.emit()
	await _frames()
	map = current_scene as WorldMapScreen
	if not _check(map != null and map.state == "result" and map.outcome == outcome, "original battle returns once"):
		return
	var result_watch := map._result.find_child("WatchReplay", true, false) as Button
	_check(root.get_visible_rect().encloses(result_watch.get_global_rect()), "result watch fits")
	var map_lock := map.canvas.input_lock
	var old_brief: Variant = link.brief
	var old_outcome: Variant = link.outcome
	var old_difficulty: Variant = link.last_difficulty
	var old_mode: Variant = link.last_mode
	result_watch.pressed.emit()
	map._replay_dialog.file_selected.emit(path)
	if not _check(map._replay_overlay != null and not map.hud.visible and map.canvas.input_lock, "overlay isolates input"):
		return
	map.back()
	_check(map._replay_overlay == null and map.hud.visible and map.outcome == outcome and map.canvas.input_lock == map_lock,
		"cancel verification keeps result")
	result_watch.pressed.emit()
	map._replay_dialog.file_selected.emit(path)
	var viewer := map._replay_overlay.get_child(0)
	viewer.set_process(false)
	for i in 5000:
		if viewer._verification == null:
			break
		viewer._verify_slice()
	if not _check(not viewer._frame.is_empty() and viewer._frame.tick == 0, "same file verifies before tick zero"):
		return
	for i in int(exported.bundle.max_ticks):
		viewer.step_replay()
	_check(viewer._finished and viewer._result.text.contains(outcome.settlement_id)
		and viewer._result.text.contains(outcome.reason), "same file replays real host result")
	viewer._leave()
	await _frames()
	_check(current_scene == map and map.state == "result" and map._result.visible and map.outcome == outcome
		and map._res_labels.src.text == outcome.settlement_id and map.canvas.input_lock == map_lock
		and link.brief == old_brief and link.outcome == old_outcome
		and link.last_difficulty == old_difficulty and link.last_mode == old_mode, "close preserves original result and WorldLink")
	_check(FileAccess.get_sha256(path) == hash, "watch does not rewrite record")
	print("FIRST_OPERATION_REPLAY_MAP_FILE ", path, " ", outcome.settlement_id)
	var args := OS.get_cmdline_user_args()
	var selected := args.find("--actual-recording")
	if selected >= 0 and selected + 1 < args.size():
		await _actual_recording(map, result_watch, link, outcome, args[selected + 1])


func _actual_recording(map: WorldMapScreen, watch: Button, link: Node, outcome: BattleOutcome, path: String) -> void:
	var loaded := Codec.read(path)
	if not _check(loaded.ok, "Windows direct host record decodes"):
		return
	var expected: Dictionary = loaded.bundle.expected_settlement
	if not _check(expected.tick == 3275 and expected.kind == "withdrawal_success"
			and expected.reason == "withdrawal_conditions_met"
			and expected.id == "red-cliffs-first-operation-dev-v1/6e3b10928fcfce97bd50e4d704626566/settlement",
			"Windows direct host witness"):
		return
	var before := FileAccess.get_sha256(path)
	watch.pressed.emit()
	map._replay_dialog.file_selected.emit(path)
	if not _check(map._replay_overlay != null, "Windows record opens through map button"):
		return
	var viewer := map._replay_overlay.get_child(0)
	viewer.set_process(false)
	for i in 5000:
		if viewer._verification == null:
			break
		viewer._verify_slice()
	if not _check(not viewer._frame.is_empty() and viewer._frame.tick == 0, "Windows witness verifies"):
		return
	for i in int(expected.tick):
		viewer.step_replay()
	_check(viewer._finished and viewer._frame.tick == expected.tick and viewer._result.text.contains(expected.id)
		and viewer._result.text.contains(expected.reason), "Windows record reaches the identical settlement")
	map.back()
	await _frames()
	_check(current_scene == map and map.outcome == outcome and map._result.visible and not link.routed()
		and link.outcome == null and FileAccess.get_sha256(path) == before,
		"Windows record leaves unrelated displayed result and file untouched")
	print("FIRST_OPERATION_REPLAY_MAP_WINDOWS_FILE ", path, " ", expected.id)



func _frames() -> void:
	for i in 8:
		await process_frame


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failed += 1
		printerr("REPLAY_MAP_FAIL ", label)
	return ok

