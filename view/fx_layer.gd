class_name FxLayer
extends Control

# POC 전투 연출 오버레이: 사격선, 함재기, 미사일, 폭발 파편, 띄우는 글자.
# 연출 난수는 이 파일의 전용 생성기만 쓴다. 규칙 난수(BattleRng)와 전역 난수열을 건드리지 않으므로
# 그리는 프레임 수가 전투 결과를 바꾸지 않는다(제안서 §3.3, M1 3단계).

class Part:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 1.0
	var maxl := 1.0
	var size := 1.0
	var col := Color.WHITE
	var ring := false

class Floaty:
	var pos := Vector2.ZERO
	var text := ""
	var color := Color.WHITE
	var t := 1.4

var rng := RandomNumberGenerator.new()
var parts: Array[Part] = []
var floats: Array[Floaty] = []
var rig: CameraRig
var vm: BattleViewModel
var active := true            # 브리핑에서는 그리지 않는다

func setup(camera_rig: CameraRig, model: BattleViewModel) -> void:
	rig = camera_rig
	vm = model
	rng.randomize()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add_mat

func clear() -> void:
	parts.clear()
	floats.clear()

func ship_pos(f: BattleViewModel.FleetView, i: int) -> Vector2:
	return f.pos + f.form[i % f.form.size()].rotated(f.heading)

func rand_ship(f: BattleViewModel.FleetView) -> Vector2:
	return ship_pos(f, rng.randi() % BattleView3D.visible_ships(f.ships, f.max_ships))

func float_text(p: Vector2, text: String, color: Color) -> void:
	var t := Floaty.new()
	t.pos = p
	t.text = text
	t.color = color
	floats.append(t)

func boom(p: Vector2, n: int, side: int) -> void:
	for i in n:
		var pt := Part.new()
		var a := rng.randf() * TAU
		var s := 20.0 + rng.randf() * 90.0
		pt.pos = p
		pt.vel = Vector2(cos(a), sin(a)) * s
		pt.life = 0.4 + rng.randf() * 0.6
		pt.maxl = 1.0
		pt.size = 1.0 + rng.randf() * 2.2
		pt.col = Color("ffd28a") if rng.randf() < 0.5 else (Color("ff8a5c") if side == 1 else Color("9ff0ff"))
		parts.append(pt)
	var ring := Part.new()
	ring.pos = p
	ring.life = 0.35
	ring.maxl = 0.35
	ring.size = 9.0
	ring.col = Color("fff2d0")
	ring.ring = true
	parts.append(ring)

# 투영 사건에서 오는 폭발. ship_lost: 맞은 전대의 한 척, destroyed: 전대의 모든 슬롯.
func on_ship_lost(f: BattleViewModel.FleetView, n: int) -> void:
	for i in n:
		boom(rand_ship(f), 10, f.side)

func on_destroyed(f: BattleViewModel.FleetView) -> void:
	for i in BattleView3D.visible_ships(f.max_ships, f.max_ships):
		boom(ship_pos(f, i), 8, f.side)

func on_missile_hit(p: Vector2, target_side: int) -> void:
	boom(p, 8, target_side)

# 프레임마다 호출. dt는 게임 속도를 반영한 시간이다.
func update(dt: float) -> void:
	for s in vm.swarms:
		if s.striking and rng.randf() < dt * 6.0:
			var t := vm.fleet(s.target_id)
			if t and not t.dead:
				boom(rand_ship(t), 3, t.side)
	for p in parts:
		p.life -= dt
		p.pos += p.vel * dt
		p.vel *= 0.96
	for i in range(parts.size() - 1, -1, -1):
		if parts[i].life <= 0.0:
			parts.remove_at(i)
	for t in floats:
		t.t -= dt
		t.pos.y -= 18.0 * dt
	for i in range(floats.size() - 1, -1, -1):
		if floats[i].t <= 0.0:
			floats.remove_at(i)

func _draw() -> void:
	if not active:
		return
	# 사격선
	for f in vm.fleets:
		if f.dead or f.fire_t == null or f.fire_t.dead:
			continue
		var k := mini(4, 1 + int(f.ships / 40.0))
		for i in k:
			if rng.randf() < 0.35:
				continue
			var a := rig.w2s(rand_ship(f))
			var b := rig.w2s(rand_ship(f.fire_t)) + Vector2(rng.randf() - 0.5, rng.randf() - 0.5) * 10.0
			var col := Color(1.0, (120.0 + rng.randf() * 60.0) / 255.0, 80.0 / 255.0, 0.35 + rng.randf() * 0.45) if f.side == 1 else Color((120.0 + rng.randf() * 60.0) / 255.0, 240.0 / 255.0, 1.0, 0.35 + rng.randf() * 0.45)
			draw_line(a, b, col, 1.4)
			if rng.randf() < 0.3:
				draw_rect(Rect2(b - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.94, 0.78, 0.8))
	# 함재기
	for s in vm.swarms:
		var col := Color(1.0, 0.75, 0.55, 0.95) if s.side == 1 else Color(0.75, 0.94, 1.0, 0.95)
		for p in s.pts:
			var sp := rig.w2s(p.pos)
			draw_rect(Rect2(sp - Vector2(1.5, 1.5), Vector2(3, 3)), col)
		var t := vm.fleet(s.target_id)
		if t and not t.dead and rng.randf() < 0.5 and s.pts.size() > 0:
			var p2: Dictionary = s.pts[rng.randi() % s.pts.size()]
			draw_line(rig.w2s(p2.pos), rig.w2s(rand_ship(t)), Color(col, 0.5), 1.0)
	# 미사일
	for m in vm.missiles:
		var col := Color(1.0, 0.67, 0.43, 0.6) if m.side == 1 else Color(0.67, 0.82, 1.0, 0.6)
		var pts := PackedVector2Array()
		for p in m.trail:
			pts.append(rig.w2s(p))
		if pts.size() > 1:
			draw_polyline(pts, col, 1.8)
		var hp := rig.w2s(m.pos)
		draw_rect(Rect2(hp - Vector2(2, 2), Vector2(4, 4)), Color.WHITE)
	# 파편/폭발
	for p in parts:
		var a := p.life / p.maxl
		var sp := rig.w2s(p.pos)
		if p.ring:
			draw_arc(sp, p.size * (1.8 - a) * rig.cam_z * 1.4, 0.0, TAU, 20, Color(1.0, 0.94, 0.82, a), 2.0)
		else:
			draw_rect(Rect2(sp - Vector2(p.size, p.size) * 0.5, Vector2(p.size, p.size)), Color(p.col, minf(1.0, a * 1.5)))
