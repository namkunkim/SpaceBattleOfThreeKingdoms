extends Control

signal returned

const Runtime := preload("res://scripts/lantern_escort/runtime.gd")
const Slot := preload("res://scripts/lantern_escort/public_slot.gd")
const ExternalSave := preload("res://scripts/lantern_escort/external_save.gd")

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
var _line: Label
var _notice: Label
var _board: Control
var _play: Button
var _save: Button
var _export: Button
var _export_dialog: FileDialog
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
	layout.add_child(UiTheme.label("퇴로의 등불", "Display", 34))
	_line = UiTheme.label("오림 외곽 · 구조 신호 두 건", "Body", 20)
	layout.add_child(_line)
	layout.add_child(UiTheme.label("노숙의 교신 · 도약 출구까지 부상병 수송선 두 척을 호위하세요.", "Body", 18))
	_notice = UiTheme.label("호위 전대에 이동 명령을 내리려면 전장을 클릭하세요.", "Body", 18)
	layout.add_child(_notice)
	_board = Control.new()
	_board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board.draw.connect(_draw_board)
	_board.gui_input.connect(_board_input)
	layout.add_child(_board)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	layout.add_child(actions)
	_play = _button(actions, "작전 시작", "LanternStart", _toggle_run)
	_save = _button(actions, "저장", "LanternSave", _save_or_retry)
	_export = _button(actions, "외부 저장 내보내기…", "LanternExport", _select_export_file)
	_stop = _button(actions, "호위 정지", "LanternStop", _queue.bind("stop"))
	_abandon = _button(actions, "작전 포기", "LanternAbandon", _abandon_operation)
	_button(actions, "천하로 돌아가기", "LanternReturn", leave)
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
		_show_settlement(receipt.settlement)
		return {"ok": true}

	if active.is_empty():
		var operation_id := Runtime.ID_PREFIX + Crypto.new().generate_random_bytes(16).hex_encode()
		_operation = Runtime.create(operation_id)
		if _operation == null:
			return {"ok": false, "error": "lantern_definition_unavailable"}
		var created := _slot.start(parent_id, operation_id, _operation.capture())
		if not created.ok:
			return created
	else:
		if active.parent_id != parent_id:
			return {"ok": false, "error": "lantern_slot_busy"}
		var parent := Slot.validate_parent(parent_id, active.parent_sha256)
		if not parent.ok:
			return parent
		var restored := Runtime.restore(active.packet)
		if not restored.ok:
			return restored
		_operation = restored.runtime
		_notice.text = "저장된 호송을 불러왔습니다."
	_previous_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	_owns_close = true
	_refresh()
	_controls()
	return {"ok": true}


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
	for event: Dictionary in _operation.drain_events():
		match event.kind:
			"pursuer_spawned":
				_notice.text = "추격대가 진입했습니다."
			"transport_escaped":
				_notice.text = "수송선이 도약 출구를 통과했습니다."
			"transport_destroyed":
				_notice.text = "수송선 한 척을 잃었습니다."
	_refresh()
	if _operation.settlement.is_empty():
		return true
	_persist()
	return false


func _queue(kind: String, point := Vector2.ZERO) -> void:
	if _operation != null and _running and not _blocked and not _terminal:
		if not _operation.queue(kind, point):
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
		_notice.text = "호송 상태를 저장했습니다."
	_controls()
	return true


static func external_save_dialog(exporting: bool) -> FileDialog:
	var dialog := FileDialog.new()
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE if exporting else FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "퇴로의 등불 외부 저장 내보내기" if exporting else "퇴로의 등불 외부 저장 가져오기"
	dialog.add_filter("*" + ExternalSave.EXTENSION, "퇴로의 등불 외부 저장")
	return dialog

func _select_export_file() -> void:
	if _export.disabled or _export_dialog != null:
		return
	set_process(false)
	_export_dialog = external_save_dialog(true)
	add_child(_export_dialog)
	_export_dialog.canceled.connect(_close_export_dialog)
	_export_dialog.file_selected.connect(_export_file_selected)
	_export_dialog.popup_centered_ratio(0.7)
	_export_dialog.get_line_edit().grab_focus()

func _export_file_selected(path: String) -> void:
	if _export_dialog == null:
		return
	var active: Dictionary = _slot.head().active
	var checkpoint := {
		"parent_id": active.parent_id, "parent_sha256": active.parent_sha256,
		"operation_id": active.operation_id, "packet": _operation.capture(),
	}
	var result := ExternalSave.write(checkpoint, path)
	_notice.text = "호송 외부 저장을 내보냈습니다." if result.ok else "내보내지 못했습니다. (%s)" % result.error
	_close_export_dialog()

func _close_export_dialog() -> void:
	if _export_dialog == null:
		return
	_export_dialog.hide()
	_export_dialog.queue_free()
	_export_dialog = null
	if _running and not _blocked and not _terminal:
		set_process(true)
	_export.grab_focus()

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
	_line.text = "작전 %.1f초 / 120초   ·   탈출 %d / 2척" % [_frame.clock_ms / 1000.0, _frame.escaped]
	_board.queue_redraw()


func _show_settlement(settlement: Dictionary) -> void:
	_terminal = true
	_running = false
	set_process(false)
	var escaped: int = int(settlement.escaped)
	var titles := ["구출 실패", "구출 성공", "완전 구출"]
	var endings := [
		"귀환 기록은 비어 있습니다. 마지막 교신 좌표를 수색대에 넘겼습니다.",
		"노숙은 한 척의 귀환을 확인하고 남은 수송선의 마지막 위치를 기록했습니다.",
		"두 번째 수송선까지 접안했습니다. 오림의 구조 채널을 닫습니다.",
	]
	_line.text = "%s   ·   탈출 %d / 2척   ·   %.1f초" % [
		titles[escaped] if settlement.kind == "success" else titles[0], escaped, settlement.clock_ms / 1000.0]
	_notice.text = "구조 작전을 포기했습니다." if settlement.reason == "abandoned" else endings[escaped]
	_controls()


func _controls() -> void:
	var active := _operation != null and not _terminal
	_play.disabled = not active or _blocked
	_play.text = "일시정지" if _running else ("계속" if active and _operation.started else "작전 시작")
	_stop.disabled = not active or not _running or _blocked
	_save.disabled = not active
	_export.disabled = not active or _blocked or not _operation.started
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
	var points := PackedVector2Array()
	for position: Vector2 in _frame.waypoints:
		points.append(field.position + position * scale_factor)
	if points.size() >= 2:
		_board.draw_polyline(points, Color("#5e8598"), 2)
	if not points.is_empty():
		_board.draw_arc(points[-1], Runtime.EXIT_RADIUS * scale_factor, 0.0, TAU, 36, Color("#b6ecda"), 2)
	var callsigns := {"transport-1": "선두 수송선", "transport-2": "후미 수송선", "escort": "감녕의 호위 전대", "pursuer-1": "추격대 1", "pursuer-2": "추격대 2"}
	var colors := {"transport": Color("#caefe3"), "escort": Color("#70afff"), "pursuer": Color("#ff916f")}
	var font := ThemeDB.fallback_font
	for ship: Dictionary in _frame.ships:
		if ship.status != "active":
			continue
		var center: Vector2 = field.position + ship.position * scale_factor
		_board.draw_circle(center, 8.0, colors[ship.team])
		_board.draw_string(font, center + Vector2(12, -10 if ship.id == "transport-1" else 24 if ship.id == "transport-2" else 4), "%s  %d/%d" % [callsigns[ship.id], ship.hp, ship.max_hp],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, colors[ship.team])


func _button(parent: Container, label: String, key: String, action: Callable) -> Button:
	var button := Button.new()
	button.name = key
	button.text = label
	button.custom_minimum_size = Vector2(136, 42)
	button.pressed.connect(action)
	parent.add_child(button)
	return button
