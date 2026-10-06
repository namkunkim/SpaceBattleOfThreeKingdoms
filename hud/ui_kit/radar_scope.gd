class_name RadarScope
extends Control

# 사각 미니맵: 전장 비율 그대로의 반투명 판. 진영 기호와 방향, 기함 지휘 범위, 현재 카메라 범위 사각 틀.
# 누르거나 끌면 그 지점으로 화면을 옮긴다. 탐지 안개가 생기면 접촉만 그린다(M10).
# 클래스 이름은 호환용으로 남겼다(RadarScope).

var battle: Node
var t := 0.0
const W := 240.0   # 전장 3400×2300에 맞춘 비율
const H := 162.0
const PAD := 6.0

func setup(b: Node) -> void:
	battle = b
	custom_minimum_size = Vector2(W, H)
	size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)

var _acc := 0.0

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	t += delta
	_acc += delta
	if _acc >= 1.0 / 30.0:
		_acc = 0.0
		queue_redraw()

func _map() -> Rect2:
	return Rect2(Vector2(PAD, PAD), Vector2(W, H) - Vector2(PAD, PAD) * 2.0)

func _scale() -> float:
	return _map().size.x / battle.field().x

func _w2r(p: Vector2) -> Vector2:
	return _map().position + p * _scale()

func _r2w(p: Vector2) -> Vector2:
	return (p - _map().position) / _scale()

func _draw() -> void:
	if battle == null or battle.G.is_empty():
		return
	var m := _map()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.055, 0.78))
	draw_rect(Rect2(Vector2.ZERO, size).grow(-0.5), UiTheme.GOLD_LINE, false, 1.0)
	draw_rect(m, Color(0.1, 0.18, 0.2, 0.55))
	# 먹선 눈금: 전장을 4×3으로 가른다
	for i in range(1, 4):
		draw_line(Vector2(m.position.x + m.size.x * i / 4.0, m.position.y), Vector2(m.position.x + m.size.x * i / 4.0, m.end.y), Color(UiTheme.GOLD_LINE, 0.12), 1.0)
	for i in range(1, 3):
		draw_line(Vector2(m.position.x, m.position.y + m.size.y * i / 3.0), Vector2(m.end.x, m.position.y + m.size.y * i / 3.0), Color(UiTheme.GOLD_LINE, 0.12), 1.0)
	var pf = battle.flag(0)
	if pf:
		draw_arc(_w2r(pf.pos), battle.CMD_R * _scale(), 0.0, TAU, 48, Color(UiTheme.ALLY, 0.4), 1.0, true)
	for f in battle.fleets:
		if f.dead:
			continue
		var p := _w2r(f.pos)
		var sel: bool = battle.selected.has(f)
		var fk: String = battle.presentation.src.faction(f.id)
		var col: Color = Color.WHITE if sel else Factions.of(fk).color
		UiDraw.faction_glyph(self, p, 3.4 if not f.is_flag else 4.2, fk, col)
		draw_line(p, p + Vector2(cos(f.heading), sin(f.heading)) * 8.0, col, 1.2, true)
		if f.has_move and f.side == 0:
			UiDraw.dashed_poly(self, PackedVector2Array([p, _w2r(f.move_to)]), Color(UiTheme.GOLD_HI, 0.7), 1.0, 3.0, 3.0)
	# 현재 카메라 범위: 화면 네 모서리의 바깥 사각 틀
	var vs: Vector2 = get_viewport_rect().size
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in [battle.s2w(Vector2(0, 0)), battle.s2w(Vector2(vs.x, 0)), battle.s2w(vs), battle.s2w(Vector2(0, vs.y))]:
		var rp := _w2r(q)
		lo = lo.min(rp)
		hi = hi.max(rp)
	var frame := Rect2(lo, hi - lo).intersection(m)
	draw_rect(frame, Color(UiTheme.GOLD_HI, 0.85), false, 1.4)

func _on_input(e: InputEvent) -> void:
	if battle.G.state == "brief":
		return
	var press: bool = e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT
	var dragm: bool = e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
	if press or dragm:
		if _map().grow(4.0).has_point(e.position):
			battle.cam_pos = _r2w(e.position).clamp(Vector2.ZERO, battle.field())
			battle._clamp_cam()
			accept_event()
