extends RefCounted

const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const ID_PREFIX := "lantern-escort-v1/"
const WORLD_SIZE := Vector2(1700, 1150)
const LIMIT := 1200
const TICK_MS := 100
const MAX_ORDERS := 8
const SEED := 20825
const ROUTE := [Vector2(600, 575), Vector2(1000, 635), Vector2(1480, 635)]
const LEAD_ID := "transport-1"
const REAR_ID := "transport-2"
const ESCORT_ID := "escort"
const EXIT_RADIUS := 24.0
const TRANSPORT_SPEED := 13.0
const TRANSPORT_HP := 45
const ESCORT_SPEED := 115.0
const ESCORT_HP := 180
const ESCORT_RANGE := 160.0
const ESCORT_DAMAGE := 18
const ESCORT_AMMO := 24
const PURSUER_SPEED := 42.0
const PURSUER_HP := 60
const PURSUER_RANGE := 130.0
const PURSUER_DAMAGE := 9
const PURSUER_AMMO := 24
const FIRE_INTERVAL := 10
const PACKET_FIELDS := ["operation_id", "tick", "started", "settlement", "pending", "applied", "event_cursor", "witness"]

var operation_id: String
var tick := 0
var started := false
var settlement: Dictionary = {}
var _ships: Array[Dictionary] = []
var _pending: Array[Dictionary] = []
var _applied: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _event_cursor := 0
var _escaped: Array[String] = []
var _escort_target: Variant = null


static func definition() -> Dictionary:
	return {
		"version": 1, "seed": SEED, "mode": "direct", "difficulty": "standard",
		"world_size": WORLD_SIZE, "tick_ms": TICK_MS, "limit_ticks": LIMIT,
		"exit_radius": EXIT_RADIUS, "waypoints": ROUTE.duplicate(), "fire_interval_ticks": FIRE_INTERVAL,
		"transport": {"speed": TRANSPORT_SPEED, "hp": TRANSPORT_HP,
			"starts": {LEAD_ID: Vector2(220, 575), REAR_ID: Vector2(100, 575)}},
		"escort": {"speed": ESCORT_SPEED, "hp": ESCORT_HP, "range": ESCORT_RANGE, "damage": ESCORT_DAMAGE,
			"ammo": ESCORT_AMMO, "start": Vector2(250, 690), "ship_types": {"SHP-03": 6, "SHP-04": 12}},
		"pursuer": {"speed": PURSUER_SPEED, "hp": PURSUER_HP, "range": PURSUER_RANGE, "damage": PURSUER_DAMAGE,
			"ammo": PURSUER_AMMO, "ship_types": {"SHP-03": 3, "SHP-04": 6}, "waves": [
				{"tick": 180, "position": Vector2(820, 200), "target": LEAD_ID},
				{"tick": 500, "position": Vector2(1360, 930), "target": REAR_ID}]},
	}


static func create(id: String) -> RefCounted:
	if not _valid_id(id):
		return null
	var runtime := new()
	runtime.operation_id = id
	var config := definition()
	for transport_id in [LEAD_ID, REAR_ID]:
		var ship := _ship(transport_id, "transport", config.transport.starts[transport_id], TRANSPORT_HP, 1)
		ship.waypoint = 0
		runtime._ships.append(ship)
	var escort := _ship(ESCORT_ID, "escort", config.escort.start, ESCORT_HP, 18)
	escort.ammo = ESCORT_AMMO
	runtime._ships.append(escort)
	for i in config.pursuer.waves.size():
		var wave: Dictionary = config.pursuer.waves[i]
		var pursuer := _ship("pursuer-%d" % [i + 1], "pursuer", wave.position, PURSUER_HP, 9)
		pursuer.status = "waiting"
		pursuer.appears = wave.tick
		pursuer.target = wave.target
		pursuer.ammo = PURSUER_AMMO
		runtime._ships.append(pursuer)
	return runtime


static func _ship(id: String, team: String, position: Vector2, hp: int, ships: int) -> Dictionary:
	return {"id": id, "team": team, "position": position, "hp": hp,
		"max_hp": hp, "status": "active", "ships": ships}


func begin() -> bool:
	if started or not settlement.is_empty():
		return false
	started = true
	return true


func queue(kind: String, point := Vector2.ZERO) -> bool:
	var command := {"kind": kind}
	if kind == "move":
		if not point.is_finite() or point.x < 0 or point.y < 0 or point.x > WORLD_SIZE.x or point.y > WORLD_SIZE.y:
			return false
		command.x = roundi(point.x)
		command.y = roundi(point.y)
	return _queue(command)


func _queue(command: Dictionary) -> bool:
	if not started or not settlement.is_empty() or _pending.size() >= MAX_ORDERS or not _valid_command(command):
		return false
	if not _pending.is_empty() and _pending.back().kind == "abandon":
		return false
	if command.kind != "abandon" and _ships[2].status != "active":
		return false
	_pending.append(command.duplicate())
	return true


func advance() -> void:
	if not started or not settlement.is_empty():
		return
	tick += 1
	if not _pending.is_empty():
		var batch := _pending
		_pending = []
		_applied.append({"tick": tick - 1, "batch": batch})
		for command in batch:
			match command.kind:
				"move":
					_escort_target = Vector2(command.x, command.y)
				"stop":
					_escort_target = null
				"abandon":
					_settle("failure", "abandoned")
					return
	_activate_pursuers()
	_move_fleets()
	if tick % FIRE_INTERVAL == 0:
		_resolve_combat()
	_record_exits()


func _activate_pursuers() -> void:
	for ship in _ships:
		if ship.status == "waiting" and ship.appears == tick:
			ship.status = "active"
			_emit("pursuer_spawned", ship.id, {"target": ship.target})


func _move_fleets() -> void:
	for ship in _ships:
		if ship.status != "active":
			continue
		match ship.team:
			"transport":
				var target: Vector2 = ROUTE[ship.waypoint]
				ship.position = ship.position.move_toward(target, TRANSPORT_SPEED / 10.0)
				if ship.position == target and ship.waypoint < ROUTE.size() - 1:
					ship.waypoint += 1
			"escort":
				if _escort_target != null:
					ship.position = ship.position.move_toward(_escort_target, ESCORT_SPEED / 10.0)
					if ship.position == _escort_target:
						_escort_target = null
			"pursuer":
				var target := _pursuer_target(ship)
				if not target.is_empty() and _distance(ship, target) > PURSUER_RANGE:
					ship.position = ship.position.move_toward(target.position, PURSUER_SPEED / 10.0)


func _resolve_combat() -> void:
	# All active shooters choose targets before damage is applied.
	var hits := {}
	for ship in _ships:
		if ship.team == "transport" or ship.status != "active" or ship.ammo == 0:
			continue
		var target: Dictionary
		var damage: int
		if ship.team == "escort":
			target = _escort_target_ship(ship)
			damage = ESCORT_DAMAGE
		else:
			target = _pursuer_target(ship)
			if not target.is_empty() and _distance(ship, target) > PURSUER_RANGE:
				continue
			damage = PURSUER_DAMAGE
		if target.is_empty():
			continue
		ship.ammo -= 1
		hits[target.id] = int(hits.get(target.id, 0)) + damage
	for ship in _ships:
		if not hits.has(ship.id):
			continue
		ship.hp = maxi(0, ship.hp - hits[ship.id])
		if ship.hp == 0:
			ship.status = "destroyed"
			_emit("%s_destroyed" % ship.team, ship.id, {})


func _escort_target_ship(escort: Dictionary) -> Dictionary:
	var target := {}
	var best_distance := ESCORT_RANGE
	for ship in _ships:
		if ship.team != "pursuer" or ship.status != "active":
			continue
		var distance := _distance(escort, ship)
		if distance <= best_distance and (target.is_empty() or distance < best_distance):
			target = ship
			best_distance = distance
	return target


func _pursuer_target(ship: Dictionary) -> Dictionary:
	var escort := _ships[2]
	if escort.status == "active" and _distance(ship, escort) <= PURSUER_RANGE:
		return escort
	var transport := _ships[0] if ship.target == LEAD_ID else _ships[1]
	return transport if transport.status == "active" else {}


func _record_exits() -> void:
	var exit: Vector2 = ROUTE.back()
	for ship in _ships.slice(0, 2):
		if ship.status == "active" and ship.waypoint == ROUTE.size() - 1 \
				and ship.position.distance_to(exit) <= EXIT_RADIUS:
			ship.status = "escaped"
			_escaped.append(ship.id)
			_emit("transport_escaped", ship.id, {})
	if _escaped.size() == 2:
		_settle("success", "both_escaped")
	else:
		var neither_active: bool = _ships[0].status != "active" and _ships[1].status != "active"
		if not neither_active and tick < LIMIT:
			return
		if _escaped.size() == 1:
			_settle("success", "one_escaped")
		else:
			_settle("failure", "transports_destroyed" if neither_active else "deadline")


func _emit(kind: String, ship_id: String, details: Dictionary) -> void:
	var event := {"tick": tick, "kind": kind, "ship_id": ship_id}
	event.merge(details)
	_events.append(event)


func drain_events() -> Array:
	var unread := _events.slice(_event_cursor).duplicate(true)
	_event_cursor = _events.size()
	return unread


func _settle(kind: String, reason: String) -> void:
	settlement = {"id": operation_id + "/settlement", "operation_id": operation_id, "kind": kind, "reason": reason,
		"escaped": _escaped.size(), "escaped_ids": _escaped.duplicate(), "tick": tick,
		"clock_ms": tick * TICK_MS, "seed": SEED, "mode": "direct", "difficulty": "standard"}
	_emit("operation_settled", "", {"result": kind, "reason": reason, "escaped": _escaped.size()})


func projection() -> Dictionary:
	var ships: Array[Dictionary] = []
	for ship in _ships:
		ships.append({"id": ship.id, "team": ship.team, "position": ship.position, "hp": ship.hp,
			"max_hp": ship.max_hp, "status": ship.status, "ships": ship.ships})
	return {"operation_id": operation_id, "tick": tick, "clock_ms": tick * TICK_MS, "started": started,
		"settlement": settlement.duplicate(true), "escaped": _escaped.size(), "events": _events.duplicate(true),
		"event_cursor": _event_cursor, "ships": ships, "waypoints": ROUTE.duplicate()}


func capture() -> Dictionary:
	return {"operation_id": operation_id, "tick": tick, "started": started, "settlement": settlement.duplicate(true),
		"pending": _pending.duplicate(true), "applied": _applied.duplicate(true), "event_cursor": _event_cursor,
		"witness": Checkpoint.digest_value([definition(), operation_id, tick, started, settlement, _pending, _applied,
			_ships, _events, _event_cursor, _escaped, _escort_target])}


static func restore(packet: Variant) -> Dictionary:
	if not _has_fields(packet, PACKET_FIELDS) or not _valid_id(packet.operation_id) \
			or not _is_int(packet.tick, 0, LIMIT) or not packet.started is bool or not packet.settlement is Dictionary \
			or not packet.applied is Array or packet.applied.size() > packet.tick \
			or not packet.pending is Array or packet.pending.size() > MAX_ORDERS \
			or not _is_int(packet.event_cursor, 0, LIMIT) or not _hex(packet.witness, 64):
		return _fail("lantern_invalid_packet")
	if not packet.started and (packet.tick != 0 or not packet.pending.is_empty()):
		return _fail("lantern_invalid_frontier")
	var runtime := create(packet.operation_id)
	if packet.started:
		runtime.begin()
	var last_tick := -1
	for entry in packet.applied:
		if not _has_fields(entry, ["tick", "batch"]) or not _is_int(entry.tick, last_tick + 1, packet.tick - 1) \
				or not entry.batch is Array or entry.batch.is_empty() or entry.batch.size() > MAX_ORDERS:
			return _fail("lantern_invalid_history")
		if not _advance_to(runtime, entry.tick) or not _queue_batch(runtime, entry.batch):
			return _fail("lantern_invalid_history")
		last_tick = entry.tick
	if not _advance_to(runtime, packet.tick) or not _queue_batch(runtime, packet.pending):
		return _fail("lantern_invalid_frontier")
	if packet.event_cursor > runtime._events.size():
		return _fail("lantern_invalid_event_cursor")
	runtime._event_cursor = packet.event_cursor
	var restored: Dictionary = runtime.capture()
	if restored.witness != packet.witness or not _same_settlement(packet.settlement, restored.settlement):
		return _fail("lantern_witness_mismatch")
	return {"ok": true, "runtime": runtime}


static func _same_settlement(input: Dictionary, generated: Dictionary) -> bool:
	if not _has_fields(input, generated.keys()):
		return false
	for key in generated:
		if typeof(input[key]) != typeof(generated[key]) or input[key] != generated[key]:
			return false
	if not input.is_empty():
		for id in input.escaped_ids:
			if not id is String:
				return false
	return true


static func _advance_to(runtime: RefCounted, frontier: int) -> bool:
	while runtime.tick < frontier and runtime.settlement.is_empty():
		runtime.advance()
	return runtime.tick == frontier


static func _queue_batch(runtime: RefCounted, batch: Array) -> bool:
	for command in batch:
		if not command is Dictionary or not runtime._queue(command):
			return false
	return true


static func _valid_command(command: Dictionary) -> bool:
	match command.get("kind", ""):
		"move":
			return _has_fields(command, ["kind", "x", "y"]) and _is_int(command.x, 0, int(WORLD_SIZE.x)) \
				and _is_int(command.y, 0, int(WORLD_SIZE.y))
		"stop", "abandon":
			return _has_fields(command, ["kind"])
	return false


static func _distance(a: Dictionary, b: Dictionary) -> float:
	return a.position.distance_to(b.position)


static func _is_int(value: Variant, lo: int, hi: int) -> bool:
	return value is int and value >= lo and value <= hi


static func _valid_id(id: Variant) -> bool:
	return id is String and id.begins_with(ID_PREFIX) and _hex(id.trim_prefix(ID_PREFIX), 32)


static func _hex(value: Variant, size: int) -> bool:
	if not value is String or value.length() != size:
		return false
	for character in value:
		if not character in "0123456789abcdef":
			return false
	return true


static func _has_fields(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}
