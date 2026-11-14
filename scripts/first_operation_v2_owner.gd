extends RefCounted

const Source := preload("res://scripts/first_operation_source_reference.gd")
const CAPABILITY := "pc/first-operation/2"
const ID_PREFIX := "red-cliffs-v2/"
const FORMATION := {"kind": "formation", "squadron_id": "RC-LIU-SQ-01", "formation_id": "FRM-01"}

var _native: RefCounted
var _live := false
var _operation_id := ""
var _pending_formation := false


static func prepare_fresh() -> Dictionary:
	var identity := ID_PREFIX + Crypto.new().generate_random_bytes(16).hex_encode()
	var prepared := Source.prepare_fresh(Source.REQUEST, identity)
	if not prepared.ok:
		return prepared
	var owner := new()
	owner._native = prepared.owner
	owner._operation_id = identity
	return {"ok": true, "owner": owner}


func presentation_identity() -> String:
	return _operation_id if _live and _native != null else ""


func preview_initial_frame() -> Dictionary:
	return _version_frame(_native.preview_initial_frame()) if _native != null else _fail("owner_closed")


func publish() -> Dictionary:
	if _native == null:
		return _fail("owner_closed")
	var result := _version_frame(_native.publish())
	if result.ok:
		_live = true
	return result


func _version_frame(result: Dictionary) -> Dictionary:
	if result.ok:
		result.frame.meta.capability = CAPABILITY
		result.frame.meta.operation_id = _operation_id
	return result


func summary() -> Dictionary:
	return _native.summary() if _native != null else _fail("owner_closed")


func read_projection() -> Dictionary:
	return _native.read_projection() if _native != null else _fail("owner_closed")


func drain_events() -> Dictionary:
	return _native.drain_events() if _native != null else _fail("owner_closed")


func capture_checkpoint() -> Dictionary:
	return _fail("v2_checkpoint_unavailable")


func queue(command: Dictionary) -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_not_published")
	var runtime: RefCounted = _native._runtime
	var fleet = runtime._fleet(FORMATION.squadron_id)
	if command.get("kind") != "formation":
		if (_pending_formation or (fleet != null and fleet.form_left > 0)) and command.get("kind") != "stop":
			return _fail("formation_in_progress")
		return _native.queue(command)
	if command != FORMATION or _pending_formation or not runtime._commands.is_empty() or not _can_form():
		return _fail("formation_unavailable")
	_pending_formation = true
	return {"ok": true}


func _can_form() -> bool:
	var runtime: RefCounted = _native._runtime
	var fleet = runtime._fleet(FORMATION.squadron_id)
	var ledger: Dictionary = runtime._policy.ledger()
	return fleet != null and not fleet.dead and not fleet.out and not fleet.moving and not fleet.has_move \
		and fleet.ships == fleet.max_ships and fleet.form_left == 0 and fleet.formation_id == "FRM-03" \
		and not ledger.withdrawal and ledger.settlement.is_empty() and runtime._sim.st.tick > 0 \
		and runtime._sim.salvo.transition_ticks(fleet, FORMATION.formation_id) == 50


func advance() -> Dictionary:
	if presentation_identity().is_empty():
		return _fail("owner_not_published")
	if not _pending_formation:
		return _native.advance()
	if not _can_form():
		_pending_formation = false
		return _fail("formation_unavailable")
	var runtime: RefCounted = _native._runtime
	var sim = runtime._sim
	var fleet = runtime._fleet(FORMATION.squadron_id)
	var before: Dictionary = sim.checkpoint_tick()
	var command_count: int = sim.command_log.size()
	sim.issue(BattleSim.command(0, [fleet.id], "formation", -1, Vector2.ZERO, {"id": FORMATION.formation_id}))
	var result: Dictionary = _native.advance() if fleet.form_to == FORMATION.formation_id else _fail("formation_not_applied")
	if not result.ok:
		sim.rollback_tick(before)
		sim.command_log.resize(command_count)
		return result
	_pending_formation = false
	return result


func close() -> void:
	_live = false
	if _native != null:
		_native.close()
		_native = null


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "path": "first_operation_v2"}
