extends SceneTree

const Slot := preload("res://scripts/orim_signal/public_slot.gd")
const Runtime := preload("res://scripts/orim_signal/runtime.gd")
const Lantern := preload("res://scripts/lantern_escort/public_slot.gd")

const WITNESS := "user://orim-public-witness"
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var root_path := OS.get_environment("SBTK_ORIM_TEST_PROFILE").replace("\\", "/")
	if not _check(args.size() == 1 and OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and root_path.begins_with("F:/WorkSpace/Campaign-Orchestration/")
			and OS.get_user_data_dir().replace("\\", "/").begins_with(root_path + "/"), "isolated Windows profile"):
		quit(1)
		return
	var hashes := _parent_hashes()
	change_scene_to_file("res://scenes/entry/EntryBoot.tscn")
	for index in 120:
		await process_frame
		if current_scene is WorldMapScreen and current_scene._orim_menu != null:
			break
	if _check(current_scene is WorldMapScreen and not "" in hashes, "public EntryBoot opens campaign map"):
		var map: WorldMapScreen = current_scene
		await process_frame
		if args[0] == "failure":
			_check(not map._orim_menu.visible and not FileAccess.file_exists(Slot.SLOT_PATH),
				"Lantern loss creates neither menu nor Orim slot")
		else:
			_run_phase(map, args[0])
	_check(_parent_hashes() == hashes, "Lantern, Cross Counter and Red Cliffs files unchanged")
	print("ORIM_PUBLIC %s %d/%d" % [args[0], checks - failures, checks])
	quit(1 if failures > 0 else 0)


func _run_phase(map: WorldMapScreen, phase: String) -> void:
	if not _check(map._orim_menu.visible and map._orim_parents.size() == 1, "success exposes one menu entry"):
		return
	var popup := map._orim_menu.get_popup()
	popup.id_pressed.emit(0)
	var host := map._orim_host
	if not _check(host != null and not map.hud.visible, "menu installs Orim host: " + map._chip_label.text):
		return
	var parent: Dictionary = Slot.read_parents().parents[map._orim_parents[0]]
	var escaped: int = parent.receipt.settlement.escaped
	_check(host._epilogue.text.contains("호송선 %d척" % escaped), "verified Lantern evacuation count appears in epilogue")
	match phase:
		"save":
			_save(host)
		"resume":
			_resume(host)
		"receipt":
			var expected := _read_witness(WITNESS + ".receipt")
			var head: Dictionary = host._slot.head()
			_check(host._terminal and host._operation == null and head.active.is_empty()
				and head.completed.size() == 1 and head.completed[map._orim_parents[0]].settlement == expected,
				"completed parent reopens identical receipt without launching another operation")
		_:
			_check(false, "known test phase")
	host.leave()
	_check(map._orim_host == null and map.hud.visible, "return to world map")


func _save(host: Control) -> void:
	if not _check(host._operation != null and host._slot.head().active.packet.tick == 0,
			"C0 committed before publication"):
		return
	host._play.pressed.emit()
	host.set_process(false)
	host._choose_unit("gan-ning")
	host._queue("move", Vector2(825, 570))
	host._choose_unit("lu-su")
	host._queue("move", Vector2(850, 630))
	while not host._terminal and not host._blocked and host._operation.tick < Runtime.LIMIT:
		host._process(0.1)
		if host._frame.transmission >= 30:
			break
	if not _check(host._frame.transmission == 30 and not host._terminal, "transmission active before save"):
		return
	host._choose_unit("gan-ning")
	host._queue("stop")
	var packet: Dictionary = host._operation.capture()
	host._play.pressed.emit()
	_check(not host._running and host._operation.capture() == packet, "pause does not change logical frontier")
	host._save.pressed.emit()
	_check(host._slot.head().active.packet == packet and packet.pending.size() == 1, "pause preserves and saves pending")
	_write_witness(WITNESS, packet)


func _resume(host: Control) -> void:
	var packet := _read_witness(WITNESS)
	if not _check(host._operation != null and not host._running and host._operation.capture() == packet,
			"separate PID resumes exact record before advancing"):
		return
	_check(host._operation.drain_events().is_empty(), "old mission events are not redelivered")
	host._play.pressed.emit()
	host.set_process(false)
	host._process(0.1)
	var next: Dictionary = host._operation.capture()
	_check(next.applied[-1].batch == packet.pending and next.pending.is_empty(), "pending stop applied exactly once")
	while not host._terminal and not host._blocked and host._operation.tick < Runtime.LIMIT:
		host._process(0.1)
	var completed: Dictionary = host._operation.capture()
	if not _check(host._terminal and completed.settlement.get("reason") == "signal_sent", "one signal success settlement"):
		return
	var active_hash := FileAccess.get_sha256(Slot.SLOT_PATH)
	var replay := Runtime.restore(completed)
	_check(replay.ok and replay.runtime.projection() == host._operation.projection()
		and FileAccess.get_sha256(Slot.SLOT_PATH) == active_hash, "read-only replay matches clock, ordered events and settlement")
	_write_witness(WITNESS + ".receipt", completed.settlement)


func _parent_hashes() -> Array:
	return [
		FileAccess.get_sha256(Lantern.SLOT_PATH),
		FileAccess.get_sha256("user://cross-counter-successor-v1.save"),
		FileAccess.get_sha256("user://pc-first-operation-product-v1-settlements.save"),
	]


func _read_witness(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	return file.get_var() if file != null else {}


func _write_witness(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if _check(file != null, "witness recorded"):
		file.store_var(value)


func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("ORIM_PUBLIC_CHECK ", ok, " ", label)
	return ok
