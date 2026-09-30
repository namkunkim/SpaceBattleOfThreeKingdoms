extends Node3D

const MODEL_ROOT := "res://assets/models/user_ver3_runtime/"
const MODEL_NAMES := ["전열함", "화력함", "공성함", "보급_수리함", "전자전함", "호위함", "항모"]
const MODEL_LABELS := ["전열함", "화력함", "공성함", "보급/수리함", "전자전함", "요격함", "강습항모"]
const MODEL_SCALES := [1.10, 1.60, 1.55, 1.45, 1.50, 0.90, 1.55]
const SHIP_VISUAL_SCALE := 1.0 / 3.0
const MODEL_TEXTURES := [
	["Imperial_Orange.png", "Imperial_Red.png"],
	["Executioner_Blue.png", "Executioner_Blue.png"],
	["Insurgent_Blue.png", "Insurgent_Red.png"],
	["Omen_Orange.png", "Omen_Orange.png"],
	["Pancake_Orange.png", "Pancake_Orange.png"],
	["Dispatcher_Purple.png", "Dispatcher_Purple.png"],
	["Challenger_Green.png", "Challenger_Green.png"],
]

var model_scenes: Array[PackedScene] = []
var fleets: Array[Dictionary] = []
var selected_fleet := 0
var battle_time := 0.0
var salvo_clock := 0.1
var selection_ring: MeshInstance3D
var status_label: Label
var target_label: Label
var tactical_label: Label
var camera: Camera3D
var selection_dome: MeshInstance3D
var fleet_tags: Array[Control] = []

func _ready() -> void:
	_load_models()
	_build_environment()
	_build_nebula_plane()
	_build_stars()
	_build_tactical_grid()
	_build_fleets()
	_build_selection_ring()
	_build_hud()
	_update_selection()

func _process(delta: float) -> void:
	battle_time += delta
	salvo_clock -= delta
	_animate_fleets(delta)
	if salvo_clock <= 0.0:
		salvo_clock = 0.66
		_fire_salvo(randi_range(0, 2), randi_range(3, 5))
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed:
		return
	match event.keycode:
		KEY_ESCAPE:
			get_tree().quit()
		KEY_TAB:
			selected_fleet = (selected_fleet + 1) % 3
			_update_selection()
		KEY_1, KEY_2, KEY_3:
			selected_fleet = int(event.keycode - KEY_1)
			_update_selection()
		KEY_W:
			_move_selected(Vector3(0.0, 0.0, -2.5))
		KEY_S:
			_move_selected(Vector3(0.0, 0.0, 2.5))
		KEY_A:
			_move_selected(Vector3(-2.5, 0.0, 0.0))
		KEY_D:
			_move_selected(Vector3(2.5, 0.0, 0.0))
		KEY_Q:
			_rotate_selected(-0.12)
		KEY_E:
			_rotate_selected(0.12)
		KEY_SPACE:
			_fire_salvo(selected_fleet, 3 + selected_fleet)

func _load_models() -> void:
	for model_name in MODEL_NAMES:
		var path: String = MODEL_ROOT + model_name + ".glb"
		var packed := load(path) as PackedScene
		assert(packed != null, "3D 함선 모델 로드 실패: %s" % path)
		model_scenes.append(packed)

func _build_environment() -> void:
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("02060f")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("355987")
	environment.ambient_light_energy = 0.22
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = environment
	add_child(world)

	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-56.0, -24.0, 0.0)
	key_light.light_color = Color("b9d8ff")
	key_light.light_energy = 0.76
	key_light.shadow_enabled = true
	add_child(key_light)

	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(48.0, 152.0, 0.0)
	rim.light_color = Color("4aa7ff")
	rim.light_energy = 0.42
	add_child(rim)

	camera = Camera3D.new()
	camera.fov = 48.0
	add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 61.0, 29.0), Vector3(0.0, 0.0, 0.0), Vector3.UP)
	camera.current = true

func _build_stars() -> void:
	var stars := MultiMeshInstance3D.new()
	var multimesh := MultiMesh.new()
	var dot := SphereMesh.new()
	dot.radius = 0.055
	dot.height = 0.11
	dot.radial_segments = 4
	dot.rings = 2
	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.albedo_color = Color("bbdcff")
	star_material.emission_enabled = true
	star_material.emission = Color("6caaff")
	star_material.emission_energy_multiplier = 1.8
	dot.material = star_material
	multimesh.mesh = dot
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.instance_count = 520
	var random := RandomNumberGenerator.new()
	random.seed = 7007
	for index in multimesh.instance_count:
		var transform := Transform3D.IDENTITY
		transform.origin = Vector3(random.randf_range(-90.0, 90.0), random.randf_range(-14.0, -8.0), random.randf_range(-95.0, 85.0))
		var scale := random.randf_range(0.45, 1.8)
		transform.basis = transform.basis.scaled(Vector3.ONE * scale)
		multimesh.set_instance_transform(index, transform)
	stars.multimesh = multimesh
	add_child(stars)

func _build_nebula_plane() -> void:
	var backdrop := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(150.0, 132.0)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = load("res://assets/backgrounds/red_cliffs_starfield_v1.png") as Texture2D
	material.albedo_color = Color(0.58, 0.70, 0.78, 1.0)
	plane.material = material
	backdrop.mesh = plane
	backdrop.position.y = -5.2
	add_child(backdrop)

func _build_tactical_grid() -> void:
	var grid_material := _unshaded_material(Color(0.08, 0.34, 0.48, 0.24), true)
	for coordinate in range(-50, 51, 5):
		_add_box(Vector3(float(coordinate), -4.0, 0.0), Vector3(0.025, 0.018, 104.0), grid_material)
		_add_box(Vector3(0.0, -4.0, float(coordinate)), Vector3(104.0, 0.018, 0.025), grid_material)
	var frontline := _unshaded_material(Color(0.18, 0.72, 1.0, 0.52), true)
	_add_box(Vector3(0.0, -3.92, 0.0), Vector3(68.0, 0.035, 0.08), frontline)

func _build_fleets() -> void:
	var definitions := [
		{"id": "I", "name": "제1 중앙함대", "team": 0, "origin": Vector3(-18.0, 0.0, 11.0), "heading": 0.0, "formation": "횡진"},
		{"id": "II", "name": "제2 좌익함대", "team": 0, "origin": Vector3(0.0, 1.0, 16.0), "heading": 0.0, "formation": "쐐기진"},
		{"id": "III", "name": "제3 우익함대", "team": 0, "origin": Vector3(19.0, -0.5, 12.0), "heading": 0.0, "formation": "방진"},
		{"id": "A", "name": "적 중앙전단", "team": 1, "origin": Vector3(-16.0, 0.5, -10.0), "heading": PI, "formation": "종진"},
		{"id": "B", "name": "적 돌격전단", "team": 1, "origin": Vector3(2.0, -0.5, -15.0), "heading": PI, "formation": "쐐기진"},
		{"id": "C", "name": "적 지원전단", "team": 1, "origin": Vector3(21.0, 0.0, -9.0), "heading": PI, "formation": "횡진"},
	]
	for definition in definitions:
		var fleet_root := Node3D.new()
		fleet_root.name = definition.name
		fleet_root.position = definition.origin
		fleet_root.rotation.y = definition.heading
		add_child(fleet_root)
		var fleet: Dictionary = definition.duplicate()
		fleet.root = fleet_root
		fleet.nodes = []
		fleet.integrity = 1.0
		fleet.shield = 1.0
		_build_fleet_units(fleet)
		fleets.append(fleet)

func _build_fleet_units(fleet: Dictionary) -> void:
	# 대형함 6개 함급을 전열 중심으로 반복하고, 요격함은 외곽 호위대만 구성한다.
	var base_roster := [0, 1, 6, 2, 4, 3, 0, 1, 6, 2, 4, 3, 5, 5, 5, 5, 5]
	var roster := base_roster + base_roster
	for index in roster.size():
		var model_index: int = roster[index]
		var wrapper := Node3D.new()
		wrapper.name = "%s-%02d-%s" % [fleet.id, index + 1, MODEL_LABELS[model_index]]
		wrapper.position = _formation_position(index, roster.size(), fleet.formation)
		wrapper.scale = Vector3.ONE * SHIP_VISUAL_SCALE
		fleet.root.add_child(wrapper)
		var model := model_scenes[model_index].instantiate() as Node3D
		var hierarchy_scale := 1.0 if index == 0 else (0.92 if model_index < 5 else 1.0)
		model.scale = Vector3.ONE * MODEL_SCALES[model_index] * hierarchy_scale
		# ver3 모델의 선수 -X를 전투 로컬 전방 -Z로 맞춘다.
		model.rotation.y = -PI * 0.5
		wrapper.add_child(model)
		_apply_ship_material(model, model_index, fleet.team)
		_add_engine_glow(wrapper, model_index, fleet.team, hierarchy_scale)
		if index == 0:
			_add_flagship_beacon(wrapper, fleet.team)
		fleet.nodes.append(wrapper)

func _formation_position(index: int, count: int, formation: String) -> Vector3:
	if index == 0:
		return Vector3.ZERO
	var slot := index - 1
	match formation:
		"쐐기진":
			var rank := int(slot / 4.0) + 1
			var lane := slot % 4
			var lane_offset := (float(lane) - 1.5) * 1.22
			var wing_bias := signf(lane_offset) * rank * 0.34
			return Vector3(lane_offset + wing_bias, -0.07 * rank, rank * 1.35)
		"종진":
			var column := slot % 3
			var row := int(slot / 3.0) + 1
			return Vector3((column - 1) * 1.25, -0.06 * row, row * 1.18)
		"방진":
			var column := slot % 6
			var row := int(slot / 6.0) + 1
			return Vector3((column - 2.5) * 1.18, -0.06 * row, row * 1.22)
		_:
			var column := slot % 8
			var row := int(slot / 8.0) + 1
			return Vector3((column - 3.5) * 1.16, -0.06 * row, row * 1.25)

func _add_engine_glow(wrapper: Node3D, model_index: int, team: int, hierarchy_scale: float) -> void:
	var color := Color("39d7ff") if team == 0 else Color("ff714a")
	var engine_material := _unshaded_material(color, false)
	engine_material.emission_enabled = true
	engine_material.emission = color
	engine_material.emission_energy_multiplier = 5.0
	var scale: float = MODEL_SCALES[model_index] * hierarchy_scale
	var aft: float = 6.5 * scale
	for x in [-0.62, 0.62]:
		var glow := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.18 if model_index < 5 else 0.10
		sphere.height = sphere.radius * 2.0
		sphere.radial_segments = 10
		sphere.rings = 5
		sphere.material = engine_material
		glow.mesh = sphere
		glow.position = Vector3(x * scale, 0.0, aft)
		wrapper.add_child(glow)
	var trail := MeshInstance3D.new()
	var trail_mesh := BoxMesh.new()
	var trail_length := 3.8 if model_index < 5 else 2.2
	trail_mesh.size = Vector3(0.10 if model_index < 5 else 0.055, 0.07, trail_length)
	var trail_color := Color(0.20, 0.78, 1.0, 0.54) if team == 0 else Color(1.0, 0.35, 0.22, 0.42)
	var trail_material := _unshaded_material(trail_color, true)
	trail_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	trail_material.emission_enabled = true
	trail_material.emission = trail_color
	trail_material.emission_energy_multiplier = 3.8
	trail_mesh.material = trail_material
	trail.mesh = trail_mesh
	trail.position = Vector3(0.0, 0.0, aft + trail_length * 0.5)
	wrapper.add_child(trail)

func _apply_ship_material(model: Node, model_index: int, team: int) -> void:
	# 사용자 ver3 GLB의 내장 PBR 재질을 그대로 보존한다.
	pass

func _add_flagship_beacon(wrapper: Node3D, team: int) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color("45cfff") if team == 0 else Color("ff634c")
	light.light_energy = 2.2
	light.omni_range = 5.5
	light.position = Vector3(0.0, 2.0, 0.0)
	wrapper.add_child(light)

func _build_selection_ring() -> void:
	selection_ring = MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 5.2
	torus.outer_radius = 5.35
	torus.rings = 48
	torus.ring_segments = 8
	var material := _unshaded_material(Color(0.18, 0.88, 1.0, 0.92), true)
	material.emission_enabled = true
	material.emission = Color("28cfff")
	material.emission_energy_multiplier = 2.6
	torus.material = material
	selection_ring.mesh = torus
	selection_ring.rotation_degrees.x = 90.0
	add_child(selection_ring)

	selection_dome = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 7.3
	sphere.height = 14.6
	sphere.radial_segments = 48
	sphere.rings = 20
	var dome_material := _unshaded_material(Color(0.08, 0.74, 0.92, 0.085), true)
	dome_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	dome_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	dome_material.emission_enabled = true
	dome_material.emission = Color("087c9c")
	dome_material.emission_energy_multiplier = 0.55
	sphere.material = dome_material
	selection_dome.mesh = sphere
	selection_dome.scale = Vector3(1.30, 0.20, 1.08)
	add_child(selection_dome)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	_build_radar(canvas)

	var top_bar := Panel.new()
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_bar.custom_minimum_size.y = 64.0
	top_bar.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.04, 0.075, 0.94), Color("2477a3")))
	canvas.add_child(top_bar)

	var title := Label.new()
	title.text = "성한지 · 우주함대 3D 전투 POC"
	title.position = Vector2(24.0, 12.0)
	title.add_theme_font_size_override("font_size", 25)
	title.add_theme_color_override("font_color", Color("d9efff"))
	top_bar.add_child(title)

	status_label = Label.new()
	status_label.position = Vector2(520.0, 17.0)
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color("58d9ff"))
	top_bar.add_child(status_label)

	var command_panel := Panel.new()
	command_panel.position = Vector2(266.0, 690.0)
	command_panel.size = Vector2(680.0, 182.0)
	command_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.018, 0.05, 0.09, 0.94), Color("238dc2")))
	canvas.add_child(command_panel)

	var portrait := TextureRect.new()
	portrait.position = Vector2(16.0, 18.0)
	portrait.size = Vector2(112.0, 142.0)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var portrait_atlas := AtlasTexture.new()
	portrait_atlas.atlas = load("res://assets/portraits/commanders_sheet_v1.png") as Texture2D
	portrait_atlas.region = Rect2(0.0, 0.0, 512.0, 512.0)
	portrait.texture = portrait_atlas
	command_panel.add_child(portrait)

	tactical_label = Label.new()
	tactical_label.position = Vector2(150.0, 18.0)
	tactical_label.size = Vector2(500.0, 94.0)
	tactical_label.add_theme_font_size_override("font_size", 20)
	tactical_label.add_theme_color_override("font_color", Color("e6f5ff"))
	command_panel.add_child(tactical_label)

	var help := Label.new()
	help.text = "[1–3/TAB] 함대 선택   [WASD] 이동   [Q/E] 선회   [SPACE] 일제사격"
	help.position = Vector2(150.0, 128.0)
	help.add_theme_font_size_override("font_size", 15)
	help.add_theme_color_override("font_color", Color("7ed7ff"))
	command_panel.add_child(help)

	var target_panel := Panel.new()
	target_panel.position = Vector2(1218.0, 690.0)
	target_panel.size = Vector2(358.0, 182.0)
	target_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.025, 0.035, 0.94), Color("b43d45")))
	canvas.add_child(target_panel)
	target_label = Label.new()
	target_label.position = Vector2(18.0, 18.0)
	target_label.size = Vector2(322.0, 146.0)
	target_label.add_theme_font_size_override("font_size", 18)
	target_label.add_theme_color_override("font_color", Color("ffd8d5"))
	target_panel.add_child(target_label)
	_build_command_buttons(canvas)
	_build_fleet_tags(canvas)

	var badge := Label.new()
	badge.text = "REAL 3D · 204 SHIPS"
	badge.position = Vector2(1320.0, 82.0)
	badge.add_theme_font_size_override("font_size", 16)
	badge.add_theme_color_override("font_color", Color("74dcff"))
	canvas.add_child(badge)

func _build_radar(canvas: CanvasLayer) -> void:
	var radar_panel := Panel.new()
	radar_panel.position = Vector2(18.0, 666.0)
	radar_panel.size = Vector2(230.0, 220.0)
	radar_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.035, 0.065, 0.96), Color("238dc2")))
	canvas.add_child(radar_panel)
	var radar := Control.new()
	radar.set_script(load("res://scripts/RadarControl.gd"))
	radar.size = radar_panel.size
	radar_panel.add_child(radar)
	var label := Label.new()
	label.text = "TACTICAL RADAR"
	label.position = Vector2(54.0, 194.0)
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color("65dfff"))
	radar_panel.add_child(label)

func _build_command_buttons(canvas: CanvasLayer) -> void:
	var panel := Panel.new()
	panel.position = Vector2(966.0, 690.0)
	panel.size = Vector2(234.0, 182.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.015, 0.045, 0.08, 0.95), Color("2477a3")))
	canvas.add_child(panel)
	var commands := ["이동", "선회", "일제", "요격", "쐐기", "방진", "지원", "정지"]
	for index in commands.size():
		var button := Panel.new()
		button.position = Vector2(12.0 + (index % 4) * 54.0, 16.0 + int(index / 4.0) * 76.0)
		button.size = Vector2(46.0, 62.0)
		var accent := Color("178fc5") if index != 2 else Color("d09124")
		button.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.09, 0.15, 0.95), accent))
		panel.add_child(button)
		var icon := Label.new()
		icon.text = ["➤", "↻", "✦", "◎", "▽", "▦", "+", "Ⅱ"][index]
		icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.position = Vector2(0.0, 5.0)
		icon.size = Vector2(46.0, 28.0)
		icon.add_theme_font_size_override("font_size", 22)
		icon.add_theme_color_override("font_color", Color("69dcff") if index != 2 else Color("ffd56a"))
		button.add_child(icon)
		var text_label := Label.new()
		text_label.text = commands[index]
		text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_label.position = Vector2(0.0, 38.0)
		text_label.size = Vector2(46.0, 20.0)
		text_label.add_theme_font_size_override("font_size", 11)
		button.add_child(text_label)

func _build_fleet_tags(canvas: CanvasLayer) -> void:
	for fleet in fleets:
		var tag := Panel.new()
		tag.size = Vector2(122.0, 43.0)
		var team_color := Color("22bfe8") if fleet.team == 0 else Color("df554b")
		tag.add_theme_stylebox_override("panel", _panel_style(Color(0.01, 0.035, 0.055, 0.88), team_color))
		canvas.add_child(tag)
		var title := Label.new()
		title.name = "Title"
		title.text = "◆ %s  %s" % [fleet.id, fleet.name]
		title.position = Vector2(6.0, 3.0)
		title.size = Vector2(112.0, 18.0)
		title.add_theme_font_size_override("font_size", 11)
		title.add_theme_color_override("font_color", team_color.lightened(0.28))
		tag.add_child(title)
		var shield_bar := ProgressBar.new()
		shield_bar.name = "Shield"
		shield_bar.position = Vector2(6.0, 23.0)
		shield_bar.size = Vector2(69.0, 6.0)
		shield_bar.show_percentage = false
		shield_bar.value = 100.0
		shield_bar.add_theme_stylebox_override("background", _bar_style(Color("06131d")))
		shield_bar.add_theme_stylebox_override("fill", _bar_style(Color("158bd0") if fleet.team == 0 else Color("bf4338")))
		tag.add_child(shield_bar)
		var hull_bar := ProgressBar.new()
		hull_bar.name = "Hull"
		hull_bar.position = Vector2(6.0, 32.0)
		hull_bar.size = Vector2(104.0, 6.0)
		hull_bar.show_percentage = false
		hull_bar.value = 100.0
		hull_bar.add_theme_stylebox_override("background", _bar_style(Color("06131d")))
		hull_bar.add_theme_stylebox_override("fill", _bar_style(Color("3dd36d")))
		tag.add_child(hull_bar)
		fleet_tags.append(tag)

func _update_hud() -> void:
	if fleets.is_empty():
		return
	var selected: Dictionary = fleets[selected_fleet]
	var hostile: Dictionary = fleets[3 + selected_fleet]
	status_label.text = "TACTICAL LINK  %05.1f   |   교전 거리 %02.1f" % [battle_time, selected.root.global_position.distance_to(hostile.root.global_position)]
	tactical_label.text = "%s  /  %s\n편제 %d척 · 방어막 %d%% · 함체 %d%%\n지시: 적 전단을 향해 전진, 화력함 사격 준비" % [selected.id, selected.name, selected.nodes.size(), int(selected.shield * 100.0), int(selected.integrity * 100.0)]
	target_label.text = "TARGET LOCK\n%s  /  %s\n방어막 %d%%\n거리 %.1f · 위협도 HIGH" % [hostile.id, hostile.name, int(hostile.shield * 100.0), selected.root.global_position.distance_to(hostile.root.global_position)]
	for index in min(fleets.size(), fleet_tags.size()):
		var fleet: Dictionary = fleets[index]
		var tag := fleet_tags[index]
		var screen_position := camera.unproject_position(fleet.root.global_position + Vector3(0.0, 3.0, 0.0))
		tag.position = screen_position + Vector2(-61.0, -57.0)
		(tag.get_node("Shield") as ProgressBar).value = fleet.shield * 100.0
		(tag.get_node("Hull") as ProgressBar).value = fleet.integrity * 100.0

func _update_selection() -> void:
	if fleets.is_empty():
		return
	selection_ring.position = fleets[selected_fleet].root.position + Vector3(0.0, -2.8, 0.0)
	selection_dome.position = fleets[selected_fleet].root.position + Vector3(0.0, -1.3, 0.0)

func _move_selected(offset: Vector3) -> void:
	var root: Node3D = fleets[selected_fleet].root
	root.position += offset
	_update_selection()

func _rotate_selected(amount: float) -> void:
	var root: Node3D = fleets[selected_fleet].root
	root.rotation.y += amount

func _animate_fleets(delta: float) -> void:
	for fleet_index in fleets.size():
		var fleet: Dictionary = fleets[fleet_index]
		var root: Node3D = fleet.root
		root.position.y = sin(battle_time * 0.55 + fleet_index) * 0.20
		for ship_index in min(5, fleet.nodes.size()):
			var ship: Node3D = fleet.nodes[ship_index]
			ship.rotation.z = sin(battle_time * 0.7 + ship_index * 0.8) * 0.018
	selection_ring.rotation.y += delta * 0.42
	selection_dome.scale.y = 0.20 + sin(battle_time * 1.8) * 0.010

func _fire_salvo(source_index: int, target_index: int) -> void:
	if source_index >= fleets.size() or target_index >= fleets.size():
		return
	var source: Dictionary = fleets[source_index]
	var target: Dictionary = fleets[target_index]
	var beam_color := Color("42ddff") if source.team == 0 else Color("ff594b")
	for shot in 8:
		var from_ship: Node3D = source.nodes[(shot * 3) % source.nodes.size()]
		var to_ship: Node3D = target.nodes[(shot * 5 + 2) % target.nodes.size()]
		var jitter := Vector3(randf_range(-0.8, 0.8), randf_range(-0.5, 0.5), randf_range(-0.8, 0.8))
		_add_beam(from_ship.global_position, to_ship.global_position + jitter, beam_color)
	if randf() > 0.34:
		_add_explosion(target.root.global_position + Vector3(randf_range(-5.0, 5.0), randf_range(-1.0, 1.0), randf_range(-4.0, 4.0)), beam_color)
	target.shield = maxf(0.0, target.shield - 0.025)
	if target.shield <= 0.0:
		target.integrity = maxf(0.0, target.integrity - 0.01)

func _add_beam(start: Vector3, finish: Vector3, color: Color) -> void:
	var beam := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.06, start.distance_to(finish))
	var beam_color := color.lightened(0.32)
	var material := _unshaded_material(beam_color, true)
	material.emission_enabled = true
	material.emission = beam_color
	material.emission_energy_multiplier = 7.0
	box.material = material
	beam.mesh = box
	add_child(beam)
	beam.look_at_from_position((start + finish) * 0.5, finish, Vector3.UP)
	var tween := create_tween()
	tween.tween_interval(0.46)
	tween.tween_property(material, "albedo_color", Color(beam_color, 0.0), 0.38)
	tween.tween_callback(beam.queue_free)

func _add_explosion(at: Vector3, color: Color) -> void:
	var flash := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	var material := _unshaded_material(Color("fff1b0"), true)
	material.emission_enabled = true
	material.emission = color.lerp(Color.WHITE, 0.72)
	material.emission_energy_multiplier = 6.0
	sphere.material = material
	flash.mesh = sphere
	flash.position = at
	add_child(flash)
	var light := OmniLight3D.new()
	light.light_color = color.lerp(Color.WHITE, 0.5)
	light.light_energy = 5.0
	light.omni_range = 9.0
	flash.add_child(light)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector3.ONE * 5.5, 0.46).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color", Color(color, 0.0), 0.46)
	tween.chain().tween_callback(flash.queue_free)
	_add_shockwave(at, color)
	_add_sparks(at, color)

func _add_shockwave(at: Vector3, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.58
	torus.rings = 32
	torus.ring_segments = 8
	var material := _unshaded_material(Color(color.lightened(0.45), 0.92), true)
	material.emission_enabled = true
	material.emission = color.lightened(0.35)
	material.emission_energy_multiplier = 4.5
	torus.material = material
	ring.mesh = torus
	ring.position = at
	ring.rotation_degrees.x = 90.0
	add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3.ONE * 7.0, 0.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color", Color(color, 0.0), 0.60)
	tween.chain().tween_callback(ring.queue_free)

func _add_sparks(at: Vector3, color: Color) -> void:
	for index in 9:
		var spark := MeshInstance3D.new()
		var shard := BoxMesh.new()
		shard.size = Vector3(0.08, 0.08, randf_range(0.32, 0.75))
		var material := _unshaded_material(color.lightened(0.42), false)
		material.emission_enabled = true
		material.emission = color.lightened(0.32)
		material.emission_energy_multiplier = 4.0
		shard.material = material
		spark.mesh = shard
		spark.position = at
		spark.rotation = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
		add_child(spark)
		var direction := Vector3(randf_range(-1.0, 1.0), randf_range(-0.32, 0.55), randf_range(-1.0, 1.0)).normalized()
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "position", at + direction * randf_range(2.2, 5.2), 0.58).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector3.ZERO, 0.58)
		tween.chain().tween_callback(spark.queue_free)

func _add_box(position: Vector3, size: Vector3, material: Material) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	box.material = material
	mesh_instance.mesh = box
	mesh_instance.position = position
	add_child(mesh_instance)

func _unshaded_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	if transparent:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material

func _panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	return style

func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2
	return style
