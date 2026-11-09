extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const StateScript := preload("res://core/battle/battle_state.gd")
const FleetScript := preload("res://core/battle/fleet_state.gd")
const CONTROLS := ["direct", "direct", "direct"]
const NAMES := ["supply_mix_01_actual_completion", "supply_mix_02_consistent_post_control",
 "supply_mix_03_mixed_acceptance", "supply_mix_04_mixed_next_step"]
const Fixture := preload("res://tests/lib/salvo_fixture.gd")
var checks := 0
var failed := false
var completed: Array[String] = []
var observation := "UNRESOLVED"
var details := {}

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_SUPPLY_MIX_FAIL " + label)
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
	var rules: Dictionary = PocSetup.profile().rules
	rules.world_w = 3400
	rules.world_h = 2300
	var combat := Fixture.combat()
	for key in ["morale", "victory", "command", "stratagem", "assault", "terrain"]:
		combat.erase(key)
	var ally := [Fixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], true),
		Fixture.def("C", 925, 450, [["SHP-04", 4]])]
	var foe := [Fixture.def("F", 1000, 450, [["SHP-02", 4]], true)]
	for fleet in ally: fleet.faction_id = "liu_bei"
	foe[0].faction_id = "cao_cao"
	return {"profile_id": "p03-supply-mixed", "rules": rules,
		"ally": ally, "foe": foe, "reinf": [], "combat": combat}

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
		and is_same(sim.st.get_script(), StateScript) and sim.st.fleets.size() == 3
		and is_same(sim.st.fleets[0].get_script(), FleetScript)
		and is_same(sim.st.fleets[1].get_script(), FleetScript)
		and is_same(sim.st.by_id(1), sim.st.fleets[0]) and is_same(sim.st.by_id(2), sim.st.fleets[1]),
		"runtime class identity and fleet bindings")

func _module_bindings(sim: BattleSim) -> bool:
	return _check(sim.salvo != null and sim.detect != null and sim.supply != null
		and is_same(sim.salvo.sim, sim) and is_same(sim.detect.sim, sim) and is_same(sim.supply.sim, sim),
		"active services bindings")

func _setup(sim: BattleSim) -> bool:
	sim.st.ai_timer = 1 << 40
	for fleet in sim.st.fleets:
		for category in fleet.next_fire: fleet.next_fire[category] = 1 << 40
	var client := sim.st.by_id(2)
	if not _check(client.stages["SHP-04"] == [4, 0, 0, 0, 0] and client.hit_tick == -1
		and sim.supply.deficit(client) == 0 and sim.supply.charge_deficit(client) == 0,
		"untouched starting ammo/charges and four original ships"):
		print("P03_SUPPLY_SETUP ", {"stages": client.stages, "hit_tick": client.hit_tick,
			"ammo_deficit": sim.supply.deficit(client), "charge_deficit": sim.supply.charge_deficit(client),
			"ammo": client.ammo, "charge": client.wch})
		return false
	client.stages["SHP-04"] = [2, 0, 2, 0, 0]
	return _check(sim.supply.moderate_of(client) == 2, "controlled two moderate damaged ships")

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	if not _check(result.ok, "capture: " + str(result.get("error", ""))): return {}
	return result.packet

func _service_events(events: Array[Dictionary]) -> Array[Dictionary]:
	return events.filter(func(event): return event.kind == "supply" and event.sq == 2)

func _literal_repair(tick: int, pos: Vector2) -> Array[Dictionary]:
	return [{"tick": tick, "kind": "supply", "sq": 2, "other": 1, "pos": pos,
		"value": {"src": "f1", "ammo": 0, "charges": 0, "repair": 1, "reload": false}}]

func _advance(owner: OperationPrivateState, raw: BattleSim) -> bool:
	if raw != null: raw.step()
	return _check(owner.advance().ok, "public advance")

func _restore(owner: OperationPrivateState, packet: Dictionary, state: Array) -> bool:
	var old := owner._sim
	var handle := owner.get_instance_id()
	var result := owner.restore_completed(packet)
	if not _check(result.ok, "consistent restore: " + str(result.get("error", ""))): return false
	_binding(owner)
	_module_bindings(owner._sim)
	return _check(owner.get_instance_id() == handle and not is_same(owner._sim, old)
		and owner._ready and not owner._busy and _exact(_properties(owner._sim), state), "consistent packet restores exact state")

func _case(owner: OperationPrivateState, raw: BattleSim) -> void:
	if not (_setup(owner._sim) and _setup(raw)): return
	_binding(owner)
	_module_bindings(owner._sim)
	var sim := owner._sim
	var supplier := sim.st.by_id(1)
	var client := sim.st.by_id(2)
	var need := sim.supply.need
	var rate := sim.supply.rate_of(supplier)
	var cost := int(sim.supply.S.repair.materials)
	var before_stock := supplier.sup_mat
	var ammo := supplier.sup_ammo
	if not _check(need > rate and rate > 0 and cost > 0 and before_stock >= 2 * cost, "two repair cycles affordable"): return
	while client.sup_prog != need - rate and sim.st.tick < 1000:
		if not _advance(owner, raw): return
		var drained := owner.drain_events()
		if not _check(drained.ok and _exact(drained.events, raw.drain_events()) and _service_events(drained.events).is_empty(),
			"no repair before the literal completion step"): return
	if not _check(client.sup_prog == need - rate and client.sup_src == "f1" and client.supplied == 0
		and supplier.sup_mat == before_stock and _exact(client.stages["SHP-04"], [2, 0, 2, 0, 0])
		and _exact(_properties(sim), _properties(raw)), "real completion pending A"): return
	var a := _capture(owner)
	if a.is_empty(): return
	var a_frozen := a.duplicate(true)
	if not _advance(owner, raw): return
	var first_tick := sim.st.tick
	var first := owner.drain_events()
	if not _check(first.ok and _exact(first.events, raw.drain_events())
		and _exact(_service_events(first.events), _literal_repair(first_tick, client.pos))
		and _exact(client.stages["SHP-04"], [2, 1, 1, 0, 0]) and client.supplied == 1
		and client.sup_prog == 0 and client.healed_mod == 1 and supplier.sup_mat == before_stock - cost
		and supplier.sup_ammo == ammo and _exact(_properties(sim), _properties(raw)), "actual first repair before B"): return
	var b := _capture(owner)
	if b.is_empty(): return
	var b_frozen := b.duplicate(true)
	var b_state := _properties(sim)
	completed.append(NAMES[0])

	if not _restore(owner, b, b_state): return
	if not _advance(owner, raw): return
	var control := owner._sim
	var b_step_events := owner.drain_events()
	var b_step := _properties(control)
	if not _check(b_step_events.ok and _exact(b_step_events.events, raw.drain_events())
		and _service_events(b_step_events.events).is_empty() and _exact(b_step, _properties(raw))
		and control.st.by_id(2).sup_prog == rate and control.st.by_id(2).supplied == 1
		and control.st.by_id(1).sup_mat == before_stock - cost, "consistent B only starts new progress"): return
	completed.append(NAMES[1])

	if not _restore(owner, b, b_state): return
	var c := b.duplicate(true)
	var a_rows: Array = a.view.service.supply.fleets
	var c_rows: Array = c.view.service.supply.fleets
	if not _check(a_rows[1].id == 2 and c_rows[1].id == 2 and a_rows[1].values.sup_prog == need - rate
		and c_rows[1].values.sup_prog == 0, "single intended progress source and target"): return
	c_rows[1].values.sup_prog = a_rows[1].values.sup_prog
	var reversed := c.duplicate(true)
	reversed.view.service.supply.fleets[1].values.sup_prog = 0
	if not _check(_exact(reversed, b_frozen) and _exact(b, b_frozen) and _exact(a, a_frozen), "only C progress differs"): return
	var c_frozen := c.duplicate(true)
	var original := owner._sim
	var handle := owner.get_instance_id()
	var mixed := owner.restore_completed(c)
	var common := owner.get_instance_id() == handle and owner._ready and not owner._busy and _exact(c, c_frozen)
	details = {"first_tick": first_tick, "rate": rate, "need": need, "cost": cost, "before_stock": before_stock, "restore": mixed}
	if not mixed.ok:
		if not _check(common and is_same(original, owner._sim) and _exact(_properties(original), b_state)
			and mixed.error is String and not mixed.error.is_empty(), "atomic mixed rejection"): return
		completed.append(NAMES[2])
		if not _advance(owner, null): return
		var after_reject := owner.drain_events()
		if not _check(after_reject.ok and _exact(after_reject.events, b_step_events.events)
			and _exact(_properties(owner._sim), b_step), "normal next step after rejection"): return
		observation = "REJECTED_ATOMIC"
	else:
		var active := owner._sim
		_binding(owner)
		_module_bindings(active)
		if not _check(common and not is_same(original, active) and active.st.by_id(2).sup_prog == need - rate
			and active.st.by_id(2).supplied == 1 and active.st.by_id(1).sup_mat == before_stock - cost
			and _exact(active.st.by_id(2).stages["SHP-04"], [2, 1, 1, 0, 0]), "mixed accepted with B values and A progress"): return
		var landed := _capture(owner)
		if not _check(_exact(landed, c_frozen), "accepted runtime captures exact mixed packet"): return
		completed.append(NAMES[2])
		if not _advance(owner, null): return
		var next := owner.drain_events()
		var repair := _service_events(next.events)
		var guest := active.st.by_id(2)
		var stock := active.st.by_id(1).sup_mat
		details.mixed_next = {"tick": active.st.tick, "supplied": guest.supplied, "stock": stock, "healed_mod": guest.healed_mod,
			"stages": guest.stages["SHP-04"], "event_count": repair.size()}
		if (next.ok and _exact(repair, _literal_repair(first_tick + 1, guest.pos)) and guest.supplied == 2
			and guest.healed_mod == 2 and _exact(guest.stages["SHP-04"], [2, 2, 0, 0, 0])
			and stock == before_stock - 2 * cost and active.st.by_id(1).sup_ammo == ammo):
			observation = "ACCEPTED_EARLY_COMPLETION"
		elif next.ok and repair.is_empty() and guest.supplied == 1 and guest.healed_mod == 1 and stock == before_stock - cost:
			observation = "ACCEPTED_NO_EARLY_COMPLETION"
		if not _check(observation != "UNRESOLVED", "one classified mixed next step"): return
	_check(_exact(a, a_frozen) and _exact(b, b_frozen) and _exact(c, c_frozen), "A/B/C immutable through execution")
	completed.append(NAMES[3])

func _run() -> void:
	var fixture_script: Script = Fixture
	if not _class_guard() or not _check(fixture_script.resource_path == "res://tests/lib/salvo_fixture.gd", "canonical fixture script"):
		quit(1)
		return
	var created := Private.create(_profile(), 7, 10, CONTROLS)
	if not _check(created.ok, "fixture create: " + str(created.get("error", ""))):
		quit(1)
		return
	var owner: OperationPrivateState = created.owner
	var raw := BattleSim.new(7, 10, _profile())
	for fleet in raw.st.fleets: fleet.control = "direct"
	raw.projection(0)
	_case(owner, raw)
	owner.close()
	for module in [raw.salvo, raw.detect, raw.supply]:
		if module != null: module.sim = null
	_check(completed == NAMES, "four named checks complete")
	print("P03_SUPPLY_MIX_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(),
		"observation": observation, "details": details, "ok": not failed}))
	quit(1 if failed else 0)

