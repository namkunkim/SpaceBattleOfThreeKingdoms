extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const NAMES := ["launch_and_exact_candidate", "positive_rebind", "atomic_reject_and_advance"]
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
		print("P03_PROJECTILE_TARGET_PASS " + JSON.stringify(record))
		quit(0)
	else:
		print("P03_PROJECTILE_TARGET_FAIL " + JSON.stringify(record))
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

func _missile_guard(sim: BattleSim) -> bool:
	var prototype := BattleState.Missile.new()
	var expected: Script = prototype.get_script()
	var observed: Array[String] = []
	var enclosing: Script = sim.st.get_script()
	var canonical_member: Variant = enclosing.get_script_constant_map().get("Missile")
	var matches := enclosing.resource_path == "res://core/battle/battle_state.gd" and is_same(canonical_member, expected)
	for missile in sim.st.missiles:
		var actual: Script = missile.get_script()
		observed.append(actual.resource_path)
		matches = matches and is_same(actual, expected)
	print("P03_PROJECTILE_SCRIPT_PATH " + JSON.stringify({"enclosing": enclosing.resource_path, "prototype": expected.resource_path, "missiles": observed, "canonical_member_matches": matches}))
	return matches

func _projectiles(view: Dictionary, age: int, label: String) -> void:
	var missiles: Array = view.missiles
	_check(_exact(missiles.map(func(m): return m.id), [2, 3, 4, 5, 6, 7]), label + "_ids")
	_check(missiles.all(func(m): return _exact([m.src_id, m.target_id, m.side, m.age, m.dead],
		[1, 2, 0, age, false])), label + "_references")

func _run() -> void:
	if "--force-gate-failure" in OS.get_cmdline_user_args():
		_check(_exact(0, 0.0), "intentional_gate_failure")
		_finish()
		return
	var profile := {"profile_id": "p03-projectile-target", "rules": PocSetup.profile().rules.duplicate(true),
		"ally": [{"name": "A", "role": "line", "ships": 10, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true, "wait": 1000}],
		"foe": [{"name": "B", "role": "line", "ships": 10, "lv": 1, "x": 1500, "y": 1000, "p": 0, "flag": true, "wait": 1000}], "reinf": []}
	var events: Array[Dictionary] = [_event("spawn", 1, Vector2.ZERO, null), _event("spawn", 2, Vector2.ZERO, null),
		{"tick": 0, "kind": "missile_launch", "sq": 1, "other": 2, "pos": Vector2(500, 500), "value": null}]
	var owners: Array[OperationPrivateState] = []
	for label in ["A", "B", "C"]:
		var created := Private.create(profile, 41, 10, [])
		if not _check(created.ok, "create_" + label):
			_finish()
			return
		var owner: OperationPrivateState = created.owner
		owners.append(owner)
		_check(_guard(owner), "class_guard_" + label)
		_check(owner._sim.st.next_event_id == 1, "initial_next_event_" + label)
		owner._sim.debug_fire_missiles(1, 2)
	var a := owners[0]
	var b := owners[1]
	var p_result := b.capture_completed()
	if not _check(p_result.ok, "capture_p"):
		_finish()
		return
	var p: Dictionary = p_result.packet
	_check(_missile_guard(b._sim), "missile_source_script")
	_projectiles(p.view, 0, "launch")
	_check(_exact([p.view.state.tick, p.view.state.next_event_id], [0, 8]), "launch_time_id")
	_check(_exact(p.view.sim._events, events) and p.view.sim._queue.is_empty()
		and p.view.sim.command_log.is_empty(), "launch_events_pending_log")
	var m := p.duplicate(true)
	m.view.missiles[0].target_id = 999
	var changed: Array[String] = []
	_diff(p, m, "", changed)
	_check(changed == [".view.missiles.0.target_id"], "exact_single_path")
	_check(typeof(m.view.missiles[0].target_id) == TYPE_INT and p.view.missiles[0].target_id == 2
		and m.view.missiles[0].target_id == 999 and b._sim.st.by_id(999) == null, "exact_single_value")
	_check(Private._packet_error(m) == "", "structural_validation")
	names.append(NAMES[0])

	var b_sim := b._sim
	var b_state := b_sim.st
	var b_fleets := b_state.fleets.duplicate()
	var b_missiles := b_state.missiles.duplicate()
	_check(_exact(b.restore_completed(p), {"ok": true}), "positive_restore")
	_check(not is_same(b._sim, b_sim) and not is_same(b._sim.st, b_state), "positive_new_state")
	for i in 2:
		_check(not is_same(b._sim.st.fleets[i], b_fleets[i])
			and is_same(b._sim.st.by_id(i + 1), b._sim.st.fleets[i]), "positive_new_fleet_" + str(i))
	for i in 6:
		var missile := b._sim.st.missiles[i]
		_check(not is_same(missile, b_missiles[i])
			and is_same(b._sim.st.by_id(missile.src_id), b._sim.st.fleets[0])
			and is_same(b._sim.st.by_id(missile.target_id), b._sim.st.fleets[1]), "positive_rebind_" + str(i))
	_check(_guard(b) and _missile_guard(b._sim), "positive_script_guard")
	_check(_exact(b.capture_completed(), p_result), "positive_exact")
	names.append(NAMES[1])

	var a_sim := a._sim
	var st := a_sim.st
	var first := st.by_id(1)
	var second := st.by_id(2)
	var cache: Dictionary = st._idx
	var old_missiles := st.missiles.duplicate()
	var before := a.capture_completed()
	var input_copy := m.duplicate(true)
	_check(_exact(before, p_result) and a._ready and not a._busy, "active_setup")
	_check(_exact(cache.keys(), [1, 2]) and st._idx_n == 2
		and is_same(cache[1], first) and is_same(cache[2], second), "active_warm_cache")
	_check(a_sim.salvo == null and a_sim.detect == null and a_sim.supply == null, "no_active_service")
	_check(_exact(a.restore_completed(m), {"ok": false, "error": "projectile_reference"}), "exact_rejection")
	_check(is_same(a._sim, a_sim) and is_same(a._sim.st, st) and is_same(st.fleets[0], first)
		and is_same(st.fleets[1], second), "active_identity")
	_check(_exact(st.missiles, old_missiles), "active_projectile_identity")
	_check(is_same(st._idx, cache) and _exact(cache.keys(), [1, 2]) and st._idx_n == 2
		and is_same(cache[1], first) and is_same(cache[2], second), "active_cache_preserved")
	_check(a._ready and not a._busy and _exact(a.capture_completed(), before), "active_exact")
	_check(_exact(m, input_copy) and _exact(a_sim._events, events)
		and a_sim._queue.is_empty() and a_sim.command_log.is_empty(), "input_pending_events")

	var after: Array[Dictionary] = []
	for owner in owners:
		var label := str(after.size())
		_check(_exact(owner.advance(), {"ok": true}), "advance_" + label)
		var next := owner.capture_completed()
		if not _check(next.ok, "capture_after_" + label):
			_finish()
			return
		var view: Dictionary = next.packet.view
		_check(_exact([view.state.tick, view.state.clock_ms, view.sim.sub_ms, view.state.next_event_id],
			[1, 100, 50, 9]), "time_oracle_" + label)
		_projectiles(view, 100, "next_" + label)
		_check(_exact(view.sim._events, events) and view.sim._queue.is_empty()
			and view.sim.command_log.is_empty(), "suffix_events_" + label)
		for i in 6:
			_check(_exact(view.missiles[i].v, (p.view.missiles[i].v + 6.0) + 6.0)
				and view.missiles[i].pos != p.view.missiles[i].pos, "velocity_position_" + label + "_" + str(i))
		after.append(next)
	_check(_exact(after[0], after[2]) and _exact(after[1], after[2]), "full_post_advance_exact")
	names.append(NAMES[2])
	for owner in owners:
		owner.close()
	_finish()

