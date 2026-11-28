extends "res://sector_tour.gd"

const RUN_TIME := 24.0
const ROUTE_START := Vector2(-240.0, 12.0)
const ROUTE_END := Vector2(210.0, 12.0)
const JADE := Color("#76efbb")
const HULLS := ["line", "carrier", "artillery", "supply", "siege", "interceptor", "ew", "fast"]
const LENGTHS := [0.75, 1.30, 0.90, 0.80, 1.05, 0.48, 0.40, 0.18]
const FORMATION_SCALE := 1.6

var fleet := Node3D.new()
var slots: Array[Vector3] = []
var roles: Array[int] = []
var map_opacity := 1.0
var recording := false


func _ready() -> void:
	recording = "--capture-tour" in OS.get_cmdline_user_args()
	rocks.seed = 91835
	var layer := CanvasLayer.new()
	add_child(layer)
	map = MAP_SCRIPT.new()
	map.show_controls = false
	layer.add_child(map)
	map.set_process_unhandled_input(false)
	selection = Node2D.new()
	layer.add_child(selection)
	selection.draw.connect(_draw_fleet_overlay)
	cluster = Vector2(165.0, -270.0)
	build_environment()
	build_asteroids()
	build_systems()
	add_child(fleet)
	_build_formation()
	if not _build_ships():
		get_tree().quit(1)
		return
	var fleet_fill := DirectionalLight3D.new()
	fleet_fill.rotation_degrees = Vector3(-30.0, -145.0, 0.0)
	fleet_fill.light_color = Color("#c9deff")
	fleet_fill.light_energy = 1.15
	fleet_fill.light_cull_mask = 2
	add_child(fleet_fill)
	camera = Camera3D.new()
	add_child(camera)
	camera.make_current()
	_sample(0.0)
	if "--verify-fleet" in OS.get_cmdline_user_args():
		_verify_flight()


func _process(delta: float) -> void:
	if recording and frames >= int(RUN_TIME * FPS):
		get_tree().quit()
		return
	elapsed = float(frames) / FPS if recording else fmod(elapsed + delta, RUN_TIME)
	_sample(elapsed)
	if recording:
		RenderingServer.force_draw(false)
	frames += 1


func _sample(time: float) -> void:
	var point := ROUTE_START.lerp(ROUTE_END, time / RUN_TIME)
	fleet.position = Vector3(point.x, 0.0, point.y)
	var approach := smoothstep(0.5, 6.0, time)
	var transition := smoothstep(8.0, 13.0, time)
	var overview: float = get_viewport().get_visible_rect().size.y / map.fit_zoom()
	var span := exp(lerpf(log(overview), log(110.0), approach))
	span = lerpf(span, 43.0, transition)
	span = lerpf(span, 21.0, smoothstep(14.0, 21.0, time))
	# Hold the enlarged 2D map long enough to see the ships move across it.
	var map_focus := ROUTE_START.lerp(ROUTE_END, minf(time, 5.4) / RUN_TIME)
	var focus := Vector2.ZERO.lerp(map_focus.lerp(point - Vector2(5.0, 0.0), transition), approach)
	var elevation := deg_to_rad(lerpf(90.0, 27.0, transition))
	var azimuth := deg_to_rad(lerpf(0.0, -20.0, transition))
	var radial := Vector3(sin(azimuth) * cos(elevation), sin(elevation), cos(azimuth) * cos(elevation))
	var right := Vector3(cos(azimuth), 0.0, -sin(azimuth))
	var distance := span / lerpf(0.035, 0.78, transition)
	var target := Vector3(focus.x, 0.0, focus.y)
	camera.transform = Transform3D(Basis(right, radial.cross(right), radial), target + radial * distance)
	var near_plane := maxf(0.3, distance - 2700.0)
	if transition == 0.0:
		camera.set_orthogonal(span, near_plane, distance + 14000.0)
	else:
		camera.set_frustum(span * near_plane / distance, Vector2.ZERO, near_plane, distance + 14000.0)

	map_opacity = 1.0 - smoothstep(0.0, 0.75, transition)
	map.center = focus
	map.zoom = get_viewport().get_visible_rect().size.y / span
	map.modulate.a = map_opacity
	map.visible = map_opacity > 0.001
	fleet.visible = transition > 0.15
	map.queue_redraw()
	selection.queue_redraw()


func _draw_fleet_overlay() -> void:
	var font := ThemeDB.fallback_font
	var screen := get_viewport().get_visible_rect().size
	var phase := "2D STRATEGIC MAP" if elapsed < 8.0 else "3D FLEET VIEW"
	if elapsed >= 8.0 and elapsed < 13.0:
		phase = "2D TO 3D"
	selection.draw_rect(Rect2(0.0, 0.0, screen.x, 52.0), Color("#101a29"))
	selection.draw_string(font, Vector2(22.0, 33.0), "SHU FLEET  /  60 SHIPS",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, JADE)
	selection.draw_string(font, Vector2(screen.x - 235.0, 33.0), phase,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#d8e7fb"))
	if map_opacity <= 0.001:
		return
	var start := camera.unproject_position(Vector3(ROUTE_START.x, 0.0, ROUTE_START.y))
	var finish := camera.unproject_position(Vector3(ROUTE_END.x, 0.0, ROUTE_END.y))
	var lead := camera.unproject_position(fleet.position)
	selection.draw_dashed_line(lead, finish, Color(JADE, map_opacity * 0.55), 2.0, 12.0, true)
	if start.distance_to(finish) < 180.0:
		_draw_arrow(lead, 13.0)
		selection.draw_string(font, lead + Vector2(20, -12), "SHU",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color(JADE, map_opacity))
	else:
		for slot in slots:
			var point := camera.unproject_position(fleet.position + Vector3(slot.x, 0.0, slot.z))
			_draw_arrow(point, 8.0 if slot == Vector3.ZERO else 3.0)


func _draw_arrow(point: Vector2, size: float) -> void:
	var heading := (camera.unproject_position(fleet.position + Vector3.RIGHT)
		- camera.unproject_position(fleet.position)).normalized()
	var wing := heading.orthogonal()
	selection.draw_colored_polygon(PackedVector2Array([
		point + heading * size,
		point - heading * size * 0.55 + wing * size * 0.65,
		point - heading * size * 0.55 - wing * size * 0.65,
	]), Color(JADE, map_opacity))


func _verify_flight() -> void:
	var count := 0
	for batch: MultiMeshInstance3D in fleet.get_children():
		count += batch.multimesh.instance_count
	assert(count == 60)
	var previous := -INF
	for time: float in [0.0, 6.0, 8.0, 10.5, 13.0, 18.0, 23.0]:
		_sample(time)
		assert(fleet.position.x > previous)
		assert(map.clear_lane(Vector2(fleet.position.x, fleet.position.z)))
		if time <= 8.0:
			assert(map.visible and not fleet.visible)
			var world: Vector2 = map.world_at(camera.unproject_position(fleet.position))
			assert(world.is_equal_approx(Vector2(fleet.position.x, fleet.position.z)))
		elif time >= 13.0:
			assert(not map.visible and fleet.visible)
			assert(not camera.is_position_behind(fleet.position))
		previous = fleet.position.x
	print("Verified 60 Shu ships, shared route, 2D alignment and continuing 3D flight.")
	get_tree().quit()


func _build_formation() -> void:
	slots.append(Vector3.ZERO)
	roles.append(0)
	for deck in 3:
		for row in 4:
			for column in 5:
				if deck == 1 and row == 0 and column == 2:
					continue
				var tier := float(deck - 1)
				var wing := float(column - 2)
				slots.append(Vector3(-4.0 - row * 1.7 - absf(wing) * 0.38 - absf(tier) * 1.5,
					tier * 1.25 + wing * 0.10, wing * 1.25 + tier * 2.8) * FORMATION_SCALE)
				roles.append((row + column + deck) % HULLS.size())

func _build_ships() -> bool:
	for role in HULLS.size():
		var reference := load("res://models/shu-%s.glb" % HULLS[role]) as PackedScene
		if reference == null:
			push_error("Missing Shu hull: " + HULLS[role])
			return false
		var model := reference.instantiate() as Node3D
		var bounds := AABB()
		var surfaces := {}
		var stack: Array[Node3D] = [model]
		var transforms := {model: model.transform}
		while not stack.is_empty():
			var part: Node3D = stack.pop_back()
			var transform_in_model: Transform3D = transforms[part]
			if part is MeshInstance3D and part.mesh:
				var section: AABB = transform_in_model * part.get_aabb()
				bounds = bounds.merge(section) if bounds.has_volume() else section
				for index in part.mesh.get_surface_count():
					var material: Material = part.get_active_material(index)
					if not surfaces.has(material):
						var surface := SurfaceTool.new()
						surface.begin(Mesh.PRIMITIVE_TRIANGLES)
						surface.set_material(material)
						surfaces[material] = surface
					var surface: SurfaceTool = surfaces[material]
					surface.append_from(part.mesh, index, transform_in_model)
			for child in part.get_children():
				if child is Node3D:
					transforms[child] = transform_in_model * child.transform
					stack.append(child)
		model.free()
		var merged := ArrayMesh.new()
		for surface in surfaces.values():
			surface.commit(merged)
		var hull_scale: float = LENGTHS[role] * FORMATION_SCALE / maxf(bounds.size.x, bounds.size.z)
		var orientation := Basis.IDENTITY
		if bounds.size.z > bounds.size.x:
			orientation = Basis(Vector3.UP, PI / 2.0)
		var basis := orientation.scaled(Vector3.ONE * hull_scale)
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = merged
		multi.instance_count = roles.count(role)
		var ship := 0
		var model_transform := Transform3D(basis, -(basis * bounds.get_center()))
		for i in slots.size():
			if roles[i] == role:
				multi.set_instance_transform(ship, Transform3D(Basis.IDENTITY, slots[i]) * model_transform)
				ship += 1
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multi
		batch.layers = 2
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fleet.add_child(batch)
	return true
