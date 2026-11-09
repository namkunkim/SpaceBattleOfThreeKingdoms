extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const NAMES := ["clock_boundary", "restored_rng_address", "next_ai_evaluation"]
var failures: Array[String] = []
var checks := 0
var names: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures.append(label)
	return condition

func _metadata(value: Variant) -> Array:
	if value is Dictionary:
		return [value.get_typed_key_builtin(), value.get_typed_key_class_name(), value.get_typed_key_script(),
			value.get_typed_value_builtin(), value.get_typed_value_class_name(), value.get_typed_value_script()]
	return [value.get_typed_builtin(), value.get_typed_class_name(), value.get_typed_script()]

func _diff(a: Variant, b: Variant, path: String, diff: Array[String]) -> void:
	if typeof(a) != typeof(b):
		diff.append(path)
	elif a is Dictionary:
		if _metadata(a) != _metadata(b) or not _exact(a.keys(), b.keys()):
			diff.append(path)
		else:
			for key in a:
				_diff(a[key], b[key], path + "." + str(key), diff)
	elif a is Array:
		if _metadata(a) != _metadata(b) or a.size() != b.size():
			diff.append(path)
		else:
			for i in a.size():
				_diff(a[i], b[i], path + "." + str(i), diff)
	elif a is Object:
		if not is_same(a, b):
			diff.append(path)
	elif a != b:
		diff.append(path)

func _exact(a: Variant, b: Variant) -> bool:
	var diff: Array[String] = []
	_diff(a, b, "", diff)
	return diff.is_empty()

func _finish() -> void:
	var record := {"checks": checks, "cases": names, "failures": failures,
		"engine_pid": OS.get_process_id(), "engine_path": OS.get_executable_path()}
	if failures.is_empty() and names.size() == NAMES.size():
		print("P03_CLOCK_RNG_PASS " + JSON.stringify(record))
		quit(0)
	else:
		print("P03_CLOCK_RNG_FAIL " + JSON.stringify(record))
		quit(1)

func _event(kind: String, id: int, pos: Vector2, value: Variant) -> Dictionary:
	return {"tick": 0, "kind": kind, "sq": id, "other": -1, "pos": pos, "value": value}

func _guard(owner: OperationPrivateState) -> bool:
	var objects: Array[Object] = [owner, owner._sim, owner._sim.st, owner._sim.st.fleets[0]]
	var files := ["operation_private_state", "battle_sim", "battle_state", "fleet_state"]
	for i in objects.size():
		if objects[i].get_script().resource_path != "res://core/battle/" + files[i] + ".gd":
			return false
	return true

func _clock(owner: OperationPrivateState, expected: Array, label: String) -> void:
	var sim := owner._sim
	var st := sim.st
	var events: Array[Dictionary] = [_event("spawn", 1, Vector2.ZERO, null), _event("spawn", 2, Vector2.ZERO, null)]
	_check(_exact([st.tick, st.clock_ms, sim.sub_ms, st.ai_timer, st.next_event_id], expected), label + "_time")
	_check(_exact(sim._events, events) and sim._queue.is_empty() and sim.command_log.is_empty(), label + "_events")
	_check(not st.over and _exact(st.fleets.map(func(f): return f.id), [1, 2]), label + "_roster")

func _rng(owner: OperationPrivateState, sub: int, u32: int, bp: int, label: String) -> void:
	var sim := owner._sim
	var eid := sim.st.next_event_id
	var tick := sim.st.tick
	_check(_exact(sim.rng.profile_id, "p03-clock-rng|41"), label + "_profile")
	_check(_exact(sim.rng.u32(tick, eid, sub), u32), label + "_u32")
	_check(_exact(sim.rng.bp(tick, eid, sub), bp), label + "_bp")
	_check(_exact(sim.st.next_event_id, eid), label + "_no_consumption")

func _run() -> void:
	if "--force-gate-failure" in OS.get_cmdline_user_args():
		_check(_exact(0, 0.0), "intentional_gate_failure")
		_finish()
		return
	var profile := {"profile_id": "p03-clock-rng", "rules": PocSetup.profile().rules.duplicate(true),
		"ally": [{"name": "A", "role": "line", "ships": 10, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true, "wait": 1000}],
		"foe": [{"name": "B", "role": "line", "ships": 10, "lv": 1, "x": 1500, "y": 1000, "p": 0, "flag": true, "wait": 1000}], "reinf": []}
	var source := Private.create(profile, 41, 10, [])
	var target := Private.create(profile, 41, 10, [])
	if not _check(source.ok and target.ok, "create_owners"):
		_finish()
		return
	var a: OperationPrivateState = source.owner
	var b: OperationPrivateState = target.owner
	_check(_guard(a) and _guard(b), "class_guard")
	_clock(a, [0, 0, 0, 0, 1], "start")
	for i in 5:
		_check(_exact(a.advance(), {"ok": true}), "advance_" + str(i + 1))
		if i == 0:
			_clock(a, [1, 100, 50, 450, 2], "first")
	_clock(a, [5, 500, 50, 50, 2], "fifth")
	var p := a.capture_completed()
	if not _check(p.ok, "capture_p"):
		_finish()
		return
	names.append(NAMES[0])

	var old_rng := b._sim.rng
	_check(_exact(b.restore_completed(p.packet), {"ok": true}), "restore")
	_check(not is_same(b._sim.rng, old_rng) and not is_same(b._sim.rng, a._sim.rng), "restored_rng_identity")
	_check(_guard(b), "restored_class_guard")
	_clock(b, [5, 500, 50, 50, 2], "restored_fifth")
	for owner in [a, b]:
		_rng(owner, 0, 3600336925, 6925, "fifth_default_sub")
		_rng(owner, 1, 2671758521, 8521, "fifth_nonzero_sub")
	_check(_exact(b.capture_completed(), p) and _exact(a.capture_completed(), p), "full_restored_exact")
	names.append(NAMES[1])

	for owner in [a, b]:
		_check(_exact(owner.advance(), {"ok": true}), "advance_six")
		_clock(owner, [6, 600, 50, 500, 3], "sixth")
		_rng(owner, 0, 3339876617, 6617, "sixth_default_sub")
	var final_a := a.capture_completed()
	var final_b := b.capture_completed()
	_check(final_a.ok and final_b.ok and _exact(final_a, final_b), "full_post_advance_exact")
	names.append(NAMES[2])
	a.close()
	b.close()
	_finish()

