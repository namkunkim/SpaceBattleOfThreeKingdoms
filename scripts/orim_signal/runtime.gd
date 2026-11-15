extends RefCounted

const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const ID_PREFIX := "orim-signal-v1/"
const WORLD_SIZE := Vector2(1700, 1150)
const LIMIT := 1200
const TICK_MS := 100
const MAX_ORDERS := 8
const SEED := 20826
const COMMAND_ID := "gan-ning"
const SUPPORT_ID := "lu-su"
const ADVANCE_ID := "wei-advance"
const RESERVE_ID := "wei-reserve"
const STATION := Vector2(850, 570)
const STATION_RADIUS := 90.0
const REPAIR_POINT := Vector2(420, 810)
const REPAIR_RADIUS := 70.0
const CAPTURE_TICKS := 100
const TRANSMISSION_TICKS := 150
const REPAIR_TICKS := 150
const SHIP_HP := 30
const REPAIR_HP := 6
const FIRE_INTERVAL := 10
const ALLY_SPEED := 100.0
const ENEMY_SPEED := 45.0
const ALLY_RANGE := 180.0
const ENEMY_RANGE := 140.0
const PACKET_FIELDS := ["operation_id", "tick", "started", "settlement", "pending", "applied", "event_cursor", "witness"]
const FLEETS := [
	{"id": COMMAND_ID, "side": "ally", "position": Vector2(300, 570), "tick": 0,
		"composition": {"SHP-03": 6, "SHP-04": 12}, "route": []},
	{"id": SUPPORT_ID, "side": "ally", "position": Vector2(260, 770), "tick": 0,
		"composition": {"SHP-03": 4, "SHP-04": 8}, "route": []},
	{"id": ADVANCE_ID, "side": "enemy", "position": Vector2(1300, 570), "tick": 0,
		"composition": {"SHP-03": 3, "SHP-04": 6}, "route": [Vector2(1170, 350), Vector2(1030, 450), Vector2(878, 570)]},
	{"id": RESERVE_ID, "side": "enemy", "position": Vector2(1500, 850), "tick": 500,
		"composition": {"SHP-03": 4, "SHP-04": 8}, "route": [Vector2(1240, 800), Vector2(1050, 675), Vector2(878, 600)]},
]

var operation_id: String
var tick := 0
var started := false
var settlement: Dictionary = {}
var _fleets: Dictionary = {}
var _owner := "neutral"
var _capture := {"fleet": "", "ticks": 0}
var _transmission := {"fleet": "", "ticks": 0}
var _repair := {"fleet": "", "ticks": 0}
var _repair_used := false
var _pending: Array[Dictionary] = []
var _applied: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _event_cursor := 0


static func definition() -> Dictionary:
	return {"version": 1, "seed": SEED, "mode": "direct", "difficulty": "standard",
		"world_size": WORLD_SIZE, "tick_ms": TICK_MS, "limit_ticks": LIMIT, "fleets": FLEETS.duplicate(true),
		"station": STATION, "station_radius": STATION_RADIUS, "capture_ticks": CAPTURE_TICKS,
		"transmission_ticks": TRANSMISSION_TICKS, "repair_point": REPAIR_POINT, "repair_radius": REPAIR_RADIUS,
		"repair_ticks": REPAIR_TICKS, "repair_hp": REPAIR_HP, "ship_hp": SHIP_HP, "fire_interval": FIRE_INTERVAL,
		"ally_speed": ALLY_SPEED, "enemy_speed": ENEMY_SPEED, "ally_range": ALLY_RANGE, "enemy_range": ENEMY_RANGE}


static func create(id: String) -> RefCounted:
	if not _valid_id(id):
		return null
	var runtime := new()
	runtime.operation_id = id
	for definition_row in FLEETS:
		var health: Array[int] = []
		# Fix ship order to SHP-03 then SHP-04, in roster order within a type.
		health.resize(definition_row.composition["SHP-03"] + definition_row.composition["SHP-04"])
		health.fill(SHIP_HP)
		var fleet: Dictionary = {"id": definition_row.id, "side": definition_row.side,
			"position": definition_row.position, "spawn_tick": definition_row.tick, "route": definition_row.route.duplicate(),
			"route_index": 0, "target": null, "health": health, "state": "waiting"}
		if definition_row.tick == 0:
			fleet.state = "stopped"
			if not fleet.route.is_empty():
				fleet.state = "moving"
				fleet.target = fleet.route.front()
		runtime._fleets[fleet.id] = fleet
	return runtime


func begin() -> bool:
	if started or not settlement.is_empty():
		return false
	started = true
	return true


func queue(kind: String, unit_id := "", point := Vector2.ZERO) -> bool:
	var command := {"kind": kind}
	if kind != "abandon":
		command.unit_id = unit_id
	elif not unit_id.is_empty():
		return false
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
	if command.kind != "abandon" and _fleets[command.unit_id].state == "destroyed":
		return false
	_pending.append(_canonical_command(command))
	return true


func advance() -> void:
	if not started or not settlement.is_empty():
		return
	tick += 1
	if not _pending.is_empty():
		var batch := _pending
		_pending = []
		_applied.append({"tick": tick - 1, "batch": batch})
		if batch.back().kind == "abandon":
			_settle("failure", "abandoned")
			return
		for command in batch:
			var fleet: Dictionary = _fleets[command.unit_id]
			if command.kind == "move":
				fleet.target = Vector2(command.x, command.y)
				fleet.state = "moving"
			else:
				fleet.target = null
				fleet.state = "stopped"
	_move_fleets()
	if tick % FIRE_INTERVAL == 0:
		_resolve_combat()
	var station := _presence(STATION, STATION_RADIUS)
	var changed := _update_capture(station)
	if not _repair_used:
		_update_repair(_presence(REPAIR_POINT, REPAIR_RADIUS))
	var sent := _update_transmission(station, changed)
	if _fleets[COMMAND_ID].state == "destroyed":
		_settle("failure", "command_destroyed")
	elif sent:
		_settle("success", "signal_sent")
	elif tick == LIMIT:
		_settle("failure", "deadline")


func _move_fleets() -> void:
	for fleet: Dictionary in _fleets.values():
		if fleet.state == "waiting" and fleet.spawn_tick == tick:
			fleet.state = "moving"
			fleet.target = fleet.route.front()
			_emit("reserve_arrived", fleet.id, {})
			continue
		if fleet.state != "moving":
			continue
		var speed := ALLY_SPEED if fleet.side == "ally" else ENEMY_SPEED
		fleet.position = fleet.position.move_toward(fleet.target, speed * TICK_MS / 1000.0)
		if fleet.position != fleet.target:
			continue
		if fleet.side == "enemy" and fleet.route_index + 1 < fleet.route.size():
			fleet.route_index += 1
			fleet.target = fleet.route[fleet.route_index]
		else:
			fleet.target = null
			fleet.state = "stopped"


func _resolve_combat() -> void:
	# Snapshot targets and ship counts before mutating any roster.
	var damage := {}
	for fleet: Dictionary in _fleets.values():
		if not _active(fleet):
			continue
		var target := _target(fleet)
		if not target.is_empty():
			damage[target] = int(damage.get(target, 0)) + _alive(fleet)
	for fleet: Dictionary in _fleets.values():
		var hits := int(damage.get(fleet.id, 0))
		if hits == 0:
			continue
		for i in fleet.health.size():
			var applied := mini(hits, fleet.health[i])
			fleet.health[i] -= applied
			hits -= applied
			if hits == 0:
				break
		if _alive(fleet) == 0:
			fleet.state = "destroyed"
			fleet.target = null
			_emit("fleet_destroyed", fleet.id, {})


func _target(shooter: Dictionary) -> String:
	var best := ""
	var reach := ALLY_RANGE if shooter.side == "ally" else ENEMY_RANGE
	var best_distance := reach * reach
	for candidate: Dictionary in _fleets.values():
		if candidate.side == shooter.side or not _active(candidate):
			continue
		var distance: float = shooter.position.distance_squared_to(candidate.position)
		if distance <= best_distance and (best.is_empty() or distance < best_distance or candidate.id < best):
			best = candidate.id
			best_distance = distance
	return best


func _presence(center: Vector2, radius: float) -> Dictionary:
	var presence := {"ally": [], "enemy": [], "ally_stopped": [], "enemy_stopped": []}
	for fleet: Dictionary in _fleets.values():
		if not _active(fleet) or fleet.position.distance_squared_to(center) > radius * radius:
			continue
		presence[fleet.side].append(fleet.id)
		if fleet.state == "stopped":
			presence[fleet.side + "_stopped"].append(fleet.id)
	return presence


func _update_capture(presence: Dictionary) -> bool:
	var side := ""
	if not presence.ally_stopped.is_empty() and presence.enemy.is_empty():
		side = "ally"
	elif not presence.enemy_stopped.is_empty() and presence.ally.is_empty():
		side = "enemy"
	if side.is_empty() or side == _owner:
		_update_progress(_capture, [])
		return false
	var progress := _update_progress(_capture, presence[side + "_stopped"])
	if progress < CAPTURE_TICKS:
		return false
	var previous := _owner
	_owner = side
	_emit("station_captured", _capture.fleet, {"owner": side, "previous": previous})
	_update_progress(_capture, [])
	return true


func _update_repair(presence: Dictionary) -> void:
	var eligible: Array = [] if not presence.enemy.is_empty() else presence.ally_stopped
	if _update_progress(_repair, eligible) < REPAIR_TICKS:
		return
	var fleet: Dictionary = _fleets[_repair.fleet]
	var healed := 0
	for i in fleet.health.size():
		var hp: int = fleet.health[i]
		if hp > 0:
			fleet.health[i] = mini(SHIP_HP, hp + REPAIR_HP)
			healed += fleet.health[i] - hp
	_repair_used = true
	_emit("repair_completed", fleet.id, {"hp": healed})


func _update_transmission(presence: Dictionary, ownership_changed: bool) -> bool:
	var eligible: Array = []
	if not ownership_changed and _owner == "ally" and presence.enemy.is_empty():
		eligible = presence.ally_stopped
	if _update_progress(_transmission, eligible) < TRANSMISSION_TICKS:
		return false
	if _fleets[COMMAND_ID].state == "destroyed":
		return false
	_emit("transmission_completed", _transmission.fleet, {})
	return true


func _update_progress(progress: Dictionary, eligible: Array) -> int:
	if eligible.is_empty():
		progress.fleet = ""
		progress.ticks = 0
	elif progress.fleet in eligible:
		progress.ticks += 1
	else:
		# A replacement starts accruing on the next tick, never on the swap tick.
		progress.ticks = 1 if progress.fleet.is_empty() else 0
		var sorted := eligible.duplicate()
		sorted.sort()
		progress.fleet = sorted.front()
	return progress.ticks


static func _active(fleet: Dictionary) -> bool:
	return fleet.state == "moving" or fleet.state == "stopped"


static func _alive(fleet: Dictionary) -> int:
	var result := 0
	for hp: int in fleet.health:
		if hp > 0:
			result += 1
	return result


func _settle(kind: String, reason: String) -> void:
	settlement = {"id": operation_id + "/settlement", "operation_id": operation_id, "kind": kind, "reason": reason,
		"tick": tick, "clock_ms": tick * TICK_MS, "seed": SEED, "mode": "direct", "difficulty": "standard"}
	_emit("operation_settled", "", {"result": kind, "reason": reason})


func _emit(kind: String, unit_id: String, details: Dictionary) -> void:
	var event := {"tick": tick, "kind": kind, "unit_id": unit_id}
	event.merge(details)
	_events.append(event)


func drain_events() -> Array:
	var unread := _events.slice(_event_cursor).duplicate(true)
	_event_cursor = _events.size()
	return unread


func projection() -> Dictionary:
	var fleets: Array[Dictionary] = []
	for fleet: Dictionary in _fleets.values():
		var hp := 0
		for remaining: int in fleet.health:
			hp += remaining
		fleets.append({"id": fleet.id, "side": fleet.side, "position": fleet.position, "alive": _alive(fleet),
			"hp": hp, "max_hp": fleet.health.size() * SHIP_HP, "state": fleet.state})
	return {"operation_id": operation_id, "tick": tick, "clock_ms": tick * TICK_MS, "started": started,
		"settlement": settlement.duplicate(true), "owner": _owner, "capture": _capture.ticks,
		"capture_fleet": _capture.fleet, "transmission": _transmission.ticks, "transmission_fleet": _transmission.fleet,
		"repair": _repair.ticks, "repair_fleet": _repair.fleet, "repair_used": _repair_used,
		"events": _events.duplicate(true), "event_cursor": _event_cursor, "fleets": fleets,
		"station": STATION, "station_radius": STATION_RADIUS, "repair_point": REPAIR_POINT, "repair_radius": REPAIR_RADIUS}


func capture() -> Dictionary:
	return {"operation_id": operation_id, "tick": tick, "started": started, "settlement": settlement.duplicate(true),
		"pending": _pending.duplicate(true), "applied": _applied.duplicate(true), "event_cursor": _event_cursor,
		"witness": Checkpoint.digest_value([definition(), operation_id, tick, started, settlement,
			_pending, _applied, _event_cursor, _events, _fleets, _owner, _capture, _transmission, _repair, _repair_used])}


static func restore(packet: Variant) -> Dictionary:
	if not _has_fields(packet, PACKET_FIELDS) or not _valid_id(packet.operation_id) \
			or not _is_int(packet.tick, 0, LIMIT) or not packet.started is bool or not packet.settlement is Dictionary \
			or not packet.applied is Array or packet.applied.size() > packet.tick \
			or not packet.pending is Array or packet.pending.size() > MAX_ORDERS \
			or not _is_int(packet.event_cursor, 0, LIMIT) or not _hex(packet.witness, 64):
		return _fail("orim_invalid_packet")
	if not packet.started and (packet.tick != 0 or not packet.pending.is_empty()):
		return _fail("orim_invalid_frontier")
	var runtime := create(packet.operation_id)
	if packet.started:
		runtime.begin()
	var last_tick := -1
	for entry in packet.applied:
		if not _has_fields(entry, ["tick", "batch"]) or not _is_int(entry.tick, last_tick + 1, packet.tick - 1) \
				or not entry.batch is Array or entry.batch.is_empty() or entry.batch.size() > MAX_ORDERS:
			return _fail("orim_invalid_history")
		if not _advance_to(runtime, entry.tick) or not _queue_batch(runtime, entry.batch):
			return _fail("orim_invalid_history")
		last_tick = entry.tick
	if not _advance_to(runtime, packet.tick) or not _queue_batch(runtime, packet.pending):
		return _fail("orim_invalid_frontier")
	if packet.event_cursor > runtime._events.size():
		return _fail("orim_invalid_event_cursor")
	runtime._event_cursor = packet.event_cursor
	var restored: Dictionary = runtime.capture()
	if restored.witness != packet.witness or not _same_settlement(packet.settlement, restored.settlement):
		return _fail("orim_witness_mismatch")
	return {"ok": true, "runtime": runtime}


static func _same_settlement(input: Dictionary, generated: Dictionary) -> bool:
	if not _has_fields(input, generated.keys()):
		return false
	for key in generated:
		if typeof(input[key]) != typeof(generated[key]) or input[key] != generated[key]:
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


static func _canonical_command(command: Dictionary) -> Dictionary:
	var canonical := {"kind": command.kind}
	if command.kind != "abandon":
		canonical.unit_id = command.unit_id
	if command.kind == "move":
		canonical.x = command.x
		canonical.y = command.y
	return canonical


static func _valid_command(command: Dictionary) -> bool:
	var kind: Variant = command.get("kind")
	var unit_id: Variant = command.get("unit_id")
	if not kind is String:
		return false
	if kind == "abandon":
		return _has_fields(command, ["kind"])
	if not unit_id is String or unit_id not in [COMMAND_ID, SUPPORT_ID]:
		return false
	if kind == "stop":
		return _has_fields(command, ["kind", "unit_id"])
	return kind == "move" and _has_fields(command, ["kind", "unit_id", "x", "y"]) \
		and _is_int(command.x, 0, int(WORLD_SIZE.x)) and _is_int(command.y, 0, int(WORLD_SIZE.y))


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
