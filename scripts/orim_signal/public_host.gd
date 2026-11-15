extends Control

signal returned

const Runtime := preload("res://scripts/orim_signal/runtime.gd")
const Slot := preload("res://scripts/orim_signal/public_slot.gd")

var _slot: Slot
var _operation: RefCounted
var _clock := TickClock.new()
var _running := false
var _blocked := false
var _terminal := false
var _owns_close := false
var _previous_auto_quit := true
var _quit_requested := false
var _return_requested := false
var _frame := {}
var _selected_unit := "gan-ning"
var _line: Label
var _epilogue: Label
var _notice: Label
var _board: Control
var _play: Button
var _save: Button
var _stop: Button
var _abandon: Button


func _ready() -> void:
	set_process(false)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#0e1826")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 32)
	layout.theme = UiTheme.build()
	layout.add_theme_constant_override("separation", 12)
	add_child(layout)
	layout.add_child(UiTheme.label("오림의 마지막 신호", "Display", 34))
	_line = UiTheme.label("오림 외곽 · 통신소 확보", "Body", 20)
	layout.add_child(_line)
	_epilogue = UiTheme.label("", "Body", 18)
	layout.add_child(_epilogue)
	_notice = UiTheme.label("감녕 또는 노숙을 선택한 뒤 전장을 클릭해 이동시키세요.", "Body", 18)
	layout.add_child(_notice)
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_board_input)
	layout.add_child(_board)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)
	var selection := ButtonGroup.new()
	for unit: Array in [["감녕", "gan-ning"], ["노숙", "lu-su"]]:
		var selected := _button(actions, unit[0], "OrimSelect" + unit[1], _choose_unit.bind(unit[1]))
		selected.toggle_mode = true
		selected.button_group = selection
		selected.button_pressed = unit[1] == _selected_unit
	_play = _button(actions, "작전 시작", "OrimStart", _toggle_run)
	_save = _button(actions, "저장", "OrimSave", _save_or_retry)
	_stop = _button(actions, "전대 정지", "OrimStop", _queue.bind("stop"))
	_abandon = _button(actions, "작전 포기", "OrimAbandon", _abandon_operation)
	_button(actions, "천하로 돌아가기", "OrimReturn", leave)
	_controls()


func open_operation(parent_id: String) -> Dictionary:
	var opened := Slot.open()
	if not opened.ok:
		return opened
	_slot = opened.lease
	var head: Dictionary = opened.head
	var active: Dictionary = head.active
	if head.completed.has(parent_id):
		var receipt: Dictionary = head.completed[parent_id]
		var parent := Slot.validate_parent(parent_id, receipt.parent_sha256)
		if not parent.ok:
			return parent
		_show_parent_epilogue(parent.receipt.settlement.escaped)
		_show_settlement(receipt.settlement)
		return {"ok": true}

	if active.is_empty():
		var operation_id := Runtime.ID_PREFIX + Crypto.new().generate_random_bytes(16).hex_encode()
		_operation = Runtime.create(operation_id)
		if _operation == null:
			return {"ok": false, "error": "orim_definition_unavailable"}
		var created := _slot.start(parent_id, operation_id, _operation.capture())
		if not created.ok:
			return created
		_show_parent_epilogue(created.escaped)
	else:
		if active.parent_id != parent_id:
			return {"ok": false, "error": "orim_slot_busy"}
		var parent := Slot.validate_parent(parent_id, active.parent_sha256)
		if not parent.ok:
			return parent
		var restored := Runtime.restore(active.packet)
		if not restored.ok:
			return restored
		_operation = restored.runtime
		_show_parent_epilogue(parent.receipt.settlement.escaped)
		_notice.text = "저장된 통신소 작전을 불러왔습니다."
	_previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	_owns_close = true
	_refresh()
	_controls()
	return {"ok": true}


func _show_parent_epilogue(escaped: int) -> void:
	_epilogue.text = "노숙의 교신 · 호송선 %d척이 퇴로를 벗어났습니다. 통신소에서 구조 좌표를 송신하세요." % escaped


func _toggle_run() -> void:
	if _terminal or _blocked or _operation == null:
		return
	if not _operation.started and not _operation.begin():
		return
	_running = not _running
	set_process(_running)
	_controls()


func _process(delta: float) -> void:
	for index in _clock.advance(delta):
		if not _advance():
			break


func _advance() -> bool:
	_operation.advance()
	_operation.drain_events()
	_refresh()
	if _operation.settlement.is_empty():
		return true
	_persist()
	return false


func _queue(kind: String, point := Vector2.ZERO) -> void:
	if _operation != null and _running and not _blocked and not _terminal:
		if not _operation.queue(kind, _selected_unit, point):
			_notice.text = "명령을 접수하지 못했습니다."


func _abandon_operation() -> void:
	if _operation == null or not _operation.started or _terminal or _blocked:
		return
	if _operation.queue("abandon"):
		_advance()


func _persist() -> bool:
	if _operation == null or _terminal:
		return true
	var packet: Dictionary = _operation.capture()
	var stored := _slot.save(packet) if _operation.settlement.is_empty() else _slot.settle(packet)
	if not stored.ok:
		_blocked = true
		set_process(false)
		_notice.text = "저장하지 못했습니다. 다시 시도해 주세요. (%s)" % stored.get("error", "")
		_controls()
		return false
	_blocked = false
	if not _operation.settlement.is_empty():
		_show_settlement(_operation.settlement)
	else:
		_notice.text = "작전 상태를 저장했습니다."
	_controls()
	return true


func _save_or_retry() -> void:
	if _persist():
		_after_save()


func _after_save() -> void:
	if _quit_requested:
		get_tree().quit()
	elif _return_requested:
		returned.emit()
	elif _running and not _terminal:
		set_process(true)


func leave() -> void:
	_return_requested = true
	set_process(false)
	if _persist():
		_after_save()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _owns_close:
		_quit_requested = true
		set_process(false)
		if _persist():
			_after_save()


func _exit_tree() -> void:
	if _slot != null:
		_slot.close()
	if _owns_close:
		get_tree().auto_accept_quit = _previous_auto_quit


func _refresh() -> void:
	_frame = _operation.projection()
	var owners := {"neutral": "중립", "ally": "연합", "enemy": "위군"}
	_line.text = "작전 %.1f / 120초   ·   통신소 %s   ·   점유 %.1f / 10초   ·   송신 %.1f / 15초   ·   정비 %s" % [
		_frame.clock_ms / 1000.0, owners[_frame.owner], _frame.capture / 10.0,
		_frame.transmission / 10.0, "완료" if _frame.repair_used else "%.1f / 15초" % (_frame.repair / 10.0)]
	_board.queue_redraw()


func _show_settlement(settlement: Dictionary) -> void:
	_terminal = true
	_running = false
	set_process(false)
	var titles := {
		"signal_sent": "송신 완료 · 구조 좌표를 연합에 전달했습니다.",
		"command_destroyed": "작전 실패 · 감녕의 지휘 전대가 전멸했습니다.",
		"deadline": "작전 실패 · 제한 시간에 도달했습니다.",
		"abandoned": "작전 실패 · 통신소 작전을 포기했습니다.",
	}
	_line.text = "%s   ·   %.1f초" % [titles[settlement.reason], settlement.clock_ms / 1000.0]
	_notice.text = ""
	_controls()


func _controls() -> void:
	var active := _operation != null and not _terminal
	_play.disabled = not active or _blocked
	_play.text = "일시정지" if _running else ("계속" if active and _operation.started else "작전 시작")
	_stop.disabled = not active or not _running or _blocked
	_save.disabled = not active
	_save.text = "저장 재시도" if _blocked else "저장"
	_abandon.disabled = not active or _blocked or not _operation.started


func _board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var field := _field()
		if field.has_point(event.position):
			_queue("move", (event.position - field.position) / field.size * Runtime.WORLD_SIZE)
			_board.accept_event()


func _field() -> Rect2:
	var scale_factor := minf(_board.size.x / Runtime.WORLD_SIZE.x, _board.size.y / Runtime.WORLD_SIZE.y)
	var extent: Vector2 = Runtime.WORLD_SIZE * scale_factor
	return Rect2((_board.size - extent) * 0.5, extent)


func _draw_board() -> void:
	var field := _field()
	_board.draw_rect(field, Color("#172a40"))
	if _frame.is_empty():
		return
	var scale_factor := field.size.x / Runtime.WORLD_SIZE.x
	var station_color: Color = {"neutral": Color.SILVER, "ally": Color.SKY_BLUE, "enemy": Color.SALMON}[_frame.owner]
	var points := [
		[_frame.station, _frame.station_radius, "오림 통신소", station_color],
		[_frame.repair_point, _frame.repair_radius, "정비 지점", Color.LIGHT_GREEN],
	]
	var font := ThemeDB.fallback_font
	for point: Array in points:
		var center: Vector2 = field.position + point[0] * scale_factor
		_board.draw_arc(center, point[1] * scale_factor, 0.0, TAU, 40, point[3], 2)
		_board.draw_string(font, center + Vector2(-38, -point[1] * scale_factor - 10), point[2],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, point[3])
	var names := {"gan-ning": "감녕 지휘 전대", "lu-su": "노숙 지원 전대", "wei-advance": "위군 접근 편성", "wei-reserve": "위군 예비 편성"}
	for fleet: Dictionary in _frame.fleets:
		if fleet.state in ["waiting", "destroyed"]:
			continue
		var center: Vector2 = field.position + fleet.position * scale_factor
		var tint := Color.SKY_BLUE if fleet.side == "ally" else Color.SALMON
		_board.draw_circle(center, 8, tint)
		if _selected_unit == fleet.id:
			_board.draw_arc(center, 14, 0.0, TAU, 24, Color.WHITE, 2)
		_board.draw_string(font, center + Vector2(12, 5), "%s · %d척" % [names[fleet.id], fleet.alive],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, tint)


func _choose_unit(unit_id: String) -> void:
	_selected_unit = unit_id
	_board.queue_redraw()



func _button(parent: Container, label: String, key: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = key
	button.text = label
	button.custom_minimum_size = Vector2(136, 42)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
