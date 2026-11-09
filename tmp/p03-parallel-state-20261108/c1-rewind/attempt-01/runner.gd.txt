extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const NAMES := ["capture_noninitial_issue_boundary", "restore_earlier_on_same_owner", "replay_suffix_after_rewind"]
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
		print("P03_C1_REWIND_PASS " + JSON.stringify(record))
		quit(0)
	else:
		print("P03_C1_REWIND_FAIL " + JSON.stringify(record))
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

func _command(kind: String, tick: int, point := Vector2.ZERO) -> Dictionary:
	return {"tick": tick, "side": 0, "ids": [1], "kind": kind, "target_id": -1, "point": point, "args": {}}

func _missile_guard(sim: BattleSim) -> bool:
	var enclosing: Script = sim.st.get_script()
	var expected: Script = BattleState.Missile.new().get_script()
	var member: Variant = enclosing.get_script_constant_map().get("Missile")
	var matches := enclosing.resource_path == "res://core/battle/battle_state.gd" and is_same(member, expected)
	var observed: Array[String] = []
	for missile in sim.st.missiles:
		var actual: Script = missile.get_script()
		observed.append(actual.resource_path)
		matches = matches and is_same(actual, expected)
	print("P03_C1_MISSILE_SCRIPT " + JSON.stringify({"enclosing": enclosing.resource_path, "prototype": expected.resource_path,
		"missiles": observed, "canonical_member_matches": matches}))
	return matches

func _missiles(view: Dictionary, age: int, label: String) -> void:
	var missiles: Array = view.missiles
	_check(_exact(missiles.map(func(m): return m.id), [2, 3, 4, 5, 6, 7]), label + "_ids")
	_check(missiles.all(func(m): return _exact([m.src_id, m.target_id, m.side, m.age, m.dead],
		[1, 2, 0, age, false])), label + "_references")

func _advance_oracle(view: Dictionary, tick: int, ai_timer: int, initial: Array, label: String) -> void:
	_check(_exact([view.state.tick, view.state.clock_ms, view.sim.sub_ms, view.state.ai_timer,
		view.state.next_event_id], [tick, tick * 100, 50, ai_timer, 9]), label + "_time")
	_missiles(view, tick * 100, label)
	for i in 6:
		_check(_exact(view.missiles[i].v, (initial[i].v + 6.0) + 6.0)
			and view.missiles[i].pos != initial[i].pos, label + "_velocity_position_" + str(i))

func _cut_state(view: Dictionary, moving: bool, commands: Array[Dictionary], events: Array[Dictionary], label: String) -> void:
	_check(_exact(view.sim.command_log, commands) and view.sim._queue.is_empty()
		and _exact(view.sim._events, events), label + "_log_and_events")
	var fleet: Dictionary = view.fleets[0]
	_check(_exact([fleet.control, fleet.has_move, fleet.pos], ["direct", moving, Vector2(500, 500)]), label + "_fleet")
	if moving:
		_check(_exact(fleet.move_to, Vector2(600, 500)), label + "_move_target")

func _say_at_one(kind: String) -> Dictionary:
	var event := _event("say", 1, Vector2(500, 500), kind)
	event.tick = 1
	return event

func _suffix(owner: OperationPrivateState, label: String) -> Dictionary:
	_check(_exact(owner.issue(_command("stop", -1)), {"ok": true}), label + "_issue_stop")
	_check(_exact(owner.advance(), {"ok": true}), label + "_advance")
	var captured := owner.capture_completed()
	_check(captured.ok, label + "_capture")
	return captured

func _run() -> void:
	if "--force-gate-failure" in OS.get_cmdline_user_args():
		_check(_exact(0, 0.0), "intentional_gate_failure")
		_finish()
		return
	var profile := {"profile_id": "p03-c1-rewind", "rules": PocSetup.profile().rules.duplicate(true),
		"ally": [{"name": "A", "role": "line", "ships": 10, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true, "wait": 1000}],
		"foe": [{"name": "B", "role": "line", "ships": 10, "lv": 1, "x": 1500, "y": 1000, "p": 0, "flag": true, "wait": 1000}], "reinf": []}
	var created := Private.create(profile, 41, 10, [])
	if not _check(created.ok, "create_owner"):
		_finish()
		return
	var owner: OperationPrivateState = created.owner
	_check(_guard(owner), "canonical_original")
	owner._sim.debug_fire_missiles(1, 2)
	var launch := owner.capture_completed()
	if not _check(launch.ok, "capture_launch"):
		_finish()
		return
	_check(_missile_guard(owner._sim), "canonical_launch_missiles")
	var events: Array[Dictionary] = [_event("spawn", 1, Vector2.ZERO, null), _event("spawn", 2, Vector2.ZERO, null),
		{"tick": 0, "kind": "missile_launch", "sq": 1, "other": 2, "pos": Vector2(500, 500), "value": null}]
	_check(_exact(owner.advance(), {"ok": true}), "first_advance")
	var first := owner.capture_completed()
	if not _check(first.ok, "capture_first_advance"):
		_finish()
		return
	var initial: Array = launch.packet.view.missiles
	var before_move: Dictionary = first.packet.view
	_advance_oracle(before_move, 1, 450, initial, "first")
	_check(_exact(before_move.sim._events, events) and before_move.sim._queue.is_empty()
		and before_move.sim.command_log.is_empty(), "first_events_empty_commands")
	_check(_exact(owner.issue(_command("move", -1, Vector2(600, 500))), {"ok": true}), "issue_move")
	var p := owner.capture_completed()
	if not _check(p.ok, "capture_p"):
		_finish()
		return
	var p_copy := p.duplicate(true)
	var p_view: Dictionary = p.packet.view
	var commands: Array[Dictionary] = [_command("move", 1, Vector2(600, 500))]
	events.append(_say_at_one("move"))
	_advance_oracle(p_view, 1, 450, initial, "cut")
	_check(_exact(p_view.missiles, before_move.missiles), "issue_does_not_advance_missiles")
	_cut_state(p_view, true, commands, events, "cut")
	names.append(NAMES[0])

	var q := _suffix(owner, "forward")
	if not q.ok:
		_finish()
		return
	var q_copy := q.duplicate(true)
	var q_view: Dictionary = q.packet.view
	commands.append(_command("stop", 1))
	events.append(_say_at_one("stop"))
	_advance_oracle(q_view, 2, 350, p_view.missiles, "forward")
	_cut_state(q_view, false, commands, events, "forward")
	_check(_exact(p, p_copy), "p_survives_forward")

	var old_sim := owner._sim
	var old_state := old_sim.st
	var old_fleets := old_state.fleets.duplicate()
	var old_missiles := old_state.missiles.duplicate()
	_check(_exact(owner.restore_completed(p.packet), {"ok": true}), "restore_p_on_same_owner")
	_check(not is_same(owner._sim, old_sim) and not is_same(owner._sim.st, old_state), "fresh_target_sim_and_state")
	for i in 2:
		_check(not is_same(owner._sim.st.fleets[i], old_fleets[i])
			and is_same(owner._sim.st.by_id(i + 1), owner._sim.st.fleets[i]), "fresh_fleet_" + str(i))
	for i in 6:
		var missile := owner._sim.st.missiles[i]
		_check(not is_same(missile, old_missiles[i])
			and is_same(owner._sim.st.by_id(missile.src_id), owner._sim.st.fleets[0])
			and is_same(owner._sim.st.by_id(missile.target_id), owner._sim.st.fleets[1]), "fresh_missile_" + str(i))
	_check(_guard(owner) and _missile_guard(owner._sim), "restored_canonical")
	var rewound := owner.capture_completed()
	if not _check(rewound.ok, "capture_rewound"):
		_finish()
		return
	_check(_exact(rewound, p) and not _exact(rewound, q) and _exact(p, p_copy), "rewind_exact")
	_advance_oracle(rewound.packet.view, 1, 450, initial, "rewound")
	var p_commands: Array[Dictionary] = [_command("move", 1, Vector2(600, 500))]
	var p_events: Array[Dictionary] = events.slice(0, 4)
	_cut_state(rewound.packet.view, true, p_commands, p_events, "rewound")
	names.append(NAMES[1])

	var replayed := _suffix(owner, "replay")
	if not replayed.ok:
		_finish()
		return
	_advance_oracle(replayed.packet.view, 2, 350, p_view.missiles, "replay")
	_cut_state(replayed.packet.view, false, commands, events, "replay")
	_check(_exact(replayed, q), "replay_exact_q")
	_check(_exact(p, p_copy) and _exact(q, q_copy), "both_captures_stable")
	names.append(NAMES[2])
	owner.close()
	_finish()

