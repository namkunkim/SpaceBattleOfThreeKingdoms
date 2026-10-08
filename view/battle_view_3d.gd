class_name BattleView3D
extends RefCounted

# POC 3D 장면: 환경·조명·배경·격자·전대의 28척 모델. 투영(BattleViewModel)만 읽고 위치를 반영한다.
# 노드는 host(전투 노드)의 자식으로 붙인다(상품화 표현 계층이 host의 WorldEnvironment를 찾아 쓴다).
# 상품화 표현 계층(view/fleet_render)이 있으면 이 함대 노드는 숨겨지고 렌더러가 대신 그린다.

const MODEL_ROOT := "res://assets/models/user_ver3_runtime/"
const MODEL_NAMES := ["전열함", "화력함", "공성함", "보급_수리함", "전자전함", "호위함", "항모"]
const MODEL_SCALES := [1.10, 1.60, 1.55, 1.45, 1.50, 0.90, 1.55]
const SHIP_VISUAL_SCALE := 0.55
# 28척 편제: 전열함 11 · 화력함 6 · 강습항모 4 · 전자전함 3 · 공성함 1 · 보급함 3
const ROSTER := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 6, 6, 6, 6, 4, 4, 4, 2, 3, 3, 3]
const MAX_VISIBLE := 28
const FORM_VIS := 1.0

var host: Node3D
var rig: CameraRig
var model_scenes: Array[PackedScene] = []
var _glow_cache := {}

func setup(h: Node3D, camera_rig: CameraRig) -> void:
	host = h
	rig = camera_rig
	_load_models()
	_build_environment()
	build_backdrop()

func _load_models() -> void:
	for model_name in MODEL_NAMES:
		var packed := load(MODEL_ROOT + model_name + ".glb") as PackedScene
		assert(packed != null, "3D 함선 모델 로드 실패: %s" % model_name)
		model_scenes.append(packed)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("02060f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("355987")
	environment.ambient_light_energy = 0.6
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	host.add_child(world)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-56.0, -24.0, 0.0)
	key_light.light_color = Color("b9d8ff")
	key_light.light_energy = 0.76
	host.add_child(key_light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(48.0, 152.0, 0.0)
	rim.light_color = Color("4aa7ff")
	rim.light_energy = 0.42
	host.add_child(rim)
	rig.attach(host, rig.vsize)

var _backdrop: Array[Node] = []

# 전장 배경판: 실제 전장(rig.limit) 크기로 깐다. 판이 전장보다 크면 경계가 안 보여 목적지가 보이지 않는 벽에서 잘리고 레이더와 어긋난다.
# 전장이 바뀌면(init_game) 다시 부른다. 바깥은 전투장 원경판이 어둡게 채운다.
func build_backdrop() -> void:
	for n in _backdrop:
		n.queue_free()
	_backdrop.clear()
	var W := rig.limit
	var backdrop := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = W * CameraRig.S
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = load("res://assets/backgrounds/red_cliffs_starfield_v1.png") as Texture2D
	material.albedo_color = Color(0.7, 0.8, 0.9, 1.0)
	plane.material = material
	backdrop.mesh = plane
	backdrop.position = rig.w3(W * 0.5, -1.0)
	host.add_child(backdrop)
	_backdrop.append(backdrop)
	# 200px 격자
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var col := Color(0.63, 0.75, 1.0, 0.16)
	var x := 0.0
	while x <= W.x:
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(rig.w3(Vector2(x, 0.0), -0.95))
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(rig.w3(Vector2(x, W.y), -0.95))
		x += 200.0
	var y := 0.0
	while y <= W.y:
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(rig.w3(Vector2(0.0, y), -0.95))
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(rig.w3(Vector2(W.x, y), -0.95))
		y += 200.0
	mesh.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = mesh
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid.material_override = gm
	host.add_child(grid)
	_backdrop.append(grid)

# 전대 하나의 3D 노드(28척)를 만든다. FleetView의 root·nodes에 채운다.
func build_fleet(f: BattleViewModel.FleetView) -> void:
	f.root = Node3D.new()
	f.root.name = "%s-%d" % [f.fname, f.id]
	host.add_child(f.root)
	for index in MAX_VISIBLE:
		var model_index: int = ROSTER[index]
		var wrapper := Node3D.new()
		var fp: Vector2 = f.form[index] * FORM_VIS * CameraRig.S
		wrapper.position = Vector3(fp.y, 0.0, -fp.x)
		wrapper.scale = Vector3.ONE * SHIP_VISUAL_SCALE
		f.root.add_child(wrapper)
		var model := model_scenes[model_index].instantiate() as Node3D
		var hs := 1.0 if index == 0 else (0.92 if model_index < 5 else 1.0)
		# 위에서 내려다보는 전술 시점에서도 선체가 읽히도록 폭·높이를 키운다.
		model.scale = Vector3(1.0, 1.8, 2.4) * MODEL_SCALES[model_index] * hs
		model.rotation.y = -PI * 0.5
		wrapper.add_child(model)
		_add_engine_glow(wrapper, model_index, f.side, hs)
		if index == 0 and f.is_flag:
			var light := OmniLight3D.new()
			light.light_color = Color("45cfff") if f.side == 0 else Color("ff634c")
			light.light_energy = 2.2
			light.omni_range = 5.5
			light.position = Vector3(0.0, 2.0, 0.0)
			wrapper.add_child(light)
		f.nodes.append(wrapper)

func free_fleet(f: BattleViewModel.FleetView) -> void:
	if f.root:
		f.root.queue_free()
		f.root = null

func _glow_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var key := "%s-%s" % [color.to_html(), transparent]
	if _glow_cache.has(key):
		return _glow_cache[key]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 4.0
	if transparent:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glow_cache[key] = m
	return m

func _add_engine_glow(wrapper: Node3D, model_index: int, team: int, hs: float) -> void:
	var color := Color("39d7ff") if team == 0 else Color("ff714a")
	var sc: float = MODEL_SCALES[model_index] * hs
	var aft: float = 0.95 * sc
	var big := model_index < 5
	for x in [-0.62, 0.62]:
		var glow := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18 if big else 0.10
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 8
		sphere.rings = 4
		sphere.material = _glow_material(color, false)
		glow.mesh = sphere
		glow.position = Vector3(x * sc * 0.3, 0.0, aft)
		wrapper.add_child(glow)
	var trail := MeshInstance3D.new()
	var tm := BoxMesh.new()
	var len := 0.9 if big else 0.6
	tm.size = Vector3(0.10 if big else 0.055, 0.07, len)
	tm.material = _glow_material(Color(0.20, 0.78, 1.0, 0.5) if team == 0 else Color(1.0, 0.35, 0.22, 0.4), true)
	trail.mesh = tm
	trail.position = Vector3(0.0, 0.0, aft + len * 0.5)
	wrapper.add_child(trail)

# 표시 척 수(슬롯 수). 화면 전용 계산이다.
static func visible_ships(ships: float, max_ships: float) -> int:
	return maxi(1, mini(MAX_VISIBLE, ceili(28.0 * ships / maxf(1.0, max_ships))))

func sync(fleets: Array) -> void:
	for f in fleets:
		if f.root == null:
			continue
		if f.dead:
			f.root.visible = false
			continue
		f.root.position = rig.w3(f.pos)
		f.root.rotation.y = -f.heading - PI * 0.5
		var n := visible_ships(f.ships, f.max_ships)
		for i in f.nodes.size():
			f.nodes[i].visible = i < n
