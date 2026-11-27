extends Node3D
var asteroid_clearance := 76.0

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


func build_lighting() -> void:
	var fill := OmniLight3D.new()
	fill.position = Vector3(0.05, -0.49, -0.39)
	fill.light_color = Color("#a0bad5")
	fill.light_energy = 0.31
	fill.light_specular = 0.07
	fill.omni_range = 1.47
	add_child(fill)
	var environment := Environment.new()
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.13
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("#081322")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#acc9e8")
	environment.ambient_light_energy = 0.49
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
			light.light_specular = 0.60
		light.directional_shadow_max_distance = 220.0
		add_child(light)
