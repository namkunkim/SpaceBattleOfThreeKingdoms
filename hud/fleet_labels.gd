class_name FleetLabels
extends Control

# POC 전술 오버레이(그리기 전용): 지휘 범위, 명령선, 선택 링, 이동 표식, 함대 라벨, 띄우는 글자, 선택 상자.
# 호스트(전투 노드)의 화면 모델만 읽는다. 규칙 계산 없음.
# 이 컨트롤이 POC HUD 위젯(BattleHud)의 부모(`ui`)다.

const CMD_R := 560.0
const MISSILE_R := 480.0

var b: Node

func setup(host: Node) -> void:
	b = host
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _circle(c: Vector2, r: float, n := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := TAU * i / n
		pts.append(b.w2s(c + Vector2(cos(a), sin(a)) * r))
	return pts

func label_rect(f) -> Rect2:
	var s: Vector2 = b.w2s(f.pos)
	if b.cam_z < 0.55:
		return Rect2(s.x - 24.0, s.y - 34.0, 48.0, 10.0)
	return Rect2(s.x - 22.0, s.y - 58.0, 98.0, 34.0)

func _draw() -> void:
	if b == null or b.G.is_empty():
		return
	var font := ThemeDB.fallback_font
	# 지휘 범위
	var ef = b.flag(1)
	var pf = b.flag(0)
	if ef:
		var pts := _circle(ef.pos, CMD_R, 64)
		draw_colored_polygon(pts, Color(1.0, 0.46, 0.31, 0.04))
		draw_polyline(pts, Color(1.0, 0.46, 0.31, 0.2), 2.0)
	if pf:
		var pts := _circle(pf.pos, CMD_R, 64)
		draw_colored_polygon(pts, Color(0.37, 0.88, 0.81, 0.06))
		draw_polyline(pts, Color(0.37, 0.88, 0.81, 0.35), 2.0)
	# 명령선
	for f in b.selected:
		if f.target:
			draw_dashed_line(b.w2s(f.pos), b.w2s(f.target.pos), Color(1.0, 0.46, 0.31, 0.5), 1.5, 8.0)
		elif f.has_move:
			draw_dashed_line(b.w2s(f.pos), b.w2s(f.move_to), Color(0.37, 0.88, 0.81, 0.4), 1.5, 8.0)
	if b.selected.size() == 1:
		var f = b.selected[0]
		draw_polyline(_circle(f.pos, f.range_r, 64), Color(0.37, 0.88, 0.81, 0.28), 1.0)
		draw_polyline(_circle(f.pos, MISSILE_R, 64), Color(0.56, 0.71, 1.0, 0.22), 1.0)
	for f in b.selected:
		var pulse := 1.0 + sin(b.now_t * 3.8) * 0.04
		draw_polyline(_circle(f.pos, 62.0 * pulse, 40), Color(0.37, 0.88, 0.81, 0.95), 2.4)
	if b.inspect and not b.inspect.dead:
		draw_polyline(_circle(b.inspect.pos, 62.0, 40), Color(1.0, 0.46, 0.31, 0.85), 2.0)
	if not b.marker.is_empty():
		var k: float = b.marker.t / 1.2
		var col := Color(1.0, 0.46, 0.31, k) if b.marker.foe else Color(0.37, 0.88, 0.81, k)
		draw_polyline(_circle(b.marker.pos, 26.0 + (1.0 - k) * 14.0, 32), col, 3.0)
	# 함대 라벨
	for f in b.fleets:
		if not f.dead and b.G.state != "brief":
			_draw_label(f, font)
	for t in b.floats:
		var sp: Vector2 = b.w2s(t.pos)
		var a := minf(1.0, t.t * 1.5)
		draw_string_outline(font, sp + Vector2(-20.0, 0.0), t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color(0, 0, 0, 0.7 * a))
		draw_string(font, sp + Vector2(-20.0, 0.0), t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(t.color, a))
	if not b.drag.is_empty() and b.drag.mode == "box":
		var r := Rect2(b.drag.s, Vector2.ZERO).expand(b.drag.c)
		draw_rect(r, Color(0.37, 0.88, 0.81, 0.08))
		draw_rect(r, Color(0.37, 0.88, 0.81, 0.8), false, 1.0)

func _draw_label(f, font: Font) -> void:
	var r := label_rect(f)
	var sel: bool = b.selected.has(f) or b.inspect == f
	var foe: bool = f.side == 1
	var bar_col := BattleHud.C_FOE if foe else BattleHud.C_LIFE
	var frac: float = f.ships / f.max_ships
	if b.cam_z < 0.55:
		draw_rect(r, Color(0.02, 0.05, 0.04, 0.85))
		draw_rect(Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4.0) * frac, r.size.y - 4.0)), bar_col)
		if sel:
			draw_rect(r.grow(0.5), BattleHud.C_ALLY, false, 1.5)
	else:
		draw_rect(r, Color(0.13, 0.04, 0.03, 0.82) if foe else Color(0.02, 0.08, 0.07, 0.82))
		draw_rect(r, BattleHud.C_ALLY if sel else (Color(1.0, 0.46, 0.31, 0.55) if foe else Color(0.37, 0.88, 0.81, 0.45)), false, 2.0 if sel else 1.0)
		draw_texture_rect(b._portrait_tex(f.portrait), Rect2(r.position + Vector2(2, 2), Vector2(30, 30)), false)
		if f.is_flag:
			draw_string(font, r.position + Vector2(3, 12), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, BattleHud.C_GOLD)
		draw_string(font, r.position + Vector2(36, 13), "Lv.%02d" % f.lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e8f1ec"))
		var gx := r.end.x - 6.0
		var glyphs: Array = []
		if f.defense:
			glyphs.append(["DEF", BattleHud.C_ALLY])
		if f.charge_t > 0.0:
			glyphs.append(["ATK", BattleHud.C_GOLD])
		if not f.in_cmd:
			glyphs.append(["!", BattleHud.C_FOE])
		for g in glyphs:
			var w := font.get_string_size(g[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			draw_string(font, Vector2(gx - w, r.position.y + 12.0), g[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, g[1])
			gx -= w + 4.0
		draw_rect(Rect2(r.position + Vector2(36, 17), Vector2(58, 6)), Color("07100d"))
		draw_rect(Rect2(r.position + Vector2(37, 18), Vector2(56.0 * frac, 4)), bar_col)
		draw_rect(Rect2(r.position + Vector2(36, 26), Vector2(58, 4)), Color("07100d"))
		draw_rect(Rect2(r.position + Vector2(37, 27), Vector2(56.0 * (1.0 - f.missile_cd / 18.0), 2)), Color("3b5a8a") if f.missile_cd > 0.0 else Color("8fb6ff"))
	if f.speech_t > 0.0 and f.speech != "":
		var w := font.get_string_size(f.speech, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14.0
		var bx := r.position.x - 2.0
		var by := r.position.y - 24.0
		draw_rect(Rect2(bx, by, w, 19), Color(0.96, 0.97, 0.96, 0.95))
		draw_colored_polygon(PackedVector2Array([Vector2(bx + 10, by + 19), Vector2(bx + 16, by + 19), Vector2(bx + 10, by + 25)]), Color(0.96, 0.97, 0.96, 0.95))
		draw_string(font, Vector2(bx + 7, by + 14), f.speech, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("10201c"))
