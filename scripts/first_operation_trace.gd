extends RefCounted

const ARG := "--first-operation-trace"
const DIRECTORY := "user://first_operation_traces"

var _file: FileAccess
var _seq := 0
var _last_snapshot_ms := 0


func start(request: Dictionary, frame: Dictionary, restored: bool) -> void:
	var error := DirAccess.make_dir_recursive_absolute(DIRECTORY)
	if error != OK:
		push_warning("[FIRST OPERATION TRACE] Cannot create log directory: %s" % error_string(error))
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var path := "%s/operation-%s-%d-%d.jsonl" % [DIRECTORY, stamp, OS.get_process_id(), Time.get_ticks_usec()]
	_file = FileAccess.open(path, FileAccess.WRITE)
	if _file == null:
		push_warning("[FIRST OPERATION TRACE] Cannot open log: %s" % error_string(FileAccess.get_open_error()))
		return
	_seq = 0
	_last_snapshot_ms = frame.clock_ms
	write(frame, "session_start", {
		"request": request, "route": frame.projection.operation.route_id,
		"hz": frame.hz, "restored": restored, "engine": Engine.get_version_info().string,
	})
	record_frame(frame, true)
	if _file != null:
		print("[FIRST OPERATION TRACE] ", ProjectSettings.globalize_path(path))


func record_frame(frame: Dictionary, initial := false) -> void:
	if _file == null:
		return
	for event in frame.events:
		write(frame, "operation_event", {"event": event})
	if initial or frame.clock_ms - _last_snapshot_ms >= 1000:
		_last_snapshot_ms = frame.clock_ms
		var allies: Array = []
		for row: Dictionary in frame.projection.squadrons:
			if row.side == 0:
				allies.append(row)
		var operation: Dictionary = frame.projection.operation
		write(frame, "snapshot", {"allies": allies, "sites": operation.sites, "withdrawal": operation.withdrawal})


func write(frame: Dictionary, kind: String, data: Dictionary = {}) -> void:
	if _file == null:
		return
	_seq += 1
	var row := {
		"v": 1, "seq": _seq, "wall_time": Time.get_datetime_string_from_system(),
		"mono_ms": Time.get_ticks_msec(), "tick": frame.tick, "sim_ms": frame.clock_ms,
		"kind": kind, "data": data,
	}
	var stored := _file.store_line(JSON.stringify(_json(row)))
	_file.flush()
	if not stored or _file.get_error() != OK:
		push_warning("[FIRST OPERATION TRACE] Cannot write log; recording stopped")
		_file.close()
		_file = null


func close(frame: Dictionary, reason: String) -> void:
	write(frame, "session_closed", {"reason": reason})
	if _file != null:
		_file.close()
		_file = null


func _json(value: Variant) -> Variant:
	if value is Vector2:
		return [value.x, value.y]
	if value is Dictionary:
		var result := {}
		for key in value:
			result[str(key)] = _json(value[key])
		return result
	if value is Array:
		var result := []
		for item in value:
			result.append(_json(item))
		return result
	return value
