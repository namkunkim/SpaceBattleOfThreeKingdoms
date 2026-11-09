extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const Decision := preload("res://core/battle/decisions.gd")
const ACTIVE_ERROR := {"ok": false, "error": "unsupported_active_decisions"}
const PRIOR_CODE := "ac59a7547469c705d33854742e9503b08422770b01956a47861b45735ab8c1c6"
const SEED := 91231
const RED_CLIFFS := "res://data/profiles/red_cliffs_rt.json"

var assertions := {}
var duplicate_assertion := false
var observations := {}
var owners: Array[OperationPrivateState] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, condition: bool) -> bool:
	duplicate_assertion = duplicate_assertion or assertions.has(label)
	assertions[label] = condition
	if not condition:
		push_error("P03_OWNER_CONTRACT_FAIL " + label)
	return condition

func _new() -> OperationPrivateState:
	var result := Adapter.create({"mode": "operation", "format": Adapter.FORMAT,
		"seed": SEED, "hz": BattleRules.TICK_HZ, "initial_controls": ["direct", "direct"],
		"policy": "none", "max_ticks": 5,
		"profile": {"profile_id": "p03-owner-contract", "rules": PocSetup.profile().rules,
			"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
			"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 2600, "y": 1500, "p": 0, "flag": true}],
			"reinf": []}})
	if not result.ok:
		return null
	var owner: OperationPrivateState = result.owner
	owners.append(owner)
	return owner

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	return result.packet if result.ok else {}

func _same(a: Variant, b: Variant) -> bool:
	return var_to_bytes(a) == var_to_bytes(b)

func _exercise(owner: OperationPrivateState, reference: OperationPrivateState) -> void:
	var ally_id: int = owner.observe().fleets[0].id
	var stop := BattleSim.command(0, [ally_id], "stop")
	var pending := BattleSim.command(0, [ally_id], "move", -1, Vector2(800, 500))
	var immediate := BattleSim.command(0, [ally_id], "def")
	for instance in [owner, reference]:
		if not instance.issue(stop).ok or not instance.advance().ok or not instance.queue(pending).ok:
			_check("fixture_public_actions", false)
			return
	_check("fixture_public_actions", true)
	var before := _capture(owner)
	if not _check("fixture_public_capture", not before.is_empty() and _same(before, _capture(reference))):
		return
	var tick: int = before.view.state.tick
	var clock: int = before.view.state.clock_ms
	var old_log: Array = before.view.sim.command_log
	var old_events: Array = before.view.sim._events
	var pending_queue: Array[Dictionary] = [pending]
	if not _check("fixture_active_with_pending_and_events", tick > 0 and clock > 0
		and _same(before.view.sim._queue, pending_queue) and not old_events.is_empty()
		and owner._sim.decisions == null and owner._ready and not owner._busy):
		return

	var definition := ProfileLoader.read_json(RED_CLIFFS)
	var scenario := ProfileLoader.read_json(definition.scenario_path)
	var cards: Dictionary = scenario.get("realtime_rules", {}).get("decision_cards", {})
	var candidate := before.duplicate(true)
	candidate.profile.scenario = {"realtime_rules": {"decision_cards": cards.duplicate(true)}}
	var frozen := var_to_bytes(candidate)
	var baseline := candidate.duplicate(true)
	baseline.profile.erase("scenario")
	if not _check("scenario_only_packet_delta", not cards.is_empty() and _same(baseline, before)):
		return
	var handle := owner
	var sim := owner._sim
	var refused := owner.restore_completed(candidate)
	_check("exact_public_refusal", refused == {"ok": false, "error": "unsupported_scenario"} and not refused.has("owner"))
	_check("candidate_bytes_preserved", var_to_bytes(candidate) == frozen)
	_check("owner_and_sim_identity_ready_idle", is_same(owner, handle) and is_same(owner._sim, sim)
		and owner._ready and not owner._busy)
	var after := _capture(owner)
	_check("entire_public_capture_preserved", _same(after, before) and _same(after, _capture(reference)))
	_check("tick_pending_and_ordered_events_preserved", not after.is_empty() and after.view.state.tick == tick
		and after.view.state.clock_ms == clock and _same(after.view.sim._queue, pending_queue)
		and _same(after.view.sim._events, old_events))

	var expected_immediate := immediate.duplicate(true)
	expected_immediate.tick = tick
	var expected_pending := pending.duplicate(true)
	expected_pending.tick = tick
	var issued_log: Array[Dictionary] = []
	issued_log.assign(old_log)
	issued_log.append(expected_immediate)
	var advanced_log := issued_log.duplicate(true)
	advanced_log.append(expected_pending)
	var issue_ok: bool = owner.issue(immediate).ok
	var control_issue_ok: bool = reference.issue(immediate).ok
	var issued := _capture(owner)
	_check("immediate_logged_before_pending", issue_ok and control_issue_ok and not issued.is_empty()
		and _same(issued, _capture(reference)) and _same(issued.view.sim.command_log, issued_log)
		and _same(issued.view.sim._queue, pending_queue) and issued.view.state.tick == tick)
	var advance_ok: bool = owner.advance().ok
	var control_advance_ok: bool = reference.advance().ok
	var advanced := _capture(owner)
	_check("pending_logged_exactly_once_in_order", advance_ok and control_advance_ok and not advanced.is_empty()
		and _same(advanced, _capture(reference)) and advanced.view.state.tick == tick + 1
		and advanced.view.sim._queue.is_empty()
		and _same(advanced.view.sim.command_log, advanced_log))
	var drained := owner.drain_events()
	var reference_drained := reference.drain_events()
	var event_prefix: Array[Dictionary] = []
	if drained.ok:
		event_prefix.assign(drained.events.slice(0, old_events.size()))
	_check("ordered_events_drained_with_original_prefix", drained.ok and reference_drained.ok
		and _same(drained, reference_drained) and not advanced.is_empty()
		and _same(drained.events, advanced.view.sim._events)
		and _same(event_prefix, old_events))
	var empty := owner.drain_events()
	var reference_empty := reference.drain_events()
	_check("second_drain_empty", empty.ok and reference_empty.ok and empty.events.is_empty() and reference_empty.events.is_empty())
	observations.rejection = {"result": refused, "tick_before": tick, "clock_before": clock,
		"pending_before": before.view.sim._queue, "events_before": old_events,
		"tick_after_advance": advanced.get("view", {}).get("state", {}).get("tick"),
		"log_before": old_log, "log_after_advance": advanced.get("view", {}).get("sim", {}).get("command_log"),
		"ordered_drained_events": drained.get("events", []), "scenario_cards": cards.size()}

func _positive(owner: OperationPrivateState) -> void:
	var before := _capture(owner)
	if not _check("positive_capture_and_advance", not before.is_empty() and owner.advance().ok
		and owner.observe().state.tick == 1):
		return
	var original := owner._sim
	var result := owner.restore_completed(before)
	_check("positive_restore_exact_on_separate_owner", result == {"ok": true}
		and not is_same(original, owner._sim) and not owner._busy and _same(_capture(owner), before))
	observations.positive = {"result": result, "restored_tick": owner.observe().state.tick}

func _live_stamp(sim: BattleSim) -> PackedByteArray:
	return var_to_bytes([sim.st.tick, sim.st.clock_ms, sim._queue, sim._events, sim.command_log])

func _active(owner: OperationPrivateState, reference: OperationPrivateState) -> void:
	var packet := _capture(owner)
	var stop := BattleSim.command(0, [1], "stop")
	var move := BattleSim.command(0, [1], "move", -1, Vector2(800, 500))
	var setup_ok := not packet.is_empty()
	for instance in [owner, reference]:
		setup_ok = instance.issue(stop).ok and instance.advance().ok and instance.queue(move).ok and setup_ok
	var sim := owner._sim
	if not _check("active_fixture_progress_with_pending_and_events", setup_ok and sim.st.tick > 0
		and sim.st.clock_ms > 0 and sim._queue.size() == 1 and not sim._events.is_empty()
		and _same(_capture(owner), _capture(reference))):
		return
	var decision := Decision.new(sim, {}, {})
	decision._seq = 47
	sim.decisions = decision
	var owner_id := owner.get_instance_id()
	var before := _live_stamp(sim)
	var packet_bytes := var_to_bytes(packet)
	var captured := owner.capture_completed()
	_check("capture_active_refusal_unchanged", captured == ACTIVE_ERROR and _live_stamp(sim) == before
		and is_same(owner._sim, sim) and is_same(sim.decisions, decision) and decision._seq == 47)
	var refused := owner.restore_completed(packet)
	_check("active_decision_valid_packet_refused_preserving_identity", refused == ACTIVE_ERROR
		and owner.get_instance_id() == owner_id and is_same(owner._sim, sim)
		and is_same(sim.decisions, decision) and is_same(decision.sim, sim)
		and decision._seq == 47 and _live_stamp(sim) == before and owner._ready and not owner._busy
		and var_to_bytes(packet) == packet_bytes)

	owner._busy = true
	owner._ready = false
	var busy := owner.restore_completed(null)
	var busy_preserved := owner._busy and not owner._ready
	owner._busy = false
	var unprepared := owner.restore_completed(null)
	var unprepared_preserved := not owner._busy and not owner._ready
	owner._ready = true
	var active := owner.restore_completed(null)
	_check("guard_and_packet_error_precedence", busy == {"ok": false, "error": "busy"}
		and unprepared == {"ok": false, "error": "unprepared_owner"}
		and active == ACTIVE_ERROR and busy_preserved and unprepared_preserved and not owner._busy
		and is_same(owner._sim, sim) and is_same(sim.decisions, decision)
		and is_same(decision.sim, sim) and decision._seq == 47 and _live_stamp(sim) == before)
	observations.active = {"capture": captured, "valid_packet": refused, "busy": busy,
		"unprepared": unprepared, "malformed_packet": active, "tick": sim.st.tick,
		"clock": sim.st.clock_ms, "pending": sim._queue.size(), "events": sim._events.size(),
		"marker": decision._seq, "busy_after": owner._busy}
	sim.decisions = null
	decision.sim = null
	var old_code := packet.duplicate(true)
	old_code.code["operation_private_state.gd"] = PRIOR_CODE
	_check("previous_owner_code_fingerprint_refused", owner.restore_completed(old_code)
		== {"ok": false, "error": "code_mismatch"} and _live_stamp(sim) == before)
	var move_after := BattleSim.command(0, [1], "def")
	_check("active_refusal_public_suffix_after_fixture_cleanup", owner.issue(move_after).ok
		and reference.issue(move_after).ok and owner.advance().ok and reference.advance().ok
		and _same(_capture(owner), _capture(reference)) and _same(owner.drain_events(), reference.drain_events()))

func _run() -> void:
	if _check("canonical_classes", Private._classes() == ""):
		var owner := _new()
		var reference := _new()
		var positive := _new()
		if _check("three_distinct_owners", owner != null and reference != null and positive != null
			and not is_same(owner, reference) and not is_same(owner, positive) and not is_same(reference, positive)):
			_exercise(owner, reference)
			_positive(positive)
		var live := _new()
		var live_reference := _new()
		if _check("active_owners_created", live != null and live_reference != null):
			_active(live, live_reference)
	for owner in owners:
		owner.close()
	owners.clear()
	var passed := assertions.size() == 24 and not duplicate_assertion and not assertions.values().has(false)
	print("P03_ACTIVE_GUARD_RESULT ", JSON.stringify({"ok": passed, "assertions": assertions,
		"observations": observations, "engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id()}))
	quit(0 if passed else 1)
