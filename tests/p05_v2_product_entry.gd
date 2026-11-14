extends SceneTree

const Home := preload("res://scripts/entry/red_cliffs_v2_home.gd")
const Host := preload("res://scripts/first_operation_v2_product_host.gd")
const V1Host := preload("res://scripts/first_operation_host.gd")
const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const Storage := preload("res://scripts/first_operation_v2_storage.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

var passed := 0
var failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _check(not Storage.has_save() and not FileAccess.file_exists(V1Host.PRODUCT_SLOT_PATH),
			"fresh isolated profile"):
		quit(1)
		return
	var replay_path := ProjectSettings.globalize_path("user://product-test" + Codec.REPLAY_EXTENSION)
	var cli := OS.get_cmdline_user_args().has("--red-cliffs-v2")
	if cli and not _seed_v1_slot():
		quit(1)
		return
	change_scene_to_file("res://scenes/entry/EntryBoot.tscn")
	if not cli:
		for i in 60:
			await process_frame
			if current_scene != null and current_scene.is_node_ready() and current_scene.screen != null:
				break
		var screen: Control = current_scene.screen
		if not _check(screen != null and _seed_v1_slot()
				and screen.request("v2", screen.flow.revision), "fresh Windows product entry exposes separate v2 menu"):
			quit(1)
			return
	for i in 60:
		await process_frame
		if current_scene is Home:
			break
	if not _check(current_scene is Home, "Windows route reaches separate v2 menu despite v1 slot"):
		quit(1)
		return
	var home: Home = current_scene
	if not _check(not home._fresh.disabled and home._resume.disabled, "fresh enabled and empty resume disabled"):
		quit(1)
		return
	home._fresh.pressed.emit()
	await process_frame
	var host := home._host
	if not _check(host != null and host.failure.is_empty() and host._formation_renderer != null
			and host.frame.meta.capability == Host.FormationOwner.CAPABILITY, "fresh product renderer binds v2 authority"):
		quit(1)
		return
	host._start.pressed.emit()
	host.set_process(false)
	host.step_operation()
	var formation := host._panel.find_child("Operation_formation", false, false) as Button
	if not _check(formation != null and not formation.disabled, "formation command exposed through UI"):
		quit(1)
		return
	formation.pressed.emit()
	for i in 20:
		host.step_operation()
		for sample in 3:
			host._formation_renderer.update(1.0 / 30.0)
	host._save.pressed.emit()
	if not _check(Storage.has_save() and host.frame.tick == 21, "save mid-transition in dedicated slot"):
		quit(1)
		return
	# Save again to cover the Win32 existing-target replacement path.
	host._save.pressed.emit()
	_check(host._save_status.text.begins_with("21"), "same slot safely replaced")
	var original_id: String = host.operation_owner.presentation_identity()
	host._return.pressed.emit()
	await process_frame
	_check(home._host == null and not home._resume.disabled, "return to v2 home enables resume")
	home._resume.pressed.emit()
	for i in 180:
		await process_frame
		if home._host.started or home._host.operation_owner != null or home._host._restore_job == null:
			break
	host = home._host
	if not _check(host.operation_owner != null and host._formation_renderer != null and not host.started
			and host.frame.tick == 21 and host.operation_owner.presentation_identity() == original_id,
			"menu restores exact owner, cursor and paused frontier"):
		quit(1)
		return
	host._start.pressed.emit()
	host.set_process(false)
	for i in range(21, 51):
		host.step_operation()
		for sample in 3:
			host._formation_renderer.update(1.0 / 30.0)
	var row: Dictionary = host._formation_source.squadrons()[0]
	_check(host.frame.tick == 51 and row.formation_id == "FRM-01"
		and host._formation_renderer.vis[row.id].p05.sample_index == 145, "formation reaches final pose")
	host._issue("withdraw")
	host.step_operation()
	host._issue("finalize_withdrawal")
	host.step_operation()
	if not _check(host.settlement != null and host._export_replay.visible, "terminal v2 battle exposes v2 replay export"):
		quit(1)
		return
	host._select_replay_file()
	host._export_replay_file(replay_path)
	_check(FileAccess.file_exists(replay_path), "v2 replay file published")
	_check(not Storage.export_replay(host._replay_recording, replay_path).ok
		and not Storage.export_replay(host._replay_recording, replay_path + ".pcopreplay").ok,
		"replay refuses overwrite and v1 suffix")
	var terminal: Dictionary = host._replay_recording.settlement
	host._return.pressed.emit()
	await process_frame
	home._open_replay(replay_path)
	for i in 240:
		await process_frame
		if home._viewer == null or home._viewer._job == null:
			break
	if not _check(home._viewer != null and home._viewer._replay != null,
			"v2 menu verifies witness before playback"):
		quit(1)
		return
	for i in terminal.tick:
		home._viewer.step_replay()
	_check(home._viewer._finished and home._viewer._frame.tick == terminal.tick
		and home._viewer._frame.projection.operation.settlement.id == terminal.id, "v2 replay reaches same terminal witness")
	var world := root.get_node("WorldLink")
	_check(world.brief == null and world.outcome == null
		and FileAccess.get_file_as_string(V1Host.PRODUCT_SLOT_PATH) == "unchanged-v1",
		"v2 exit and replay preserve v1 routing and slot")
	_check(Checkpoint.rules_digest() == "b7189ae8f3408fd4e053a792491ac5f6457a520218df2b709c4a8e3986863658",
		"v1 rule digest stays pinned")
	print("P05_V2_PRODUCT_ENTRY %d/%d" % [passed, passed + failed])
	quit(0 if failed == 0 else 1)


func _seed_v1_slot() -> bool:
	var file := FileAccess.open(V1Host.PRODUCT_SLOT_PATH, FileAccess.WRITE)
	if not _check(file != null, "create isolated v1 sentinel"):
		return false
	file.store_string("unchanged-v1")
	file.close()
	return true


func _check(ok: bool, description: String) -> bool:
	if ok:
		passed += 1
	else:
		failed += 1
	print("P05_V2_PRODUCT_CHECK %s %s" % [ok, description])
	return ok
