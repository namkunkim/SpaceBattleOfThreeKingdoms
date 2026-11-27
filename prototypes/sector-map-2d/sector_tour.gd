extends Node3D

const FPS := 30
const DURATION := 48.0
const MAP_SCRIPT = preload("res://sector_map.gd")
const SUN_RADIUS := 5.2

var map
var camera: Camera3D
var cluster := Vector2.ZERO
var selection: Node2D
var system_point := Vector2.ZERO
var system_name := ""
var frames := 0
var rocks := RandomNumberGenerator.new()

func _ready() -> void:
	rocks.seed = 91835
	var overlay := CanvasLayer.new()
	add_child(overlay)
	map = MAP_SCRIPT.new()
	overlay.add_child(map)
	var candidates := PackedVector2Array()
	for stone in map.stones:
		var point: Vector2 = stone.p
		if MAP_SCRIPT.MAP.grow(-430.0).has_point(point) and map.lane_clearance(point) < -260.0 and map.density(point) > 0.79:
			candidates.append(point)
	if candidates.is_empty():
		push_error("No terrain suitable for the sector tour.")
		get_tree().quit(1)
		return
	var choice := RandomNumberGenerator.new()
	choice.randomize()
	cluster = candidates[choice.randi_range(0, candidates.size() - 1)]
	var central: Dictionary = map.systems[0]
	system_point = central.p
	system_name = central.name
	print("Selected sector point: ", cluster, " | central system: ", system_name, " at ", system_point)
	selection = Node2D.new()
	overlay.add_child(selection)
	selection.draw.connect(draw_selection)
	build_environment()
	build_asteroids()
	build_systems()
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	update_shot(0.0)

func _process(delta: float) -> void:
	var time := float(frames) / FPS if "--capture-tour" in OS.get_cmdline_user_args() else elapsed + delta
	elapsed = time
	update_shot(minf(time, DURATION))
	frames += 1

var elapsed := 0.0

func update_shot(time: float) -> void:
	var overview_span: float = get_viewport().get_visible_rect().size.y / map.fit_zoom()
	var shots := [
		[0.0, Vector2.ZERO, overview_span, 90.0, 0.0, 0.0],
		[2.8, Vector2.ZERO, overview_span, 90.0, 0.0, 0.0],
		[8.0, cluster, 205.0, 90.0, 0.0, 0.0],
		[10.8, cluster, 149.0, 90.0, 0.0, 0.02],
		[15.0, cluster, 101.0, 40.0, -14.0, 0.59],
		[20.0, cluster + Vector2(9.0, 5.0), 83.0, 22.0, 21.0, 0.85],
		[24.0, cluster, 226.0, 90.0, 0.0, 0.0],
		[27.2, Vector2.ZERO, overview_span, 90.0, 0.0, 0.0],
		[30.6, Vector2.ZERO, overview_span, 90.0, 0.0, 0.0],
		[35.4, system_point, 245.0, 90.0, 0.0, 0.0],
		[38.0, system_point, 223.0, 90.0, 0.0, 0.04],
		[42.0, system_point, 175.0, 54.0, -13.0, 0.31],
		[DURATION, system_point, 153.0, 38.0, 28.0, 0.48],
	]
	var index := 0
	while index + 2 < shots.size() and time > shots[index + 1][0]:
		index += 1
	var a: Array = shots[index]
	var b: Array = shots[index + 1]
	var t := smoothstep(a[0], b[0], time)
	var target: Vector2 = a[1].lerp(b[1], t)
	var span := exp(lerpf(log(a[2]), log(b[2]), t))
	var elevation := deg_to_rad(lerpf(a[3], b[3], t))
	var azimuth := deg_to_rad(lerpf(a[4], b[4], t))
	var perspective := lerpf(a[5], b[5], t)
	var terrain_blend := smoothstep(8.9, 11.1, time) * (1.0 - smoothstep(22.0, 24.0, time))
	var system_blend := smoothstep(36.0, 38.4, time)
	var blend := maxf(terrain_blend, system_blend)
	map.modulate.a = 1.0 - blend
	map.visible = map.modulate.a > 0.001
	map.center = target
	map.zoom = get_viewport().get_visible_rect().size.y / span
	map.queue_redraw()
	selection.queue_redraw()
	var forward := Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation))
	var right := Vector3(cos(azimuth), 0.0, -sin(azimuth))
	var distance := span / lerpf(0.035, 0.88, perspective)
	var target_3d := Vector3(target.x, 0.0, target.y)
	camera.transform = Transform3D(Basis(right, forward.cross(right), forward), target_3d + forward * distance)
	var near_plane := maxf(0.3, distance - 2700.0)
	if perspective < 0.001:
		camera.set_orthogonal(span, near_plane, distance + 14000.0)
	else:
		camera.set_frustum(span * near_plane / distance, Vector2.ZERO, near_plane, distance + 14000.0)

func draw_selection() -> void:
	var visiting_system := elapsed >= 26.5
	var opacity := smoothstep(26.5, 28.0, elapsed) if visiting_system else smoothstep(0.9, 1.45, elapsed) * (1.0 - smoothstep(12.0, 14.0, elapsed))
	var selected := system_point if visiting_system else cluster
	if opacity <= 0.0:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var point: Vector2 = viewport_size * 0.5 + (selected - map.center) * map.zoom
	if elapsed >= 38.4 or (not visiting_system and elapsed >= 11.1):
		point = camera.unproject_position(Vector3(selected.x, 0.0, selected.y))
	if visiting_system and elapsed >= 39.0:
		point += Vector2(0.0, -24.0)
	var tint := Color(0.66, 0.93, 1.0, opacity)
	var shadow := Color(0.03, 0.10, 0.15, opacity * 0.91)
	selection.draw_circle(point, 15.0, shadow, false, 4.0, true)
	selection.draw_arc(point, 15.0, 0.0, TAU, 40, tint, 1.5, true)
	for side in 4:
		var direction := Vector2.from_angle(side * TAU / 4.0)
		selection.draw_line(point + direction * 9.0, point + direction * 20.0, tint, 1.6, true)
	var label_position := point + Vector2(24.0, -16.0)
	selection.draw_rect(Rect2(label_position + Vector2(-5.0, -16.0), Vector2(190.0, 23.0)), shadow)
	selection.draw_string(ThemeDB.fallback_font, label_position, system_name + "  /  STAR SYSTEM" if visiting_system else "SELECTED SECTOR",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, tint)


func build_environment() -> void:
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("#080d19")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("#a3b8db")
	world.environment.ambient_light_energy = 0.35
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-31.0, 124.0, 0.0)
	light.light_color = Color("#ffe5c5")
	light.light_energy = 1.22
	add_child(light)
	var sky := ImmediateMesh.new()
	var star_material := StandardMaterial3D.new()
	star_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	star_material.vertex_color_use_as_albedo = true
	sky.surface_begin(Mesh.PRIMITIVE_POINTS, star_material)
	for i in 6200:
		var p := Vector3(rocks.randf_range(-4900.0, 4900.0), rocks.randf_range(-750.0, -200.0),
			rocks.randf_range(-3600.0, 3600.0))
		sky.surface_set_color(Color("#29415e").lerp(Color("#dce9ff"), pow(rocks.randf(), 4.0)))
		sky.surface_add_vertex(p)
	sky.surface_end()
	var stars := MeshInstance3D.new()
	stars.mesh = sky
	add_child(stars)
	build_clouds()


func build_clouds() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 722634
	noise.frequency = 0.044
	noise.fractal_octaves = 4
	var materials: Array[StandardMaterial3D] = []
	for variant in 5:
		var image := Image.create_empty(96, 96, false, Image.FORMAT_RGBA8)
		for y in 96:
			for x in 96:
				var uv := (Vector2(x, y) + Vector2(0.5, 0.5)) / 96.0
				var p := (uv - Vector2(0.5, 0.5)) * 2.0
				var turbulence := noise.get_noise_2d(x + variant * 139, y - variant * 97)
				var fine := noise.get_noise_2d(x * 2.4 - variant * 90, y * 2.4)
				var envelope := 1.0 - smoothstep(0.19, 0.97, p.length() + turbulence * 0.32)
				var alpha := envelope * smoothstep(-0.55, 0.5, turbulence + fine * 0.27)
				var tint := Color("#3c5068").lerp(Color("#9ca4ad"), smoothstep(-0.39, 0.66, turbulence))
				tint.a = alpha
				image.set_pixel(x, y, tint)
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		material.billboard_keep_scale = true
		material.albedo_texture = ImageTexture.create_from_image(image)
		material.albedo_color = Color(0.92, 0.96, 1.0, 0.42)
		materials.append(material)
	var quad := QuadMesh.new()
	for i in 115:
		var cloud := MeshInstance3D.new()
		cloud.mesh = quad
		cloud.material_override = materials[i % materials.size()]
		var offset := Vector3(rocks.randfn(0.0, 52.0), rocks.randfn(0.0, 34.0), rocks.randfn(0.0, 60.0))
		cloud.position = Vector3(cluster.x, 0.0, cluster.y) + offset
		var width := rocks.randf_range(24.0, 104.0)
		cloud.scale = Vector3(width, width * rocks.randf_range(0.52, 1.08), 1.0)
		cloud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(cloud)


func build_asteroids() -> void:
	var batches: Array[Array] = []
	for variant in MAP_SCRIPT.ROCK_SHAPES:
		batches.append([])
	for stone in map.stones:
		batches[MAP_SCRIPT.rock_variant(stone.shape)].append(stone)
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("#8993a9")
	surface.roughness = 0.97
	surface.vertex_color_use_as_albedo = true
	for variant in batches.size():
		var stones: Array = batches[variant]
		if stones.is_empty():
			continue
		var mesh := build_rock_mesh(MAP_SCRIPT.rock_outline(variant))
		mesh.surface_set_material(0, surface)
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.use_colors = true
		instances.mesh = mesh
		instances.instance_count = stones.size()
		for i in stones.size():
			var stone: Dictionary = stones[i]
			var p: Vector2 = stone.p
			var pose := Basis(Vector3.UP, -float(stone.angle)).scaled(Vector3.ONE * float(stone.radius))
			instances.set_instance_transform(i, Transform3D(pose,
				Vector3(p.x, rocks.randfn(0.0, 19.0), p.y)))
			var shade := 0.54 + float(stone.shade) * 0.39
			instances.set_instance_color(i, Color(shade, shade, shade))
		var belt := MultiMeshInstance3D.new()
		belt.multimesh = instances
		add_child(belt)

func build_rock_mesh(outline: PackedVector2Array) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	var crest := Vector3(-0.22, 0.39, -0.17)
	var bottom := Vector3(0.14, -0.27, 0.08)
	for i in outline.size():
		var next := (i + 1) % outline.size()
		var a := Vector3(outline[i].x, 0.07 * sin(i * 2.1), outline[i].y)
		var b := Vector3(outline[next].x, 0.07 * sin(next * 2.1), outline[next].y)
		surface.add_vertex(crest)
		surface.add_vertex(a)
		surface.add_vertex(b)
		surface.add_vertex(bottom)
		surface.add_vertex(b)
		surface.add_vertex(a)
	surface.generate_normals()
	return surface.commit()

func build_systems() -> void:
	var orbit_color := StandardMaterial3D.new()
	orbit_color.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	orbit_color.albedo_color = Color("#536b8b")
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, orbit_color)
	for system in map.systems:
		var p: Vector2 = system.p
		var origin := Vector3(p.x, 0.0, p.y)
		sphere_at(origin, SUN_RADIUS, system.color, true)
		var sun_light := OmniLight3D.new()
		sun_light.position = origin
		sun_light.light_color = system.color
		sun_light.omni_range = 112.0
		sun_light.light_energy = 2.1
		add_child(sun_light)
		var orbit_angles: Array[float] = system.orbits
		for i in orbit_angles.size():
			var radius := 20.0 + i * 19.0
			for step in 96:
				var start := Vector2.from_angle(step * TAU / 96.0) * radius
				var end := Vector2.from_angle((step + 1) * TAU / 96.0) * radius
				lines.surface_add_vertex(origin + Vector3(start.x, -0.4, start.y))
				lines.surface_add_vertex(origin + Vector3(end.x, -0.4, end.y))
			var location := Vector2.from_angle(orbit_angles[i]) * radius
			var color: Color = MAP_SCRIPT.GAS_COLORS[i % MAP_SCRIPT.GAS_COLORS.size()]
			sphere_at(origin + Vector3(location.x, 0.0, location.y), 2.2 + (i % 3) * 0.9, color.lightened(0.2), false)
	lines.surface_end()
	var rings := MeshInstance3D.new()
	rings.mesh = lines
	add_child(rings)

func sphere_at(position: Vector3, radius: float, tint: Color, emitting: bool) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 36
	mesh.rings = 18
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.roughness = 0.8
	if emitting:
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	var body := MeshInstance3D.new()
	body.mesh = mesh
	body.position = position
	add_child(body)
