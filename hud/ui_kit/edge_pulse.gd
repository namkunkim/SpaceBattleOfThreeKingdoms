extends Control

# 분기 예고의 가장자리 방향 펄스(리뷰 V-4, EXPERIENCE-DESIGN §5 1단계).
# BattleSource.decision_incoming()의 위치 쪽 화면 가장자리에 금빛 펄스를 그린다. 화면 안이면 그 자리에 고리.

var deck: Control
var src: BattleSource
var _t := 0.0

func setup(d: Control) -> void:
	deck = d
	src = d.src
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_t += UiDraw.real_dt(delta)
	queue_redraw()

func _draw() -> void:
	var inc := src.decision_incoming()
	if inc.is_empty() or src.state() != "play":
		return
	var view := size
	var sp: Vector2 = deck.battle.w2s(inc.get("pos", Vector2.ZERO))
	var k := 0.5 + 0.5 * sin(_t * TAU * 1.6)
	var col := Color(UiTheme.GOLD_HI, 0.35 + 0.45 * k)
	if Rect2(Vector2(40, 40), view - Vector2(80, 80)).has_point(sp):
		draw_arc(sp, 34.0 + 10.0 * k, 0.0, TAU, 40, col, 2.5, true)
		draw_arc(sp, 50.0 + 14.0 * k, 0.0, TAU, 40, Color(col, col.a * 0.4), 1.5, true)
	else:
		# 화면 가운데에서 그 위치 쪽 가장자리 점
		var c := view * 0.5
		var d := sp - c
		var t := INF
		if absf(d.x) > 0.001:
			t = minf(t, (view.x * 0.5 - 18.0) / absf(d.x))
		if absf(d.y) > 0.001:
			t = minf(t, (view.y * 0.5 - 18.0) / absf(d.y))
		var e := c + d * t
		var n := d.normalized()
		var side := Vector2(-n.y, n.x)
		for i in 3:
			var w := 120.0 - i * 30.0
			draw_line(e - side * w * 0.5 - n * (i * 6.0), e + side * w * 0.5 - n * (i * 6.0), Color(col, col.a * (1.0 - i * 0.3)), 4.0 - i, true)
		draw_colored_polygon(PackedVector2Array([e + n * 2.0, e - n * 16.0 + side * 9.0, e - n * 16.0 - side * 9.0]), col)
	UiDraw.text(self, Vector2(0, 150), "결정 임박 · 약 %d초" % ceili(float(inc.get("secs", 0.0))), "semibold", 14, col, HORIZONTAL_ALIGNMENT_CENTER, view.x)
