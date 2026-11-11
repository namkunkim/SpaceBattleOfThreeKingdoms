extends Control

signal exit_requested

const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const ADAPTER_PATH := "res://scripts/first_operation_adapter.gd"
const FLAG := "--pc-first-operation-dev"
const EVENTS_LIMIT := 60
const VERIFY_BUDGET_USEC := 4000
const VERIFY_TICKS_PER_FRAME := 8

var _replay: RefCounted
var _verification: RefCounted
var _verified_bundle: Dictionary
var _adapter: Script
var _frame: Dictionary
var _clock: Label
var _result: Label
var _events: RichTextLabel
var _field: Control
var _play: Button
var _step: Button
var _playing := false
var _finished := false
var _elapsed := 0.0
var _lines: PackedStringArray


func _ready() -> void:
	var layout := VBoxContainer.new()
	add_child(layout)
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 16)
	_clock = Label.new()
	_result = Label.new()
	layout.add_child(_clock)
	layout.add_child(_result)
	var controls := HBoxContainer.new()
	layout.add_child(controls)
	_play = _button(controls, "Play", _toggle)
	_step = _button(controls, "Step one tick", step_replay)
	_button(controls, "Close replay", _leave)
	_field = Control.new()
	_field.custom_minimum_size.y = 220
	_field.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field.draw.connect(_draw_field)
	layout.add_child(_field)
	_events = RichTextLabel.new()
	_events.custom_minimum_size.y = 160
	_events.scroll_following = true
	layout.add_child(_events)
	_controls()
	set_process(false)


func open_file(path: String) -> Dictionary:
	if not OS.get_cmdline_user_args().has(FLAG):
		return _fail("replay_development_only")
	if not is_node_ready() or _replay != null or _verification != null:
		return _fail("replay_viewer_busy")
	var loaded := Codec.read(path)
	if not loaded.ok:
		return loaded
	if not ResourceLoader.exists(ADAPTER_PATH):
		return _fail("replay_adapter_unavailable")
	_adapter = load(ADAPTER_PATH) as Script
	if _adapter == null or not _adapter.can_instantiate() or not _adapter.has_method("open_replay"):
		return _fail("replay_adapter_unavailable")
	var opened: Dictionary = _adapter.open_replay(loaded.bundle)
	if not opened.ok:
		return opened
	_verified_bundle = loaded.bundle
	_verification = opened.replay
	_result.text = "Validating replay…"
	set_process(true)
	return {"ok": true, "pending": true}


# Transfers a dedicated replay, never the active battle owner. No issue,
# queue, save, WorldLink or BattleOutcome operation crosses this boundary.
func attach_playback(replay: RefCounted, frame: Dictionary) -> Dictionary:
	if not is_node_ready() or _replay != null or replay == null:
		return _fail("replay_viewer_busy")
	if not replay.has_method("step") or not replay.has_method("close"):
		return _fail("replay_invalid_session")
	if not _valid_frame(frame):
		replay.close()
		return _fail("replay_invalid_frame")
	_replay = replay
	_finished = false
	_install(frame)
	_controls()
	return {"ok": true}


func step_replay() -> void:
	if _replay == null or _finished:
		return
	var result: Dictionary = _replay.step()
	if not result.ok:
		_show_failure(str(result.get("error", "replay_step_failed")))
		return
	var next: Variant = result.get("frame")
	if not next is Dictionary or not _valid_frame(next) or next.tick != _frame.tick + 1 or next.clock_ms <= _frame.clock_ms:
		_show_failure("replay_invalid_frame")
		return
	_install(next)
	if result.get("done", false) and not _finished:
		_show_failure("replay_missing_settlement")


func _process(delta: float) -> void:
	if _verification != null:
		_verify_slice()
		return
	_elapsed += delta
	var period := 1.0 / maxf(1.0, float(_frame.projection.get("hz", 10)))
	# A slow render frame never triggers an unbounded catch-up loop.
	if _elapsed >= period:
		_elapsed = minf(period, _elapsed - period)
		step_replay()


func _verify_slice() -> void:
	var start := Time.get_ticks_usec()
	for i in VERIFY_TICKS_PER_FRAME:
		var next: Dictionary = _verification.step()
		if not next.ok:
			_show_failure(str(next.get("error", "replay_verification_failed")))
			return
		if next.done:
			_verification.close()
			_verification = null
			var playback: Dictionary = _adapter.open_replay(_verified_bundle)
			_verified_bundle = {}
			_pause()
			if not playback.ok:
				_show_failure(str(playback.error))
				return
			var attached := attach_playback(playback.replay, playback.frame)
			if not attached.ok:
				_show_failure(str(attached.error))
			else:
				_result.text = ""
			return
		_result.text = "Validating replay… %d / %d" % [next.frame.tick, _verified_bundle.max_ticks]
		if Time.get_ticks_usec() - start >= VERIFY_BUDGET_USEC:
			return


func _install(value: Dictionary) -> void:
	_frame = value.duplicate(true)
	_clock.text = "Replay | Tick %d | %.1f s" % [_frame.tick, _frame.clock_ms / 1000.0]
	for event: Variant in _frame.events:
		if event is Dictionary:
			_lines.append("%d  %s" % [event.get("tick", _frame.tick), event.get("kind", "?")])
	while _lines.size() > EVENTS_LIMIT:
		_lines.remove_at(0)
	_events.text = "\n".join(_lines)
	var projection: Dictionary = _frame.projection
	var operation: Dictionary = projection.get("operation", {})
	var outcome: Dictionary = projection.get("outcome", {})
	var terminal: Dictionary = operation.get("settlement", _frame.get("settlement", {}))
	if terminal.is_empty() and outcome.get("over", false):
		terminal = outcome.get("result", {})
	if not terminal.is_empty():
		_finished = true
		_result.text = "%s / %s\n%s" % [terminal.get("kind", ""), terminal.get("reason", ""), terminal.get("id", "")]
		_pause()
	_field.queue_redraw()
	_controls()


func _draw_field() -> void:
	_field.draw_rect(Rect2(Vector2.ZERO, _field.size), Color("#182536"))
	if _frame.is_empty():
		return
	var projection: Dictionary = _frame.projection
	var operation: Dictionary = projection.get("operation", {})
	var scale_factor := minf(_field.size.x / 1700.0, _field.size.y / 1150.0)
	var origin := (_field.size - Vector2(1700, 1150) * scale_factor) * 0.5
	var path := PackedVector2Array()
	for point: Variant in operation.get("route_points", []):
		if point is Vector2 and point.is_finite():
			path.append(origin + point * scale_factor)
	if path.size() > 1:
		_field.draw_polyline(path, Color("#a9b6c5"), 2.0)
	for row: Variant in projection.get("squadrons", []):
		if not row is Dictionary or row.get("dead", false) or row.get("out", ""):
			continue
		var point: Variant = row.get("pos")
		if point is Vector2 and point.is_finite():
			var color := Color.CORNFLOWER_BLUE if row.get("side") == 0 else Color.ORANGE_RED
			_field.draw_circle(origin + point * scale_factor, 5.0, color)


func _button(parent: Control, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _toggle() -> void:
	if _playing:
		_pause()
	elif _replay != null and not _finished:
		_playing = true
		_elapsed = 0.0
		set_process(true)
	_controls()


func _pause() -> void:
	_playing = false
	set_process(false)


func _controls() -> void:
	_play.text = "Pause" if _playing else "Play"
	_play.disabled = _replay == null or _finished
	_step.disabled = _replay == null or _finished or _playing


func _show_failure(error: String) -> void:
	_result.text = error
	_close_replay()
	_controls()


func _close_replay() -> void:
	_pause()
	if _verification != null:
		_verification.close()
		_verification = null
	_verified_bundle = {}
	if _replay != null:
		_replay.close()
		_replay = null


func _leave() -> void:
	_close_replay()
	exit_requested.emit()
	queue_free()


func _exit_tree() -> void:
	_close_replay()


static func _valid_frame(frame: Dictionary) -> bool:
	return (typeof(frame.get("tick")) == TYPE_INT and frame.tick >= 0
		and typeof(frame.get("clock_ms")) == TYPE_INT and frame.clock_ms >= 0
		and frame.get("projection") is Dictionary and frame.get("events") is Array)


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "path": "replay"}

