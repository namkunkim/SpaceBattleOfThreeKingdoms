extends SceneTree

const Service := preload("res://core/battle/operation_service_state.gd")
const SEEDS := [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]
const OUT := "res://tmp/i01b-p2c-resume-20261101/attempt5-p2b-regression-observations.json"
var checks := 0
var failed := false
var cases: Array = []
var rejection_codes := {}

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> bool:
	checks += 1
	if not ok:
		failed = true
		push_error("I01B_P2B_FAIL: " + message)
	return ok

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

func _typed(value: Variant) -> Dictionary:
	var result := {"type": type_string(typeof(value))}
	if value is Dictionary:
		var entries: Array = []
		for key in value: entries.append({"key": _typed(key), "value": _typed(value[key])})
		result.entries = entries
	elif value is Array:
		var entries: Array = []
		for entry in value: entries.append(_typed(entry))
		result.entries = entries
	elif typeof(value) == TYPE_VECTOR2:
		result.x = _typed(value.x)
		result.y = _typed(value.y)
	elif typeof(value) == TYPE_FLOAT:
		result.bytes = var_to_bytes(value).hex_encode()
	else: result.value = value
	return result

# Exact logical data for the prepared-target precondition and side-effect checks.
# These fixtures have Salvo/Detection/Supply only; this is not a whole-game codec.
func _plain(value: Variant) -> Variant:
	if value is Object:
		return _properties(value)
	if value is Dictionary:
		var out := {}
		for key in value: out[key] = _plain(value[key])
		return out
	if value is Array:
		var out: Array = []
		for item in value: out.append(_plain(item))
		return out
	return value

func _properties(value: Object, excluded: Array = []) -> Dictionary:
	var out := {}
	for property in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and property.name not in excluded:
			out[property.name] = _plain(value.get(property.name))
	return out

func _outside(sim: BattleSim) -> Dictionary:
	var fleets: Array = []
	for fleet in sim.st.fleets: fleets.append(_properties(fleet, Service.SUP_FIELDS))
	return {
		"state": _properties(sim.st, ["fleets", "_idx", "_idx_n"]), "fleets": fleets,
		"salvo": _properties(sim.salvo, ["sim", "C", "terr"]) if sim.salvo else {},
		"detect": _properties(sim.detect, ["sim", "D", "terr", "contacts"]) if sim.detect else {},
		"supply": _properties(sim.supply, ["sim", "S"]) if sim.supply else {},
		"command_log": _plain(sim.command_log), "queue": _plain(sim._queue), "events": _plain(sim._events),
		"first_hit_tick": sim.first_hit_tick, "sub_ms": sim.sub_ms,
	}

func _selected(sim: BattleSim) -> Dictionary:
	var fleets: Array = []
	if sim.supply:
		for fleet in sim.st.fleets:
			var values := {}
			for field in Service.SUP_FIELDS: values[field] = fleet.get(field)
			fleets.append({"id": fleet.id, "values": values})
	return {"contacts": sim.detect.contacts.duplicate(true) if sim.detect else [], "supply": fleets}

func _all(sim: BattleSim) -> Dictionary:
	return {"outside": _outside(sim), "selected": _selected(sim)}

func _capture(sim: BattleSim) -> Dictionary:
	var before := _all(sim)
	var answer := Service.capture_partial(sim)
	_check(answer.ok, "capture: " + str(answer.get("error", "")))
	_check(_same(before, _all(sim)), "capture does not change selected or external data")
	return answer.get("packet", {})

func _fixture(seed_id: int, detection: bool, supply: bool) -> BattleSim:
	var full := SalvoFixture.combat()
	var ally: Array = []
	var foe: Array = []
	if supply:
		var supplier := SalvoFixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], true)
		var client := SalvoFixture.def("A", 925, 450, [["SHP-04", 2]])
		supplier.faction_id = "liu_bei"
		client.faction_id = "liu_bei"
		ally = [supplier, client]
		foe = [SalvoFixture.def("Z", 1500, 850, [["SHP-04", 1]], true)]
		foe[0].faction_id = "cao_cao"
	else:
		ally = [SalvoFixture.def("A", 400, 450, [["SHP-01", 10]], true)]
		foe = [SalvoFixture.def("B", 500, 450, [["SHP-02", 4]], true)]
	var sim := SalvoFixture.sim(ally, foe, seed_id, "", func(combat):
		if detection:
			combat.detection = full.detection.duplicate(true)
			combat.detection.view_r = 0
			combat.detection.radar_r = 0
			combat.detection.ship_points_div = 1
		if supply: combat.supply = full.supply.duplicate(true))
	if supply:
		for cat in sim.st.fleets[1].ammo: sim.st.fleets[1].ammo[cat] = 0
	return sim

func _advance(sim: BattleSim, count: int) -> void:
	for i in count:
		sim.step()
		sim.drain_events()

func _suffix(a: BattleSim, b: BattleSim, count: int, label: String) -> void:
	for i in count:
		a.step()
		b.step()
		_check(a.fingerprint() == b.fingerprint(), label + " fingerprint suffix")
		_check(_same(_all(a), _all(b)), label + " exact state and events suffix")
		_check(_same(a.drain_events(), b.drain_events()), label + " event order suffix")

func _restore(a: BattleSim, b: BattleSim, packet: Dictionary, label: String) -> void:
	var outside := _outside(b)
	var source_before := _all(a)
	var packet_before: Dictionary = packet.duplicate(true)
	var detect_ref: Variant = b.detect
	var supply_ref: Variant = b.supply
	var fleets_ref: Array = b.st.fleets.duplicate()
	var answer := Service.restore_into_prepared_target(b, packet)
	_check(answer.ok, label + " restore " + str(answer.get("error", "")))
	_check(_same(outside, _outside(b)), label + " external state unchanged")
	_check(_same(source_before, _all(a)) and _same(packet_before, packet), label + " source and packet unchanged")
	_check(_same(_selected(a), _selected(b)), label + " exact slice restored")
	_check(is_same(detect_ref, b.detect) and is_same(supply_ref, b.supply), label + " module instances unchanged")
	for i in fleets_ref.size(): _check(is_same(fleets_ref[i], b.st.fleets[i]), label + " fleet instances unchanged")
	if b.detect:
		_check(is_same(b.detect.sim, b) and not is_same(b.detect.sim, a), label + " detection target binding")
		_check(not is_same(b.detect.contacts, a.detect.contacts) and not is_same(b.detect.contacts, packet.detection.contacts), label + " contact container detachment")
		for side in 2:
			_check(not is_same(b.detect.contacts[side], packet.detection.contacts[side]), label + " side dictionary detachment")
			for id in b.detect.contacts[side]:
				_check(not is_same(b.detect.contacts[side][id], packet.detection.contacts[side][id]), label + " record detachment")
	if b.supply: _check(is_same(b.supply.sim, b) and not is_same(b.supply.sim, a), label + " supply target binding")
	var again := _all(b)
	_check(Service.restore_into_prepared_target(b, packet).ok and _same(again, _all(b)), label + " repeated apply adds no effects")

# Diagnostic immutability oracle handles NaN, objects and cyclic malicious inputs
# without serializing objects or following their properties.
func _input_stamp(value: Variant, ancestors: Array = []) -> Dictionary:
	var stamp := {"type": typeof(value)}
	if value is Dictionary or value is Array:
		for i in ancestors.size():
			if is_same(value, ancestors[i]):
				stamp.cycle_to_ancestor = i
				return stamp
		var path := ancestors.duplicate()
		path.append(value)
		var entries: Array = []
		if value is Dictionary:
			for key in value: entries.append({"key": _input_stamp(key, path), "value": _input_stamp(value[key], path)})
		else:
			for entry in value: entries.append(_input_stamp(entry, path))
		stamp.entries = entries
	elif value is Object:
		stamp.instance_id = value.get_instance_id()
	else:
		stamp.bytes = var_to_bytes(value).hex_encode()
	return stamp

func _reject(target: BattleSim, packet: Dictionary, label: String) -> void:
	var before := _all(target)
	var packet_before := _input_stamp(packet)
	var answer := Service.restore_into_prepared_target(target, packet)
	_check(not answer.ok, label + " rejected")
	_check(_same(before, _all(target)), label + " atomic refusal")
	_check(_same(packet_before, _input_stamp(packet)), label + " rejected packet unchanged")
	if not answer.ok: rejection_codes[label] = answer.error

func _detection(seed_id: int, wanted: String) -> void:
	var a := _fixture(seed_id, true, false)
	var b := _fixture(seed_id, true, false)
	_advance(a, 2 * a.st.hz)
	_advance(b, 2 * b.st.hz)
	_check(not a.detect.contacts[0].is_empty(), "actual confirmed contact exists")
	for sim in [a, b]: sim.st.fleets[1].pos = Vector2(1500, 450)
	var age_seconds := 30.0 if wanted == "estimated" else 190.0
	_advance(a, roundi(age_seconds * a.st.hz))
	_advance(b, roundi(age_seconds * b.st.hz))
	var id: int = a.st.fleets[1].id
	var record := a.detect.rec(0, id)
	_check(record.get("state") == wanted and record.pos != a.st.fleets[1].pos, "actual " + wanted + " past position retained")
	_check(_same(_all(a), _all(b)), "prepared detection external context equal")
	var packet := _capture(a)
	b.detect.contacts = [{}, {}]
	_check(a.fingerprint() != b.fingerprint(), "omitted contact slice negative control")
	_restore(a, b, packet, wanted)
	var original: Dictionary = record.duplicate(true)
	packet.detection.contacts[0][id].pos = Vector2.ZERO
	_check(_same(a.detect.rec(0, id), original) and _same(b.detect.rec(0, id), original), "packet mutation cannot leak to source/target")
	var wrong := _capture(a)
	wrong.detection.contacts[0][id].pos = a.st.fleets[1].pos
	_check(Service.restore_into_prepared_target(b, wrong).ok and a.fingerprint() != b.fingerprint(), "re-observing actual position diverges")
	_restore(a, b, _capture(a), wanted + " repaired")
	var suffix := a.detect._period + 1
	_suffix(a, b, suffix, wanted)
	cases.append({"kind": wanted, "seed": seed_id, "tick": a.st.tick - suffix, "suffix_ticks": suffix, "record": _typed(original), "scope": "PARTIAL_NOT_CHECKPOINT"})
	_release(a)
	_release(b)

func _supply(seed_id: int, after_completion: bool) -> void:
	var a := _fixture(seed_id, false, true)
	var b := _fixture(seed_id, false, true)
	var cycle: int = a.supply.need / BattleRules.BP
	var tick := cycle + 1 if after_completion else cycle - 1
	_advance(a, tick)
	_advance(b, tick)
	var supplier: FleetState = a.st.fleets[0]
	var client: FleetState = a.st.fleets[1]
	_check(_same(_all(a), _all(b)), "prepared supply external context equal")
	_check(client.supplied > 0 if after_completion else (client.sup_src != "" and client.sup_prog > 0), "actual supply stage reached")
	var initial_stock: int = supplier.sup_n * int(a.supply.S.per_ship.ammo)
	if after_completion: _check(supplier.sup_ammo < initial_stock, "actual resource spending observed")
	var packet := _capture(a)
	b.st.fleets[0].sup_ammo = 0
	b.st.fleets[1].sup_prog = 0
	b.st.fleets[1].sup_src = ""
	_check(a.fingerprint() != b.fingerprint(), "omitted supply slice negative control")
	_restore(a, b, packet, "supply")
	packet.supply.fleets[0].values.sup_ammo = 999
	_check(supplier.sup_ammo == b.st.fleets[0].sup_ammo and b.st.fleets[0].sup_ammo != 999, "supply packet independent")
	# Bad order is proven specifically AFTER a completed service spent stock.
	# Before completion the constructor may reproduce the same stock, which
	# would not be evidence of divergence and is not claimed as such.
	if after_completion:
		var constructor := SupplyCore.new(b, b.supply.S)
		_check(b.st.fleets[0].sup_ammo == initial_stock and b.st.fleets[0].sup_ammo != supplier.sup_ammo, "post-completion constructor bad order resets spent stock")
		constructor.sim = null
		_restore(a, b, _capture(a), "supply after bad order")
	var old_cycles: int = client.supplied
	var old_stock: int = supplier.sup_ammo
	var suffix := 3
	_suffix(a, b, suffix, "supply")
	if not after_completion:
		_check(client.supplied == old_cycles + 1 and supplier.sup_ammo < old_stock, "suffix crosses actual completion and resource spending")
	cases.append({"kind": "supply_post" if after_completion else "supply_pending", "seed": seed_id, "tick": tick, "suffix_ticks": suffix, "stock_before": old_stock, "stock_after": supplier.sup_ammo, "completed_after": client.supplied, "slice": _typed(_selected(a)), "scope": "SUP10_NOT_FULL_ST11"})
	_release(a)
	_release(b)

func _refusals() -> void:
	var a := _fixture(1, true, true)
	_advance(a, 2)
	var packet := _capture(a)
	# Populate contacts naturally in a separate detection pair for late-record checks.
	var det := _fixture(1, true, false)
	_advance(det, 2)
	var dp := _capture(det)
	var id: int = det.st.fleets[1].id
	for kind in ["missing", "extra", "version", "seed", "clock", "profile", "hz", "tick", "roster", "context_type", "module_type", "layout", "cfg", "order", "late_fleet", "source", "priority", "nan", "object", "cycle"]:
		var bad: Dictionary = packet.duplicate(true)
		match kind:
			"missing": bad.erase("supply")
			"extra": bad.extra = true
			"version": bad.format = "unknown"
			"seed": bad.context.seed += 1
			"clock": bad.context.clock_ms += 1
			"profile": bad.context.profile_id = "other"
			"hz": bad.context.hz += 1
			"tick": bad.context.tick += 1
			"roster": bad.context.roster.reverse()
			"context_type": bad.context = []
			"module_type": bad.supply.active = 1
			"layout": bad.supply.active = false
			"cfg": bad.context.combat.supply.stationary_s += 1
			"order": bad.supply.fleets.reverse()
			"late_fleet":
				bad.supply.fleets[0].values.sup_ammo += 1
				bad.supply.fleets[-1].values.sup_hold = 1
			"source": bad.supply.fleets[-1].values.sup_src = "unknown-source"
			"priority": bad.supply.fleets[-1].values.sup_first = a.st.next_id
			"nan": bad.supply.fleets[-1].values.sup_pos = Vector2(NAN, 0)
			"object": bad.extra = a
			"cycle": bad.extra = bad
		_reject(a, bad, kind)
		if kind == "cycle": bad.erase("extra")
	for kind in ["late_contact", "future_seen", "int_error_radius", "bad_state", "foreign_id", "infinity"]:
		var bad: Dictionary = dp.duplicate(true)
		match kind:
			"late_contact":
				bad.detection.contacts[0][id].pos = Vector2.ZERO
				var late_record: Dictionary = bad.detection.contacts[0][id].duplicate(true)
				late_record.conf_bp = "bad"
				bad.detection.contacts[1][det.st.fleets[0].id] = late_record
			"future_seen": bad.detection.contacts[0][id].seen = det.st.tick + 1
			"int_error_radius": bad.detection.contacts[0][id].err_r = 0
			"bad_state": bad.detection.contacts[0][id].state = "hidden"
			"foreign_id": bad.detection.contacts[1][det.st.next_id] = bad.detection.contacts[0][id].duplicate(true)
			"infinity": bad.detection.contacts[0][id].err_r = INF
		_reject(det, bad, kind)
	for count in [1, 3]:
		var malformed: Dictionary = dp.duplicate(true)
		malformed.detection.contacts.resize(count)
		_reject(det, malformed, "packet_side_count_%d" % count)
		var good_contacts: Array = det.detect.contacts
		det.detect.contacts = [{}, {}]
		det.detect.contacts.resize(count)
		_check(not Service.capture_partial(det).ok, "malformed source side count rejected")
		det.detect.contacts = good_contacts
	# Target's selected contacts may be corrupted; restore must not use their
	# length as an oracle for the packet's two-side contract.
	var good_contacts: Array = det.detect.contacts.duplicate(true)
	det.detect.contacts = [{}]
	_check(Service.restore_into_prepared_target(det, dp).ok and _same(det.detect.contacts, good_contacts), "restore repairs selected contact length")
	# Live target binding/config/derived validation must refuse before mutation.
	var old_sim := a.supply.sim
	a.supply.sim = det
	_reject(a, packet, "foreign_module_binding")
	a.supply.sim = old_sim
	a.supply.need += 1
	_reject(a, packet, "derived_target_mismatch")
	a.supply.need -= 1
	var old_stationary: Variant = a.supply.S.stationary_s
	a.supply.S.erase("stationary_s")
	_reject(a, packet, "target_missing_config")
	a.supply.S.stationary_s = old_stationary
	var cfg_order: Dictionary = packet.context.combat.supply.duplicate(true)
	# Preserve the original config key order after the deliberate missing-key probe.
	a.supply.S.clear()
	a.supply.S.merge(cfg_order)
	a.supply.S.stationary_s = "bad"
	_reject(a, packet, "target_config_type")
	a.supply.S.stationary_s = old_stationary
	var old_hz: int = a.st.hz
	a.st.hz = 0
	_reject(a, packet, "target_invalid_hz")
	a.st.hz = old_hz
	# Legacy can retain dead fleet references until next evaluation/step.
	det.st.fleets[1].dead = true
	_check(Service.capture_partial(det).ok, "dead contact ID is a reachable stale reference")
	a.st.fleets[0].sup_first = a.st.fleets[-1].id
	a.st.fleets[-1].dead = true
	a.st.fleets[1].sup_src = "f%d" % a.st.fleets[-1].id
	_check(Service.capture_partial(a).ok, "dead priority/source ID accepted until next service step")
	_release(a)
	_release(det)

func _inactive() -> void:
	var a := BattleSim.new(1)
	var b := BattleSim.new(1)
	_restore(a, b, _capture(a), "both absent")
	_release(a)
	_release(b)

func _release(sim: BattleSim) -> void:
	# Only after observations; teardown is a separate mutation.
	for field in ["morale", "victory", "salvo", "detect", "supply", "chain", "cmd", "assault", "skills", "decisions"]:
		var module: Variant = sim.get(field)
		if module != null:
			for property in module.get_property_list():
				if property.name == "sim": module.set("sim", null)

func _run() -> void:
	_inactive()
	_refusals()
	for seed_id in SEEDS:
		_detection(seed_id, "estimated")
		_detection(seed_id, "lost")
		_supply(seed_id, false)
		_supply(seed_id, true)
	_check(cases.size() == 40, "all planned positive segments completed")
	_check(rejection_codes.size() == 33, "all planned refusal segments completed")
	var report := {"scope": "PARTIAL_IN_MEMORY_NOT_CHECKPOINT", "overall_I01b": "NOT_READY", "external_save_schema": "UNCLASSIFIED", "cases": cases, "rejections": rejection_codes, "checks_before_file_open": checks, "failed": failed}
	var file := FileAccess.open(OUT, FileAccess.WRITE)
	_check(file != null, "open diagnostic evidence")
	if file != null:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	if failed:
		print("I01B_P2B_SERVICE_STATE_FAIL cases=%d checks=%d" % [cases.size(), checks])
		quit(1)
	else:
		print("I01B_P2B_SERVICE_STATE_PASS cases=%d seeds=%d checks=%d rejections=%d PARTIAL_NOT_CHECKPOINT NOT_READY" % [cases.size(), SEEDS.size(), checks, rejection_codes.size()])
		quit(0)