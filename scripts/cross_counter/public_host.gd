extends Control

signal returned

const Store := preload("res://scripts/cross_counter/public_slot.gd")
const RuntimePath := "res://scripts/cross_counter/runtime.gd"
const CheckpointPath := "res://scripts/cross_counter/checkpoint.gd"
const RESTORE_BUDGET_USEC := 4000

var _factory: Script
var _checkpoint: Script
var _lease: Store
var _owner: RefCounted
var _restore_job: RefCounted
var _frame: Dictionary
var _operation_id := ""
var _clock := TickClock.new()
var _terminal := false
var _running := false
var _blocked := false
var _closing_requested := false
var _return_requested := false
var _old_auto_quit := true
var _manages_quit := false
var _status: Label
var _clock_label: Label
var _begin_button: Button
var _save_button: Button
var _abandon_button: Button
var _stop_button: Button
var _return_button: Button
var _board: Control


func _ready() -> void:
	set_process(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color("#101a28")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 30)
	column.theme = UiTheme.build()
	add_child(column)
	var title := Label.new()
	title.text = "Cross Counter · 교차 반격"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	_clock_label = Label.new()
	column.add_child(_clock_label)
	_status = Label.new()
	column.add_child(_status)
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_board_input)
	column.add_child(_board)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	_begin_button = _button(actions, "작전 시작", _begin)
	_save_button = _button(actions, "저장", _save_or_retry)
	_stop_button = _button(actions, "정지", _queue_order.bind("stop", Vector2.ZERO))
	_abandon_button = _button(actions, "작전 포기", _abandon)
	_return_button = _button(actions, "적벽으로 돌아가기", _return)
	_controls()


func open_operation(parent_id: String) -> Dictionary:
	if _lease != null:
		return {"ok": false, "error": "cross_counter_owner_active"}
	var opened := Store.open()
	if not opened.ok:
		return opened
	_lease = opened.lease
	var head: Dictionary = opened.head
	var active: Dictionary = head.active
	if active.is_empty() and head.completed.has(parent_id):
		_show_settlement(head.completed[parent_id].settlement)
		return {"ok": true}
	if not ResourceLoader.exists(RuntimePath) or not ResourceLoader.exists(CheckpointPath):
		_lease.close()
		_lease = null
		return {"ok": false, "error": "cross_counter_runtime_unavailable"}
	_factory = load(RuntimePath)
	_checkpoint = load(CheckpointPath)
	var prepared: Dictionary
	if active.is_empty():
		_operation_id = Store.OPERATION_PREFIX + Crypto.new().generate_random_bytes(16).hex_encode()
		prepared = _factory.prepare_fresh(_factory.request(), _operation_id)
		if not prepared.ok:
			return prepared
		var stored := _lease.start(parent_id, _operation_id, prepared.checkpoint)
		if not stored.ok:
			prepared.owner.close()
			return stored
		var published := _publish_owner(prepared.owner)
		if not published.ok:
			return {"ok": false, "error": "cross_counter_publish_failed"}
	else:
		if not parent_id.is_empty() and active.parent_id != parent_id:
			return {"ok": false, "error": "cross_counter_owner_active"}
		var parent := Store.eligible_parent(active.parent_id)
		if not parent.ok or parent.digest != active.parent_sha256:
			return {"ok": false, "error": "cross_counter_parent_binding_changed"}
		_operation_id = active.operation_id
		var packet: Dictionary = active.packet
		var binding: Dictionary = _checkpoint.binding_for(packet)
		if binding.get("packet_sha256") != active.packet_sha256:
			return {"ok": false, "error": "cross_counter_checkpoint_binding_changed"}
		var restoring: Dictionary = _checkpoint.begin_restore(packet, binding, _factory.prepare_fresh)
		if not restoring.ok:
			return restoring
		_restore_job = restoring.job
		_status.text = "저장된 작전을 확인하고 있습니다."
	_hold_close_request()
	_controls()
	return {"ok": true}


func _publish_owner(candidate: RefCounted) -> Dictionary:
	var checked: Dictionary = candidate.preview_initial_frame()
	if not checked.ok or checked.frame.meta.get("definition_id") != "cross-counter-successor-v1":
		candidate.close()
		return {"ok": false, "error": "cross_counter_invalid_host_frame"}
	var published: Dictionary = candidate.publish()
	if not published.ok or published.get("frame") != checked.frame:
		candidate.close()
		return {"ok": false, "error": "cross_counter_publish_failed"}
	var read: Dictionary = candidate.summary()
	if not read.ok or read.summary.operation_id != _operation_id:
		candidate.close()
		return {"ok": false, "error": "cross_counter_invalid_owner_identity"}
	_owner = candidate
	_frame = published.frame
	_refresh()
	_status.text = "" if not read.summary.started else "저장된 작전을 불러왔습니다."
	_controls()
	return {"ok": true}


func _hold_close_request() -> void:
	_old_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	_manages_quit = true
	set_process(_restore_job != null)


func _process(delta: float) -> void:
	if _restore_job != null:
		var next: Dictionary = _restore_job.step(RESTORE_BUDGET_USEC)
		if not next.ok:
			_restore_job.cancel()
			_restore_job = null
			_show_error(next)
			set_process(false)
		elif next.done:
			_restore_job = null
			var published := _publish_owner(next.owner)
			if not published.ok:
				_show_error(published)
			set_process(false)
		return
	for index in _clock.advance(delta):
		if not _advance():
			break


func _begin() -> void:
	if _owner == null or _blocked or _running or _terminal:
		return
	var begun: Dictionary = _owner.issue({"kind": "begin_operation", "operation_id": _operation_id})
	if not begun.ok:
		_show_error(begun)
		return
	_clock = TickClock.new()
	_running = true
	_refresh()
	if not _persist():
		return
	set_process(true)
	_controls()


func _abandon() -> void:
	if _owner == null or _blocked or _terminal:
		return
	var queued: Dictionary = _owner.queue({"kind": "abandon", "operation_id": _operation_id})
	if not queued.ok:
		_show_error(queued)
		return
	_advance()


func _board_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or event.button_index != MOUSE_BUTTON_LEFT or not event.pressed:
		return
	var ratio := minf(_board.size.x / 1700.0, _board.size.y / 1150.0)
	if ratio <= 0.0:
		return
	var origin := (_board.size - Vector2(1700.0, 1150.0) * ratio) * 0.5
	var target: Vector2 = (event.position - origin) / ratio
	if Rect2(Vector2.ZERO, Vector2(1700, 1150)).has_point(target):
		_queue_order("move", target)


func _queue_order(kind: String, target: Vector2) -> void:
	if not _running or _blocked or _terminal:
		return
	var ids := []
	for row: Dictionary in _frame.projection.squadrons:
		if row.side == 0 and not row.get("dead", false):
			ids.append(row.id)
	var command := {"kind": kind, "operation_id": _operation_id, "side": 0, "ids": ids}
	if kind == "move":
		command.point = target
	var queued: Dictionary = _owner.queue(command)
	if not queued.ok:
		_show_error(queued)


func _advance() -> bool:
	var advanced: Dictionary = _owner.advance()
	if not advanced.ok:
		_freeze_error(advanced)
		return false
	_owner.drain_events()
	_refresh()
	return _persist_terminal() and not _terminal


func _persist_terminal() -> bool:
	if not _frame.projection.operation.settlement.is_empty():
		return _persist()
	return true


func _persist() -> bool:
	var captured: Dictionary = _checkpoint.capture(_owner)
	if not captured.ok:
		_freeze_error(captured)
		return false
	var packet: Dictionary = captured.packet
	var result := _lease.save(packet) if packet.settlement.is_empty() else _lease.settle(packet, packet.settlement)
	if not result.ok:
		_freeze_error(result)
		return false
	_blocked = false
	if not packet.settlement.is_empty():
		_show_settlement(packet.settlement)
	else:
		_status.text = "저장했습니다."
	_controls()
	return true


func _save_or_retry() -> void:
	if _owner == null or _terminal or not _persist():
		return
	if _closing_requested:
		get_tree().quit()
	elif _return_requested:
		returned.emit()
	elif _running and not _terminal:
		set_process(true)


func _return() -> void:
	_return_requested = true
	set_process(false)
	if _owner == null or _terminal or _persist():
		returned.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _manages_quit:
		_closing_requested = true
		set_process(false)
		if _owner == null or _terminal or _persist():
			get_tree().quit()


func _exit_tree() -> void:
	if _restore_job != null:
		_restore_job.cancel()
	if _owner != null:
		_owner.close()
	if _lease != null:
		_lease.close()
	if _manages_quit:
		get_tree().auto_accept_quit = _old_auto_quit


func _refresh() -> void:
	var ready: Dictionary = _owner.read_projection()
	var summary: Dictionary = _owner.summary()
	if ready.ok and summary.ok:
		_frame = {"projection": ready.projection, "tick": summary.summary.tick, "clock_ms": summary.summary.clock_ms}
		_clock_label.text = "%d 틱 · %.1f초" % [_frame.tick, _frame.clock_ms / 1000.0]
		_board.queue_redraw()


func _show_settlement(settlement: Dictionary) -> void:
	_terminal = true
	_running = false
	set_process(false)
	_status.text = "%s · %s" % ["작전 성공" if settlement.kind == "objective_success" else "작전 종료", settlement.reason]
	_controls()


func _freeze_error(problem: Dictionary) -> void:
	_blocked = true
	set_process(false)
	_show_error(problem)
	_controls()


func _show_error(problem: Dictionary) -> void:
	_status.text = str(problem.get("error", "cross_counter_failed"))


func _controls() -> void:
	_begin_button.disabled = _owner == null or _blocked or _running or _terminal
	_stop_button.disabled = not _running or _blocked or _terminal
	_save_button.disabled = _owner == null or _terminal
	_save_button.text = "저장 재시도" if _blocked else "저장"
	_abandon_button.disabled = _owner == null or _blocked or _terminal
	if _owner != null and not _terminal:
		var current: Dictionary = _owner.summary()
		_abandon_button.disabled = _abandon_button.disabled or not current.ok or not current.summary.started


func _draw_board() -> void:
	_board.draw_rect(Rect2(Vector2.ZERO, _board.size), Color("#142538"))
	if _frame.is_empty():
		return
	var ratio := minf(_board.size.x / 1700.0, _board.size.y / 1150.0)
	var origin := (_board.size - Vector2(1700.0, 1150.0) * ratio) * 0.5
	for row: Dictionary in _frame.projection.squadrons:
		if not row.get("dead", false):
			_board.draw_circle(origin + row.pos * ratio, 12.0, Color.CORNFLOWER_BLUE if row.side == 0 else Color.ORANGE_RED)


func _button(row: Container, label: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size.y = 42
	button.pressed.connect(action)
	row.add_child(button)
	return button
