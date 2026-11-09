extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const NAMES := ["busy_precedes_unsupported_cn", "unbusy_rejects_same_candidate", "progresses_after_both_rejections"]
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
		print("P03_BUSY_CN_PASS " + JSON.stringify(record))
		quit(0)
	else:
		print("P03_BUSY_CN_FAIL " + JSON.stringify(record))
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

func _warm_preserved(owner: OperationPrivateState, sim: BattleSim, st: BattleState, first: FleetState,
		second: FleetState, cache: Dictionary, busy: bool) -> bool:
	return (owner._ready and owner._busy == busy and is_same(owner._sim, sim) and is_same(sim.st, st)
		and is_same(st.fleets[0], first) and is_same(st.fleets[1], second) and is_same(st._idx, cache)
		and st._idx_n == 2 and _exact(st._idx.keys(), [1, 2])
		and is_same(st._idx[1], first) and is_same(st._idx[2], second))

func _time(view: Dictionary, tick: int, ai_timer: int, label: String) -> void:
	_check(_exact([view.state.tick, view.state.clock_ms, view.sim.sub_ms, view.state.ai_timer,
		view.state.next_event_id, view.state.reinf, view.state.reinf_ms], [tick, tick * 100, 50, ai_timer, 2, false, -1]),
		label + "_time")
	_check(_exact(view.fleets.map(func(f): return f.id), [1, 2]) and view.missiles.is_empty() and view.swarms.is_empty(),
		label + "_roster")

func _run() -> void:
	if "--force-gate-failure" in OS.get_cmdline_user_args():
		_check(_exact(0, 0.0), "intentional_gate_failure")
		_finish()
		return
	var profile := {"profile_id": "p03-busy-cn", "rules": PocSetup.profile().rules.duplicate(true),
		"ally": [{"name": "A", "role": "line", "ships": 10, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true, "wait": 1000}],
		"foe": [{"name": "B", "role": "line", "ships": 10, "lv": 1, "x": 1500, "y": 1000, "p": 0, "flag": true, "wait": 1000}], "reinf": []}
	var source := Private.create(profile, 41, 10, [])
	var control := Private.create(profile, 41, 10, [])
	if not _check(source.ok and control.ok, "create_both"):
		_finish()
		return
	var a: OperationPrivateState = source.owner
	var b: OperationPrivateState = control.owner
	_check(_guard(a) and _guard(b), "canonical_both")
	var command := {"tick": -1, "side": 0, "ids": [1], "kind": "stop", "target_id": -1, "point": Vector2.ZERO, "args": {}}
	var pending: Array[Dictionary] = [command]
	var events: Array[Dictionary] = [_event("spawn", 1, Vector2.ZERO, null), _event("spawn", 2, Vector2.ZERO, null)]
	for owner in [a, b]:
		_check(_exact(owner.advance(), {"ok": true}), "first_advance")
		_check(_exact(owner.queue(BattleSim.command(0, [1], "stop")), {"ok": true}), "queue_stop")
	var p := a.capture_completed()
	if not _check(p.ok and _exact(b.capture_completed(), p), "initial_capture_exact"):
		_finish()
		return
	var p_copy := p.duplicate(true)
	_time(p.packet.view, 1, 450, "initial")
	_check(p.packet.view.sim.command_log.is_empty() and _exact(p.packet.view.sim._queue, pending)
		and _exact(p.packet.view.sim._events, events), "initial_log_pending_events")
	var sim := a._sim
	var st := sim.st
	var first := st.by_id(1)
	var second := st.by_id(2)
	var cache: Dictionary = st._idx
	_check(_warm_preserved(a, sim, st, first, second, cache, false), "warm_setup")
	_check(sim.decisions == null, "decision_inactive")
	var m: Dictionary = p.packet.duplicate(true)
	m.view.state.reinf_ms = 0
	var m_copy := m.duplicate(true)
	var changed: Array[String] = []
	_diff(p.packet, m, "", changed)
	_check(changed == [".view.state.reinf_ms"] and typeof(m.view.state.reinf_ms) == TYPE_INT
		and p.packet.view.state.reinf_ms == -1 and m.view.state.reinf_ms == 0, "single_mutation")
	_check(Private._packet_error(m) == "", "structural_validation")

	a._busy = true
	_check(_exact(a.restore_completed(m), {"ok": false, "error": "busy"}), "exact_busy")
	_check(_warm_preserved(a, sim, st, first, second, cache, true), "busy_identity")
	_check(_exact(sim._queue, pending) and _exact(sim._events, events) and sim.command_log.is_empty(), "busy_pending_events")
	_check(_exact(m, m_copy) and _exact(p, p_copy), "busy_inputs")
	a._busy = false
	_check(_exact(a.capture_completed(), p), "busy_capture_after_release")
	names.append(NAMES[0])

	_check(_exact(a.restore_completed(m), {"ok": false, "error": "unsupported_reinforcement"}), "exact_unsupported")
	_check(_warm_preserved(a, sim, st, first, second, cache, false), "unsupported_identity")
	_check(_exact(sim._queue, pending) and _exact(sim._events, events) and sim.command_log.is_empty(), "unsupported_pending_events")
	_check(_exact(a.capture_completed(), p) and _exact(m, m_copy) and _exact(p, p_copy), "unsupported_inputs_capture")
	names.append(NAMES[1])

	var stop_at_one := command.duplicate(true)
	stop_at_one.tick = 1
	var applied: Array[Dictionary] = [stop_at_one]
	var say := _event("say", 1, Vector2(500, 500), "stop")
	say.tick = 1
	events.append(say)
	var results: Array[Dictionary] = []
	for owner in [a, b]:
		_check(_exact(owner.advance(), {"ok": true}), "next_advance")
		var captured: Dictionary = owner.capture_completed()
		if not _check(captured.ok, "next_capture"):
			_finish()
			return
		var view: Dictionary = captured.packet.view
		_time(view, 2, 350, "next")
		_check(_exact(view.sim.command_log, applied) and view.sim._queue.is_empty()
			and _exact(view.sim._events, events), "next_log_pending_events")
		_check(_exact([view.fleets[0].pos, view.fleets[0].has_move], [Vector2(500, 500), false]), "next_stop_effect")
		results.append(captured)
	_check(_exact(results[0], results[1]), "next_full_exact")
	_check(_exact(m, m_copy) and _exact(p, p_copy), "final_inputs_preserved")
	names.append(NAMES[2])
	a.close()
	b.close()
	_finish()

