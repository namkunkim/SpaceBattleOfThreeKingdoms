extends RefCounted

enum State { PREPARED, LIVE, CLOSED }

var _state := State.PREPARED
var _runtime: RefCounted
var _initial_frame: Dictionary
var _meta: Dictionary

func _init(runtime: RefCounted, frame: Dictionary) -> void:
	_runtime = runtime
	_initial_frame = frame
	_meta = frame.get("meta", {}).duplicate(true)

# Inspect before installing anything in the host. The caller owns this copy.
func preview_initial_frame() -> Dictionary:
	if _state != State.PREPARED:
		return _unavailable()
	return {"ok": true, "frame": _initial_frame.duplicate(true)}

# Call after host preflight. The host installs this frame and routes commands
# to this owner together, then closes the displaced owner. A host that cancels
# before installation must close this candidate.
func publish() -> Dictionary:
	if _state != State.PREPARED:
		return _unavailable()
	_state = State.LIVE
	var frame := _initial_frame
	_initial_frame = {}
	return {"ok": true, "frame": frame}

func advance() -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	return _runtime.advance()

func issue(command: Dictionary) -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	return _runtime.issue(command.duplicate(true))

func queue(command: Dictionary) -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	return _runtime.queue(command.duplicate(true))

func summary() -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	return _runtime.summary().duplicate(true)

func read_projection() -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	return _runtime.read_projection(0).duplicate(true)

func drain_events() -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	return _runtime.drain_events_for(0).duplicate(true)

func capture_checkpoint() -> Dictionary:
	if _state != State.LIVE:
		return _unavailable()
	if not _runtime.has_method("checkpoint_packet"):
		return {"ok": false, "error": "unsupported_checkpoint", "path": "owner"}
	return _runtime.checkpoint_packet(_meta)

# The validated packet goes to a fresh candidate that has never been published.
# The restored unread events stay in its queue for the host's first drain.
func _begin_prepared_checkpoint(packet: Dictionary) -> Dictionary:
	if _state != State.PREPARED:
		return _unavailable()
	if not _runtime.has_method("finish_restore_replay"):
		return {"ok": false, "error": "unsupported_checkpoint", "path": "owner"}
	for key in ["source_digest", "effective_digest"]:
		if packet[key] != _meta[key]:
			return {"ok": false, "error": "checkpoint_source_mismatch", "path": "packet." + key}
	return {"ok": true}

func _replay_checkpoint_tick(batch: Array, path: String) -> Dictionary:
	if _state != State.PREPARED:
		return _unavailable()
	return _runtime.replay_tick(batch, path)

func _finish_prepared_checkpoint(packet: Dictionary) -> Dictionary:
	if _state != State.PREPARED:
		return _unavailable()
	var restored: Dictionary = _runtime.finish_restore_replay(packet)
	if not restored.ok:
		return restored
	var state: Dictionary = _runtime.summary().summary
	_initial_frame = {
		"tick": state.tick, "clock_ms": state.clock_ms, "hz": _initial_frame.hz, "phase": "resume",
		"projection": _runtime.read_projection(0).projection, "events": [], "meta": _meta.duplicate(true),
	}
	return {"ok": true}

func close() -> void:
	if _state == State.CLOSED:
		return
	_state = State.CLOSED
	_initial_frame = {}
	var runtime := _runtime
	_runtime = null
	runtime.close()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _runtime != null:
		_runtime.close()

func _unavailable() -> Dictionary:
	var errors := {
		State.PREPARED: "owner_not_published",
		State.LIVE: "owner_already_published",
		State.CLOSED: "owner_closed",
	}
	return {"ok": false, "error": errors[_state], "path": "owner"}
