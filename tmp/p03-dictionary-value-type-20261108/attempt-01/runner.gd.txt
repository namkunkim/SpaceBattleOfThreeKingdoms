extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const StateScript := preload("res://core/battle/battle_state.gd")
const FleetScript := preload("res://core/battle/fleet_state.gd")
const CONTROLS := ["direct", "direct"]
const NAMES := ["value_type_01_same_context_control", "value_type_02_key_derived_control", "value_type_03_only_value_metadata"]
var checks := 0
var failed := false
var completed: Array[String] = []
var observations: Array[Dictionary] = []
var value_metadata_contract := "UNRESOLVED"

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_VALUE_TYPE_FAIL " + label)
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
	return {"profile_id": "p03-dictionary-value-type", "rules": rules,
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

func _probe(index: int, target: bool) -> Dictionary:
	if target and index == 1: return {"k": 7}
	if target and index == 2:
		var generic: Dictionary[String, Variant] = {"k": 7}
		return generic
	var precise: Dictionary[String, int] = {"k": 7}
	return precise

func _array_type(value: Array) -> Array:
	return [value.get_typed_builtin(), value.get_typed_class_name(), value.get_typed_script()]

func _describe(value: Variant) -> Array:
	var fields := _dict_type(value) if value is Dictionary else _array_type(value)
	for i in fields.size():
		if fields[i] is Script: fields[i] = fields[i].resource_path
		if fields[i] is StringName: fields[i] = str(fields[i])
		if fields[i] == null: fields[i] = null
	return fields

func _check_probe(index: int, left: Dictionary, right: Dictionary) -> bool:
	if not (left.size() == 1 and right.size() == 1 and _exact(left.keys()[0], right.keys()[0])
		and _exact(left.keys()[0], "k") and _exact(left["k"], 7) and _exact(right["k"], 7)
		and left.get_typed_key_builtin() == TYPE_STRING and left.get_typed_value_builtin() == TYPE_INT
		and left.get_typed_key_class_name() == right.get_typed_key_class_name()
		and left.get_typed_value_class_name() == right.get_typed_value_class_name()
		and is_same(left.get_typed_key_script(), right.get_typed_key_script())
		and is_same(left.get_typed_value_script(), right.get_typed_value_script())):
		return false
	match index:
		0:
			return _exact(left, right) and _exact(left.keys(), right.keys())
		1:
			return (right.get_typed_key_builtin() == TYPE_NIL and right.get_typed_value_builtin() == TYPE_NIL
				and not _exact(left.keys(), right.keys()) and not _exact(left, right))
		2:
			return (right.get_typed_key_builtin() == TYPE_STRING and right.get_typed_value_builtin() == TYPE_NIL
				and _exact(left.keys(), right.keys()) and not _exact(left, right))
	return false

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	if not _check(result.ok, "capture: " + str(result.get("error", ""))): return {}
	return result.packet

func _make_profile(value: Variant) -> Dictionary:
	var result := _profile()
	result.note.probe = value
	return result

func _compatible_other_profile(left: Dictionary, right: Dictionary) -> bool:
	var a := left.duplicate(true)
	var b := right.duplicate(true)
	a.note.erase("probe")
	b.note.erase("probe")
	return _exact(a, b)

func _case(index: int) -> void:
	var left: Variant = _probe(index, false)
	var right: Variant = _probe(index, true)
	var left_desc := _describe(left)
	var right_desc := _describe(right)
	if not _check(_check_probe(index, left, right), "isolated probe input " + str(index)): return
	var start := Private.create(_make_profile(left), 7, 10, CONTROLS)
	if not _check(start.ok, "active create " + str(start.get("error", ""))): return
	var owner: OperationPrivateState = start.owner
	_observe_case(index, owner, left, right, left_desc, right_desc)
	owner.close()

func _observe_case(index: int, owner: OperationPrivateState, left: Variant, right: Variant, left_desc: Array, right_desc: Array) -> void:
	_binding(owner)
	_check(owner.advance().ok, "active real advance")
	_check(owner.issue(BattleSim.command(0, [1], "stop")).ok, "active issue")
	_check(owner.queue(BattleSim.command(0, [1], "stop")).ok, "active pending")
	var sim := owner._sim
	_check(sim.st.tick == 1 and sim.command_log.size() == 1 and sim._queue.size() == 1
		and not sim._events.is_empty(), "nonempty active log queue events")
	var active_packet := _capture(owner)
	if active_packet.is_empty(): return
	var old_state := _properties(sim)
	var owner_id := owner.get_instance_id()
	var made := Private.create(_make_profile(right), 7, 10, CONTROLS)
	if not _check(made.ok, "candidate create " + str(made.get("error", ""))): return
	var candidate: OperationPrivateState = made.owner
	var candidate_profile := candidate._profile.duplicate(true)
	var packet := _capture(candidate)
	candidate.close()
	if packet.is_empty(): return
	var frozen := packet.duplicate(true)
	var prepared := Private.prepare(packet)
	if not _check(prepared.ok, "candidate prepare " + str(prepared.get("error", ""))): return
	var ready: OperationPrivateState = prepared.owner
	var ready_state := _properties(ready._sim)
	var ready_profile := ready._profile.duplicate(true)
	ready.close()
	var pass_inputs := (_exact(left, owner._profile.note.probe) and _exact(left, active_packet.profile.note.probe)
		and _exact(right, candidate_profile.note.probe) and _exact(right, packet.profile.note.probe)
		and _exact(right, ready_profile.note.probe) and _check_probe(index, active_packet.profile.note.probe, ready_profile.note.probe)
		and _compatible_other_profile(active_packet.profile, ready_profile) and _exact(active_packet.controls, packet.controls)
		and _exact([active_packet.seed, active_packet.hz], [packet.seed, packet.hz]) and _exact(frozen, packet))
	if not _check(pass_inputs, "probe survived all packet stages " + str(index)): return
	var result := owner.restore_completed(packet)
	var preserved := (owner.get_instance_id() == owner_id and owner._ready and not owner._busy
		and _exact(frozen, packet) and _exact(left, owner._profile.note.probe))
	var row := {"name": NAMES[index], "active_input_meta": left_desc, "candidate_input_meta": right_desc,
		"active_packet_meta": _describe(active_packet.profile.note.probe), "candidate_packet_meta": _describe(packet.profile.note.probe),
		"candidate_prepared_meta": _describe(ready_profile.note.probe), "active_post_meta": _describe(owner._profile.note.probe),
		"result": result, "same_active_sim": is_same(owner._sim, sim)}
	if left is Dictionary and right is Dictionary:
		row.active_key_list_meta = _describe(left.keys())
		row.candidate_key_list_meta = _describe(right.keys())
	if result.ok:
		if not _check(index in [0, 2] and preserved and not is_same(owner._sim, sim)
			and _exact(_properties(owner._sim), ready_state), "replacement success and exact prepared runtime"): return
		_binding(owner)
		if index == 2: value_metadata_contract = "MISMATCH"
	else:
		if not _check(index != 0 and _exact(result, {"ok": false, "error": "replacement_context_mismatch"})
			and preserved and is_same(owner._sim, sim) and _exact(old_state, _properties(sim)), "exact refusal and atomic preservation"): return
		if not _check(owner.advance().ok and sim.st.tick == 2 and sim._queue.is_empty()
			and sim.command_log.size() == 2, "advance after refusal consumes pending once"): return
		if index == 2: value_metadata_contract = "MATCH"
	observations.append(row)
	completed.append(NAMES[index])

func _run() -> void:
	if not _class_guard():
		quit(1)
		return
	for index in NAMES.size():
		_case(index)
	_check(completed == NAMES and value_metadata_contract in ["MATCH", "MISMATCH"], "all three observations classified")
	print("P03_VALUE_TYPE_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(),
		"value_metadata_contract": value_metadata_contract, "observations": observations, "ok": not failed}))
	quit(1 if failed else 0)

