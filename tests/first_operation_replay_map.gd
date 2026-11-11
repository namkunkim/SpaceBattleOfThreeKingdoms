extends SceneTree

const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const OperationHost := preload("res://scripts/first_operation_host.gd")
const Settlements := preload("res://scripts/first_operation_settlement_store.gd")
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
	var watch_available := enabled or OS.has_feature("windows")
	if _check((watch != null and watch.is_visible_in_tree()) == watch_available, "watch available in browse"):
		if enabled:
			await _development(map, watch)
		elif watch_available:
			await _product(map, watch)
	print("FIRST_OPERATION_REPLAY_MAP %d/%d" % [_checks - _failed, _checks])
	quit(0 if _failed == 0 else 1)


func _product(map: WorldMapScreen, watch: Button) -> void:
	var folder := ProjectSettings.globalize_path("user://")
	var record_path := folder.path_join("approved-front.pcopreplay")
	var original_lock := map.canvas.input_lock
	watch.grab_focus()
	watch.pressed.emit()
	if not _check(map._replay_dialog != null, "product watch opens picker without dev flag"):
		return
	map.back()
	await _frames()
	_check(map._replay_dialog == null and map._card.visible and watch.has_focus(),
		"cancel restores browse focus")

	var corrupt_path := folder.path_join("corrupt-product.pcopreplay")
	var corrupt := FileAccess.open(corrupt_path, FileAccess.WRITE)
	if not _check(corrupt != null, "write malformed replay fixture"):
		return
	corrupt.store_string("damaged")
	corrupt.close()
	watch.pressed.emit()
	map._replay_dialog.file_selected.emit(corrupt_path)
	await _frames()
	_check(map._replay_overlay == null and map.state == "browse" and map.hud.visible
		and map.canvas.input_lock == original_lock and watch.has_focus()
		and map._chip_label.text.begins_with("replay_invalid_json"), "invalid file restores browse state")

	map._product_sortie.pressed.emit()
	map._skip.pressed.emit()
	await _frames()
	var host := current_scene.get_node_or_null("FirstOperationHost")
	if not _check(host != null and host.operation_owner != null, "approved product host opens"):
		return
	host._start.pressed.emit()
	host.set_process(false)
	host._commands[1].pressed.emit()
	var sent_c := false
	for tick in 12000:
		if not sent_c and host.frame.projection.operation.sites.A.active:
			host._commands[2].pressed.emit()
			sent_c = true
		if not host.step_operation():
			break
		if tick == 112 and OperationHost.product_save_supported():
			host._save.pressed.emit()
	var outcome: BattleOutcome = host.settlement
	if not _check(sent_c and outcome != null and outcome.kind == "objective_success", "approved product host settles"):
		return
	var export_button := host.find_child("ExportReplay", true, false) as Button
	if not _check(export_button != null and export_button.visible, "completed product host offers replay export"):
		return
	export_button.pressed.emit()
	if not _check(host._file_dialog != null, "product replay export picker opens"):
		return
	host._file_dialog.file_selected.emit(record_path)
	var exported := Codec.read(record_path)
	if not _check(exported.ok and exported.bundle.expected_settlement.id == outcome.settlement_id,
		"product export contains actual settlement"):
		return

	host._return.pressed.emit()
	await _frames()
	map = current_scene as WorldMapScreen
	if not _check(map != null and map.state == "result" and map.outcome == outcome, "product host returns with its settlement"):
		return
	var result_watch := map._result.find_child("WatchReplay", true, false) as Button
	if not _check(result_watch != null and result_watch.is_visible_in_tree()
		and root.get_visible_rect().encloses(result_watch.get_global_rect()), "product watch available in result"):
		return
	var link := root.get_node("WorldLink")
	var old_link_brief: Variant = link.brief
	var old_link_outcome: Variant = link.outcome
	var map_lock := map.canvas.input_lock
	var record_hash := FileAccess.get_sha256(record_path)
	var slot_hash := FileAccess.get_sha256(OperationHost.PRODUCT_SLOT_PATH)
	var ledger_hash := FileAccess.get_sha256(Settlements.PRODUCT_SLOT_PATH)
	if OperationHost.product_save_supported():
		_check(not slot_hash.is_empty() and not ledger_hash.is_empty(), "product save and settlement ledger exist")

	var development: Dictionary = exported.bundle.duplicate(true)
	development.request = BattleBrief.FIRST_OPERATION_DEV_REQUEST.duplicate()
	development.request.route_id = "front"
	var development_path := folder.path_join("development.pcopreplay")
	if _check(Codec.write(development, development_path).ok and Codec.read(development_path).ok,
		"development replay passes the file codec"):
		_reject_result_replay(map, result_watch, development_path, "replay_unsupported_capability")

	var unsupported: Dictionary = exported.bundle.duplicate(true)
	unsupported.request.seed += 1
	var unsupported_path := folder.path_join("unsupported-seed.pcopreplay")
	var forged := FileAccess.open(unsupported_path, FileAccess.WRITE)
	if _check(forged != null, "write forged product replay fixture"):
		var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(record_path))
		var body := JSON.stringify(unsupported, "", true, true)
		forged.store_string(Codec._envelope(body, envelope.rules_digest))
		forged.close()
		_reject_result_replay(map, result_watch, unsupported_path, "unapproved_operation_request")

	result_watch.grab_focus()
	result_watch.pressed.emit()
	map._replay_dialog.file_selected.emit(record_path)
	if not _check(map._replay_overlay != null and map.canvas.input_lock and not map.hud.visible,
		"product replay isolates the result screen"):
		return
	var viewer := map._replay_overlay.get_child(0)
	_check(viewer._frame.is_empty(), "verification keeps frames private")
	viewer.set_process(false)
	for i in int(exported.bundle.max_ticks) + 1:
		if viewer._verification == null:
			break
		viewer._verify_slice()
	if not _check(not viewer._frame.is_empty() and viewer._frame.tick == 0, "verified product replay starts at tick zero"):
		return
	for i in int(exported.bundle.max_ticks):
		viewer.step_replay()
	_check(viewer._finished and viewer._result.text.contains(outcome.settlement_id)
		and viewer._result.text.contains(outcome.reason), "product replay reaches original settlement")
	viewer._leave()
	await _frames()
	_check(map._replay_overlay == null and map._result.visible and map.outcome == outcome
		and map.canvas.input_lock == map_lock and result_watch.has_focus() and map.hud.visible
		and link.brief == old_link_brief and link.outcome == old_link_outcome and not link.routed(),
		"close restores original product result, focus, and WorldLink")
	_check(FileAccess.get_sha256(record_path) == record_hash
		and FileAccess.get_sha256(OperationHost.PRODUCT_SLOT_PATH) == slot_hash
		and FileAccess.get_sha256(Settlements.PRODUCT_SLOT_PATH) == ledger_hash,
		"watch preserves replay, save, and settlement bytes")


func _reject_result_replay(map: WorldMapScreen, watch: Button, path: String, error: String) -> void:
	watch.pressed.emit()
	map._replay_dialog.file_selected.emit(path)
	_check(map._replay_overlay == null and map.state == "result" and map._result.visible
		and map.hud.visible and map._chip_label.text.begins_with(error), "product replay rejects " + error)


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

