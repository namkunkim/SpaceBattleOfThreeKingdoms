extends SceneTree

const Owner := preload("res://scripts/first_operation_v2_owner.gd")
const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const Restore := preload("res://scripts/first_operation_v2_restore.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

var passes := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if not _check(Checkpoint.rules_digest() == "b7189ae8f3408fd4e053a792491ac5f6457a520218df2b709c4a8e3986863658",
			"v1 rules digest remains pinned"):
		quit(1)
		return
	var prepared := Owner.prepare_fresh()
	if not _check(prepared.ok, "prepare original v2 owner"):
		quit(1)
		return
	var original: Owner = prepared.owner
	original.publish()
	_check(original.advance().ok and original.capture_record().get("error") == "v2_events_unread", "undrained effects prevent save")
	original.drain_events()
	_check(original.queue(Owner.FORMATION).ok, "original queues formation")
	var queued_record := Codec.encode(original.capture_record().record, Codec.SAVE_FORMAT)
	var cancelled := Restore.begin_restore(queued_record.bytes)
	_check(cancelled.ok and not cancelled.job.step(0).ok, "invalid budget does not publish")
	cancelled.job.cancel()
	_check(not cancelled.job.step(1).ok, "cancelled restore cannot publish")
	var pending := _restore(original)
	if pending == null:
		original.close()
		quit(1)
		return
	_check(pending.publish().ok, "publish verified pending candidate")
	_check(pending.capture_record().record == original.capture_record().record, "pending packet exact before advance")
	_check(_step(pending) and _step(original), "both owners advance queued formation")
	_check(pending.capture_record().record == original.capture_record().record, "restored formation consumed once")
	pending.close()

	for i in 20:
		_step(original)
	var mid := _restore(original)
	if mid == null:
		original.close()
		quit(1)
		return
	var preview := mid.preview_initial_frame()
	_check(preview.ok and preview.frame.phase == "resume" and preview.frame.tick == 22,
		"mid-formation restore hands off actual resume frame")
	mid.publish()
	var rows: Array = mid.read_projection().projection.squadrons
	var squad: Dictionary = rows.filter(func(row): return row.get("squadron_id") == Owner.FORMATION.squadron_id)[0]
	_check(squad.form_to == "FRM-01" and is_equal_approx(squad.form_left_s, 2.9), "mid-formation countdown survives")
	for i in range(22, 51):
		_step(original)
		_step(mid)
	_check(mid.capture_record().record == original.capture_record().record, "mid-formation restore converges")
	mid.close()

	var invalid: Dictionary = original.capture_record().record
	invalid.state_digest = "0".repeat(64)
	var corrupt := Codec.encode(invalid, Codec.SAVE_FORMAT)
	var rejected := _complete(Restore.begin_restore(corrupt.bytes))
	_check(not rejected.ok and rejected.error == "v2_restore_witness_mismatch", "valid-checksum wrong witness rejects")
	_check(original.presentation_identity() == invalid.operation_id, "failed restore leaves original active")
	var ok: bool = original.queue({"kind": "withdraw", "side": 0}).ok and _step(original)
	ok = ok and original.queue({"kind": "finalize_withdrawal", "side": 0}).ok and _step(original)
	if _check(ok and original.summary().summary.over, "enter real terminal v2 result"):
		var record := original.capture_record()
		var encoded := Codec.encode(record.record, Codec.REPLAY_FORMAT)
		if _check(encoded.ok, "encode real terminal recording"):
			var checked := _complete(Restore.begin_replay_validation(encoded.bytes))
			_check(checked.ok and checked.settlement == record.record.settlement and not checked.has("owner"),
				"replay reconstructs exact terminal witness without publishing")
			var wrong: Dictionary = record.record.duplicate(true)
			wrong.settlement.reason = "forged"
			var forged := Codec.encode(wrong, Codec.REPLAY_FORMAT)
			_check(not _complete(Restore.begin_replay_validation(forged.bytes)).ok, "forged terminal reason rejected")
	original.close()
	print("P05_V2_RESTORE_RESULT %d/%d" % [passes, failures + passes])
	quit(0 if failures == 0 else 1)


func _restore(original: Owner) -> Owner:
	var captured := original.capture_record()
	if not _check(captured.ok, "capture committed v2 state"):
		return null
	var bytes := Codec.encode(captured.record, Codec.SAVE_FORMAT)
	if not _check(bytes.ok, "v2 save has a valid envelope"):
		return null
	var begun := Restore.begin_restore(bytes.bytes)
	var done := _complete(begun)
	if not _check(done.ok and done.owner.presentation_identity().is_empty()
			and not done.owner.advance().ok and not done.owner.summary().ok, "restore returns a detached prepared candidate"):
		print(done)
		return null
	return done.owner


func _complete(begun: Dictionary) -> Dictionary:
	if not begun.ok:
		return begun
	for i in 150:
		var result: Dictionary = begun.job.step(1)
		if not result.ok or result.done:
			return result
	begun.job.cancel()
	return {"ok": false, "error": "test_restore_timeout"}


func _step(owner: Owner) -> bool:
	var result := owner.advance()
	owner.drain_events()
	return result.ok


func _check(ok: bool, label: String) -> bool:
	if ok:
		passes += 1
	else:
		failures += 1
	print("P05_V2_RESTORE_CHECK ", ok, " ", label)
	return ok
