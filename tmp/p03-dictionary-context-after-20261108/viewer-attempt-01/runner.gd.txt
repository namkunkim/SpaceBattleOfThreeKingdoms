extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const StateScript := preload("res://core/battle/battle_state.gd")
const FleetScript := preload("res://core/battle/fleet_state.gd")
const CONTROLS := ["direct", "direct"]
const NAMES := ["viewer_cut_01_capture_nonempty_and_filter", "viewer_cut_02_restore_preconsume_raw",
 "viewer_cut_03_restore_preconsume_other_side", "viewer_cut_04_restore_postconsume_empty"]
const SERVICE_FIXTURE := "res://tests/fixtures/p02/services.json"
var checks := 0
var failed := false
var completed: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_VIEWER_CUT_FAIL " + label)
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
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(property.name) not in ["_idx", "_idx_n", "sim"]:
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
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERVICE_FIXTURE))
	var ally := {"name": "A", "role": "A", "ships": 4, "lv": 1, "x": 400.0, "y": 500.0,
		"p": 0, "flag": true, "composition": [{"ship_type_id": "SHP-01", "count": 1},
		{"ship_type_id": "SHP-03", "count": 1}, {"ship_type_id": "SHP-04", "count": 2}],
		"formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	var foe := {"name": "B", "role": "B", "ships": 40, "lv": 1, "x": 1550.0, "y": 500.0,
		"p": 0, "flag": true, "composition": [{"ship_type_id": "SHP-02", "count": 40}],
		"formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	return {"profile_id": "p02-explicit-services", "rules": data.profile.rules,
		"ally": [ally], "foe": [foe], "reinf": [], "combat": data.profile.combat}

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

func _module_bindings(sim: BattleSim) -> bool:
	return _check(sim.salvo != null and sim.detect != null and sim.supply != null
		and is_same(sim.salvo.sim, sim) and is_same(sim.detect.sim, sim) and is_same(sim.supply.sim, sim),
		"active services bindings")

func _stop(side: int) -> Dictionary:
	return BattleSim.command(side, [side + 1], "stop")

func _literal_events() -> Array[Dictionary]:
	return [{"tick": 0, "kind": "spawn", "sq": 1, "other": -1, "pos": Vector2.ZERO, "value": null},
		{"tick": 0, "kind": "spawn", "sq": 2, "other": -1, "pos": Vector2.ZERO, "value": null},
		{"tick": 0, "kind": "say", "sq": 1, "other": -1, "pos": Vector2(400, 500), "value": "stop"},
		{"tick": 0, "kind": "say", "sq": 2, "other": -1, "pos": Vector2(1550, 500), "value": "stop"}]

func _raw_reference(side: int) -> Dictionary:
	var sim := BattleSim.new(0, 10, _profile())
	for fleet in sim.st.fleets: fleet.control = "direct"
	sim.projection(0)
	sim.issue(_stop(0))
	sim.issue(_stop(1))
	sim.step()
	var snapshot := _properties(sim)
	var events: Array[Dictionary] = sim.drain_events() if side == -1 else sim.drain_events_for(side)
	var out := {"instance_id": sim.get_instance_id(), "state": snapshot, "events": events.duplicate(true)}
	for module in [sim.salvo, sim.detect, sim.supply]:
		if module != null: module.sim = null
	return out

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	if not _check(result.ok, "capture: " + str(result.get("error", ""))): return {}
	return result.packet

func _restore(owner: OperationPrivateState, packet: Dictionary, state: Array, label: String) -> bool:
	var previous := owner._sim
	var handle := owner.get_instance_id()
	var result := owner.restore_completed(packet)
	if not _check(result.ok, label + ": " + str(result.get("error", ""))): return false
	_binding(owner)
	_module_bindings(owner._sim)
	return _check(handle == owner.get_instance_id() and not is_same(previous, owner._sim)
		and owner._ready and not owner._busy and _exact(_properties(owner._sim), state),
		label + " exact fresh runtime")

func _drain(owner: OperationPrivateState, side: int, expected: Array, label: String) -> bool:
	var result := owner.drain_events() if side == -1 else owner.drain_events_for(side)
	return _check(_exact(result, {"ok": true, "events": expected}), label)

func _case(owner: OperationPrivateState) -> void:
	var native := _raw_reference(-1)
	var side0 := _raw_reference(0)
	var side1 := _raw_reference(1)
	_check(native.instance_id != side0.instance_id and native.instance_id != side1.instance_id
		and side0.instance_id != side1.instance_id and _exact(native.state, side0.state)
		and _exact(native.state, side1.state), "three independent destructive native references")
	var literal := _literal_events()
	var literal0: Array[Dictionary] = [literal[0], literal[2]]
	var literal1: Array[Dictionary] = [literal[1], literal[3]]
	var empty: Array[Dictionary] = []
	if not _check(_exact(native.events, literal) and _exact(side0.events, literal0)
		and _exact(side1.events, literal1), "native raw and two side literal payloads"): return

	_binding(owner)
	_module_bindings(owner._sim)
	_check(owner.issue(_stop(0)).ok and owner.issue(_stop(1)).ok, "two immediate stops")
	_check(owner.advance().ok and owner._sim.st.tick == 1, "actual advance before cut")
	_check(_exact(native.state, _properties(owner._sim))
		and _exact(owner._sim._events, literal), "live raw state/contacts and queue exact")
	var contacts := owner._sim.detect.contacts.duplicate(true)
	var clock := owner._sim.st.clock_ms
	var a_state := _properties(owner._sim)
	var a := _capture(owner)
	if a.is_empty(): return
	var a_frozen := a.duplicate(true)
	_drain(owner, 0, side0.events, "live side0 expected display")
	var b_state := _properties(owner._sim)
	var b := _capture(owner)
	if b.is_empty(): return
	var b_frozen := b.duplicate(true)
	_check(owner._sim.st.tick == 1 and owner._sim.st.clock_ms == clock
		and _exact(owner._sim.detect.contacts, contacts) and _exact(b.view.sim._events, empty)
		and _exact(a.view.sim._events, literal), "B captured after filter before any new tick")
	_drain(owner, -1, empty, "raw empty after live filtered consumption")
	_drain(owner, 1, empty, "other side empty after live filtered consumption")
	completed.append(NAMES[0])

	_check(owner.advance().ok and owner._sim.st.tick == 2, "real additional advance before A replacement")
	if not _restore(owner, a, a_state, "pre-consume A raw"): return
	_drain(owner, -1, native.events, "restored raw includes hidden opposing events")
	_drain(owner, -1, empty, "restored raw consumed exactly once in this timeline")
	completed.append(NAMES[1])

	if not _restore(owner, a, a_state, "pre-consume A side1"): return
	_drain(owner, 1, side1.events, "restored side1 exact and distinct from side0")
	_drain(owner, 0, empty, "side0 empty after side1 filtered consumption")
	_check(_exact(a, a_frozen), "same A unchanged after all branches")
	completed.append(NAMES[2])

	if not _restore(owner, a, a_state, "pre-consume A for B comparison"): return
	_check(_exact(owner._sim._events, literal), "A truly nonempty immediately before B")
	if not _restore(owner, b, b_state, "post-consume B"): return
	_drain(owner, -1, empty, "B raw empty")
	_drain(owner, 0, empty, "B side0 empty")
	_drain(owner, 1, empty, "B side1 empty")
	_check(owner._sim.st.tick == 1 and owner._sim.st.clock_ms == clock
		and _exact(owner._sim.detect.contacts, contacts)
		and _exact(a, a_frozen) and _exact(b, b_frozen), "same contacts/time and immutable A/B")
	completed.append(NAMES[3])

func _run() -> void:
	if not _class_guard():
		quit(1)
		return
	var created := Private.create(_profile(), 0, 10, CONTROLS)
	if not _check(created.ok, "fixture create: " + str(created.get("error", ""))):
		quit(1)
		return
	var owner: OperationPrivateState = created.owner
	_case(owner)
	owner.close()
	_check(completed == NAMES, "four named checks complete")
	print("P03_VIEWER_CUT_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(), "ok": not failed}))
	quit(1 if failed else 0)

