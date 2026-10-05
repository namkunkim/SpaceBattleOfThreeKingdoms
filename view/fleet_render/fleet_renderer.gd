class_name FleetRenderer
extends Node3D

# 함대 대량 표시와 전투 연출.
# - 함대 하나 = 함종별 MultiMesh(저폴리 LOD) + 엔진광 MultiMesh. 함선 수는 남은 전력에 비례한다.
# - 전투 상태는 BattleSource로만 읽고 바꾸지 않는다. 연출용 난수는 전투 난수와 분리한다.
# - 사격은 2초 안팎 주기의 일제 포화로 재생한다. 앞줄부터 물결처럼 쏘고 방어막 섬광·피격·격침을 그린다.

# 소리 훅: "volley"(일제 포화), "ship_kill"(함선 격침). 표현 계층이 효과음으로 잇는다.
signal fx_event(kind: String)

const CLASS_NAMES := ["전열함", "화력함", "공성함", "보급_수리함", "전자전함", "호위함", "항모"]
enum { LINE, FIRE, SIEGE, SUPPLY, EW, ESCORT, CARRIER }
const CLASS_LABEL := ["전열", "화력", "공성", "보급", "전자전", "호위", "항모"]
# 함종별 선체 길이(3D 단위). 원본 모델은 길이 약 1.9.
const CLASS_LEN := [1.15, 1.0, 1.2, 0.9, 0.88, 0.6, 1.25]
const MODEL_LEN := 1.9
# 함선은 3D 모델이 아니라 바닥에 눕힌 평면 위의 셰이더 실루엣이다(`ship_sprite.gdshader`, 참고 영상 방식).
# 평면 길이 = MODEL_LEN, 폭 = SHIP_WIDTH(길이:폭 약 4:1). 실제 크기는 CLASS_LEN과 _ship_xform의 배율이 정한다.
const SHIP_WIDTH := 0.48
const PLANE_K := 1.6   # ship_sprite.gdshader의 PLANE_K와 같아야 한다
const HULL_STRETCH := Vector3(0.75, 1.0, 1.0)   # x = 길이 배율(대열에서 앞뒤 함선이 겹치지 않게)
const CLASS_FAT := [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0]   # 함종별 폭 미세 조정(실루엣 자체는 셰이더 kind가 정한다)
const C_ALLY_HULL := Color(0.09, 0.13, 0.19)
const C_FOE_HULL := Color(0.17, 0.11, 0.1)
const C_ALLY_OUTLINE := Color(0.62, 0.9, 1.0)
const C_FOE_OUTLINE := Color(1.0, 0.72, 0.5)
# 표시 함선 = 정원 × 고정 배율(리뷰 C-1). 손실은 같은 배율로 줄어든다. 화면 숫자는 언제나 실제 척 수다.
# 배율은 설정의 "함선 표시"(낮음·보통·높음)로 고른다(리뷰 C-4, 모바일 성능).
const VIS_RATIOS := [0.35, 0.6, 0.85]

static func vis_ratio() -> float:
	return VIS_RATIOS[clampi(GameSettings.ship_density, 0, VIS_RATIOS.size() - 1)]
const GAP_LAT := 13.0
const GAP_FWD := 25.0
const LAYER_H := 0.34
const LOD_NEAR_ZOOM := 1.05
const WORLD_AABB := AABB(Vector3(-120, -6, -120), Vector3(240, 12, 240))   # 함선이 월드 좌표로 움직이므로 컬링 상자를 전장 전체로 둔다
# 대형 추종(뷰 전용 연출). 함선마다 자기 슬롯 목표를 지연 추종한다. 코어 상태·전역 난수와 무관하다(리뷰 REVIEW-FLEET-VISUAL).
const SIM_STEP := 1.0 / 30.0     # 추종 갱신 주기(태블릿 예산: 정지한 전대는 갱신하지 않는다)
const TAU_MIN := 0.25            # 함선별 추종 시간 상수(초). 슬롯마다 TAU_MIN~TAU_MAX
const TAU_MAX := 0.95
const SWAY := 0.22               # 이동 중 개체 흔들림 진폭(3D 단위)
const MOVE_EPS := 0.3            # 이 속도(3D 단위/초) 이상이면 속도 방향을 보고, 아니면 전대 방향을 본다
const REFORM_MIN := 0.6          # 진형 전환 때 함선이 슬롯을 향해 수렴하는 최소 tau 배율

const C_ALLY_BEAM := Color(0.42, 0.9, 1.0, 1.0)
const C_FOE_BEAM := Color(1.0, 0.52, 0.28, 1.0)
const C_ALLY_ENGINE := Color(0.42, 0.82, 1.0)
const C_FOE_ENGINE := Color(1.0, 0.52, 0.24)
const C_ALLY_TINT := Color(0.94, 1.0, 1.05)
const C_FOE_TINT := Color(1.07, 0.9, 0.84)
const C_FLASH := Color(2.4, 2.4, 2.6)

class Slot:
	var cls := 0
	var idx := 0
	var pos := Vector3.ZERO      # 현재 월드 위치(대형 추종 결과)
	var home := Vector3.ZERO     # 진형 슬롯(전대 로컬: 전방 -Z, 측면 +X)
	var vel := Vector3.ZERO
	var yaw := 0.0               # 월드 yaw(모델 기준)
	var tau := 0.5
	var phase := 0.0
	var trail := 0.0             # 항적 세기 0~1(속도에 따라)
	var trail_sent := 0.0        # 마지막으로 MultiMesh에 쓴 항적 값(변화가 작으면 다시 쓰지 않는다)
	var scl := Vector3.ONE       # 선체 배율(함종·기함)
	var gsz := 0.4               # 엔진광 크기
	var cph := 1.0               # 흔들림 위상의 cos/sin(갱신마다 삼각함수를 부르지 않으려고 미리 계산)
	var sph := 0.0
	var cph2 := 1.0
	var sph2 := 0.0
	var half_len := 0.4
	var rank := 0.0
	var alive := true
	var flag := false
	var flash_until := 0.0
	var hit_t := -10.0

class FleetVis:
	var id := 0
	var side := 0
	var node: Node3D
	var mmis: Array = []
	var glow: MultiMeshInstance3D
	var slots: Array = []
	var alive_n := 0
	var volley_t := 0.0
	var dying := false
	var die_acc := 0.0
	var lod := -1
	var formation := -1
	var rest := 0                # 연속으로 목표에 닿아 있던 갱신 횟수(3 이상이면 갱신 생략)
	var last_pos := Vector3(1e9, 0, 0)
	var last_rot := 1e9
	var acc := 0.0

var src: BattleSource
var meshes := [[], []]
var mats := [[], []]
var wreck_mat: StandardMaterial3D
var vis := {}
var shots: Array = []
var wrecks: Array = []
var fx_add: FxPool
var fx_mix: FxPool
var beams: BeamPool
var dust: MultiMeshInstance3D
var rng := RandomNumberGenerator.new()
var clock := 0.0
var _detail := -1.0   # 확대 정도에 따른 함선 세부 표현(0~1)
var _missile_last := {}

func setup(source: BattleSource) -> void:
	src = source
	rng.seed = 20261003
	_load_assets()
	fx_mix = FxPool.new(900, false)
	add_child(fx_mix)
	beams = BeamPool.new(900)
	add_child(beams)
	fx_add = FxPool.new(2600, true)
	add_child(fx_add)
	_build_dust()
	_build_far_backdrop()

func _load_assets() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(MODEL_LEN * PLANE_K, SHIP_WIDTH)   # 뒤쪽 (PLANE_K-1)/PLANE_K 구간은 항적 자리
	plane.center_offset = Vector3(MODEL_LEN * (PLANE_K - 1.0) * 0.5, 0.0, 0.0)   # 선체 중심이 원점에 오게
	for lod in 2:
		meshes[lod] = []
		for n in CLASS_NAMES:
			meshes[lod].append(plane)
	var sh := load("res://view/fleet_render/ship_sprite.gdshader") as Shader
	for side in 2:
		var arr := []
		for c in CLASS_NAMES.size():
			var m := ShaderMaterial.new()
			m.shader = sh
			m.set_shader_parameter("hull_color", C_ALLY_HULL if side == 0 else C_FOE_HULL)
			m.set_shader_parameter("rim_color", C_ALLY_OUTLINE if side == 0 else C_FOE_OUTLINE)
			m.set_shader_parameter("fat", CLASS_FAT[c])
			m.set_shader_parameter("kind", c)   # 함종 번호 = 실루엣 종류
			var tex_path := "res://assets/ships/silhouette/%d.png" % c
			if ResourceLoader.exists(tex_path):
				m.set_shader_parameter("ship_tex", load(tex_path))
				m.set_shader_parameter("use_tex", true)
			arr.append(m)
		mats[side] = arr
	wreck_mat = StandardMaterial3D.new()
	wreck_mat.albedo_color = Color(0.09, 0.08, 0.08)
	wreck_mat.emission_enabled = true
	wreck_mat.emission = Color(1.0, 0.35, 0.1)
	wreck_mat.emission_energy_multiplier = 0.2
	wreck_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _build_far_backdrop() -> void:
	# 넓은 화면·원거리 확대에서 전장 배경판 바깥이 보이지 않도록 아래에 더 큰 원경판을 깐다.
	var ws := src.world_size() * src.unit_scale()
	var far := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = ws * 3.2
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_texture = load("res://assets/backgrounds/red_cliffs_starfield_v1.png")
	m.albedo_color = Color(0.32, 0.38, 0.46)
	m.uv1_scale = Vector3(2.0, 2.0, 1.0)
	m.texture_repeat = true
	plane.material = m
	far.mesh = plane
	far.position = src.to3(src.world_size() * 0.5, -6.0)
	far.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(far)

func _build_dust() -> void:
	# 함대 평면 위아래에 흩어진 먼지와 원거리 별. 화면을 옮길 때 시차로 깊이가 보인다.
	var ws := src.world_size()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mm.mesh = quad
	var n := 1400
	mm.instance_count = n
	for i in n:
		var p := Vector2(rng.randf() * ws.x, rng.randf() * ws.y)
		var y := rng.randf_range(-0.8, 7.0) if i % 3 else rng.randf_range(-0.9, -0.2)
		var s := rng.randf_range(0.04, 0.12) * (1.6 if rng.randf() < 0.04 else 1.0)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * s), src.to3(p, y)))
		var warm := rng.randf() < 0.18
		mm.set_instance_color(i, Color(1.0, 0.85, 0.6) if warm else Color(0.7, 0.85, 1.0))
		mm.set_instance_custom_data(i, Color(0.0, 0.0, rng.randf(), rng.randf_range(0.15, 0.55)))
	dust = MultiMeshInstance3D.new()
	dust.multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://view/fleet_render/fx_sprite_add.gdshader")
	dust.material_override = mat
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(dust)

# ------------------------------------------------------------ formation
# 진형 이름 순서는 POC FORM_NAMES와 같다.
func formation_points(kind: int, n: int) -> Array:
	var per := ceili(n / 2.0)
	var base := _pattern(kind, per)
	var pts := []
	for i in n:
		var layer := i % 2
		var p: Vector2 = base[mini(i / 2, base.size() - 1)]
		var off := Vector2(GAP_FWD * 0.5, GAP_LAT * 0.5) if layer == 1 else Vector2.ZERO
		pts.append(Vector3(p.x + off.x, (LAYER_H if layer == 1 else -LAYER_H * 0.5), p.y + off.y))
	var c := Vector3.ZERO
	for p in pts:
		c += p
	c /= maxf(1.0, pts.size())
	for i in pts.size():
		pts[i] = Vector3(pts[i].x - c.x, pts[i].y, pts[i].z - c.z)
	return pts

func _pattern(kind: int, m: int) -> Array:
	var out := []
	match kind:
		4: # 원진
			var ring := 0
			while out.size() < m:
				var cnt := 1 if ring == 0 else ring * 7
				for k in cnt:
					if out.size() >= m:
						break
					var a := TAU * k / cnt + ring * 0.3
					out.append(Vector2(cos(a), sin(a)) * ring * GAP_LAT * 1.25)
				ring += 1
			return out
		3, 9: # 종진, 장사진
			var cols := 3 if kind == 3 else 2
			for k in m:
				var r := k / cols
				var cc := k % cols - (cols - 1) * 0.5
				var wob := sin(r * 0.5) * GAP_LAT * 0.6 if kind == 9 else 0.0
				out.append(Vector2(-r * GAP_FWD * 0.85, cc * GAP_LAT * 1.2 + wob))
			return out
	var cols := ceili(sqrt(m * (1.4 if kind == 2 else 3.0)))
	for k in m:
		var r := k / cols
		var c := k % cols
		var cc := c - (cols - 1) * 0.5
		var f := -r * GAP_FWD
		var l := cc * GAP_LAT
		match kind:
			1: f -= absf(cc) * GAP_FWD * 0.5   # 쐐기진
			5: f += absf(cc) * GAP_FWD * 0.42  # 학익진
			6: f += cc * GAP_FWD * 0.3         # 사선진
			7: l += (GAP_LAT * 0.5 if r % 2 == 1 else 0.0)  # 어린진
			8: f += absf(cc) * GAP_FWD * 0.5 - (cols * 0.5) * GAP_FWD * 0.2  # 안행진
		out.append(Vector2(f, l))
	return out

func _assign_class(pts: Array, flag: bool, seed_v: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed_v
	var minf_ := 1e9
	var maxf_ := -1e9
	var maxl := 1.0
	for p in pts:
		minf_ = minf(minf_, p.x)
		maxf_ = maxf(maxf_, p.x)
		maxl = maxf(maxl, absf(p.z))
	var span := maxf(1.0, maxf_ - minf_)
	var out := []
	var carriers := 0
	for p in pts:
		var rank: float = (maxf_ - p.x) / span
		var edge: float = absf(p.z) / maxl
		var c := FIRE
		if rank < 0.2:
			c = LINE
		elif edge > 0.86:
			c = ESCORT
		elif rank > 0.78 and edge < 0.4 and carriers < pts.size() / 9:
			c = CARRIER
			carriers += 1
		elif rank > 0.6:
			c = [SUPPLY, EW, SIEGE, FIRE][r.randi() % 4]
		elif r.randf() < 0.35:
			c = LINE
		out.append({"cls": c, "rank": rank})
	if flag:
		var best := 0
		var bd := 1e9
		for i in pts.size():
			var d: float = Vector2(pts[i].x, pts[i].z).length()
			if d < bd:
				bd = d
				best = i
		out[best].cls = LINE
		out[best]["flag"] = true
	return out

# ------------------------------------------------------------ 대형 추종 (뷰 전용)
# 함선마다 슬롯 목표를 tau(0.25~0.95초) 지연으로 따라간다. 선회하면 바깥쪽 슬롯의 목표가 더 빨리 움직여 안쪽보다 뒤처졌다 부채꼴로 펼쳐지고,
# 진형이 바뀌면 슬롯이 재배정되어 함선이 새 자리로 흘러간다. 코어 상태·전투 난수에 닿지 않고 추종 갱신에는 난수가 없다(tau·위상은 전대 id 시드).
func _follow(v: FleetVis, sq: Dictionary, dt: float) -> void:
	if dt <= 0.0:
		return
	v.acc += dt
	if v.acc < SIM_STEP:
		return
	var step := minf(v.acc, 0.25)
	v.acc = 0.0
	var fpos := src.to3(sq.pos)
	var frot := -float(sq.heading) - PI * 0.5
	var moved := fpos.distance_squared_to(v.last_pos) > 1e-8 or absf(frot - v.last_rot) > 1e-5
	v.last_pos = fpos
	v.last_rot = frot
	if not moved and v.rest >= 3:
		return
	var fb := Basis(Vector3.UP, frot)
	var h_fleet := -float(sq.heading) - PI   # 전대 방향의 모델 yaw
	var ca := cos(clock * 0.9)
	var sa := sin(clock * 0.9)
	var cb := cos(clock * 0.7)
	var sb := sin(clock * 0.7)
	var sw := SWAY if moved else 0.0
	var maxerr := 0.0
	var maxtr := 0.0
	var yk := 1.0 - exp(-step / 0.35)
	var eps2 := MOVE_EPS * MOVE_EPS
	var inv := 1.0 / step
	var gl := v.glow.multimesh
	var gi := -1
	for s: Slot in v.slots:
		gi += 1
		if not s.alive:
			continue
		var t := fpos + fb * s.home
		if sw > 0.0:
			t.x += sw * (sa * s.cph + ca * s.sph)
			t.z += sw * (cb * s.cph2 - sb * s.sph2)
		var d := (t - s.pos) * (step / (s.tau + step))   # 지수 추종의 유리 근사(안정, 오버슈트 없음)
		s.pos += d
		s.vel = d * inv
		var e2 := (t - s.pos).length_squared()
		maxerr = maxf(maxerr, e2)
		var sp2 := s.vel.length_squared()
		var want := h_fleet
		if sp2 > eps2:
			want = -atan2(s.vel.z, s.vel.x) - PI
		s.yaw = lerp_angle(s.yaw, want, yk)
		var c := cos(s.yaw)
		var sn := sin(s.yaw)
		var mm: MultiMesh = v.mmis[s.cls].multimesh
		mm.set_instance_transform(s.idx, _xform_cs(s, c, sn))
		s.trail += (smoothstep(MOVE_EPS, 2.5, sqrt(sp2)) - s.trail) * 0.3
		maxtr = maxf(maxtr, s.trail)
		if absf(s.trail - s.trail_sent) > 0.02:
			s.trail_sent = s.trail
			mm.set_instance_custom_data(s.idx, Color(s.trail, 0.0, 0.0, 0.0))
		# 엔진광은 선미(전방의 반대)에: 전방 = (-cos yaw, 0, sin yaw)
		gl.set_instance_transform(gi, Transform3D(Basis.from_scale(Vector3.ONE * s.gsz), s.pos + Vector3(c, 0.0, -sn) * (s.half_len * 0.98)))
	v.rest = v.rest + 1 if (maxerr < 0.0004 and maxtr < 0.02) else 0

# 진형이 바뀌면 새 슬롯을 앞쪽 순서대로 기존 함선에 다시 배정한다(함종 구성은 그대로).
func _reform(v: FleetVis, sq: Dictionary) -> void:
	v.formation = sq.formation
	v.rest = 0
	var alive: Array = v.slots.filter(func(x): return x.alive)
	var n := alive.size()
	if n == 0:
		return
	var pts := formation_points(sq.formation, n)
	var S := src.unit_scale()
	var order_new := range(n)
	order_new.sort_custom(func(a, b): return pts[a].x > pts[b].x)
	var order_old := range(n)
	order_old.sort_custom(func(a, b): return alive[a].rank < alive[b].rank)
	var minf_ := 1e9
	var maxf_ := -1e9
	for p in pts:
		minf_ = minf(minf_, p.x)
		maxf_ = maxf(maxf_, p.x)
	var span := maxf(1.0, maxf_ - minf_)
	for i in n:
		var s: Slot = alive[order_old[i]]
		var p: Vector3 = pts[order_new[i]]
		s.home = Vector3(p.z * S, p.y, -p.x * S)
		s.rank = (maxf_ - p.x) / span

# ------------------------------------------------------------ fleets
func _make_vis(sq: Dictionary) -> FleetVis:
	var v := FleetVis.new()
	v.id = sq.id
	v.side = sq.side
	v.node = Node3D.new()
	v.node.name = "FleetVis-%d" % sq.id
	add_child(v.node)
	_build_slots(v, sq)
	return v

func _build_slots(v: FleetVis, sq: Dictionary) -> void:
	for m in v.mmis:
		if m:
			m.queue_free()
	if v.glow:
		v.glow.queue_free()
	v.mmis = []
	v.slots = []
	v.formation = sq.formation
	var n := maxi(12, roundi(sq.max_ships * vis_ratio()))
	var pts := formation_points(sq.formation, n)
	var cls := _assign_class(pts, sq.flagship, sq.id * 7919)
	var S := src.unit_scale()
	var per_class := []
	per_class.resize(CLASS_NAMES.size())
	for i in per_class.size():
		per_class[i] = []
	var jr := RandomNumberGenerator.new()
	jr.seed = sq.id * 104729
	for i in pts.size():
		var s := Slot.new()
		s.cls = cls[i].cls
		s.rank = cls[i].rank
		s.flag = cls[i].get("flag", false)
		var p: Vector3 = pts[i]
		# 함대 로컬 공간: 전방 = -Z, 측면 = +X (POC _build_fleet_3d와 같은 축)
		s.home = Vector3(p.z * S, p.y + jr.randf_range(-0.06, 0.06), -p.x * S)
		s.tau = lerpf(TAU_MIN, TAU_MAX, jr.randf())
		s.phase = jr.randf() * TAU
		s.cph = cos(s.phase)
		s.sph = sin(s.phase)
		s.cph2 = cos(s.phase * 1.3)
		s.sph2 = sin(s.phase * 1.3)
		var L: float = CLASS_LEN[s.cls] * HULL_STRETCH.x * (1.8 if s.flag else 1.0)
		s.half_len = L * 0.5
		s.scl = HULL_STRETCH * ((CLASS_LEN[s.cls] / MODEL_LEN) * (1.8 if s.flag else 1.0))
		s.gsz = s.half_len * (0.6 if s.cls != ESCORT else 0.5)
		s.idx = per_class[s.cls].size()
		per_class[s.cls].append(s)
		v.slots.append(s)
	var fpos := src.to3(sq.pos)
	var frot := -float(sq.heading) - PI * 0.5
	for s in v.slots:
		s.pos = _target(s, fpos, frot, 0.0)
		s.yaw = -float(sq.heading) - PI
	v.last_pos = fpos
	v.last_rot = frot
	for c in CLASS_NAMES.size():
		var list: Array = per_class[c]
		if list.is_empty():
			v.mmis.append(null)
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = meshes[1][c]
		mm.instance_count = list.size()
		var tint := C_ALLY_TINT if v.side == 0 else C_FOE_TINT
		for s in list:
			mm.set_instance_transform(s.idx, _ship_xform(s))
			mm.set_instance_color(s.idx, tint)
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.custom_aabb = WORLD_AABB
		mi.material_override = mats[v.side][c]
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		v.node.add_child(mi)
		v.mmis.append(mi)
	# 엔진광
	var gm := MultiMesh.new()
	gm.transform_format = MultiMesh.TRANSFORM_3D
	gm.use_colors = true
	gm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	gm.mesh = quad
	gm.instance_count = v.slots.size()
	var ec := C_ALLY_ENGINE if v.side == 0 else C_FOE_ENGINE
	for i in v.slots.size():
		var s: Slot = v.slots[i]
		var sz := s.half_len * (0.6 if s.cls != ESCORT else 0.5)
		gm.set_instance_transform(i, _glow_xform(s, sz))
		gm.set_instance_color(i, ec)
		gm.set_instance_custom_data(i, Color(0.0, 0.0, jr.randf(), 0.75 if s.cls != ESCORT else 0.55))
	v.glow = MultiMeshInstance3D.new()
	v.glow.multimesh = gm
	var gmat := ShaderMaterial.new()
	gmat.shader = load("res://view/fleet_render/fx_sprite_add.gdshader")
	v.glow.material_override = gmat
	v.glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	v.glow.custom_aabb = WORLD_AABB
	v.node.add_child(v.glow)
	v.alive_n = v.slots.size()
	v.lod = 1

func _ship_xform(s: Slot) -> Transform3D:
	return _xform_cs(s, cos(s.yaw), sin(s.yaw))

# 회전 행렬 Basis(UP, yaw)와 배율을 직접 조립한다(갱신 루프의 비용을 줄이려고).
func _xform_cs(s: Slot, c: float, sn: float) -> Transform3D:
	return Transform3D(Basis(Vector3(c * s.scl.x, 0.0, -sn * s.scl.x), Vector3(0.0, s.scl.y, 0.0), Vector3(sn * s.scl.z, 0.0, c * s.scl.z)), s.pos)

# 선체 전방(월드). 모델 yaw a = -h - PI 이므로 전방각 h = -a - PI, 전방 = (cos h, 0, sin h).
func _fwd(s: Slot) -> Vector3:
	var h := -s.yaw - PI
	return Vector3(cos(h), 0.0, sin(h))

func _glow_xform(s: Slot, sz: float) -> Transform3D:
	return Transform3D(Basis.from_scale(Vector3.ONE * sz), s.pos - _fwd(s) * (s.half_len * 0.98))

# 슬롯 목표(월드): 전대 위치 + 전대 회전 x 슬롯 (+ 이동 중 개체 흔들림)
func _target(s: Slot, fpos: Vector3, frot: float, sway: float) -> Vector3:
	var t := fpos + Basis(Vector3.UP, frot) * s.home
	if sway > 0.0:
		t += Vector3(sin(clock * 0.9 + s.phase), 0.0, cos(clock * 0.7 + s.phase * 1.3)) * (SWAY * sway)
	return t

func _hide_slot(v: FleetVis, s: Slot) -> void:
	s.alive = false
	v.alive_n -= 1
	var mi: MultiMeshInstance3D = v.mmis[s.cls]
	if mi:
		mi.multimesh.set_instance_transform(s.idx, Transform3D(Basis.from_scale(Vector3.ZERO), s.pos))
	var gi := v.slots.find(s)
	v.glow.multimesh.set_instance_custom_data(gi, Color(0, 0, 0, 0))

func slot_world(_v: FleetVis, s: Slot) -> Vector3:
	return s.pos

func bow_world(_v: FleetVis, s: Slot) -> Vector3:
	return s.pos + _fwd(s) * s.half_len

# 지금 화면에 살아 있는 표시 함선 수(성능 측정용, 규칙 값 아님)
func visible_ship_count() -> int:
	var n := 0
	for k in vis:
		n += (vis[k] as FleetVis).alive_n
	return n

func composition(id: int) -> Array:
	# 함종별 남은 표시 척수 [[라벨, 수], ...]
	var v: FleetVis = vis.get(id)
	var cnt := []
	cnt.resize(CLASS_NAMES.size())
	cnt.fill(0)
	if v:
		for s in v.slots:
			if s.alive:
				cnt[s.cls] += 1
	var out := []
	for c in [LINE, FIRE, CARRIER, ESCORT, EW, SUPPLY, SIEGE]:
		if cnt[c] > 0:
			out.append([CLASS_LABEL[c], cnt[c], c])
	return out

# ------------------------------------------------------------ frame
func update(dt: float) -> void:
	# 강조 포화의 화면 흔들림(카메라 오프셋만 건드린다. 실제 시간으로 줄인다)
	var cam := src.camera()
	if cam:
		shake = maxf(0.0, shake - get_process_delta_time() / maxf(0.001, Engine.time_scale) * 0.9)
		cam.h_offset = rng.randf_range(-1.0, 1.0) * shake
		cam.v_offset = rng.randf_range(-1.0, 1.0) * shake
	clock += dt
	var sqs := src.squadrons()
	var seen := {}
	var by_id := {}
	for sq in sqs:
		seen[sq.id] = true
		by_id[sq.id] = sq
		if not vis.has(sq.id):
			vis[sq.id] = _make_vis(sq)
	for id in vis.keys():
		if not seen.has(id):
			_free_vis(vis[id])
			vis.erase(id)
	var near := src.zoom() >= LOD_NEAR_ZOOM
	var detail := smoothstep(1.0, 1.9, src.zoom())
	if absf(detail - _detail) > 0.01:
		_detail = detail
		for side in mats:
			for m in side:
				(m as ShaderMaterial).set_shader_parameter("detail", detail)
	for sq in sqs:
		var v: FleetVis = vis[sq.id]
		if sq.formation != v.formation:
			_reform(v, sq)
		if not sq.dead:
			_follow(v, sq, dt)
		var want := 0 if near else 1
		if v.lod != want:
			v.lod = want
			for c in v.mmis.size():
				if v.mmis[c]:
					v.mmis[c].multimesh.mesh = meshes[want][c]
		if sq.dead:
			_dying(v, dt)
		else:
			var target := clampi(ceili(v.slots.size() * sq.ships / maxf(1.0, sq.max_ships)), 1, v.slots.size())
			var guard := 0
			while v.alive_n > target and guard < 8:
				_kill_one(v)
				guard += 1
			if dt > 0.0 and sq.firing_at >= 0 and vis.has(sq.firing_at):
				v.volley_t -= dt
				if v.volley_t <= 0.0:
					v.volley_t = rng.randf_range(1.5, 2.3)
					_volley(v, vis[sq.firing_at])
		_update_flash(v)
	if dt > 0.0:
		_update_shots(dt)
		_update_missiles()
		_update_swarms()
		_update_wrecks(dt)
		fx_add.step(dt)
		fx_mix.step(dt)
	else:
		_draw_shots_static()

func _free_vis(v: FleetVis) -> void:
	v.node.queue_free()
	shots = shots.filter(func(s): return s.av != v and s.bv != v)

func reset() -> void:
	for id in vis.keys():
		vis[id].node.queue_free()
	vis.clear()
	shots.clear()
	for w in wrecks:
		w.node.queue_free()
	wrecks.clear()
	fx_add.clear()
	fx_mix.clear()
	beams.begin()
	beams.commit()
	_missile_last.clear()

func _update_flash(v: FleetVis) -> void:
	var tint := C_ALLY_TINT if v.side == 0 else C_FOE_TINT
	for s in v.slots:
		if s.flash_until > 0.0 and clock >= s.flash_until:
			s.flash_until = 0.0
			if s.alive and v.mmis[s.cls]:
				v.mmis[s.cls].multimesh.set_instance_color(s.idx, tint)

func _flash(v: FleetVis, s: Slot) -> void:
	if not s.alive or v.mmis[s.cls] == null:
		return
	s.flash_until = clock + 0.08
	v.mmis[s.cls].multimesh.set_instance_color(s.idx, C_FLASH)

func _pick_victim(v: FleetVis) -> Slot:
	var best: Slot = null
	var bt := clock - 0.8
	for s in v.slots:
		if s.alive and not s.flag and s.hit_t > bt:
			bt = s.hit_t
			best = s
	if best:
		return best
	# 최근 피격이 없으면 전열(rank 작은 쪽)에서 우선 고른다. 앞줄이 먼저 깎이고 뒤 함선이 메운다.
	var alive := v.slots.filter(func(s): return s.alive and not s.flag and s.rank < 0.45)
	if alive.is_empty():
		alive = v.slots.filter(func(s): return s.alive and not s.flag)
	if alive.is_empty():
		alive = v.slots.filter(func(s): return s.alive)
	if alive.is_empty():
		return null
	return alive[rng.randi() % alive.size()]

func _kill_one(v: FleetVis) -> void:
	fx_event.emit("ship_kill")
	var s := _pick_victim(v)
	if s == null:
		return
	var w := slot_world(v, s)
	_hide_slot(v, s)
	_close_ranks(v, s.home)
	explode(w, s.half_len * 2.0, v.side)
	_spawn_wreck(v, s, w)

# 빈자리 메우기: 구멍 바로 뒤의 가장 가까운 함선이 그 자리로 올라오고, 그 함선의 옛 자리가 새 구멍이 된다. 최대 5번 이어 꼬리까지 당긴다.
# 기함은 제자리를 지킨다. 함선은 _follow의 추종으로 천천히 올라온다(뷰 전용, 난수 없음).
func _close_ranks(v: FleetVis, gap: Vector3) -> void:
	var hole := gap
	var reach := src.unit_scale() * GAP_FWD * 2.2
	for hop in 5:
		var best: Slot = null
		var bd := 1e9
		for s in v.slots:
			if not s.alive or s.flag or s.home.z <= hole.z + 0.05:
				continue
			var d := Vector2(s.home.x - hole.x, (s.home.z - hole.z) * 0.5).length()
			if d < bd:
				bd = d
				best = s
		if best == null or bd > reach:
			break
		var h := best.home
		best.home = hole
		hole = h
	v.rest = 0

func _dying(v: FleetVis, dt: float) -> void:
	if not v.dying:
		v.dying = true
		v.die_acc = 0.0
	if v.alive_n <= 0:
		v.node.visible = false
		return
	# 함대 궤멸: 1.6초에 걸쳐 남은 함선이 연쇄로 폭발한다.
	v.die_acc += dt * maxf(6.0, v.slots.size() / 1.6)
	while v.die_acc >= 1.0 and v.alive_n > 0:
		v.die_acc -= 1.0
		var alive := v.slots.filter(func(s): return s.alive)
		var s: Slot = alive[rng.randi() % alive.size()]
		var w := slot_world(v, s)
		_hide_slot(v, s)
		explode(w, s.half_len * (3.2 if s.flag else 2.0), v.side)
		if rng.randf() < 0.5:
			_spawn_wreck(v, s, w)

func explode(w: Vector3, size: float, side: int) -> void:
	fx_add.spawn(FxPool.FLARE, w, size * 2.6, 0.22, Color(1.0, 0.95, 0.85), 1.4)
	fx_add.spawn(FxPool.FIRE, w, size * 1.6, rng.randf_range(0.9, 1.3), Color.WHITE, 1.2, Vector3.ZERO, 0.9)
	fx_add.spawn(FxPool.RING, w + Vector3(0, 0.05, 0), size * 3.6, 0.7, Color(1.0, 0.86, 0.66), 0.9)
	for i in 9:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.4, 0.8), rng.randf_range(-1, 1)).normalized()
		fx_add.spawn(FxPool.EMBER, w, rng.randf_range(0.08, 0.16), rng.randf_range(0.6, 1.5), Color(1.0, 0.7, 0.35), 1.0, d * rng.randf_range(1.5, 4.5), 0.0, 1.4)
	fx_mix.spawn(FxPool.SMOKE, w, size * 1.4, 2.4, Color(0.22, 0.2, 0.2), 0.55, Vector3(0, 0.2, 0), 1.6)

func _spawn_wreck(v: FleetVis, s: Slot, w: Vector3) -> void:
	if wrecks.size() >= 48:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = meshes[1][s.cls]
	var mat := wreck_mat.duplicate() as StandardMaterial3D
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	mi.global_transform = _ship_xform(s)
	mi.scale *= 0.4   # 잔해는 작은 파편으로(평면 실루엣 그대로면 큰 판자로 보인다)
	var drift := Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(-0.5, -0.1), rng.randf_range(-0.6, 0.6))
	var spin := Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.6, 1.8)
	wrecks.append({"node": mi, "mat": mat, "vel": drift, "spin": spin, "age": 0.0, "life": rng.randf_range(2.2, 3.2), "ember": 0.0})

func _update_wrecks(dt: float) -> void:
	var keep := []
	for w in wrecks:
		w.age += dt
		var mi: MeshInstance3D = w.node
		if w.age >= w.life:
			mi.queue_free()
			continue
		mi.global_position += w.vel * dt
		mi.rotate(w.spin.normalized(), w.spin.length() * dt)
		var k: float = w.age / w.life
		var mat: StandardMaterial3D = w.mat
		mat.albedo_color.a = 1.0 - k * k
		mat.emission_energy_multiplier = 0.4 * (1.0 - k)
		w.ember -= dt
		if w.ember <= 0.0 and k < 0.7:
			w.ember = 0.12
			fx_add.spawn(FxPool.EMBER, mi.global_position, 0.18, 0.5, Color(1.0, 0.55, 0.2), 0.8, Vector3(0, 0.3, 0))
		keep.append(w)
	wrecks = keep

# ------------------------------------------------------------ volleys
# 강조 포화(리뷰 C-2): 코어의 일제사격 사건(Q46, 무기 범주마다 60초에 한 번)이 오면 부른다.
# 상시 포화(분위기 연출)보다 굵고 밝은 광선을 두 배로 쏘고, 화면을 짧게 흔들고, "salvo" 소리 훅을 낸다.
# 지금 POC에는 이 사건이 없어 게임에서는 부르지 않는다(캡처·테스트만).
var shake := 0.0

func emphasis_volley(squadron_id: int) -> bool:
	if not vis.has(squadron_id):
		return false
	var a: FleetVis = vis[squadron_id]
	var sq := src.squadron(squadron_id)
	var tid: int = sq.get("firing_at", -1)
	if tid < 0:
		tid = sq.get("target_id", -1)
	if tid < 0 or not vis.has(tid):
		return false
	fx_event.emit("salvo")
	_volley(a, vis[tid], 2.2)
	shake = maxf(shake, 0.35)
	return true

func _volley(a: FleetVis, b: FleetVis, boost := 1.0) -> void:
	if boost <= 1.0:
		fx_event.emit("volley")
	var front := a.slots.filter(func(s): return s.alive and s.rank < 0.4 and s.cls != CARRIER)
	if front.size() < 6:
		front = a.slots.filter(func(s): return s.alive)
	var tgt := b.slots.filter(func(s): return s.alive)
	if front.is_empty() or tgt.is_empty():
		return
	var n := roundi(clampi(a.alive_n / 4, 6, 26) * boost)
	var col := (C_ALLY_BEAM if a.side == 0 else C_FOE_BEAM) * (1.0 + (boost - 1.0) * 0.8)
	for i in n:
		var s: Slot = front[rng.randi() % front.size()]
		shots.append({"av": a, "slot": s, "bv": b, "tslot": tgt[rng.randi() % tgt.size()],
			"t": -(s.rank * 0.5 + rng.randf() * 0.14), "speed": 75.0, "len": 9.0 * boost, "hit": false, "muzzle": false,
			"jit": Vector3(rng.randf_range(-0.15, 0.15), rng.randf_range(-0.1, 0.1), rng.randf_range(-0.15, 0.15)), "col": col})

func _update_shots(dt: float) -> void:
	beams.begin()
	var keep := []
	for sh in shots:
		sh.t += dt
		var a: FleetVis = sh.av
		var s: Slot = sh.slot
		if not s.alive or a.dying:
			continue
		if sh.t < 0.0:
			keep.append(sh)
			continue
		var b: FleetVis = sh.bv
		var ts: Slot = sh.tslot
		if not ts.alive:
			var alt := b.slots.filter(func(x): return x.alive)
			if alt.is_empty():
				continue
			ts = alt[rng.randi() % alt.size()]
			sh.tslot = ts
		var A := bow_world(a, s)
		var B: Vector3 = slot_world(b, ts) + sh.jit
		if not sh.muzzle:
			sh.muzzle = true
			fx_add.spawn(FxPool.FLARE, A, 0.7, 0.12, sh.col, 1.0)
		var dist := maxf(0.01, A.distance_to(B))
		var travel: float = sh.t * sh.speed
		var head := minf(1.0, travel / dist)
		var tail := clampf((travel - sh.len) / dist, 0.0, 1.0)
		if head >= 1.0 and not sh.hit:
			sh.hit = true
			_impact(a, b, ts, A, B)
		if tail >= 1.0:
			continue
		sh["head"] = head
		sh["tail"] = tail
		beams.add(A, B, head, tail, 0.045, sh.col)
		keep.append(sh)
	shots = keep
	beams.commit()

func _draw_shots_static() -> void:
	# 일시정지 중에도 광선이 사라지지 않게 마지막 상태로 다시 그린다.
	beams.begin()
	for sh in shots:
		if sh.has("head") and sh.slot.alive and sh.tslot.alive:
			beams.add(bow_world(sh.av, sh.slot), slot_world(sh.bv, sh.tslot) + sh.jit, sh.head, sh.tail, 0.045, sh.col)
	beams.commit()

func _impact(a: FleetVis, b: FleetVis, ts: Slot, A: Vector3, B: Vector3) -> void:
	ts.hit_t = clock
	if rng.randf() < 0.24:
		_flash(b, ts)
		fx_add.spawn(FxPool.FLARE, B, 0.6, 0.14, Color(1.0, 0.8, 0.5), 1.0)
		for i in 3:
			var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0, 1), rng.randf_range(-1, 1)).normalized()
			fx_add.spawn(FxPool.EMBER, B, 0.07, rng.randf_range(0.25, 0.5), Color(1.0, 0.75, 0.4), 1.0, d * 2.5, 0.0, 2.0)
	else:
		var back := (A - B).normalized()
		fx_add.spawn(FxPool.SHIELD, B + back * 0.3, 0.62, 0.26, Color(0.55, 0.78, 1.0) if b.side == 0 else Color(1.0, 0.7, 0.5), 0.55)

# ------------------------------------------------------------ missiles, fighters
func _update_missiles() -> void:
	var now := {}
	for m in src.missiles():
		var p := src.to3(m.pos, 0.55)
		now[m.key] = p
		var col := Color(0.75, 0.88, 1.0) if m.side == 0 else Color(1.0, 0.75, 0.5)
		fx_add.spawn(FxPool.FLARE, p, 0.55, 0.035, col, 1.2)
		fx_mix.spawn(FxPool.SMOKE, p, 0.22, 1.5, Color(0.55, 0.6, 0.68), 0.45, Vector3(0, 0.05, 0), 2.5)
	for k in _missile_last.keys():
		if not now.has(k):
			var p: Vector3 = _missile_last[k]
			fx_add.spawn(FxPool.FIRE, p, 0.9, 0.5, Color.WHITE, 1.0, Vector3.ZERO, 0.8)
			fx_add.spawn(FxPool.FLARE, p, 1.4, 0.12, Color(1.0, 0.9, 0.7), 1.2)
	_missile_last = now

func _update_swarms() -> void:
	for sw in src.swarms():
		var col := Color(0.8, 0.95, 1.0) if sw.side == 0 else Color(1.0, 0.8, 0.6)
		for p in sw.pts:
			fx_add.spawn(FxPool.GLOW, src.to3(p, 0.9), 0.16, 0.035, col, 1.3)
