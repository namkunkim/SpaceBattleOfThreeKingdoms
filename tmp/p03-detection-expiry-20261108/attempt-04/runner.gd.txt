extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const StateScript := preload("res://core/battle/battle_state.gd")
const FleetScript := preload("res://core/battle/fleet_state.gd")
const CONTROLS := ["direct", "direct"]
const NAMES := ["expiry_01_last_seen_distinct", "expiry_02_native_and_owner_expiry", "expiry_03_restore_before_and_repeat"]
const LAST := Vector2(625, 500)
const HIDDEN := Vector2(2800, 1800)
const PRE_EXPIRY := 2410
const EXPIRY := 2411
const SERVICE_FIXTURE := "res://tests/fixtures/p02/services.json"
var checks := 0
var failed := false
var completed: Array[String] = []
var observation := "UNRESOLVED"
var payload_details := {}

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_DETECTION_EXPIRY_FAIL " + label)
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
		"p": 0, "flag": true, "composition": [{"ship_type_id": "SHP-03", "count": 3}, {"ship_type_id": "SHP-06", "count": 1}],
		"formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	var foe := {"name": "B", "role": "B", "ships": 4, "lv": 1, "x": 625.0, "y": 500.0,
		"p": 0, "flag": true, "composition": [{"ship_type_id": "SHP-04", "count": 4}],
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

func _step(sim: BattleSim, owner: OperationPrivateState) -> bool:
	if owner != null: return owner.advance().ok
	sim.step()
	return true

func _events(sim: BattleSim, owner: OperationPrivateState, side: int) -> Array[Dictionary]:
	if owner == null:
		return sim.drain_events() if side == -1 else sim.drain_events_for(side)
	var result := owner.drain_events() if side == -1 else owner.drain_events_for(side)
	_check(result.ok, "owner drain side %d" % side)
	return result.events

func _contacts(events: Array[Dictionary]) -> Array[Dictionary]:
	return events.filter(func(event): return event.kind == "contact" and event.sq == 2)

func _reach_pre(sim: BattleSim, owner: OperationPrivateState, label: String) -> bool:
	for side in 2:
		if owner == null: sim.issue(_stop(side))
		elif not _check(owner.issue(_stop(side)).ok, label + " issue stop"): return false
	if not _check(sim.detect._period == 10 and BattleRules.ticks(sim.detect.D.memory_s, sim.st.hz) == 1800
		and BattleRules.ticks(sim.detect.D.lost_s, sim.st.hz) == 600, label + " trusted cadence"): return false
	if not _check(_step(sim, owner), label + " first advance"): return false
	var seen := sim.detect.rec(0, 2)
	var acquired := _contacts(_events(sim, owner, -1))
	if not _check(sim.st.tick == 1 and not sim.st.over and _exact(seen.seen, 1)
		and _exact(seen.pos, LAST) and seen.state == "confirmed"
		and acquired.size() == 1 and acquired[0].tick == 1 and acquired[0].value.state == "confirmed",
		label + " actual first contact"): return false
	# Test-only relocation and home control prevent AI from returning to the old spawn.
	sim.st.by_id(2).pos = HIDDEN
	sim.st.by_id(2).home = HIDDEN
	var states: Array[String] = []
	var ticks: Array[int] = []
	for i in PRE_EXPIRY - 1:
		if not _step(sim, owner): return _check(false, label + " advance to expiry")
		for event in _contacts(_events(sim, owner, -1)):
			states.append(event.value.state)
			ticks.append(event.tick)
	var record := sim.detect.rec(0, 2)
	var good: bool = (sim.st.tick == PRE_EXPIRY and sim.st.clock_ms == PRE_EXPIRY * 100 and not sim.st.over
		and not sim.st.by_id(2).dead and _exact(sim.st.by_id(2).pos, HIDDEN)
		and _exact(record.seen, 1) and _exact(record.pos, LAST) and record.state == "lost"
		and states == ["estimated", "lost"] and ticks == [11, 1811])
	if not good:
		print("P03_EXPIRY_PRECONDITION ", label, " ", {
			"tick": sim.st.tick, "clock_ms": sim.st.clock_ms, "over": sim.st.over, "foe_dead": sim.st.by_id(2).dead,
			"foe_pos": sim.st.by_id(2).pos, "record": record, "states": states, "ticks": ticks})
	return _check(good, label + " last seen and lost precondition")

func _projection_item(view: Dictionary) -> Dictionary:
	for item in view.squadrons:
		if item.id == 2: return item
	return {}

func _expiry_reached(sim: BattleSim, view: Dictionary) -> bool:
	return (sim.st.tick == EXPIRY and sim.st.clock_ms == EXPIRY * 100 and not sim.st.over
		and not sim.st.by_id(2).dead and _exact(sim.st.by_id(2).pos, HIDDEN)
		and sim.detect.rec(0, 2).is_empty() and _projection_item(view).is_empty())

func _native(side: int) -> Dictionary:
	var sim := BattleSim.new(0, 10, _profile())
	for fleet in sim.st.fleets: fleet.control = "direct"
	sim.projection(0)
	var result := {"instance_id": sim.get_instance_id()}
	if _reach_pre(sim, null, "native side %d" % side):
		result.pre = _properties(sim)
		sim.step()
		_check(_expiry_reached(sim, sim.projection(0)), "native expiry removes contact")
		result.terminal = _properties(sim)
		result.events = _events(sim, null, side)
	for module in [sim.salvo, sim.detect, sim.supply]:
		if module != null: module.sim = null
	return result

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	if not _check(result.ok, "capture: " + str(result.get("error", ""))): return {}
	return result.packet

func _replay(owner: OperationPrivateState, packet: Dictionary, before: Array, after: Array, side: int, expected: Array[Dictionary]) -> bool:
	var old := owner._sim
	var handle := owner.get_instance_id()
	var restored := owner.restore_completed(packet)
	if not _check(restored.ok, "restore: " + str(restored.get("error", ""))): return false
	_binding(owner)
	_module_bindings(owner._sim)
	if not _check(handle == owner.get_instance_id() and not is_same(old, owner._sim)
		and owner._ready and not owner._busy and _exact(before, _properties(owner._sim)), "fresh sim, same lost checkpoint"): return false
	return _check(owner.advance().ok and _expiry_reached(owner._sim, owner.read_projection(0).projection)
		and _exact(after, _properties(owner._sim)) and _exact(_events(owner._sim, owner, side), expected),
		"same expiry step and ordered events side %d" % side)

func _case(owner: OperationPrivateState) -> void:
	var raw := _native(-1)
	var side0 := _native(0)
	var side1 := _native(1)
	if not _check(raw.has("events") and side0.has("events") and side1.has("events")
		and raw.instance_id != side0.instance_id and raw.instance_id != side1.instance_id and side0.instance_id != side1.instance_id
		and _exact(raw.pre, side0.pre) and _exact(raw.pre, side1.pre)
		and _exact(raw.terminal, side0.terminal) and _exact(raw.terminal, side1.terminal),
		"separate native raw/side references"): return
	_binding(owner)
	_module_bindings(owner._sim)
	if not _reach_pre(owner._sim, owner, "owner"): return
	var contact := _projection_item(owner.read_projection(0).projection)
	var before := _properties(owner._sim)
	if not _check(_exact(raw.pre, before) and contact.get("contact") == "lost" and _exact(contact.get("pos"), LAST),
		"public pre-expiry projection has last known only"): return
	var packet := _capture(owner)
	if packet.is_empty(): return
	var frozen := packet.duplicate(true)
	completed.append(NAMES[0])
	if not _check(owner.advance().ok and _expiry_reached(owner._sim, owner.read_projection(0).projection)
		and _exact(raw.terminal, _properties(owner._sim)), "live actual expiry and native parity"): return
	var after := _properties(owner._sim)
	var actual := _events(owner._sim, owner, 0)
	var contact0 := _contacts(actual)
	var raw_contacts := _contacts(raw.events)
	var side1_contacts := _contacts(side1.events)
	if not _check(_exact(actual, side0.events) and contact0.size() == 1 and raw_contacts.size() == 1
		and side1_contacts.is_empty() and _exact(contact0, raw_contacts), "raw/side0 carry one equal payload, side1 absent"): return
	var pos: Vector2 = contact0[0].pos
	var expected: Array[Dictionary] = [{"tick": EXPIRY, "kind": "contact", "sq": 2, "other": -1,
		"pos": pos, "value": {"state": "none", "was": "lost"}}]
	if not _check(_exact(contact0, expected), "literal ordered none event payload"): return
	if _exact(pos, HIDDEN): observation = "CURRENT_POS_OBSERVED"
	elif _exact(pos, LAST): observation = "LAST_KNOWN_OBSERVED"
	if not _check(observation != "UNRESOLVED", "event position matches one specified alternative"): return
	payload_details = {"tick": EXPIRY, "last_known": [LAST.x, LAST.y], "hidden_actual": [HIDDEN.x, HIDDEN.y],
		"side0_event_pos": [pos.x, pos.y], "side1_contact_count": side1_contacts.size(), "raw_contact_count": raw_contacts.size()}
	completed.append(NAMES[1])
	if not _replay(owner, packet, before, after, -1, raw.events): return
	if not _replay(owner, packet, before, after, 0, side0.events): return
	_check(_exact(packet, frozen), "source packet stays immutable")
	completed.append(NAMES[2])

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
	_check(completed == NAMES, "three named checks complete")
	print("P03_DETECTION_EXPIRY_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(),
		"position_observation": observation, "payload": payload_details, "ok": not failed}))
	quit(1 if failed else 0)

