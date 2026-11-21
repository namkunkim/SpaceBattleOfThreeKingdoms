extends RefCounted
## Replay owns its own simulation. Only a completed worker can publish a verified session.
const Replay := preload("res://scripts/campaign/open_jump_restore_job.gd")
const CANCELLED := {"ok": false, "error": "checkpoint_cancelled"}

var _thread: Thread
var _lock := Mutex.new()
var _cancelled := false
var _progress := {"ok": true, "done": false, "tick": 0, "total": 0}
var _start_error: Error

func _init(path: String) -> void:
	# Initialize the shared layout cache before the worker can read it.
	BundleLayout.offsets(1, 0, 1.0)
	var thread := Thread.new()
	_start_error = thread.start(_replay.bind(path))
	if _start_error == OK:
		_thread = thread

func poll() -> Dictionary:
	if _thread == null:
		return {"ok": false, "error": "checkpoint_worker_start_failed", "code": _start_error}
	if _thread.is_alive():
		_lock.lock()
		var progress := _progress.duplicate()
		progress.cancelling = _cancelled
		_lock.unlock()
		return progress
	var result: Dictionary = _thread.wait_to_finish()
	_thread = null
	return CANCELLED if _is_cancelled() else result

func request_cancel() -> void:
	_lock.lock()
	_cancelled = true
	_lock.unlock()

func cancel_and_join() -> void:
	if _thread == null:
		return
	request_cancel()
	_thread.wait_to_finish()
	_thread = null

func _is_cancelled() -> bool:
	_lock.lock()
	var cancelled := _cancelled
	_lock.unlock()
	return cancelled

func _replay(path: String) -> Dictionary:
	var replay := Replay.new(path)
	while not _is_cancelled():
		var result := replay.step()
		if not result.ok or result.done:
			return result
		_lock.lock()
		_progress = result
		_lock.unlock()
	replay.cancel()
	return CANCELLED