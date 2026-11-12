extends SceneTree
## Windows headless driver for approved Red Cliffs product host / CLI parity.
## Launch with a new isolated APPDATA and SBTK_P02_PARITY_PROFILE set to that path.

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


func _exercise() -> void:
	for label in ["적벽대전 선택 · 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			return
	if not _expect(await _wait_until(func(): return is_instance_valid(_host()) \
			and _host().operation_owner != null), "public sortie publishes a live owner"):
		return
	var host := _host()
	var initial: Dictionary = host.frame.duplicate(true)
	if not _expect(initial.tick == 0 and initial.clock_ms == 0 and not host.started, "public host publishes paused C0"):
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


func _run() -> void:
	var profile := OS.get_environment("SBTK_P02_PARITY_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	var empty := not FileAccess.file_exists(Host.PRODUCT_SLOT_PATH) \
		and not FileAccess.file_exists(Host.PRODUCT_SLOT_PATH + ".previous") \
		and not FileAccess.file_exists(Settlements.PRODUCT_SLOT_PATH) \
		and not FileAccess.file_exists(Settlements.PRODUCT_SLOT_PATH + ".previous") \
		and not FileAccess.file_exists("user://approved-host.pcopreplay")
	if _expect(not profile.is_empty() and actual == expected and empty \
			and ProjectSettings.get_setting("application/run/main_scene") == ENTRY, "fresh isolated profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			await _exercise()
	print("P02_PARITY_RESULT checks=%d failures=%d pid=%d" % [_checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
