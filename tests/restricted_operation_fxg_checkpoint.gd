extends SceneTree

const Host := preload("res://scenes/RestrictedOperationHost.tscn")
const INPUT_SHA := "cfe28ef673bf953ba6c864788206ec37f213c6a2b983295810c7fd0b88429270"
const SLOT := "user://restricted-operation-host.pcopstate"
const ORACLE := "user://restricted-operation-fxg-oracle"

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var profile := OS.get_environment("SBTK_FXG_CHECKPOINT_PROFILE").replace("\\", "/")
	var user_path := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if _check(args.size() == 1 or (args.size() == 2 and args[1] in ["seed", "reopen"]),
			"pass the byte-preserved FX-G fixture path and optional seed/reopen mode") \
			and _check(not profile.is_empty() and user_path.begins_with(profile + "/"),
				"Godot uses the explicitly isolated profile") \
			and _check(FileAccess.get_sha256(args[0]) == INPUT_SHA, "frozen FX-G host input hash"):
		var mode := args[1] if args.size() == 2 else "round-trip"
		_run_mode(args[0], mode)
		_check(FileAccess.get_sha256(args[0]) == INPUT_SHA, "frozen input bytes unchanged")
	print("FXG_CHECKPOINT %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _run_mode(input: String, mode: String) -> void:
	if mode != "reopen" and not _check(not FileAccess.file_exists(SLOT)
			and not FileAccess.file_exists(SLOT + ".previous") and not FileAccess.file_exists(ORACLE),
			"checkpoint generations and oracle start empty"):
		return
	var host := Host.instantiate()
	root.add_child(host)
	if mode == "reopen":
		var file := FileAccess.open(ORACLE, FileAccess.READ)
		if _check(file != null, "read the seed oracle"):
			var expected: Variant = file.get_var()
			file.close()
			if _check(expected is Dictionary and expected.get("pid", 0) > 0
					and expected.pid != OS.get_process_id(),
					"oracle belongs to a different Godot process, current pid=%d" % OS.get_process_id()):
				_reopen(host, input, expected)
	else:
		var expected := _seed(host, input)
		if not expected.is_empty():
			if mode == "seed":
				var file := FileAccess.open(ORACLE, FileAccess.WRITE)
				if _check(file != null and file.store_var(expected), "write oracle for pid=%d" % expected.pid):
					file.close()
			else:
				var resumed := Host.instantiate()
				root.add_child(resumed)
				_resume(resumed, input, expected)
				resumed.free()
	host.free()


func _seed(original, input: String) -> Dictionary:
	var prepared: Dictionary = original.load_runtime_file(input)
	if not _check(prepared.ok, "prepare restricted host: %s" % prepared):
		return {}
	if not _check(original._summary.tick == 0 and original._summary.clock_ms == 0
			and original.advance().ok and original._summary.tick == 1
			and original._summary.clock_ms == 100 and not original._summary.over,
			"uninterrupted host reaches the nonterminal 100 ms boundary"):
		return {}
	var saved_frame := _frame(original)
	original._save_slot.pressed.emit()
	var slot_sha := FileAccess.get_sha256(SLOT)
	if not _check(original._status.text == "Saved slot at tick 1" and not slot_sha.is_empty(),
			"restricted save control commits tick 1: " + original._status.text):
		return {}
	if not _check(original.advance().ok and _terminal(original._summary),
			"uninterrupted host ends at tick 2 / 150 ms"):
		return {}
	var expected := _frame(original)
	var expected_events: Dictionary = original._operation.drain_events()
	if not _check(expected_events.ok and expected_events.events.filter(
			func(event): return event.kind == "battle_end").size() == 1,
			"uninterrupted terminal event appears once"):
		return {}

	return {"pid": OS.get_process_id(), "saved_frame": saved_frame, "slot_sha": slot_sha,
		"frame": expected, "events": expected_events}


func _reopen(host, input: String, expected: Dictionary) -> void:
	if _check(FileAccess.get_sha256(SLOT) == expected.slot_sha
			and not FileAccess.file_exists(SLOT + ".previous"),
			"original checkpoint bytes are intact before reopening"):
		_resume(host, input, expected)


func _resume(resumed, input: String, expected: Dictionary) -> void:
	if not _check(resumed.load_runtime_file(input).ok and resumed._summary.tick == 0,
			"separate restricted host prepares at tick 0"):
		return
	resumed._restore_slot.pressed.emit()
	if not _check(resumed._status.text == "Restored slot at tick 1" and _frame(resumed) == expected.saved_frame,
			"restore control reconstructs exact 100 ms state: " + resumed._status.text):
		return
	if not _check(resumed.advance().ok and _terminal(resumed._summary) and _frame(resumed) == expected.frame,
			"resumed terminal clock, owner state, projection and display equal the uninterrupted host"):
		return
	var actual_events: Dictionary = resumed._operation.drain_events()
	_check(actual_events == expected.events, "resumed terminal event batch equals uninterrupted")
	_check(not resumed.advance().ok and _terminal(resumed._summary)
			and resumed._operation.drain_events().events.is_empty(),
			"terminal host rejects further advance without emitting events")
	_check(FileAccess.get_sha256(SLOT) == expected.slot_sha and not FileAccess.file_exists(SLOT + ".previous"),
			"resume and terminal advance preserve checkpoint bytes")


func _terminal(summary: Dictionary) -> bool:
	return summary.tick == 2 and summary.clock_ms == 150 and summary.end_tick == 2 \
		and summary.end_ms == 150 and summary.over and summary.win and summary.reason == "annihilation"


func _frame(host) -> Dictionary:
	return {"owner": host._operation.observe(), "summary": host._summary.duplicate(true),
		"projection": host._projection.duplicate(true), "display": host._view.text}


func _check(condition: bool, description: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print("FXG_CHECKPOINT_CHECK ", condition, " ", description)
	return condition
