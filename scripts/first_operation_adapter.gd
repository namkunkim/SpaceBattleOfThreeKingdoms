extends RefCounted

const Dev := preload("res://core/battle/first_operation_dev.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

const FORMAT := "pc-first-operation-run/1"
const MAX_TICKS := 12000
const MAX_COMMANDS := 16384
const MAX_BATCH := 256
const SETTLEMENT_FIELDS := ["id", "operation_id", "kind", "reason", "tick", "clock_ms"]
const REQUEST_FIELDS := ["capability", "definition_id", "definition_version", "roster_id",
	"seed", "difficulty", "mode", "route_id"]

# Product replay owns a private live simulation. Consumers receive only
# detached side-0 frames; the interface has no command or publication API.
class ReplaySession extends RefCounted:
	var _owner: RefCounted
	var _bundle: Dictionary
	var _projection: Dictionary
	var _tick := 0
	var _cursor := 0
	var _issue_scheduled: Callable
	var _advance_owner: Callable
	var _matches_settlement: Callable
	var _done := false

	func _init(owner: RefCounted, bundle: Dictionary, initial: Dictionary,
			issue_scheduled: Callable, advance_owner: Callable, matches_settlement: Callable) -> void:
		_owner = owner
		_bundle = bundle
		_projection = initial.projection.duplicate(true)
		_issue_scheduled = issue_scheduled
		_advance_owner = advance_owner
		_matches_settlement = matches_settlement

	func step() -> Dictionary:
		if _done:
			return {"ok": true, "done": true}
		if _owner == null:
			return {"ok": false, "error": "replay_closed", "path": "replay"}
		while _cursor < _bundle.commands.size() and _bundle.commands[_cursor].tick == _tick:
			var queued: Dictionary = _issue_scheduled.call(_owner, _bundle.commands[_cursor], _projection)
			if not queued.ok:
				queued.path = "commands[%d].%s" % [_cursor, queued.path]
				close()
				return queued
			_cursor += 1
		var result: Dictionary = _advance_owner.call(_owner)
		if not result.ok:
			close()
			return result
		_tick = result.frame.tick
		var finished: bool = result.summary.over or _tick == _bundle.max_ticks
		if finished:
			close()
			if not _bundle.expected_settlement.is_empty() and not _matches_settlement.call(result.summary.settlement, _bundle.expected_settlement):
				return {"ok": false, "error": "replay_settlement_mismatch", "path": "expected_settlement"}
			if _cursor < _bundle.commands.size():
				return {"ok": false, "error": "commands_after_terminal", "path": "commands[%d]" % _cursor}
		else:
			_projection = result.frame.projection.duplicate(true)
		_done = finished
		result.done = finished
		return result

	func close() -> void:
		if _owner != null:
			_owner.close()
			_owner = null
		_projection = {}

static func prepare_fresh(request: Variant) -> Dictionary:
	var operation_id := Dev.DEFINITION_ID + "/" + Crypto.new().generate_random_bytes(16).hex_encode()
	return _prepare_identity(request, operation_id)

static func _prepare_identity(request: Variant, operation_id: String) -> Dictionary:
	var prepared := (Product.prepare_fresh(request, operation_id)
		if request is Dictionary and request.get("capability") == Product.CAPABILITY
		else Dev._prepare(request, operation_id))
	if prepared.ok:
		prepared.operation_id = operation_id
	return prepared

static func begin_restore(packet: Variant) -> Dictionary:
	if packet is Dictionary and packet.get("request") is Dictionary and packet.request.get("capability") == Product.CAPABILITY:
		return Checkpoint.begin_restore(packet, _prepare_product_checkpoint, Dev.DEFINITION_ID)
	return Dev.begin_restore(packet)

static func _prepare_product_checkpoint(request: Dictionary, operation_id: String) -> Dictionary:
	if request.route_id != Product.ROUTE:
		return fail("unsupported_route", "packet.request.route_id")
	var external := request.duplicate()
	external.erase("route_id")
	return Product.prepare_fresh(external, operation_id)

static func queue(owner: RefCounted, command: Dictionary) -> Dictionary:
	var current: Dictionary = owner.summary()
	if not current.ok:
		return current
	var record := {"tick": current.summary.tick, "kind": command.get("kind")}
	if record.kind == "move" and typeof(command.get("point")) == TYPE_VECTOR2 and command.point.is_finite():
		var viewed: Dictionary = owner.read_projection()
		if not viewed.ok:
			return viewed
		var points: Array = viewed.projection.operation.route_points
		var nearest := INF
		for index in range(1, points.size()):
			var distance: float = command.point.distance_squared_to(points[index])
			if distance < nearest:
				nearest = distance
				record.waypoint = index
	var queued: Dictionary = owner.queue(command)
	if queued.ok:
		queued.record = record
	return queued

static func advance(owner: RefCounted) -> Dictionary:
	var stepped: Dictionary = owner.advance()
	if not stepped.ok:
		return stepped
	var read: Dictionary = owner.summary()
	if not read.ok:
		return read
	var viewed: Dictionary = owner.read_projection()
	if not viewed.ok:
		return viewed
	var summary: Dictionary = read.summary
	var projection: Dictionary = viewed.projection
	if (projection.tick != summary.tick or projection.operation.settlement != summary.settlement
			or summary.over != (not summary.settlement.is_empty())):
		return fail("inconsistent_operation_frame", "runtime.frame")
	var drained: Dictionary = owner.drain_events()
	if not drained.ok:
		return drained
	var result := {"ok": true, "summary": summary, "frame": {
		"tick": summary.tick, "clock_ms": summary.clock_ms, "projection": projection, "events": drained.events,
	}}
	if stepped.has("movement_error"):
		result.movement_error = stepped.movement_error
	return result

static func normalize(input: Variant) -> Dictionary:
	if not input is Dictionary or input.get("format") != FORMAT:
		return fail("unsupported_first_operation_bundle", "format")
	var required := ["format", "request", "max_ticks", "commands"]
	if not required.all(func(key): return input.has(key)) or not input.keys().all(func(key): return key in required + ["operation_id", "expected_settlement"]):
		return fail("unsupported_first_operation_bundle", "format")
	var fields := REQUEST_FIELDS
	if input.request is Dictionary and input.request.get("capability") == Product.CAPABILITY:
		fields = Product.REQUEST.keys()
	if not _fields(input.request, fields):
		return fail("invalid_operation_request", "request")
	var request := {}
	for key in fields:
		var value: Variant = input.request[key]
		if key in ["seed", "definition_version"]:
			if not _uint(value, 4294967295):
				return fail("invalid_operation_request", "request." + key)
			request[key] = int(value)
		else:
			if not value is String or value.length() > 128:
				return fail("invalid_operation_request", "request." + key)
			request[key] = value
	if request.capability == Product.CAPABILITY and request != Product.REQUEST:
		return fail("unapproved_operation_request", "request")
	if not _uint(input.max_ticks, MAX_TICKS) or int(input.max_ticks) == 0:
		return fail("invalid_tick_limit", "max_ticks")
	var max_ticks := int(input.max_ticks)
	if not input.commands is Array or input.commands.size() > MAX_COMMANDS:
		return fail("invalid_command_list", "commands")
	var commands: Array[Dictionary] = []
	var previous := -1
	var batch_size := 0
	for i in input.commands.size():
		var row: Variant = input.commands[i]
		var path := "commands[%d]" % i
		if not row is Dictionary or row.get("kind") not in ["move", "stop", "withdraw", "finalize_withdrawal"]:
			return fail("unsupported_operation_command", path + ".kind")
		var kind: String = row.kind
		if not _fields(row, ["tick", "kind", "waypoint"] if kind == "move" else ["tick", "kind"]):
			return fail("invalid_operation_command_fields", path)
		if not _uint(row.tick, max_ticks - 1) or int(row.tick) < previous:
			return fail("invalid_command_tick", path + ".tick")
		var tick := int(row.tick)
		batch_size = batch_size + 1 if tick == previous else 1
		if batch_size > MAX_BATCH:
			return fail("operation_queue_full", path)
		var command := {"tick": tick, "kind": kind}
		if kind == "move":
			if not _uint(row.waypoint, 4) or int(row.waypoint) == 0:
				return fail("invalid_route_waypoint", path + ".waypoint")
			command.waypoint = int(row.waypoint)
		commands.append(command)
		previous = tick
	var operation_id: Variant = input.get("operation_id", "")
	if input.has("operation_id") and not _valid_operation_id(operation_id):
		return fail("invalid_operation_id", "operation_id")
	var expected := {}
	if input.has("expected_settlement"):
		var settlement: Variant = input.expected_settlement
		if (operation_id.is_empty() or not _fields(settlement, SETTLEMENT_FIELDS)
				or settlement.operation_id != operation_id or settlement.id != operation_id + "/settlement"
				or settlement.kind not in ["objective_success", "withdrawal_success", "failure"]
				or not settlement.reason is String or settlement.reason.is_empty() or settlement.reason.length() > 128
				or not _uint(settlement.tick, MAX_TICKS) or int(settlement.tick) != max_ticks
				or not _uint(settlement.clock_ms, MAX_TICKS * 100) or int(settlement.clock_ms) != max_ticks * 100):
			return fail("invalid_replay_settlement", "expected_settlement")
		expected = settlement.duplicate(true)
		expected.tick = max_ticks
		expected.clock_ms = max_ticks * 100
	var bundle := {"format": FORMAT, "request": request, "max_ticks": max_ticks, "commands": commands}
	if not operation_id.is_empty():
		bundle.operation_id = operation_id
	if not expected.is_empty():
		bundle.expected_settlement = expected
	return {"ok": true, "bundle": bundle}

static func make_recording(request: Dictionary, operation_id: String, records: Array, settlement: Dictionary) -> Dictionary:
	var expected := {}
	for key in SETTLEMENT_FIELDS:
		if not settlement.has(key):
			return fail("invalid_replay_settlement", "expected_settlement." + key)
		expected[key] = settlement[key]
	return normalize({"format": FORMAT, "request": request, "operation_id": operation_id,
		"max_ticks": settlement.tick, "commands": records, "expected_settlement": expected})

# A verified resume packet supplies the earlier commands and already queued
# commands so a recording can span save/load without silently losing history.
static func recording_prefix(packet: Dictionary) -> Array[Dictionary]:
	var records: Array[Dictionary] = []
	for batch in packet.commands:
		_append_records(records, int(batch.tick), batch.batch)
	_append_records(records, int(packet.tick), packet.pending)
	return records

static func _append_records(records: Array[Dictionary], tick: int, commands: Array) -> void:
	for command in commands:
		var row := {"tick": tick, "kind": command.kind}
		if command.kind == "move":
			row.waypoint = command.goal
		records.append(row)

static func _valid_operation_id(value: Variant) -> bool:
	if not value is String or not value.begins_with(Dev.DEFINITION_ID + "/"):
		return false
	var suffix: String = value.trim_prefix(Dev.DEFINITION_ID + "/")
	if suffix.length() != 32:
		return false
	for character in suffix:
		if not character in "0123456789abcdef":
			return false
	return true

static func _matches_settlement(actual: Dictionary, expected: Dictionary) -> bool:
	return SETTLEMENT_FIELDS.all(func(key): return actual.has(key) and actual[key] == expected[key])

static func open_replay(input: Variant) -> Dictionary:
	return _open(input, true)

static func _open(input: Variant, require_settlement: bool) -> Dictionary:
	var normalized := normalize(input)
	if not normalized.ok:
		return normalized
	var bundle: Dictionary = normalized.bundle
	bundle.expected_settlement = bundle.get("expected_settlement", {})
	var operation_id: String = bundle.get("operation_id", "")
	if require_settlement and bundle.expected_settlement.is_empty():
		return fail("missing_replay_settlement", "expected_settlement")
	var prepared := (prepare_fresh(bundle.request) if operation_id.is_empty()
		else _prepare_identity(bundle.request, operation_id))
	if not prepared.ok:
		return prepared
	var owner: RefCounted = prepared.owner
	var published: Dictionary = owner.publish()
	if not published.ok:
		owner.close()
		return published
	var frame: Dictionary = published.frame
	return {"ok": true, "frame": frame,
		"replay": ReplaySession.new(owner, bundle, frame, _queue_scheduled, advance, _matches_settlement)}

static func run(input: Variant, should_cancel := Callable()) -> Dictionary:
	return _run(input, false, should_cancel)

static func run_replay(input: Variant) -> Dictionary:
	return _run(input, true, Callable())

static func _run(input: Variant, require_settlement: bool, should_cancel: Callable) -> Dictionary:
	if should_cancel.is_valid() and should_cancel.call():
		return fail("cancelled", "worker")
	var opened := _open(input, require_settlement)
	if not opened.ok:
		return opened
	var replay: ReplaySession = opened.replay
	var events: Array = opened.frame.events.duplicate(true)
	var blocked := 0
	while true:
		if should_cancel.is_valid() and should_cancel.call():
			replay.close()
			return fail("cancelled", "worker")
		var next := replay.step()
		if not next.ok:
			return next
		events.append_array(next.frame.events)
		blocked += int(next.has("movement_error"))
		if next.done:
			if should_cancel.is_valid() and should_cancel.call():
				return fail("cancelled", "worker")
			return {"ok": true, "summary": next.summary, "projection": next.frame.projection,
				"events": events, "event_count": events.size(), "blocked_ticks": blocked, "meta": opened.frame.meta}
	return fail("first_operation_run_failed", "runtime")

static func _queue_scheduled(owner: RefCounted, row: Dictionary, projection: Dictionary) -> Dictionary:
	var command := {"kind": row.kind, "side": 0}
	if row.kind in ["move", "stop"]:
		var ids: Array = []
		for fleet in projection.squadrons:
			if fleet.side == 0 and not fleet.dead and fleet.get("out", "") == "":
				ids.append(fleet.id)
		command.ids = ids
	if row.kind == "move":
		var points: Array = projection.operation.route_points
		if row.waypoint >= points.size():
			return fail("invalid_route_waypoint", "waypoint")
		command.point = points[row.waypoint]
	return owner.queue(command)

static func _fields(value: Variant, fields: Array) -> bool:
	return value is Dictionary and value.size() == fields.size() and fields.all(func(key): return value.has(key))

static func _uint(value: Variant, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return is_finite(number) and number >= 0.0 and number <= maximum and floorf(number) == number

static func fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
