extends SceneTree

const Dev := preload("res://core/battle/first_operation_dev.gd")
const Preparer := preload("res://core/battle/first_operation_preparer.gd")

class PolicyProbe extends RefCounted:
	var policy: RefCounted
	var reject_effect := false
	var reject_movement := false
	var discards := 0

	func route_points(route_id: String, reverse := false) -> Array[Vector2]:
		return policy.route_points(route_id, reverse)

	func validate_movement(moves: Dictionary, leg: int, elapsed_ms: int) -> Dictionary:
		if reject_movement:
			moves = moves.duplicate(true)
			moves["RC-LIU-SQ-01"].to += Vector2(1000, 0)
		return policy.validate_movement(moves, leg, elapsed_ms)

	func ledger() -> Dictionary:
		return policy.ledger()

	func propose_tick(frame: Dictionary) -> Dictionary:
		var result: Dictionary = policy.propose_tick(frame)
		if result.ok and reject_effect:
			result.effects.append({"kind": "test_invalid_effect"})
		return result

	func commit_tick(revision: int) -> Dictionary:
		return policy.commit_tick(revision)

	func discard_tick(revision: int) -> Dictionary:
		discards += 1
		return policy.discard_tick(revision)

var _checks := 0
var _failed := false
var _defender: Dictionary
var _observed_runtime: RefCounted
var _probe: PolicyProbe
var _initial_combat: Dictionary

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var request := {
		"capability": Dev.CAPABILITY, "definition_id": Dev.DEFINITION_ID, "definition_version": 1,
		"roster_id": Dev.ROSTER_ID, "difficulty": "standard", "seed": 208, "mode": "direct", "route_id": "front",
	}
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		if args.size() == 3 and args[0] == "front-delay" and args[1].is_valid_int() and args[2].is_valid_int():
			_check_front(request, int(args[1]), int(args[2]))
		else:
			_check(false, "expected front-delay <A seconds> <C seconds>")
		_finish()
		return
	var product := request.duplicate()
	product.capability = Preparer.CAPABILITY
	_check(Dev.prepare_fresh(product).get("error") == "unsupported_capability", "development entry rejects product capability")
	var no_route := request.duplicate()
	no_route.erase("route_id")
	_check(Dev.prepare_fresh(no_route).get("error") == "missing_field", "route is required")
	var wrong_route := request.duplicate()
	wrong_route.route_id = "reinforcement"
	_check(Dev.prepare_fresh(wrong_route).get("error") == "unsupported_route", "unsupported route rejected")
	var wrong_seed := request.duplicate()
	wrong_seed.seed = 209
	_check(Dev.prepare_fresh(wrong_seed).get("error") == "unsupported_dev_seed", "only frozen development seed is accepted")

	var result := Dev.prepare_fresh(request)
	var observed := Preparer.new(Dev._resolve, _observe_build, Dev.CAPABILITY).prepare_fresh(request)
	if not result.get("ok", false) or not observed.get("ok", false):
		_check(false, "preparation failed: %s / %s" % [result, observed])
		_finish()
		return
	var owner: RefCounted = observed.owner
	var frame: Dictionary = owner.publish().frame
	_check(frame == result.owner.preview_initial_frame().frame, "independent native initialization matches")
	result.owner.close()
	_check(frame.tick == 0 and frame.clock_ms == 0 and frame.hz == 10, "native initial time")
	_check(frame.meta.capability == Dev.CAPABILITY, "frame identifies development capability")
	var allies: Array = frame.projection.squadrons
	_check(allies.size() == 2, "player initial projection contains only the two E fleets")
	if allies.size() != 2 or _defender.is_empty():
		_check(false, "initial fleet projection missing")
		owner.close()
		_finish()
		return
	_check(allies[0].squadron_id == "RC-LIU-SQ-01" and allies[1].squadron_id == "RC-LIU-SQ-02", "E roster IDs")
	_check(allies[0].pos == Vector2(250, 763) and allies[1].pos == Vector2(250, 897), "E offsets")
	_check(allies[0].ships_milli == 39000 and allies[1].ships_milli == 21000, "E composition counts")
	_check(allies[0].formation_id == "FRM-03" and allies[1].formation_id == "FRM-01", "E formations")
	_check(is_equal_approx(allies[0].heading, deg_to_rad(-51.54629078329403)) and is_equal_approx(allies[1].heading, allies[0].heading), "E heading")
	_check(allies[0].control == "direct" and allies[1].control == "direct", "E initial controls")
	_check(_defender.squadron_id == "RC-CAO-SQ-04" and _defender.pos == Vector2(1320, 640), "C actual native defender")
	_check(_defender.ships_milli == 45000 and _defender.formation_id == "FRM-04" and _defender.heading == 0.0, "C composition and pose")
	_check_ammo(allies[0], 0.9, "LIU01")
	_check_ammo(allies[1], 0.9, "LIU02")
	_check_ammo(_defender, 1.0, "CAO04")
	_check(frame.events.map(func(event): return event.kind) == ["spawn", "spawn"], "initial side-filtered native spawn events")
	_check(owner.drain_events().events.is_empty(), "initial events are consumed once")

	var ids := [allies[0].id, allies[1].id]
	var cmd := {"kind": "move", "side": 0, "ids": ids, "point": Vector2(520, 490)}
	var invalid := cmd.duplicate()
	invalid.ids = [_defender.id]
	_check(owner.queue(invalid).get("error") == "invalid_selection", "enemy IDs are rejected as player selection")
	_check(owner.queue(cmd).ok and owner.summary().summary.tick == 0, "queue native group command without advancing")
	_probe.reject_movement = true
	var held: Dictionary = owner.advance()
	_check(held.get("movement_error") == "movement_limit", "actual P05 guard rejects an invalid swept proposal")
	var held_view: Array = owner.read_projection().projection.squadrons
	_check(held_view[0].pos == allies[0].pos and held_view[0].heading == allies[0].heading and owner.summary().summary.tick == 1, "rejected move holds pose while time proceeds")
	_probe.reject_movement = false
	_check(owner.advance().ok, "valid held command retries on the next native tick")
	var moved: Array = owner.read_projection().projection.squadrons
	_check(moved[0].has_move and moved[1].has_move and moved[0].move_to != moved[1].move_to, "native move keeps group offsets")
	var time: Dictionary = owner.summary().summary
	_check(time.tick == 2 and time.clock_ms == 200, "native logical clock")
	_check(owner.issue({"kind": "stop", "side": 0, "ids": ids}).ok, "native stop command queued")
	owner.advance()
	_check(not owner.read_projection().projection.squadrons[0].has_move, "stop applied to native state")

	for step in range(1247):
		owner.advance()
	var before_summary: Dictionary = owner.summary().summary
	var before_view: Dictionary = owner.read_projection().projection
	_check(before_summary.clock_ms == 125000 and before_summary.reserve.status == "scheduled", "R stays scheduled at the exact threshold")
	_probe.reject_effect = true
	_check(owner.advance().get("error") == "unsupported_policy_effect" and _probe.discards == 1, "invalid effect discards a real policy proposal")
	_check(owner.summary().summary == before_summary and owner.read_projection().projection == before_view, "rollback preserves native clock, roster and projection")
	_probe.reject_effect = false
	_check(owner.advance().ok, "same tick retries after discard")
	time = owner.summary().summary
	_check(time.tick == 1251 and time.clock_ms == 125100, "native clock crosses development reserve time")
	_check(time.reserve == {"id": "RC-CAO-SQ-05", "status": "entered"}, "R enters at the first eligible policy tick")
	var enemy_view: Array = _observed_runtime.read_projection(1).projection.squadrons
	_check(enemy_view.any(func(row): return row.get("squadron_id") == "RC-CAO-SQ-05"), "R appears in the actual native roster after policy commit")
	var events: Array = owner.drain_events().events
	_check(events.filter(func(event): return event.kind == "reinforcement_entered").size() == 1, "reinforcement policy event committed once")
	_check(not time.over, "development runtime has no terminal campaign outcome")
	owner.close()
	_check(owner.advance().get("error") == "owner_closed", "closed native runtime cannot advance")
	_check_withdrawal(request)
	_check_front(request)
	_finish()

func _observe_build(effective: Dictionary, selection: Dictionary, request: Dictionary) -> Dictionary:
	_initial_combat = selection.inputs.combat_rules.combat
	var result := Dev._build_runtime(effective, selection, request)
	if result.get("ok", false):
		_observed_runtime = result.runtime
		_probe = PolicyProbe.new()
		_probe.policy = _observed_runtime._policy
		_observed_runtime._policy = _probe
		_observed_runtime._routes._policy = _probe
		var projection: Dictionary = _observed_runtime.read_projection(1).projection
		var defenders: Array = projection.squadrons.filter(func(row): return row.side == 1)
		_check(defenders.size() == 1, "R must be absent from initial native roster")
		if defenders.size() == 1:
			_defender = defenders[0]
	return result

func _check_withdrawal(request: Dictionary) -> void:
	var flank := request.duplicate()
	flank.route_id = "flank"
	var result := Dev.prepare_fresh(flank)
	if not result.get("ok", false):
		_check(false, "flank preparation failed: %s" % result)
		return
	var owner: RefCounted = result.owner
	var initial: Dictionary = owner.publish().frame.projection
	var points: Array = initial.operation.route_points
	_check(initial.operation.route_id == "flank" and points[2] == Vector2(690, 875), "flank publishes the B route")
	var ids: Array = initial.squadrons.map(func(row): return row.id)
	_check(owner.queue({"side": 0, "kind": "move", "ids": ids, "point": Vector2(120, 100)}).get("error") == "invalid_route_target", "off-route command rejected")
	_check(owner.queue({"side": 0, "kind": "move", "ids": ids, "point": points[2]}).ok, "B waypoint command")
	var blocked := false
	for step in 1500:
		var tick: Dictionary = owner.advance()
		blocked = blocked or not tick.ok or tick.has("movement_error")
	_check(not blocked, "B approach and wait pass the actual movement guard")
	var at_b: Array = owner.read_projection().projection.squadrons
	_check(at_b[0].pos == Vector2(690, 808) and at_b[1].pos == Vector2(690, 942), "B arrival preserves the two formation offsets")
	var events: Array = owner.drain_events().events
	_check(events.any(func(event): return event.kind == "facility_active" and event.fact.facility_id == "B"), "B capture and activation commit")
	_check(events.any(func(event): return event.kind == "supply_completed" and event.fact.facility_id == "B"), "B applies a live supply effect")
	_check(owner.queue({"side": 0, "kind": "withdraw"}).ok, "explicit withdrawal command")
	for step in 650:
		var tick: Dictionary = owner.advance()
		blocked = blocked or not tick.ok or tick.has("movement_error")
	_check(not blocked, "reverse path passes actual movement guard")
	_check(owner.queue({"side": 0, "kind": "finalize_withdrawal"}).ok and owner.advance().ok, "explicit withdrawal finalization")
	var summary: Dictionary = owner.summary().summary
	var dto: Dictionary = summary.settlement
	var final_view: Dictionary = owner.read_projection().projection
	var terminal: Array = owner.drain_events().events.filter(func(event): return event.kind == "operation_settled")
	_check(dto.get("kind") == "withdrawal_success" and dto.get("reason") == "withdrawal_conditions_met", "P07 commits a successful native withdrawal")
	_check(terminal.size() == 1 and terminal[0].fact == dto and final_view.operation.settlement == dto and final_view.outcome.result == dto, "one settlement DTO across event, projection and summary")
	_check(dto.get("clock_ms") == summary.clock_ms and dto.get("tick") == summary.tick, "settlement shares the native logical timestamp")
	_check(owner.advance().get("error") == "operation_terminal" and owner.drain_events().events.is_empty(), "terminal clock and settlement freeze")
	owner.close()

func _check_front(request: Dictionary, a_seconds := 0, c_seconds := 90) -> void:
	var result := Preparer.new(Dev._resolve, _observe_build, Dev.CAPABILITY).prepare_fresh(request)
	if not result.get("ok", false):
		_check(false, "front preparation failed: %s" % result)
		return
	var owner: RefCounted = result.owner
	var initial: Dictionary = owner.publish().frame.projection
	var points: Array = initial.operation.route_points
	var ids: Array = initial.squadrons.map(func(row): return row.id)
	_check(points[2] == Vector2(895, 240), "front publishes the A route")
	var blocked := 0
	for step in 12000:
		if step == a_seconds * 10:
			_check(owner.queue({"side": 0, "kind": "move", "ids": ids, "point": points[2]}).ok, "A waypoint command")
		if step == c_seconds * 10:
			_check(owner.read_projection().projection.operation.sites.A.active, "A is active when the C command is sent")
			_check(owner.queue({"side": 0, "kind": "move", "ids": ids, "point": points[3]}).ok, "C approach waypoint command")
		var tick: Dictionary = owner.advance()
		if tick.get("error") == "operation_terminal":
			break
		if not tick.ok:
			_check(false, "front runtime failed: %s" % tick)
			break
		blocked += int(tick.has("movement_error"))
	var summary: Dictionary = owner.summary().summary
	print("front A=%ds C=%ds outcome: %s; blocked ticks: %d" % [a_seconds, c_seconds, summary.settlement, blocked])
	var terminal_view: Dictionary = owner.read_projection().projection
	var own: Array = terminal_view.squadrons.filter(func(row): return row.side == 0)
	_check(blocked == 0 and own.size() == 2 and own[0].pos.is_equal_approx(points[3] + Vector2(0, -67))
		and own[1].pos.is_equal_approx(points[3] + Vector2(0, 67)), "front reaches the guarded engagement point without movement rejection")
	_check(summary.settlement.get("kind") == "objective_success" and summary.settlement.get("reason") == "objective_conditions_met", "front objective succeeds")
	_check(summary.settlement.get("clock_ms", 0) < 1200000 and summary.settlement.get("tick") == summary.tick and summary.settlement.get("clock_ms") == summary.clock_ms, "front objective completes on the native clock before the deadline")
	var sim: BattleSim = _observed_runtime._sim
	var defeated := []
	for fleet in sim.st.fleets:
		if fleet.side == 1 and (fleet.dead or sim.salvo.present_ships(fleet) == 0):
			defeated.append(fleet.sq_id)
	_check(defeated == ["RC-CAO-SQ-04", "RC-CAO-SQ-05"], "native combat neutralizes both C contesting fleets")
	var settled: Array = owner.drain_events().events.filter(func(event): return event.kind == "operation_settled")
	_check(settled.size() == 1 and settled[0].fact == summary.settlement and terminal_view.operation.settlement == summary.settlement, "front settlement is identical across consumers")
	owner.close()

func _check_ammo(fleet: Dictionary, multiplier: float, label: String) -> void:
	# The recon-equipped fast craft contributes only to matching weapon categories.
	var equipment := "FAST-EQ-RECON" if label == "LIU01" else ""
	for category in _initial_combat.categories:
		var weapon: Dictionary = _initial_combat.weapons[category]
		var platforms := 0
		for ship in weapon.platforms:
			platforms += int(fleet.counts.get(ship, [0])[0])
		if equipment in weapon.equipment:
			platforms += int(fleet.counts.get(_initial_combat.fast_craft.ship_type_id, [0])[0])
		var capacity := platforms * int(weapon.ammo_per_platform if weapon.shot.ammo > 0 else weapon.special_per_platform)
		_check(fleet.ammo[category] == floori(capacity * multiplier), "%s %s initial ammunition" % [label, category])

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)

func _finish() -> void:
	print("first_operation_dev: %d checks, passed=%s" % [_checks, not _failed])
	quit(1 if _failed else 0)
