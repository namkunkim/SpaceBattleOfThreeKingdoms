extends SceneTree

const Policy = preload("res://core/battle/p05_p07_first_operation.gd")
const COMMAND := "RC-LIU-SQ-01"
const OTHER := "RC-LIU-SQ-02"
const DEFENDER := "RC-CAO-SQ-04"
const SITE_A := Vector2(895, 240)
const ENTRY := Vector2(250, 830)
const SITE_C := Vector2(1320, 640)

var checks := 0
var failures := 0


func _initialize() -> void:
	var source := Policy.load_source()
	if not expect(source.ok, "pinned Red Cliffs v1 definition"):
		finish()
		return
	var envelope := {"space": "effective", "origin": [0, 0],
		"world_size": [1700, 1150], "definition": source.definition}
	check_capture(envelope, COMMAND, 21900, 22000)
	check_capture(envelope, OTHER, 31900, 32000)
	finish()


func check_capture(envelope: Dictionary, next_actor: String, before_ms: int, capture_ms: int) -> void:
	var setup := Policy.create(envelope, "p07-contest-" + next_actor, "front")
	if not expect(setup.ok, "create policy for " + next_actor):
		return
	var policy: RefCounted = setup.policy
	var fleets := {COMMAND: fleet(SITE_A, 39, true),
		OTHER: fleet(ENTRY, 21), DEFENDER: fleet(SITE_C, 45)}
	var tick := 0
	var capture_events: Array[Dictionary] = []
	var observed_effects: Array = []
	# 100 ms fixed ticks. A hostile center arrives after 10000 ms and leaves
	# after 12000 ms, before either ally can complete the 20000 ms capture.
	while tick * 100 < capture_ms:
		tick += 1
		var clock := tick * 100
		if clock == 10100:
			fleets[DEFENDER].position = SITE_A
		elif clock == 12100:
			fleets[DEFENDER].position = SITE_C
			if next_actor == OTHER:
				fleets[COMMAND].position = ENTRY
				fleets[OTHER].position = SITE_A
		var proposed: Dictionary = policy.propose_tick({"tick": tick, "clock_ms": clock, "fleets": fleets})
		if not proposed.ok:
			expect(false, "policy proposal at %d: %s" % [clock, proposed])
			return
		var committed: Dictionary = policy.commit_tick(proposed.revision)
		if not committed.ok:
			expect(false, "policy commit at %d: %s" % [clock, committed])
			return
		for event: Dictionary in proposed.events:
			if event.kind == "site_captured" and event.get("fact", {}).get("site_id") == "A":
				capture_events.append(event)
		observed_effects.append_array(proposed.effects)
		var state: Dictionary = policy.ledger().sites.A
		match clock:
			10000:
				expect(state.capture_ms == 10000 and state.actor == COMMAND and state.control == "neutral" and
					state.epoch == 0 and not state.active, "%s baseline before contest" % next_actor)
			10100, 12000:
				expect(state.capture_ms == 10000 and state.actor == COMMAND and state.control == "neutral" and
					state.epoch == 0 and not state.active, "%s frozen at %d" % [next_actor, clock])
			12100:
				var expected_progress := 10100 if next_actor == COMMAND else 100
				expect(state.capture_ms == expected_progress and state.actor == next_actor and
					state.control == "neutral" and state.epoch == 0,
					"%s %d ms on first uncontested tick" % [next_actor, expected_progress])
		if clock == before_ms:
			expect(state.capture_ms == 19900 and state.control == "neutral" and capture_events.is_empty(),
				"%s no capture before %d" % [next_actor, capture_ms])
	var final_state: Dictionary = policy.ledger().sites.A
	expect(final_state.capture_ms == 20000 and final_state.control == "ally" and final_state.epoch == 1 and
		not final_state.active, "%s captures once before activation" % next_actor)
	expect(capture_events.size() == 1 and capture_events[0].clock_ms == capture_ms and
		capture_events[0].get("fact", {}).get("ownership_epoch") == 1, "%s one capture event at %d" % [next_actor, capture_ms])
	expect(observed_effects.is_empty(), "%s no refill, reinforcement or withdrawal effect" % next_actor)


func fleet(position: Vector2, count: int, flagship := false) -> Dictionary:
	return {"position": position, "stopped": true, "combat_capable": true, "flagship_alive": flagship,
		"at_route_exit": false, "entry_ship_count": count, "present_ships": count,
		"ammo": {"shell": 90}, "ammo_cap": {"shell": 100}}


func expect(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)
	return condition


func finish() -> void:
	print("P07 contest continuity: %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 and checks == 19 else 1)
