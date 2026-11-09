extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const NAMES := ["combined_cut", "restore_active_pending", "advance_once_in_order"]
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
		print("P03_COMBINED_CUT_PASS " + JSON.stringify(record))
		quit(0)
	else:
		print("P03_COMBINED_CUT_FAIL " + JSON.stringify(record))
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
	print("P03_COMBINED_MISSILE_SCRIPT " + JSON.stringify({"enclosing": enclosing.resource_path, "prototype": expected.resource_path,
		"missiles": observed, "canonical_member_matches": matches}))
	return matches

func _missiles(view: Dictionary, age: int, label: String) -> void:
	var missiles: Array = view.missiles
	_check(_exact(missiles.map(func(m): return m.id), [2, 3, 4, 5, 6, 7]), label + "_ids")
	_check(missiles.all(func(m): return _exact([m.src_id, m.target_id, m.side, m.age, m.dead],
		[1, 2, 0, age, false])), label + "_references")

func _run() -> void:
	if "--force-gate-failure" in OS.get_cmdline_user_args():
		_check(_exact(0, 0.0), "intentional_gate_failure")
		_finish()
		return
	var profile := {"profile_id": "p03-combined-cut", "rules": PocSetup.profile().rules.duplicate(true),
		"ally": [{"name": "A", "role": "line", "ships": 10, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true, "wait": 1000}],
		"foe": [{"name": "B", "role": "line", "ships": 10, "lv": 1, "x": 1500, "y": 1000, "p": 0, "flag": true, "wait": 1000}], "reinf": []}
	var source := Private.create(profile, 41, 10, [])
	var target := Private.create(profile, 41, 10, [])
	if not _check(source.ok and target.ok, "create_both"):
		_finish()
		return
	var a: OperationPrivateState = source.owner
	var b: OperationPrivateState = target.owner
	_check(_guard(a) and _guard(b), "canonical_original")
	var first_stop := _command("stop", -1)
	var first_move := _command("move", -1, Vector2(600, 500))
	_check(_exact(a.issue(first_stop), {"ok": true}), "issue_stop")
	_check(_exact(a.issue(first_move), {"ok": true}), "issue_move")
	var fleet := a._sim.st.fleets[0]
	_check(_exact([fleet.control, fleet.has_move, fleet.move_to, fleet.pos],
		["direct", true, Vector2(600, 500), Vector2(500, 500)]), "move_effect_before_pending")
	a._sim.debug_fire_missiles(1, 2)
	_check(_exact(a.queue(_command("stop", -1)), {"ok": true}), "queue_stop")
	var captured := a.capture_completed()
	if not _check(captured.ok, "capture_combined"):
		_finish()
		return
	var p: Dictionary = captured.packet
	var prefix: Array[Dictionary] = [_command("stop", 0), _command("move", 0, Vector2(600, 500))]
	var pending: Array[Dictionary] = [_command("stop", -1)]
	var events: Array[Dictionary] = [_event("spawn", 1, Vector2.ZERO, null), _event("spawn", 2, Vector2.ZERO, null),
		_event("say", 1, Vector2(500, 500), "stop"), _event("say", 1, Vector2(500, 500), "move"),
		{"tick": 0, "kind": "missile_launch", "sq": 1, "other": 2, "pos": Vector2(500, 500), "value": null}]
	_check(_exact([p.view.state.tick, p.view.state.clock_ms, p.view.sim.sub_ms, p.view.state.next_event_id],
		[0, 0, 0, 8]), "cut_time_and_id")
	_check(_exact(p.view.sim.command_log, prefix) and _exact(p.view.sim._queue, pending)
		and _exact(p.view.sim._events, events), "cut_log_pending_events")
	_check(p.view.fleets[0].has_move and _exact(p.view.fleets[0].move_to, Vector2(600, 500)), "pending_has_not_applied")
	_missiles(p.view, 0, "cut")
	_check(_missile_guard(a._sim), "cut_missile_script")
	names.append(NAMES[0])

	var old_sim := b._sim
	var old_state := old_sim.st
	var old_fleets := old_state.fleets.duplicate()
	_check(old_state.missiles.is_empty() and old_sim._queue.is_empty() and old_sim.command_log.is_empty(), "target_empty_before_restore")
	_check(_exact(b.restore_completed(p), {"ok": true}), "public_restore")
	_check(not is_same(b._sim, old_sim) and not is_same(b._sim.st, old_state), "fresh_target_sim_and_state")
	for i in 2:
		_check(not is_same(b._sim.st.fleets[i], old_fleets[i])
			and not is_same(b._sim.st.fleets[i], a._sim.st.fleets[i])
			and is_same(b._sim.st.by_id(i + 1), b._sim.st.fleets[i]), "fresh_target_fleet_" + str(i))
	for i in 6:
		var missile := b._sim.st.missiles[i]
		_check(not is_same(missile, a._sim.st.missiles[i])
			and is_same(b._sim.st.by_id(missile.src_id), b._sim.st.fleets[0])
			and is_same(b._sim.st.by_id(missile.target_id), b._sim.st.fleets[1]), "missile_rebind_" + str(i))
	_check(_guard(b) and _missile_guard(b._sim), "restored_canonical")
	_check(_exact(b.capture_completed(), captured) and _exact(a.capture_completed(), captured), "both_cuts_exact")
	names.append(NAMES[1])

	prefix.append(_command("stop", 0))
	events.append(_event("say", 1, Vector2(500, 500), "stop"))
	var after: Array[Dictionary] = []
	for owner in [a, b]:
		var label := str(after.size())
		_check(_exact(owner.advance(), {"ok": true}), "advance_once_" + label)
		var next: Dictionary = owner.capture_completed()
		if not _check(next.ok, "capture_after_" + label):
			_finish()
			return
		var view: Dictionary = next.packet.view
		_check(_exact([view.state.tick, view.state.clock_ms, view.sim.sub_ms, view.state.next_event_id],
			[1, 100, 50, 9]), "next_time_and_id_" + label)
		_check(_exact(view.sim.command_log, prefix) and view.sim._queue.is_empty()
			and _exact(view.sim._events, events), "exact_once_log_and_events_" + label)
		_check(_exact([view.fleets[0].pos, view.fleets[0].has_move], [Vector2(500, 500), false]), "pending_stop_effect_" + label)
		_missiles(view, 100, "next_" + label)
		for i in 6:
			_check(_exact(view.missiles[i].v, (p.view.missiles[i].v + 6.0) + 6.0)
				and view.missiles[i].pos != p.view.missiles[i].pos, "next_velocity_position_" + label + "_" + str(i))
		after.append(next)
	_check(_exact(after[0], after[1]), "full_post_advance_exact")
	names.append(NAMES[2])
	a.close()
	b.close()
	_finish()

