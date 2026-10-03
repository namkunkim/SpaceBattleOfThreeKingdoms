extends Control

# 빠른 선택 알림(리뷰 V-7, NARRATIVE-RED-CLIFFS §1 "의심 게이지 경고").
# 결정 카드와 달리 짧은 알림이다: 한 줄 + 버튼 2개(추천 표시), 실제 시간 2초.
# 2초 안에 고르지 않으면 하던 대로 진행하고, 추천안을 자동으로 적용하지 않는다(제안값).
# 되돌리기 알림 자리를 같이 쓴다(뜨는 동안 되돌리기 알림을 숨긴다).
# open_alert({text: "...", options: [{label, rec: bool}, {label, rec}], time: 2.0})

signal chosen(index: int)
signal expired

var data := {}
var left := 0.0
var _btns: Array = []

func setup() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

func open_alert(d: Dictionary) -> void:
	data = d
	left = float(d.get("time", 2.0))
	for b in _btns:
		b.queue_free()
	_btns.clear()
	var opts: Array = d.get("options", [])
	var x := size.x - 12.0
	for i in range(opts.size() - 1, -1, -1):
		var rec: bool = opts[i].get("rec", false)
		var b := Button.new()
		b.text = ("★ " if rec else "") + str(opts[i].label)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 52)
		b.size = Vector2(150, 52)
		x -= 150.0
		b.position = Vector2(x, (size.y - 52.0) * 0.5)
		x -= 8.0
		if rec:
			b.theme_type_variation = "PrimaryButton"
		b.pressed.connect(func():
			chosen.emit(i)
			close_alert())
		add_child(b)
		_btns.append(b)
	visible = true

func close_alert() -> void:
	visible = false
	data = {}

func _process(delta: float) -> void:
	if not visible:
		return
	left -= UiDraw.real_dt(delta)
	queue_redraw()
	if left <= 0.0:
		close_alert()
		expired.emit()

func _draw() -> void:
	if data.is_empty():
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.08, 0.05, 0.03, 0.94))
	draw_rect(r.grow(-0.5), Color(UiTheme.WARN, 0.7), false, 1.2)
	UiDraw.icon(self, "warn", Rect2(14, size.y * 0.5 - 11, 22, 22), UiTheme.WARN, 1.6)
	UiDraw.text(self, Vector2(46, size.y * 0.5 + 5), str(data.get("text", "")), "semibold", 14, UiTheme.INK)
	var k := clampf(left / maxf(0.01, float(data.get("time", 2.0))), 0.0, 1.0)
	draw_rect(Rect2(0, size.y - 3, size.x * k, 3), UiTheme.WARN)
