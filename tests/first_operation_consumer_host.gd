extends SceneTree
## Windows headless driver for approved Red Cliffs product host / CLI parity.
## Launch with a new isolated APPDATA and SBTK_P02_PARITY_PROFILE set to that path.
## Pass -- c0 to compare only the initial state through the shared CLI bootstrap.

const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const Cli := preload("res://tests/autoresolve.gd")
const Host := preload("res://scripts/first_operation_host.gd")
const Settlements := preload("res://scripts/first_operation_settlement_store.gd")
const ENTRY := "res://scenes/entry/EntryBoot.tscn"
const ROUTE := {0: 2, 900: 3}
const FINAL_TICK := 5487

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	print("P02_PARITY_CHECK ", condition, " ", label)
	if not condition:
		_failures += 1
	return condition


func _wait_until(ready: Callable) -> bool:
	for attempt in 300:
		if ready.call():
			return true
		await process_frame
	return false


func _button(node: Node, label: String) -> Button:
	for child: Button in node.find_children("*", "Button", true, false):
		if child.text == label and child.is_visible_in_tree() and not child.disabled:
			return child
	return null


func _entry_action(label: String) -> bool:
	var ready := func() -> bool:
		return is_instance_valid(current_scene) and current_scene.scene_file_path == ENTRY \
			and is_instance_valid(current_scene.screen) and _button(current_scene.screen, label) != null
	if not _expect(await _wait_until(ready), "public EntryBoot offers " + label):
		return false
	_button(current_scene.screen, label).pressed.emit()
	await create_timer(0.30).timeout
	return true


func _host() -> Node:
	return current_scene.get_node_or_null("FirstOperationHost") if is_instance_valid(current_scene) else null


func _write_json(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	var written := file.store_string(JSON.stringify(Cli._first_operation_json(value)))
	file.close()
	return written


func _exercise(c0_only: bool) -> void:
	for label in ["적벽대전 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			return
	if not _expect(await _wait_until(func(): return is_instance_valid(_host()) \
			and _host().operation_owner != null), "public sortie publishes a live owner"):
		return
	var host := _host()
	var initial: Dictionary = host.frame.duplicate(true)
	if not _expect(initial.tick == 0 and initial.clock_ms == 0 and not host.started, "public host publishes paused C0"):
		return
	if c0_only:
		_compare_initial(host, initial)
		return
	var events: Array = initial.events.duplicate(true)
	host._start.pressed.emit()
	host.set_process(false)
	for tick in FINAL_TICK:
		if ROUTE.has(tick):
			var button := _button(host, "Move to waypoint %d" % ROUTE[tick])
			if not _expect(button != null, "public host offers approved waypoint at tick %d" % tick):
				return
			button.pressed.emit()
		var advanced: bool = host.step_operation()
		if host.frame.tick != tick + 1 or advanced != (tick + 1 < FINAL_TICK):
			_expect(false, "host fails to advance the approved schedule at tick %d" % tick)
			return
		events.append_array(host.frame.events)
	if not _expect(host.settlement != null and host.settlement.kind == "objective_success" \
			and host.settlement.reason == "objective_conditions_met" \
			and host.frame.clock_ms == FINAL_TICK * 100, "public host reaches approved terminal result"):
		return
	var read: Dictionary = host.operation_owner.summary()
	if not _expect(read.ok and read.summary.over and read.summary.tick == FINAL_TICK, "read live terminal summary"):
		return
	if not _expect(host._export_replay.is_visible_in_tree() and not host._export_replay.disabled, "terminal host offers replay export"):
		return
	host._export_replay.pressed.emit()
	if not _expect(host._file_dialog != null, "export opens a file dialog"):
		return
	var replay_path := ProjectSettings.globalize_path("user://approved-host.pcopreplay")
	host._file_dialog.file_selected.emit(replay_path)
	var replay := Codec.read(replay_path)
	if not _expect(replay.ok and host._save_status.text == "Replay exported", "export and read back the real host replay"):
		return
	var expected_commands := [{"tick": 0, "kind": "move", "waypoint": 2}, {"tick": 900, "kind": "move", "waypoint": 3}]
	if not _expect(replay.bundle.commands == expected_commands and replay.bundle.max_ticks == FINAL_TICK \
			and Adapter.SETTLEMENT_FIELDS.all(func(key): return replay.bundle.expected_settlement[key] == read.summary.settlement[key]), \
			"export binds approved ordered input and all contracted terminal witness fields"):
		return
	_expect(_write_json("user://approved-bundle.json", replay.bundle), "write verified replay bundle for both CLI consumers")
	_expect(_write_json("user://host-result.json", {
		"summary": read.summary, "projection": host.frame.projection, "events": events,
		"event_count": events.size(), "meta": initial.meta, "initial_frame": initial,
	}), "write public host initial and terminal state plus complete ordered events")


func _compare_initial(host: Node, initial: Dictionary) -> void:
	var captured: Dictionary = host.operation_owner.capture_checkpoint()
	if not _expect(captured.ok and captured.packet.tick == 0 and captured.packet.commands.is_empty() \
			and captured.packet.pending.is_empty(), "public host publishes a clean C0 checkpoint"):
		return
	var packet: Dictionary = captured.packet
	var operation_id: String = packet.operation_id
	var expected := {"operation_id": operation_id, "id": operation_id + "/settlement",
		"kind": "objective_success", "reason": "objective_conditions_met", "tick": FINAL_TICK, "clock_ms": FINAL_TICK * 100}
	var bundle := {"format": Adapter.FORMAT, "request": host.brief.operation_request(),
		"operation_id": operation_id, "max_ticks": FINAL_TICK,
		"commands": [{"tick": 0, "kind": "move", "waypoint": ROUTE[0]}, {"tick": 900, "kind": "move", "waypoint": ROUTE[900]}],
		"expected_settlement": expected}
	# The headless CLI calls this bootstrap via run(); replay exposes the same
	# bootstrap with its required-settlement policy through open_replay().
	var headless := Adapter._open(bundle, false)
	var replay := Adapter.open_replay(bundle)
	var headless_c0 := _capture_bootstrap(headless, "headless")
	var replay_c0 := _capture_bootstrap(replay, "replay")
	if headless_c0.is_empty() or replay_c0.is_empty():
		return
	var host_c0 := {"frame": initial, "checkpoint": packet}
	_expect(headless_c0.frame == initial, "headless bootstrap matches the complete public C0 frame")
	_expect(replay_c0.frame == initial, "replay bootstrap matches the complete public C0 frame")
	_expect(headless_c0.checkpoint == packet, "headless bootstrap matches the full C0 checkpoint and operation identity")
	_expect(replay_c0.checkpoint == packet, "replay bootstrap matches the full C0 checkpoint and operation identity")
	_expect(host.operation_owner.capture_checkpoint() == captured and host.frame == initial,
		"comparison leaves the live public host at the same C0")
	_expect(_write_json("user://c0-result.json", {"host": host_c0, "headless": headless_c0, "replay": replay_c0,
		"bundle": bundle}), "write complete C0 frames and checkpoints for review")


func _capture_bootstrap(opened: Dictionary, label: String) -> Dictionary:
	if not _expect(opened.ok, label + " bootstrap publishes a fresh owner"):
		return {}
	var session: RefCounted = opened.replay
	var captured: Dictionary = session._owner.capture_checkpoint()
	session.close()
	if not _expect(captured.ok and captured.packet.tick == 0 and session._owner == null,
			label + " checkpoint captured at tick zero and owner closed"):
		return {}
	return {"frame": opened.frame, "checkpoint": captured.packet}


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var c0_only := args == PackedStringArray(["c0"])
	var profile := OS.get_environment("SBTK_P02_PARITY_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	var empty := not FileAccess.file_exists(Host.PRODUCT_SLOT_PATH) \
		and not FileAccess.file_exists(Host.PRODUCT_SLOT_PATH + ".previous") \
		and not FileAccess.file_exists(Settlements.PRODUCT_SLOT_PATH) \
		and not FileAccess.file_exists(Settlements.PRODUCT_SLOT_PATH + ".previous") \
		and not FileAccess.file_exists("user://approved-host.pcopreplay")
	if _expect((args.is_empty() or c0_only) and not profile.is_empty() and actual == expected and empty \
			and ProjectSettings.get_setting("application/run/main_scene") == ENTRY, "fresh isolated profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			await _exercise(c0_only)
	print("P02_PARITY_RESULT checks=%d failures=%d pid=%d" % [_checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
