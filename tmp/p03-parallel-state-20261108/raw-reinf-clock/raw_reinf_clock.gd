extends SceneTree

const NAMES := ["threshold_is_strict", "timed_spawn_at_150ms", "no_second_spawn"]
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
		print("P03_RAW_REINF_CLOCK_PASS " + JSON.stringify(record))
		quit(0)
	else:
		print("P03_RAW_REINF_CLOCK_FAIL " + JSON.stringify(record))
		quit(1)

func _event(kind: String, id: int, pos: Vector2, value: Variant) -> Dictionary:
	return {"tick": 0, "kind": kind, "sq": id, "other": -1, "pos": pos, "value": value}

func _canonical(sim: BattleSim) -> bool:
	var objects: Array[Object] = [sim, sim.st, sim.st.fleets[0]]
	var files := ["battle_sim", "battle_state", "fleet_state"]
	for i in objects.size():
		if objects[i].get_script().resource_path != "res://core/battle/" + files[i] + ".gd":
			return false
	return true

func _expect_boundary(sim: BattleSim, expected: Array, ids: Array, events: Array[Dictionary], label: String) -> void:
	var st := sim.st
	_check(_exact([st.tick, st.clock_ms, sim.sub_ms, st.reinf, st.reinf_ms, st.next_id, st.form_counter],
		expected), label + "_time_and_counters")
	_check(_exact(st.fleets.map(func(f): return f.id), ids), label + "_roster_ids")
	_check(_exact(sim._events, events), label + "_event_order")
	_check(not st.over and st.flag(0) != null and st.flag(1) != null
		and not st.flag(0).dead and not st.flag(1).dead, label + "_both_flags_alive")
	_check(sim._queue.is_empty() and sim.command_log.is_empty() and st.missiles.is_empty() and st.swarms.is_empty(),
		label + "_empty_auxiliary")

func _expect_reinf(fleet: FleetState, label: String) -> void:
	_check(_exact([fleet.id, fleet.side, fleet.name, fleet.role, fleet.ships, fleet.max_ships, fleet.shown,
		fleet.lv, fleet.form_id, fleet.is_flag, fleet.pos, fleet.home, fleet.spawn, fleet.wait, fleet.dead],
		[3, 1, "R", "line", 7000, 7000, 7000, 1, 2, false, Vector2(2100, 1400), Vector2(2100, 1400),
		Vector2(2100, 1400), 10000, false]), label + "_reinforcement_state")
	_check(fleet.get_script().resource_path == "res://core/battle/fleet_state.gd", label + "_reinforcement_script")

func _run() -> void:
	if "--force-gate-failure" in OS.get_cmdline_user_args():
		_check(_exact(0, 0.0), "intentional_gate_failure")
		_finish()
		return
	var rules: Dictionary = PocSetup.profile().rules.duplicate(true)
	rules.reinf_ms = 100
	var profile := {"profile_id": "p03-raw-reinf-clock", "rules": rules,
		"ally": [{"name": "A", "role": "line", "ships": 10, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true, "wait": 1000}],
		"foe": [{"name": "B", "role": "line", "ships": 10, "lv": 1, "x": 1500, "y": 1000, "p": 0, "flag": true, "wait": 1000}],
		"reinf": [{"name": "R", "role": "line", "ships": 7, "lv": 1, "x": 2100, "y": 1400, "p": 0, "flag": false, "wait": 1000}]}
	var sim := BattleSim.new(41, 10, profile)
	var st := sim.st
	_check(_canonical(sim), "canonical_raw_script_paths")
	_check(_exact(sim.R.reinf_ms, 100) and sim._reinf_def.size() == 1, "timed_fixture_rules")
	var first := st.by_id(1)
	var second := st.by_id(2)
	_check(is_same(first, st.fleets[0]) and is_same(second, st.fleets[1])
		and st._idx_n == 2 and _exact(st._idx.keys(), [1, 2]), "warm_lookup")
	var events: Array[Dictionary] = [_event("spawn", 1, Vector2.ZERO, null), _event("spawn", 2, Vector2.ZERO, null)]
	_expect_boundary(sim, [0, 0, 0, false, -1, 3, 2], [1, 2], events, "created")
	sim.step()
	_expect_boundary(sim, [1, 100, 50, false, -1, 3, 2], [1, 2], events, "threshold")
	_check(st.by_id(3) == null and st._idx_n == 2, "threshold_no_new_id")
	names.append(NAMES[0])

	for kind in ["spawn", "reinforcements"]:
		var event := _event(kind, 3 if kind == "spawn" else -1, Vector2.ZERO, null)
		event.tick = 2
		events.append(event)
	sim.step()
	_expect_boundary(sim, [2, 200, 50, true, 150, 4, 3], [1, 2, 3], events, "crossed")
	var reinforcement := st.by_id(3)
	if not _check(reinforcement != null, "reinforcement_found"):
		_finish()
		return
	_check(is_same(reinforcement, st.fleets[2]) and is_same(st.by_id(1), first) and is_same(st.by_id(2), second)
		and st._idx_n == 3 and _exact(st._idx.keys(), [1, 2, 3]), "new_lookup_preserves_old_ids")
	_expect_reinf(reinforcement, "crossed")
	names.append(NAMES[1])

	sim.step()
	_expect_boundary(sim, [3, 300, 50, true, 150, 4, 3], [1, 2, 3], events, "later")
	_check(is_same(st.by_id(1), first) and is_same(st.by_id(2), second)
		and is_same(st.by_id(3), reinforcement) and is_same(st.fleets[2], reinforcement), "later_objects_preserved")
	_expect_reinf(reinforcement, "later")
	names.append(NAMES[2])
	_finish()

