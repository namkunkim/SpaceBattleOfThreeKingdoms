extends "res://scripts/first_operation_replay_viewer.gd"

const V2Restore := preload("res://scripts/first_operation_v2_restore.gd")
const V2Storage := preload("res://scripts/first_operation_v2_storage.gd")
const V2Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const V2Owner := preload("res://scripts/first_operation_v2_owner.gd")
const V3Restore := preload("res://scripts/first_operation_v3_restore.gd")
const V3Storage := preload("res://scripts/first_operation_v3_storage.gd")
const V3Codec := preload("res://scripts/first_operation_v3_record_codec.gd")
const V3Owner := preload("res://scripts/first_operation_v3_owner.gd")

var _storage: Script = V2Storage
var _codec: Script = V2Codec
var _restore: Script = V2Restore
var _owner_class: Script = V2Owner
var _title := "적벽 v2"

var _job: RefCounted
var _record: Dictionary


class Playback extends RefCounted:
	var _owner: RefCounted
	var _record: Dictionary
	var _tick := 0
	var _cursor := 0

	func _init(owner: RefCounted, record: Dictionary) -> void:
		_owner = owner
		_record = record

	func step() -> Dictionary:
		if _owner == null:
			return _fail("v2_replay_closed")
		var history: Array = _record.history
		if _cursor < history.size() and history[_cursor].tick == _tick:
			for command: Dictionary in history[_cursor].batch:
				if not _owner._queue_record(command).ok:
					close()
					return _fail("v2_replay_command_rejected")
			_cursor += 1
		var advanced: Dictionary = _owner.advance()
		if not advanced.ok:
			close()
			return advanced
		_tick += 1
		var frame := {"tick": _tick, "clock_ms": _tick * V2Codec.TICK_MS,
			"events": _owner.drain_events().events, "projection": _owner.read_projection().projection}
		var done: bool = _tick == _record.tick
		if done:
			var captured: Dictionary = _owner.capture_record()
			var matched: bool = captured.ok and captured.record == _record
			close()
			if not matched:
				return _fail("v2_replay_witness_mismatch")
		return {"ok": true, "frame": frame, "done": done}

	func close() -> void:
		if _owner != null:
			_owner.close()
			_owner = null

	static func _fail(error: String) -> Dictionary:
		return {"ok": false, "error": error, "path": "v2_replay"}


func configure(multi_formation: bool) -> void:
	if multi_formation:
		_storage = V3Storage
		_codec = V3Codec
		_restore = V3Restore
		_owner_class = V3Owner
		_title = "적벽 v2 · 다중 진형"


func open_file(path: String, _product_only := false) -> Dictionary:
	if not is_node_ready() or _replay != null or _job != null:
		return _fail("v2_replay_viewer_busy")
	var loaded: Dictionary = _storage.read_replay(path)
	if not loaded.ok:
		return loaded
	var decoded: Dictionary = _codec.decode(loaded.bytes, _codec.REPLAY_FORMAT)
	if not decoded.ok:
		return decoded
	var verified: Dictionary = _restore.begin_replay_validation(loaded.bytes)
	if not verified.ok:
		return verified
	_record = decoded.record
	_job = verified.job
	_result.text = _title + " 리플레이 검증 중"
	set_process(true)
	return {"ok": true, "pending": true}


func _process(delta: float) -> void:
	if _job == null:
		super._process(delta)
		return
	var checked: Dictionary = _job.step(VERIFY_BUDGET_USEC)
	if not checked.ok:
		_close_replay()
		_show_failure(str(checked.error))
		return
	if not checked.done:
		_result.text = "%d / %d 틱 검증 중" % [checked.tick, checked.total]
		return
	_job = null
	_pause()
	var prepared: Dictionary = _owner_class._prepare_identity(_record.operation_id)
	if not prepared.ok:
		_show_failure(str(prepared.error))
		return
	var candidate: RefCounted = prepared.owner
	var initial: Dictionary = candidate.publish()
	if not initial.ok:
		candidate.close()
		_show_failure(str(initial.error))
		return
	var playback := Playback.new(candidate, _record)
	_record = {}
	var attached := attach_playback(playback, initial.frame)
	if not attached.ok:
		playback.close()
		_show_failure(str(attached.error))
		return
	_result.text = ""


func _close_replay() -> void:
	if _job != null:
		_job.cancel()
		_job = null
	_record = {}
	super._close_replay()
