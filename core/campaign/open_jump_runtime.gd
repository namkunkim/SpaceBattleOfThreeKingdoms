extends RefCounted
## Authoritative single-map campaign host. Inputs are native commands plus
## escort/extraction orders; zone observations are computed from BattleState.
const Native := preload("res://core/campaign/open_jump_native.gd")
const Policy := preload("res://core/campaign/open_jump_policy.gd")
const PLAYER_ALIASES := ["liu", "guan"]
const NATIVE_COMMANDS := ["move", "stop", "formation", "skill", "attack", "missile", "fighter", "volley"]
var definition: Dictionary
var seed: int
var sim: Native
var policy := Policy.new()
var journal: Array = []
var pending: Array = []
var deployed := {}
var capture_progress := 0
var base_owner := "cao_cao"
var recon_reported := false
var _events: Array = []
var _tick_order := ""

func _init(data: Dictionary, seed_id: int = 208) -> void:
	definition = data.duplicate(true)
	seed = seed_id
	sim = Native.new(seed, BattleRules.TICK_HZ, definition.initial_profile)
	sim.mission_think = _mission_think
	sim.escort_id = fleet("huang").id
	for alias in definition.operation.deployments.initial:
		deployed[alias] = 0
	for fleet in sim.st.fleets:
		fleet.control = "direct"
	_events.append({"kind": "briefing", "tick": 0,
		"text": "황개는 필수 철수 대상입니다. 황개와 살아 있는 유비·관우 함대 하나 이상이 함께 철수해야 합니다."})

func fleet(alias: String) -> FleetState:
	if not definition.fleets.has(alias):
		return null
	var sq: String = definition.fleets[alias].definition.squadron_id
	for item in sim.st.fleets:
		if item.sq_id == sq:
			return item
	return null

func queue(input: Dictionary) -> Dictionary:
	if sim.st.over:
		return {"ok": false, "error": "operation_terminal"}
	if typeof(input.get("kind")) != TYPE_STRING:
		return {"ok": false, "error": "invalid_command"}
	var kind: String = input.kind
	var command := {"kind": kind}
	if kind in ["huang_wait", "huang_advance", "confirm_jump"]:
		if kind != "confirm_jump" and policy.snapshot().phase == "rendezvous":
			return {"ok": false, "error": "not_joined"}
		if pending.any(func(row): return row.kind in ["huang_wait", "huang_advance", "confirm_jump"]):
			return {"ok": false, "error": "operation_order_pending"}
	elif kind in NATIVE_COMMANDS:
		if typeof(input.get("fleet")) != TYPE_STRING or input.fleet not in PLAYER_ALIASES:
			return {"ok": false, "error": "not_player_fleet"}
		if not _alive(fleet(input.fleet)):
			return {"ok": false, "error": "fleet_unavailable"}
		command.fleet = input.fleet
		if kind == "move":
			var point: Variant = input.get("point")
			if typeof(point) != TYPE_ARRAY or point.size() != 2:
				return {"ok": false, "error": "invalid_point"}
			for value in point:
				if typeof(value) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(value)):
					return {"ok": false, "error": "invalid_point"}
			if float(point[0]) < 0 or float(point[1]) < 0 or float(point[0]) > sim.rs.world.x or float(point[1]) > sim.rs.world.y:
				return {"ok": false, "error": "point_outside_map"}
			command.point = [float(point[0]), float(point[1])]
		if kind == "formation":
			if typeof(input.get("formation")) != TYPE_STRING or not sim.salvo.C.formations.has(input.formation):
				return {"ok": false, "error": "invalid_formation"}
			command.formation = input.formation
		if kind in ["attack", "missile", "fighter", "volley"]:
			var target: Variant = input.get("target_id", -1)
			if typeof(target) != TYPE_INT and typeof(target) != TYPE_FLOAT:
				return {"ok": false, "error": "invalid_target"}
			if not is_finite(float(target)) or float(target) != floor(float(target)) or target < 1 or target > 2147483647:
				return {"ok": false, "error": "invalid_target"}
			var other := sim.st.by_id(int(target))
			if other == null or other.side == 0 or not _alive(other) or not sim.sees(fleet(input.fleet), other):
				return {"ok": false, "error": "target_not_visible"}
			command.target_id = int(target)
		if kind == "skill":
			var slot: Variant = input.get("slot", -1)
			if typeof(slot) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(slot)) or float(slot) != floor(float(slot)) or slot < 0 or slot >= fleet(input.fleet).skill_slots.size():
				return {"ok": false, "error": "invalid_slot"}
			command.slot = int(slot)
			if input.has("target_id"):
				var target: Variant = input.target_id
				if typeof(target) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(target)) or float(target) != floor(float(target)) or target < 1 or target > 2147483647:
					return {"ok": false, "error": "invalid_target"}
				var other := sim.st.by_id(int(target))
				if other == null or not _alive(other) or (other.side != 0 and not sim.sees(fleet(input.fleet), other)):
					return {"ok": false, "error": "target_not_visible"}
				command.target_id = int(target)
	else:
		return {"ok": false, "error": "unsupported_command"}
	command.tick = sim.st.tick
	pending.append(command.duplicate(true))
	journal.append(command.duplicate(true))
	return {"ok": true}

func advance() -> Dictionary:
	if sim.st.over:
		return {"ok": false, "error": "operation_terminal", "state": snapshot()}
	_tick_order = ""
	for command in pending:
		match command.kind:
			"huang_wait": _tick_order = "wait"
			"huang_advance": _tick_order = "advance"
			"confirm_jump": _tick_order = "confirm_jump"
			_:
				var f := fleet(command.fleet)
				var point := Vector2.ZERO
				if command.has("point"):
					point = Vector2(command.point[0], command.point[1])
				var args := {}
				if command.has("formation"):
					args.id = command.formation
				if command.has("slot"):
					args.slot = command.slot
				sim.queue(BattleSim.command(0, [f.id], command.kind, int(command.get("target_id", -1)), point, args))
	pending.clear()
	var old_phase: String = policy.snapshot().phase
	sim.step()
	var observed := _observe()
	var result: Dictionary = policy.advance(observed, _tick_order)
	if not result.ok:
		return result
	for event in result.events:
		var emitted: Dictionary = event.duplicate(true)
		emitted.tick = sim.st.tick
		_events.append(emitted)
		if event.kind == "base_captured":
			_set_base_owner("liu_sun_alliance")
			_deploy("base_captured")
	var phase: String = result.state.phase
	if phase != old_phase:
		_events.append({"kind": "mission_started", "phase": phase, "tick": sim.st.tick})
		_deploy(phase)
		if phase == "escort":
			recon_reported = true
			_events.append({"kind": "recon_report", "tick": sim.st.tick,
				"text": "조조 본대가 기지 방면으로 접근합니다. 철수 예정지는 열린 도약로 끝입니다.",
				"exit": definition.operation.regions.exit.duplicate(true),
				"cao_approach": definition.operation.get("recon", {}).get("cao_approach", [1450, 200]).duplicate()})
	if result.state.jump_open and _enemies_in("base") and not (_inside(fleet("liu"), "base") or _inside(fleet("guan"), "base")):
		_set_base_owner("cao_cao")
	if result.state.outcome != "active":
		sim.finish_campaign(result.state.outcome == "success", "open_jump_" + result.state.outcome,
			{"evacuated": result.state.evacuated, "losses": _losses()})
	_tick_order = ""
	return {"ok": true, "state": snapshot()}

func _observe() -> Dictionary:
	var frame := {"tick": sim.st.tick, "recon_reported": recon_reported}
	for alias in ["liu", "guan", "huang"]:
		frame[alias + "_alive"] = _alive(fleet(alias))
		frame[alias + "_at_base"] = _inside(fleet(alias), "base")
		frame[alias + "_at_exit"] = _inside(fleet(alias), "exit")
	frame.liu_contact = _inside(fleet("liu"), "rendezvous") and _inside(fleet("huang"), "rendezvous")
	frame.guan_contact = _inside(fleet("guan"), "rendezvous") and _inside(fleet("huang"), "rendezvous")
	frame.huang_at_jump = _inside(fleet("huang"), "jump")
	frame.defenders_cleared = not _enemies_in("base")
	var capturing: bool = policy.snapshot().phase == "capture" and frame.huang_at_base and (frame.liu_at_base or frame.guan_at_base) and frame.defenders_cleared
	capture_progress = capture_progress + 1 if capturing else 0
	frame.capture_confirmed = capture_progress >= int(definition.operation.capture_ticks)
	return frame

func _deploy(event: String) -> void:
	var aliases: Array = definition.operation.deployments.get(event, [])
	# Validate every member before mutating; paired deployments are one transaction.
	for alias in aliases:
		assert(definition.fleets.has(alias))
	for alias in aliases:
		if deployed.has(alias):
			continue
		var row: Dictionary = definition.fleets[alias]
		sim.enter_reserve(row.definition, int(row.side))
		deployed[alias] = sim.st.tick
	if not aliases.is_empty():
		_events.append({"kind": "deployment", "group": event, "tick": sim.st.tick, "aliases": aliases.duplicate()})

func _mission_think(think: bool) -> void:
	var state: Dictionary = policy.snapshot()
	var huang := fleet("huang")
	if _alive(huang):
		var order: String = _tick_order if _tick_order in ["wait", "advance"] else state.huang_order
		var destination := "base" if state.phase in ["rendezvous", "escort", "capture"] else ("jump" if state.phase == "clash" else "exit")
		if state.phase == "rendezvous" or order == "wait" or (state.phase == "extraction" and _inside(huang, "exit")):
			_hold(huang)
		else:
			_move(huang, _center(destination))
	if not think:
		return
	for alias in ["patrol", "ren", "wen", "cao", "xu", "chun", "zhou", "cheng"]:
		var f := fleet(alias)
		if not _alive(f):
			continue
		var destination := _center("base")
		var target: FleetState = null
		match alias:
			"patrol": destination = _center("rendezvous")
			"ren": destination = (_center("rendezvous") + _center("base")) * 0.5
			"wen": destination = _center("base")
			"cao": destination = _center("base")
			"xu": destination = _center("base") + Vector2(180, -100)
			"chun":
				destination = _center("exit")
				if _alive(huang) and sim.sees(f, huang):
					target = huang
			"zhou", "cheng":
				var foe := fleet("cao" if alias == "zhou" else "xu")
				destination = _center("base") + Vector2(0, 120 if alias == "zhou" else -120)
				if _alive(foe) and sim.sees(f, foe):
					target = foe
		if target:
			f.target_id = target.id
			destination = sim.known_pos(f, target)
		else:
			var visible := sim.sight_foe(f, f.range_r)
			f.target_id = visible.id if visible else -1
		if f.pos.distance_to(destination) <= maxf(float(sim.R.arrive_r), 30.0):
			f.has_move = false
			f.route.clear()
		else:
			_move(f, destination)
		if sim.skills:
			sim.skills.ai_eval(f, sim.projection(f.side))

func _move(f: FleetState, point: Vector2) -> void:
	f.has_move = true
	f.move_to = point
	f.route.clear()
	f.control = "direct"

func _hold(f: FleetState) -> void:
	f.has_move = false
	f.target_id = -1
	f.route.clear()
	f.control = "direct"

func _center(region: String) -> Vector2:
	var center: Array = definition.operation.regions[region].center
	return Vector2(float(center[0]), float(center[1]))

func _inside(f: FleetState, region: String) -> bool:
	return _alive(f) and f.pos.distance_to(_center(region)) <= float(definition.operation.regions[region].radius)

func _enemies_in(region: String) -> bool:
	for f in sim.st.alive(1):
		if _inside(f, region):
			return true
	return false

static func _alive(f: FleetState) -> bool:
	return f != null and not f.dead and f.out == "" and f.ships > 0

func _losses() -> Dictionary:
	var result := {}
	for alias in ["liu", "guan", "huang"]:
		var f := fleet(alias)
		result[alias] = {"initial": f.max_ships, "remaining": f.ships if _alive(f) else 0}
	return result

func snapshot() -> Dictionary:
	return {"tick": sim.st.tick, "clock_ms": sim.st.clock_ms, "policy": policy.snapshot(),
		"deployed": deployed.duplicate(true), "capture_progress": capture_progress, "base_owner": base_owner,
		"recon_reported": recon_reported, "battle_fingerprint": sim.fingerprint(), "pending": pending.duplicate(true)}

func view() -> Dictionary:
	return {"battle": sim.projection(0), "operation": policy.snapshot(), "capture_progress": capture_progress,
		"capture_ticks": definition.operation.capture_ticks, "base_owner": base_owner, "regions": definition.operation.regions.duplicate(true)}

func drain_events() -> Array:
	var events: Array = _events
	_events = []
	events.append_array(sim.drain_events_for(0))
	return events

func close() -> void:
	if sim == null:
		return
	sim.mission_think = Callable()
	for key in ["salvo", "morale", "victory", "decisions", "detect", "supply", "chain", "cmd", "assault", "skills"]:
		var core: Variant = sim.get(key)
		if core != null:
			core.sim = null
	sim = null
	pending.clear()
	_events.clear()


func _set_base_owner(owner: String) -> void:
	if base_owner == owner:
		return
	base_owner = owner
	if sim.supply:
		for base in sim.supply.bases:
			if base.key == "OPEN-JUMP-BASE":
				base.side = 1 if owner == "cao_cao" else 0
				base.faction = "cao_cao" if owner == "cao_cao" else "liu_bei"
				for f in sim.st.fleets:
					if f.sup_src == base.key:
						f.sup_src = ""
						f.sup_prog = 0
