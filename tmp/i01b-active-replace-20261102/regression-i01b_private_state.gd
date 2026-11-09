extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const Service := preload("res://core/battle/operation_service_state.gd")
const SEEDS := [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]
const OUT := "res://tmp/i01b-active-replace-20261102/p2c-regression-observations.json"
var checks := 0
var failed := false
var cases: Array = []
var rejections := {}

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error("I01B_P2C_FAIL " + label)

func _same(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if not _same(a.keys(), b.keys()): return false
		for key in a:
			if not _same(a[key], b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i in a.size():
			if not _same(a[i], b[i]): return false
		return true
	return a == b

# This oracle enumerates actual script properties, not production field lists
# or the packet. It independently includes even newly added script fields.
func _properties(value: Object, excluded: Array = []) -> Dictionary:
	var out := {}
	for property in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(property.name) not in excluded:
			out[property.name] = _plain(value.get(property.name))
	return out

func _plain(value: Variant) -> Variant:
	if value is Object: return _properties(value)
	if value is Dictionary:
		var out := {}
		for key in value: out[key] = _plain(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item in value: out.append(_plain(item))
		return {"typed_builtin": value.get_typed_builtin(), "typed_class": str(value.get_typed_class_name()), "typed_script": value.get_typed_script().resource_path if value.get_typed_script() != null else "", "values": out}
	return value

func _oracle(owner: OperationPrivateState) -> Dictionary:
	var sim := owner._sim
	return {"state": _properties(sim.st, ["_idx", "_idx_n"]),
		"sim": _properties(sim, ["st", "salvo", "terrain", "detect", "supply", "morale", "victory", "cai", "decisions", "chain", "cmd", "assault", "skills"]),
		"salvo": _properties(sim.salvo, ["sim", "C", "terr"]) if sim.salvo else {},
		"terrain": _properties(sim.terrain) if sim.terrain else {},
		"detect": _properties(sim.detect, ["sim", "D", "terr"]) if sim.detect else {},
		"supply": _properties(sim.supply, ["sim", "S"]) if sim.supply else {}}

# Malicious packet stamp has no property traversal and terminates on cycles.
func _stamp(value: Variant, path: Array = []) -> Variant:
	if value is Object: return ["Object", value.get_instance_id()]
	if value is Array or value is Dictionary:
		for old in path:
			if is_same(value, old): return ["cycle"]
		var next := path.duplicate()
		next.append(value)
		var out: Array = [type_string(typeof(value))]
		if value is Array:
			out.append([value.get_typed_builtin(), str(value.get_typed_class_name()), value.get_typed_script().resource_path if value.get_typed_script() != null else ""])
		if value is Dictionary:
			for key in value: out.append([_stamp(key, next), _stamp(value[key], next)])
		else:
			for item in value: out.append(_stamp(item, next))
		return out
	return [type_string(typeof(value)), var_to_bytes(value).hex_encode()]

func _profile(kind: String) -> Dictionary:
	var rules: Dictionary = PocSetup.profile().rules
	rules.world_w = 3400
	rules.world_h = 2300
	if kind == "projectile":
		return {"profile_id": "p2c-restricted-poc", "rules": rules, "ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}], "foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 750, "y": 500, "p": 0, "flag": true}], "reinf": []}
	var combat := SalvoFixture.combat()
	for key in ["morale", "victory", "command", "stratagem", "assault"]: combat.erase(key)
	if kind != "terrain": combat.erase("terrain")
	if kind not in ["memory"]: combat.erase("detection")
	if kind not in ["pending", "post"]: combat.erase("supply")
	var ally: Array = []
	var foe: Array = []
	if kind in ["pending", "post"]:
		ally = [SalvoFixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], true), SalvoFixture.def("C", 925, 450, [["SHP-04", 2]])]
		foe = [SalvoFixture.def("F", 3000, 1800, [["SHP-04", 2]], true)]
		ally[0].faction_id = "liu_bei"
		ally[1].faction_id = "liu_bei"
		foe[0].faction_id = "cao_cao"
	else:
		ally = [SalvoFixture.def("A", 400, 450, [["SHP-01", 1], ["SHP-03", 1], ["SHP-04", 2]], true)]
		foe = [SalvoFixture.def("B", 550, 450, [["SHP-02", 40]], true)]
		if kind == "memory":
			ally = [SalvoFixture.def("A", 400, 450, [["SHP-01", 10]], true)]
			foe = [SalvoFixture.def("B", 550, 450, [["SHP-02", 4]], true)]
		if kind == "terrain":
			ally[0].x = 650
			ally[0].y = 100
			foe[0].x = 1000
			foe[0].y = 100
	return {"profile_id": "p2c-" + kind, "rules": rules, "ally": ally, "foe": foe, "reinf": [], "combat": combat}

func _new(seed: int, kind: String) -> OperationPrivateState:
	var result := Private.create(_profile(kind), seed, 10)
	_check(result.ok, "create " + kind)
	if not result.ok: return null
	var owner: OperationPrivateState = result.owner
	# Fixture-only inspection/setup of private fields. Production callers receive
	# no mutable runtime reference; all evolution below uses the owner operations.
	owner._sim.st.ai_timer = 1 << 40
	owner._sim.endless = true
	return owner

func _advance(owner: OperationPrivateState, count: int, drain := true) -> void:
	for i in count:
		owner.advance()
		if drain: owner.drain_events()

func _suffix(a: OperationPrivateState, b: OperationPrivateState, count: int, label: String) -> void:
	for i in count:
		if i == 1:
			var command := BattleSim.command(0, [1], "stop")
			_check(a.queue(command).ok and b.queue(command).ok, label + " suffix input")
		a.advance()
		b.advance()
		_check(_same(_oracle(a), _oracle(b)), label + " suffix state " + str(i))
		_check(_same(a.drain_events(), b.drain_events()), label + " suffix ordered events " + str(i))

func _roundtrip(seed: int, kind: String) -> void:
	var a := _new(seed, kind)
	if a == null: return
	var sim := a._sim
	var before_stock := 0
	if kind == "projectile":
		_check(a.issue(BattleSim.command(0, [1], "missile", 2)).ok, "actual missile issue")
		_check(a.issue(BattleSim.command(1, [2], "fighter", 1)).ok, "actual fighter issue")
		_advance(a, 1, false)
		_check(not sim.st.missiles.is_empty() and not sim.st.swarms.is_empty(), "active missile and swarm")
		_check(sim.st.fleets[0].missile_cd > 0 and sim.st.fleets[1].fighter_cd > 0, "active weapon timers")
	elif kind in ["pending", "post"]:
		# Empty initial cargo is fixture setup; real Supply.step assigns/spends it.
		for category in sim.st.fleets[1].ammo: sim.st.fleets[1].ammo[category] = 0
		before_stock = sim.st.fleets[0].sup_ammo
		_advance(a, 599 if kind == "pending" else 601)
		if kind == "pending": _check(sim.st.fleets[1].sup_prog > 0 and sim.st.fleets[1].supplied == 0, "actual incomplete supply")
		else: _check(sim.st.fleets[1].supplied > 0 and sim.st.fleets[0].sup_ammo < before_stock, "actual completed supply spending")
	elif kind == "memory":
		_advance(a, 1)
		_check(sim.detect.contacts[0].has(2), "real observed contact")
		# Test-only relocation creates an unseen target; memory itself is generated
		# and aged by actual detection evaluation at ordinary completed steps.
		sim.st.fleets[1].pos = Vector2(3200, 2000)
		_advance(a, 11)
		_check(sim.detect.contacts[0].has(2) and sim.detect.contacts[0][2].state == "estimated" and sim.detect.contacts[0][2].pos != sim.st.fleets[1].pos, "actual stale remembered position")
	elif kind == "damaged":
		var capacity: Dictionary = sim.st.fleets[0].wmax.duplicate(true)
		# Fixture invokes the same production damage+removal path synchronously.
		# Platform destruction is real, not a manual wmax edit.
		sim.salvo.apply_hull(sim.st.fleets[1], sim.st.fleets[0], float(sim.st.fleets[0].max_hull), "engagement", "front", sim.st.new_event_id())
		sim.remove_fleet(sim.st.fleets[0], "sunk")
		_check(not _same(capacity, sim.st.fleets[0].wmax) and sim.st.fleets[0].lost_ships > 0, "real platform loss changes dynamic wmax")
	elif kind == "terrain":
		_check(sim.terrain != null and sim.terrain.move_cost_bp(sim.st.fleets[0].pos) > 10000, "real terrain effect active")
		var position := sim.st.fleets[0].pos
		a.issue(BattleSim.command(0, [1], "move", -1, Vector2(850, 100)))
		_advance(a, 5, false)
		_check(sim.st.fleets[0].pos != position, "actual movement through effect terrain")
	else:
		for category in sim.st.fleets[1].next_fire: sim.st.fleets[1].next_fire[category] = 1 << 40
		var initial_ammo: Dictionary = sim.st.fleets[0].ammo.duplicate(true)
		var initial_charges: Dictionary = sim.st.fleets[0].wch.duplicate(true)
		var initial_energy := sim.st.fleets[0].energy_m
		var initial_hull := sim.st.fleets[1].hull
		_check(a.issue(BattleSim.command(0, [1], "attack", 2)).ok, "salvo attack")
		_check(a.issue(BattleSim.command(0, [1], "volley")).ok, "salvo actual pull")
		_advance(a, 5, false)
		_check(sim._events.any(func(event): return event.kind == "salvo"), "actual salvo event")
		_check(not _same(initial_ammo, sim.st.fleets[0].ammo) and not _same(initial_charges, sim.st.fleets[0].wch), "actual ammo and charge spending")
		_check(sim.st.fleets[0].energy_m < initial_energy and sim.st.fleets[0].heat_m > 0, "actual energy heat state")
		_check(sim.st.fleets[0].energy_rem != 0 or sim.st.fleets[0].heat_rem != 0, "actual fractional resource remainder")
		_check(sim.st.fleets[1].hull < initial_hull, "actual volley damage")
		_check(a.issue(BattleSim.command(0, [1], "formation", -1, Vector2.ZERO, {"id": "FRM-02"})).ok, "formation transition issue")
		_check(sim.st.fleets[0].form_left > 0, "actual transition timer")
	var command := BattleSim.command(0, [1], "stop")
	var log_size := sim.command_log.size()
	_check(a.queue(command).ok, "queue accepted")
	command.kind = "attack"
	command.ids.append(9999)
	_check(sim._queue.back().kind == "stop" and sim._queue.back().ids.size() == 1 and sim.command_log.size() == log_size, "pending detached and unapplied")
	# Warm source cache; this reference must never enter the restored target.
	var source_fleet := sim.st.by_id(1)
	var before := _oracle(a)
	var captured := a.capture_completed()
	_check(captured.ok, "capture " + kind)
	if not captured.ok:
		a.close()
		return
	var packet: Dictionary = captured.packet
	var packet_stamp: Variant = _stamp(packet)
	var restored := Private.prepare(packet)
	_check(restored.ok, "fresh restore " + kind + " " + str(restored.get("error", "")))
	if not restored.ok:
		a.close()
		return
	var b: OperationPrivateState = restored.owner
	_check(_same(before, _oracle(b)), "independent full typed oracle " + kind)
	_check(_same(before, _oracle(a)) and _same(packet_stamp, _stamp(packet)), "prepare preserves source and packet")
	_check(not is_same(source_fleet, b._sim.st.by_id(1)) and is_same(b._sim.st.by_id(1), b._sim.st.fleets[0]), "target cache references own fleet")
	_check(b._sim.command_log.size() == log_size and b._sim._queue.size() == 1, "prepare never applies pending")
	var wrong_result := Private.prepare(packet)
	_check(wrong_result.ok, "negative clone")
	if wrong_result.ok:
		var wrong: OperationPrivateState = wrong_result.owner
		if kind == "projectile": wrong._sim.st.missiles[0].age = 0
		elif kind in ["pending", "post"]: wrong._sim.st.fleets[1].supplied += 1
		else: wrong._sim.st.fleets[0].next_fire.clear()
		_check(not _same(_oracle(a), _oracle(wrong)), "independent omitted field negative " + kind)
		wrong.close()
	# P2b alone must not silently count as full fresh restore.
	var naive := _new(seed, kind)
	naive._sim.st.tick = sim.st.tick
	naive._sim.st.clock_ms = sim.st.clock_ms
	var partial := Service.restore_into_prepared_target(naive._sim, packet.view.service)
	_check(partial.ok and not _same(_oracle(naive), before), "P2b alone insufficient " + kind)
	naive.close()
	var suffix_steps := 110 if kind == "projectile" else 65
	_suffix(a, b, suffix_steps, kind)
	_check(a._sim.command_log.size() == log_size + 2, "pending and suffix input each applied once")
	_check(a._sim._queue.is_empty() and b._sim._queue.is_empty(), "pending consumed once")
	if kind == "projectile": _check(a._sim.st.missiles.is_empty() and a._sim.st.swarms.is_empty(), "suffix crosses projectile lifetime")
	if kind == "pending": _check(a._sim.st.fleets[1].supplied == 1 and a._sim.st.fleets[0].sup_ammo < before_stock, "suffix crosses actual supply completion")
	if kind == "post": _check(a._sim.st.fleets[1].supplied == 1, "post supply not repeated")
	if kind == "resource": _check(a._sim.st.fleets[0].form_left == 0 and a._sim.st.fleets[0].formation_id == "FRM-02", "suffix completes actual formation transition")
	# Mutable packet/observe containers must not reach either runtime.
	var stable_a := _oracle(a)
	var stable_b := _oracle(b)
	packet.view.fleets[0].route.append(Vector2(1, 2))
	packet.profile.ally[0].name = "packet mutation"
	var view := b.observe()
	view.fleets[0].ammo["alias-probe"] = 3
	_check(_same(stable_a, _oracle(a)) and _same(stable_b, _oracle(b)), "packet and observe alias isolation")
	cases.append({"seed": seed, "kind": kind, "suffix_steps": suffix_steps, "tick": a._sim.st.tick, "clock_ms": a._sim.st.clock_ms, "log_size": a._sim.command_log.size()})
	a.close()
	b.close()

func _reject(owner: OperationPrivateState, packet: Dictionary, label: String) -> void:
	var source := _oracle(owner)
	var stamp: Variant = _stamp(packet)
	var result := Private.prepare(packet)
	_check(not result.ok and not result.has("owner"), "reject " + label)
	_check(_same(source, _oracle(owner)) and _same(stamp, _stamp(packet)), "reject atomic " + label)
	rejections[label] = result.get("error", "UNEXPECTED_SUCCESS")
	if result.ok: result.owner.close()

func _negative() -> void:
	var typed: Array[int] = [1]
	var untyped: Array = [1]
	_check(not _same(_plain(typed), _plain(untyped)), "independent oracle catches array metadata mismatch")
	var profile := _profile("projectile")
	var controls: Array = ["direct", "delegate"]
	var created := Private.create(profile, 1, 10, controls)
	_check(created.ok, "explicit initial controls")
	if created.ok:
		var isolated: OperationPrivateState = created.owner
		var raw := _oracle(isolated)
		profile.rules.world_w = 999
		profile.ally[0].name = "caller mutation"
		controls[0] = "delegate"
		_check(_same(raw, _oracle(isolated)) and isolated._profile.rules.world_w != 999 and isolated._controls[0] == "direct", "caller profile controls deep isolated")
		isolated.close()
	var owner := _new(20824, "projectile")
	owner.issue(BattleSim.command(0, [1], "missile", 2))
	owner.issue(BattleSim.command(1, [2], "fighter", 1))
	owner.queue(BattleSim.command(0, [1], "stop"))
	var packet: Dictionary = owner.capture_completed().packet
	var changes := {
		"format": func(p): p.format = "other",
		"code": func(p): p.code["rules.gd"] = "wrong",
		"seed": func(p): p.seed = -1,
		"hz": func(p): p.hz = 20,
		"reinf": func(p): p.profile.reinf = [{}],
		"scenario": func(p): p.profile.scenario = {"active": true},
		"ai": func(p): p.profile.ai = {"active": true},
		"rules": func(p): p.profile.rules.missile_v0 = 0,
		"missing_profile": func(p): p.profile.erase("ally"),
		"profile_bad_type": func(p): p.profile.rules = 5,
		"view": func(p): p.view.erase("state"),
		"state_extra": func(p): p.view.state.extra = 1,
		"clock": func(p): p.view.state.clock_ms = -1,
		"late_fleet": func(p): p.view.fleets.back().max_ships = 0,
		"late_fleet_id": func(p): p.view.fleets.back().id = 1,
		"reference": func(p): p.view.fleets.back().target_id = 999,
		"fleet_type": func(p): p.view.fleets.back().ships = "bad",
		"fleet_route": func(p): p.view.fleets.back().route = ["bad"],
		"event": func(p): p.view.sim._events.back().pos = 7,
		"pending": func(p): p.view.sim._queue.back().ids = ["bad"],
		"pending_kind": func(p): p.view.sim._queue.back().kind = "skill",
		"pending_args": func(p): p.view.sim._queue.back().args = {"extra": true},
		"log": func(p): p.view.sim.command_log.back().point = "bad",
		"sim_container": func(p): p.view.sim._events = 3,
		"projectile_id": func(p): p.view.missiles.back().id = p.view.state.next_event_id,
		"projectile_src": func(p): p.view.missiles.back().src_id = 999,
		"projectile_age": func(p): p.view.missiles.back().age = -1,
		"projectile_type": func(p): p.view.missiles.back().v = "bad",
		"swarm_point": func(p): p.view.swarms.back().pts.back().w = "bad",
		"service": func(p): p.view.service = 5,
		"derived": func(p): p.view.derived.dt = 0.2,
		"nan": func(p): p.view.fleets.back().heading = NAN,
		"infinity": func(p): p.view.missiles.back().pos = Vector2(INF, 0),
	}
	for label in changes:
		var bad: Dictionary = packet.duplicate(true)
		changes[label].call(bad)
		_reject(owner, bad, label)
	var stable_result := Private.prepare(packet)
	_check(stable_result.ok, "normal packet prepares before empty form rejection")
	if stable_result.ok:
		var stable: OperationPrivateState = stable_result.owner
		var stable_before := _oracle(stable)
		for index in [0, packet.view.fleets.size() - 1]:
			var empty_form_packet: Dictionary = packet.duplicate(true)
			empty_form_packet.view.fleets[index].form.clear()
			var label: String = "empty_form_first" if index == 0 else "empty_form_last"
			_reject(owner, empty_form_packet, label)
			_check(rejections[label] == "fleet_empty_form", "empty form expected error " + label)
			_check(_same(stable_before, _oracle(stable)), "empty form preserves existing successful owner " + label)
		stable.close()
	var object := RefCounted.new()
	var bad: Dictionary = packet.duplicate(true)
	bad.view.state.result.probe = object
	_reject(owner, bad, "Object")
	bad = packet.duplicate(true)
	bad.view.state.result.self = bad.view.state.result
	_reject(owner, bad, "cycle")
	bad.view.state.result.clear()
	var combat := _new(1, "resource")
	var combat_packet: Dictionary = combat.capture_completed().packet
	for key in ["next_fire", "ammo", "wch", "wmax", "comp0", "stats", "stages"]:
		bad = combat_packet.duplicate(true)
		bad.view.fleets.back()[key] = {}
		_reject(combat, bad, "missing_nested_" + key)
	bad = combat_packet.duplicate(true)
	bad.profile.combat.morale = SalvoFixture.combat().morale
	_reject(combat, bad, "unsupported_morale")
	combat.close()
	# All malformed public inputs must fail before log/events/control mutation.
	var inputs := [
		{}, BattleSim.command(0, [1], "skill"), BattleSim.command(0, [1], "move", -1, Vector2(NAN, 0)),
		BattleSim.command(0, [1, 1], "stop"), BattleSim.command(0, [1], "formation", -1, Vector2.ZERO, {"id": 1}),
		BattleSim.command(0, [1], "supply_hold", -1, Vector2.ZERO, {"on": 1}),
		BattleSim.command(0, [1], "stop", -1, Vector2.ZERO, {"extra": true})]
	for i in inputs.size():
		for pending in [false, true]:
			var before := _oracle(owner)
			var result := owner.queue(inputs[i]) if pending else owner.issue(inputs[i])
			_check(not result.ok and _same(before, _oracle(owner)) and not owner._busy, "malformed public atomic " + str(i))
	var before := _oracle(owner)
	owner._busy = true
	_check(not owner.capture_completed().ok and not owner.issue(BattleSim.command(0, [1], "stop")).ok and not owner.queue(BattleSim.command(0, [1], "stop")).ok and not owner.advance().ok and not owner.drain_events().ok and not owner.observe().ok, "busy guard all operations")
	owner._busy = false
	_check(_same(before, _oracle(owner)), "busy rejection no mutation")
	owner._ready = false
	_check(not owner.capture_completed().ok, "incomplete guard")
	owner._ready = true
	var log_size := owner._sim.command_log.size()
	var events_size := owner._sim._events.size()
	_check(owner.issue(BattleSim.command(0, [99999], "stop")).ok and owner._sim.command_log.size() == log_size + 1 and owner._sim._events.size() == events_size + 1 and owner._sim._events.back().kind == "rejected", "logical rejected is completed logged event")
	var drained := owner.drain_events()
	_check(drained.ok and owner.drain_events().events.is_empty(), "drain exactly once")
	owner.close()
	_check(not owner.capture_completed().ok, "closed guard")

func _run() -> void:
	for seed in SEEDS:
		for kind in ["projectile", "resource", "memory", "pending", "post", "damaged", "terrain"]: _roundtrip(seed, kind)
	_negative()
	_check(cases.size() == 70, "complete seventy cases")
	_check(rejections.size() == 45, "complete named rejections")
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	_check(file != null, "evidence output opens")
	if file != null:
		file.store_string(JSON.stringify({"scope": "RESTRICTED_PRIVATE_RUNTIME_NOT_CHECKPOINT", "overall": "NOT_READY", "cases": cases, "checks": checks, "rejections": rejections, "failed": failed}, "  "))
		file.close()
	print("I01B_P2C_PRIVATE_STATE_", "FAIL" if failed else "PASS", " cases=", cases.size(), " checks=", checks, " rejections=", rejections.size())
	quit(1 if failed else 0)
