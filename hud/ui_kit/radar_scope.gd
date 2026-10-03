class_name RadarScope
extends Control

# 원형 전술도: 금장 눈금 테, 회전 탐색선, 진영 기호와 방향, 기함 지휘 범위, 현재 화면 범위(사다리꼴).
# 클릭하거나 끌면 그 지점으로 화면을 옮긴다.

var battle: Node
var t := 0.0
const SIZE := 208.0

func setup(b: Node) -> void:
	battle = b
	custom_minimum_size = Vector2(SIZE, SIZE)
	size = Vector2(SIZE, SIZE)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)

var _acc := 0.0

func _process(delta: float) -> void:
	t += delta
	_acc += delta
	if _acc >= 1.0 / 30.0:
		_acc = 0.0
		queue_redraw()

func _r() -> float:
	return SIZE * 0.5 - 18.0

func _scale() -> float:
	var ws: Vector2 = battle.WORLD
	return _r() * 1.86 / ws.length()

func _w2r(p: Vector2) -> Vector2:
	return (p - battle.WORLD * 0.5) * _scale() + Vector2(SIZE, SIZE) * 0.5

func _r2w(p: Vector2) -> Vector2:
	return (p - Vector2(SIZE, SIZE) * 0.5) / _scale() + battle.WORLD * 0.5

func _draw() -> void:
	if battle == null or battle.G.is_empty():
		return
	var c := Vector2(SIZE, SIZE) * 0.5
	var R := _r()
	draw_circle(c, R + 16.0, Color(0.03, 0.045, 0.07, 0.95))
	draw_arc(c, R + 16.0, 0.0, TAU, 96, UiTheme.GOLD_LO, 2.0, true)
	draw_arc(c, R + 10.0, 0.0, TAU, 96, Color(UiTheme.GOLD, 0.55), 1.2, true)
	var minor := PackedVector2Array()
	var major_l := PackedVector2Array()
	for i in 72:
		var a := TAU * i / 72.0
		var major := i % 18 == 0
		var r1 := R + 10.0
		var r2 := R + (3.0 if major else (6.0 if i % 6 == 0 else 8.0))
		var arr := major_l if major else minor
		arr.append(c + Vector2(cos(a), sin(a)) * r1)
		arr.append(c + Vector2(cos(a), sin(a)) * r2)
		if major:
			major_l = arr
		else:
			minor = arr
	draw_multiline(minor, Color(UiTheme.GOLD, 0.5), 1.0)
	draw_multiline(major_l, UiTheme.GOLD_HI, 1.6)
	draw_circle(c, R, Color(0.025, 0.07, 0.12, 0.96))
	for i in range(1, 4):
		draw_arc(c, R * i / 4.0, 0.0, TAU, 64, Color(0.47, 0.7, 1.0, 0.12), 1.0, true)
	draw_line(c + Vector2(-R, 0), c + Vector2(R, 0), Color(0.47, 0.7, 1.0, 0.1))
	draw_line(c + Vector2(0, -R), c + Vector2(0, R), Color(0.47, 0.7, 1.0, 0.1))
	var a0 := _w2r(Vector2.ZERO)
	var a1 := _w2r(battle.WORLD)
	draw_rect(Rect2(a0, a1 - a0), Color(0.3, 0.55, 0.9, 0.08))
	draw_rect(Rect2(a0, a1 - a0), Color(0.3, 0.55, 0.9, 0.25), false, 1.0)
	# 탐색선 잔상
	var sw := t * 1.1
	var fan := PackedVector2Array([c])
	var cols := PackedColorArray([Color(0.47, 0.82, 1.0, 0.0)])
	for k in 15:
		var a := sw - k * 0.035
		fan.append(c + Vector2(cos(a), sin(a)) * R)
		cols.append(Color(0.47, 0.82, 1.0, 0.24 * (1.0 - k / 14.0)))
	draw_polygon(fan, cols)
	var pf = battle.flag(0)
	if pf:
		draw_arc(_w2r(pf.pos), battle.CMD_R * _scale(), 0.0, TAU, 48, Color(UiTheme.ALLY, 0.45), 1.0, true)
	for f in battle.fleets:
		if f.dead:
			continue
		var p := _w2r(f.pos)
		var sel: bool = battle.selected.has(f)
		var col := Color.WHITE if sel else UiTheme.side_color(f.side)
		UiDraw.side_glyph(self, p, 3.6 if not f.is_flag else 4.4, f.side, col)
		var hd := Vector2(cos(f.heading), sin(f.heading))
		draw_line(p, p + hd * 8.0, col, 1.2, true)
		if f.is_flag:
			draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), UiTheme.GOLD_HI, false, 1.0)
		if f.has_move and f.side == 0:
			UiDraw.dashed_poly(self, PackedVector2Array([p, _w2r(f.move_to)]), Color(UiTheme.GOLD_HI, 0.7), 1.0, 3.0, 3.0)
	# 현재 화면이 보는 전장 범위
	var vs: Vector2 = get_viewport_rect().size
	var corners := [battle.s2w(Vector2(0, 0)), battle.s2w(Vector2(vs.x, 0)), battle.s2w(vs), battle.s2w(Vector2(0, vs.y))]
	var poly := PackedVector2Array()
	for q in corners:
		var rp := _w2r(q)
		poly.append(c + (rp - c).limit_length(R))
	poly.append(poly[0])
	draw_polyline(poly, Color(0.55, 1.0, 0.68, 0.8), 1.3, true)
	UiDraw.text(self, Vector2(c.x, c.y - R - 19.0), "N", "semibold", 11, UiTheme.GOLD_HI, HORIZONTAL_ALIGNMENT_CENTER, 0.0)

func _on_input(e: InputEvent) -> void:
	if battle.G.state == "brief":
		return
	var press: bool = e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	var dragm: bool = e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if press or dragm:
		var c := Vector2(SIZE, SIZE) * 0.5
		if (e.position - c).length() <= _r() + 4.0:
			battle.cam_pos = _r2w(e.position)
			battle._clamp_cam()
			accept_event()
