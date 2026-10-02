extends Node3D
# 실시간 함대 전술 전투 (altair-corridor.html 과 동일한 플레이 규칙 / 화면 배치)
# 전장 좌표는 HTML 과 같은 2D 픽셀 단위(WORLD)로 계산하고, 3D 씬에는 S 배율로 투영한다.

const MODEL_ROOT := "res://assets/models/user_ver3_runtime/"
const MODEL_NAMES := ["전열함", "화력함", "공성함", "보급_수리함", "전자전함", "호위함", "항모"]
const MODEL_SCALES := [1.10, 1.60, 1.55, 1.45, 1.50, 0.90, 1.55]
const SHIP_VISUAL_SCALE := 0.55
# 28척 편제: 전열함 11 · 화력함 6 · 강습항모 4 · 전자전함 3 · 공성함 1 · 보급함 3
const ROSTER := [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 6, 6, 6, 6, 4, 4, 4, 2, 3, 3, 3]
const MAX_VISIBLE := 28
const PORTRAIT_SHEET := "res://assets/portraits/commanders_sheet_v1.png"

const WORLD := Vector2(3400.0, 2300.0)
const S := 0.05
const FORM_VIS := 1.0
const SHIP_GAP := 20.0
const FORM_NAMES := ["횡진", "쐐기진", "방진", "종진", "원진", "학익진", "사선진", "어린진", "안행진", "장사진"]
const CMD_R := 560.0
const MISSILE_R := 480.0
const FIGHTER_R := 380.0
const PITCH := deg_to_rad(68.0)

const C_ALLY := Color("5fe0cf")
const C_ALLY_SHIP := Color("bff3ec")
const C_FOE := Color("ff7550")
const C_FOE_SHIP := Color("ffc7a8")
const C_LIFE := Color("63d47e")
const C_GOLD := Color("f0c24b")
const C_INK := Color("dbe7e1")
const C_MUTE := Color("8ea29a")
const C_RIVET := Color("3d4f47")

class Fleet:
	var id := 0
	var form_id := 0
	var side := 0
	var fname := ""
	var role := ""
	var ships := 100.0
	var max_ships := 100.0
	var shown := 100.0
	var lv := 1
	var xp := 0.0
	var pos := Vector2.ZERO
	var heading := 0.0
	var target: Fleet = null
	var has_move := false
	var move_to := Vector2.ZERO
	var missile_cd := 0.0
	var fighter_cd := 0.0
	var defense := false
	var charge_t := 0.0
	var speech := ""
	var speech_t := 0.0
	var dead := false
	var fire_t: Fleet = null
	var flank_msg_t := 0.0
	var in_cmd := true
	var spd := 1.0
	var wait := 0.0
	var is_flag := false
	var home := Vector2.ZERO
	var form: Array[Vector2] = []
	var range_r := 300.0
	var portrait := 0
	var root: Node3D
	var nodes: Array[Node3D] = []

class Missile:
	var pos := Vector2.ZERO
	var t: Fleet
	var src: Fleet
	var dmg := 0.0
	var v := 260.0
	var wob := 0.0
	var age := 0.0
	var side := 0
	var trail := PackedVector2Array()
	var dead := false

class Swarm:
	var src: Fleet
	var t: Fleet
	var life := 9.0
	var side := 0
	var dps := 0.0
	var pts: Array[Dictionary] = []

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

const ALLY_DEF := [
	{"name": "유비", "role": "사령관 · 기함 전대", "ships": 120, "lv": 12, "x": 620, "y": 1150, "flag": true, "p": 0},
	{"name": "관우", "role": "제1분함대", "ships": 108, "lv": 8, "x": 840, "y": 960, "p": 1},
	{"name": "제갈량", "role": "제2분함대", "ships": 108, "lv": 7, "x": 840, "y": 1340, "p": 2},
	{"name": "조운", "role": "제3분함대 · 고속", "ships": 96, "lv": 9, "x": 1000, "y": 830, "spd": 1.18, "p": 3},
	{"name": "마초", "role": "제4분함대 · 고속", "ships": 96, "lv": 6, "x": 1000, "y": 1470, "spd": 1.18, "p": 5},
	{"name": "장비", "role": "제5분함대 · 전위", "ships": 100, "lv": 10, "x": 1040, "y": 1150, "p": 1},
]
const FOE_DEF := [
	{"name": "조조", "role": "원정군 총사령", "ships": 125, "lv": 12, "x": 2950, "y": 1150, "flag": true, "wait": 0, "p": 4},
	{"name": "하후돈", "role": "위 제2분함대", "ships": 110, "lv": 9, "x": 2500, "y": 880, "wait": 5, "p": 5},
	{"name": "조인", "role": "위 제3분함대", "ships": 105, "lv": 8, "x": 2500, "y": 1420, "wait": 9, "p": 5},
	{"name": "장료", "role": "위 선봉", "ships": 100, "lv": 7, "x": 2330, "y": 1150, "wait": 0, "p": 4},
	{"name": "서황", "role": "위 제4분함대", "ships": 95, "lv": 6, "x": 2680, "y": 680, "wait": 20, "p": 3},
	{"name": "악진", "role": "위 제5분함대", "ships": 95, "lv": 7, "x": 2680, "y": 1620, "wait": 16, "p": 3},
	{"name": "허저", "role": "위 친위대", "ships": 95, "lv": 10, "x": 2780, "y": 1150, "wait": 28, "p": 5},
]
const REINF_DEF := [
	{"name": "하후연", "role": "위 별동대", "ships": 85, "lv": 8, "x": 3300, "y": 260, "wait": 0, "spd": 1.15, "p": 4},
	{"name": "장합", "role": "위 별동대", "ships": 85, "lv": 9, "x": 3300, "y": 2040, "wait": 0, "spd": 1.15, "p": 5},
]
const CMDS := [
	{"id": "stop", "key": "S", "name": "정지", "cost": 0},
	{"id": "def", "key": "D", "name": "방어진형", "cost": 0},
	{"id": "missile", "key": "M", "name": "미사일 일제사격", "cost": 2},
	{"id": "fighter", "key": "F", "name": "함재기 발진", "cost": 3},
	{"id": "charge", "key": "C", "name": "전 함대 돌격", "cost": 3},
	{"id": "rally", "key": "R", "name": "기함으로 집결", "cost": 0},
	{"id": "retreat", "key": "G", "name": "후퇴", "cost": 0},
	{"id": "all", "key": "A", "name": "전 함대 선택", "cost": 0},
]

# ---- game state ----
var model_scenes: Array[PackedScene] = []
var fleets: Array[Fleet] = []
var missiles: Array[Missile] = []
var swarms: Array[Swarm] = []
var parts: Array[Part] = []
var floats: Array[Floaty] = []
var selected: Array[Fleet] = []
var inspect: Fleet = null
var groups := {}
var marker := {}
var next_id := 1
var form_counter := 0
var cam_pos := Vector2(900.0, 1150.0)
var cam_z := 0.9
var G := {}
var camera: Camera3D
var sheet: Texture2D
var vsize := Vector2(1600.0, 900.0)
var drag := {}
var last_click := 0
var panel_key := ""
var beam_flicker := 0.0
var now_t := 0.0

# ---- ui refs ----
var ui: Control
var fx: Control
var radar: Control
var cp_fills: Array[ColorRect] = []
var cp_num: Label
var clock_label: Label
var speed_btn: Button
var log_box: VBoxContainer
var toast_label: Label
var panel_root: Control
var p_portrait: TextureRect
var p_name: Label
var p_role: Label
var p_ships: Label
var p_bar: ProgressBar
var p_chips: Label
var p_hint: Label
var cmd_btns := {}
var group_btns: Array[Button] = []
var brief_ov: Control
var menu_ov: Control
var end_ov: Control
var end_labels := {}
var toast_tween: Tween

func _ready() -> void:
	randomize()
	vsize = get_viewport().get_visible_rect().size
	sheet = load(PORTRAIT_SHEET) as Texture2D
	_load_models()
	_build_environment()
	_build_backdrop()
	_build_hud()
	init_game()

# ============================================================ setup
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
	add_child(world)
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-56.0, -24.0, 0.0)
	key_light.light_color = Color("b9d8ff")
	key_light.light_energy = 0.76
	add_child(key_light)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(48.0, 152.0, 0.0)
	rim.light_color = Color("4aa7ff")
	rim.light_energy = 0.42
	add_child(rim)
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.far = 600.0
	add_child(camera)
	camera.current = true
	_update_camera()

func _build_backdrop() -> void:
	var backdrop := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = WORLD * S
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = load("res://assets/backgrounds/red_cliffs_starfield_v1.png") as Texture2D
	material.albedo_color = Color(0.7, 0.8, 0.9, 1.0)
	plane.material = material
	backdrop.mesh = plane
	backdrop.position.y = -1.0
	add_child(backdrop)
	# 200px 격자
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	var col := Color(0.63, 0.75, 1.0, 0.16)
	var x := 0.0
	while x <= WORLD.x:
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(w3(Vector2(x, 0.0), -0.95))
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(w3(Vector2(x, WORLD.y), -0.95))
		x += 200.0
	var y := 0.0
	while y <= WORLD.y:
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(w3(Vector2(0.0, y), -0.95))
		mesh.surface_set_color(col)
		mesh.surface_add_vertex(w3(Vector2(WORLD.x, y), -0.95))
		y += 200.0
	mesh.surface_end()
	var grid := MeshInstance3D.new()
	grid.mesh = mesh
	var gm := StandardMaterial3D.new()
	gm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	gm.vertex_color_use_as_albedo = true
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	grid.material_override = gm
	add_child(grid)

func w3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3((p.x - WORLD.x * 0.5) * S, y, (p.y - WORLD.y * 0.5) * S)

func _update_camera() -> void:
	var d := vsize.y * S / (2.0 * tan(deg_to_rad(24.0)) * cam_z)
	var target := w3(cam_pos)
	camera.global_position = target + Vector3(0.0, sin(PITCH), cos(PITCH)) * d
	camera.look_at(target, Vector3.UP)

func w2s(p: Vector2) -> Vector2:
	return camera.unproject_position(w3(p))

func s2w(sp: Vector2) -> Vector2:
	var o := camera.project_ray_origin(sp)
	var n := camera.project_ray_normal(sp)
	if absf(n.y) < 0.0001:
		return cam_pos
	var t := -o.y / n.y
	var hit := o + n * t
	return Vector2(hit.x / S + WORLD.x * 0.5, hit.z / S + WORLD.y * 0.5)

# ============================================================ HUD
func _style(bg: Color, border: Color, radius := 6, bw := 1) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(bw)
	st.set_corner_radius_all(radius)
	return st

func _panel(parent: Node, pos: Vector2, sz: Vector2, bg: Color, border: Color, radius := 6) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	p.add_theme_stylebox_override("panel", _style(bg, border, radius))
	parent.add_child(p)
	return p

func _label(parent: Node, text: String, pos: Vector2, size: int, color: Color, width := -1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if width > 0.0:
		l.size = Vector2(width, size * 1.4)
		l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, pos: Vector2, sz: Vector2, size: int, bg: Color, border: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = sz
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_stylebox_override("normal", _style(bg, border, 4))
	b.add_theme_stylebox_override("hover", _style(bg.lightened(0.18), C_ALLY, 4))
	b.add_theme_stylebox_override("pressed", _style(bg.darkened(0.2), C_ALLY, 4))
	b.add_theme_stylebox_override("disabled", _style(bg.darkened(0.4), border, 4))
	parent.add_child(b)
	return b

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	# 전투 오버레이(그리기 전용)
	fx = Control.new()
	fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add_mat := CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	fx.material = add_mat
	fx.draw.connect(_draw_fx)
	canvas.add_child(fx)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	canvas.add_child(ui)

	# ---- 상단 중앙: 커맨드 포인트 + SYSTEM ----
	var top := _panel(ui, Vector2(vsize.x * 0.5 - 200.0, 6.0), Vector2(400.0, 38.0), Color("18211e"), C_RIVET, 6)
	var hex := ColorRect.new()
	hex.color = C_GOLD
	hex.position = Vector2(10.0, 12.0)
	hex.size = Vector2(14.0, 14.0)
	top.add_child(hex)
	for i in 10:
		var back := ColorRect.new()
		back.color = Color("1a2a44")
		back.position = Vector2(32.0 + i * 22.0, 14.0)
		back.size = Vector2(20.0, 10.0)
		top.add_child(back)
		var fill := ColorRect.new()
		fill.color = Color("5f8fea")
		fill.size = Vector2(0.0, 10.0)
		back.add_child(fill)
		cp_fills.append(fill)
	cp_num = _label(top, "0", Vector2(256.0, 9.0), 16, Color("b9cdfa"))
	var sys := _button(top, "SYSTEM", Vector2(300.0, 6.0), Vector2(90.0, 26.0), 12, Color("2b3a34"), Color("5d7268"))
	sys.pressed.connect(_toggle_menu)

	# ---- 상단 우측: 시계 + 속도 ----
	clock_label = _label(ui, "00:00", Vector2(vsize.x - 130.0, 10.0), 16, C_MUTE)
	speed_btn = _button(ui, "×1", Vector2(vsize.x - 66.0, 6.0), Vector2(54.0, 28.0), 13, Color("2b3a34"), Color("5d7268"))
	speed_btn.pressed.connect(_toggle_speed)

	# ---- 상단 좌측: 교신 로그 ----
	log_box = VBoxContainer.new()
	log_box.position = Vector2(12.0, 8.0)
	log_box.size = Vector2(320.0, 200.0)
	log_box.add_theme_constant_override("separation", 4)
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(log_box)

	toast_label = _label(ui, "", Vector2(0.0, vsize.y - 210.0), 15, C_GOLD, vsize.x)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0

	# ---- 하단 좌측: 레이더 ----
	var rw := _panel(ui, Vector2(12.0, vsize.y - 152.0), Vector2(140.0, 140.0), Color("101714"), C_RIVET, 70)
	radar = Control.new()
	radar.position = Vector2(6.0, 6.0)
	radar.size = Vector2(128.0, 128.0)
	radar.clip_contents = true
	radar.draw.connect(_draw_radar)
	radar.gui_input.connect(_radar_input)
	rw.add_child(radar)

	# ---- 하단 중앙: 함대 정보 패널 ----
	panel_root = _panel(ui, Vector2(vsize.x * 0.5 - 280.0, vsize.y - 116.0), Vector2(560.0, 108.0), Color("1c2723"), C_RIVET, 6)
	p_portrait = TextureRect.new()
	p_portrait.position = Vector2(10.0, 10.0)
	p_portrait.size = Vector2(88.0, 88.0)
	p_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel_root.add_child(p_portrait)
	p_name = _label(panel_root, "", Vector2(108.0, 8.0), 18, Color("f1f6f3"), 440.0)
	p_role = _label(panel_root, "", Vector2(108.0, 32.0), 12, C_MUTE, 440.0)
	p_ships = _label(panel_root, "", Vector2(108.0, 50.0), 13, Color("c9d8d1"), 440.0)
	p_bar = ProgressBar.new()
	p_bar.position = Vector2(108.0, 72.0)
	p_bar.size = Vector2(440.0, 7.0)
	p_bar.show_percentage = false
	p_bar.add_theme_stylebox_override("background", _style(Color("0a1210"), Color("2d3b35"), 2))
	p_bar.add_theme_stylebox_override("fill", _style(C_LIFE, C_LIFE, 2, 0))
	panel_root.add_child(p_bar)
	p_chips = _label(panel_root, "", Vector2(108.0, 84.0), 12, C_MUTE, 440.0)
	p_hint = _label(panel_root, "", Vector2(20.0, 26.0), 14, C_MUTE, 520.0)
	p_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p_hint.clip_text = false

	# ---- 하단 우측: 그룹 탭 + 명령 ----
	var gx := vsize.x - 12.0 - 156.0
	for i in 4:
		var b := _button(ui, ["I", "II", "III", "IV"][i], Vector2(gx + i * 39.0, vsize.y - 128.0 - 6.0 - 34.0 + 34.0 - 34.0 + 0.0), Vector2(34.0, 34.0), 12, Color("2f5ea8"), Color("7fb3ff"))
		b.position.y = vsize.y - 12.0 - 100.0 - 6.0 - 34.0
		b.tooltip_text = "그룹 %s 선택 (%d) · 길게 누르면 저장" % [["I", "II", "III", "IV"][i], i + 1]
		var idx := i + 1
		b.button_down.connect(_group_down.bind(idx))
		b.button_up.connect(_group_up.bind(idx))
		group_btns.append(b)
	var cmd_panel := _panel(ui, Vector2(vsize.x - 12.0 - 210.0, vsize.y - 12.0 - 100.0), Vector2(210.0, 100.0), Color("1c2723"), C_RIVET, 6)
	for i in CMDS.size():
		var c: Dictionary = CMDS[i]
		var warm := Color("35507a")
		if c.id == "missile" or c.id == "fighter":
			warm = Color("7a3a4c")
		elif c.id == "charge":
			warm = Color("7a6230")
		var label := "%s\n%s" % [["정지","방어","미사일","함재기","돌격","집결","후퇴","전체"][i], c.key]
		var b := _button(cmd_panel, label, Vector2(7.0 + (i % 4) * 49.0, 7.0 + (i / 4) * 47.0), Vector2(46.0, 44.0), 10, warm, Color("4a5e56"))
		b.tooltip_text = "%s (%s)%s" % [c.name, c.key, (" · CP %d" % c.cost) if c.cost > 0 else ""]
		b.pressed.connect(do_cmd.bind(c.id))
		cmd_btns[c.id] = b

	# ---- 오버레이 ----
	brief_ov = _overlay(
		"성간연합 제13함대 · 작전 브리핑".replace("성간연합 제13함대", "촉한 연합함대"),
		"적벽 회랑 전투",
		"사령관 유비 제독. 위(魏) 원정군 7개 분함대가 회랑을 건너오고 있습니다. 교전 중 적 증원이 측면에서 나타날 가능성이 있습니다. 기함을 지키면서 적 함대를 모두 격파하십시오.\n\n"
		+ "• 측면·배후 공격: 적의 옆구리를 치면 화력 +30%, 뒤를 잡으면 +60%.\n"
		+ "• 지휘 범위: 기함 주위 원 밖의 함대는 화력이 25% 떨어집니다.\n"
		+ "• 커맨드 포인트: 상단 게이지로 미사일, 함재기, 돌격 명령을 쓸 수 있습니다.\n\n"
		+ "선택: 함대 클릭 · 드래그 범위 선택 · 그룹 I–IV (Ctrl+숫자로 지정)\n"
		+ "명령: 빈 곳 클릭/우클릭 = 이동 · 적 함대 클릭 = 공격 · Esc = 선택 해제\n"
		+ "화면: 우클릭 드래그 또는 방향키 = 이동 · 휠 = 확대 · 레이더 클릭 = 점프 · Space = 일시정지",
		[["출격", _start]])
	menu_ov = _overlay("SYSTEM", "일시정지",
		"S 정지 · D 방어진형 · M 미사일 · F 함재기\nC 돌격 · R 기함으로 집결 · G 후퇴 · A 전 함대 선택\n그룹 탭을 길게 누르면 현재 선택을 그 탭에 저장합니다.",
		[["계속", _close_menu], ["처음부터", _restart], ["종료", _quit]])
	menu_ov.visible = false
	end_ov = _overlay("전투 종료", "승리", "", [["다시 출격", _restart]])
	end_ov.visible = false

func _overlay(eyebrow: String, title: String, body: String, buttons: Array) -> Control:
	var ov := ColorRect.new()
	ov.color = Color(0.01, 0.015, 0.03, 0.82)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(ov)
	var card := _panel(ov, Vector2(vsize.x * 0.5 - 310.0, vsize.y * 0.5 - 250.0), Vector2(620.0, 500.0), Color("141c19"), C_RIVET, 8)
	var eb := _label(card, eyebrow, Vector2(28.0, 24.0), 12, C_ALLY)
	var t := _label(card, title, Vector2(28.0, 46.0), 34, Color("f3f8f5"))
	var bd := _label(card, body, Vector2(28.0, 100.0), 14, Color("c3d3cb"), 564.0)
	bd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bd.clip_text = false
	bd.size = Vector2(564.0, 300.0)
	ov.set_meta("eyebrow", eb)
	ov.set_meta("title", t)
	ov.set_meta("body", bd)
	var x := 28.0
	for spec in buttons:
		var b := _button(card, spec[0], Vector2(x, 428.0), Vector2(140.0, 46.0), 16, Color("1f8f81") if x < 30.0 else Color("2b3a34"), C_ALLY)
		b.pressed.connect(spec[1])
		x += 152.0
	return ov

# ============================================================ game init
func _mk_fleet(d: Dictionary, side: int) -> Fleet:
	var f := Fleet.new()
	f.id = next_id
	next_id += 1
	f.side = side
	f.fname = d.name
	f.role = d.role
	f.ships = float(d.ships)
	f.max_ships = f.ships
	f.shown = f.ships
	f.lv = d.lv
	f.pos = Vector2(d.x, d.y)
	f.heading = PI if side == 1 else 0.0
	f.is_flag = d.get("flag", false)
	f.spd = d.get("spd", 1.0)
	f.wait = float(d.get("wait", 0))
	f.portrait = d.p
	f.home = f.pos
	f.form_id = form_counter
	form_counter += 1
	f.form = formation_offsets(f.form_id % FORM_NAMES.size(), 1.0 if f.form_id < FORM_NAMES.size() else 1.35)
	_build_fleet_3d(f)
	return f

# 28척 진형 좌표 (x=전방, y=측면, 단위 px). 앞쪽 슬롯일수록 전열함이 배치된다.
func formation_offsets(kind: int, dens: float) -> Array[Vector2]:
	var d := SHIP_GAP * dens
	var pts: Array[Vector2] = []
	match kind:
		0: # 횡진: 2열 횡대
			for k in 28:
				pts.append(Vector2(-(k / 14) * d, (k % 14 - 6.5) * d))
		1: # 쐐기진: 전방 돌출 V
			pts.append(Vector2.ZERO)
			for k in range(1, 28):
				var rank := (k + 1) / 2
				pts.append(Vector2(-rank * d * 0.9, rank * d * (1.0 if k % 2 == 1 else -1.0)))
		2: # 방진: 4x7 방형
			for k in 28:
				pts.append(Vector2(-(k / 7) * d, (k % 7 - 3.0) * d))
		3: # 종진: 3열 종대
			for k in 28:
				pts.append(Vector2(-(k / 3) * d, (k % 3 - 1.0) * d))
		4: # 원진: 동심원
			pts.append(Vector2.ZERO)
			var rings := [[7, 1.4], [12, 2.6], [8, 3.6]]
			for rg in rings:
				for i in int(rg[0]):
					var a: float = TAU * i / int(rg[0])
					pts.append(Vector2(cos(a), sin(a)) * d * float(rg[1]))
		5: # 학익진: 양익이 앞으로 굽은 호
			for k in 28:
				var ly := (k - 13.5) * d * 0.85
				pts.append(Vector2(absf(ly) * 0.45, ly))
		6: # 사선진: 대각선 2열
			for k in 28:
				var line := k / 14
				var i := k % 14
				pts.append(Vector2((6.5 - i) * d * 0.7 - line * d, (i - 6.5) * d * 0.9 + line * d * 0.6))
		7: # 어린진: 엇갈린 6-5 배열
			var row := 0
			var placed := 0
			while placed < 28:
				var cols := 6 if row % 2 == 0 else 5
				for c in cols:
					if placed >= 28:
						break
					pts.append(Vector2(-row * d * 0.9, (c - (cols - 1) * 0.5) * d))
					placed += 1
				row += 1
		8: # 안행진: 후방 돌출 역V
			pts.append(Vector2.ZERO)
			for k in range(1, 28):
				var rank := (k + 1) / 2
				pts.append(Vector2(rank * d * 0.9 - 14.0 * d * 0.9 * 0.0, rank * d * (1.0 if k % 2 == 1 else -1.0)))
		_: # 장사진: 2열 장사 종대(엇갈림)
			for k in 28:
				pts.append(Vector2(-(k / 2) * d * 0.8, ((k % 2) - 0.5) * d * 1.1 + sin(k * 0.45) * d * 0.5))
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= pts.size()
	for i in pts.size():
		pts[i] -= c
	return pts

func _build_fleet_3d(f: Fleet) -> void:
	f.root = Node3D.new()
	f.root.name = "%s-%d" % [f.fname, f.id]
	add_child(f.root)
	for index in MAX_VISIBLE:
		var model_index: int = ROSTER[index]
		var wrapper := Node3D.new()
		var fp: Vector2 = f.form[index] * FORM_VIS * S
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

var _glow_cache := {}
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

func init_game() -> void:
	for f in fleets:
		f.root.queue_free()
	next_id = 1
	form_counter = 0
	fleets.clear()
	missiles.clear()
	swarms.clear()
	parts.clear()
	floats.clear()
	selected.clear()
	inspect = null
	marker = {}
	for d in ALLY_DEF:
		fleets.append(_mk_fleet(d, 0))
	for d in FOE_DEF:
		fleets.append(_mk_fleet(d, 1))
	G = {"t": 0.0, "cp": 3.0, "ecp": 3.0, "reinf": false, "state": "brief", "speed": 1, "killed": 0.0, "lost": 0.0, "ai_t": 0.0, "panel_t": 0.0, "over": false, "end_t": -1.0, "end_win": false, "end_text": ""}
	groups = {1: [fleets[0].id], 2: [fleets[1].id, fleets[3].id], 3: [fleets[2].id, fleets[4].id], 4: [fleets[5].id]}
	cam_pos = Vector2(900.0, 1150.0)
	cam_z = clampf(vsize.x / 1500.0, 0.45, 1.0)
	speed_btn.text = "×1"
	for c in log_box.get_children():
		c.queue_free()
	panel_key = ""
	refresh_panel()

func _start() -> void:
	brief_ov.visible = false
	end_ov.visible = false
	menu_ov.visible = false
	G.state = "play"
	selected = [flag(0)]
	refresh_panel()
	add_log("전 함대, 전투 배치 완료.", "", fleets[0])
	var foe: Fleet = null
	for f in fleets:
		if f.side == 1 and not f.is_flag:
			foe = f
			break
	get_tree().create_timer(0.9).timeout.connect(func(): if G.state == "play": add_log("위군 선봉, 회랑 진입 확인.", "foe", foe))

func _restart() -> void:
	init_game()
	_start()

func _quit() -> void:
	get_tree().quit()

func _toggle_menu() -> void:
	if G.state == "play":
		G.state = "pause"
		menu_ov.visible = true
	elif G.state == "pause":
		_close_menu()

func _close_menu() -> void:
	menu_ov.visible = false
	G.state = "play"

func _toggle_speed() -> void:
	G.speed = 2 if G.speed == 1 else 1
	speed_btn.text = "×%d" % G.speed

# ============================================================ helpers
func alive(side: int) -> Array[Fleet]:
	var out: Array[Fleet] = []
	for f in fleets:
		if not f.dead and f.side == side:
			out.append(f)
	return out

func flag(side: int) -> Fleet:
	for f in fleets:
		if f.is_flag and f.side == side and not f.dead:
			return f
	return null

func by_id(id: int) -> Fleet:
	for f in fleets:
		if f.id == id:
			return f
	return null

func ang_diff(a: float, b: float) -> float:
	var d := fmod(b - a, TAU)
	if d > PI:
		d -= TAU
	if d < -PI:
		d += TAU
	return d

func nearest_foe(f: Fleet, max_r: float) -> Fleet:
	var best: Fleet = null
	var bd := max_r
	for o in fleets:
		if o.dead or o.side == f.side:
			continue
		var d := f.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best

func n_ships(ships: float, mx: float = 100.0) -> int:
	return maxi(1, mini(MAX_VISIBLE, ceili(28.0 * ships / maxf(1.0, mx))))

func ship_pos(f: Fleet, i: int) -> Vector2:
	return f.pos + f.form[i % f.form.size()].rotated(f.heading) * FORM_VIS

func rand_ship(f: Fleet) -> Vector2:
	return ship_pos(f, randi() % n_ships(f.ships, f.max_ships))

func say(f: Fleet, text: String) -> void:
	if f:
		f.speech = text
		f.speech_t = 2.4

func float_text(p: Vector2, text: String, color: Color) -> void:
	var t := Floaty.new()
	t.pos = p
	t.text = text
	t.color = color
	floats.append(t)

func toast(text: String) -> void:
	toast_label.text = text
	if toast_tween:
		toast_tween.kill()
	toast_label.modulate.a = 1.0
	toast_tween = create_tween()
	toast_tween.tween_interval(1.5)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func add_log(text: String, kind: String, f: Fleet) -> void:
	var row := PanelContainer.new()
	var border := C_ALLY
	if kind == "foe":
		border = C_FOE
	elif kind == "sys":
		border = C_GOLD
	row.add_theme_stylebox_override("panel", _style(Color(0.05, 0.11, 0.10, 0.85) if kind != "foe" else Color(0.16, 0.06, 0.05, 0.85), border, 2))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hb)
	if f:
		var tr := TextureRect.new()
		tr.texture = _portrait_tex(f.portrait)
		tr.custom_minimum_size = Vector2(26.0, 26.0)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hb.add_child(tr)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", C_INK)
	hb.add_child(l)
	log_box.add_child(row)
	log_box.move_child(row, 0)
	while log_box.get_child_count() > 6:
		log_box.get_child(log_box.get_child_count() - 1).queue_free()
		log_box.remove_child(log_box.get_child(log_box.get_child_count() - 1))
	var tw := row.create_tween()
	tw.tween_interval(6.5)
	tw.tween_property(row, "modulate:a", 0.0, 0.6)
	tw.tween_callback(row.queue_free)

var _ptex := {}
func _portrait_tex(i: int) -> Texture2D:
	if _ptex.has(i):
		return _ptex[i]
	var at := AtlasTexture.new()
	at.atlas = sheet
	at.region = Rect2((i % 3) * 512.0 + 5.0, (i / 3) * 512.0 + 5.0, 502.0, 502.0)
	_ptex[i] = at
	return at

# ============================================================ combat
func flank_mul(att: Fleet, tgt: Fleet) -> float:
	var a := atan2(att.pos.y - tgt.pos.y, att.pos.x - tgt.pos.x)
	var d := absf(ang_diff(tgt.heading, a))
	if d < PI / 3.0:
		return 1.0
	if d < PI * 2.0 / 3.0:
		return 1.3
	return 1.6

func power(f: Fleet) -> float:
	return (1.0 + 0.07 * (f.lv - 1)) * (1.35 if f.charge_t > 0.0 else 1.0) * (1.0 if f.in_cmd else 0.75) * (0.7 if f.defense else 1.0)

func boom(p: Vector2, n: int, side: int) -> void:
	for i in n:
		var pt := Part.new()
		var a := randf() * TAU
		var s := 20.0 + randf() * 90.0
		pt.pos = p
		pt.vel = Vector2(cos(a), sin(a)) * s
		pt.life = 0.4 + randf() * 0.6
		pt.maxl = 1.0
		pt.size = 1.0 + randf() * 2.2
		pt.col = Color("ffd28a") if randf() < 0.5 else (Color("ff8a5c") if side == 1 else Color("9ff0ff"))
		parts.append(pt)
	var ring := Part.new()
	ring.pos = p
	ring.life = 0.35
	ring.maxl = 0.35
	ring.size = 9.0
	ring.col = Color("fff2d0")
	ring.ring = true
	parts.append(ring)

func apply_dmg(src: Fleet, tgt: Fleet, amt: float) -> void:
	if tgt.dead:
		return
	if tgt.defense:
		amt *= 0.6
	amt = minf(amt, tgt.ships)
	tgt.ships -= amt
	if src and not src.dead:
		src.xp += amt
		var need := 20.0 + src.lv * 12.0
		if src.xp >= need and src.lv < 20:
			src.xp -= need
			src.lv += 1
			float_text(src.pos + Vector2(0.0, -60.0), "LEVEL UP", C_GOLD)
	if tgt.side == 1:
		G.killed += amt
	else:
		G.lost += amt
	while tgt.shown - tgt.ships >= 1.0:
		tgt.shown -= 1.0
		boom(rand_ship(tgt), 10, tgt.side)
	if tgt.ships <= 0.5:
		kill(tgt, src)

func kill(f: Fleet, src: Fleet) -> void:
	if f.dead:
		return
	f.dead = true
	f.ships = 0.0
	for i in n_ships(f.max_ships, f.max_ships):
		boom(ship_pos(f, i), 8, f.side)
	f.root.visible = false
	selected.erase(f)
	if inspect == f:
		inspect = null
	for o in fleets:
		if o.target == f:
			o.target = null
	if f.side == 1:
		add_log("%s 함대 격파!" % f.fname, "", src if (src and src.side == 0) else null)
		if src and not src.dead and src.side == 0:
			say(src, "적 함대 격파!")
	else:
		add_log("%s 함대가 궤멸되었습니다" % f.fname, "foe", f)
	refresh_panel()

func fire_missiles(f: Fleet, tgt: Fleet) -> void:
	for i in 6:
		var m := Missile.new()
		m.pos = rand_ship(f)
		m.t = tgt
		m.src = f
		m.dmg = f.ships * 0.03 * power(f) / (0.7 if f.defense else 1.0)
		m.v = 260.0 + randf() * 60.0
		m.wob = (randf() - 0.5) * 2.4
		m.side = f.side
		missiles.append(m)
	f.missile_cd = 18.0

func launch_fighters(f: Fleet, tgt: Fleet) -> void:
	var s := Swarm.new()
	s.src = f
	s.t = tgt
	s.side = f.side
	s.dps = f.ships * 0.009 * (1.0 + 0.07 * (f.lv - 1))
	for i in 22:
		s.pts.append({"pos": rand_ship(f), "a": randf() * TAU, "r": 20.0 + randf() * 50.0, "w": (-1.0 if randf() < 0.5 else 1.0) * (1.5 + randf() * 2.0)})
	swarms.append(s)
	f.fighter_cd = 26.0

# ============================================================ enemy AI
func enemy_ai() -> void:
	var pl := alive(0)
	if pl.is_empty():
		return
	for f in alive(1):
		var n: Fleet = null
		var nd := 1e9
		for p in pl:
			var d := f.pos.distance_to(p.pos)
			if d < nd:
				nd = d
				n = p
		if f.is_flag:
			if nd < 750.0:
				f.target = n
			else:
				f.target = null
				if f.pos.distance_to(f.home) > 30.0:
					f.has_move = true
					f.move_to = f.home
		elif G.t >= f.wait or nd < 700.0:
			if f.target == null or f.target.dead or randf() < 0.15:
				var best: Fleet = null
				var bs := 1e9
				for p in pl:
					var sc := f.pos.distance_to(p.pos) * (0.55 + p.ships / p.max_ships * 0.6)
					if sc < bs:
						bs = sc
						best = p
				f.target = best
		else:
			f.target = null
			f.has_move = true
			f.move_to = Vector2(f.home.x - G.t * 4.0, f.home.y)
		if f.ships < f.max_ships * 0.3 and not f.defense:
			f.defense = true
			say(f, "방어진을 펴라!")
		var t := f.target
		if t and not t.dead:
			var d := f.pos.distance_to(t.pos)
			if f.missile_cd <= 0.0 and G.ecp >= 2.0 and d <= MISSILE_R and randf() < 0.3:
				fire_missiles(f, t)
				G.ecp -= 2.0
				say(f, "미사일 발사!")
			elif f.fighter_cd <= 0.0 and G.ecp >= 3.0 and d <= FIGHTER_R and randf() < 0.18:
				launch_fighters(f, t)
				G.ecp -= 3.0
				say(f, "전투정 발진!")

func spawn_reinf() -> void:
	G.reinf = true
	for d in REINF_DEF:
		fleets.append(_mk_fleet(d, 1))
	add_log("경고: 위군 별동대 2개 함대가 측면에 출현!", "sys", null)
	toast("적 증원 함대 출현 · 측면 주의")

# ============================================================ update
func update_sim(dt: float) -> void:
	G.t += dt
	G.cp = minf(10.0, G.cp + dt / 4.5)
	G.ecp = minf(10.0, G.ecp + dt / 5.5)
	if not G.reinf and G.t > 95.0:
		spawn_reinf()
	G.ai_t -= dt
	if G.ai_t <= 0.0:
		G.ai_t = 0.5
		enemy_ai()
	var flags := [flag(0), flag(1)]
	for f in fleets:
		if f.dead:
			continue
		f.missile_cd = maxf(0.0, f.missile_cd - dt)
		f.fighter_cd = maxf(0.0, f.fighter_cd - dt)
		if f.charge_t > 0.0:
			f.charge_t -= dt
		if f.flank_msg_t > 0.0:
			f.flank_msg_t -= dt
		if f.speech_t > 0.0:
			f.speech_t -= dt
		var fl: Fleet = flags[f.side]
		f.in_cmd = fl == null or fl == f or f.pos.distance_to(fl.pos) < CMD_R
		if f.target and f.target.dead:
			f.target = null
		var has_dest := false
		var dest := Vector2.ZERO
		if f.target:
			if f.pos.distance_to(f.target.pos) > f.range_r * 0.8:
				has_dest = true
				dest = f.target.pos
		elif f.has_move:
			if f.pos.distance_to(f.move_to) < 10.0:
				f.has_move = false
			else:
				has_dest = true
				dest = f.move_to
		var spd := 62.0 * f.spd * (0.5 if f.defense else 1.0) * (1.4 if f.charge_t > 0.0 else 1.0)
		if has_dest:
			var a := atan2(dest.y - f.pos.y, dest.x - f.pos.x)
			var m := 1.7 * dt
			var dh := ang_diff(f.heading, a)
			f.heading += dh if absf(dh) < m else signf(dh) * m
			var dd := f.pos.distance_to(dest)
			if dd < spd * 0.7:
				f.pos += (dest - f.pos) * minf(1.0, dt * 2.0)
			else:
				var k := maxf(0.3, cos(ang_diff(f.heading, a)))
				var st := minf(spd * dt * k, dd)
				f.pos += Vector2(cos(f.heading), sin(f.heading)) * st
		var ft: Fleet = f.target if (f.target and f.pos.distance_to(f.target.pos) <= f.range_r) else nearest_foe(f, f.range_r)
		f.fire_t = ft
		if ft:
			if not has_dest:
				var a2 := atan2(ft.pos.y - f.pos.y, ft.pos.x - f.pos.x)
				var m2 := 1.7 * dt
				var dh2 := ang_diff(f.heading, a2)
				f.heading += dh2 if absf(dh2) < m2 else signf(dh2) * m2
			var fm := flank_mul(f, ft)
			apply_dmg(f, ft, f.ships * 0.011 * power(f) * fm * dt)
			if fm > 1.0 and f.flank_msg_t <= 0.0:
				f.flank_msg_t = 3.0
				float_text(ft.pos + Vector2(0.0, -50.0), "배후 공격!" if fm > 1.4 else "측면 공격!", C_FOE if f.side == 1 else C_GOLD)
	# 함대 간 간격
	for i in fleets.size():
		var a: Fleet = fleets[i]
		if a.dead:
			continue
		for j in range(i + 1, fleets.size()):
			var b: Fleet = fleets[j]
			if b.dead:
				continue
			var dv := b.pos - a.pos
			var d := maxf(dv.length(), 0.001)
			var mn := 110.0 if a.side == b.side else 90.0
			if d < mn:
				var p := (mn - d) * 0.5 * minf(1.0, dt * 4.0)
				a.pos -= dv / d * p
				b.pos += dv / d * p
	for f in fleets:
		f.pos.x = clampf(f.pos.x, 40.0, WORLD.x - 40.0)
		f.pos.y = clampf(f.pos.y, 40.0, WORLD.y - 40.0)
	# 미사일
	for m in missiles:
		m.age += dt
		if m.t.dead:
			m.dead = true
			continue
		var a := atan2(m.t.pos.y - m.pos.y, m.t.pos.x - m.pos.x) + m.wob * maxf(0.0, 0.6 - m.age)
		m.pos += Vector2(cos(a), sin(a)) * m.v * dt
		m.v += 120.0 * dt
		m.trail.append(m.pos)
		if m.trail.size() > 8:
			m.trail.remove_at(0)
		if m.pos.distance_to(m.t.pos) < 22.0:
			m.dead = true
			apply_dmg(m.src, m.t, m.dmg)
			boom(m.pos, 8, m.t.side)
	missiles = missiles.filter(func(m): return not m.dead)
	# 함재기
	for s in swarms:
		s.life -= dt
		if s.t.dead or s.src.dead:
			s.life = minf(s.life, 1.0)
		for p in s.pts:
			p.a += p.w * dt
			var goal: Vector2 = s.t.pos + Vector2(cos(p.a), sin(p.a)) * p.r
			if s.life < 1.0:
				p.pos += (s.src.pos - p.pos) * dt * 2.0
			else:
				p.pos += (goal - p.pos) * minf(1.0, dt * 2.2)
		if not s.t.dead and s.life > 1.0 and s.pts.size() > 0 and (s.pts[0].pos as Vector2).distance_to(s.t.pos) < 120.0:
			apply_dmg(s.src, s.t, s.dps * dt)
			if randf() < dt * 6.0:
				boom(rand_ship(s.t), 3, s.t.side)
	swarms = swarms.filter(func(s): return s.life > 0.0)
	for p in parts:
		p.life -= dt
		p.pos += p.vel * dt
		p.vel *= 0.96
	parts = parts.filter(func(p): return p.life > 0.0)
	for t in floats:
		t.t -= dt
		t.pos.y -= 18.0 * dt
	floats = floats.filter(func(t): return t.t > 0.0)
	if not marker.is_empty():
		marker.t -= dt
		if marker.t <= 0.0:
			marker = {}
	if not G.over:
		if flag(0) == null:
			end_game(false, "기함이 격침되었습니다. 지휘 계통이 무너진 함대는 회랑에서 철수합니다.")
		elif alive(1).is_empty():
			if not G.reinf:
				spawn_reinf()
			else:
				end_game(true, "위 원정군이 회랑에서 모두 사라졌습니다. 회랑은 연합의 손에 남습니다.")

func end_game(win: bool, text: String) -> void:
	G.over = true
	G.end_t = 1.6
	G.end_win = win
	G.end_text = text

func _show_end() -> void:
	G.state = "end"
	end_ov.visible = true
	var win: bool = G.end_win
	(end_ov.get_meta("eyebrow") as Label).text = "작전 성공" if win else "작전 실패"
	(end_ov.get_meta("title") as Label).text = "회랑을 지켜냈습니다" if win else "기함 격침"
	var t := int(G.t)
	(end_ov.get_meta("body") as Label).text = "%s\n\n격침한 적 함정  %d\n잃은 아군 함정  %d\n교전 시간  %d:%02d" % [G.end_text, roundi(G.killed), roundi(G.lost), t / 60, t % 60]

func _process(delta: float) -> void:
	now_t += delta
	var dt := minf(0.05, delta)
	if G.state == "play":
		var ps := 700.0 * dt / cam_z
		if Input.is_key_pressed(KEY_LEFT):
			cam_pos.x -= ps
		if Input.is_key_pressed(KEY_RIGHT):
			cam_pos.x += ps
		if Input.is_key_pressed(KEY_UP):
			cam_pos.y -= ps
		if Input.is_key_pressed(KEY_DOWN):
			cam_pos.y += ps
		_clamp_cam()
		for i in int(G.speed):
			update_sim(dt)
		G.panel_t -= dt
		if G.panel_t <= 0.0:
			G.panel_t = 0.25
			refresh_panel()
		if G.over and G.end_t > 0.0:
			G.end_t -= dt
			if G.end_t <= 0.0:
				_show_end()
	elif G.state == "brief":
		cam_pos.x = 900.0 + sin(now_t / 5.0) * 120.0
	elif G.state == "end" or G.state == "pause":
		pass
	_sync_3d()
	_update_camera()
	_paint_cmds()
	fx.queue_redraw()
	ui.queue_redraw()
	radar.queue_redraw()

func _sync_3d() -> void:
	for f in fleets:
		if f.dead:
			continue
		f.root.position = w3(f.pos)
		f.root.rotation.y = -f.heading - PI * 0.5
		var n := n_ships(f.ships, f.max_ships)
		for i in f.nodes.size():
			f.nodes[i].visible = i < n

func _clamp_cam() -> void:
	cam_pos.x = clampf(cam_pos.x, 0.0, WORLD.x)
	cam_pos.y = clampf(cam_pos.y, 0.0, WORLD.y)
	cam_z = clampf(cam_z, 0.35, 1.7)

# ============================================================ commands
func my_sel() -> Array[Fleet]:
	var out: Array[Fleet] = []
	for f in selected:
		if not f.dead:
			out.append(f)
	return out

func lead() -> Fleet:
	var s := my_sel()
	for f in s:
		if f.is_flag:
			return f
	return s[0] if s.size() > 0 else null

func do_cmd(id: String) -> void:
	if G.state != "play":
		return
	if id == "all":
		selected = alive(0)
		inspect = null
		refresh_panel()
		return
	var s := my_sel()
	if s.is_empty():
		toast("먼저 아군 함대를 선택하세요")
		return
	var L := lead()
	match id:
		"stop":
			for f in s:
				f.target = null
				f.has_move = false
			say(L, "전 함 정지.")
		"def":
			var on := false
			for f in s:
				if not f.defense:
					on = true
			for f in s:
				f.defense = on
			say(L, "방어진형으로 전환!" if on else "방어진형 해제.")
		"missile":
			if G.cp < 2.0:
				toast("커맨드 포인트가 부족합니다 (필요 2)")
				return
			var n := 0
			for f in s:
				if f.missile_cd > 0.0:
					continue
				var t: Fleet = f.target if (f.target and f.pos.distance_to(f.target.pos) <= MISSILE_R) else nearest_foe(f, MISSILE_R)
				if t:
					fire_missiles(f, t)
					n += 1
			if n == 0:
				var ready := false
				for f in s:
					if f.missile_cd <= 0.0:
						ready = true
				toast("미사일 사정거리 안에 적이 없습니다" if ready else "미사일 재장전 중")
				return
			G.cp -= 2.0
			say(L, "미사일, 일제 발사!")
			add_log("%d개 함대 미사일 일제사격" % n, "", L)
		"fighter":
			if G.cp < 3.0:
				toast("커맨드 포인트가 부족합니다 (필요 3)")
				return
			var n := 0
			for f in s:
				if f.fighter_cd > 0.0:
					continue
				var t: Fleet = f.target if (f.target and f.pos.distance_to(f.target.pos) <= FIGHTER_R) else nearest_foe(f, FIGHTER_R)
				if t:
					launch_fighters(f, t)
					n += 1
			if n == 0:
				var ready := false
				for f in s:
					if f.fighter_cd <= 0.0:
						ready = true
				toast("함재기 작전 반경 안에 적이 없습니다" if ready else "함재기 정비 중")
				return
			G.cp -= 3.0
			say(L, "함재기, 발진!")
		"charge":
			if G.cp < 3.0:
				toast("커맨드 포인트가 부족합니다 (필요 3)")
				return
			G.cp -= 3.0
			for f in s:
				f.charge_t = 10.0
				f.defense = false
				if f.target == null:
					var t := nearest_foe(f, 900.0)
					if t:
						f.target = t
			say(L, "전 함대, 돌격하라!")
			add_log("돌격 명령 · 10초간 화력·속도 상승", "", L)
		"rally":
			var pf := flag(0)
			var i := 0
			for f in s:
				if f == pf:
					continue
				var a := i * TAU / maxf(1.0, s.size() - 1.0) + PI / 2.0
				i += 1
				f.target = null
				f.has_move = true
				f.move_to = pf.pos + Vector2(cos(a), sin(a)) * 120.0
			say(L, "기함 주위로 집결한다.")
		"retreat":
			for f in s:
				var t := nearest_foe(f, 2000.0)
				f.target = null
				var a := atan2(f.pos.y - t.pos.y, f.pos.x - t.pos.x) if t else PI
				f.has_move = true
				f.move_to = Vector2(clampf(f.pos.x + cos(a) * 420.0, 60.0, WORLD.x - 60.0), clampf(f.pos.y + sin(a) * 420.0, 60.0, WORLD.y - 60.0))
			say(L, "전선을 물린다. 후퇴!")
	refresh_panel()

# 전 함대 일괄 이동: 선택 전체가 현재 배치를 유지한 채 목표 지점으로 이동
func order_move(w: Vector2) -> void:
	var s := my_sel()
	if s.is_empty():
		return
	var c := Vector2.ZERO
	for f in s:
		c += f.pos
	c /= s.size()
	for f in s:
		var o := f.pos - c
		# 여러 함대를 선택했으면 대형을 유지한 채 전 함대가 동시에 이동한다.
		f.target = null
		f.has_move = true
		f.move_to = Vector2(clampf(w.x + o.x, 40.0, WORLD.x - 40.0), clampf(w.y + o.y, 40.0, WORLD.y - 40.0))
	marker = {"pos": w, "t": 1.2, "foe": false}
	say(lead(), "전 함대 전진!" if s.size() > 1 else "항로 변경, 전진.")

func order_attack(t: Fleet) -> void:
	var s := my_sel()
	if s.is_empty():
		return
	for f in s:
		f.target = t
		f.has_move = false
	marker = {"pos": t.pos, "t": 1.2, "foe": true}
	say(lead(), "%s 함대를 친다!" % t.fname)

# ---- groups ----
var _group_press := {}
func _group_down(n: int) -> void:
	_group_press[n] = Time.get_ticks_msec()

func _group_up(n: int) -> void:
	var held := Time.get_ticks_msec() - int(_group_press.get(n, 0))
	if held >= 600:
		assign_group(n)
	else:
		select_group(n)

func group_fleets(n: int) -> Array[Fleet]:
	var out: Array[Fleet] = []
	for id in groups.get(n, []):
		var f := by_id(id)
		if f and not f.dead:
			out.append(f)
	return out

func same_sel(g: Array[Fleet]) -> bool:
	if g.size() != selected.size():
		return false
	for f in g:
		if not selected.has(f):
			return false
	return true

func select_group(n: int) -> void:
	if G.state != "play":
		return
	var g := group_fleets(n)
	if g.is_empty():
		toast("비어 있는 그룹입니다 · 길게 눌러 저장")
		return
	if same_sel(g):
		var c := Vector2.ZERO
		for f in g:
			c += f.pos
		cam_pos = c / g.size()
	selected = g
	inspect = null
	refresh_panel()

func assign_group(n: int) -> void:
	var s := my_sel()
	if s.is_empty():
		toast("저장할 함대를 먼저 선택하세요")
		return
	var ids := []
	for f in s:
		ids.append(f.id)
	groups[n] = ids
	toast("그룹 %s에 %d개 함대 저장" % [["I", "II", "III", "IV"][n - 1], ids.size()])

# ============================================================ panel
func chips_for(f: Fleet) -> String:
	var c: Array[String] = []
	if f.is_flag:
		c.append("[기함]")
	if f.defense:
		c.append("[방어진형]")
	if f.charge_t > 0.0:
		c.append("[돌격 %ds]" % ceili(f.charge_t))
	if not f.in_cmd:
		c.append("[지휘 범위 밖]")
	c.append("[미사일 %s]" % (("%ds" % ceili(f.missile_cd)) if f.missile_cd > 0.0 else "준비"))
	c.append("[함재기 %s]" % (("%ds" % ceili(f.fighter_cd)) if f.fighter_cd > 0.0 else "준비"))
	return " ".join(c)

func refresh_panel() -> void:
	if p_name == null:
		return
	var s := my_sel()
	var single: Fleet = null
	if s.size() == 1:
		single = s[0]
	elif s.is_empty() and inspect and not inspect.dead:
		single = inspect
	p_portrait.visible = single != null
	p_name.visible = single != null or s.size() > 1
	p_role.visible = p_name.visible
	p_ships.visible = p_name.visible
	p_bar.visible = p_name.visible
	p_chips.visible = single != null
	p_hint.visible = not p_name.visible
	if single:
		var foe := single.side == 1
		p_portrait.texture = _portrait_tex(single.portrait)
		p_name.text = "%s 함대" % single.fname
		p_role.text = single.role + (" · 적" if foe else "")
		p_ships.text = "Lv.%02d      %d / %d척" % [single.lv, ceili(single.ships), int(single.max_ships)]
		p_bar.value = single.ships / single.max_ships * 100.0
		p_bar.add_theme_stylebox_override("fill", _style(C_FOE if foe else C_LIFE, C_FOE if foe else C_LIFE, 2, 0))
		if foe:
			p_chips.text = ("[방어진형] " if single.defense else "") + ("[기함]" if single.is_flag else "")
		else:
			p_chips.text = chips_for(single)
		_shift_panel(108.0)
	elif s.size() > 1:
		var tot := 0.0
		var mx := 0.0
		var names: Array[String] = []
		for f in s:
			tot += f.ships
			mx += f.max_ships
			names.append(f.fname)
		p_name.text = "%d개 함대 선택" % s.size()
		p_role.text = " · ".join(names)
		p_ships.text = "%d / %d척" % [ceili(tot), int(mx)]
		p_bar.value = tot / mx * 100.0
		p_bar.add_theme_stylebox_override("fill", _style(C_LIFE, C_LIFE, 2, 0))
		_shift_panel(16.0)
	else:
		var a := alive(0)
		var e := alive(1)
		var at := 0.0
		var et := 0.0
		for f in a:
			at += f.ships
		for f in e:
			et += f.ships
		p_hint.text = "함대를 선택하세요.  아군 %d개 함대 · %d척\n적 %d개 함대 · %d척 확인" % [a.size(), ceili(at), e.size(), ceili(et)]
	_paint_groups()

func _shift_panel(x: float) -> void:
	for l in [p_name, p_role, p_ships, p_chips]:
		l.position.x = x
	p_bar.position.x = x
	p_bar.size.x = 548.0 - x
	for l in [p_name, p_role, p_ships, p_chips]:
		l.size.x = 548.0 - x

func _paint_groups() -> void:
	for i in 4:
		var g := group_fleets(i + 1)
		var b := group_btns[i]
		b.modulate = Color(1, 1, 1, 0.45 if g.is_empty() else (1.0 if same_sel(g) else 0.8))

func _paint_cmds() -> void:
	var s := my_sel()
	for c in CMDS:
		var b: Button = cmd_btns[c.id]
		var dis := false
		if c.id != "all" and s.is_empty():
			dis = true
		if c.cost > 0 and G.cp < c.cost:
			dis = true
		if c.id == "missile" and not s.is_empty():
			var m := 999.0
			for f in s:
				m = minf(m, f.missile_cd)
			if m > 0.0:
				dis = true
		if c.id == "fighter" and not s.is_empty():
			var m := 999.0
			for f in s:
				m = minf(m, f.fighter_cd)
			if m > 0.0:
				dis = true
		b.modulate = Color(0.55, 0.55, 0.55, 1.0) if dis else Color.WHITE
	for i in 10:
		cp_fills[i].size.x = 20.0 * clampf(G.cp - i, 0.0, 1.0)
	cp_num.text = str(int(G.cp))
	var t := int(G.t)
	clock_label.text = "%02d:%02d" % [t / 60, t % 60]

# ============================================================ input
func _hit_fleet(sp: Vector2) -> Fleet:
	var best: Fleet = null
	var bd := 1e9
	for f in fleets:
		if f.dead:
			continue
		var r := label_rect(f)
		if sp.x >= r.position.x - 4.0 and sp.x <= r.end.x + 4.0 and sp.y >= r.position.y - 4.0 and sp.y <= r.end.y + 4.0:
			return f
		var s := w2s(f.pos)
		var d := s.distance_to(sp)
		if d < maxf(28.0, 52.0 * cam_z) and d < bd:
			bd = d
			best = f
	return best

func _click_at(sp: Vector2, btn: int, shift: bool) -> void:
	var f := _hit_fleet(sp)
	if btn == MOUSE_BUTTON_LEFT and f and f.side == 0:
		if shift:
			if selected.has(f):
				selected.erase(f)
			else:
				selected.append(f)
		else:
			if selected.size() == 1 and selected[0] == f and Time.get_ticks_msec() - last_click < 400:
				cam_pos = f.pos
			selected = [f]
		inspect = null
		last_click = Time.get_ticks_msec()
		refresh_panel()
		return
	if f and f.side == 1:
		if not my_sel().is_empty():
			order_attack(f)
		else:
			inspect = f
			refresh_panel()
		return
	if f == null and not my_sel().is_empty():
		order_move(s2w(sp))
		return
	if f == null:
		inspect = null
		refresh_panel()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		_key(event)
		return
	if G.state != "play":
		return
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
				drag = {"s": event.position, "c": event.position, "btn": event.button_index, "moved": false, "mode": "", "shift": event.shift_pressed, "last": event.position}
			MOUSE_BUTTON_WHEEL_UP:
				_zoom(event.position, 1.12)
			MOUSE_BUTTON_WHEEL_DOWN:
				_zoom(event.position, 1.0 / 1.12)

func _input(event: InputEvent) -> void:
	if G.state != "play" or drag.is_empty():
		return
	if event is InputEventMouseMotion:
		drag.c = event.position
		if not drag.moved and (drag.c as Vector2).distance_to(drag.s) > 6.0:
			drag.moved = true
			drag.mode = "box" if drag.btn == MOUSE_BUTTON_LEFT else "pan"
		if drag.mode == "pan":
			var d: Vector2 = event.position - (drag.last as Vector2)
			cam_pos -= d / cam_z
			_clamp_cam()
		drag.last = event.position
	elif event is InputEventMouseButton and not event.pressed and event.button_index == drag.btn:
		if not drag.moved:
			_click_at(drag.s, drag.btn, drag.shift)
		elif drag.mode == "box":
			var r := Rect2(drag.s, Vector2.ZERO).expand(drag.c)
			var got: Array[Fleet] = []
			for f in alive(0):
				if r.has_point(w2s(f.pos)):
					got.append(f)
			if not got.is_empty():
				if drag.shift:
					for f in got:
						if not selected.has(f):
							selected.append(f)
				else:
					selected = got
				inspect = null
				refresh_panel()
		drag = {}

func _zoom(mp: Vector2, factor: float) -> void:
	var before := s2w(mp)
	cam_z *= factor
	_clamp_cam()
	_update_camera()
	var after := s2w(mp)
	cam_pos += before - after
	_clamp_cam()

func _key(e: InputEventKey) -> void:
	if e.keycode == KEY_SPACE:
		_toggle_menu()
		return
	if G.state != "play":
		return
	if e.keycode >= KEY_1 and e.keycode <= KEY_4:
		var n: int = e.keycode - KEY_0
		if e.ctrl_pressed or e.meta_pressed:
			assign_group(n)
		else:
			select_group(n)
		return
	if e.keycode == KEY_ESCAPE:
		selected.clear()
		inspect = null
		refresh_panel()
		return
	if e.ctrl_pressed or e.meta_pressed:
		return
	var key := OS.get_keycode_string(e.keycode)
	for c in CMDS:
		if c.key == key:
			do_cmd(c.id)
			return

# ============================================================ drawing
func label_rect(f: Fleet) -> Rect2:
	var s := w2s(f.pos)
	if cam_z < 0.55:
		return Rect2(s.x - 24.0, s.y - 34.0, 48.0, 10.0)
	return Rect2(s.x - 22.0, s.y - 58.0, 98.0, 34.0)

func _circle(c: Vector2, r: float, n := 48) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := TAU * i / n
		pts.append(w2s(c + Vector2(cos(a), sin(a)) * r))
	return pts

func _draw_fx() -> void:
	if G.is_empty() or G.state == "brief":
		return
	# 사격선
	for f in fleets:
		if f.dead or f.fire_t == null or f.fire_t.dead:
			continue
		var k := mini(4, 1 + int(f.ships / 40.0))
		for i in k:
			if randf() < 0.35:
				continue
			var a := w2s(rand_ship(f))
			var b := w2s(rand_ship(f.fire_t)) + Vector2(randf() - 0.5, randf() - 0.5) * 10.0
			var col := Color(1.0, (120.0 + randf() * 60.0) / 255.0, 80.0 / 255.0, 0.35 + randf() * 0.45) if f.side == 1 else Color((120.0 + randf() * 60.0) / 255.0, 240.0 / 255.0, 1.0, 0.35 + randf() * 0.45)
			fx.draw_line(a, b, col, 1.4)
			if randf() < 0.3:
				fx.draw_rect(Rect2(b - Vector2(1.5, 1.5), Vector2(3, 3)), Color(1, 0.94, 0.78, 0.8))
	# 함재기
	for s in swarms:
		var col := Color(1.0, 0.75, 0.55, 0.95) if s.side == 1 else Color(0.75, 0.94, 1.0, 0.95)
		for p in s.pts:
			var sp := w2s(p.pos)
			fx.draw_rect(Rect2(sp - Vector2(1.5, 1.5), Vector2(3, 3)), col)
		if not s.t.dead and randf() < 0.5:
			var p2: Dictionary = s.pts[randi() % s.pts.size()]
			fx.draw_line(w2s(p2.pos), w2s(rand_ship(s.t)), Color(col, 0.5), 1.0)
	# 미사일
	for m in missiles:
		var col := Color(1.0, 0.67, 0.43, 0.6) if m.side == 1 else Color(0.67, 0.82, 1.0, 0.6)
		var pts := PackedVector2Array()
		for p in m.trail:
			pts.append(w2s(p))
		if pts.size() > 1:
			fx.draw_polyline(pts, col, 1.8)
		var hp := w2s(m.pos)
		fx.draw_rect(Rect2(hp - Vector2(2, 2), Vector2(4, 4)), Color.WHITE)
	# 파편/폭발
	for p in parts:
		var a := p.life / p.maxl
		var sp := w2s(p.pos)
		if p.ring:
			fx.draw_arc(sp, p.size * (1.8 - a) * cam_z * 1.4, 0.0, TAU, 20, Color(1.0, 0.94, 0.82, a), 2.0)
		else:
			fx.draw_rect(Rect2(sp - Vector2(p.size, p.size) * 0.5, Vector2(p.size, p.size)), Color(p.col, minf(1.0, a * 1.5)))

func _draw_ui() -> void:
	if G.is_empty():
		return
	var font := ThemeDB.fallback_font
	# 지휘 범위
	var ef := flag(1)
	var pf := flag(0)
	if ef:
		var pts := _circle(ef.pos, CMD_R, 64)
		ui.draw_colored_polygon(pts, Color(1.0, 0.46, 0.31, 0.04))
		ui.draw_polyline(pts, Color(1.0, 0.46, 0.31, 0.2), 2.0)
	if pf:
		var pts := _circle(pf.pos, CMD_R, 64)
		ui.draw_colored_polygon(pts, Color(0.37, 0.88, 0.81, 0.06))
		ui.draw_polyline(pts, Color(0.37, 0.88, 0.81, 0.35), 2.0)
	# 명령선
	for f in selected:
		if f.target:
			ui.draw_dashed_line(w2s(f.pos), w2s(f.target.pos), Color(1.0, 0.46, 0.31, 0.5), 1.5, 8.0)
		elif f.has_move:
			ui.draw_dashed_line(w2s(f.pos), w2s(f.move_to), Color(0.37, 0.88, 0.81, 0.4), 1.5, 8.0)
	if selected.size() == 1:
		var f := selected[0]
		ui.draw_polyline(_circle(f.pos, f.range_r, 64), Color(0.37, 0.88, 0.81, 0.28), 1.0)
		ui.draw_polyline(_circle(f.pos, MISSILE_R, 64), Color(0.56, 0.71, 1.0, 0.22), 1.0)
	for f in selected:
		var pulse := 1.0 + sin(now_t * 3.8) * 0.04
		ui.draw_polyline(_circle(f.pos, 62.0 * pulse, 40), Color(0.37, 0.88, 0.81, 0.95), 2.4)
	if inspect and not inspect.dead:
		ui.draw_polyline(_circle(inspect.pos, 62.0, 40), Color(1.0, 0.46, 0.31, 0.85), 2.0)
	if not marker.is_empty():
		var k: float = marker.t / 1.2
		var col := Color(1.0, 0.46, 0.31, k) if marker.foe else Color(0.37, 0.88, 0.81, k)
		ui.draw_polyline(_circle(marker.pos, 26.0 + (1.0 - k) * 14.0, 32), col, 3.0)
	# 함대 라벨
	for f in fleets:
		if not f.dead and G.state != "brief":
			_draw_label(f, font)
	for t in floats:
		var sp := w2s(t.pos)
		var a := minf(1.0, t.t * 1.5)
		ui.draw_string_outline(font, sp + Vector2(-20.0, 0.0), t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, 3, Color(0, 0, 0, 0.7 * a))
		ui.draw_string(font, sp + Vector2(-20.0, 0.0), t.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(t.color, a))
	if not drag.is_empty() and drag.mode == "box":
		var r := Rect2(drag.s, Vector2.ZERO).expand(drag.c)
		ui.draw_rect(r, Color(0.37, 0.88, 0.81, 0.08))
		ui.draw_rect(r, Color(0.37, 0.88, 0.81, 0.8), false, 1.0)

func _draw_label(f: Fleet, font: Font) -> void:
	var r := label_rect(f)
	var sel := selected.has(f) or inspect == f
	var foe := f.side == 1
	var bar_col := C_FOE if foe else C_LIFE
	var frac := f.ships / f.max_ships
	if cam_z < 0.55:
		ui.draw_rect(r, Color(0.02, 0.05, 0.04, 0.85))
		ui.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2((r.size.x - 4.0) * frac, r.size.y - 4.0)), bar_col)
		if sel:
			ui.draw_rect(r.grow(0.5), C_ALLY, false, 1.5)
	else:
		ui.draw_rect(r, Color(0.13, 0.04, 0.03, 0.82) if foe else Color(0.02, 0.08, 0.07, 0.82))
		ui.draw_rect(r, C_ALLY if sel else (Color(1.0, 0.46, 0.31, 0.55) if foe else Color(0.37, 0.88, 0.81, 0.45)), false, 2.0 if sel else 1.0)
		ui.draw_texture_rect(_portrait_tex(f.portrait), Rect2(r.position + Vector2(2, 2), Vector2(30, 30)), false)
		if f.is_flag:
			ui.draw_string(font, r.position + Vector2(3, 12), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, C_GOLD)
		ui.draw_string(font, r.position + Vector2(36, 13), "Lv.%02d" % f.lv, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("e8f1ec"))
		var gx := r.end.x - 6.0
		var glyphs: Array = []
		if f.defense:
			glyphs.append(["DEF", C_ALLY])
		if f.charge_t > 0.0:
			glyphs.append(["ATK", C_GOLD])
		if not f.in_cmd:
			glyphs.append(["!", C_FOE])
		for g in glyphs:
			var w := font.get_string_size(g[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
			ui.draw_string(font, Vector2(gx - w, r.position.y + 12.0), g[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, g[1])
			gx -= w + 4.0
		ui.draw_rect(Rect2(r.position + Vector2(36, 17), Vector2(58, 6)), Color("07100d"))
		ui.draw_rect(Rect2(r.position + Vector2(37, 18), Vector2(56.0 * frac, 4)), bar_col)
		ui.draw_rect(Rect2(r.position + Vector2(36, 26), Vector2(58, 4)), Color("07100d"))
		ui.draw_rect(Rect2(r.position + Vector2(37, 27), Vector2(56.0 * (1.0 - f.missile_cd / 18.0), 2)), Color("3b5a8a") if f.missile_cd > 0.0 else Color("8fb6ff"))
	if f.speech_t > 0.0 and f.speech != "":
		var w := font.get_string_size(f.speech, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 14.0
		var bx := r.position.x - 2.0
		var by := r.position.y - 24.0
		ui.draw_rect(Rect2(bx, by, w, 19), Color(0.96, 0.97, 0.96, 0.95))
		ui.draw_colored_polygon(PackedVector2Array([Vector2(bx + 10, by + 19), Vector2(bx + 16, by + 19), Vector2(bx + 10, by + 25)]), Color(0.96, 0.97, 0.96, 0.95))
		ui.draw_string(font, Vector2(bx + 7, by + 14), f.speech, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("10201c"))

# ---- radar ----
const RS := 128.0
func _rsc() -> float:
	return RS * 0.92 / WORLD.length()

func _w2r(p: Vector2) -> Vector2:
	return (p - WORLD * 0.5) * _rsc() + Vector2(RS, RS) * 0.5

func _r2w(p: Vector2) -> Vector2:
	return (p - Vector2(RS, RS) * 0.5) / _rsc() + WORLD * 0.5

func _draw_radar() -> void:
	if G.is_empty():
		return
	var c := Vector2(RS, RS) * 0.5
	radar.draw_circle(c, RS * 0.5, Color("0a2038"))
	var a := _w2r(Vector2.ZERO)
	var b := _w2r(WORLD)
	radar.draw_rect(Rect2(a, b - a), Color(0.24, 0.47, 0.78, 0.2))
	for i in range(1, 4):
		radar.draw_arc(c, i * RS / 8.0, 0.0, TAU, 32, Color(0.47, 0.71, 1.0, 0.18), 1.0)
	var sweep := now_t / 1.4
	radar.draw_line(c, c + Vector2(cos(sweep), sin(sweep)) * RS * 0.5, Color(0.47, 0.78, 1.0, 0.4), 1.5)
	var pf := flag(0)
	if pf:
		radar.draw_arc(_w2r(pf.pos), CMD_R * _rsc(), 0.0, TAU, 32, Color(0.37, 0.88, 0.81, 0.5), 1.0)
	for f in fleets:
		if f.dead:
			continue
		var p := _w2r(f.pos)
		var col := C_FOE if f.side == 1 else (Color.WHITE if selected.has(f) else C_ALLY)
		var sz := 5.0 if f.is_flag else 3.5
		radar.draw_rect(Rect2(p - Vector2(sz, sz) * 0.5, Vector2(sz, sz)), col)
	var tl := _w2r(s2w(Vector2.ZERO))
	var br := _w2r(s2w(vsize))
	radar.draw_rect(Rect2(tl, br - tl), Color(0.47, 1.0, 0.59, 0.85), false, 1.2)

func _radar_input(e: InputEvent) -> void:
	if G.state == "brief":
		return
	if (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT) or (e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0):
		cam_pos = _r2w(e.position)
		_clamp_cam()
