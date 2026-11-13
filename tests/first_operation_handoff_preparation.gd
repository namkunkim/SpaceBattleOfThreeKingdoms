extends SceneTree

const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Host := preload("res://scripts/first_operation_host.gd")
const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Slot := preload("res://scripts/first_operation_save_store.gd")

var _checks := 0
var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var profile := OS.get_environment("SBTK_HANDOFF_PROFILE").replace("\\", "/")
	var user_path := ProjectSettings.globalize_path("user://").replace("\\", "/")
	if _expect(not profile.is_empty() and user_path.begins_with(profile + "/"),
			"use an isolated Godot user profile"):
		var clean := true
		for path in [Host.PRODUCT_SLOT_PATH, Ledger.PRODUCT_SLOT_PATH]:
			clean = clean and not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".previous")
		if _expect(clean, "product checkpoint and ledger generations are absent"):
			_verify()
	print("P02_P03_HANDOFF_PREPARATION checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _verify() -> void:
	var first := Adapter.prepare_fresh(Product.REQUEST)
	if not _expect(first.ok, "prepare the approved Red Cliffs v1 request"):
		return
	var parent: RefCounted = first.owner
	var c0: Dictionary = parent.publish()
	if not _expect(c0.ok, "publish the first operation"):
		return
	var initial := _capture(parent)
	if initial.is_empty():
		return
	if not _expect(Adapter.queue(parent, {"kind": "withdraw", "side": 0}).ok and Adapter.advance(parent).ok
			and Adapter.queue(parent, {"kind": "finalize_withdrawal", "side": 0}).ok,
			"apply Withdraw at local tick zero and queue Finalize withdrawal"):
		return
	var old := _capture(parent)
	if old.is_empty() or not _expect(old.tick == 1 and old.clock_ms == 100
			and old.commands == [{"tick": 0, "batch": [{"kind": "withdraw"}]}]
			and old.pending == [{"kind": "finalize_withdrawal"}]
			and old.event_cursor > initial.event_cursor and old.proposal_serial > initial.proposal_serial,
			"first operation changes both cursors and owns its applied and pending commands"):
		return
	if not _expect(Slot.write(old, Host.PRODUCT_SLOT_PATH).ok
			and Host.read_saved_battle(true).ok, "save a resumable first-operation checkpoint"):
		return
	var terminal := Adapter.advance(parent)
	if not _expect(terminal.ok and terminal.summary.over, "reach the first operation's terminal frame"):
		return
	var settlement: Dictionary = terminal.summary.settlement
	if not _expect(settlement.operation_id == first.operation_id
			and settlement.id == first.operation_id + "/settlement" and settlement.clock_ms == 200
			and settlement.kind == "failure" and settlement.reason == "facility_never_secured",
			"observe the approved early-withdrawal settlement"):
		return
	var brief := BattleBrief.new()
	brief.select_first_operation_product()
	var outcome := BattleOutcome.from_operation(settlement, brief, terminal.summary.clock_ms)
	if not _expect(outcome != null, "convert terminal settlement with the product outcome contract"):
		return
	var ledger_hash := _check_ledger(outcome)
	if ledger_hash.is_empty():
		return
	_expect(Host.read_saved_battle(true).get("error") == "checkpoint_already_settled",
		"product save gate rejects a checkpoint for the settled operation")
	parent.close()

	var unsupported := Product.REQUEST.duplicate()
	unsupported.definition_version += 1
	_expect(Adapter.prepare_fresh(unsupported).get("error") == "unknown_definition_version",
		"an unapproved definition version cannot start through the product adapter")
	# The control is a second explicit launch of Red Cliffs v1 via the same adapter.
	var second := Adapter.prepare_fresh(Product.REQUEST)
	if not _expect(second.ok and second.operation_id != first.operation_id,
			"prepare the same approved operation with a fresh instance identity"):
		return
	var next: RefCounted = second.owner
	var next_c0: Dictionary = next.publish()
	if not _expect(next_c0.ok and next_c0.frame == c0.frame,
			"new launch matches original C0 projection, event stream, phase and metadata"):
		return
	var next_initial := _capture(next)
	if next_initial.is_empty():
		return
	for key in ["request", "rules_digest", "source_digest", "effective_digest"]:
		_expect(next_initial[key] == initial[key], "fresh preparation recomputes the same %s" % key)
	_expect(next_initial.operation_id == second.operation_id and next_initial.state_digest != initial.state_digest,
		"the state witness is scoped to the new identity")
	_expect(next_initial.tick == 0 and next_initial.clock_ms == 0 and next_initial.commands.is_empty()
		and next_initial.pending.is_empty() and next_initial.event_cursor == initial.event_cursor
		and next_initial.proposal_serial == initial.proposal_serial,
		"tick, clock, applied commands, pending commands and both cursors begin at C0")

	var saved := _check_local_resume(next, next_c0.frame, old)
	if not saved.is_empty():
		_expect(Host.read_saved_battle(true).ok, "the new identity remains resumable after parent settlement")
		_expect(FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH) == ledger_hash,
			"new launch, command restore and empty tick preserve the settlement ledger bytes")
	next.close()


func _check_ledger(outcome: BattleOutcome) -> String:
	var consumed := Ledger.consume(outcome, Ledger.PRODUCT_SLOT_PATH)
	if not _expect(consumed.ok and consumed.applied, "publish the first operation's ledger record"):
		return ""
	var ledger_hash := FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH)
	var repeated := Ledger.consume(outcome, Ledger.PRODUCT_SLOT_PATH)
	_expect(repeated.ok and not repeated.applied and repeated.outcome.to_dict() == outcome.to_dict(),
		"same settlement ID and contents publish once")
	var conflict := BattleOutcome.from_dict(outcome.to_dict())
	conflict.reason = "conflicting_test_payload"
	_expect(Ledger.consume(conflict, Ledger.PRODUCT_SLOT_PATH).get("error") == "settlement_id_conflict",
		"same settlement ID with different contents is rejected")
	_expect(not ledger_hash.is_empty() and FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH) == ledger_hash
		and not FileAccess.file_exists(Ledger.PRODUCT_SLOT_PATH + ".previous"),
		"duplicate and conflict leave the only ledger generation byte-identical")
	return ledger_hash


func _check_local_resume(owner: RefCounted, c0: Dictionary, old: Dictionary) -> Dictionary:

	var ids: Array = []
	for row: Dictionary in c0.projection.squadrons:
		if row.side == 0 and not row.get("dead", false) and not row.get("out", ""):
			ids.append(row.id)
	var stop := {"kind": "stop", "side": 0, "ids": ids}
	var move := {"kind": "move", "side": 0, "ids": ids, "point": c0.projection.operation.route_points[1]}
	if not _expect(Adapter.queue(owner, stop).ok and Adapter.advance(owner).ok
			and Adapter.queue(owner, move).ok and Adapter.advance(owner).ok and Adapter.queue(owner, stop).ok,
			"new operation reuses local tick zero and queues its own third command"):
		return {}
	var saved := _capture(owner)
	if saved.is_empty() or not _expect(saved.tick == 2 and saved.commands == [
			{"tick": 0, "batch": [{"kind": "stop"}]},
			{"tick": 1, "batch": [{"kind": "move", "goal": 1}]}] and saved.pending == [{"kind": "stop"}],
			"new operation owns the two applied batches and one pending command"):
		return {}
	if not _expect(Slot.write(saved, Host.PRODUCT_SLOT_PATH).ok, "persist the second operation's local cursor"):
		return {}
	var slot_hash := FileAccess.get_sha256(Host.PRODUCT_SLOT_PATH)
	# Adapter restore opens the identity in the packet. Rebinding a packet to a
	# different identity must fail witness validation before a candidate publishes.
	var rebound := old.duplicate(true)
	rebound.operation_id = saved.operation_id
	var rejected := _restore(rebound)
	if rejected.ok:
		rejected.owner.close()
	_expect(rejected.get("error") == "checkpoint_state_mismatch"
		and rejected.get("path") == "packet.state_digest" and _capture(owner) == saved
		and FileAccess.get_sha256(Host.PRODUCT_SLOT_PATH) == slot_hash,
		"retagged first-operation packet fails its witness and preserves the live owner and slot")
	var uninterrupted := Adapter.advance(owner)
	var advanced := _capture(owner)
	if not _expect(uninterrupted.ok and not advanced.is_empty() and advanced.commands == saved.commands + [
			{"tick": saved.tick, "batch": saved.pending}] and advanced.pending.is_empty(),
			"uninterrupted advance appends the pending batch once"):
		return {}
	var read := Host.read_saved_battle(true)
	if not _expect(read.ok, "read the second operation's persisted cursor"):
		return {}
	var result := _restore(read.payload)
	if not _expect(result.ok, "restore the second operation from its own slot"):
		return {}
	var restored: RefCounted = result.owner
	_expect(restored.publish().ok and _capture(restored) == saved, "restore the exact operation-local packet")
	_expect(Adapter.advance(restored) == uninterrupted and _capture(restored) == advanced,
		"restored pending batch applies once with the same frame and event order")
	_expect(Adapter.advance(restored).ok, "advance one more tick without input")
	var empty := _capture(restored)
	_expect(not empty.is_empty() and empty.tick == advanced.tick + 1 and empty.pending.is_empty()
		and empty.commands == advanced.commands and FileAccess.get_sha256(Host.PRODUCT_SLOT_PATH) == slot_hash,
		"empty tick adds no command and restore does not rotate the slot")
	restored.close()
	return saved


func _capture(owner: RefCounted) -> Dictionary:
	var captured: Dictionary = owner.capture_checkpoint()
	return captured.packet if _expect(captured.ok, "capture checkpoint") else {}


func _restore(packet: Dictionary) -> Dictionary:
	var begun := Adapter.begin_restore(packet)
	if not begun.ok:
		return begun
	var result: Dictionary = begun.job.step(100000)
	while result.ok and not result.done:
		result = begun.job.step(100000)
	return result


func _expect(condition: bool, label: String) -> bool:
	_checks += 1
	print("P02_P03_HANDOFF_CHECK ", condition, " ", label)
	if not condition:
		_failures += 1
	return condition
