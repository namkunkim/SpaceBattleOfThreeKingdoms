extends SceneTree

const Slot := preload("res://scripts/cross_counter/public_slot.gd")
const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := OS.get_environment("SBTK_CC_LIFECYCLE_PROFILE").replace("\\", "/")
	var args := OS.get_cmdline_user_args()
	if not _check(args.size() == 1 and OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and profile.begins_with("F:/WorkSpace/Campaign-Orchestration/")
			and OS.get_user_data_dir().replace("\\", "/").begins_with(profile + "/"), "explicit isolated profile"):
		return
	var ledger_hash := FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH)
	change_scene_to_file("res://scenes/entry/EntryBoot.tscn")
	for attempt in 120:
		await process_frame
		if current_scene is WorldMapScreen and current_scene._cross_counter_button != null \
				and current_scene._cross_counter_button.visible:
			break
	if not _check(current_scene is WorldMapScreen and current_scene._cross_counter_button.visible
			and not current_scene._cross_counter_button.disabled and not ledger_hash.is_empty(), "eligible result opens explicit route"):
		return
	var map: WorldMapScreen = current_scene
	map._cross_counter_button.pressed.emit()
	for attempt in 180:
		await process_frame
		if map._cross_counter_host != null and map._cross_counter_host._owner != null:
			break
	var host := map._cross_counter_host
	if not _check(host != null and host._owner != null and not auto_accept_quit and not host._running,
			"published owner held and paused"):
		return
	if args[0] == "close":
		_close_phase(host)
	elif args[0] == "resume":
		await _resume_phase(map, host, ledger_hash)
	else:
		_check(false, "known process phase")


func _close_phase(host: Control) -> void:
	if not _check(host._lease.head().active.packet.tick == 0, "durable C0 before publication"):
		return
	host._begin_button.pressed.emit()
	host.set_process(false)
	for i in 16:
		host._process(0.1)
	if not _check(host._frame.tick >= 15, "approved native owner advances"):
		return
	var previous := Slot.SLOT_PATH + ".previous"
	DirAccess.remove_absolute(previous)
	if not _check(DirAccess.make_dir_absolute(previous) == OK, "force backup replace failure"):
		return
	var before := FileAccess.get_sha256(Slot.SLOT_PATH)
	var frontier: int = host._frame.tick
	host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	if not _check(host._closing_requested and host._blocked and not host.is_processing()
			and not auto_accept_quit and Slot.open().get("error") == "cross_counter_slot_busy"
			and FileAccess.get_sha256(Slot.SLOT_PATH) == before,
			"failed close preserves active lease, paused UI and committed bytes"):
		return
	DirAccess.remove_absolute(previous)
	var expected := FileAccess.open("user://expected-close", FileAccess.WRITE)
	expected.store_var({"operation_id": host._operation_id, "tick": frontier})
	expected.close()
	host._save_button.pressed.emit()
	if not _check(not host._blocked and host._lease.head().active.packet.tick == frontier
			and FileAccess.get_sha256(Slot.SLOT_PATH) != before, "retry persists frontier before window shutdown"):
		return
	print("CROSS_COUNTER_PUBLIC_HOST_CLOSE ", checks)


func _resume_phase(map: WorldMapScreen, host: Control, ledger_hash: String) -> void:
	var expected := FileAccess.open("user://expected-close", FileAccess.READ)
	if not _check(expected != null, "original process close witness exists"):
		return
	var prior: Dictionary = expected.get_var()
	expected.close()
	if not _check(host._operation_id == prior.operation_id and host._frame.tick == prior.tick
			and FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH) == ledger_hash, "new process resumes same durable owner and tick"):
		return
	host._abandon_button.pressed.emit()
	if not _check(host._terminal and host._lease.head().active.is_empty(), "explicit abandon records terminal atomically"):
		return
	var head: Dictionary = host._lease.head()
	var outcome: Dictionary = head.completed.values()[0].settlement
	if not _check(outcome.kind == "failure" and outcome.reason == "abandoned",
			"authoritative abandon settlement persisted"):
		return
	host._return_button.pressed.emit()
	await process_frame
	if not _check(map._cross_counter_host == null and auto_accept_quit
			and map._cross_counter_button.text.contains("결산"), "return releases lease and restores prior quit behavior"):
		return
	map._cross_counter_button.pressed.emit()
	if not _check(map._cross_counter_host != null and map._cross_counter_host._terminal
			and map._cross_counter_host._owner == null, "historical receipt cannot activate gameplay"):
		return
	print("CROSS_COUNTER_PUBLIC_HOST_RESUME ", checks)
	quit()


func _check(ok: bool, label: String) -> bool:
	checks += 1
	print("CROSS_COUNTER_PUBLIC_HOST_CHECK ", ok, " ", label)
	if not ok:
		quit(1)
	return ok
