extends RefCounted

const Source := preload("res://scripts/first_operation_source_reference.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const CAPABILITY := "pc/first-operation/3"
const ID_PREFIX := "red-cliffs-v3/"
const RULESET := "red-cliffs-multi-formation/1"
const FLEETS := ["RC-LIU-SQ-01", "RC-LIU-SQ-02"]
const FORMATIONS := ["FRM-01", "FRM-03"]
const FORMATION := {"kind": "formation", "squadron_id": "RC-LIU-SQ-01", "formation_id": "FRM-01"}

var _native: RefCounted
var _live := false
var _operation_id := ""
var _pending_formation := {}
var _active := {}
var _interrupted := {}
var _initial := {}
var _pending: Array[Dictionary] = []
var _history: Array[Dictionary] = []
var _events: Array = []
var _events_unread := false


static func prepare_fresh() -> Dictionary:
	return _prepare_identity(ID_PREFIX + Crypto.new().generate_random_bytes(16).hex_encode())


static func _prepare_identity(identity: String) -> Dictionary:
	var prepared := Source.prepare_fresh(Source.REQUEST, identity)
	if not prepared.ok:
		return prepared
	var owner := new()
	owner._native = prepared.owner
	owner._operation_id = identity
	var boot: Dictionary = prepared.owner.publish()
	if not boot.ok:
		owner.close()
		return boot
	owner._initial = owner._version_frame(boot).frame
	return {"ok": true, "owner": owner}


func presentation_identity() -> String:
	return _operation_id if _live and _native != null else ""


func preview_initial_frame() -> Dictionary:
	if _native == null or _live:
		return _fail("owner_unavailable")
	return {"ok": true, "frame": _initial.duplicate(true)}


func publish() -> Dictionary:
	var preview := preview_initial_frame()
	if preview.ok:
		_live = true
		_initial = {}
	return preview

func _version_frame(result: Dictionary) -> Dictionary:
	if result.ok:
		result.frame.meta.capability = CAPABILITY
		result.frame.meta.ruleset = RULESET
		result.frame.meta.operation_id = _operation_id
		_publish_formation_state(result.frame.projection)
	return result


func summary() -> Dictionary:
	return _native.summary() if not presentation_identity().is_empty() else _fail("owner_unavailable")


func read_projection() -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_unavailable")
	var result: Dictionary = _native.read_projection()
	if result.ok:
		_publish_formation_state(result.projection)
	return result


func _publish_formation_state(projection: Dictionary) -> void:
	for row: Dictionary in projection.squadrons:
		var squadron_id: String = row.get("squadron_id", "")
		if row.side != 0 or squadron_id not in FLEETS:
			continue
		row["formation_v3"] = {"active": {}, "interrupted": _interrupted.get(squadron_id, {}).duplicate(true)}
		if _active.get("squadron_id") == squadron_id:
			row.formation_v3.active = _active.duplicate(true)


func drain_events() -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_not_published")
	return {"ok": true, "events": _take_events()}


func _take_events() -> Array:
	var result := _events
	_events = []
	_events_unread = false
	return result


func capture_checkpoint() -> Dictionary:
	# The legacy host and external save codec must never receive a v3 packet.
	return _fail("v3_checkpoint_unavailable")


func capture_record() -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_not_published")
	if _events_unread:
		return _fail("v3_events_unread")
	return _record()


func _record() -> Dictionary:
	var runtime: RefCounted = _native._runtime
	var read: Dictionary = _native.summary()
	var serial: int = runtime._policy.checkpoint_serial()
	if not read.ok or serial < 0:
		return _fail("v3_state_unavailable")
	var current: Dictionary = read.summary
	var settlement := {}
	if current.over:
		for field in ["id", "operation_id", "kind", "reason", "tick", "clock_ms"]:
			settlement[field] = current.settlement[field]
	return {"ok": true, "record": {"capability": CAPABILITY, "operation_id": _operation_id,
		"tick": current.tick, "clock_ms": current.clock_ms, "history": _history.duplicate(true),
		"pending": _pending.duplicate(true), "state_digest": Checkpoint.digest_value([runtime._checkpoint_witness(serial), formation_state()]),
		"settlement": settlement}}


func queue(command: Dictionary) -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_not_published")
	return _queue(command)


func formation_state() -> Dictionary:
	return {"active": _active.duplicate(true), "interrupted": _interrupted.duplicate(true)}


func _queue(command: Dictionary) -> Dictionary:
	var runtime: RefCounted = _native._runtime
	var kind: Variant = command.get("kind")
	if not kind is String:
		return _fail("invalid_command_kind")
	if kind != "formation":
		if (not _pending_formation.is_empty() or not _active.is_empty()) and kind != "stop":
			return _fail("formation_in_progress")
		var recorded := {"kind": kind}
		if kind == "move":
			var point: Variant = command.get("point")
			if not point is Vector2 or not point.is_finite():
				return _fail("invalid_command_point")
			recorded.waypoint = runtime._routes.target(point)
		var queued: Dictionary = _native.queue(command)
		if queued.ok:
			_pending.append(recorded)
		return queued
	if command.size() != 3 or command.get("squadron_id") not in FLEETS or command.get("formation_id") not in FORMATIONS:
		return _fail("formation_unavailable")
	if not _pending_formation.is_empty():
		return {"ok": true} if command == _pending_formation else _fail("formation_in_progress")
	if not _active.is_empty():
		return {"ok": true} if command.squadron_id == _active.squadron_id and command.formation_id == _active.target else _fail("formation_in_progress")
	if not runtime._commands.is_empty() or not _can_form(command):
		return _fail("formation_unavailable")
	_pending_formation = command.duplicate()
	_pending.append(command.duplicate())
	return {"ok": true}


func _queue_record(command: Dictionary) -> Dictionary:
	if command.kind == "formation":
		return _queue(command)
	var runtime: RefCounted = _native._runtime
	var ids: Array = runtime._sim.st.alive(0).filter(func(f): return not f.out).map(func(f): return f.id)
	var requested := {"kind": command.kind, "side": 0, "ids": ids}
	if command.kind == "move":
		var points: Array = runtime._routes.points()
		if command.waypoint >= points.size():
			return _fail("invalid_waypoint")
		requested.point = points[command.waypoint]
	return _queue(requested)

func _can_form(command: Dictionary) -> bool:
	var runtime: RefCounted = _native._runtime
	var fleet = runtime._fleet(command.squadron_id)
	var ledger: Dictionary = runtime._policy.ledger()
	return fleet != null and not fleet.dead and not fleet.out and not fleet.moving and not fleet.has_move \
		and fleet.ships == fleet.max_ships and fleet.form_left == 0 and fleet.formation_id in FORMATIONS \
		and fleet.formation_id != command.formation_id and not fleet.face_set and not fleet.flip \
		and not ledger.withdrawal and ledger.settlement.is_empty() and runtime._sim.st.tick > 0 \
		and runtime._sim.salvo.transition_ticks(fleet, command.formation_id) == 50


func advance() -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_not_published")
	return _advance_recorded()


func _advance_recorded() -> Dictionary:
	var tick: int = _native.summary().summary.tick
	var result := _advance_native()
	if not result.ok:
		return result
	if not _pending.is_empty():
		_history.append({"tick": tick, "batch": _pending})
		_pending = []
	_events.append_array(_native.drain_events().events)
	_events_unread = true
	return result


func _advance_native() -> Dictionary:
	var runtime: RefCounted = _native._runtime
	var sim = runtime._sim
	var before: Dictionary = sim.checkpoint_tick()
	var command_count: int = sim.command_log.size()
	var previous := _active.duplicate(true)
	if not _pending_formation.is_empty():
		if not _can_form(_pending_formation):
			return _fail("formation_unavailable")
		var fleet = runtime._fleet(_pending_formation.squadron_id)
		_active = {"squadron_id": _pending_formation.squadron_id, "source": fleet.formation_id,
			"target": _pending_formation.formation_id, "start_tick": sim.st.tick, "elapsed_ticks": 0}
		sim.issue(BattleSim.command(0, [fleet.id], "formation", -1, Vector2.ZERO, {"id": _active.target}))
		if fleet.form_to != _active.target:
			sim.rollback_tick(before)
			sim.command_log.resize(command_count)
			_active = previous
			return _fail("formation_not_applied")
	# Completion must follow this tick's damage. Hold only the final native
	# decrement until the committed tick has established whether the roster survived.
	if not _active.is_empty():
		var fleet = runtime._fleet(_active.squadron_id)
		if fleet.form_left == 1:
			fleet.form_left = 2
	var result: Dictionary = _native.advance()
	if not result.ok:
		sim.rollback_tick(before)
		sim.command_log.resize(command_count)
		_active = previous
		return result
	_pending_formation = {}
	if not _active.is_empty():
		var fleet = runtime._fleet(_active.squadron_id)
		if fleet.dead or fleet.out or fleet.ships != fleet.max_ships:
			var stopped := _active.duplicate(true)
			stopped.tick = sim.st.tick
			_interrupted[_active.squadron_id] = stopped
			fleet.form_left = 0
			fleet.form_to = ""
			fleet.shape_to = fleet.shape
			fleet.form_t = fleet.form
			sim.emit("formation_interrupted", fleet.id, -1, fleet.pos, stopped.duplicate(true))
			_active = {}
		else:
			_active.elapsed_ticks += 1
			if _active.elapsed_ticks == 50:
				sim.salvo._transition_step(fleet)
				_active = {}
		# Preserve damage/policy event order before the v3 completion/interruption.
		runtime._committed_events.append_array(sim.drain_events_for(0))
	return result


func _set_restored_frame() -> void:
	var current: Dictionary = _native.summary().summary
	_initial.tick = current.tick
	_initial.clock_ms = current.clock_ms
	_initial.phase = "resume"
	_initial.projection = _native.read_projection().projection
	_publish_formation_state(_initial.projection)
	_initial.events = []

func close() -> void:
	_live = false
	if _native != null:
		_native.close()
		_native = null


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "path": "first_operation_v3"}
