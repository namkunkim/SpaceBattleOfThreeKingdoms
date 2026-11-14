extends SceneTree

const Slot := preload("res://scripts/lantern_escort/public_slot.gd")
const Runtime := preload("res://scripts/lantern_escort/runtime.gd")
const CrossSlot := preload("res://scripts/cross_counter/public_slot.gd")
const RedCliffs := preload("res://scripts/first_operation_settlement_store.gd")
const WITNESS := "user://lantern-public-integration.witness"

var _checks := 0
var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var profile := OS.get_environment("SBTK_LANTERN_TEST_PROFILE").replace("\\", "/")
	var actual := OS.get_user_data_dir().replace("\\", "/")
	if not _check(args.size() == 1 and OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and profile.begins_with("F:/WorkSpace/Campaign-Orchestration/") and actual.begins_with(profile + "/"),
			"explicit isolated profile"):
		_finish("invalid")
		return
	var parent_hash := FileAccess.get_sha256(CrossSlot.SLOT_PATH)
	var red_hash := FileAccess.get_sha256(RedCliffs.PRODUCT_SLOT_PATH)
	change_scene_to_file("res://scenes/entry/EntryBoot.tscn")
	for attempt in 120:
		await process_frame
		if current_scene is WorldMapScreen and current_scene._lantern_menu != null:
			break
	if not _check(current_scene is WorldMapScreen and not parent_hash.is_empty() and not red_hash.is_empty(),
			"normal public campaign entry with parent records"):
		_finish(args[0])
		return
	var map: WorldMapScreen = current_scene
	await process_frame
	if args[0] == "failed_parent":
		_check(not map._lantern_menu.visible and map._lantern_parents.is_empty()
			and not FileAccess.file_exists(Slot.SLOT_PATH), "failed Cross Counter has no card or slot")
	else:
		_run_public_phase(map, args[0])
	_check(FileAccess.get_sha256(CrossSlot.SLOT_PATH) == parent_hash
		and FileAccess.get_sha256(RedCliffs.PRODUCT_SLOT_PATH) == red_hash, "both parent ledgers unchanged")
	_finish(args[0])


func _run_public_phase(map: WorldMapScreen, phase: String) -> void:
	if not _check(map._lantern_menu.is_visible_in_tree() and map._lantern_parents.size() == 1,
			"successful Cross Counter exposes one public card"):
		return
	var popup := map._lantern_menu.get_popup()
	var label := popup.get_item_text(0)
	match phase:
		"save":
			_check(label.begins_with("출격"), "unused parent starts a child")
		"resume", "after_escape":
			_check(label.begins_with("재개"), "active child offered after restart")
		"receipt":
			_check(label.begins_with("결산 보기"), "completed parent offers receipt")
	popup.id_pressed.emit(0)
	var host := map._lantern_host
	if not _check(host != null and not map.hud.visible, "public menu installs host: " + map._chip_label.text):
		return
	match phase:
		"save":
			_save(host, map)
		"resume":
			_pause_after_escape(host, map)
		"after_escape":
			_resume(host, map)
		"receipt":
			_receipt(host, map)
		_:
			_check(false, "known phase")


func _save(host: Control, map: WorldMapScreen) -> void:
	if not _check(host._slot.head().active.packet.tick == 0 and host._operation != null,
			"durable C0 before play"):
		return
	host._play.pressed.emit()
	host.set_process(false)
	host._queue("move", Vector2(820, 200))
	for index in 390:
		host._process(0.1)
	host._queue("move", Vector2(1360, 930))
	var packet: Dictionary = host._operation.capture()
	_check(packet.tick == 390 and packet.pending.size() == 1, "second wave order still pending")
	host._save.pressed.emit()
	host.set_process(false)
	_check(host._slot.head().active.packet == packet, "public save commits exact pending packet")
	var output := FileAccess.open(WITNESS, FileAccess.WRITE)
	if output != null:
		output.store_var(packet)
		output.close()
	_check(output != null, "restart witness saved")
	host.leave()
	_check(map._lantern_host == null and map.hud.visible, "return to map saves and releases host")


func _pause_after_escape(host: Control, map: WorldMapScreen) -> void:
	var input := FileAccess.open(WITNESS, FileAccess.READ)
	if not _check(input != null and host._operation != null and not host._running, "restored host paused"):
		return
	var packet: Dictionary = input.get_var()
	input.close()
	_check(host._operation.capture() == packet, "new process restored exact pending packet")
	host._play.pressed.emit()
	host.set_process(false)
	while host._operation.tick < 956 and not host._terminal and not host._blocked:
		host._process(0.1)
	_check(host._operation.tick == 956 and host._frame.escaped == 1 and not host._terminal,
		"lead escape recorded before terminal")
	var after_escape: Dictionary = host._operation.capture()
	_check(after_escape.event_cursor == host._frame.events.size(), "public host consumed lead escape")
	var output := FileAccess.open(WITNESS, FileAccess.WRITE)
	output.store_var(after_escape)
	output.close()
	host.leave()
	_check(map._lantern_host == null, "save after escape returns to map")

func _resume(host: Control, map: WorldMapScreen) -> void:
	var input := FileAccess.open(WITNESS, FileAccess.READ)
	if not _check(input != null and host._operation != null and not host._running, "restored host paused"):
		return
	var packet: Dictionary = input.get_var()
	input.close()
	_check(host._operation.capture() == packet, "new process restored same ID, tick, history and cursor")
	_check(host._operation.drain_events().is_empty(), "previous escape never redelivered")
	host._play.pressed.emit()
	host.set_process(false)
	while not host._terminal and not host._blocked and host._operation.tick < Runtime.LIMIT:
		host._process(0.1)
	var result: Dictionary = host._operation.settlement
	_check(host._terminal and result.get("escaped") == 2 and result.get("tick") == 1048,
		"public host commits two-ship rescue at tick 1048")
	var replay := Runtime.restore(host._operation.capture())
	_check(replay.ok and replay.runtime.projection() == host._operation.projection(),
		"read-only replay obtains exact host projection, ordered events and receipt")
	var head: Dictionary = host._slot.head()
	_check(head.active.is_empty() and head.completed.size() == 1, "single receipt replaces active slot")
	if not _failed:
		var output := FileAccess.open(WITNESS + ".terminal", FileAccess.WRITE)
		output.store_var(result)
		output.close()
	host.leave()
	_check(map._lantern_host == null and map.hud.visible, "terminal returns to public map")


func _receipt(host: Control, map: WorldMapScreen) -> void:
	var input := FileAccess.open(WITNESS + ".terminal", FileAccess.READ)
	if not _check(input != null and host._terminal and host._operation == null, "receipt view has no active owner"):
		return
	var expected: Dictionary = input.get_var()
	input.close()
	var head: Dictionary = host._slot.head()
	_check(head.active.is_empty() and head.completed.size() == 1
		and head.completed[map._lantern_parents[0]].settlement == expected,
		"repeated public request reopens exact committed receipt")
	host.leave()
	_check(map._lantern_host == null, "receipt returns to map")


func _check(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failed += 1
	print("LANTERN_PUBLIC_CHECK ", condition, " ", label)
	return condition


func _finish(phase: String) -> void:
	print("LANTERN_PUBLIC %s %d/%d" % [phase, _checks - _failed, _checks])
	quit(1 if _failed else 0)
