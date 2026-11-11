extends SceneTree

const Policy = preload("res://core/battle/p05_p07_first_operation.gd")
const COMMAND := "RC-LIU-SQ-01"
const OTHER := "RC-LIU-SQ-02"
const DEFENDER := "RC-CAO-SQ-04"
const RESERVE := "RC-CAO-SQ-05"

var failures: Array[String] = []
var checks := 0


func _initialize() -> void:
	var source: Dictionary = Policy.load_source()
	expect(source.ok, "pinned source")
	if not source.ok:
		finish()
		return
	var envelope := {"space": "source", "origin": [0, 0], "world_size": [1700, 1150], "definition": source.definition}
	expect(Policy.create(envelope, "test", "front").error == "invalid_effective_definition", "source cannot bypass preparation")
	envelope.space = "effective"
	expect(Policy.create(envelope, "test", "unknown").error == "invalid_operation_selection", "unsupported route")
	test_movement(Policy.create(envelope, "geo", "front").policy)
	test_supply_and_reinforcement(Policy.create(envelope, "supply", "front").policy)
	test_result(envelope)
	test_deadline(envelope)
	finish()


func test_movement(policy: RefCounted) -> void:
	var points: Array[Vector2] = policy.route_points("front")
	expect(points.size() == 4 and points.front() == Vector2(250, 830), "front points")
	var forward: Vector2 = points[0].move_toward(points[1], 1.0)
	var start := points[0] + Vector2(0, -67)
	var target := forward + Vector2(0, -67)
	var row := {"from": start, "to": target, "heading_from": 0.0, "heading_to": 0.0,
		"formation_id": "FRM-03", "plan_from": points[0], "plan_to": forward}
	expect(policy.validate_movement({COMMAND: row}, 0, 100).ok, "valid movement")
	row.heading_to = 0.01
	expect(policy.validate_movement({COMMAND: row}, 0, 100).error == "turn_while_moving", "moving turn rejected")
	row.heading_to = 0.0
	row.plan_to = Vector2.ZERO
	expect(policy.validate_movement({COMMAND: row}, 0, 100).error == "tracking_budget", "tracking rejected")
	row.plan_to = forward
	var blocker := row.duplicate()
	blocker.from = target
	blocker.to = target
	blocker.formation_id = "FRM-04"
	expect(policy.validate_movement({COMMAND: row, DEFENDER: blocker}, 0, 100).error == "interfleet_clearance", "overlap rejected")
	expect(policy.validate_movement({COMMAND: row}, 0, 100, "front", true).error == "invalid_movement_context",
		"reverse requires withdrawal")


func test_supply_and_reinforcement(policy: RefCounted) -> void:
	var ships := {COMMAND: fleet(Vector2(895, 240), 39, true),
		OTHER: fleet(Vector2(250, 897), 21), DEFENDER: fleet(Vector2(1320, 640), 45)}
	var frame := {"tick": 1, "clock_ms": 100, "fleets": ships}
	var first: Dictionary = policy.propose_tick(frame)
	expect(first.ok and policy.ledger().tick == 0, "proposal detached")
	expect(policy.discard_tick(first.revision).ok and policy.ledger().tick == 0, "rejected proposal preserves state")
	var retried: Dictionary = policy.propose_tick(frame)
	expect(not policy.commit_tick(first.revision).ok and policy.commit_tick(retried.revision).ok,
		"stale proposal cannot commit a retry")
	advance(policy, ships, 20000)
	expect(policy.ledger().sites.A.control == "ally" and not policy.ledger().sites.A.active, "captured before activation")
	advance(policy, ships, 30000)
	expect(policy.ledger().sites.A.active and policy.ledger().transactions.is_empty(), "facility activates")
	advance(policy, ships, 89900)
	expect(policy.ledger().transactions.is_empty(), "no early refill")
	ships[COMMAND].stopped = false
	advance(policy, ships, 90000)
	expect(policy.ledger().sites.A.work.is_empty(), "movement discards partial service")
	ships[COMMAND].stopped = true
	advance(policy, ships, 125000)
	expect(policy.ledger().reinforcement == "scheduled", "strict schedule")
	ships[DEFENDER] = fleet(Vector2(1450, 290), 45)
	var waiting := advance(policy, ships, 125100)
	expect(waiting.events.size() == 1 and waiting.events[0].kind == "reinforcement_waiting"
		and waiting.effects.is_empty(), "blocked R waits")
	ships[DEFENDER].position = Vector2(1320, 640)
	var arrived := advance(policy, ships, 125200)
	expect(arrived.effects.size() == 1 and arrived.effects[0].kind == "spawn_reinforcement", "unblocked R spawns once")
	ships[RESERVE] = fleet(Vector2(1450, 290), 30)
	expect(advance(policy, ships, 125300).effects.is_empty(), "no repeated reinforcement")
	var paid := advance(policy, ships, 150000)
	expect(paid.effects.size() == 1 and paid.effects[0].kind == "set_ammo" and paid.effects[0].ammo.shell == 100,
		"completed refill effect")
	expect(policy.ledger().sites.A.stock == {"ammo": 990.0, "materials": 1.0}
		and policy.ledger().transactions.size() == 1, "finite atomic debit")
	expect(not policy.commit_tick(paid.revision).ok, "duplicate commit rejected")


func test_result(envelope: Dictionary) -> void:
	for mode: String in ["objective", "command_loss", "withdrawal", "insufficient"]:
		var policy: RefCounted = Policy.create(envelope, mode, "front").policy
		var ships := {COMMAND: fleet(Vector2(895, 240), 39, true),
			OTHER: fleet(Vector2(895, 307), 21), DEFENDER: fleet(Vector2(1320, 640), 45)}
		ships[DEFENDER].present_ships = 0
		ships[DEFENDER].combat_capable = false
		advance(policy, ships, 30000)
		if mode in ["objective", "command_loss"]:
			ships[COMMAND].position = Vector2(1320, 640)
			advance(policy, ships, 49900)
			if mode == "command_loss":
				ships[COMMAND].flagship_alive = false
			var result := advance(policy, ships, 50000)
			var kind := "objective_success" if mode == "objective" else "failure"
			expect(result.settlement.kind == kind and result.settlement.id == mode + "/settlement", mode)
			expect(policy.propose_tick({"tick": 501, "clock_ms": 50100, "fleets": ships}).error == "operation_terminal",
				"terminal freezes effects")
		else:
			ships[COMMAND].position = Vector2(250, 763)
			ships[COMMAND].at_route_exit = true
			ships[COMMAND].present_ships = 30 if mode == "withdrawal" else 29
			advance(policy, ships, 30100)
			expect(policy.ledger().exits.is_empty(), "E contact alone cannot withdraw")
			var leaving := advance(policy, ships, 30200, "withdraw")
			expect(leaving.effects.size() == 1 and leaving.effects[0].kind == "remove_exited_fleet", "real E exit effect")
			ships.erase(COMMAND)
			var final := advance(policy, ships, 30300, "finalize_withdrawal")
			expect(final.settlement.kind == ("withdrawal_success" if mode == "withdrawal" else "failure"), mode)
			expect(final.settlement.entry_cost == 60 and final.settlement.surviving_cost == (30 if mode == "withdrawal" else 29),
				"entry cost preserved through losses")


func test_deadline(envelope: Dictionary) -> void:
	var policy: RefCounted = Policy.create(envelope, "deadline", "flank").policy
	var ships := {COMMAND: fleet(Vector2(690, 875), 39, true),
		OTHER: fleet(Vector2(250, 897), 21), DEFENDER: fleet(Vector2(1320, 640), 45)}
	advance(policy, ships, 125100)
	ships[RESERVE] = fleet(Vector2(1450, 290), 30)
	advance(policy, ships, 1199800, "withdraw")
	expect(policy.ledger().settlement.is_empty(), "withdrawal waits before deadline")
	advance(policy, ships, 1199900)
	ships[COMMAND].position = Vector2(250, 763)
	ships[COMMAND].at_route_exit = true
	var result := advance(policy, ships, 1200000)
	expect(result.settlement.kind == "withdrawal_success" and result.settlement.clock_ms == 1200000,
		"valid E arrival at deadline counts")


func fleet(position: Vector2, count: int, flagship := false) -> Dictionary:
	return {"position": position, "stopped": true, "combat_capable": true, "flagship_alive": flagship,
		"at_route_exit": false, "entry_ship_count": count, "present_ships": count,
		"ammo": {"shell": 90}, "ammo_cap": {"shell": 100}}


func advance(policy: RefCounted, fleets: Dictionary, target: int, command := "") -> Dictionary:
	var result := {}
	var clock: int = policy.ledger().clock_ms
	var tick: int = policy.ledger().tick
	while clock < target:
		clock = mini(clock + 100, target)
		tick += 1
		result = policy.propose_tick({"clock_ms": clock, "tick": tick, "fleets": fleets,
			"command": command if clock == target else ""})
		if not result.ok:
			expect(false, str(result))
			return {"events": [], "effects": [], "settlement": {}}
		if not policy.commit_tick(result.revision).ok:
			expect(false, "commit failed")
			break
	return result


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		printerr("FAIL: ", label)


func finish() -> void:
	print("P05/P07 policy: %d/%d" % [checks - failures.size(), checks])
	quit(0 if failures.is_empty() else 1)

