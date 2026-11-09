class_name OperationServiceState
extends RefCounted

# Partial in-memory component, NOT a checkpoint, save file, C0 or whole ST11.
# Caller owns a prepared, quiescent target and must first restore every field
# outside contacts and SUP_FIELDS (ammo/stages/healing/events/commands included).
# Matching context is necessary, not proof that those external fields agree.
const FORMAT := "i01b/service-slice/1"
const SUP_FIELDS := ["sup_src", "sup_prog", "sup_since", "sup_still", "sup_pos", "sup_n", "sup_ammo", "sup_mat", "sup_hold", "sup_first"]
const RECORD_FIELDS := ["seen", "pos", "state", "conf_bp", "err_r"]

static func capture_partial(sim: BattleSim) -> Dictionary:
	var error := _bindings(sim)
	if error != "": return _failure(error)
	var fleets: Array = []
	if sim.supply != null:
		for fleet in sim.st.fleets:
			var values := {}
			for field in SUP_FIELDS: values[field] = fleet.get(field)
			fleets.append({"id": fleet.id, "values": values})
	var packet := {
		"format": FORMAT, "context": _context(sim),
		"detection": {"active": sim.detect != null, "contacts": sim.detect.contacts.duplicate(true) if sim.detect != null else []},
		"supply": {"active": sim.supply != null, "fleets": fleets},
	}
	error = _preflight(sim, packet)
	if error != "": return _failure(error)
	return {"ok": true, "packet": packet}

static func restore_into_prepared_target(target: BattleSim, packet: Dictionary) -> Dictionary:
	var error := _bindings(target)
	if error == "": error = _preflight(target, packet)
	if error != "": return _failure(error)
	# No constructors, evaluation, steps, events or resource spending here.
	# Validate every late entry before the first write; detach before applying.
	var detached: Dictionary = packet.duplicate(true)
	if target.detect != null: target.detect.contacts = detached.detection.contacts
	if target.supply != null:
		for i in target.st.fleets.size():
			for field in SUP_FIELDS:
				target.st.fleets[i].set(field, detached.supply.fleets[i].values[field])
	return {"ok": true}

static func _failure(code: String) -> Dictionary:
	return {"ok": false, "error": code}

static func _keys(value: Variant, expected: Array) -> bool:
	if not value is Dictionary or value.size() != expected.size(): return false
	for key in expected:
		if not value.has(key): return false
	return true

static func _has(value: Variant, required: Array) -> bool:
	if not value is Dictionary: return false
	for key in required:
		if not value.has(key): return false
	return true

static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT]

static func _same(a: Variant, b: Variant) -> bool:
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

# Reject objects, non-finite values and cyclic containers before deep copy.
static func _data(value: Variant, ancestors: Array = []) -> bool:
	if value is Dictionary or value is Array:
		for old in ancestors:
			if is_same(value, old): return false
		var path := ancestors.duplicate()
		path.append(value)
		if value is Dictionary:
			for key in value:
				if typeof(key) not in [TYPE_INT, TYPE_STRING, TYPE_STRING_NAME]: return false
				if not _data(value[key], path): return false
		else:
			for entry in value:
				if not _data(entry, path): return false
		return true
	if typeof(value) == TYPE_FLOAT: return is_finite(value)
	if typeof(value) == TYPE_VECTOR2: return is_finite(value.x) and is_finite(value.y)
	return typeof(value) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING, TYPE_STRING_NAME]

static func _bindings(sim: BattleSim) -> String:
	if sim == null or sim.st == null or sim.rs == null: return "invalid_target"
	if sim.st.hz <= 0: return "invalid_hz"
	if not _data(sim.R) or not _data(sim.rs.scenario): return "invalid_rules_data"
	if sim.salvo != null and not _data(sim.salvo.C): return "invalid_combat_data"
	if sim.detect != null:
		if sim.salvo == null or not is_same(sim.detect.sim, sim): return "detection_binding"
		if not is_same(sim.detect.D, sim.salvo.C.get("detection")): return "detection_config_binding"
		if sim.detect.terr == null: return "terrain_binding"
		if sim.terrain != null and not is_same(sim.detect.terr, sim.terrain): return "terrain_binding"
		if sim.terrain == null and not sim.detect.terr.zones.is_empty(): return "terrain_fallback"
		var cfg: Dictionary = sim.detect.D
		if not _has(cfg, ["eval_period_s", "confidence_bp"]) or not _number(cfg.eval_period_s) or not _number(cfg.confidence_bp): return "detection_config_fields"
		if sim.detect._period != maxi(1, BattleRules.ticks(float(cfg.eval_period_s), sim.st.hz)): return "detection_period"
		if sim.detect._conf0 != int(sim.rs.rt("fog_override.estimated_confidence_basis_points", cfg.confidence_bp)): return "detection_confidence"
	if sim.supply != null:
		if sim.salvo == null or not is_same(sim.supply.sim, sim): return "supply_binding"
		if not is_same(sim.supply.S, sim.salvo.C.get("supply")): return "supply_config_binding"
		var cfg: Dictionary = sim.supply.S
		if not _has(cfg, ["ship_type_id", "stationary_s", "repair", "still_eps_px_s", "bases", "mutual"]): return "supply_config_fields"
		if typeof(cfg.ship_type_id) != TYPE_STRING or not _number(cfg.stationary_s) or not _number(cfg.still_eps_px_s): return "supply_config_type"
		if not _has(cfg.repair, ["light_recover_s"]) or not _number(cfg.repair.light_recover_s): return "supply_repair_config"
		if not cfg.bases is Array or not cfg.mutual is Array: return "supply_config_container"
		for group in cfg.mutual:
			if not group is Array: return "supply_mutual_config"
		if sim.supply.ship != str(cfg.ship_type_id): return "supply_ship"
		if sim.supply.need != BattleRules.ticks(float(cfg.stationary_s), sim.st.hz) * BattleRules.BP: return "supply_need"
		if sim.supply.light_ticks != BattleRules.ticks(float(cfg.repair.light_recover_s), sim.st.hz): return "supply_light_ticks"
		if sim.supply.still_eps != float(cfg.still_eps_px_s) / sim.st.hz: return "supply_still_eps"
		var expected: Array = []
		for base in cfg.bases:
			if not _has(base, ["id", "faction_id", "position"]): return "supply_base_config"
			if not base.position is Array or base.position.size() != 2: return "supply_base_position"
			if not _number(base.position[0]) or not _number(base.position[1]): return "supply_base_position"
			var side := -1
			for fleet in sim.st.fleets:
				if sim.supply.allied(fleet.faction, str(base.faction_id)): side = fleet.side
			expected.append({"key": str(base.id), "faction": str(base.faction_id), "side": side, "pos": Vector2(float(base.position[0]), float(base.position[1]))})
		if not _same(sim.supply.bases, expected): return "supply_bases"
	return ""

static func _context(sim: BattleSim) -> Dictionary:
	var roster: Array = []
	for fleet in sim.st.fleets: roster.append({"id": fleet.id, "side": fleet.side, "faction": fleet.faction})
	return {
		"profile_id": sim.profile_id, "seed": sim.st.seed_id, "hz": sim.st.hz,
		"tick": sim.st.tick, "clock_ms": sim.st.clock_ms, "roster": roster,
		"rules": sim.R.duplicate(true), "scenario": sim.rs.scenario.duplicate(true),
		"combat": sim.salvo.C.duplicate(true) if sim.salvo != null else {},
		"detection_derived": {"period": sim.detect._period, "conf0": sim.detect._conf0, "zones": sim.detect.terr.zones.duplicate(true)} if sim.detect != null else {},
		"supply_derived": {"ship": sim.supply.ship, "need": sim.supply.need, "light_ticks": sim.supply.light_ticks, "still_eps": sim.supply.still_eps, "bases": sim.supply.bases.duplicate(true)} if sim.supply != null else {},
	}

static func _preflight(target: BattleSim, packet: Dictionary) -> String:
	if not _data(packet): return "unsupported_value"
	if not _keys(packet, ["format", "context", "detection", "supply"]): return "packet_fields"
	if typeof(packet.format) != TYPE_STRING or packet.format != FORMAT: return "unsupported_format"
	if not _same(packet.context, _context(target)): return "context_mismatch"
	if not _keys(packet.detection, ["active", "contacts"]) or not _keys(packet.supply, ["active", "fleets"]): return "module_fields"
	if typeof(packet.detection.active) != TYPE_BOOL or typeof(packet.supply.active) != TYPE_BOOL: return "module_type"
	if packet.detection.active != (target.detect != null) or packet.supply.active != (target.supply != null): return "module_layout"
	if not packet.detection.contacts is Array or not packet.supply.fleets is Array: return "module_container"
	var ids := {}
	var source_keys := {"": true}
	for fleet in target.st.fleets:
		if ids.has(fleet.id): return "duplicate_target_id"
		ids[fleet.id] = true
		# A dead/stopped supplier may remain referenced until the next step.
		source_keys["f%d" % fleet.id] = true
	if target.supply != null:
		for base in target.supply.bases: source_keys[base.key] = true
	if target.detect == null:
		if not packet.detection.contacts.is_empty(): return "inactive_contacts"
	else:
		if packet.detection.contacts.size() != 2: return "contact_sides"
		for book in packet.detection.contacts:
			if not book is Dictionary: return "contact_book"
			for id in book:
				if typeof(id) != TYPE_INT or not ids.has(id): return "contact_id"
				var record: Variant = book[id]
				if not _keys(record, RECORD_FIELDS): return "contact_fields"
				if typeof(record.seen) != TYPE_INT or record.seen < 0 or record.seen > target.st.tick: return "contact_seen"
				if typeof(record.pos) != TYPE_VECTOR2 or typeof(record.err_r) != TYPE_FLOAT or record.err_r < 0.0: return "contact_geometry"
				if typeof(record.state) != TYPE_STRING or record.state not in ["confirmed", "estimated", "lost"]: return "contact_state"
				if typeof(record.conf_bp) != TYPE_INT or record.conf_bp < 0 or record.conf_bp > BattleRules.BP: return "contact_confidence"
	if target.supply == null:
		if not packet.supply.fleets.is_empty(): return "inactive_supply"
	else:
		if packet.supply.fleets.size() != target.st.fleets.size(): return "fleet_count"
		for i in packet.supply.fleets.size():
			var entry: Variant = packet.supply.fleets[i]
			if not _keys(entry, ["id", "values"]): return "fleet_fields"
			if typeof(entry.id) != TYPE_INT or entry.id != target.st.fleets[i].id: return "fleet_order"
			var values: Variant = entry.values
			if not _keys(values, SUP_FIELDS): return "supply_fields"
			for field in SUP_FIELDS:
				if typeof(values[field]) != typeof(target.st.fleets[i].get(field)): return "supply_type"
			if not source_keys.has(values.sup_src): return "supply_source"
			if values.sup_first != -1 and not ids.has(values.sup_first): return "supply_priority_id"
			if values.sup_since < -1 or values.sup_since > target.st.tick: return "supply_since"
			for field in ["sup_prog", "sup_n", "sup_ammo", "sup_mat"]:
				if values[field] < 0: return "negative_supply"
	return ""