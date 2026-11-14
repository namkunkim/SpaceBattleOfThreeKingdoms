extends RefCounted

const Owner := preload("res://scripts/first_operation_v2_owner.gd")
const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")


class RestoreJob extends RefCounted:
	var _owner: Owner
	var _expected: Dictionary
	var _cursor := 0
	var _tick := 0
	var _terminal := false

	func _init(candidate: Owner, record: Dictionary, terminal: bool) -> void:
		_owner = candidate
		_expected = record
		_terminal = terminal

	func step(budget_usec: int) -> Dictionary:
		if _owner == null or budget_usec <= 0:
			return _fail("v2_restore_unavailable")
		var start := Time.get_ticks_usec()
		while _tick < _expected.tick:
			if _cursor < _expected.history.size() and _expected.history[_cursor].tick == _tick:
				if not _queue_batch(_expected.history[_cursor].batch):
					return _reject("v2_restore_command_rejected")
				_cursor += 1
			var advanced := _owner._advance_recorded()
			if not advanced.ok:
				return _reject("v2_restore_advance_failed")
			_owner._take_events()
			_tick += 1
			if Time.get_ticks_usec() - start >= budget_usec:
				return {"ok": true, "done": false, "tick": _tick, "total": _expected.tick}
		if _cursor != _expected.history.size() or not _queue_batch(_expected.pending):
			return _reject("v2_restore_pending_rejected")
		var captured := _owner._record()
		if not captured.ok or captured.record != _expected:
			return _reject("v2_restore_witness_mismatch")
		if _terminal:
			# Replay validation returns facts only. Playback uses a fresh owner.
			var facts: Dictionary = captured.record.settlement
			cancel()
			return {"ok": true, "done": true, "settlement": facts}
		var restored := _owner
		restored._set_restored_frame()
		_owner = null
		_expected = {}
		return {"ok": true, "done": true, "owner": restored}

	func _queue_batch(batch: Array) -> bool:
		for command: Dictionary in batch:
			if not _owner._queue_record(command).ok:
				return false
		return true

	func _reject(error: String) -> Dictionary:
		cancel()
		return _fail(error)

	func cancel() -> void:
		if _owner != null:
			_owner.close()
			_owner = null
		_expected = {}


	static func _fail(error: String) -> Dictionary:
		return {"ok": false, "error": error, "path": "first_operation_v2_restore"}


static func begin_restore(bytes: PackedByteArray) -> Dictionary:
	return _begin(bytes, Codec.SAVE_FORMAT)


static func begin_replay_validation(bytes: PackedByteArray) -> Dictionary:
	return _begin(bytes, Codec.REPLAY_FORMAT)


static func _begin(bytes: PackedByteArray, format: String) -> Dictionary:
	var decoded := Codec.decode(bytes, format)
	if not decoded.ok:
		return decoded
	var prepared := Owner._prepare_identity(decoded.record.operation_id)
	if not prepared.ok:
		return prepared
	return {"ok": true, "job": RestoreJob.new(prepared.owner, decoded.record, format == Codec.REPLAY_FORMAT)}
