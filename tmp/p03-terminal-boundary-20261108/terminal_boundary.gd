extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const StateScript := preload("res://core/battle/battle_state.gd")
const FleetScript := preload("res://core/battle/fleet_state.gd")
const CONTROLS := ["direct", "direct"]
const NAMES := ["terminal_01_pre_boundary_actual", "terminal_02_natural_core_partial_end",
 "terminal_03_restore_pre_and_repeat", "terminal_04_restore_terminal_and_drain"]
var checks := 0
var failed := false
var completed: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_TERMINAL_FAIL " + label)
	return condition

func _exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if not _exact(_dict_type(a), _dict_type(b)) or not _exact(a.keys(), b.keys()): return false
		for key in a:
			if not _exact(a[key], b[key]): return false
		return true
	if a is Array:
		if a.get_typed_builtin() != b.get_typed_builtin() or a.get_typed_class_name() != b.get_typed_class_name(): return false
		if not is_same(a.get_typed_script(), b.get_typed_script()) or a.size() != b.size(): return false
		for i in a.size():
			if not _exact(a[i], b[i]): return false
		return true
	if a is Object: return is_same(a, b)
	return a == b

func _dict_type(value: Dictionary) -> Array:
	return [value.get_typed_key_builtin(), value.get_typed_key_class_name(), value.get_typed_key_script(),
		value.get_typed_value_builtin(), value.get_typed_value_class_name(), value.get_typed_value_script()]

func _properties(value: Object) -> Array:
	var fields: Array = []
	for property in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(property.name) not in ["_idx", "_idx_n"]:
			fields.append([property.name, _snapshot(value.get(property.name))])
	return [value.get_script(), fields]

func _snapshot(value: Variant) -> Variant:
	if value is Object: return _properties(value)
	if value is Dictionary:
		var entries: Array = []
		for key in value: entries.append([key, _snapshot(value[key])])
		return ["dictionary", _dict_type(value), entries]
	if value is Array:
		var entries: Array = []
		for item in value: entries.append(_snapshot(item))
		return ["array", value.get_typed_builtin(), value.get_typed_class_name(), value.get_typed_script(), entries]
	return value

func _profile() -> Dictionary:
	var rules: Dictionary = PocSetup.profile().rules
	rules.world_w = 3400
	rules.world_h = 2300
	var note_array: Array[int] = [7]
	return {"profile_id": "p03-terminal-boundary", "rules": rules,
		"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
		"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 2600, "y": 1500, "p": 0, "flag": true}],
		"reinf": [], "note": {"typed_probe": note_array, "key_probe": {7: "value"}, "order_probe": {"first": 1, "last": 2}}}

func _class_guard() -> bool:
	var classes := [Private, SimScript, StateScript, FleetScript]
	var names := ["operation_private_state", "battle_sim", "battle_state", "fleet_state"]
	for i in classes.size():
		var script: Script = classes[i]
		if not _check(script.resource_path == "res://core/battle/" + names[i] + ".gd", "canonical " + names[i]): return false
	return _check(Private._classes() == "", "canonical transitive class map")

func _binding(owner: OperationPrivateState) -> bool:
	var sim := owner._sim
	return _check(is_same(owner.get_script(), Private) and is_same(sim.get_script(), SimScript)
		and is_same(sim.st.get_script(), StateScript) and sim.st.fleets.size() == 2
		and is_same(sim.st.fleets[0].get_script(), FleetScript)
		and is_same(sim.st.fleets[1].get_script(), FleetScript)
		and is_same(sim.st.by_id(1), sim.st.fleets[0]) and is_same(sim.st.by_id(2), sim.st.fleets[1]),
		"runtime class identity and fleet bindings")

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	if not _check(result.ok, "capture: " + str(result.get("error", ""))): return {}
	return result.packet

func _clock(sim: BattleSim, tick: int, clock_ms: int, over: bool) -> bool:
	return _exact([sim.st.tick, sim.st.clock_ms, sim.st.over], [tick, clock_ms, over])

func _terminal(sim: BattleSim) -> bool:
	return _clock(sim, 2, 150, true) and _exact(
		[sim.st.end_tick, sim.st.end_ms, sim.sub_ms, sim.dt, sim.st.win, sim.st.end_reason],
		[2, 150, 50, 0.1, true, "annihilation"])

func _terminal_events(sim: BattleSim) -> bool:
	var expected: Array[Dictionary] = [{"tick": 2, "kind": "battle_end", "sq": -1, "other": -1,
		"pos": Vector2.ZERO, "value": "annihilation"}]
	return _exact(sim._events, expected)

func _restore(owner: OperationPrivateState, packet: Dictionary, state: Array, label: String) -> bool:
	var previous := owner._sim
	var handle := owner.get_instance_id()
	var result := owner.restore_completed(packet)
	if not _check(result.ok, label + ": " + str(result.get("error", ""))): return false
	_binding(owner)
	return _check(handle == owner.get_instance_id() and not is_same(previous, owner._sim)
		and owner._ready and not owner._busy and _exact(_properties(owner._sim), state),
		label + " exact fresh bindings on same handle")

func _case(owner: OperationPrivateState, raw: BattleSim) -> void:
	_binding(owner)
	_check(owner.advance().ok, "live prefix advance")
	raw.step()
	_check(_clock(owner._sim, 1, 100, false) and _exact(_properties(owner._sim), _properties(raw)), "literal prefix and raw")
	_check(_exact(owner.drain_events().events, raw.drain_events()), "pre-damage drain raw parity")

	var ships: int = owner._sim.st.by_id(2).ships
	if not _check(ships > 0 and raw.st.by_id(2).ships == ships
		and not owner._sim.st.by_id(2).defense and not raw.st.by_id(2).defense, "positive millicount and damage preconditions"):
		return
	var damage_milli := float(ships + 1000)
	owner._sim.debug_damage(1, 2, damage_milli)
	raw.debug_damage(1, 2, damage_milli)
	_check(_clock(owner._sim, 1, 100, false) and owner._sim.st.alive(1).is_empty()
		and owner._sim.st.flag(0) != null and owner._sim.st.by_id(2).dead
		and _exact(_properties(owner._sim), _properties(raw)), "last foe killed before core termination")
	var damaged := owner.drain_events()
	_check(damaged.ok and _exact(damaged.events, raw.drain_events())
		and damaged.events.any(func(event): return event.kind == "destroyed")
		and not damaged.events.any(func(event): return event.kind == "battle_end"), "damage events drained before cut")
	var pre := _capture(owner)
	if pre.is_empty(): return
	var pre_frozen := pre.duplicate(true)
	var pre_state := _properties(owner._sim)
	completed.append(NAMES[0])

	_check(owner.advance().ok, "first terminal advance")
	raw.step()
	_check(_terminal(owner._sim) and _terminal(raw) and _terminal_events(owner._sim)
		and _exact(_properties(owner._sim), _properties(raw)), "real core first substep end and ordered event")
	var terminal := _capture(owner)
	if terminal.is_empty(): return
	var terminal_frozen := terminal.duplicate(true)
	var terminal_state := _properties(owner._sim)
	var event_reference := raw.drain_events()
	_check(_exact(owner.drain_events().events, event_reference), "first live terminal drain")
	completed.append(NAMES[1])

	if not _restore(owner, pre, pre_state, "pre-terminal restore"): return
	_check(_clock(owner._sim, 1, 100, false) and owner._sim.st.alive(1).is_empty()
		and _exact(pre, pre_frozen), "pre-terminal state and packet still exact")
	_check(owner.advance().ok and _terminal(owner._sim) and _terminal_events(owner._sim)
		and _exact(_properties(owner._sim), terminal_state), "same advance without repeating damage")
	_check(_exact(owner.drain_events().events, event_reference), "repeat terminal drain")
	completed.append(NAMES[2])

	if not _restore(owner, terminal, terminal_state, "terminal restore"): return
	_check(_terminal(owner._sim) and _terminal_events(owner._sim), "restored terminal literal clock and event")
	_check(_exact(owner.drain_events().events, event_reference), "terminal packet event once in this timeline")
	var again := owner.drain_events()
	_check(again.ok and again.events.is_empty() and _exact(pre, pre_frozen)
		and _exact(terminal, terminal_frozen), "terminal drain empty and both packets immutable")
	completed.append(NAMES[3])

func _run() -> void:
	if not _class_guard():
		quit(1)
		return
	if "--p03-timeout-probe" in OS.get_cmdline_user_args():
		print("P03_TIMEOUT_PROBE ", JSON.stringify({"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id()}))
		OS.delay_msec(15000)
		quit(3)
		return
	var created := Private.create(_profile(), 7, 10, CONTROLS)
	if not _check(created.ok, "fixture create: " + str(created.get("error", ""))):
		quit(1)
		return
	var owner: OperationPrivateState = created.owner
	var raw := BattleSim.new(7, 10, _profile())
	for fleet in raw.st.fleets: fleet.control = "direct"
	_case(owner, raw)
	owner.close()
	_check(completed == NAMES, "four named checks complete")
	print("P03_TERMINAL_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(), "ok": not failed}))
	quit(1 if failed else 0)

