extends SceneTree

const Dev := preload("res://core/battle/first_operation_dev.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")

var _fails := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	change_scene_to_file("res://scenes/WorldMap.tscn")
	await _frames()
	if OS.get_cmdline_user_args().has("--verify-external"):
		await _external_round_trip()
	elif OS.get_cmdline_user_args().has("--verify-late"):
		await _late_restore()
	elif OS.get_cmdline_user_args().has("--verify-restart"):
		await _restart_resume()
	else:
		await _save_and_replace()
	print("FIRST_OPERATION_SAVE_HOST_%s failures=%d" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)

func _frames() -> void:
	for i in 8:
		await process_frame

func _check(ok: bool, message: String) -> bool:
	if not ok:
		_fails += 1
		push_error("SAVE_HOST_FAIL " + message)
	return ok

func _save_and_replace() -> void:
	var map := current_scene as WorldMapScreen
	map.open_card()
	await _check_card_layout(map, "without save")
	map.find_child("FirstOperationDev_front", true, false).pressed.emit()
	map._skip.pressed.emit()
	await _frames()
	var host := current_scene.get_node_or_null("FirstOperationHost")
	if not _check(host != null and host.operation_owner != null, "fresh operation published"):
		return
	host._start.pressed.emit()
	host.set_process(false)
	host._commands[1].pressed.emit()
	for i in 4:
		host.step_operation()
	host.find_child("Operation_stop", true, false).pressed.emit()
	host._save.pressed.emit()
	var saved := Store.read()
	if not _check(saved.ok and int(saved.payload.tick) == 4 and saved.payload.pending.size() == 1,
			"save writes the committed tick and pending stop"):
		return
	var stored_bytes := FileAccess.get_file_as_bytes(Store.SLOT_PATH)
	var previous: RefCounted = host.operation_owner
	host.step_operation()
	var next: Dictionary = host.frame.duplicate(true)
	var invalid_file := FileAccess.open(Store.SLOT_PATH, FileAccess.WRITE)
	invalid_file.store_string("damaged")
	invalid_file.close()
	host._load.pressed.emit()
	await _frames()
	_check(host.operation_owner == previous and host.frame == next and host.started
		and not host._commands[0].disabled and host._save_status.text.begins_with("invalid_envelope"),
		"invalid slot preserves active owner, frame and input")
	_write_bytes(stored_bytes)
	var incompatible: Dictionary = saved.payload.duplicate(true)
	incompatible.rules_digest = "0".repeat(64)
	_check(Store.write(incompatible).ok, "write incompatible packet fixture")
	host._load.pressed.emit()
	await _frames()
	_check(host.operation_owner == previous and host.frame == next and host.started
		and host._save_status.text.begins_with("checkpoint_rules_mismatch"), "rules mismatch preserves active battle")
	_write_bytes(stored_bytes)
	host._load.pressed.emit()
	await _frames()
	_check(host.operation_owner != previous and previous.summary().error == "owner_closed"
		and host.frame.tick == 4 and not host.started and not host.is_processing()
		and host._start.visible and host._commands[0].disabled, "successful atomic replacement pauses at saved tick")
	await _frames()
	_check(host.frame.tick == 4, "paused replacement does not advance")
	host._start.pressed.emit()
	host.set_process(false)
	host.step_operation()
	_check(host.frame == next, "pending stop and first post-restore frame match uninterrupted play")
	host._return.pressed.emit()
	await _frames()
	map = current_scene as WorldMapScreen
	if not _check(map != null and map.state == "browse", "return to map from live operation"):
		return
	map.open_card()
	_check(Store.write(incompatible).ok, "write incompatible packet for map fixture")
	var map_id := map.get_instance_id()
	map._card.find_child("ResumeSavedBattle", true, false).pressed.emit()
	_check(current_scene == map and map.get_instance_id() == map_id and map._card.visible
		and map._chip_label.text.begins_with("checkpoint_rules_mismatch"), "map rejection retains original card and shows the error")
	var displayed := BattleOutcome.new()
	displayed.settlement_id = "fixture/settlement"
	displayed.kind = "objective_success"
	map._show_result(displayed)
	map._result.find_child("ResumeSavedBattle", true, false).pressed.emit()
	_check(current_scene == map and map.outcome == displayed and map._result.visible
		and map._chip_label.text.begins_with("checkpoint_rules_mismatch"), "map rejection retains the displayed result")
	map._result_to_world()
	_write_bytes(stored_bytes)
	await _restart_resume()

func _restart_resume() -> void:
	var map := current_scene as WorldMapScreen
	var saved := Store.read()
	if not _check(map != null and saved.ok, "save available from map entry"):
		return
	map.open_card()
	await _check_card_layout(map, "with save")
	map._card.find_child("ResumeSavedBattle", true, false).pressed.emit()
	await _frames()
	var host := current_scene.get_node_or_null("FirstOperationHost")
	if not _check(host != null and host.operation_owner != null, "map resume enters operation host"):
		return
	var captured: Dictionary = host.operation_owner.capture_checkpoint()
	_check(captured.ok and captured.packet.operation_id == saved.payload.operation_id
		and captured.packet.state_digest == saved.payload.state_digest
		and host.frame.tick == int(saved.payload.tick) and host.frame.clock_ms == int(saved.payload.clock_ms)
		and host._start.text == "Resume operation" and not host.is_processing(), "map resume preserves instance and pauses")
	_check(root.get_node("WorldLink").take_prepared_restore() == null, "restore handoff consumed once")
	print("FIRST_OPERATION_SAVE_HOST_RESTORED tick=%d id=%s" % [host.frame.tick, saved.payload.operation_id])

func _late_restore() -> void:
	var map := current_scene as WorldMapScreen
	var brief := BattleBrief.new()
	brief.select_first_operation_dev("front")
	var fresh := Dev.prepare_fresh(brief.operation_request())
	if not _check(fresh.ok, "prepare late fixture"):
		return
	var fixture: RefCounted = fresh.owner
	fixture.publish()
	for i in 11999:
		if not _check(fixture.advance().ok, "advance late fixture"):
			fixture.close()
			return
	var captured: Dictionary = fixture.capture_checkpoint()
	fixture.close()
	if not _check(captured.ok and captured.packet.tick == 11999 and Store.write(captured.packet).ok, "write 11999-tick slot"):
		return

	map.open_card()
	map.canvas.jump_to("z2")
	await _frames()
	var button := map._card.find_child("ResumeSavedBattle", true, false) as Button
	button.pressed.emit()
	var map_job: RefCounted = map._restore_job
	button.pressed.emit()
	await _frames()
	_check(map_job != null and map._restore_job == map_job and current_scene == map and map._card.visible
		and map._restore_label.text != "Restoring battle: 0 / 11999 ticks", "map yields progress and ignores duplicate resume")
	map.find_child("CancelMapRestore", true, false).pressed.emit()
	await _frames()
	_check(current_scene == map and map._card.visible and not map.canvas.input_lock
		and map_job.step(1).error == "restore_job_cancelled", "map cancellation preserves card and disposes candidate")
	print("RESTORE_LATE_MAP_CANCEL")

	var broken: Dictionary = captured.packet.duplicate(true)
	broken.state_digest = "0".repeat(64)
	_check(Store.write(broken).ok, "write late witness mismatch")
	button.pressed.emit()
	var frames := 0
	while map._restore_job != null and frames < 20000:
		frames += 1
		await process_frame
	_check(frames > 8 and current_scene == map and map._card.visible and not map.canvas.input_lock
		and map._chip_label.text.begins_with("checkpoint_state_mismatch"), "late verification failure preserves map")
	print("RESTORE_LATE_MAP_FAILURE frames=%d error=%s" % [frames, map._chip_label.text])
	_check(Store.write(captured.packet).ok, "restore valid slot")

	map.find_child("FirstOperationDev_front", true, false).pressed.emit()
	map._skip.pressed.emit()
	await _frames()
	var host := current_scene.get_node_or_null("FirstOperationHost")
	if not _check(host != null and host.operation_owner != null, "fresh battle for replacement"):
		return
	host._start.pressed.emit()
	host.set_process(false)
	host.step_operation()
	var existing: RefCounted = host.operation_owner
	var old_frame: Dictionary = host.frame.duplicate(true)
	host._load.pressed.emit()
	var battle_job: RefCounted = host._restore_job
	await _frames()
	_check(battle_job != null and host._restore_job == battle_job and host.frame == old_frame
		and host._save_status.text != "Restoring battle: 0 / 11999 ticks", "battle yields progress without advancing active owner")
	host._cancel_restore.pressed.emit()
	await _frames()
	_check(host.operation_owner == existing and host.frame == old_frame and host.started
		and not host._commands[0].disabled and not host.is_processing()
		and battle_job.step(1).error == "restore_job_cancelled", "battle cancellation preserves owner, clock and inputs")
	print("RESTORE_LATE_BATTLE_CANCEL")
	host._load.pressed.emit()
	frames = 0
	while host._restore_job != null and frames < 20000:
		frames += 1
		await process_frame
	_check(frames > 8 and host.operation_owner != existing and existing.summary().error == "owner_closed"
		and host.frame.tick == 11999 and host.frame.clock_ms == 1199900
		and not host.started and not host.is_processing(), "late success atomically replaces and pauses")
	print("RESTORE_LATE_BATTLE_SUCCESS frames=%d tick=%d" % [frames, host.frame.tick])

func _external_round_trip() -> void:
	var map := current_scene as WorldMapScreen
	map.open_card()
	await _frames()
	var map_import := map._card.find_child("ImportBattle", true, false) as Button
	if not _check(map_import != null and root.get_visible_rect().encloses(map_import.get_global_rect()), "map import button is in view"):
		return
	map_import.pressed.emit()
	_check(not map._import_dialog.use_native_dialog and map._import_dialog.get_line_edit().has_focus(),
		"embedded map import focuses the filename field")
	map._import_dialog.canceled.emit()
	await _frames()
	_check(current_scene == map and map._card.visible and map._import_dialog == null and map._restore_job == null,
		"map dialog cancellation preserves the card")
	map.find_child("FirstOperationDev_front", true, false).pressed.emit()
	map._skip.pressed.emit()
	await _frames()
	var host := current_scene.get_node_or_null("FirstOperationHost")
	if not _check(host != null and host.operation_owner != null, "fresh battle for external round trip"):
		return
	host._start.pressed.emit()
	host.set_process(false)
	for i in 4:
		host.step_operation()
	host._save.pressed.emit()
	var local_hash := FileAccess.get_sha256(Store.SLOT_PATH)
	_check(not local_hash.is_empty(), "local slot baseline")
	host.step_operation()
	var path := ProjectSettings.globalize_path("user://round-trip.pcopsave")
	var existing: RefCounted = host.operation_owner
	var old_frame: Dictionary = host.frame.duplicate(true)
	host._export.pressed.emit()
	_check(host._file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE
		and host._file_dialog.filters[0].begins_with("*.pcopsave") and not host._file_dialog.use_native_dialog
		and host._file_dialog.get_line_edit().has_focus(), "embedded export focuses filename and uses the correct extension")
	host._file_dialog.canceled.emit()
	await _frames()
	_check(host.operation_owner == existing and host.frame == old_frame and host.started
		and not FileAccess.file_exists(path), "export dialog cancellation leaves battle and filesystem unchanged")
	host._export.pressed.emit()
	host._file_dialog.file_selected.emit(path)
	await _frames()
	if not _check(FileAccess.file_exists(path) and host._save_status.text == "Exported at tick 5",
			"external export writes selected file"):
		return
	var external_hash := FileAccess.get_sha256(path)
	host._export.pressed.emit()
	host._file_dialog.file_selected.emit(path)
	await _frames()
	_check(FileAccess.get_sha256(path) == external_hash and not host._save_status.text.begins_with("Exported"),
		"existing external file is preserved on overwrite attempt")
	host.step_operation()
	old_frame = host.frame.duplicate(true)
	host._import.pressed.emit()
	_check(host._file_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE, "import dialog uses open-file mode")
	host._file_dialog.canceled.emit()
	await _frames()
	_check(host.operation_owner == existing and host.frame == old_frame and host._restore_job == null,
		"battle import dialog cancellation preserves active state")
	host._import.pressed.emit()
	host._file_dialog.file_selected.emit(path + ".missing.pcopsave")
	await _frames()
	_check(host.operation_owner == existing and host.frame == old_frame and host._restore_job == null
		and not host._save_status.text.is_empty(), "invalid external path preserves active battle")
	host._import.pressed.emit()
	host._file_dialog.file_selected.emit(path)
	await _frames()
	_check(host.operation_owner != existing and existing.summary().error == "owner_closed"
		and host.frame.tick == 5 and not host.started and not host.is_processing(),
		"battle import atomically restores external tick")
	host._return.pressed.emit()
	await _frames()
	map = current_scene as WorldMapScreen
	if not _check(map != null, "return to map before external import"):
		return
	map.open_card()
	map._card.find_child("ImportBattle", true, false).pressed.emit()
	map._import_dialog.file_selected.emit(path)
	await _frames()
	host = current_scene.get_node_or_null("FirstOperationHost")
	_check(host != null and host.frame.tick == 5 and not host.started, "map imports through the same paused restore")
	_check(FileAccess.get_sha256(Store.SLOT_PATH) == local_hash and int(Store.read().payload.tick) == 4,
		"external round trip leaves the local slot byte-for-byte unchanged")
	print("EXTERNAL_SAVE_HOST_ROUND_TRIP external_tick=5 local_tick=4")

func _check_card_layout(map: WorldMapScreen, context: String) -> void:
	var original := root.size
	for size: Vector2i in [Vector2i(1600, 900), Vector2i(1920, 1030)]:
		root.size = size
		await _frames()
		var viewport := root.get_visible_rect()
		var controls := 0
		for button: Button in map._card.find_children("*", "Button", true, false):
			if button.name in ["ResumeSavedBattle", "ImportBattle", "FirstOperationDev_front", "FirstOperationDev_flank"] \
					or button.text.replace(" ", "") == "출격":
				controls += 1
				var bounds := button.get_global_rect()
				_check(button.is_visible_in_tree() and viewport.encloses(bounds),
					"%s %s %s inside %s: %s" % [context, size, button.text, viewport, bounds])
		_check(controls == 5, "all five card actions checked")
		print("FIRST_OPERATION_CARD_LAYOUT %s %s controls=%d" % [context, size, controls])
	root.size = original
	await _frames()

func _write_bytes(bytes: PackedByteArray) -> void:
	var file := FileAccess.open(Store.SLOT_PATH, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

