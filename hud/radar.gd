class_name BattleRadar
extends Control

# POC 레이더: 전장 축소도와 현재 화면 범위. 클릭·끌기로 카메라를 옮긴다(호스트의 cam_pos).
# 상품화 레이더(hud/ui_kit/radar_scope.gd)가 있으면 이 레이더는 숨겨진다.

const RS := 128.0
const CMD_R := 560.0

var b: Node

func setup(host: Node) -> void:
	b = host
	gui_input.connect(_radar_input)

func _rsc() -> float:
	return RS * 0.92 / CameraRig.WORLD.length()

func _w2r(p: Vector2) -> Vector2:
	return (p - CameraRig.WORLD * 0.5) * _rsc() + Vector2(RS, RS) * 0.5

func _r2w(p: Vector2) -> Vector2:
	return (p - Vector2(RS, RS) * 0.5) / _rsc() + CameraRig.WORLD * 0.5

func _draw() -> void:
	if b == null or b.G.is_empty():
		return
	var c := Vector2(RS, RS) * 0.5
	draw_circle(c, RS * 0.5, Color("0a2038"))
	var a := _w2r(Vector2.ZERO)
	var bb := _w2r(CameraRig.WORLD)
	draw_rect(Rect2(a, bb - a), Color(0.24, 0.47, 0.78, 0.2))
	for i in range(1, 4):
		draw_arc(c, i * RS / 8.0, 0.0, TAU, 32, Color(0.47, 0.71, 1.0, 0.18), 1.0)
	var sweep: float = b.now_t / 1.4
	draw_line(c, c + Vector2(cos(sweep), sin(sweep)) * RS * 0.5, Color(0.47, 0.78, 1.0, 0.4), 1.5)
	var pf = b.flag(0)
	if pf:
		draw_arc(_w2r(pf.pos), CMD_R * _rsc(), 0.0, TAU, 32, Color(0.37, 0.88, 0.81, 0.5), 1.0)
	for f in b.fleets:
		if f.dead:
			continue
		var p := _w2r(f.pos)
		var col := BattleHud.C_FOE if f.side == 1 else (Color.WHITE if b.selected.has(f) else BattleHud.C_ALLY)
		var sz := 5.0 if f.is_flag else 3.5
		draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col)
	var tl := _w2r(b.s2w(Vector2.ZERO))
	var br := _w2r(b.s2w(b.vsize))
	draw_rect(Rect2(tl, br - tl), Color(0.47, 1.0, 0.59, 0.85), false, 1.2)

func _radar_input(e: InputEvent) -> void:
	if b.G.state == "brief":
		return
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0):
		b.cam_pos = _r2w(e.position)
		b._clamp_cam()
