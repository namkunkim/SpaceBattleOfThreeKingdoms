extends RefCounted

const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const NativeTick := preload("res://core/battle/first_operation_native_tick.gd")
const Routes := preload("res://core/battle/first_operation_routes.gd")

var _sim: NativeTick
var _reserve: Dictionary
var _policy: RefCounted
var _routes: Routes
var _definition: Dictionary
var _route: String
var _progress: Dictionary
var _stopped_since := {}
var _commands: Array[Dictionary] = []
var _committed_events: Array[Dictionary] = []
var _request: Dictionary
var _operation_id: String
var _command_history: Array[Dictionary] = []
var _event_cursor := 0

func _init(profile: Dictionary, seed: int, initial: Dictionary, reserve: Dictionary,
		policy: RefCounted, definition: Dictionary, request: Dictionary, operation_id: String) -> void:
	var route: String = request.route_id
	_request = {}
	for key in Checkpoint.REQUEST_FIELDS:
		_request[key] = request[key]
	_operation_id = operation_id
	_sim = NativeTick.new(seed, BattleRules.TICK_HZ, profile)
	_reserve = reserve
	_policy = policy
	_definition = definition
	_route = route
	_routes = Routes.new(policy, definition, route)
	_progress = {route: _routes.start(route, false)}
	for fleet in _sim.st.fleets:
		_sim.initialize_fleet(fleet, initial[fleet.sq_id])

func advance() -> Dictionary:
	var ledger: Dictionary = _policy.ledger()
	if not ledger.settlement.is_empty():
		return _fail("operation_terminal", "runtime.policy")
	var progress := _progress.duplicate(true)
	var order := ""
	for command in _commands:
		match command.kind:
			"move": _routes.order(progress[_route], command.goal)
			"stop": _routes.stop(progress[_route])
			"withdraw", "finalize_withdrawal": order = command.kind

	var elapsed := roundi(_sim.dt * 1000.0)
	var movement := _routes.advance(_sim.st.fleets, progress, elapsed)
	var moves: Dictionary = movement.moves if movement.ok else {}
	if movement.ok:
		progress = movement.progress
	var checkpoint := _sim.checkpoint_tick()
	_apply_movement(moves, progress)
	_sim.advance_combat()
	var stationary := _stopped_since.duplicate()
	var frame := _policy_frame(moves, progress, stationary, order)
	var proposal: Dictionary = _policy.propose_tick(frame)
	if not proposal.ok:
		_sim.rollback_tick(checkpoint)
		return _fail(proposal.error, "runtime.policy.propose_tick")
	var effect_error := _apply_effects(proposal.effects, progress)
	if not effect_error.is_empty():
		_policy.discard_tick(proposal.revision)
		_sim.rollback_tick(checkpoint)
		return _fail(effect_error, "runtime.policy.effects")
	var committed: Dictionary = _policy.commit_tick(proposal.revision)
	if not committed.ok:
		_policy.discard_tick(proposal.revision)
		_sim.rollback_tick(checkpoint)
		return _fail(committed.error, "runtime.policy.commit_tick")

	if order == "withdraw":
		_routes.reverse(progress[_route])
	_progress = progress
	_stopped_since = stationary
	if not _commands.is_empty():
		_command_history.append({"tick": _sim.st.tick - 1, "batch": _commands.duplicate(true)})
	_commands.clear()
	_committed_events.append_array(_sim.drain_events_for(0))
	_committed_events.append_array(proposal.events)
	if not movement.ok:
		return {"ok": true, "movement_error": movement.error}
	return {"ok": true}

func issue(command: Dictionary) -> Dictionary:
	return queue(command)

func queue(command: Dictionary) -> Dictionary:
	var ledger: Dictionary = _policy.ledger()
	if not ledger.settlement.is_empty():
		return _fail("operation_terminal", "runtime.policy")
	if _commands.size() >= Checkpoint.MAX_BATCH:
		return _fail("operation_queue_full", "command")
	var kind: Variant = command.get("kind")
	if kind not in ["move", "stop", "withdraw", "finalize_withdrawal"]:
		return _fail("unsupported_dev_command", "command.kind")
	if typeof(command.get("side")) != TYPE_INT or command.side != 0:
		return _fail("invalid_command_side", "command.side")
	if command.get("args", {}) != {}:
		return _fail("unsupported_dev_command_args", "command.args")
	if kind in ["withdraw", "finalize_withdrawal"]:
		if _commands.any(func(item): return item.kind in ["withdraw", "finalize_withdrawal"]):
			return _fail("operation_command_pending", "command.kind")
		if (kind == "withdraw") == bool(ledger.withdrawal):
			return _fail("withdrawal_already_started" if ledger.withdrawal else "withdrawal_not_started", "command.kind")
		_commands.append({"kind": kind})
		return {"ok": true}
	if ledger.withdrawal:
		return _fail("withdrawal_in_progress", "command.kind")
	if not _valid_selection(command.get("ids")):
		return _fail("invalid_selection", "command.ids")
	if kind == "stop":
		_commands.append({"kind": kind})
		return {"ok": true}
	var point: Variant = command.get("point")
	if typeof(point) != TYPE_VECTOR2 or not point.is_finite():
		return _fail("invalid_command_point", "command.point")
	var goal := _routes.target(point)
	if goal < _progress[_route].next:
		return _fail("invalid_route_target", "command.point")
	_commands.append({"kind": kind, "goal": goal})
	return {"ok": true}

func _valid_selection(ids: Variant) -> bool:
	if not ids is Array or ids.is_empty() or not ids.all(func(id): return typeof(id) == TYPE_INT):
		return false
	var live := _sim.st.alive(0).filter(func(fleet): return not fleet.out)
	return live.size() == ids.size() and live.all(func(fleet): return ids.has(fleet.id))

func _apply_movement(moves: Dictionary, progress: Dictionary) -> void:
	for fleet in _sim.st.fleets:
		if not moves.has(fleet.sq_id):
			continue
		var move: Dictionary = moves[fleet.sq_id]
		fleet.pos = move.to
		fleet.heading = move.heading_to
		fleet.moving = not move.from.is_equal_approx(move.to)
		var route: String = _route if fleet.side == 0 else "reinforcement"
		fleet.has_move = progress.has(route) and progress[route].goal >= 0 and progress[route].goal != progress[route].reached
		if fleet.has_move:
			var destination := _routes.points(route)
			fleet.move_to = destination[progress[route].goal] + (fleet.pos - Vector2(progress[route].center))

func _policy_frame(moves: Dictionary, progress: Dictionary, stationary: Dictionary, order: String) -> Dictionary:
	var fleets := {}
	var elapsed := roundi(_sim.dt * 1000.0)
	var now := _sim.st.clock_ms
	for fleet in _sim.st.fleets:
		if fleet.out == "escaped":
			continue
		var move: Dictionary = moves.get(fleet.sq_id, {})
		var distance := float(move.from.distance_to(move.to)) if not move.is_empty() else 0.0
		var stopped := distance <= float(_definition.supply.still_eps_per_s) * elapsed / 1000.0
		stationary[fleet.sq_id] = int(stationary.get(fleet.sq_id, now - elapsed)) if stopped else now
		var present := 0 if fleet.dead else _sim.salvo.present_ships(fleet)
		var cap := {}
		for cat in fleet.ammo:
			cap[cat] = _ammo_cap(fleet, cat)
		var route: Dictionary = progress[_route]
		fleets[fleet.sq_id] = {
			"position": fleet.pos, "stopped": stopped, "stopped_since_ms": stationary[fleet.sq_id],
			"combat_capable": present > 0, "flagship_alive": fleet.is_flag and present > 0,
			"at_route_exit": fleet.side == 0 and route.reverse and route.reached == 0 and route.center.is_equal_approx(_routes.points()[0]),
			"entry_ship_count": roundi(float(fleet.max_ships) / BattleRules.MILLI),
			"present_ships": present, "ammo": fleet.ammo.duplicate(), "ammo_cap": cap,
		}
	return {"tick": _sim.st.tick, "clock_ms": now, "command": order, "fleets": fleets}

func _ammo_cap(fleet: FleetState, cat: String) -> int:
	var weapon: Dictionary = _sim.salvo.C.weapons[cat]
	var platforms := 0
	for ship in weapon.platforms:
		if fleet.stages.has(ship):
			platforms += _sim.salvo.present_of(fleet, ship)
	var fast_craft: String = _sim.salvo.C.fast_craft.ship_type_id
	if weapon.equipment.has(fleet.equip) and fleet.stages.has(fast_craft):
		platforms += _sim.salvo.present_of(fleet, fast_craft)
	return platforms * int(weapon.ammo_per_platform if int(weapon.shot.ammo) > 0 else weapon.special_per_platform)

func _apply_effects(effects: Array, progress: Dictionary) -> String:
	for effect in effects:
		match effect.kind:
			"set_ammo":
				var fleet := _fleet(effect.fleet_id)
				if fleet == null or fleet.dead or fleet.out or effect.ammo.keys() != fleet.ammo.keys():
					return "invalid_ammo_effect"
				fleet.ammo = effect.ammo.duplicate()
			"spawn_reinforcement":
				if _fleet(_reserve.id) != null or effect.fleet.id != _reserve.id or effect.route_id != "reinforcement":
					return "invalid_reinforcement_effect"
				_sim.enter_reserve(_reserve.fleet, _reserve.pose, effect.position)
				progress.reinforcement = _routes.start("reinforcement", true)
			"remove_exited_fleet":
				var fleet := _fleet(effect.fleet_id)
				if fleet == null or fleet.dead or fleet.out or fleet.side != 0:
					return "invalid_exit_effect"
				fleet.out = "escaped"
				fleet.dead = true
				fleet.has_move = false
			_:
				return "unsupported_policy_effect"
	return ""

func _fleet(id: String) -> FleetState:
	for fleet in _sim.st.fleets:
		if fleet.sq_id == id:
			return fleet
	return null

func summary() -> Dictionary:
	var ledger: Dictionary = _policy.ledger()
	return {"ok": true, "summary": {
		"tick": _sim.st.tick, "clock_ms": _sim.st.clock_ms, "over": not ledger.settlement.is_empty(),
		"settlement": ledger.settlement,
		"reserve": {"id": _reserve.id, "status": ledger.reinforcement},
	}}

func read_projection(side: int) -> Dictionary:
	var projection := _sim.projection(side).duplicate(true)
	var ledger: Dictionary = _policy.ledger()
	var sites := {}
	for site in ledger.sites:
		sites[site] = {"control": ledger.sites[site].control, "active": ledger.sites[site].active}
	projection.operation = {
		"route_id": _route, "route_points": _routes.points(), "withdrawal": ledger.withdrawal, "sites": sites,
		"settlement": ledger.settlement,
	}
	if not ledger.settlement.is_empty():
		projection.outcome.over = true
		projection.outcome.win = ledger.settlement.kind != "failure"
		projection.outcome.reason = ledger.settlement.reason
		projection.outcome.end_tick = ledger.settlement.tick
		projection.outcome.result = ledger.settlement.duplicate(true)
	for row in projection.squadrons:
		if row.side == side:
			row.squadron_id = _sim.st.by_id(row.id).sq_id
	return {"ok": true, "projection": projection}

func drain_events_for(side: int) -> Dictionary:
	if side != 0:
		return _fail("invalid_event_side", "side")
	var events := _sim.drain_events_for(0)
	events.append_array(_committed_events)
	_event_cursor += _committed_events.size()
	_committed_events.clear()
	return {"ok": true, "events": events}

func checkpoint_packet(meta: Dictionary) -> Dictionary:
	var ledger: Dictionary = _policy.ledger()
	if not ledger.settlement.is_empty():
		return _fail("checkpoint_terminal", "runtime.policy")
	var serial: int = _policy.checkpoint_serial()
	if serial < 0:
		return _fail("checkpoint_busy", "runtime.policy")
	var code := Checkpoint.rules_digest()
	if code.is_empty():
		return _fail("checkpoint_rules_unavailable", "runtime")
	return {"ok": true, "packet": {
		"format": Checkpoint.FORMAT, "request": _request.duplicate(true), "operation_id": _operation_id,
		"rules_digest": code, "source_digest": meta.source_digest, "effective_digest": meta.effective_digest,
		"tick": _sim.st.tick, "clock_ms": _sim.st.clock_ms,
		"commands": _command_history.duplicate(true), "pending": _commands.duplicate(true),
		"event_cursor": _event_cursor, "proposal_serial": serial, "state_digest": _checkpoint_witness(serial),
	}}

func replay_tick(batch: Array, path: String) -> Dictionary:
	if not batch.is_empty():
		var queued := _replay_batch(batch, path)
		if not queued.ok:
			return queued
	var advanced := advance()
	if not advanced.ok:
		if advanced.error == "operation_terminal":
			return _fail("checkpoint_terminal", "packet.tick")
		return _fail("checkpoint_replay_failed", "packet.tick")
	return {"ok": true}

func finish_restore_replay(packet: Dictionary) -> Dictionary:
	var ledger: Dictionary = _policy.ledger()
	if not ledger.settlement.is_empty():
		return _fail("checkpoint_terminal", "packet.tick")
	if _sim.st.clock_ms != packet.clock_ms or ledger.tick != packet.tick or ledger.clock_ms != packet.clock_ms:
		return _fail("checkpoint_clock_mismatch", "packet.clock_ms")
	var pending := _replay_batch(packet.pending, "packet.pending")
	if not pending.ok:
		return pending
	if packet.event_cursor > _committed_events.size():
		return _fail("checkpoint_event_cursor_mismatch", "packet.event_cursor")
	_event_cursor = packet.event_cursor
	_committed_events = _committed_events.slice(_event_cursor)
	if not _policy.restore_checkpoint_serial(packet.proposal_serial):
		return _fail("checkpoint_serial_mismatch", "packet.proposal_serial")
	if _checkpoint_witness(packet.proposal_serial) != packet.state_digest:
		return _fail("checkpoint_state_mismatch", "packet.state_digest")
	return {"ok": true}

func _replay_batch(batch: Array, path: String) -> Dictionary:
	var waypoints := _routes.points()
	var ids := _sim.st.alive(0).filter(func(fleet): return not fleet.out).map(func(fleet): return fleet.id)
	for i in batch.size():
		var row: Dictionary = batch[i]
		var command := {"kind": row.kind, "side": 0}
		if row.kind == "move" or row.kind == "stop":
			command.ids = ids
		if row.kind == "move":
			if row.goal < 1 or row.goal >= waypoints.size():
				return _fail("checkpoint_replay_command_rejected", "%s[%d].goal" % [path, i])
			command.point = waypoints[row.goal]
		if not queue(command).ok:
			return _fail("checkpoint_replay_command_rejected", "%s[%d]" % [path, i])
	return {"ok": true}

func _checkpoint_witness(serial: int) -> String:
	return Checkpoint.digest_value({
		"native": _sim.replay_witness(), "request": _request, "operation_id": _operation_id,
		"reserve": _reserve, "route_progress": _progress, "stopped_since": _stopped_since,
		"ledger": _policy.ledger(), "proposal_serial": serial, "command_history": _command_history,
		"pending": _commands, "events": _committed_events, "event_cursor": _event_cursor,
	})

func close() -> void:
	if _sim == null:
		return
	_sim.salvo.sim = null
	if _sim.detect != null:
		_sim.detect.sim = null
	_sim = null
	_routes = null
	_policy = null
	_reserve.clear()
	_committed_events.clear()
	_commands.clear()
	_command_history.clear()

func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
