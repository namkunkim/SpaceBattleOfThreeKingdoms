extends SceneTree

const Host := preload("res://scenes/RestrictedOperationHost.tscn")
const Store := preload("res://scripts/first_operation_save_store.gd")
const ORACLE := "user://restricted-slot-test-oracle"
var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := {"profile_id": "operating-checkpoint-poc", "rules": PocSetup.profile().rules,
		"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
		"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 750, "y": 500, "p": 0, "flag": true}],
		"reinf": []}
	var input := {"mode": "operation", "format": "p02/restricted-headless/1", "profile": profile,
		"seed": 20824, "hz": 10, "initial_controls": [], "policy": "none", "max_ticks": 500}
	var host := Host.instantiate()
	root.add_child(host)
	expect(host._save_slot.disabled and host._restore_slot.disabled, "requires prepared host")
	var prepared: Dictionary = host.prepare(input)
	expect(prepared.ok, "prepare host: %s" % prepared)
	var reopening := "--verify-restart" in OS.get_cmdline_user_args()
	if prepared.ok:
		if reopening:
			_reopen(host)
		else:
			_save_and_restore(host, input)
	host.free()
	print("RESTRICTED_SLOT_HOST %s %d/%d" % ["REOPEN" if reopening else "SAVE", checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _save_and_restore(host, input: Dictionary) -> void:
	expect(not host._save_slot.disabled and not host._restore_slot.disabled, "both controls available")
	expect(host.issue(BattleSim.command(0, [1], "missile", 2)).ok
		and host.issue(BattleSim.command(1, [2], "fighter", 1)).ok and host.advance().ok, "launch projectiles")
	var stop := BattleSim.command(0, [1], "stop")
	expect(host.queue(stop).ok, "queue third command")
	var saved: Dictionary = _frame(host)
	expect(saved.summary.tick == 1 and saved.summary.clock_ms == 100
		and not saved.state.missiles.is_empty() and not saved.state.swarms.is_empty(), "save with active projectiles and clock")
	host._save_slot.pressed.emit()
	var slot: String = host.SLOT_PATH
	var stored := Store.read(slot)
	expect(host._status.text == "Saved slot at tick 1" and stored.ok, "save control writes slot: %s %s" % [host._status.text, stored.get("error")])
	if not stored.ok:
		return
	expect(stored.payload.host_max_ticks == 500 and stored.payload.last_applied_seq == 2
		and stored.payload.last_accepted_seq == 3, "slot stores host limit and command cursors")
	var original := FileAccess.get_file_as_bytes(slot)
	expect(host.advance().ok, "uninterrupted advance")
	var advanced := _frame(host)
	expect(advanced.state.sim.command_log.size() == 3 and advanced.state.sim._queue.is_empty(), "third command applied once")
	expect(host.queue(stop).ok, "failure probe starts with pending input")
	var active := _frame(host)
	var owner: OperationPrivateState = host._operation
	expect(FileAccess.open(slot, FileAccess.WRITE).store_buffer("broken".to_utf8_buffer()), "corrupt slot fixture")
	host._restore_slot.pressed.emit()
	expect(not host._status.text.begins_with("Restored") and not host._status.text.is_empty()
		and host._operation == owner and _frame(host) == active, "corruption preserves owner, display, queue and clock")
	expect(FileAccess.open(slot, FileAccess.WRITE).store_buffer(original), "replace original slot")

	var other := Host.instantiate()
	root.add_child(other)
	var different := input.duplicate(true)
	different.max_ticks = 501
	expect(other.prepare(different).ok and other.advance().ok and other.queue(stop).ok, "prepare different limit with pending input")
	var other_frame := _frame(other)
	var other_owner: OperationPrivateState = other._operation
	other._restore_slot.pressed.emit()
	expect(other._status.text == "checkpoint_host_limit_mismatch / host_max_ticks"
		and other._operation == other_owner and _frame(other) == other_frame, "different max_ticks preserves owner and display")
	other.free()

	host._restore_slot.pressed.emit()
	expect(host._status.text == "Restored slot at tick 1" and host._operation == owner
		and _frame(host) == saved, "restore control restores exact completed frame")
	expect(host.advance().ok and _frame(host) == advanced, "restored queue applies exactly once")
	var oracle := FileAccess.open(ORACLE, FileAccess.WRITE)
	expect(oracle != null and oracle.store_var({"saved": saved, "advanced": advanced}), "write process-independent oracle")


func _reopen(host) -> void:
	var oracle := FileAccess.open(ORACLE, FileAccess.READ)
	expect(oracle != null, "read oracle from first process")
	if oracle == null:
		return
	var expected: Dictionary = oracle.get_var()
	expect(host._summary.tick == 0 and host._summary.commands == 0, "fresh process starts at tick zero")
	host._restore_slot.pressed.emit()
	expect(host._status.text == "Restored slot at tick 1" and _frame(host) == expected.saved,
		"fresh process restores exact frame and pending input")
	expect(host.advance().ok and _frame(host) == expected.advanced, "fresh process applies pending input once")


func _frame(host) -> Dictionary:
	return {"state": host._operation.observe(), "summary": host._summary.duplicate(true),
		"projection": host._projection.duplicate(true), "display": host._view.text}


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("RESTRICTED_SLOT_FAIL ", label)

