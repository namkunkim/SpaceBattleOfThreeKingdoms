extends "res://fleet_camera.gd"

const FORMATION_CENTERS: Array[Vector3] = [
	Vector3(64, 7, 1), Vector3(22, -4, -23), Vector3(31, 5, 19),
	Vector3(-8, 1, -42), Vector3(-1, 9, 34), Vector3(-49, -8, -64),
	Vector3(-13, 4, -4), Vector3(-54, -3, 61), Vector3(-40, -7, -26),
	Vector3(-34, 2, 21),
]
const INSPECTED_FORMATION := 1
const GROUP_STAGES := [
	[0.0, "Strategic overview"], [10.0, "Ten fleets  /  staggered wedge"],
	[20.0, "Tactical descent"], [35.0, "Group tracking"],
	[47.0, "Approach  /  Fleet 02"], [60.0, "Fleet 02  /  sixty ships"],
	[83.0, "Rejoin the fleet group"], [105.0, "Return to strategic overview"],
]
const GROUP_SHOTS := [
	[0.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
	[3.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
	[10.0, 90.0, 90.0, 410.0, 0.0, 0.0],
	[15.0, 90.0, 90.0, 200.0, 0.0, 0.0],
	[20.0, 103.0, 61.0, 120.0, 0.14, 0.0],
	[35.0, 116.0, 29.0, 99.0, 0.30, 0.0],
	[47.0, 119.0, 22.0, 87.0, 0.31, 0.12],
	[55.0, 122.0, 19.0, 24.0, 0.37, 0.87],
	[60.0, 119.0, 16.0, 14.5, 0.40, 1.0],
	[70.0, 106.0, 15.0, 14.0, 0.41, 1.0],
	[78.0, 87.0, 20.0, 15.3, 0.39, 1.0],
	[83.0, 77.0, 23.0, 19.0, 0.35, 1.0],
	[94.0, 64.0, 27.0, 96.0, 0.30, 0.0],
	[105.0, 75.0, 40.0, 163.0, 0.19, 0.0],
	[112.0, 90.0, 83.0, 224.0, 0.035, 0.0],
	[115.0, 90.0, 90.0, 410.0, 0.0, 0.0],
	[119.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
	[120.0, 90.0, 90.0, 27000.0, 0.0, 0.0],
]


class GroupMap extends StrategyOverlay:
	func _draw() -> void:
		var alpha := maxf(map_opacity, transition_marker_weight)
		if alpha <= 0.0:
			return
		if map_opacity > 0.0:
			draw_map()

		var world_center := fleet.position + FLEET_FOCUS
		if camera.is_position_behind(world_center):
			return
		var center := camera.unproject_position(world_center)
		var extent := center.distance_to(camera.unproject_position(world_center + Vector3.BACK * 90.0))
		var color := Color(0.68, 0.93, 1.0, alpha)
		if extent < 74.0:
			draw_circle(center, 16.0, Color(0.02, 0.055, 0.09, 0.9 * alpha))
			draw_arc(center, 16.0, 0.0, TAU, 24, color, 2.0, true)
			draw_string(ThemeDB.fallback_font, center + Vector2(23, -12), "10 WU FLEETS  /  600 SHIPS",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 23, color)
			return

		for i in FORMATION_CENTERS.size():
			var formation := fleet.position + FLEET_FOCUS + FORMATION_CENTERS[i]
			if camera.is_position_behind(formation):
				continue
			var point := camera.unproject_position(formation)
			var heading := (camera.unproject_position(formation + Vector3.RIGHT) - point).normalized()
			var wing := heading.orthogonal()
			draw_colored_polygon(PackedVector2Array([point + heading * 8.0,
				point - heading * 5.0 + wing * 5.0, point - heading * 5.0 - wing * 5.0]), color)
			draw_string(ThemeDB.fallback_font, point + Vector2(12, -8), "%02d" % (i + 1),
				HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)


func _ready() -> void:
	camera_shots = GROUP_SHOTS
	camera_stages = GROUP_STAGES
	hud_title = "WU FLEET GROUP   /   10 FORMATIONS   /   600 SHIPS"
	overlay.free()
	overlay = GroupMap.new()
	asteroid_clearance = 76.0
	super._ready()


func build_fleet() -> bool:
	build_formation()
	if offsets.size() != 60 or roles.size() != offsets.size():
		push_error("Expected 60 ships per formation")
		return false
	add_child(fleet)

	for role in PATHS.size():
		var scene := load(PATHS[role]) as PackedScene
		if scene == null:
			push_error("Missing fleet model: " + PATHS[role])
			return false
		var model := scene.instantiate() as Node3D
		var bounds := mesh_bounds(model, Transform3D.IDENTITY)
		var hull_length := maxf(bounds.size.x, bounds.size.z)
		if hull_length <= 0.0:
			model.free()
			push_error("Missing hull geometry: " + PATHS[role])
			return false

		var surfaces := {}
		collect_surfaces(model, Transform3D.IDENTITY, surfaces)
		model.free()
		if surfaces.is_empty():
			push_error("Missing renderable surfaces: " + PATHS[role])
			return false
		var mesh := ArrayMesh.new()
		for surface in surfaces.values():
			surface.commit(mesh)

		var ship_basis := Basis.IDENTITY.scaled(Vector3.ONE * LENGTHS[role] / hull_length)
		for center in FORMATION_CENTERS:
			var placements: Array[Vector3] = []
			for i in offsets.size():
				if roles[i] == role:
					placements.append(center + offsets[i])
			if placements.is_empty():
				continue
			var multimesh := MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = mesh
			multimesh.instance_count = placements.size()
			for i in placements.size():
				multimesh.set_instance_transform(i, Transform3D(ship_basis, placements[i]))
			var batch := MultiMeshInstance3D.new()
			batch.multimesh = multimesh
			batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			fleet.add_child(batch)

	var count := 0
	for batch in fleet.get_children():
		count += (batch as MultiMeshInstance3D).multimesh.instance_count
	print("Wu fleet group: %d identical formations, %d ships" % [FORMATION_CENTERS.size(), count])
	return count == 600


func collect_surfaces(node: Node3D, parent: Transform3D, surfaces: Dictionary) -> void:
	var transform_in_model := parent * node.transform
	if node is MeshInstance3D and node.mesh:
		for i in node.mesh.get_surface_count():
			var material: Material = node.get_active_material(i)
			if not surfaces.has(material):
				var surface := SurfaceTool.new()
				surface.begin(Mesh.PRIMITIVE_TRIANGLES)
				surface.set_material(material)
				surfaces[material] = surface
			var entry: SurfaceTool = surfaces[material]
			entry.append_from(node.mesh, i, transform_in_model)
	for child in node.get_children():
		if child is Node3D:
			collect_surfaces(child, transform_in_model, surfaces)


func map_focus_weight(strength: float, span: float) -> float:
	return maxf(super.map_focus_weight(strength, span), 1.0 - smoothstep(420.0, 13500.0, span))


func tracking_point(weight: float) -> Vector3:
	return FLEET_FOCUS + FORMATION_CENTERS[INSPECTED_FORMATION] * weight


func build_lighting() -> void:
	super.build_lighting()
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.ambient_light_energy = 0.49


func show_frame(at: float) -> void:
	super.show_frame(at)
	sun.light_specular = 0.60
	overlay.transition_marker_weight = maxf(1.0 - smoothstep(18.0, 30.0, at),
		smoothstep(105.0, 115.0, at))
