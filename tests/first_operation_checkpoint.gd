extends SceneTree

const Dev := preload("res://core/battle/first_operation_dev.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const Preparer := preload("res://core/battle/first_operation_preparer.gd")
const REQUEST := {
	"route_id": "front", "mode": "direct", "seed": 208, "difficulty": "standard",
	"definition_version": 1, "definition_id": "red-cliffs-first-operation-dev-v1",
	"roster_id": "red-cliffs-dev-roster-v1", "capability": "pc/first-operation-dev/1",
}

var _checks := 0
var _failed := false
var _runtime: RefCounted

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2:
		if args[0] == "write":
			_write_late(args[1])
		elif args[0] == "read":
			_read_late(args[1])
		elif args[0] == "previous":
			_read_previous(args[1])
		else:
			_check(false, "unsupported probe mode")
	elif args.is_empty():
		_round_trip()
	else:
		_check(false, "expected write/read/previous and a temporary path")
	print("first_operation_checkpoint: %d checks, passed=%s" % [_checks, not _failed])
	quit(1 if _failed else 0)

func _observe_runtime(effective: Dictionary, selection: Dictionary, request: Dictionary) -> Dictionary:
	var built := Dev._build_runtime(effective, selection, request)
	_runtime = built.get("runtime")
	return built

func _round_trip() -> void:
	var fresh := Preparer.new(Dev._resolve, _observe_runtime, Dev.CAPABILITY).prepare_fresh(REQUEST)
	if not fresh.get("ok", false):
		_check(false, "fresh owner: %s" % fresh)
		return
	var owner: RefCounted = fresh.owner
	_check(owner.capture_checkpoint().get("error") == "owner_not_published", "prepared candidate cannot capture")
	var initial: Dictionary = owner.publish().frame
	var proposal_frame: Dictionary = _runtime._policy_frame({}, _runtime._progress, {}, "")
	proposal_frame.tick = 1
	proposal_frame.clock_ms = 100
	var proposal: Dictionary = _runtime._policy.propose_tick(proposal_frame)
	_check(proposal.ok and owner.capture_checkpoint().get("error") == "checkpoint_busy", "in-flight policy proposal cannot save")
	_check(_runtime._policy.discard_tick(proposal.revision).ok, "discard the private policy proposal")
	var ids: Array = initial.projection.squadrons.map(func(row): return row.id)
	var points: Array = initial.projection.operation.route_points
	_check(owner.queue({"side": 0, "kind": "move", "ids": ids, "point": points[2]}).ok, "queue first route command")
	for tick in 25:
		owner.advance()
	var moving: Dictionary = owner.capture_checkpoint()
	var mid_leg := Dev.prepare_restore(_json_round_trip(moving.packet))
	if mid_leg.get("ok", false):
		_check(mid_leg.owner.publish().frame.projection == owner.read_projection().projection, "mid-leg pose survives restore")
		mid_leg.owner.close()
	else:
		_check(false, "mid-leg restore failed: %s" % mid_leg)
	for tick in 1225:
		owner.advance()
	var drained: Array = owner.drain_events().events
	_check(drained.any(func(row): return row.kind == "facility_active"), "consume earlier policy events")
	_check(owner.summary().summary.reserve.status == "scheduled", "R remains scheduled at checkpoint")
	_check(owner.queue({"side": 0, "kind": "withdraw"}).ok, "withdraw pending at checkpoint")
	var saved: Dictionary = owner.capture_checkpoint()
	if not saved.get("ok", false):
		_check(false, "capture failed: %s" % saved)
		owner.close()
		return
	var packet: Dictionary = saved.packet
	_check(packet.proposal_serial == packet.tick + 1, "discarded proposal serial is retained")
	_check(packet.tick == 1250 and packet.clock_ms == 125000 and packet.request == REQUEST, "saved logical time and complete request")
	_check(packet.commands == [{"tick": 0, "batch": [{"kind": "move", "goal": 2}]}], "applied commands recorded separately")
	_check(packet.pending == [{"kind": "withdraw"}] and packet.event_cursor > 0, "pending command and consumed cursor captured")
	var malformed := packet.duplicate(true)
	malformed.rules_digest = "0".repeat(64)
	_check(Dev.prepare_restore(malformed).get("error") == "checkpoint_rules_mismatch", "changed rules reject")
	malformed = packet.duplicate(true)
	malformed.source_digest = "0".repeat(64)
	_check(Dev.prepare_restore(malformed).get("error") == "checkpoint_source_mismatch", "changed input rejects")
	malformed = packet.duplicate(true)
	malformed.pending[0].kind = "finalize_withdrawal"
	_check(Dev.prepare_restore(malformed).get("error") == "checkpoint_replay_command_rejected", "semantically invalid pending command rejects")
	malformed = packet.duplicate(true)
	malformed.event_cursor += 1000
	_check(Dev.prepare_restore(malformed).get("error") == "checkpoint_event_cursor_mismatch", "unreachable event cursor rejects")
	malformed = packet.duplicate(true)
	malformed.state_digest = "0".repeat(64)
	_check(Dev.prepare_restore(malformed).get("error") == "checkpoint_state_mismatch", "divergent replay witness rejects")
	_check(owner.capture_checkpoint().packet == packet, "all failed restores preserve the existing owner")
	var restored := Dev.prepare_restore(_json_round_trip(packet))
	if not restored.get("ok", false):
		_check(false, "restore failed: %s" % restored)
		owner.close()
		return
	var cancelled := Dev.begin_restore(_json_round_trip(packet))
	if not cancelled.get("ok", false):
		_check(false, "start cancelled test job: %s" % cancelled)
	else:
		var progress: Dictionary = cancelled.job.step(1)
		_check(progress.ok and not progress.done and progress.tick == 1 and progress.total == 1250 and not progress.has("owner"),
			"budget yields between committed ticks without exposing candidate")
		cancelled.job.cancel()
		cancelled.job.cancel()
		_check(cancelled.job.step(1000).get("error") == "restore_job_cancelled", "cancel is idempotent")
		_check(owner.capture_checkpoint().packet == packet, "cancel leaves the live owner unchanged")
	var sliced := _complete_job(Dev.begin_restore(_json_round_trip(packet)), 1800)
	if sliced.get("ok", false):
		var sliced_owner: RefCounted = sliced.owner
		_check(sliced_owner.preview_initial_frame() == restored.owner.preview_initial_frame(), "sliced and synchronous resume frames match")
		sliced_owner.publish()
		_check(sliced_owner.capture_checkpoint().packet == packet, "sliced and synchronous authority matches")
		sliced_owner.close()
	else:
		_check(false, "sliced restore failed: %s" % sliced)
	malformed = packet.duplicate(true)
	malformed.state_digest = "0".repeat(64)
	_check(_complete_job(Dev.begin_restore(malformed), 1800).get("error") == "checkpoint_state_mismatch", "late sliced error rejects candidate")
	_check(owner.capture_checkpoint().packet == packet, "late sliced error preserves the live owner")
	var resumed: RefCounted = restored.owner
	var preview: Dictionary = resumed.preview_initial_frame().frame
	_check(preview.phase == "resume" and preview.tick == 1250 and preview.clock_ms == 125000, "restored resume frame before publication")
	_check(preview.projection == owner.read_projection().projection and preview.events.is_empty(), "preview uses saved state without delivering events")
	_check(resumed.advance().get("error") == "owner_not_published", "restored candidate is gated")
	_check(resumed.publish().frame == preview and resumed.publish().get("error") == "owner_already_published", "resume frame publishes once")
	_check(resumed.capture_checkpoint().packet == packet, "JSON round trip reconstructs exact checkpoint")
	_check(owner.advance().ok and resumed.advance().ok, "both advance with the saved pending command")
	_check(resumed.summary() == owner.summary() and resumed.read_projection() == owner.read_projection(), "same continuation through R entry and withdrawal")

	var after: Dictionary = resumed.capture_checkpoint().packet
	var unread := Dev.prepare_restore(_json_round_trip(after))
	if unread.get("ok", false):
		var later: RefCounted = unread.owner
		later.publish()
		var events: Array = owner.drain_events().events
		_check(events == resumed.drain_events().events and events == later.drain_events().events, "restored unread events retain order, IDs and data")
		_check(events.any(func(row): return row.kind == "withdrawal_started") and events.any(func(row): return row.kind == "reinforcement_entered"), "real policy events resumed")
		_check(later.drain_events().events.is_empty(), "unread events drain once")
		later.close()
	else:
		_check(false, "restore with unread events: %s" % unread)
	_check(owner.queue({"side": 0, "kind": "finalize_withdrawal"}).ok and resumed.queue({"side": 0, "kind": "finalize_withdrawal"}).ok, "same subsequent command accepted")
	_check(owner.advance().ok and resumed.advance().ok, "same subsequent command commits")
	_check(owner.summary() == resumed.summary() and owner.summary().summary.over, "same terminal operation identity and settlement")
	_check(owner.capture_checkpoint().get("error") == "checkpoint_terminal", "terminal owner cannot save")
	malformed = after.duplicate(true)
	malformed.commands.append({"tick": after.tick, "batch": [{"kind": "finalize_withdrawal"}]})
	malformed.tick += 1
	malformed.clock_ms += 100
	malformed.proposal_serial += 1
	_check(Dev.prepare_restore(malformed).get("error") == "checkpoint_terminal", "early terminal replay cannot restore")
	owner.close()
	resumed.close()

func _write_late(path: String) -> void:
	var result := Dev.prepare_fresh(REQUEST)
	if not result.ok:
		_check(false, "late fresh owner: %s" % result)
		return
	var owner: RefCounted = result.owner
	owner.publish()
	for tick in 11999:
		var advanced: Dictionary = owner.advance()
		if not advanced.ok:
			_check(false, "late advance failed: %s" % advanced)
			owner.close()
			return
	var start := Time.get_ticks_msec()
	var saved: Dictionary = owner.capture_checkpoint()
	_check(saved.get("ok", false), "capture near deadline")
	if saved.get("ok", false):
		var file := FileAccess.open(path, FileAccess.WRITE)
		_check(file != null, "temporary packet file is writable")
		if file != null:
			file.store_string(JSON.stringify(saved.packet))
		print("late capture_ms=", Time.get_ticks_msec() - start, " tick=", saved.packet.tick)
	owner.close()

func _complete_job(begun: Dictionary, budget: int) -> Dictionary:
	if not begun.ok:
		return begun
	var job: RefCounted = begun.job
	var slices := 0
	var maximum_usec := 0
	while true:
		var start := Time.get_ticks_usec()
		var result: Dictionary = job.step(budget)
		maximum_usec = maxi(maximum_usec, Time.get_ticks_usec() - start)
		slices += 1
		if not result.ok:
			return result
		if result.done:
			job.cancel()
			result.slices = slices
			result.maximum_usec = maximum_usec
			return result
	return {"ok": false}

func _read_previous(path: String) -> void:
	var envelope: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not envelope is Dictionary or not envelope.get("body") is String:
		_check(false, "previous slot envelope")
		return
	var packet: Variant = JSON.parse_string(envelope.body)
	if not packet is Dictionary:
		_check(false, "previous slot payload")
		return
	_check(Checkpoint._compatible_rules(packet.rules_digest, Checkpoint.rules_digest()), "previous digest matches pinned current inventory")
	_check(not Checkpoint._compatible_rules(packet.rules_digest, "0".repeat(64)), "future or unknown code does not accept the old digest")
	var restored := _complete_job(Dev.begin_restore(packet), 2500)
	if not restored.get("ok", false):
		_check(false, "previous Windows slot restores: %s" % restored)
		return
	var owner: RefCounted = restored.owner
	var frame: Dictionary = owner.publish().frame
	var current: Dictionary = owner.capture_checkpoint().packet
	_check(frame.tick == int(packet.tick) and frame.clock_ms == int(packet.clock_ms), "previous Windows clock is intact")
	_check(current.operation_id == packet.operation_id and current.state_digest == packet.state_digest, "previous Windows authority is exact")
	_check(current.rules_digest == Checkpoint.rules_digest() and current.rules_digest != packet.rules_digest, "new captures use current inventory digest")
	print("previous Windows save verified at tick ", frame.tick)
	owner.close()

func _read_late(path: String) -> void:
	var packet: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var start := Time.get_ticks_msec()
	var restored := _complete_job(Dev.begin_restore(packet), 2500)
	_check(restored.get("ok", false), "cross-process restore: %s" % restored.get("error", "ok"))
	if not restored.get("ok", false):
		return
	var elapsed := Time.get_ticks_msec() - start
	var owner: RefCounted = restored.owner
	var frame: Dictionary = owner.publish().frame
	_check(frame.tick == 11999 and frame.clock_ms == 1199900, "late resume clock")
	var saved: Dictionary = owner.capture_checkpoint()
	_check(saved.ok and saved.packet.state_digest == packet.state_digest, "cross-process witness matches")
	_check(owner.advance().ok and owner.summary().summary.settlement.reason == "deadline", "resumed tick reaches deadline normally")
	_check(owner.capture_checkpoint().get("error") == "checkpoint_terminal", "deadline save rejected")
	print("late restore_ms=", elapsed, " tick=", frame.tick, " slices=", restored.slices, " max_slice_usec=", restored.maximum_usec)
	owner.close()

func _json_round_trip(packet: Dictionary) -> Variant:
	return JSON.parse_string(JSON.stringify(packet))

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
