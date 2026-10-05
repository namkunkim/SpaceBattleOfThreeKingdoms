class_name TacticalOverlay
extends Control

# 전장 위 2D 표시: 지휘 범위, 선택 함대 괄호와 사거리 부채꼴, 명령선과 도착 예상, 함대 명패, 대사, 떠오르는 글자.
# 입력은 받지 않는다(POC 입력 처리가 그대로 받는다). 명패 위치는 POC 클릭 판정(label_rect)과 맞춘다.

var battle: Node
var touch: TouchController
var t := 0.0

func setup(b: Node) -> void:
	battle = b
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	t += delta
	queue_redraw()

func _ground_ring(c: Vector2, r: float, n := 72, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := a0 + (a1 - a0) * i / n
		pts.append(battle.w2s(c + Vector2(cos(a), sin(a)) * r))
	return pts

func _draw() -> void:
	if battle == null or battle.G.is_empty() or battle.G.state == "brief":
		return
	var pf = battle.flag(0)
	var ef = battle.flag(1)
	if ef:
		draw_polyline(_ground_ring(ef.pos, battle.CMD_R), Color(UiTheme.FOE, 0.16), 1.2, true)
	if pf:
		var ring := _ground_ring(pf.pos, battle.CMD_R, 96)
		UiDraw.dashed_poly(self, ring, Color(UiTheme.ALLY, 0.32), 1.2, 3.0, 7.0)
		var ticks := PackedVector2Array()
		for i in 48:
			var a := TAU * i / 48.0
			var r0: float = battle.CMD_R
			var r1: float = r0 - (18.0 if i % 4 == 0 else 9.0)
			ticks.append(battle.w2s(pf.pos + Vector2(cos(a), sin(a)) * r0))
			ticks.append(battle.w2s(pf.pos + Vector2(cos(a), sin(a)) * r1))
		draw_multiline(ticks, Color(UiTheme.ALLY, 0.34), 1.0)
	var sel: Array = battle.my_sel()
	if sel.size() == 1:
		_weapon_arcs(sel[0])
	for f in sel:
		_orders(f)
		_brackets(f, UiTheme.GOLD_HI)
	if battle.inspect and not battle.inspect.dead:
		_brackets(battle.inspect, UiTheme.FOE)
	if not battle.marker.is_empty():
		var k: float = battle.marker.t / 1.2
		var col := Color(UiTheme.FOE, k) if battle.marker.foe else Color(UiTheme.GOLD_HI, k)
		draw_polyline(_ground_ring(battle.marker.pos, 22.0 + (1.0 - k) * 26.0, 40), col, 2.0, true)
		UiDraw.diamond(self, battle.w2s(battle.marker.pos), 5.0, col)
	var compact: bool = battle.cam_z < 0.55
	for f in battle.fleets:
		if not f.dead:
			if compact:
				_symbol(f)
			else:
				_plate(f)
	for f in battle.fleets:
		if not f.dead and f.speech_t > 0.0 and f.speech != "":
			_speech(f)
	for ft in battle.floats:
		var sp: Vector2 = battle.w2s(ft.pos)
		var a := minf(1.0, ft.t * 1.5)
		UiDraw.text(self, sp + Vector2(0, -6), ft.text, "serif_bold", 16, Color(ft.color, a), HORIZONTAL_ALIGNMENT_CENTER, 0.0, 4)
	if touch and not touch.order.is_empty() and touch.order.from_fleet:
		_touch_order(touch.order)
	if not battle.drag.is_empty() and battle.drag.mode == "box":
		var r := Rect2(battle.drag.s, Vector2.ZERO).expand(battle.drag.c)
		draw_rect(r, Color(UiTheme.GOLD_HI, 0.06))
		draw_rect(r, Color(UiTheme.GOLD_HI, 0.85), false, 1.0)

func _weapon_arcs(f) -> void:
	# 광선 사거리 부채꼴(정면 ±60°)과 미사일 사거리 파선 원
	var half := PI / 3.0
	var arc := _ground_ring(f.pos, f.range_r, 40, f.heading - half, f.heading + half)
	var fan := PackedVector2Array([battle.w2s(f.pos)])
	fan.append_array(arc)
	var cols := PackedColorArray()
	cols.append(Color(UiTheme.ALLY, 0.0))
	for i in arc.size():
		cols.append(Color(UiTheme.ALLY, 0.11))
	draw_polygon(fan, cols)
	draw_polyline(arc, Color(UiTheme.ALLY_HI, 0.6), 1.4, true)
	UiDraw.dashed_poly(self, _ground_ring(f.pos, battle.MISSILE_R, 96), Color(UiTheme.CP, 0.4), 1.2, 10.0, 7.0)
	var lp: Vector2 = arc[arc.size() - 1]
	UiDraw.text(self, lp + Vector2(8, 14), "광선 사거리", "medium", 11, Color(UiTheme.ALLY_HI, 0.8), HORIZONTAL_ALIGNMENT_LEFT, -1, 3)

func _orders(f) -> void:
	var a: Vector2 = battle.w2s(f.pos)
	if f.target and not f.target.dead:
		var b: Vector2 = battle.w2s(f.target.pos)
		UiDraw.dashed_poly(self, PackedVector2Array([a, b]), Color(UiTheme.FOE, 0.7), 1.6, 9.0, 6.0, -t * 30.0)
		_reticle(b, Color(UiTheme.FOE, 0.9))
	elif f.has_move:
		var b: Vector2 = battle.w2s(f.move_to)
		UiDraw.dashed_poly(self, PackedVector2Array([a, b]), Color(UiTheme.GOLD_HI, 0.8), 1.6, 9.0, 6.0, -t * 30.0)
		var dir: Vector2 = (f.move_to - f.pos).normalized()
		var tip: Vector2 = battle.w2s(f.move_to + dir * 46.0)
		var l: Vector2 = battle.w2s(f.move_to + dir * 22.0 + dir.orthogonal() * 14.0)
		var r: Vector2 = battle.w2s(f.move_to + dir * 22.0 - dir.orthogonal() * 14.0)
		draw_colored_polygon(PackedVector2Array([tip, l, r]), Color(UiTheme.GOLD_HI, 0.85))
		UiDraw.diamond(self, b, 5.0, Color(UiTheme.GOLD_HI, 0.9), false)
		var spd: float = 62.0 * f.spd * (0.5 if f.defense else 1.0)
		var eta := int(f.pos.distance_to(f.move_to) / maxf(1.0, spd))
		var label := "도착 %d:%02d" % [eta / 60, eta % 60]
		var w := UiDraw.text_w(label, "semibold", 12) + 18.0
		var box := Rect2(b + Vector2(-w * 0.5, 14.0), Vector2(w, 22.0))
		draw_rect(box, Color(0.03, 0.05, 0.07, 0.88))
		draw_rect(box, Color(UiTheme.GOLD_HI, 0.6), false, 1.0)
		UiDraw.text(self, box.position + Vector2(9, 15.5), label, "semibold", 12, UiTheme.GOLD_HI)

func _reticle(c: Vector2, col: Color) -> void:
	var r := 16.0 + sin(t * 5.0) * 1.5
	for i in 4:
		var a := i * PI * 0.5 + PI * 0.25
		draw_arc(c, r, a - 0.45, a + 0.45, 8, col, 1.6, true)
	draw_line(c + Vector2(-r - 6, 0), c + Vector2(-r + 2, 0), col, 1.4)
	draw_line(c + Vector2(r - 2, 0), c + Vector2(r + 6, 0), col, 1.4)

func _brackets(f, col: Color) -> void:
	# 함대 방향에 맞춘 모서리 괄호와 진행 방향 화살표
	var hx := Vector2(cos(f.heading), sin(f.heading))
	var hy := hx.orthogonal()
	var bx := 110.0
	var by := 120.0
	var pulse := 1.0 + sin(t * 3.4) * 0.02
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var c: Vector2 = f.pos + (hx * bx * sx + hy * by * sy) * pulse
			var p0: Vector2 = battle.w2s(c - hx * 30.0 * sx)
			var p1: Vector2 = battle.w2s(c)
			var p2: Vector2 = battle.w2s(c - hy * 30.0 * sy)
			draw_polyline(PackedVector2Array([p0, p1, p2]), Color(col, 0.9), 1.6, true)
	var tip: Vector2 = battle.w2s(f.pos + hx * (bx + 44.0))
	var l: Vector2 = battle.w2s(f.pos + hx * (bx + 18.0) + hy * 15.0)
	var r: Vector2 = battle.w2s(f.pos + hx * (bx + 18.0) - hy * 15.0)
	draw_colored_polygon(PackedVector2Array([tip, l, r]), Color(col, 0.85))

func _plate(f) -> void:
	# 명패(V-6): 소유 글리프 · 이름 · 연속 막대 · 지휘 상태 · 가장 급한 경고 하나. 초상·레벨 없음.
	var s: Vector2 = battle.w2s(f.pos)
	var foe: bool = f.side == 1
	var sel: bool = battle.selected.has(f) or battle.inspect == f
	var r := Rect2(s.x - 22.0, s.y - 58.0, 98.0, 34.0)   # 클릭 판정(FleetLabels.label_rect)과 같다
	var src: BattleSource = battle.presentation.src
	var fk := src.faction(f.id)
	var sc: Color = Factions.of(fk).color
	draw_line(Vector2(s.x, r.end.y), Vector2(s.x, s.y - 8.0), Color(sc, 0.45), 1.0)
	draw_circle(Vector2(s.x, s.y - 8.0), 2.0, Color(sc, 0.8))
	draw_rect(r, Color(0.16, 0.055, 0.04, 0.78) if foe else Color(0.03, 0.07, 0.09, 0.78))
	draw_rect(r, UiTheme.GOLD_HI if sel else Color(sc, 0.5), false, 1.5 if sel else 1.0)
	if sel:
		draw_rect(r.grow(2.5), Color(UiTheme.GOLD_HI, 0.3), false, 1.0)
	UiDraw.faction_glyph(self, r.position + Vector2(12, 13), 5.0, fk, sc)
	if f.is_flag:
		UiDraw.text(self, r.position + Vector2(20, 14), "旗", "serif_bold", 10, UiTheme.GOLD_HI, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	var nx := 33.0 if f.is_flag else 22.0
	UiDraw.text(self, r.position + Vector2(nx, 17), f.fname, "serif_bold", 13, UiTheme.INK)
	# 지휘 상태: ● 직접 / ○ 위임(Q20). 코어가 값을 주기 전에는 그리지 않는다.
	var cm := src.command_mode(f.id) if not foe else ""
	if cm != "":
		var dp := r.end - Vector2(24, 21)
		draw_circle(dp, 3.6, Color(0.02, 0.03, 0.05, 0.9))
		if cm == "direct":
			draw_circle(dp, 2.6, sc)
		else:
			draw_arc(dp, 2.6, 0.0, TAU, 12, sc, 1.2, true)
	# 가장 급한 경고 하나: 지휘 범위 밖 > 돌격 > 방어진형
	var tag := ""
	var tcol := UiTheme.WARN
	if not f.in_cmd and not foe:
		tag = "warn"
	elif f.charge_t > 0.0:
		tag = "charge"
		tcol = UiTheme.GOLD_HI
	elif f.defense:
		tag = "def"
		tcol = UiTheme.ALLY_HI
	if tag != "":
		UiDraw.icon(self, tag, Rect2(r.end.x - 18.0, r.position.y + 5.0, 14, 14), tcol, 1.3)
	var frac: float = f.ships / f.max_ships
	var bar := Rect2(r.position + Vector2(6, 23), Vector2(86, 5))
	draw_rect(bar, UiTheme.SLOT)
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * frac, bar.size.y)), UiTheme.FOE if foe else UiTheme.LIFE)
	if not foe:
		var cd: float = 1.0 - f.missile_cd / 18.0
		draw_rect(Rect2(r.position + Vector2(6, 30), Vector2(86, 2)), UiTheme.SLOT)
		draw_rect(Rect2(r.position + Vector2(6, 30), Vector2(86 * cd, 2)), UiTheme.CP if f.missile_cd <= 0.0 else Color(UiTheme.CP, 0.45))

func _symbol(f) -> void:
	# 원거리: 진영 기호 + 방향 + 이름
	var s: Vector2 = battle.w2s(f.pos)
	var fk: String = battle.presentation.src.faction(f.id)
	var sc: Color = Factions.of(fk).color
	var sel: bool = battle.selected.has(f)
	UiDraw.faction_glyph(self, s + Vector2(0, -28), 6.0, fk, sc)
	if f.is_flag:
		draw_rect(Rect2(s + Vector2(-10, -38), Vector2(20, 20)), UiTheme.GOLD_HI, false, 1.2)
	var hd := Vector2(cos(f.heading), sin(f.heading))
	draw_line(s + Vector2(0, -28), s + Vector2(0, -28) + hd * 14.0, sc, 1.6, true)
	UiDraw.text(self, s + Vector2(10, -24), f.fname, "serif_bold", 12, UiTheme.GOLD_HI if sel else UiTheme.INK_2, HORIZONTAL_ALIGNMENT_LEFT, -1, 3)
	var rr := Rect2(s.x - 24.0, s.y - 18.0, 48.0, 4.0)
	draw_rect(rr, UiTheme.SLOT)
	draw_rect(Rect2(rr.position, Vector2(48.0 * f.ships / f.max_ships, 4.0)), UiTheme.FOE if f.side == 1 else UiTheme.LIFE)

func _speech(f) -> void:
	var s: Vector2 = battle.w2s(f.pos)
	var fs := 13
	var w := UiDraw.text_w(f.speech, "medium", fs) + 22.0
	var r := Rect2(s.x - 22.0, s.y - 96.0, w, 26.0)
	var a: float = clampf(f.speech_t / 0.4, 0.0, 1.0)
	draw_rect(r, Color(0.03, 0.045, 0.07, 0.92 * a))
	draw_rect(Rect2(r.position, Vector2(3, r.size.y)), Color(UiTheme.side_color(f.side), a))
	draw_rect(r, Color(UiTheme.GOLD, 0.45 * a), false, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + 14, r.end.y), Vector2(r.position.x + 22, r.end.y), Vector2(r.position.x + 14, r.end.y + 6)]), Color(0.03, 0.045, 0.07, 0.92 * a))
	UiDraw.text(self, r.position + Vector2(12, 17.5), f.speech, "medium", fs, Color(UiTheme.INK, a))

func _touch_order(o: Dictionary) -> void:
	# 손가락으로 끄는 명령의 미리보기: 이동(금) / 공격(적색) / 취소(회색, 출발 함대 위)
	var a: Vector2 = battle.w2s(o.from_fleet.pos)
	var b: Vector2 = o.to
	var col := UiTheme.GOLD_HI
	var label := "이동"
	if o.cancel:
		col = UiTheme.INK_3
		label = "취소"
	elif o.target:
		col = UiTheme.FOE
		label = "공격 · %s" % o.target.fname
	draw_arc(a, touch.CANCEL_R, 0.0, TAU, 40, Color(UiTheme.INK_3, 0.5), 1.2, true)
	if not o.cancel:
		UiDraw.dashed_poly(self, PackedVector2Array([a, b]), Color(col, 0.9), 2.0, 10.0, 6.0, -t * 40.0)
		if o.target:
			_reticle(battle.w2s(o.target.pos), col)
		else:
			draw_arc(b, 18.0, 0.0, TAU, 32, Color(col, 0.9), 2.0, true)
			UiDraw.diamond(self, b, 5.0, col)
	var w := UiDraw.text_w(label, "semibold", 13) + 20.0
	var box := Rect2(b + Vector2(-w * 0.5, -58.0), Vector2(w, 26.0))
	draw_rect(box, Color(0.03, 0.05, 0.07, 0.9))
	draw_rect(box, Color(col, 0.7), false, 1.0)
	UiDraw.text(self, box.position + Vector2(10, 18), label, "semibold", 13, col)
