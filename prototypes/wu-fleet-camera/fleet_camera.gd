extends Node3D

const DURATION := 120.0
const SPEED := 18.0
const FLEET_FOCUS := Vector3(-7.0, 0.0, 0.0)
const STRATEGIC_CENTER := Vector3(1080.0, 0.0, -900.0)
const PATHS := [
	"res://models/final/changjiang-hydro.glb",
	"res://models/final/assault-carrier.glb",
	"res://models/final/artillery-dreadnought.glb",
	"res://models/final/supply-repair.glb",
	"res://models/final/siege-ship.glb",
	"res://models/final/interceptor.glb",
	"res://models/final/electronic-warfare.glb",
	"res://models/final/fast-attack.glb",
]
const COLORS := [
	Color("#61e3f1"), Color("#ffd391"), Color("#fd947c"), Color("#a6aef3"),
	Color("#edb7ef"), Color("#a8fbd6"), Color("#dac894"), Color("#fdf7e5"),
]
const LENGTHS := [0.75, 1.30, 0.90, 0.80, 1.05, 0.48, 0.40, 0.18]
const STAGES := [
	[0.0, "Strategy map"], [10.0, "2.5D transition"], [20.0, "Tactical view"],
	[35.0, "Fleet tracking"], [45.0, "Battleship approach"],
	[55.0, "Bow"], [63.0, "Port"], [72.0, "Dorsal"], [82.0, "Starboard"],
	[91.0, "Ventral"], [100.0, "Stern"], [105.0, "Return to strategy map"],
]
# Time, azimuth, elevation, vertical span at the focus, perspective strength,
# and the focus blend from the fleet center to the lead battleship.
const SHOTS := [
	[0.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
	[10.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
	[17.0, 101.0, 60.0, 55.0, 0.15, 0.0],
	[20.0, 105.0, 60.0, 39.0, 0.15, 0.0],
	[29.0, 114.0, 30.0, 15.0, 0.33, 0.0],
	[32.0, 114.0, 30.0, 15.0, 0.33, 0.0],
	[35.0, 113.0, 19.0, 14.0, 0.35, 0.0],
	[45.0, 105.0, 13.0, 12.5, 0.40, 0.28],
	[48.0, 39.0, 9.0, 3.7, 0.36, 0.94],
	[50.0, 28.0, 7.0, 2.85, 0.34, 0.98],
	[52.0, 16.0, 5.0, 1.75, 0.30, 1.0],
	[55.0, 0.0, 0.0, 0.62, 0.23, 1.0],
	[57.0, 0.0, 0.0, 0.62, 0.23, 1.0],
	[63.0, 90.0, 0.0, 0.92, 0.24, 1.0],
	[65.0, 90.0, 0.0, 0.92, 0.24, 1.0],
	[72.0, 90.0, 90.0, 0.92, 0.24, 1.0],
	[74.0, 90.0, 90.0, 0.92, 0.24, 1.0],
	[82.0, 270.0, 0.0, 0.92, 0.24, 1.0],
	[84.0, 270.0, 0.0, 0.92, 0.24, 1.0],
	[91.0, 270.0, -90.0, 0.92, 0.24, 1.0],
	[93.0, 270.0, -90.0, 0.92, 0.24, 1.0],
	[100.0, 180.0, 0.0, 0.62, 0.23, 1.0],
	[105.0, 180.0, 0.0, 0.62, 0.23, 1.0],
	[109.0, 120.0, 7.0, 5.0, 0.32, 1.0],
	[113.0, 90.0, 28.0, 38.0, 0.32, 0.0],
	[116.0, 90.0, 60.0, 550.0, 0.14, 0.0],
	[119.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
	[120.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
]

class StrategyOverlay extends Node2D:
	var camera: Camera3D
	var fleet: Node3D
	var offsets: Array[Vector3]
	var roles: Array[int]
	var map_opacity := 1.0
	var transition_marker_weight := 1.0

	func _draw() -> void:
		var world_center := fleet.position + FLEET_FOCUS
		if camera.is_position_behind(world_center):
			return
		var center := camera.unproject_position(world_center)
		var projected_forward := camera.unproject_position(world_center + Vector3.RIGHT * 24.0)
		var fleet_width := center.distance_to(projected_forward)
		var marker_alpha := maxf(map_opacity, transition_marker_weight) * (1.0 - smoothstep(75.0, 230.0, fleet_width))
		if map_opacity > 0.0:
			draw_map()
		if marker_alpha > 0.0:
			var heading := (projected_forward - center).normalized()
			var wing := heading.orthogonal()
			var tint := Color(0.70, 0.95, 1.0, marker_alpha)
			draw_circle(center, 14.0, Color(0.02, 0.055, 0.09, 0.90 * marker_alpha))
			draw_arc(center, 14.0, 0.0, TAU, 28, tint, 2.4, true)
			draw_colored_polygon(PackedVector2Array([center + heading * 9.0,
				center - heading * 5.0 + wing * 5.0, center - heading * 3.0,
				center - heading * 5.0 - wing * 5.0]), tint)
			var label_position := center + Vector2(22.0, -15.0)
			draw_rect(Rect2(label_position + Vector2(-5.0, -22.0), Vector2(179.0, 29.0)),
				Color(0.01, 0.035, 0.06, 0.85 * marker_alpha))
			draw_string(ThemeDB.fallback_font, label_position, "WU FLEET  /  60",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 24, tint)

	func draw_map() -> void:
		var grid_color := Color(0.38, 0.62, 0.80, 0.24 * map_opacity)
		for x in range(-22000, 22001, 2000):
			draw_world_line(Vector3(x, -1, -15000), Vector3(x, -1, 15000), grid_color)
		for z in range(-15000, 15001, 2000):
			draw_world_line(Vector3(-22000, -1, z), Vector3(22000, -1, z), grid_color)
		var route_color := Color(0.42, 0.80, 0.93, 0.88 * map_opacity)
		var route_start := Vector3(FLEET_FOCUS.x, -1.0, 0.0)
		var route_end := route_start + Vector3.RIGHT * SPEED * DURATION
		draw_world_line(route_start, route_end, route_color)
		draw_world_line(route_start + Vector3.BACK * 115.0, route_start + Vector3.FORWARD * 115.0, route_color)
		draw_world_line(route_end + Vector3.BACK * 115.0, route_end + Vector3.FORWARD * 115.0, route_color)

	func draw_world_line(a: Vector3, b: Vector3, color: Color) -> void:
		if not camera.is_position_behind(a) and not camera.is_position_behind(b):
			draw_line(camera.unproject_position(a), camera.unproject_position(b), color, 1.0, true)

@onready var camera: Camera3D = $Camera3D
var sun: DirectionalLight3D
var camera_shots: Array = SHOTS
var camera_stages: Array = STAGES
var asteroid_clearance := 7.5
var hud_title := "WU FLEET   /   60 SHIPS"
var fleet := Node3D.new()
var offsets: Array[Vector3] = []
var roles: Array[int] = []
var overlay := StrategyOverlay.new()
var stage_label := Label.new()
var time_label := Label.new()
var scrubber := HSlider.new()
var time := 0.0
var paused := false


func _ready() -> void:
	if not build_fleet():
		get_tree().quit(1)
		return
	build_space()
	build_lighting()
	build_hud()
	show_frame(0.0)


func build_fleet() -> bool:
	var models: Array[PackedScene] = []
	for path: String in PATHS:
		var model := load(path) as PackedScene
		if model == null:
			push_error("Missing Wu fleet model: " + path)
			return false
		models.append(model)
	add_child(fleet)
	build_formation()
	for i in offsets.size():
		var role := roles[i]
		var ship := models[role].instantiate() as Node3D
		ship.position = offsets[i]
		var bounds := mesh_bounds(ship, Transform3D.IDENTITY)
		var length := maxf(bounds.size.x, bounds.size.z)
		if length <= 0.0:
			ship.free()
			push_error("Missing hull bounds for role %d" % role)
			return false
		ship.scale = Vector3.ONE * LENGTHS[role] / length
		fleet.add_child(ship)
	return true


func build_formation() -> void:
	# The lead ship travels ahead of the formation. The gap clears the complete
	# inspection orbit, including the stern view, while the fleet stays in motion.
	offsets.append(Vector3.ZERO)
	roles.append(0)
	for deck in 3:
		for row in 4:
			for column in 5:
				if deck == 1 and row == 0 and column == 2:
					continue
				var tier := float(deck - 1)
				var wing := float(column - 2)
				offsets.append(Vector3(-4.0 - row * 1.7 - absf(wing) * 0.38 - absf(tier) * 1.5,
					tier * 1.25 + wing * 0.10, wing * 1.25 + tier * 2.8))
				roles.append((row + column + deck) % PATHS.size())


func mesh_bounds(node: Node3D, parent: Transform3D) -> AABB:
	var basis := parent * node.transform
	var result := AABB()
	if node is MeshInstance3D and node.mesh:
		result = basis * node.mesh.get_aabb()
	for child in node.get_children():
		if child is Node3D:
			var child_bounds := mesh_bounds(child, basis)
			if child_bounds.has_volume():
				result = result.merge(child_bounds) if result.has_volume() else child_bounds
	return result

func build_space() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4837
	var sky_material := StandardMaterial3D.new()
	sky_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_material.vertex_color_use_as_albedo = true
	var stars := ImmediateMesh.new()
	stars.surface_begin(Mesh.PRIMITIVE_POINTS, sky_material)
	for i in 2800:
		var direction := Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized()
		stars.surface_set_color(Color(0.52, 0.65, 0.82).lerp(Color.WHITE, rng.randf()))
		stars.surface_add_vertex(direction * 1450.0)
	stars.surface_end()
	var star_field := MeshInstance3D.new()
	star_field.mesh = stars
	add_child(star_field)
	var planet := SphereMesh.new()
	planet.radius = 6360.0
	planet.height = 12720.0
	place_body(planet, Vector3(-12000, -14500, 5300), Color("#4584ae"))
	var moon := SphereMesh.new()
	moon.radius = 1737.0
	moon.height = 3474.0
	place_body(moon, Vector3(-4300, -3800, -5600), Color("#adb7c7"))
	var outer_planet := SphereMesh.new()
	outer_planet.radius = 3400.0
	outer_planet.height = 6800.0
	place_body(outer_planet, Vector3(14500, -3600, -7500), Color("#9b664f"))
	var rock := SphereMesh.new()
	rock.radial_segments = 9
	rock.rings = 5
	var rock_arrays := rock.get_mesh_arrays()
	var vertices: PackedVector3Array = rock_arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()):
		var point := vertices[i]
		var ripple := sin(point.x * 29.0 + point.y * 19.0) * cos(point.z * 31.0)
		vertices[i] = point * (1.0 + 0.38 * ripple)
	rock_arrays[Mesh.ARRAY_VERTEX] = vertices
	var rubble := ArrayMesh.new()
	rubble.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, rock_arrays)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("#504d50")
	stone.roughness = 0.95
	rubble.surface_set_material(0, stone)
	var stream := MultiMesh.new()
	stream.transform_format = MultiMesh.TRANSFORM_3D
	stream.mesh = rubble
	stream.instance_count = 650
	for i in range(stream.instance_count):
		var group := i % 28
		var side := -1.0 if group % 2 == 0 else 1.0
		var far_band := group % 4 >= 2
		var group_x := -75.0 + group * 81.0
		if i >= 560:
			var patrol_band := float((i - 560) % 6)
			group_x = 529.0 + patrol_band * 41.0
		var x := group_x + clampf(rng.randfn(0.0, 16.0 if far_band else 9.0), -34.0, 34.0)
		var group_z := 27.0 if far_band else 10.0
		if i >= 560:
			group_z = 15.0 if far_band else 9.0
		var z := side * (group_z + 4.0 * sin(group * 0.9))
		z += clampf(rng.randfn(0.0, 3.5), -5.0, 5.0)
		z = side * (maxf(absf(z), 7.5) + asteroid_clearance - 7.5)
		var y := 5.0 * sin(group * 0.67) + rng.randfn(0.0, 2.5)
		var size := pow(rng.randf(), 2.2) * (1.52 if far_band else 0.72) + 0.04
		var spin := Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU))
		spin = spin.scaled(Vector3(1.65, 0.57, 0.87) * size)
		stream.set_instance_transform(i, Transform3D(spin, Vector3(x, y, z)))
	var belt := MultiMeshInstance3D.new()
	belt.multimesh = stream
	add_child(belt)
	var cloud_mesh := QuadMesh.new()
	cloud_mesh.size = Vector2(118.0, 65.0)
	for i in 22:
		var cloud := MeshInstance3D.new()
		cloud.mesh = cloud_mesh
		var gas := ShaderMaterial.new()
		gas.shader = preload("res://nebula_veil.gdshader")
		gas.set_shader_parameter("seed", float(i) * 43.0)
		cloud.material_override = gas
		cloud.position = Vector3(40.0 + i * 104.0, -18.0 + sin(i * 0.69) * 22.0,
			-93.0 - cos(i * 0.42) * 69.0)
		cloud.rotation = Vector3(-0.32, i * 0.58, i * 0.79)
		add_child(cloud)


func place_body(mesh: Mesh, where: Vector3, tint: Color) -> MeshInstance3D:
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.position = where
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.92
	body.material_override = material
	if mesh is SphereMesh and mesh.radius >= 10.0:
		var planet_material := ShaderMaterial.new()
		planet_material.shader = preload("res://planet_surface.gdshader")
		planet_material.set_shader_parameter("base_color", tint)
		body.material_override = planet_material
	add_child(body)
	return body


var wheel_tween: Tween
var wheel_target := 0.0


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton and event.pressed):
		return
	var direction := 0.0
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		direction = 1.0
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		direction = -1.0
	if direction == 0.0:
		return
	if wheel_tween and wheel_tween.is_running():
		wheel_tween.kill()
	else:
		wheel_target = time
	paused = true
	wheel_target = clampf(wheel_target + direction * 1.5 * event.factor, 0.0, DURATION)
	wheel_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	wheel_tween.tween_method(show_frame, time, wheel_target, 0.20)
	get_viewport().set_input_as_handled()

func build_lighting() -> void:
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.05, -0.49, -0.39)
	fill.light_color = Color("#a0bad5")
	fill.light_energy = 0.31
	fill.light_specular = 0.07
	fill.omni_range = 1.47
	fleet.add_child(fill)
	var environment := Environment.new()
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.13
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#081322")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#acc9e8")
	environment.ambient_light_energy = 0.34
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	for setup in [
		[Vector3(-35, -38, 0), Color("#fff0d9"), 2.15],
		[Vector3(-23, 138, 0), Color("#a6c5f2"), 0.47],
		[Vector3(48, 63, 0), Color("#a5c8ff"), 0.28],
	]:
		var light := DirectionalLight3D.new()
		light.rotation_degrees = setup[0]
		light.light_color = setup[1]
		light.light_energy = setup[2]
		light.shadow_enabled = light.light_energy > 2.0
		if light.shadow_enabled:
			sun = light
		light.directional_shadow_max_distance = 220.0
		add_child(light)


func build_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	overlay.camera = camera
	overlay.fleet = fleet
	overlay.offsets = offsets
	overlay.roles = roles
	layer.add_child(overlay)

	var hud := Control.new()
	layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var title := Label.new()
	title.text = hud_title
	title.position = Vector2(32, 22)
	title.modulate = Color("#8cbdcf")
	hud.add_child(title)
	stage_label.position = Vector2(32, 44)
	stage_label.add_theme_font_size_override("font_size", 32)
	hud.add_child(stage_label)

	var bottom := VBoxContainer.new()
	hud.add_child(bottom)
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 32
	bottom.offset_right = -32
	bottom.offset_top = -68
	bottom.offset_bottom = -20
	var controls := HBoxContainer.new()
	bottom.add_child(controls)
	time_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(time_label)
	var help := Label.new()
	help.text = "Space  Pause / Resume     ·     R  Replay"
	help.modulate = Color("#a4bbcc")
	controls.add_child(help)
	scrubber.max_value = DURATION
	scrubber.step = 0.0
	scrubber.focus_mode = Control.FOCUS_NONE
	scrubber.add_theme_constant_override("center_grabber", 1)
	scrubber.value_changed.connect(seek)
	bottom.add_child(scrubber)


var profile_enabled := "--profile-camera" in OS.get_cmdline_user_args()
var profile_phase := -1
var profile_frames := 0
var profile_seconds := 0.0
var profile_peak := 0.0
var profile_draws := 0


func sample_performance(delta: float) -> void:
	var phase := 0
	for boundary in [10.0, 20.0, 35.0, 45.0, 55.0, 105.0, 120.0]:
		if time >= boundary:
			phase += 1
	if phase != profile_phase:
		if profile_frames > 0:
			print("Stage %d: %d frames, avg %.2f ms, max %.2f ms, max %d draw calls" %
				[profile_phase + 1, profile_frames, profile_seconds * 1000.0 / profile_frames,
				profile_peak * 1000.0, profile_draws])
		if phase == 7:
			get_tree().quit()
			return
		profile_phase = phase
		profile_frames = 0
		profile_seconds = 0.0
		profile_peak = 0.0
		profile_draws = 0
	profile_frames += 1
	profile_seconds += delta
	profile_peak = maxf(profile_peak, delta)
	profile_draws = maxi(profile_draws,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))


var capture_frame := 0


func _process(delta: float) -> void:
	if "--capture-24" in OS.get_cmdline_user_args():
		show_frame(minf(float(capture_frame) * DURATION / 2879.0, DURATION))
		capture_frame += 1
		return
	if not paused and time < DURATION:
		show_frame(minf(time + delta, DURATION))
	if profile_enabled:
		sample_performance(delta)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if time >= DURATION:
			show_frame(0.0)
		paused = not paused if time > 0.0 else false
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		paused = false
		show_frame(0.0)


func seek(value: float) -> void:
	if wheel_tween and wheel_tween.is_running():
		wheel_tween.kill()
	paused = true
	show_frame(value)


func map_focus_weight(strength: float, _span: float) -> float:
	return smoothstep(0.0, 0.14, strength)


func tracking_point(weight: float) -> Vector3:
	return FLEET_FOCUS.lerp(Vector3.ZERO, weight)


func show_frame(at: float) -> void:
	var approach := smoothstep(45.0, 48.0, at) * (1.0 - smoothstep(52.0, 55.0, at))
	sun.light_specular = lerpf(0.68, 0.40, approach)
	time = at
	fleet.position.x = SPEED * at
	var index := 0
	while index + 2 < camera_shots.size() and at > camera_shots[index + 1][0]:
		index += 1
	var a: Array = camera_shots[index]
	var b: Array = camera_shots[index + 1]
	var u := smoothstep(a[0], b[0], at)
	var az := deg_to_rad(lerpf(a[1], b[1], u))
	var elevation := lerpf(a[2], b[2], u)
	var el := deg_to_rad(elevation)
	var span := exp(lerpf(log(a[3]), log(b[3]), u))
	var strength := lerpf(a[4], b[4], u)
	var focus := fleet.position + tracking_point(lerpf(a[5], b[5], u))
	focus = STRATEGIC_CENTER.lerp(focus, map_focus_weight(strength, span))
	var horizontal := Vector3(cos(az), 0.0, -sin(az))
	var radial := horizontal * cos(el) + Vector3.UP * sin(el)
	var right := Vector3(-sin(az), 0.0, -cos(az))
	# Explicit basis preserves roll at both poles. A matched vertical span keeps
	# focus-plane magnification fixed as the perspective eye recedes to parallel.
	var parallel_distance := 100000.0
	var distance := span / (2.0 * strength + span / parallel_distance)
	camera.transform = Transform3D(Basis(right, radial.cross(right), radial), focus + radial * distance)
	var near_clip := maxf(0.08, distance - 750.0)
	if strength <= 0.000001:
		camera.set_orthogonal(span, near_clip, distance + 52000.0)
	else:
		camera.set_frustum(span * near_clip / distance, Vector2.ZERO, near_clip, distance + 52000.0)

	var stage: String = camera_stages[0][1]
	for cue in camera_stages:
		if at >= cue[0]:
			stage = cue[1]
	stage_label.text = stage
	time_label.text = "%05.1f / 120.0 s   ·   %+.0f°" % [at, elevation]
	scrubber.set_value_no_signal(at)
	overlay.map_opacity = 1.0 - smoothstep(0.0, 0.18, strength)
	overlay.transition_marker_weight = maxf(1.0 - smoothstep(16.0, 23.0, at), smoothstep(112.0, 118.0, at))
	overlay.queue_redraw()
