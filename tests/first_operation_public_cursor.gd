extends SceneTree

const Host := preload("res://scripts/first_operation_host.gd")
const Slot := preload("res://scripts/first_operation_save_store.gd")
const ENTRY := "res://scenes/entry/EntryBoot.tscn"
const PRIMARY := Host.PRODUCT_SLOT_PATH
const PREVIOUS := PRIMARY + ".previous"
const ORACLE_A := "user://p03-public-cursor-a"
const ORACLE_B := "user://p03-public-cursor-b"

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	print("P03_PUBLIC_CURSOR_CHECK ", condition, " ", label)
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
	for child: Node in node.find_children("*", "Button", true, false):
		if child.text == label and child.is_visible_in_tree() and not child.disabled:
			return child
	return null


func _entry_action(label: String) -> bool:
	var ready := func() -> bool:
		return is_instance_valid(current_scene) and current_scene.scene_file_path == ENTRY \
			and is_instance_valid(current_scene.screen) and _button(current_scene.screen, label) != null
	if not _expect(await _wait_until(ready), "EntryBoot offers " + label):
		return false
	_button(current_scene.screen, label).pressed.emit()
	await create_timer(0.30).timeout
	return true


func _host() -> Node:
	return current_scene.get_node_or_null("FirstOperationHost") if is_instance_valid(current_scene) else null


func _wait_host() -> bool:
	return await _wait_until(func(): return is_instance_valid(_host()) and _host().operation_owner != null)


func _atlas_resume() -> Button:
	if not current_scene is WorldMapScreen or current_scene.state != "browse":
		return null
	for candidate: Button in current_scene.find_children("ResumeProductBattle", "Button", true, false):
		if candidate.is_visible_in_tree() and not candidate.disabled:
			return candidate
	return null


func _resume() -> bool:
	if not _expect(await _wait_until(func(): return _atlas_resume() != null), "public atlas offers product resume"):
		return false
	_atlas_resume().pressed.emit()
	return _expect(await _wait_host(), "public atlas resume publishes the product host")


func _start(host: Node) -> void:
	host._start.pressed.emit()
	host.set_process(false)


func _capture(host: Node) -> Dictionary:
	var result: Dictionary = host.operation_owner.capture_checkpoint()
	if not _expect(result.ok, "capture product checkpoint"):
		return {}
	return result.packet


func _write_oracle(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not _expect(file != null, "open comparison oracle for write"):
		return
	_expect(file.store_var(value), "write comparison oracle")
	file.close()


func _read_oracle(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not _expect(file != null, "open comparison oracle from earlier process"):
		return {}
	var value: Variant = file.get_var()
	file.close()
	if not _expect(value is Dictionary and value.pid != OS.get_process_id(), "oracle belongs to a distinct process"):
		return {}
	return value


func _queue(host: Node, label: String) -> bool:
	var button := _button(host, label)
	if not _expect(button != null, "public host offers " + label):
		return false
	button.pressed.emit()
	return true


func _slot_value(packet: Dictionary) -> Dictionary:
	# The save envelope represents numbers through Godot JSON, which decodes them as floats.
	return JSON.parse_string(JSON.stringify(packet, "", true, true))


func _save(host: Node, expected: Dictionary) -> bool:
	host._save.pressed.emit()
	var saved := Host.read_saved_battle(true)
	return _expect(saved.ok and saved.payload == _slot_value(expected) \
		and host._save_status.text == "Saved at tick %d" % expected.tick, "button commits exact primary checkpoint")


func _seed() -> void:
	if not _expect(not FileAccess.file_exists(PRIMARY) and not FileAccess.file_exists(PREVIOUS) \
		and not FileAccess.file_exists(ORACLE_A) and not FileAccess.file_exists(ORACLE_B), "start with an empty isolated profile"):
		return
	for label in ["적벽대전 선택 · 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			return
	if not _expect(await _wait_host(), "public EntryBoot sortie publishes product host"):
		return
	var host := _host()
	if not _expect(host.frame.tick == 0 and not host.started, "new sortie starts paused at tick 0"):
		return
	_start(host)
	if not _queue(host, "Move to waypoint 1") or not _expect(host.step_operation() and host.step_operation(), "advance to tick 2"):
		return
	if not _queue(host, "Stop"):
		return
	var saved := _capture(host)
	if not _expect(not saved.is_empty() and saved.tick == 2 and saved.commands.size() == 1 \
		and saved.pending.size() == 1 and saved.pending[0].kind == "stop", "generation A stores applied movement and pending Stop"):
		return
	if not _save(host, saved) or not _expect(not FileAccess.file_exists(PREVIOUS), "initial commit has no previous generation"):
		return
	if not _expect(host.step_operation(), "uninterrupted tick 3 consumes Stop"):
		return
	var advanced := _capture(host)
	if not _expect(not advanced.is_empty() and advanced.tick == 3 and advanced.pending.is_empty() \
		and advanced.commands.size() == 2 and advanced.commands[1].tick == saved.tick \
		and advanced.commands[1].batch == saved.pending, "Stop is appended once with the pre-advance cursor"):
		return
	_write_oracle(ORACLE_A, {
		"pid": OS.get_process_id(), "saved": saved, "advanced": advanced, "advanced_frame": JSON.stringify(host.frame),
		"primary_sha": FileAccess.get_sha256(PRIMARY)
	})


func _rotate() -> void:
	var earlier := _read_oracle(ORACLE_A)
	if earlier.is_empty() or not _expect(FileAccess.get_sha256(PRIMARY) == earlier.primary_sha, "generation A bytes before first resume"):
		return
	if not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == earlier.saved, "first resume restores exact generation A packet while paused"):
		return
	_start(host)
	if not _expect(host.step_operation() and _capture(host) == earlier.advanced \
		and JSON.stringify(host.frame) == earlier.advanced_frame, "first resume tick 3 equals uninterrupted state, events and frame"):
		return
	if not _queue(host, "Move to waypoint 1") or not _queue(host, "Stop"):
		return
	var saved := _capture(host)
	if not _expect(not saved.is_empty() and saved.tick == 3 and saved.commands == earlier.advanced.commands \
		and saved.pending.size() == 2 and saved.pending[0].kind == "move" and saved.pending[1].kind == "stop", \
		"generation B preserves applied prefix and pending batch order"):
		return
	if not _save(host, saved):
		return
	var primary_sha := FileAccess.get_sha256(PRIMARY)
	var previous_sha := FileAccess.get_sha256(PREVIOUS)
	var previous := Slot.read(PREVIOUS)
	if not _expect(not primary_sha.is_empty() and primary_sha != earlier.primary_sha and previous_sha == earlier.primary_sha \
		and previous.ok and previous.payload == _slot_value(earlier.saved), "rotation preserves exact generation A bytes and packet"):
		return
	if not _expect(host.step_operation(), "uninterrupted tick 4 consumes generation B batch"):
		return
	var advanced := _capture(host)
	var advanced_frame := JSON.stringify(host.frame)
	if not _expect(not advanced.is_empty() and advanced.tick == 4 and advanced.pending.is_empty() \
		and advanced.commands.size() == saved.commands.size() + 1 and advanced.commands[2].tick == saved.tick \
		and advanced.commands[2].batch == saved.pending, "generation B batch is appended once at its pre-advance cursor in original order"):
		return
	if not _expect(host.step_operation(), "advance uninterrupted empty tick 5"):
		return
	var empty := _capture(host)
	if not _expect(not empty.is_empty() and empty.tick == 5 and empty.commands == advanced.commands \
		and empty.pending.is_empty(), "uninterrupted empty tick appends no command"):
		return
	_write_oracle(ORACLE_B, {
		"pid": OS.get_process_id(), "saved": saved, "advanced": advanced, "advanced_frame": advanced_frame,
		"empty": empty, "empty_frame": JSON.stringify(host.frame), "primary_sha": primary_sha, "previous_sha": previous_sha
	})


func _reopen() -> void:
	var earlier := _read_oracle(ORACLE_B)
	if earlier.is_empty() or not _expect(FileAccess.get_sha256(PRIMARY) == earlier.primary_sha \
		and FileAccess.get_sha256(PREVIOUS) == earlier.previous_sha, "both committed generations match before second resume"):
		return
	if not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == earlier.saved, "second resume restores exact generation B packet while paused"):
		return
	_start(host)
	if not _expect(host.step_operation() and _capture(host) == earlier.advanced \
		and JSON.stringify(host.frame) == earlier.advanced_frame, "second resume consumes ordered batch once with exact uninterrupted state, events and frame"):
		return
	_expect(host.step_operation() and _capture(host) == earlier.empty \
		and JSON.stringify(host.frame) == earlier.empty_frame, "resumed empty tick does not repeat a command")
	_expect(FileAccess.get_sha256(PRIMARY) == earlier.primary_sha and FileAccess.get_sha256(PREVIOUS) == earlier.previous_sha, \
		"both generations remain byte-identical through the second resume")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase: String = args[0] if args.size() == 1 else ""
	var profile := OS.get_environment("SBTK_P03_CURSOR_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(phase in ["seed", "rotate", "reopen"] and not profile.is_empty() and actual == expected \
		and ProjectSettings.get_setting("application/run/main_scene") == ENTRY, "isolated profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			match phase:
				"seed": await _seed()
				"rotate": await _rotate()
				"reopen": await _reopen()
	print("P03_PUBLIC_CURSOR_RESULT phase=%s checks=%d failures=%d pid=%d" % [phase, _checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
