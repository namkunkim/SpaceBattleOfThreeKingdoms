extends RefCounted

const Runtime := preload("res://core/battle/operation_runtime_adapter.gd")
const Private := preload("res://core/battle/operation_private_state.gd")
const EventReferences := preload("res://scripts/operation_event_references.gd")
const Service := preload("res://core/battle/operation_service_state.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const FORMAT := "pc-restricted-operation-checkpoint/1"

var _owner: OperationPrivateState
var _host_max_ticks := 0


static func create(input: Variant) -> Dictionary:
	var prepared := Runtime.create(input)
	if not prepared.ok:
		return prepared
	return {"ok": true, "session": bind_owner(prepared.owner)}


static func bind_owner(owner: OperationPrivateState, host_max_ticks := 0) -> RefCounted:
	var session: RefCounted = new()
	session._owner = owner
	session._host_max_ticks = host_max_ticks
	return session


func issue(seq: int, command: Variant) -> Dictionary:
	return _submit(seq, command, false)


func queue(seq: int, command: Variant) -> Dictionary:
	return _submit(seq, command, true)


func _submit(seq: int, command: Variant, pending: bool) -> Dictionary:
	var state := _owner.observe()
	if not state.ok:
		return state
	var applied: int = state.sim.command_log.size()
	var queued: int = state.sim._queue.size()
	if seq != applied + queued + 1:
		return _fail("command_sequence_mismatch", "seq")
	# In this initial protocol, the applied cursor is a contiguous prefix.
	if not pending and queued != 0:
		return _fail("immediate_behind_pending", "seq")
	return _owner.queue(command) if pending else _owner.issue(command)


func advance() -> Dictionary:
	return _owner.advance()


func observe() -> Dictionary:
	return _owner.observe()


func drain_events() -> Dictionary:
	return _owner.drain_events()


func close() -> void:
	_owner.close()


func write_checkpoint(path: String) -> Dictionary:
	if not _slot_path(path):
		return _fail("restricted_slot_required", "path")
	var captured := _owner.capture_completed()
	if not captured.ok:
		return captured
	if captured.packet.view.state.over:
		return _fail("unsupported_terminal_settlement", "snapshot.state")
	var sim: Dictionary = captured.packet.view.sim
	# The Store handles UTF-8, hashing, size limits and publication. Godot's
	# object-disabled Variant format retains Vector2 and integer dictionary keys.
	var encoded := Marshalls.raw_to_base64(var_to_bytes(captured.packet))
	var payload := {"format": FORMAT, "snapshot": encoded,
		"last_applied_seq": sim.command_log.size(), "last_accepted_seq": sim.command_log.size() + sim._queue.size()}
	if _host_max_ticks > 0:
		if captured.packet.view.state.tick >= _host_max_ticks:
			return _fail("checkpoint_host_tick_limit", "snapshot.state.tick")
		payload["host_max_ticks"] = _host_max_ticks
	return Store.write(payload, path)


func restore_checkpoint(path: String, suffix: Array = []) -> Dictionary:
	if not _slot_path(path):
		return _fail("restricted_slot_required", "path")
	var stored := Store.read(path)
	if not stored.ok:
		return stored
	var payload: Dictionary = stored.payload
	if payload.get("format") != FORMAT or not payload.get("snapshot") is String:
		return _fail("unsupported_operating_checkpoint", "format")
	if _host_max_ticks > 0:
		if payload.size() != 5 or not _same_seq(payload.get("host_max_ticks"), _host_max_ticks):
			return _fail("checkpoint_host_limit_mismatch", "host_max_ticks")
	elif payload.size() != 4:
		return _fail("unsupported_operating_checkpoint", "format")
	var encoded: String = payload.snapshot
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.is_empty() or Marshalls.raw_to_base64(bytes) != encoded:
		return _fail("invalid_snapshot_encoding", "snapshot")
	var snapshot: Variant = bytes_to_var(bytes)
	if not snapshot is Dictionary or var_to_bytes(snapshot) != bytes:
		return _fail("invalid_snapshot_encoding", "snapshot")
	var prepared := Private.prepare(snapshot)
	if not prepared.ok:
		return prepared
	var candidate: OperationPrivateState = prepared.owner
	if not EventReferences.valid(snapshot.view):
		candidate.close()
		return _fail("event_reference", "snapshot.sim._events")
	if snapshot.view.state.over:
		candidate.close()
		return _fail("unsupported_terminal_settlement", "snapshot.state")
	if _host_max_ticks > 0 and snapshot.view.state.tick >= _host_max_ticks:
		candidate.close()
		return _fail("checkpoint_host_tick_limit", "snapshot.state.tick")
	var checked := _queue_suffix(candidate, snapshot, payload, suffix)
	if not checked.ok:
		candidate.close()
		return checked
	var staged := candidate.capture_completed()
	candidate.close()
	if not staged.ok:
		return staged
	# The restricted owner compares context and replaces its live sim only
	# after fully validating the staged state.
	return _owner.restore_completed(staged.packet)


static func _queue_suffix(candidate: OperationPrivateState, snapshot: Dictionary, payload: Dictionary, suffix: Array) -> Dictionary:
	var applied: int = snapshot.view.sim.command_log.size()
	var pending: Array = snapshot.view.sim._queue
	var accepted := applied + pending.size()
	if not _same_seq(payload.get("last_applied_seq"), applied) or not _same_seq(payload.get("last_accepted_seq"), accepted):
		return _fail("checkpoint_cursor_mismatch", "cursor")
	var expected := applied + 1
	for row: Variant in suffix:
		if not row is Dictionary or row.size() != 2 or not _same_seq(row.get("seq"), expected) or not row.has("command"):
			return _fail("invalid_checkpoint_suffix", "suffix")
		if expected <= accepted:
			if not Service._same(pending[expected - applied - 1], row.command):
				return _fail("conflicting_pending_command", "suffix")
		else:
			var queued := candidate.queue(row.command)
			if not queued.ok:
				return queued
		expected += 1
	return {"ok": true}


static func _same_seq(value: Variant, expected: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and value == expected


static func _slot_path(path: String) -> bool:
	return path.get_file().ends_with(".pcopstate")


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
