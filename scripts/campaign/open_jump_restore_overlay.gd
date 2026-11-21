extends ColorRect

signal cancelled

var _status := Label.new()
var _bar := ProgressBar.new()
var _cancel := Button.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color("0b1424df")
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 390
	box.add_theme_constant_override("separation", 14)
	center.add_child(box)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_status)
	_bar.max_value = 100
	_bar.custom_minimum_size.y = 24
	box.add_child(_bar)
	_cancel.text = "불러오기 취소"
	_cancel.custom_minimum_size.y = 52
	_cancel.pressed.connect(func(): cancelled.emit())
	box.add_child(_cancel)
	hide()

func begin() -> void:
	_status.text = "저장 데이터를 확인하는 중…"
	_bar.value = 0
	_cancel.disabled = false
	show()
	_cancel.grab_focus()

func update_progress(tick: int, total: int) -> void:
	if total > 0:
		_status.text = "전장 복원 중 · %d / %d" % [tick, total]
		_bar.value = 100.0 * tick / total
func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey or event is InputEventJoypadButton):
		return
	get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		cancelled.emit()
func show_cancelling() -> void:
	_status.text = "불러오기를 취소하는 중…"
	_cancel.disabled = true
