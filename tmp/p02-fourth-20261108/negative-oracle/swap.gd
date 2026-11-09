extends SceneTree

const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const Private := preload("res://core/battle/operation_private_state.gd")
const Service := preload("res://core/battle/operation_service_state.gd")
const SERVICE_FIXTURE := "res://tests/fixtures/p02/services.json"
const SEED := 0
const HZ := 10
const CONTROLS := ["direct", "direct"]
const FAR_STEPS := 1
const NEAR_STEPS := 1200

func input(scenario: String) -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERVICE_FIXTURE))
	data.seed = SEED
	data.hz = HZ
	data.initial_controls = CONTROLS.duplicate()
	data.policy = "none"
	data.max_ticks = NEAR_STEPS
	if scenario == "clear":
		data.profile.combat.erase("detection")
	if scenario == "near":
		# Scout radar sees 225 units. The enemy's ordinary view does not.
		# Artillery's 260-unit range permits a natural asymmetric engagement.
		data.profile.ally[0].composition = [{"ship_type_id": "SHP-03", "count": 3}, {"ship_type_id": "SHP-06", "count": 1}]
		data.profile.foe[0].ships = 4
		data.profile.foe[0].composition = [{"ship_type_id": "SHP-04", "count": 4}]
		data.profile.foe[0].x = 625
	else:
		data.profile.foe[0].x = 1550
	return data

func typed_profile(scenario: String) -> Dictionary:
	# Construct the native profile directly from trusted rules/combat and typed
	# roster literals. Do not use adapter normalization or an owner observation.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERVICE_FIXTURE))
	var combat: Dictionary = data.profile.combat
	if scenario == "clear":
		combat.erase("detection")
	var near := scenario == "near"
	var ally_comp := [{"ship_type_id": "SHP-01", "count": 1}, {"ship_type_id": "SHP-03", "count": 1}, {"ship_type_id": "SHP-04", "count": 2}]
	if near:
		ally_comp = [{"ship_type_id": "SHP-03", "count": 3}, {"ship_type_id": "SHP-06", "count": 1}]
	var ally := {"name": "A", "role": "A", "ships": 4, "lv": 1, "x": 400.0, "y": 500.0,
		"p": 0, "flag": true, "composition": ally_comp, "formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	var foe := {"name": "B", "role": "B", "ships": 4 if near else 40, "lv": 1,
		"x": 625.0 if near else 1550.0, "y": 500.0, "p": 0, "flag": true,
		"composition": [{"ship_type_id": "SHP-04" if near else "SHP-02", "count": 4 if near else 40}],
		"formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	return {"profile_id": "p02-explicit-services", "rules": data.profile.rules,
		"ally": [ally], "foe": [foe], "reinf": [], "combat": combat}

func native(scenario: String) -> BattleSim:
	var sim := BattleSim.new(SEED, HZ, typed_profile(scenario))
	for i in CONTROLS.size():
		sim.st.fleets[i].control = CONTROLS[i]
	sim.projection(0)
	return sim

func clean(sim: BattleSim) -> void:
	for field in ["salvo", "detect", "supply"]:
		var module: Variant = sim.get(field)
		if module:
			module.sim = null

func stop_commands() -> Array[Dictionary]:
	return [BattleSim.command(0, [1], "stop"), BattleSim.command(1, [2], "stop")]

func prepare_native(sim: BattleSim, steps: int) -> void:
	for command in stop_commands():
		sim.issue(command)
	for i in steps:
		sim.step()


var checks := 0
var failures := 0
var rows := 0

func require(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("VIEWER_FAIL ", message)

func report(row: String, prior: int, details := {}) -> void:
	rows += 1
	print("VIEWER_ROW ", row, " ", "PASS" if failures == prior else "FAIL", " ", JSON.stringify(details))

func make_owner(scenario: String, steps: int) -> OperationPrivateState:
	var result := Adapter.create(input(scenario))
	require(result.ok, "restricted input accepted: " + str(result.get("error", "")))
	if not result.ok:
		return null
	var owner: OperationPrivateState = result.owner
	for command in stop_commands():
		require(owner.issue(command).ok, "owner immediate stop")
	for i in steps:
		if not owner.advance().ok:
			require(false, "owner advance")
			break
	return owner

func native_events(scenario: String, steps: int, side: int) -> Array[Dictionary]:
	var sim := native(scenario)
	prepare_native(sim, steps)
	var events := sim.drain_events() if side == -1 else sim.drain_events_for(side)
	clean(sim)
	return events

func same_events(actual: Array, expected: Array) -> bool:
	return actual.is_typed() and actual.get_typed_builtin() == TYPE_DICTIONARY and Service._same(actual, expected)

func events_for(events: Array, kind: String, id: int) -> Array:
	return events.filter(func(event: Dictionary): return event.kind == kind and event.sq == id)

func compare(owner: OperationPrivateState, side: int, expected: Array[Dictionary]) -> Array:
	var actual := owner.drain_events_for(1 - side)
	require(actual.keys() == ["ok", "events"] and actual.ok, "successful drain DTO")
	var events: Array = actual.get("events", [])
	require(same_events(events, expected), "exact event type/order/value for side %d" % side)
	return events

func test_matrix() -> void:
	var index := 0
	for scenario in ["clear", "far"]:
		for side in [0, 1]:
			var prior := failures
			var raw := native_events(scenario, FAR_STEPS, -1)
			var filtered := native_events(scenario, FAR_STEPS, side)
			require(raw.size() == 4 and events_for(raw, "say", 1).size() == 1 and events_for(raw, "say", 2).size() == 1, "two identifiable immediate stops")
			require(raw[2].tick == 0 and raw[3].tick == 0 and typeof(raw[3].pos) == TYPE_VECTOR2, "same-tick ordering and native position type")
			var owner := make_owner(scenario, FAR_STEPS)
			if owner:
				compare(owner, side, filtered)
				owner.close()
			var hidden_id: int = 2 - side
			if scenario == "clear":
				require(same_events(filtered, raw), "clear: both sides retain raw events")
			else:
				var reversed := native_events(scenario, FAR_STEPS, 1 - side)
				require(filtered.size() == 2 and events_for(filtered, "say", hidden_id).is_empty(), "fog: hidden opposing stop")
				require(not same_events(raw, filtered) and not same_events(reversed, filtered), "raw replacement and side swap are rejected by the oracle")
			index += 1
			report("E%02d" % index, prior, {"raw": raw.size(), "filtered": filtered.size(), "side": side, "opposing_id": hidden_id})

func test_contact_and_masks() -> void:
	var prior := failures
	var early := native_events("near", 0, 0)
	var late := native_events("near", 1, 0)
	var opposite := native_events("near", 1, 1)
	require(events_for(early, "say", 2).is_empty(), "foe not visible before first scan")
	require(events_for(late, "say", 2).size() == 1 and events_for(late, "say", 2)[0].tick == 0, "drain-time contact reveals an earlier event")
	var contacts := events_for(late, "contact", 2)
	require(contacts.size() == 1 and contacts[0].value == {"state": "confirmed", "was": "none"} and contacts[0].tick == 1, "real first-step contact")
	require(events_for(opposite, "contact", 2).is_empty(), "contact only for side 0")
	for spec in [[0, 0, early], [1, 0, late], [1, 1, opposite]]:
		var owner := make_owner("near", spec[0])
		if owner:
			compare(owner, spec[1], spec[2])
			owner.close()
	report("E05", prior, {"before": early.size(), "after_side0": late.size(), "after_side1": opposite.size(), "contacts": contacts.size()})

	prior = failures
	var raw := native_events("near", NEAR_STEPS, -1)
	var masked := native_events("near", NEAR_STEPS, 1)
	var salvo_raw := events_for(raw, "salvo", 1)
	var salvo_mask := events_for(masked, "salvo", -1)
	var loss_raw := events_for(raw, "ship_lost", 2)
	var loss_mask := events_for(masked, "ship_lost", 2)
	require(salvo_raw.size() == 2 and salvo_mask.size() == 2, "naturally fired salvos become anonymous")
	for i in mini(salvo_raw.size(), salvo_mask.size()):
		var expected: Dictionary = salvo_raw[i].duplicate(true)
		expected.sq = -1
		require(Service._same(salvo_mask[i], expected), "salvo actor only is masked")
	require(loss_raw.size() == 1 and loss_mask.size() == 1, "naturally observed ship loss")
	if loss_raw.size() == 1 and loss_mask.size() == 1:
		var expected: Dictionary = loss_raw[0].duplicate(true)
		require(expected.other == 1, "raw ship loss identifies the source")
		expected.other = -1
		require(Service._same(loss_mask[0], expected), "loss source only is masked")
	var owner := make_owner("near", NEAR_STEPS)
	if owner:
		compare(owner, 1, masked)
		owner.close()
	report("E06", prior, {"raw": raw.size(), "filtered": masked.size(), "masked_salvos": salvo_mask.size(), "masked_losses": loss_mask.size()})

func test_shared_queue() -> void:
	var prior := failures
	var owner := make_owner("far", FAR_STEPS)
	if owner:
		compare(owner, 0, native_events("far", FAR_STEPS, 0))
		require(owner.drain_events().events.is_empty(), "filtered drain consumes hidden events in raw queue")
		require(owner.drain_events_for(1).events.is_empty(), "other side cannot receive drained events")
		owner.close()
	owner = make_owner("far", FAR_STEPS)
	if owner:
		compare(owner, 1, native_events("far", FAR_STEPS, 1))
		require(owner.drain_events_for(0).events.is_empty(), "opposite-first also consumes queue")
		owner.close()
	report("E07", prior)

	prior = failures
	owner = make_owner("far", FAR_STEPS)
	if owner:
		require(same_events(owner.drain_events().events, native_events("far", FAR_STEPS, -1)), "raw still returns both sides")
		require(owner.drain_events_for(0).events.is_empty() and owner.drain_events_for(1).events.is_empty(), "raw then filtered is empty")
		owner.close()
	report("E08", prior)

func test_errors() -> void:
	var index := 9
	for invalid in [false, 0.0, "0", -1]:
		var prior := failures
		var owner := make_owner("far", FAR_STEPS)
		if owner:
			var original := owner._sim._events
			var snapshot := owner.capture_completed()
			require(snapshot.ok, "pre-error capture")
			require(owner.drain_events_for(invalid) == {"ok": false, "error": "invalid_side", "path": "side"}, "exact Variant validation")
			require(is_same(original, owner._sim._events) and original.size() == 4, "invalid request preserves queue identity")
			require(Service._same(snapshot, owner.capture_completed()), "invalid request preserves entire captured owner")
			compare(owner, 0, native_events("far", FAR_STEPS, 0))
			owner.close()
		report("E%02d" % index, prior, {"type": type_string(typeof(invalid)), "value": invalid})
		index += 1
	var prior := failures
	var owner := make_owner("far", FAR_STEPS)
	if owner:
		var snapshot := owner.capture_completed()
		var original := owner._sim._events
		owner._busy = true
		require(owner.drain_events_for(false) == {"ok": false, "error": "busy", "path": "owner"}, "busy has precedence over invalid side")
		require(owner.drain_events_for(0) == {"ok": false, "error": "busy", "path": "owner"}, "busy refuses valid side")
		require(owner._busy and is_same(original, owner._sim._events), "busy and queue identity preserved")
		owner._busy = false
		require(snapshot.ok and Service._same(snapshot, owner.capture_completed()), "busy request preserves entire captured owner")
		compare(owner, 1, native_events("far", FAR_STEPS, 1))
		owner.close()
		require(owner.drain_events_for(false) == {"ok": false, "error": "unprepared_owner", "path": "owner"}, "closed has precedence over invalid side")
		require(owner.drain_events_for(0) == {"ok": false, "error": "unprepared_owner", "path": "owner"}, "closed refuses valid side")
	report("E13", prior)

func test_copy_and_state() -> void:
	var prior := failures
	var owner := make_owner("near", NEAR_STEPS)
	if owner:
		var sim := native("near")
		prepare_native(sim, NEAR_STEPS)
		var pending := BattleSim.command(0, [1], "stop")
		sim.queue(pending)
		require(owner.queue(pending).ok, "nonempty pending command queue")
		var original := owner._sim._events
		var original_copy := original.duplicate(true)
		var original_salvos := events_for(original, "salvo", 1)
		var before := owner.capture_completed()
		var summary := owner.summary()
		require(before.ok and summary.ok, "capture and summary available before drain")
		var expected := sim.drain_events_for(1)
		var result := compare(owner, 1, expected)
		var after := owner.capture_completed()
		require(after.ok and after.packet.view.sim._events.is_empty() and sim._events.is_empty(), "both captures align with native queue consumption")
		if before.ok and after.ok:
			require(same_events(before.packet.view.sim._events, native_events("near", NEAR_STEPS, -1)), "pre-drain capture stores native raw events")
			before.packet.view.sim._events = sim._events
			require(Service._same(before, after), "capture changes only by removal of events")
			require(Service._same(after.packet.view.sim._queue, sim._queue) and Service._same(after.packet.view.sim.command_log, sim.command_log), "native command queue and log")
			require(after.packet.view.state.tick == sim.st.tick and after.packet.view.state.clock_ms == sim.st.clock_ms and after.packet.controls == CONTROLS, "native clock and initial controls")
		require(Service._same(summary, owner.summary()) and summary.summary.fp == sim.fingerprint(), "summary unchanged and native fingerprint")
		for side in [0, 1]:
			require(Service._same(owner.read_projection(side).projection, sim.projection(side)), "native projection after drain")
		var returned_salvos := events_for(result, "salvo", -1)
		require(not original_salvos.is_empty() and not returned_salvos.is_empty(), "real nested payload in both queue and output")
		if not original_salvos.is_empty() and not returned_salvos.is_empty():
			var original_payload: Dictionary = original_salvos[0].value
			returned_salvos[0].value.cat = "mutated"
			returned_salvos[0].sq = 999
			result.clear()
			require(original_payload.cat == "artillery" and same_events(original, original_copy), "nested/output mutations cannot alias pre-drain owner queue")
		clean(sim)
		owner.close()
	report("E14", prior)

func _initialize() -> void:
	require(Private._classes() == "", "canonical runtime class resource paths")
	if failures != 0:
		quit(1)
		return
	test_matrix()
	test_contact_and_masks()
	test_shared_queue()
	test_errors()
	test_copy_and_state()
	require(rows == 14, "fixed logical denominator")
	print("P02_VIEWER_EVENTS_", "PASS" if failures == 0 else "FAIL", " rows=", rows, " assertions=", checks)
	quit(0 if failures == 0 else 1)
