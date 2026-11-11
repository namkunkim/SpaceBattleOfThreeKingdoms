extends SceneTree

const Adapter := preload("res://scripts/first_operation_adapter.gd")
const REQUEST := {
	"capability": "pc/first-operation-dev/1", "definition_id": "red-cliffs-first-operation-dev-v1",
	"definition_version": 1, "roster_id": "red-cliffs-dev-roster-v1",
	"seed": 208, "difficulty": "standard", "mode": "direct", "route_id": "front",
}

var _checks := 0
var _failed := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_check_short_cases()
	_check_recorded_battle()
	print("first_operation_adapter: %d checks, passed=%s" % [_checks, not _failed])
	quit(1 if _failed else 0)

func _check_short_cases() -> void:
	var plan := {"format": Adapter.FORMAT, "request": REQUEST, "max_ticks": 2, "commands": []}
	var normalized := Adapter.normalize(JSON.parse_string(JSON.stringify(plan)))
	_check(normalized.ok and Adapter.normalize(normalized.bundle).ok, "JSON request normalized and remains valid")
	_check(Adapter.open_replay(plan).get("error") == "missing_replay_settlement", "replay requires a recorded settlement")
	_check(Adapter.run(plan, func(): return true).get("error") == "cancelled", "cancel before preparing")
	var worker := Thread.new()
	if _check(worker.start(Adapter.run.bind(plan)) == OK, "common runtime starts in a worker thread"):
		var computed: Dictionary = worker.wait_to_finish()
		_check(computed.ok and computed.summary.tick == 2 and not computed.summary.over, "worker receives same partial result")
	var bad := plan.duplicate(true)
	bad.commands = [{"tick": 0, "kind": "move", "waypoint": 4}]
	_check(Adapter.run(bad).get("error") == "invalid_route_waypoint", "route-specific waypoint guard")

	var early := plan.duplicate(true)
	early.commands = [{"tick": 0, "kind": "withdraw"}, {"tick": 1, "kind": "finalize_withdrawal"}]
	var done := Adapter.run(early)
	if not _check(done.ok and done.summary.over, "quick run reaches real terminal"):
		return
	var settlement: Dictionary = done.summary.settlement
	var recorded := Adapter.make_recording(REQUEST, settlement.operation_id, early.commands, settlement)
	if not _check(recorded.ok, "terminal tuple recorded"):
		return
	recorded.bundle.expected_settlement.reason = "wrong_reason"
	_check(Adapter.run_replay(recorded.bundle).get("error") == "replay_settlement_mismatch", "mismatched terminal reason rejects")

func _check_recorded_battle() -> void:
	var prepared := Adapter.prepare_fresh(REQUEST)
	if not _check(prepared.ok and prepared.has("operation_id"), "host-facing prepare exposes identity"):
		return
	var owner: RefCounted = prepared.owner
	var frame: Dictionary = owner.publish().frame
	var points: Array = frame.projection.operation.route_points
	var ids: Array = frame.projection.squadrons.map(func(fleet): return fleet.id)
	var records: Array = []
	var events: Array = frame.events.duplicate(true)
	var final: Dictionary
	for tick in Adapter.MAX_TICKS:
		if tick in [0, 900]:
			var waypoint := 2 if tick == 0 else 3
			var queued := Adapter.queue(owner, {"kind": "move", "side": 0, "ids": ids, "point": points[waypoint]})
			if not _check(queued.ok and queued.record == {"tick": tick, "kind": "move", "waypoint": waypoint}, "host queue receipts record accepted command"):
				owner.close()
				return
			records.append(queued.record)
			if tick == 900:
				var checkpoint: Dictionary = owner.capture_checkpoint()
				_check(checkpoint.ok and Adapter.recording_prefix(checkpoint.packet) == records, "resume packet preserves applied and pending history")
		final = Adapter.advance(owner)
		if not final.ok:
			_check(false, "live adapter advance: %s" % final)
			owner.close()
			return
		events.append_array(final.frame.events)
		if final.summary.over:
			break
	owner.close()
	var settlement: Dictionary = final.summary.settlement
	if not _check(settlement.get("kind") == "objective_success" and settlement.reason == "objective_conditions_met"
			and settlement.operation_id == prepared.operation_id, "host command path reaches real objective under same identity"):
		return
	var recorded := Adapter.make_recording(REQUEST, prepared.operation_id, records, settlement)
	if not _check(recorded.ok, "live receipts form replay input"):
		return
	var path_args := OS.get_cmdline_user_args()
	if not path_args.is_empty():
		var output := FileAccess.open(path_args[0], FileAccess.WRITE)
		if _check(output != null, "write CLI replay fixture"):
			output.store_string(JSON.stringify(recorded.bundle))
			output.close()
	var opened := Adapter.open_replay(JSON.parse_string(JSON.stringify(recorded.bundle)))
	if not _check(opened.ok and not opened.has("owner") and opened.frame.tick == 0, "read-only replay exposes frame and cursor"):
		return
	var replay: RefCounted = opened.replay
	var replay_events: Array = opened.frame.events.duplicate(true)
	opened.frame.projection.operation.route_points.clear()
	var observed: Dictionary
	while true:
		observed = replay.step()
		if not observed.ok:
			_check(false, "replay advance: %s" % observed)
			return
		replay_events.append_array(observed.frame.events)
		if observed.done:
			break
	_check(observed.summary == final.summary and observed.frame.projection == final.frame.projection, "same natural settlement and final projection")
	_check(replay_events == events, "same ordered events, including operation identity")
	_check(replay.step() == {"ok": true, "done": true}, "terminal frame is delivered once")
	replay.close()

func _check(condition: bool, label: String) -> bool:
	_checks += 1
	if not condition:
		_failed = true
		push_error(label)
	return condition
