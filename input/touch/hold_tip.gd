class_name HoldTip
extends Control

# 터치 길게 누르기 툴팁. 마우스는 올리면 뜨는 기본 툴팁을 그대로 쓴다.
# - 등록한 버튼을 손가락으로 LONG_PRESS초 누르고 있으면 그 버튼의 툴팁을 버튼 위에 띄운다.
# - 툴팁이 뜬 뒤 손을 떼면 버튼은 눌리지 않는다(명령을 확인만 하고 취소할 수 있다).
# - 손가락이 TAP_MOVE 이상 움직이면 취소한다.
# 터치는 Godot의 마우스 흉내(DEVICE_ID_EMULATION)로 들어오는 이벤트를 본다. 이벤트는 소비하지 않는다.

const LONG_PRESS := 0.45
const TAP_MOVE := 14.0
const GAP := 10.0

var targets: Array[Control] = []
var _btn: Control = null
var _start := Vector2.ZERO
var _t := 0.0
var _tip: Control = null
var _fade: Tween

func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func register(c: Control) -> void:
	if not targets.has(c):
		targets.append(c)
		c.tree_exiting.connect(func(): targets.erase(c))

func showing() -> bool:
	return _tip != null

func _input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.device == InputEvent.DEVICE_ID_EMULATION:
		if e.pressed:
			_hide()
			_btn = _hit(e.position)
			_start = e.position
			_t = 0.0
		else:
			_btn = null
			_hide()
	elif e is InputEventMouseMotion and e.device == InputEvent.DEVICE_ID_EMULATION and _btn:
		if (e.position - _start).length() > TAP_MOVE:
			_btn = null
			_hide()

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	if _btn == null or _tip != null:
		return
	if not is_instance_valid(_btn) or not _btn.is_visible_in_tree():
		_btn = null
		return
	_t += delta
	if _t >= LONG_PRESS:
		_open(_btn)

func _hit(p: Vector2) -> Control:
	for c in targets:
		if is_instance_valid(c) and c.is_visible_in_tree() and c.get_global_rect().has_point(p):
			return c
	return null

func _open(b: Control) -> void:
	var tip: Control = b._make_custom_tooltip(b.tooltip_text) if b.has_method("_make_custom_tooltip") else null
	if tip == null:
		if b.tooltip_text.strip_edges() == "":
			return
		tip = _plain(b.tooltip_text)
	# 손을 떼도 버튼이 눌리지 않게 누름 상태를 지운다(disabled를 껐다 켜면 BaseButton이 누름을 잊는다).
	# 길게 눌러 확정하는 버튼은 누름을 그대로 둔다(확정 판정은 명령 데크가 한다).
	if b is BaseButton and not (b as BaseButton).disabled and not b.has_meta("hold_confirm"):
		(b as BaseButton).disabled = true
		(b as BaseButton).disabled = false
	_tip = tip
	add_child(tip)
	tip.reset_size()
	_place(tip, b.get_global_rect())
	tip.modulate.a = 0.0
	if _fade:
		_fade.kill()
	_fade = create_tween().set_ignore_time_scale()
	_fade.tween_property(tip, "modulate:a", 1.0, 0.12)
	Input.vibrate_handheld(20)

# 버튼 위(손가락에 가리지 않는 쪽)에 띄우고 화면 안으로 맞춘다. 위가 모자라면 아래로.
func _place(tip: Control, r: Rect2) -> void:
	var view := get_viewport_rect().size
	var s := tip.size
	var x := clampf(r.get_center().x - s.x * 0.5, 8.0, view.x - s.x - 8.0)
	var y := r.position.y - s.y - GAP
	if y < 8.0:
		y = minf(r.end.y + GAP, view.y - s.y - 8.0)
	tip.position = Vector2(x, y) - get_global_rect().position

func _plain(text: String) -> Control:
	var p := PanelContainer.new()
	var st := UiTheme.ornate(false)
	st.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", st)
	var l := UiTheme.label(text, "Body", 13)
	p.add_child(l)
	return p

func hide_tip() -> void:
	_btn = null
	_hide()

func _hide() -> void:
	if _tip:
		_tip.queue_free()
		_tip = null
