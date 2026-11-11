extends RefCounted

const PATH := "res://data/scenarios/p05_p07_first_operation_dev_v1.json"
const SOURCE_SHA := "1e385b25003a5c78bc7a0c4ec0de90ac27f46f290c8277192092803e43e8a164"
const SITES := ["A", "B", "C"]

var _definition: Dictionary
var _operation_id: String
var _route: String
var _fleets: Dictionary
var _state: Dictionary
var _pending: Dictionary = {}
var _proposal_id := 0


static func load_source() -> Dictionary:
	if FileAccess.get_sha256(PATH) != SOURCE_SHA:
		return _fail("candidate_digest_mismatch")
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if not source is Dictionary or source.space.kind != "source":
		return _fail("invalid_candidate_source")
	return {"ok": true, "definition": source}


# P03's prepared envelope marks the single identity transform. The original
# definition nested in that envelope stays in source form for digest validation.
static func create(effective: Dictionary, operation_id: String, route_id: String) -> Dictionary:
	var loaded := load_source()
	if not loaded.ok:
		return loaded
	if (effective.get("space") != "effective" or effective.get("origin") != [0, 0]
			or effective.get("world_size") != [int(loaded.definition.space.size[0]), int(loaded.definition.space.size[1])] or effective.get("definition") != loaded.definition):
		return _fail("invalid_effective_definition")
	if operation_id.is_empty() or route_id not in ["front", "flank"]:
		return _fail("invalid_operation_selection")
	var runtime: RefCounted = new()
	runtime._configure(loaded.definition, operation_id, route_id)
	return {"ok": true, "policy": runtime}


func _configure(definition: Dictionary, operation_id: String, route_id: String) -> void:
	_definition = definition
	_operation_id = operation_id
	_route = route_id
	_fleets = {}
	for fleet: Dictionary in definition.fleets:
		_fleets[fleet.id] = fleet
	_state = {"revision": 0, "tick": 0, "clock_ms": 0, "event_seq": 0,
		"sites": {}, "entries": {}, "exits": {}, "settlement": {}, "withdrawal": false,
		"secured": false, "transactions": [], "losses": {}, "reinforcement": "scheduled"}
	for site: String in SITES:
		_state.sites[site] = {"control": definition.capture.initial_control[site], "active": false,
			"epoch": 0, "actor": "", "capture_ms": 0, "activation_ms": 0, "active_since_ms": -1, "work": {},
			"stock": definition.supply.stock_by_facility.get(site, {}).duplicate()}


func route_points(route_id: String, reverse := false) -> Array[Vector2]:
	var points: Array[Vector2] = []
	if route_id not in [_route, "reinforcement"] or (reverse and route_id == "reinforcement"):
		return points
	var route: Dictionary = _definition.space.routes[route_id]
	for id: String in route.nodes:
		points.append(_node(id))
	var c := points[-1]
	points[-1] = c.move_toward(points[-2], float(route.approach_standoff))
	if reverse:
		points.reverse()
	return points


# moves contains all live participants: id -> {from, to, heading_from,
# heading_to, formation_id}. Movers also carry plan_from/plan_to (group
# reference center for the selected leg). Other live fleets may hold position.
func validate_movement(moves: Dictionary, leg: int, elapsed_ms: int,
		route_id := "", reverse := false) -> Dictionary:
	var route := _route if route_id.is_empty() else route_id
	var points := route_points(route, reverse)
	var motion: Dictionary = _definition.space.motion
	if (leg < 0 or leg + 1 >= points.size() or elapsed_ms <= 0 or elapsed_ms > motion.max_step_ms
			or moves.is_empty() or (reverse and not _state.withdrawal)):
		return _fail("invalid_movement_context")
	var ids := moves.keys()
	var space: Dictionary = _definition.space
	for id: Variant in ids:
		var row: Variant = moves[id]
		if (not _fleets.has(id) or not row is Dictionary or not _finite_position(row.get("from"))
				or not _finite_position(row.get("to")) or not _number(row.get("heading_from"))
				or not _number(row.get("heading_to"))
				or row.get("formation_id") not in _fleets[id].allowed_formations):
			return _fail("invalid_movement_fleet")
		var origin: Vector2 = row.from
		var target: Vector2 = row.to
		var travel := origin.distance_to(target)
		var turn := absf(angle_difference(row.heading_from, row.heading_to))
		var seconds := elapsed_ms / 1000.0
		if travel > motion.max_speed_per_s * seconds or turn > deg_to_rad(motion.max_turn_deg_per_s * seconds) + 0.00001:
			return _fail("movement_limit")
		if travel > 0.00001 and turn > 0.00001:
			return _fail("turn_while_moving")
		if not _inside_world(origin, _radius(id)) or not _inside_world(target, _radius(id)):
			return _fail("world_boundary")
		if travel > 0.0 or turn > 0.00001:
			var mover_route: String = row.get("route_id", route)
			var mover_reverse: bool = row.get("reverse", reverse)
			var mover_leg: int = row.get("leg", leg)
			var mover_points := route_points(mover_route, mover_reverse)
			if (mover_leg < 0 or mover_leg + 1 >= mover_points.size()
					or (mover_reverse and not _state.withdrawal)):
				return _fail("invalid_movement_context")
			if (mover_route == "reinforcement" and _fleets[id].spawn != "R") or (mover_route != "reinforcement" and _fleets[id].side != 0):
				return _fail("wrong_route_fleet")
			var offset := _vector(_fleets[id].offset_xy)
			for endpoint: Array in [[origin, row.get("plan_from")], [target, row.get("plan_to")]]:
				var actual: Vector2 = endpoint[0]
				if not _finite_position(endpoint[1]) or actual.distance_to(endpoint[1] + offset) > space.center_tolerance:
					return _fail("tracking_budget")
				if actual.distance_to(_closest(mover_points[mover_leg], mover_points[mover_leg + 1], actual)) + _radius(id) > space.corridor_half_width:
					return _fail("corridor_clearance")
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			var a: Dictionary = moves[ids[i]]
			var b: Dictionary = moves[ids[j]]
			var gap_start: Vector2 = a.from - b.from
			var gap_end: Vector2 = a.to - b.to
			if _closest(gap_start, gap_end, Vector2.ZERO).length() < _radius(ids[i]) + _radius(ids[j]):
				return _fail("interfleet_clearance")
	return {"ok": true}


# frame is post-movement/combat and pre-policy. Only the owner advances time.
# A proposal is detached. Apply all effects to a private owner candidate, then
# commit the matching revision and publish. Discard on any owner-side failure.
func propose_tick(frame: Dictionary) -> Dictionary:
	if not _pending.is_empty():
		return _fail("proposal_pending")
	if not _state.settlement.is_empty():
		return _fail("operation_terminal")
	var error := _validate_frame(frame)
	if not error.is_empty():
		return _fail(error)
	var next := _state.duplicate(true)
	var elapsed: int = frame.clock_ms - next.clock_ms
	next.tick = frame.tick
	next.clock_ms = frame.clock_ms
	next.revision += 1
	var events: Array = []
	var effects: Array = []
	var command: String = frame.get("command", "")
	if command == "withdraw" and not next.withdrawal:
		next.withdrawal = true
		_emit(next, events, "withdrawal_started")
	var command_id: String = _definition.settlement.command_fleet_id
	for id: String in _fleets:
		var row: Dictionary = frame.fleets.get(id, {})
		if _fleets[id].side == 0 and not row.is_empty() and not next.exits.has(id):
			if not next.entries.has(id):
				next.entries[id] = row.entry_ship_count
			next.losses[id] = int(next.entries[id]) - int(row.present_ships)
	if not next.exits.has(command_id) and not frame.fleets[command_id].flagship_alive:
		_finish(next, events, "failure", "command_lost")
	else:
		for site: String in SITES:
			_update_site(next, frame.fleets, site, elapsed, events)
		if next.withdrawal:
			_record_exits(next, frame.fleets, events, effects)
		_evaluate(next, command, events)
		if next.settlement.is_empty():
			_supply(next, frame.fleets, elapsed, events, effects)
			_reinforce(next, frame.fleets, events, effects)
	_proposal_id += 1
	_pending = {"state": next, "proposal_id": _proposal_id}
	return {"ok": true, "revision": _proposal_id, "ledger": next.duplicate(true),
		"events": events.duplicate(true), "effects": effects.duplicate(true),
		"settlement": next.settlement.duplicate(true)}


func commit_tick(revision: int) -> Dictionary:
	if _pending.is_empty() or _pending.proposal_id != revision:
		return _fail("unknown_revision")
	_state = _pending.state
	_pending = {}
	return {"ok": true}


func discard_tick(revision: int) -> Dictionary:
	if _pending.is_empty() or _pending.proposal_id != revision:
		return _fail("unknown_revision")
	_pending = {}
	return {"ok": true}


# Proposal tokens never cross the owner boundary. Preserve the high-water
# mark after replay so tokens issued for discarded proposals are not reused.
func checkpoint_serial() -> int:
	return _proposal_id if _pending.is_empty() else -1

func restore_checkpoint_serial(value: int) -> bool:
	if not _pending.is_empty() or not _state.settlement.is_empty() or value < _proposal_id:
		return false
	_proposal_id = value
	return true


func ledger() -> Dictionary:
	return _state.duplicate(true)


func _validate_frame(frame: Dictionary) -> String:
	if (typeof(frame.get("tick")) != TYPE_INT or frame.tick != _state.tick + 1
			or typeof(frame.get("clock_ms")) != TYPE_INT or frame.clock_ms <= _state.clock_ms
			or frame.clock_ms - _state.clock_ms > _definition.space.motion.max_step_ms
			or not frame.get("fleets") is Dictionary):
		return "invalid_tick_frame"
	if frame.get("command", "") not in ["", "withdraw", "finalize_withdrawal"]:
		return "invalid_operation_command"
	if frame.get("command") == "finalize_withdrawal" and not _state.withdrawal:
		return "withdrawal_not_started"
	for id: Variant in frame.fleets:
		var row: Variant = frame.fleets[id]
		if (not _fleets.has(id) or not row is Dictionary or not _finite_position(row.get("position"))
				or typeof(row.get("stopped")) != TYPE_BOOL or typeof(row.get("combat_capable")) != TYPE_BOOL
				or typeof(row.get("flagship_alive")) != TYPE_BOOL or typeof(row.get("at_route_exit")) != TYPE_BOOL
				or typeof(row.get("present_ships")) != TYPE_INT or row.present_ships < 0
				or typeof(row.get("entry_ship_count")) != TYPE_INT or row.entry_ship_count < row.present_ships
				or row.entry_ship_count <= 0 or row.entry_ship_count > _fleets[id].ship_count
				or (_state.entries.has(id) and row.entry_ship_count != _state.entries[id])
				or not row.get("ammo") is Dictionary or not row.get("ammo_cap") is Dictionary
				or row.ammo.size() != row.ammo_cap.size()):
			return "invalid_fleet_frame"
		for category: Variant in row.ammo:
			if (typeof(row.ammo[category]) != TYPE_INT or row.ammo[category] < 0
					or typeof(row.ammo_cap.get(category)) != TYPE_INT or row.ammo_cap[category] < 0):
				return "invalid_ammo_frame"
		if _fleets[id].spawn == "R" and _state.reinforcement != "entered":
			return "reinforcement_not_entered"
	for id: String in _fleets:
		var required: bool = _fleets[id].spawn != "R" or _state.reinforcement == "entered"
		if required and not _state.exits.has(id) and not frame.fleets.has(id):
			return "missing_entered_fleet"
	return ""


func _update_site(next: Dictionary, fleets: Dictionary, site: String, elapsed: int, events: Array) -> void:
	var state: Dictionary = next.sites[site]
	var actor := ""
	var contested := false
	var defender: Dictionary = fleets.get(_definition.capture.objective_defender_id, {})
	for id: String in _fleets:
		var row: Dictionary = fleets.get(id, {})
		if row.is_empty() or row.present_ships == 0 or next.exits.has(id) or not _in_region(row.position, site):
			continue
		if _fleets[id].side == 1 and row.combat_capable:
			contested = true
		elif _fleets[id].side == 0 and row.stopped and row.combat_capable and (actor.is_empty() or id == state.actor):
			actor = id
	if site == "C" and defender.get("combat_capable", false):
		contested = true
	if contested:
		if state.active:
			state.active = false
			state.activation_ms = 0
			_emit(next, events, "facility_inactive", {"facility_id": site})
		return
	if actor.is_empty():
		return
	if actor != state.actor:
		state.actor = actor
		if state.control != "ally":
			state.capture_ms = 0
		if not state.active:
			state.activation_ms = 0
	if state.control != "ally":
		state.capture_ms += elapsed
		var need: int = _definition.capture.objective_capture_ms if site == "C" else _definition.capture.facility_capture_ms
		if state.capture_ms < need:
			return
		state.control = "ally"
		state.epoch += 1
		if site != "C":
			next.secured = true
		_emit(next, events, "site_captured", {"site_id": site, "ownership_epoch": state.epoch})
		return
	if site != "C" and not state.active:
		state.activation_ms += elapsed
		if state.activation_ms >= _definition.capture.facility_activate_ms:
			state.active = true
			state.active_since_ms = next.clock_ms
			_emit(next, events, "facility_active", {"facility_id": site})


func _supply(next: Dictionary, fleets: Dictionary, elapsed: int, events: Array, effects: Array) -> void:
	for site: String in ["A", "B"]:
		var facility: Dictionary = next.sites[site]
		var candidates: Array = []
		var old_work: Dictionary = facility.work
		facility.work = {}
		if not facility.active or facility.active_since_ms == next.clock_ms:
			continue
		var cost: int = _definition.supply.materials_per_refill
		for id: String in _fleets:
			var row: Dictionary = fleets.get(id, {})
			if (_fleets[id].side != 0 or row.is_empty() or row.present_ships == 0 or next.exits.has(id)
					or not row.stopped or not _in_region(row.position, site)):
				continue
			var amount := 0
			var total := 0
			var missing := 0
			var ammo: Dictionary = row.ammo.duplicate()
			for category: String in ammo:
				amount += mini(ammo[category], row.ammo_cap[category])
				total += int(row.ammo_cap[category])
				missing += maxi(0, row.ammo_cap[category] - ammo[category])
				ammo[category] = maxi(ammo[category], row.ammo_cap[category])
			if missing > 0 and facility.stock.ammo >= missing and facility.stock.materials >= cost:
				candidates.append({"id": id, "missing": missing, "ammo": ammo,
					"ratio": float(amount) / total, "since": row.get("stopped_since_ms", next.clock_ms)})
		candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			if old_work.has(a.id) != old_work.has(b.id):
				return old_work.has(a.id)
			if a.ratio != b.ratio:
				return a.ratio < b.ratio
			if a.since != b.since:
				return a.since < b.since
			return a.id < b.id)
		for i in mini(candidates.size(), _definition.supply.slots_per_facility):
			var item: Dictionary = candidates[i]
			var progress: int = old_work.get(item.id, 0) + elapsed
			if progress < _definition.supply.stationary_ms:
				facility.work[item.id] = progress
				continue
			if facility.stock.ammo < item.missing or facility.stock.materials < cost:
				continue
			facility.stock.ammo -= item.missing
			facility.stock.materials -= cost
			var fact := {"facility_id": site, "ownership_epoch": facility.epoch, "fleet_id": item.id,
				"cycle_id": next.revision, "ammo": item.missing, "materials": cost}
			next.transactions.append(fact)
			var event_id := _emit(next, events, "supply_completed", fact)
			effects.append({"kind": "set_ammo", "id": event_id, "fleet_id": item.id, "ammo": item.ammo})


func _reinforce(next: Dictionary, fleets: Dictionary, events: Array, effects: Array) -> void:
	var rule: Dictionary = _definition.reinforcement
	if next.reinforcement == "entered" or next.clock_ms <= rule.scheduled_ms:
		return
	var pos := _node("R")
	var radius := _radius(rule.fleet_id)
	var blocked: bool = not _inside_world(pos, radius) or radius > _definition.space.regions.R.deployment_radius
	for id: String in fleets:
		if fleets[id].present_ships > 0 and not next.exits.has(id) and pos.distance_to(fleets[id].position) < radius + _radius(id):
			blocked = true
	if blocked:
		if next.reinforcement != "waiting":
			next.reinforcement = "waiting"
			_emit(next, events, "reinforcement_waiting", {"schedule_id": rule.id})
		return
	next.reinforcement = "entered"
	var event_id := _emit(next, events, "reinforcement_entered", {"schedule_id": rule.id, "fleet_id": rule.fleet_id})
	effects.append({"kind": "spawn_reinforcement", "id": event_id, "fleet": _fleets[rule.fleet_id].duplicate(true),
		"position": pos, "route_id": rule.route_id})


func _record_exits(next: Dictionary, fleets: Dictionary, events: Array, effects: Array) -> void:
	if next.clock_ms > _definition.settlement.deadline_ms:
		return
	for id: String in next.entries:
		var row: Dictionary = fleets.get(id, {})
		if (not next.exits.has(id) and not row.is_empty() and row.present_ships > 0 and row.stopped
				and row.at_route_exit and row.position.distance_to(_node("E")) <= _definition.space.regions.E.exit_radius):
			next.exits[id] = row.present_ships
			var event_id := _emit(next, events, "fleet_exited", {"fleet_id": id, "cost": row.present_ships})
			effects.append({"kind": "remove_exited_fleet", "id": event_id, "fleet_id": id})


func _evaluate(next: Dictionary, command: String, events: Array) -> void:
	var rule: Dictionary = _definition.settlement
	var deadline: bool = next.clock_ms >= rule.deadline_ms
	if next.withdrawal:
		if deadline or command == "finalize_withdrawal":
			var d := _cost(next.entries)
			var n := _cost(next.exits)
			if not next.secured:
				_finish(next, events, "failure", "facility_never_secured")
			elif not next.exits.has(rule.command_fleet_id):
				_finish(next, events, "failure", "command_not_exited")
			elif d == 0 or n * 10000 < d * rule.withdrawal_min_survival_bp:
				_finish(next, events, "failure", "insufficient_survival")
			else:
				_finish(next, events, "withdrawal_success", "withdrawal_conditions_met")
	elif (next.clock_ms <= rule.deadline_ms and next.sites.C.control == "ally"
			and (next.sites.A.active or next.sites.B.active)):
		_finish(next, events, "objective_success", "objective_conditions_met")
	elif deadline:
		_finish(next, events, "failure", "deadline")


func _finish(next: Dictionary, events: Array, kind: String, reason: String) -> void:
	next.settlement = {"id": _operation_id + "/settlement", "kind": kind, "reason": reason,
		"operation_id": _operation_id, "tick": next.tick, "clock_ms": next.clock_ms,
		"entry_cost": _cost(next.entries), "surviving_cost": _cost(next.exits),
		"facility_secured": next.secured, "active_facilities": [],
		"losses": next.losses.duplicate(), "command_exited": next.exits.has(_definition.settlement.command_fleet_id),
		"command_lost": reason == "command_lost"}
	for site: String in ["A", "B"]:
		if next.sites[site].active:
			next.settlement.active_facilities.append(site)
	_emit(next, events, "operation_settled", next.settlement)


func _emit(next: Dictionary, events: Array, kind: String, fact := {}) -> String:
	next.event_seq += 1
	var id := "%s/%d" % [_operation_id, next.event_seq]
	events.append({"id": id, "kind": kind, "tick": next.tick, "clock_ms": next.clock_ms,
		"operation_id": _operation_id, "fact": fact.duplicate(true)})
	return id


func _node(id: String) -> Vector2:
	return _vector(_definition.space.nodes[id])


func _radius(id: String) -> float:
	return float(_fleets[id].outer_radius) + float(_definition.space.safety_margin)


func _inside_world(position: Vector2, radius: float) -> bool:
	var inset := maxf(radius, _definition.space.center_inset)
	var size := _vector(_definition.space.size)
	return position.x >= inset and position.y >= inset and position.x <= size.x - inset and position.y <= size.y - inset


func _in_region(position: Vector2, site: String) -> bool:
	var field: String = _definition.capture.region_radius_fields[site]
	return position.distance_to(_node(site)) <= _definition.space.regions[site][field]


static func _closest(a: Vector2, b: Vector2, point: Vector2) -> Vector2:
	return a if a == b else Geometry2D.get_closest_point_to_segment(point, a, b)


static func _vector(values: Array) -> Vector2:
	return Vector2(values[0], values[1])


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


static func _finite_position(value: Variant) -> bool:
	return value is Vector2 and value.is_finite()


static func _cost(values: Dictionary) -> int:
	var total := 0
	for value: int in values.values():
		total += value
	return total


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "path": "first_operation_policy"}

