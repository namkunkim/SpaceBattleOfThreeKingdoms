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
		_resume_phase(host, ledger_hash)
	elif args[0] == "settle":
		await _settle_phase(map, host, ledger_hash)
	else:
		_check(false, "known process phase")


func _close_phase(host: Control) -> void:
	if not _check(host._lease.head().active.packet.tick == 0, "durable C0 before publication"):
		return
	host._begin_button.pressed.emit()
	host.set_process(false)
	for i in 16:
		host._process(0.1)
	if not _check(host._frame.tick == 16, "approved native owner advances to tick 16"):
		return
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = host._board.size * 0.5
	host._board.gui_input.emit(event)
	host._stop_button.pressed.emit()
	var queued := _live_packet(host)
	if not _check(queued.pending.size() == 2 and queued.pending[0].kind == "move"
			and queued.pending[1].kind == "stop" and queued.commands.is_empty(),
			"public board and stop controls queue two unapplied orders"):
		return
	var previous := Slot.SLOT_PATH + ".previous"
	DirAccess.remove_absolute(previous)
	if not _check(DirAccess.make_dir_absolute(previous) == OK, "force backup replace failure"):
		return
	var before := FileAccess.get_sha256(Slot.SLOT_PATH)
	host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	if not _check(host._closing_requested and host._blocked and not host.is_processing()
			and not auto_accept_quit and Slot.open().get("error") == "cross_counter_slot_busy"
			and FileAccess.get_sha256(Slot.SLOT_PATH) == before and _live_packet(host) == queued,
			"failed close preserves active lease, paused UI and committed bytes"):
		return
	DirAccess.remove_absolute(previous)
	var expected := FileAccess.open("user://expected-close", FileAccess.WRITE)
	expected.store_var({"packet": queued, "pid": OS.get_process_id(), "ledger_hash": FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH)})
	expected.close()
	host._save_button.pressed.emit()
	if not _check(not host._blocked and host._lease.head().active.packet == queued
			and FileAccess.get_sha256(Slot.SLOT_PATH) != before, "retry persists frontier before window shutdown"):
		return
	print("CROSS_COUNTER_PUBLIC_HOST_CLOSE ", checks)


func _resume_phase(host: Control, ledger_hash: String) -> void:
	var expected := FileAccess.open("user://expected-close", FileAccess.READ)
	if not _check(expected != null, "original process close witness exists"):
		return
	var prior: Dictionary = expected.get_var()
	expected.close()
	var restored := _live_packet(host)
	if not _check(OS.get_process_id() != prior.pid and restored == prior.packet
			and host._lease.head().active.packet == prior.packet and host._frame.tick == restored.tick
			and host._operation_id == restored.operation_id and _parent_preserved(prior, ledger_hash),
			"new process restores the exact live packet, including pending orders and event cursor"):
		return
	host._begin_button.pressed.emit()
	host.set_process(false)
	if not _check(_live_packet(host) == restored, "resume does not consume orders or replay bootstrap"):
		return
	var prior_log := _native_log(host)
	host._process(0.1)
	var applied := _live_packet(host)
	var applied_log := _native_log(host)
	if not _check(applied.tick == restored.tick + 1 and applied.pending.is_empty()
			and applied.commands == [{"tick": restored.tick, "batch": restored.pending}]
			and applied_log.size() == prior_log.size() + 2 and applied_log.slice(0, prior_log.size()) == prior_log
			and applied.event_cursor >= restored.event_cursor and applied.event_cursor == applied.emitted_events,
			"next tick commits both orders once and drains events"):
		return
	host._process(0.1)
	var advanced := _live_packet(host)
	if not _check(advanced.tick == applied.tick + 1 and advanced.pending.is_empty()
			and advanced.commands == applied.commands and _native_log(host) == applied_log,
			"following tick does not replay the command batch"):
		return
	host._save_button.pressed.emit()
	if not _check(host._lease.head().active.packet == advanced, "public save persists the applied frontier"):
		return
	var witness := FileAccess.open("user://expected-resume", FileAccess.WRITE)
	witness.store_var({"packet": advanced, "pid": OS.get_process_id(), "ledger_hash": ledger_hash, "native_log": applied_log})
	witness.close()
	print("CROSS_COUNTER_PUBLIC_HOST_RESUME ", checks)
	host.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)


func _settle_phase(map: WorldMapScreen, host: Control, ledger_hash: String) -> void:
	var expected := FileAccess.open("user://expected-resume", FileAccess.READ)
	if not _check(expected != null, "applied frontier witness exists"):
		return
	var prior: Dictionary = expected.get_var()
	expected.close()
	if not _check(OS.get_process_id() != prior.pid and _live_packet(host) == prior.packet
			and _parent_preserved(prior, ledger_hash), "third process restores applied history and an empty queue"):
		return
	host._begin_button.pressed.emit()
	host.set_process(false)
	host._process(0.1)
	var advanced := _live_packet(host)
	if not _check(advanced.tick == prior.packet.tick + 1 and advanced.pending.is_empty()
			and advanced.commands == prior.packet.commands
			and _native_log(host) == prior.native_log,
			"advancing after the second restart does not replay the orders"):
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
	print("CROSS_COUNTER_PUBLIC_HOST_SETTLE ", checks)
	quit()


func _live_packet(host: Control) -> Dictionary:
	var captured: Dictionary = host._checkpoint.capture(host._owner)
	return captured.get("packet", {})


func _native_log(host: Control) -> Array:
	var captured: Dictionary = host._owner.capture_checkpoint()
	return captured.packet.native_witness.command_log


func _parent_preserved(prior: Dictionary, ledger_hash: String) -> bool:
	return prior.ledger_hash == ledger_hash and FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH) == ledger_hash


func _check(ok: bool, label: String) -> bool:
	checks += 1
	print("CROSS_COUNTER_PUBLIC_HOST_CHECK ", ok, " ", label)
	if not ok:
		quit(1)
	return ok
