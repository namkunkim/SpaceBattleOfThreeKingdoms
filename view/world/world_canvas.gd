class_name WorldCanvas
extends Control

# 천하 지도 캔버스(docs/battle-core/WORLD-MAP-LINK.md §4). 한 카메라의 연속 확대로 Z0 천하 → Z2 형주 → Z3 구지 행성계.
# 좌표는 본편 지도 v3 월드 좌표를 그대로 쓴다(data/scenarios/base/world_208.json). 세분화는 구지 행성계 한 곳뿐이다.
# 입력: 한 손가락 끌기 = 이동, 두 손가락 = 확대·이동, 탭 = 선택. PC는 끌기·휠·트랙패드 제스처.

signal system_tapped(id: String)
signal region_tapped(id: String)
signal marker_tapped
signal level_changed(level: String)

const BG := "res://assets/backgrounds/red_cliffs_starfield_v1.png"
const LEVELS := ["z0", "z2", "z3"]
const TAP_SLOP := 14.0        # 이 거리(화면 단위) 안에서 떼면 탭
const SYS_HIT := 44.0         # 성계 탭 반경(48dp 목표에 맞춘 화면 단위)
const MARKER_HIT := 52.0
# 구지 궤도의 진영 위치(월드 단위, 구지 기준). 전장 방위와 같다: 조조 동쪽, 연합 서쪽.
const WULIN_OFS := Vector2(32, -10)
const CHIBI_OFS := Vector2(-32, 10)

var world: Dictionary = {}
var sys_by_id := {}
var owners_rgn := {}
var _rgn_from := {}
var _rgn_mix := 1.0
var center := Vector2.ZERO
var zoom := 0.05
var inset := Vector4.ZERO      # 패널이 가리는 가장자리(왼, 위, 오른, 아래). 맞춤 계산에서 뺀다
var input_lock := false
var arrows := ""               # "" | "advance"(Z0 조조 남하) | "sortie"(Z3 양군 진입)
var battle_live := false       # 자동 해결 중: 전장 표식을 더 세게 깜빡인다
var t := 0.0

var _bg: Texture2D
var _tw := {}
var _touches := {}
var _press := Vector2.ZERO
var _moved := false
var _vel := Vector2.ZERO
var _level := ""
var _mouse_down := false
var _drag_acc := 0.0

func setup(w: Dictionary) -> void:
	world = w
	for s in world.systems:
		sys_by_id[s.id] = s
	for r in world.regions:
		owners_rgn[r.id] = r.owner
	_bg = load(BG) as Texture2D if ResourceLoader.exists(BG) else null
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_on_resized)

func _on_resized() -> void:
	if _tw.is_empty() and _level != "":
		var v := view_of(_level)
		center = v[0]
		zoom = v[1]

# ------------------------------------------------------------ 좌표
func w2s(w: Vector2) -> Vector2:
	return (w - center) * zoom + size * 0.5

func s2w(s: Vector2) -> Vector2:
	return (s - size * 0.5) / zoom + center

static func v2(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))

func focus_pos() -> Vector2:
	for b in world.bodies:
		if b.id == world.focus.body:
			return v2(b.pos)
	return v2(sys_by_id[world.focus.system].pos)

func level_rect(level: String) -> Rect2:
	var pts: Array = []
	match level:
		"z0":
			for s in world.systems:
				pts.append(v2(s.pos))
		"z2":
			for r in world.regions:
				for p in r.boundary:
					pts.append(v2(p))
		_:
			for b in world.bodies:
				pts.append(v2(b.pos))
	var rc := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		rc = rc.expand(p)
	match level:
		"z0":
			return rc.grow(380.0)
		"z2":
			return rc.grow(120.0)
	return rc.grow(70.0)

# 패널이 가리는 곳을 뺀 영역에 맞춘 [중심, 배율]
func view_of(level: String) -> Array:
	var rc := level_rect(level)
	var avail := Vector2(maxf(200.0, size.x - inset.x - inset.z), maxf(200.0, size.y - inset.y - inset.w))
	var z := minf(avail.x / rc.size.x, avail.y / rc.size.y)
	var off := Vector2(inset.x - inset.z, inset.y - inset.w) * 0.5   # 가용 영역 중심이 화면 중심에서 벗어난 만큼
	return [rc.get_center() - off / z, z]

func zoom_limits() -> Vector2:
	return Vector2(view_of("z0")[1] * 0.8, view_of("z3")[1] * 1.8)

func level() -> String:
	return _level

func _update_level() -> void:
	# 가장 가까운 배율(로그 거리)의 단계를 현재 단계로 본다
	var best := "z0"
	var bd := INF
	for l in LEVELS:
		var d := absf(log(zoom) - log(float(view_of(l)[1])))
		if d < bd:
			bd = d
			best = l
	if best != _level:
		_level = best
		level_changed.emit(best)

# ------------------------------------------------------------ 카메라 이동
func jump_to(level: String) -> void:
	var v := view_of(level)
	center = v[0]
	zoom = v[1]
	_tw = {}
	_update_level()

func fly_to(level: String, dur := 1.2) -> void:
	var v := view_of(level)
	_tw = {"c0": center, "z0": zoom, "c1": v[0], "z1": float(v[1]), "t": 0.0, "dur": maxf(0.05, dur)}
	_vel = Vector2.ZERO

func flying() -> bool:
	return not _tw.is_empty()

func zoom_at(sp: Vector2, f: float) -> void:
	var lim := zoom_limits()
	var w := s2w(sp)
	zoom = clampf(zoom * f, lim.x, lim.y)
	center = w - (sp - size * 0.5) / zoom
	_update_level()

func set_region_owners(o: Dictionary, animate := true) -> void:
	_rgn_from = owners_rgn.duplicate()
	owners_rgn = o.duplicate()
	_rgn_mix = 0.0 if animate else 1.0

func _process(delta: float) -> void:
	t += delta
	if not _tw.is_empty():
		_tw.t += delta
		var k := clampf(_tw.t / _tw.dur, 0.0, 1.0)
		var e := k * k * (3.0 - 2.0 * k)
		# 배율은 로그로, 중심은 화면 위치가 자연스럽게 보이도록 배율 보정 보간
		var lz := lerpf(log(_tw.z0), log(_tw.z1), e)
		zoom = exp(lz)
		center = (_tw.c0 as Vector2).lerp(_tw.c1, e)
		if k >= 1.0:
			_tw = {}
		_update_level()
	elif _vel.length() > 2.0 and _touches.is_empty() and not _mouse_down:
		center -= _vel * delta / zoom
		_vel *= pow(0.02, delta)
	if _rgn_mix < 1.0:
		_rgn_mix = minf(1.0, _rgn_mix + delta / 1.4)
	queue_redraw()

# ------------------------------------------------------------ 입력
func _gui_input(ev: InputEvent) -> void:
	if input_lock:
		return
	if ev is InputEventScreenTouch:
		var st := ev as InputEventScreenTouch
		if st.pressed:
			_touches[st.index] = st.position
			if _touches.size() == 1:
				_press = st.position
				_moved = false
				_drag_acc = 0.0
				_tw = {}
				_vel = Vector2.ZERO
			else:
				_moved = true
		else:
			_touches.erase(st.index)
			if _touches.is_empty() and not _moved:
				_tap(st.position)
		accept_event()
	elif ev is InputEventScreenDrag:
		var sd := ev as InputEventScreenDrag
		var prev: Vector2 = _touches.get(sd.index, sd.position - sd.relative)
		_touches[sd.index] = sd.position
		if _touches.size() == 1:
			_pan(sd.relative)
			_vel = sd.velocity
		elif _touches.size() >= 2:
			var other := Vector2.ZERO
			for k in _touches:
				if k != sd.index:
					other = _touches[k]
					break
			var d0 := prev.distance_to(other)
			var d1 := sd.position.distance_to(other)
			var mid := (sd.position + other) * 0.5
			if d0 > 4.0:
				zoom_at(mid, d1 / d0)
			_pan(sd.relative * 0.5)
			_moved = true
		accept_event()
	elif ev is InputEventMouseButton:
		var mb := ev as InputEventMouseButton
		if mb.device == InputEvent.DEVICE_ID_EMULATION:
			return   # 터치를 흉내 낸 마우스는 위에서 이미 처리했다
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_tw = {}
			zoom_at(mb.position, 1.15)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_tw = {}
			zoom_at(mb.position, 1.0 / 1.15)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			_mouse_down = mb.pressed
			if mb.pressed:
				_press = mb.position
				_moved = false
				_drag_acc = 0.0
				_tw = {}
				_vel = Vector2.ZERO
			elif not _moved:
				_tap(mb.position)
		accept_event()
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if mm.device == InputEvent.DEVICE_ID_EMULATION:
			return
		if _mouse_down:
			_pan(mm.relative)
			_vel = mm.velocity
			accept_event()
	elif ev is InputEventMagnifyGesture:
		var mg := ev as InputEventMagnifyGesture
		_tw = {}
		zoom_at(mg.position, mg.factor)
		accept_event()
	elif ev is InputEventPanGesture:
		_tw = {}
		_pan(-(ev as InputEventPanGesture).delta * 8.0)
		accept_event()

func _pan(rel: Vector2) -> void:
	_tw = {}
	center -= rel / zoom
	_drag_acc += rel.length()
	if _drag_acc > TAP_SLOP:
		_moved = true
	_clamp_center()
	_update_level()

func _clamp_center() -> void:
	var rc := level_rect("z0")
	center = center.clamp(rc.position, rc.end)

func _tap(sp: Vector2) -> void:
	if _marker_visible() and w2s(focus_pos()).distance_to(sp) <= MARKER_HIT:
		marker_tapped.emit()
		return
	var best := ""
	var bd := SYS_HIT
	for s in world.systems:
		var d := w2s(v2(s.pos)).distance_to(sp)
		if d < bd:
			bd = d
			best = s.id
	if best != "" and not _regions_visible():
		system_tapped.emit(best)
		return
	if _regions_visible():
		var w := s2w(sp)
		for r in world.regions:
			var poly := PackedVector2Array()
			for p in r.boundary:
				poly.append(v2(p))
			if Geometry2D.is_point_in_polygon(w, poly):
				region_tapped.emit(r.id)
				return
	if best != "":
		system_tapped.emit(best)

# 테스트·자동 조작용: 화면 좌표 탭
func tap_at(sp: Vector2) -> void:
	_tap(sp)

# ------------------------------------------------------------ 표시 단계(배율로 섞는다)
func _k(level_a: String, level_b: String) -> float:
	# 배율이 a 단계에서 b 단계로 갈수록 0 → 1
	var a := log(float(view_of(level_a)[1]))
	var b := log(float(view_of(level_b)[1]))
	return clampf((log(zoom) - a) / maxf(0.001, b - a), 0.0, 1.0)

func _regions_visible() -> bool:
	return _k("z0", "z2") > 0.45

func _bodies_alpha() -> float:
	return clampf((_k("z2", "z3") - 0.35) / 0.4, 0.0, 1.0)

func _marker_visible() -> bool:
	return _bodies_alpha() < 0.6

static func faction_color(key: String) -> Color:
	match key:
		"wei", "wu", "shu":
			return Factions.of(key).color
		"contested":
			return UiTheme.WARN
		"none":
			return UiTheme.INK_4
	return UiTheme.INK_3

func _rgn_color(id: String) -> Color:
	var to := faction_color(owners_rgn.get(id, "other"))
	if _rgn_mix >= 1.0:
		return to
	return faction_color(_rgn_from.get(id, "other")).lerp(to, _rgn_mix)

# ------------------------------------------------------------ 그리기
func _draw() -> void:
	_draw_bg()
	if world.is_empty():
		return
	var k_reg := _k("z0", "z2")
	var a_body := _bodies_alpha()
	var a_sys := 1.0 - a_body * 0.85
	_draw_territory(a_sys)
	_draw_routes(a_sys)
	if k_reg > 0.3:
		_draw_regions(clampf((k_reg - 0.3) / 0.4, 0.0, 1.0) * (1.0 - a_body * 0.7))
	_draw_systems(a_sys, k_reg)
	if a_body > 0.0:
		_draw_solar(a_body)
	if _marker_visible():
		_draw_marker(1.0 - a_body / 0.6)
	if arrows == "advance" and k_reg < 0.6:
		_draw_advance(1.0 - k_reg / 0.6)
	if arrows == "sortie" and a_body > 0.5:
		_draw_sortie(clampf((a_body - 0.5) * 2.0, 0.0, 1.0))

func _draw_bg() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.012, 0.02, 0.035))
	if _bg:
		var ts := Vector2(_bg.get_size())
		var sc := maxf(size.x / ts.x, size.y / ts.y) * 1.15
		var par := Vector2(fposmod(center.x * 0.004, ts.x * 0.1), fposmod(center.y * 0.004, ts.y * 0.1))
		var rc := Rect2(size * 0.5 - ts * sc * 0.5 - par, ts * sc)
		draw_texture_rect(_bg, rc, false, Color(1, 1, 1, 0.55))
	# 가장자리 어둡게(비네트)
	var v := Color(0, 0, 0, 0.45)
	draw_rect(Rect2(0, 0, size.x, 40), v)
	draw_rect(Rect2(0, size.y - 40, size.x, 40), v)

func _draw_territory(a: float) -> void:
	# 세력 영역: 성계마다 부드러운 원 세 겹
	var r0 := 950.0 * zoom
	if r0 < 6.0:
		return
	for s in world.systems:
		var c := faction_color(s.owner)
		var p := w2s(v2(s.pos))
		for i in 3:
			draw_circle(p, r0 * (1.0 - i * 0.28), Color(c, 0.035 * a))

func _draw_routes(a: float) -> void:
	for r in world.routes:
		var pts := PackedVector2Array()
		for p in r.line:
			pts.append(w2s(v2(p)))
		var kind: String = r.kind
		if r.yangtze:
			draw_polyline(pts, Color(UiTheme.GOLD, 0.22 * a), 7.0, true)
			UiDraw.dashed_poly(self, pts, Color(UiTheme.GOLD_HI, 0.85 * a), 2.2, 14.0, 9.0, -t * 26.0)
		elif kind.begins_with("고속항로"):
			draw_polyline(pts, Color(UiTheme.GOLD, 0.45 * a), 1.8, true)
		elif kind == "회랑":
			UiDraw.dashed_poly(self, pts, Color(UiTheme.INK_3, 0.55 * a), 1.6, 6.0, 6.0)
		else:
			draw_polyline(pts, Color(UiTheme.LINE.lightened(0.15), 0.8 * a), 1.2, true)

func _draw_regions(a: float) -> void:
	for r in world.regions:
		var poly := PackedVector2Array()
		for p in r.boundary:
			poly.append(w2s(v2(p)))
		var c := _rgn_color(r.id)
		draw_colored_polygon(poly, Color(c, 0.16 * a))
		var ring := poly.duplicate()
		ring.append(poly[0])
		draw_polyline(ring, Color(c, 0.75 * a), 2.0, true)
		var cp := Vector2.ZERO
		for p in poly:
			cp += p
		cp /= poly.size()
		UiDraw.text(self, cp + Vector2(0, -6), r.name, "serif_bold", 20, Color(UiTheme.INK, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 4)
		UiDraw.text(self, cp + Vector2(0, 16), r.label, "medium", 14, Color(UiTheme.INK_2, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 3)
		var ok: String = owners_rgn.get(r.id, "other")
		if ok in ["wei", "wu", "shu"]:
			UiDraw.faction_seal(self, Rect2(cp + Vector2(-13, 26), Vector2(26, 26)), ok)

func _draw_systems(a: float, k_reg: float) -> void:
	var focus: String = world.focus.system
	for s in world.systems:
		var p := w2s(v2(s.pos))
		if p.x < -80 or p.y < -80 or p.x > size.x + 80 or p.y > size.y + 80:
			continue
		var c := faction_color(s.owner)
		var is_f: bool = s.id == focus
		var aa := a * (1.0 - k_reg)
		if aa <= 0.02:
			continue
		var r := 9.0 if not is_f else 12.0
		if is_f:
			var pulse := 0.5 + 0.5 * sin(t * 2.4)
			draw_arc(p, 22.0 + pulse * 6.0, 0.0, TAU, 40, Color(UiTheme.GOLD_HI, (0.35 + 0.4 * pulse) * aa), 2.0, true)
		if s.owner in ["wei", "wu", "shu"]:
			UiDraw.faction_glyph(self, p, r, s.owner, Color(c, aa))
		else:
			draw_circle(p, r * 0.8, Color(c, aa))
			draw_arc(p, r, 0.0, TAU, 24, Color(UiTheme.INK, 0.5 * aa), 1.2, true)
		var fs := 19 if not is_f else 24
		if is_f:   # 형주는 남양·조조 남하 화살표와 겹치지 않게 왼쪽에 쓴다
			UiDraw.text(self, p + Vector2(-r - 22, 8), s.name, "serif_bold", fs, Color(UiTheme.GOLD_HI, aa), HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 4)
		else:
			UiDraw.text(self, p + Vector2(0, -r - 10), s.name, "semibold", fs, Color(UiTheme.INK, aa), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 4)
		if s.holder != "" and zoom > view_of("z0")[1] * 1.3:
			UiDraw.text(self, p + Vector2(0, r + 20), s.holder, "regular", 13, Color(UiTheme.INK_3, aa), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 3)

func _body(id: String) -> Dictionary:
	for b in world.bodies:
		if b.id == id:
			return b
	return {}

func _draw_solar(a: float) -> void:
	var sun := _body("BODY-RGN-04-01-STAR")
	var sp := w2s(v2(sun.pos))
	# 궤도
	for b in world.bodies:
		if b.kind in ["planet", "terran"]:
			var d := v2(b.pos).distance_to(v2(sun.pos)) * zoom
			draw_arc(sp, d, 0.0, TAU, 128, Color(UiTheme.INK_3, 0.25 * a), 1.0, true)
	# 태양
	var sr := float(sun.radius) * zoom * 0.32
	for i in 4:
		draw_circle(sp, sr * (1.0 + i * 0.45), Color(1.0, 0.78, 0.4, 0.08 * a))
	draw_circle(sp, sr, Color(1.0, 0.86, 0.55, a))
	for b in world.bodies:
		if b.kind == "star":
			continue
		var p := w2s(v2(b.pos))
		var rr := maxf(4.0, float(b.radius) * zoom * 0.35)
		var col: Color = Color("8fb4d8")
		match b.name:
			"구지": col = Color("5fa8d3")
			"형혹": col = Color("c8714f")
			"목성": col = Color("c9a77a")
			"금성": col = Color("d9c38f")
			"태음": col = Color("c9ced6")
		if b.id == world.focus.body:
			draw_circle(p, rr * 2.6, Color(UiTheme.WARN, 0.10 * a))
			draw_arc(p, rr * 2.6, 0.0, TAU, 48, Color(UiTheme.WARN, 0.6 * a), 1.5, true)
		draw_circle(p, rr, Color(col, a))
		draw_arc(p, rr, PI * 0.15, PI * 1.15, 24, Color(0, 0, 0, 0.35 * a), rr * 0.5, true)
		var fs := 16 if b.id != world.focus.body else 22
		UiDraw.text(self, p + Vector2(0, -rr - 8), b.name, "semibold" if fs == 16 else "serif_bold", fs, Color(UiTheme.INK, a), HORIZONTAL_ALIGNMENT_CENTER, -1.0, 4)
	# 오림(조조, 동)·적벽(연합, 서)
	var g := focus_pos()
	var wp := w2s(g + WULIN_OFS)
	var cp := w2s(g + CHIBI_OFS)
	UiDraw.faction_glyph(self, wp, 10.0, "wei", Color(Factions.of("wei").color, a))
	UiDraw.text(self, wp + Vector2(16, 6), str(world.edge_labels.get("cao_side", "오림")), "serif_bold", 20, Color(Factions.of("wei").rim, a), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)
	UiDraw.faction_glyph(self, cp, 10.0, "wu", Color(Factions.of("wu").color, a))
	UiDraw.text(self, cp + Vector2(-16, 6), str(world.edge_labels.get("alliance_side", "적벽")), "serif_bold", 20, Color(Factions.of("wu").rim, a), HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 4)

func _draw_marker(a: float) -> void:
	var p := w2s(focus_pos())
	var sp := 2.4 if not battle_live else 6.0
	var pulse := 0.5 + 0.5 * sin(t * sp)
	var col: Color = UiTheme.WARN if not battle_live else Factions.of("wei").color
	draw_circle(p, 18.0, Color(0.03, 0.04, 0.07, 0.85 * a))
	draw_arc(p, 18.0, 0.0, TAU, 40, Color(col, a), 2.0, true)
	draw_arc(p, 24.0 + pulse * 12.0, 0.0, TAU, 48, Color(col, (1.0 - pulse) * 0.8 * a), 2.0, true)
	# 엇갈린 칼(교전 표식)
	draw_line(p + Vector2(-8, -8), p + Vector2(8, 8), Color(UiTheme.INK, a), 2.4, true)
	draw_line(p + Vector2(8, -8), p + Vector2(-8, 8), Color(UiTheme.INK, a), 2.4, true)
	UiDraw.text(self, p + Vector2(28, 7), "적벽", "serif_bold", 22, Color(UiTheme.GOLD_HI, a), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 4)

func _arrow(pts: PackedVector2Array, col: Color, w := 3.0, flow := true) -> void:
	if flow:
		UiDraw.dashed_poly(self, pts, col, w, 16.0, 8.0, -t * 40.0)
	else:
		draw_polyline(pts, col, w, true)
	var n := pts.size()
	var tip := pts[n - 1]
	var dir := (tip - pts[n - 2]).normalized()
	var nrm := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([tip + dir * 6.0, tip - dir * 14.0 + nrm * 9.0, tip - dir * 14.0 - nrm * 9.0]), col)

static func _curve(a: Vector2, b: Vector2, bend: float, n := 24) -> PackedVector2Array:
	var mid := (a + b) * 0.5
	var d := b - a
	var ctl := mid + Vector2(-d.y, d.x).normalized() * d.length() * bend
	var out := PackedVector2Array()
	for i in n + 1:
		var u := float(i) / n
		out.append(a.lerp(ctl, u).lerp(ctl.lerp(b, u), u))
	return out

func _draw_advance(a: float) -> void:
	var from := w2s(v2(sys_by_id[world.focus.advance_from].pos)) + Vector2(-10, -24)
	var to := w2s(focus_pos()) + Vector2(-14, -20)
	_arrow(_curve(from, to, 0.18), Color(Factions.of("wei").color, 0.9 * a), 3.0)
	UiDraw.text(self, from + Vector2(-16, -8), "조조 남하", "semibold", 16, Color(Factions.of("wei").rim, a), HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 4)

func _draw_sortie(a: float) -> void:
	var g := focus_pos()
	var wp := w2s(g + WULIN_OFS)
	var cp := w2s(g + CHIBI_OFS)
	var e0 := Vector2(size.x - inset.z - 40.0, inset.y + 60.0)
	var a0 := Vector2(inset.x + 40.0, size.y - inset.w - 90.0)
	_arrow(_curve(e0, wp + Vector2(10, -14), -0.15), Color(Factions.of("wei").color, 0.85 * a), 3.0)
	_arrow(_curve(a0, cp + Vector2(-12, 12), 0.15), Color(Factions.of("wu").color, 0.85 * a), 3.0)
	UiDraw.text(self, e0 + Vector2(-8, 28), "조조군 · " + str(world.edge_labels.get("cao_exit", "")) + " · 규모 추정", "medium", 15, Color(UiTheme.INK_2, a), HORIZONTAL_ALIGNMENT_RIGHT, -1.0, 3)
	UiDraw.text(self, a0 + Vector2(8, 28), "연합 · " + str(world.edge_labels.get("alliance_exit", "")) + "에서", "medium", 15, Color(UiTheme.INK_2, a), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 3)
