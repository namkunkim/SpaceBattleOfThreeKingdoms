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


@export var mouse_validation := false

const WIDE_ZOOM := 3.0
const CLOSE_ZOOM := 68.0
var camera_zoom := WIDE_ZOOM
var camera_pan := Vector3.ZERO
var panning := false
var simulation_paused := false
var move_gesture_index := -1
var move_gesture_start := Vector2.ZERO
var move_gesture_target := Vector3.ZERO
const FACING_DRAG_THRESHOLD := 8.0
var formations: Array[Node3D] = []
var destinations: Dictionary[int, Vector3] = {}
const FleetMotion = preload("res://fleet_poc_motion.gd")
const COMMAND_SPEED := 22.0
# Mirrors the factions in the main project's world atlas.
const FACTION_COLORS := {"wei": Color("#74bdff"), "shu": Color("#85d9ab"), "wu": Color("#ff938b")}
@export_enum("wei", "shu", "wu") var fleet_faction := "wu"
var motion: Array[FleetMotion] = []
var ship_batches: Array[Array] = []
var role_scales: Array[float] = []
var role_bounds: Array[AABB] = []
var role_nozzles: Array[Array] = []
var engine_plumes: Array[MultiMeshInstance3D] = []

const ORDER_LABELS := ["이동", "방향 전환", "정지"]
enum Order { NONE = -1, MOVE, FACE, STOP }


class GroupMap extends StrategyOverlay:
	const INK := Color("#bbf1ff")
	const EDGE := Color("#527b8d")
	const PANEL := Color("#0a1927f5")
	const ROLE_NAMES := ["수상전함", "강습항모", "포격전함", "보급수리함",
		"공성함", "요격기", "전자전함", "고속공격함"]
	var commander_font := SystemFont.new()
	var formations: Array[Node3D]
	var destinations: Dictionary[int, Vector3]
	var order_mode := Order.NONE
	var command_hits: Array[Rect2] = []
	var tactical := false
	var selected_index := -1
	var fleet_hits: Dictionary[int, Rect2] = {}
	var fleet_areas: Dictionary[int, Rect2] = {}
	var hull_bounds: Array[AABB]
	var show_move_preview := false
	var move_preview_start := Vector2.ZERO
	var move_preview_end := Vector2.ZERO
	var group_panel := Rect2()
	var details_panel := Rect2()
	var selected_bounds := Rect2()
	var motion: Array[FleetMotion]
	var flagship_view := false

	func _init() -> void:
		commander_font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR"])

	func _draw() -> void:
		fleet_hits.clear()
		fleet_areas.clear()
		command_hits.clear()
		group_panel = Rect2()
		details_panel = Rect2()
		selected_bounds = Rect2()
		if map_opacity > 0.0:
			draw_map()
		if show_move_preview:
			draw_brackets(move_preview_start, Vector2(9, 9))
			var direction := (move_preview_end - move_preview_start).normalized()
			var wing := direction.orthogonal() * 5.0
			if move_preview_start.distance_to(move_preview_end) >= FACING_DRAG_THRESHOLD:
				draw_line(move_preview_start, move_preview_end, INK, 1.5, true)
				draw_polyline(PackedVector2Array([move_preview_end - direction * 10.0 + wing,
					move_preview_end, move_preview_end - direction * 10.0 - wing]), INK, 1.5, true)
		var world_center := fleet.position + FLEET_FOCUS
		var center := camera.unproject_position(world_center)
		var extent := center.distance_to(camera.unproject_position(world_center + Vector3.BACK * 90.0))
		if not flagship_view and extent < 74.0 and not camera.is_position_behind(world_center):
			selected_bounds = Rect2(center - Vector2(20, 20), Vector2(40, 40))
			draw_circle(center, 16.0, PANEL)
			draw_arc(center, 16.0, 0.0, TAU, 32, INK, 2.0, true)
			var badge := fit_panel(center + Vector2(-215, 24), Vector2(186, 126))
			draw_line(center + Vector2(-12, 10), badge.position + Vector2(186, 0), EDGE, 1.0, true)
			group_panel = badge
			draw_rect(badge, PANEL)
			draw_rect(badge, EDGE, false)
			draw_crest(badge.position + Vector2(93, 22))
			draw_line(badge.position + Vector2(9, 42), badge.position + Vector2(177, 42), EDGE)
			for i in FORMATION_CENTERS.size():
				var bow := world_center + formations[i].global_basis.x * 24.0
				var heading := (camera.unproject_position(bow) - center).normalized()
				var icon := badge.position + Vector2(21 + (i % 5) * 36, 56 + floori(i / 5.0) * 38)
				draw_fleet_icon(icon, heading, i)
			draw_selection_panel()
			return

		for i in FORMATION_CENTERS.size():
			var formation_center := formations[i].global_position + FLEET_FOCUS
			if flagship_view and i == selected_index:
				formation_center = fleet.to_global(motion[i].positions[0])
			var area := Rect2()
			if not motion.is_empty():
				area = project_fleet_area(i)
				if area.intersects(get_viewport_rect()):
					fleet_areas[i] = area
			var point := camera.unproject_position(formation_center)
			var heading := (camera.unproject_position(formation_center + formations[i].global_basis.x) - point).normalized()
			if camera.is_position_behind(formation_center) or not get_viewport_rect().has_point(point):
				if not fleet_areas.has(i):
					continue
				point = area.intersection(get_viewport_rect()).get_center()
			if i == selected_index:
				draw_inspected(point, heading, i)
			else:
				draw_fleet_icon(point, heading, i)
		draw_selection_panel()

	func project_fleet_area(index: int) -> Rect2:
		var state := motion[index]
		var bounds := Rect2()
		var projected := false
		for i in roles.size():
			var hull := hull_bounds[roles[i]]
			var pose := fleet.global_transform * Transform3D(Basis(Vector3.UP, state.headings[i]), state.positions[i])
			for corner in 8:
				var world := pose * hull.get_endpoint(corner)
				if camera.is_position_behind(world):
					continue
				var point := camera.unproject_position(world)
				bounds = bounds.expand(point) if projected else Rect2(point, Vector2.ZERO)
				projected = true
		return bounds.grow(12.0) if projected else Rect2()

	func select_at(point: Vector2) -> bool:
		var index := nearest_hit(point, fleet_hits)
		if index == -1:
			index = nearest_hit(point, fleet_areas)
		if index == -1:
			return false
		selected_index = index
		order_mode = Order.NONE
		queue_redraw()
		return true

	func nearest_hit(point: Vector2, areas: Dictionary[int, Rect2]) -> int:
		var index := -1
		var distance := INF
		for candidate in areas:
			var area := areas[candidate]
			var candidate_distance := area.get_center().distance_squared_to(point)
			if area.has_point(point) and candidate_distance < distance:
				index = candidate
				distance = candidate_distance
		return index

	func draw_selection_panel() -> void:
		if selected_index < 0:
			return
		var size := Vector2(330, 283)
		var selected_hit: Rect2 = fleet_hits.get(selected_index, Rect2())
		if not selected_hit.has_area():
			return
		var reference := group_panel if group_panel.has_area() else selected_hit
		var obstacle := reference.merge(selected_bounds).grow(10.0)
		var screen := get_viewport_rect().grow(-8.0)
		var anchor := selected_hit.get_center()
		var sides := [Vector2(obstacle.position.x - size.x - 8, anchor.y - 38),
			Vector2(obstacle.end.x + 8, anchor.y - 38)]
		if screen.end.x - obstacle.end.x > obstacle.position.x - screen.position.x:
			sides.reverse()
		sides.append(Vector2(anchor.x - size.x * 0.5, obstacle.position.y - size.y - 8))
		sides.append(Vector2(anchor.x - size.x * 0.5, obstacle.end.y + 8))
		var panel := Rect2()
		for side in sides:
			var candidate := fit_panel(side, size)
			if screen.encloses(candidate) and not candidate.intersects(obstacle):
				panel = candidate
				break
		if not panel.has_area():
			return
		details_panel = panel
		var start := Vector2(clampf(panel.get_center().x, reference.position.x, reference.end.x),
			clampf(panel.get_center().y, reference.position.y, reference.end.y))
		var connector := Vector2(clampf(start.x, panel.position.x, panel.end.x),
			clampf(start.y, panel.position.y, panel.end.y))
		draw_line(start, connector, EDGE, 1.2, true)
		var origin := panel.position
		draw_rect(panel, PANEL)
		draw_rect(panel, EDGE, false)
		draw_line(origin, origin + Vector2(size.x, 0), INK, 1.5, true)
		draw_crest(origin + Vector2(30, 30))
		var commander := "주유 (예시)" if selected_index == INSPECTED_FORMATION else "미지정"
		draw_string(commander_font, origin + Vector2(58, 25), "오국  ·  %02d함대" % (selected_index + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 20, INK)
		draw_string(commander_font, origin + Vector2(58, 47), "사령관  %s" % commander,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#a7c8d5"))
		for i in offsets.size():
			var offset := offsets[i]
			var dot := origin + Vector2(258 - offset.x * 3.5, 29 + offset.z * 3.4)
			draw_circle(dot, 2.1 if i == 0 else 0.8, INK, true, -1.0, true)
		draw_line(origin + Vector2(15, 60), origin + Vector2(315, 60), EDGE)
		draw_string(commander_font, origin + Vector2(16, 84), "함선 %d척" % offsets.size(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 18, INK)
		draw_string(commander_font, origin + Vector2(164, 84), "기함 선도 · 3개 고도층",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)
		draw_line(origin + Vector2(15, 96), origin + Vector2(315, 96), EDGE)
		var counts: Array[int] = []
		counts.resize(ROLE_NAMES.size())
		counts.fill(0)
		for role in roles:
			counts[role] += 1
		for i in ROLE_NAMES.size():
			var position := origin + Vector2(16 + (i % 2) * 157, 116 + floori(i / 2.0) * 18)
			draw_string(commander_font, position, "%s  %d" % [ROLE_NAMES[i], counts[i]],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#a7c8d5"))
		draw_line(origin + Vector2(15, 181), origin + Vector2(315, 181), EDGE)
		var status := "이동 중" if destinations.has(selected_index) else "대기 중"
		if order_mode != Order.NONE:
			status = "지도에서 %s 목표 지점을 클릭하세요" % ORDER_LABELS[order_mode]
		draw_string(commander_font, origin + Vector2(16, 207), status,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 15, INK)



		for i in ORDER_LABELS.size():
			var button := Rect2(origin + Vector2(16 + i * 101, 227), Vector2(95, 36))
			command_hits.append(button)
			var armed := order_mode == i
			var available := tactical or i == Order.STOP
			var border := INK if armed else EDGE
			draw_rect(button, Color("#20495d") if armed else Color("#102a3a"))
			draw_rect(button, border, false)
			draw_string(commander_font, button.position + Vector2(0, 23), ORDER_LABELS[i],
				HORIZONTAL_ALIGNMENT_CENTER, 95, 16, INK if available else Color("#73909c"))

	func command_at(point: Vector2) -> int:
		for i in command_hits.size():
			if command_hits[i].has_point(point):
				return i
		return Order.NONE


	func fit_panel(position: Vector2, size: Vector2) -> Rect2:
		var limit := get_viewport_rect().size - size - Vector2(8, 8)
		return Rect2(position.clamp(Vector2(8, 8), limit.max(Vector2(8, 8))), size)

	func draw_fleet_icon(point: Vector2, heading: Vector2, index: int) -> void:
		# A 22 px screen-space carrier keeps the footprint constant as its hull rotates.
		fleet_hits[index] = Rect2(point - Vector2(14, 13), Vector2(28, 39))
		var selected := index == selected_index
		var rim := INK if selected else Color("#56899d")
		var light := Color("#e0faff") if selected else Color("#a0ddec")
		var wing := heading.orthogonal()
		var nose := point + heading * 8.0
		var left := point - heading * 5.5 + wing * 6.0
		var right := point - heading * 5.5 - wing * 6.0
		var stern := point - heading * 3.5
		var keel := point + heading * 1.4
		draw_circle(point + Vector2(1, 2), 11.0, Color("#03080ed9"), true, -1.0, true)
		draw_circle(point, 11.0, Color("#102c3d"), true, -1.0, true)
		draw_arc(point, 10.5, PI, TAU, 24, rim, 1.0, true)
		draw_arc(point, 10.5, 0, PI, 24, EDGE, 1.0, true)
		draw_colored_polygon(PackedVector2Array([nose, left, stern, right]), Color("#183b51"))
		draw_colored_polygon(PackedVector2Array([nose, left, stern, keel]), light)
		draw_colored_polygon(PackedVector2Array([nose, keel, stern, right]), Color("#488fa8"))
		draw_line(nose, keel, Color("#effcff"), 1.0, true)
		var number_position := point + Vector2(-10, 11)
		draw_rect(Rect2(number_position, Vector2(20, 14)), PANEL)
		draw_string(ThemeDB.fallback_font, number_position + Vector2(0, 11), "%02d" % (index + 1),
			HORIZONTAL_ALIGNMENT_CENTER, 20, 12, light)



	func draw_crest(point: Vector2) -> void:
		# This screen-space glyph stays 34 × 28 at every camera depth.
		var face := PackedVector2Array([Vector2(-17, -9), Vector2(-12, -14),
			Vector2(12, -14), Vector2(17, -9), Vector2(17, 9), Vector2(12, 14),
			Vector2(-12, 14), Vector2(-17, 9)])
		var colors := PackedColorArray([Color("#376b81"), Color("#437c8f"),
			Color("#437c8f"), Color("#2f5d72"), Color("#112737"), Color("#102231"),
			Color("#102231"), Color("#112737")])
		var outline := PackedVector2Array()
		for corner in face:
			outline.append(point + corner)
		var shadow := PackedVector2Array()
		for corner in outline:
			shadow.append(corner + Vector2(1, 3))
		draw_colored_polygon(shadow, Color("#040a11d9"))
		draw_polygon(outline, colors)
		outline.append(outline[0])
		draw_polyline(outline, Color("#84c1d3"), 1.0, true)
		draw_line(point + Vector2(-11, -11), point + Vector2(11, -11), Color("#c2ebf4"), 1.0, true)
		for row in [-4.0, 2.0]:
			var ridge := PackedVector2Array()
			var ridge_shadow := PackedVector2Array()
			for offset: Vector2 in [Vector2(-9, 2), Vector2(-4, -2), Vector2(0, 1),
				Vector2(4, -2), Vector2(9, 2)]:
				var vertex := point + offset + Vector2(0, row)
				ridge.append(vertex)
				ridge_shadow.append(vertex + Vector2(0, 1.4))
			draw_polyline(ridge_shadow, Color("#091c27"), 2.1, true)
			draw_polyline(ridge, Color("#d3f7ff"), 1.4, true)



	func draw_ticks(point: Vector2) -> void:
		for i in floori(offsets.size() / 10.0):
			draw_rect(Rect2(point + Vector2(i * 6, 0), Vector2(4, 2.5)), INK)

	func draw_brackets(point: Vector2, half: Vector2) -> void:
		for x in [-1.0, 1.0]:
			for y in [-1.0, 1.0]:
				var corner := point + Vector2(x, y) * half
				draw_polyline(PackedVector2Array([corner - Vector2(x * 8, 0),
					corner, corner - Vector2(0, y * 8)]), INK, 1.15, true)

	func draw_inspected(point: Vector2, heading: Vector2, index: int) -> void:
		if not get_viewport_rect().grow(40).has_point(point):
			return
		var bounds: Rect2 = fleet_areas.get(index, Rect2())
		if motion.is_empty():
			bounds = Rect2(point, Vector2.ZERO)
			for offset in offsets:
				var ship := formations[index].to_global(offset)
				if not camera.is_position_behind(ship):
					bounds = bounds.expand(camera.unproject_position(ship))
			bounds = bounds.grow(12)
		selected_bounds = bounds
		if map_opacity > 0.28:
			if bounds.has_area() and not motion.is_empty():
				draw_brackets(bounds.get_center(), bounds.size * 0.5)
			else:
				draw_brackets(point, Vector2(15, 14))
			draw_fleet_icon(point, heading, index)
			return

		var viewport_bounds := get_viewport_rect()
		if bounds.size.x > viewport_bounds.size.x * 0.8 or bounds.size.y > viewport_bounds.size.y * 0.8:
			draw_crest(point + Vector2(-30, -26))
			draw_fleet_icon(point, heading, index)
		else:
			draw_brackets(bounds.get_center(), bounds.size * 0.5)
			var label := fit_panel(bounds.position + Vector2(-76, 0), Vector2(73, 38)).position
			draw_crest(label + Vector2(17, 14))
			draw_fleet_icon(label + Vector2(52, 12), heading, index)
			if tactical:
				draw_ticks(label + Vector2(0, 33))
		if tactical and destinations.has(index):
			var target := fleet.to_global(destinations[index])
			if camera.is_position_behind(target):
				return
			var destination := camera.unproject_position(target)
			draw_dashed_line(point, destination, INK, 1.3, 8.0, true, true)
			draw_brackets(destination, Vector2(9, 9))



func _ready() -> void:
	camera_shots = GROUP_SHOTS
	if mouse_validation:
		camera_shots = GROUP_SHOTS.slice(0, 10)
		camera_shots.append([68.0, 103.0, 16.0, 1.8, 0.40, 1.0])
	camera_stages = GROUP_STAGES
	hud_title = "WU FLEET GROUP   /   10 FORMATIONS   /   600 SHIPS"
	overlay.free()
	overlay = GroupMap.new()
	asteroid_clearance = 76.0
	super._ready()
	paused = true
	if mouse_validation:
		get_window().title = "Wu Fleet Mouse Validation"
		get_window().focus_exited.connect(cancel_map_gestures)
		get_viewport().size_changed.connect(overlay.queue_redraw)


func build_fleet() -> bool:
	build_formation()
	if offsets.size() != 60 or roles.size() != offsets.size():
		push_error("Expected 60 ships per formation")
		return false
	add_child(fleet)
	for center in FORMATION_CENTERS:
		var formation_node := Node3D.new()
		formation_node.position = center
		fleet.add_child(formation_node)
		formations.append(formation_node)
		ship_batches.append([])
		if mouse_validation:
			motion.append(FleetMotion.new(formation_node, offsets, roles))
	var map := overlay as GroupMap
	map.formations = formations
	map.destinations = destinations
	map.motion = motion
	map.hull_bounds = role_bounds

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
		if mouse_validation:
			var scale_factor: float = LENGTHS[role] / hull_length
			var nozzles: Array[Vector4] = []
			collect_engine_nozzles(model, Transform3D.IDENTITY, scale_factor, nozzles)
			role_scales.append(scale_factor)
			role_bounds.append(AABB(bounds.position * scale_factor, bounds.size * scale_factor))
			role_nozzles.append(nozzles)
		model.free()
		if surfaces.is_empty():
			push_error("Missing renderable surfaces: " + PATHS[role])
			return false
		var mesh := ArrayMesh.new()
		for surface in surfaces.values():
			surface.commit(mesh)

		var ship_basis := Basis.IDENTITY.scaled(Vector3.ONE * LENGTHS[role] / hull_length)
		for formation_index in formations.size():
			var formation_node := formations[formation_index]
			var placements: Array[Vector3] = []
			for i in offsets.size():
				if roles[i] == role:
					placements.append(offsets[i])
			if placements.is_empty():
				ship_batches[formation_index].append(null)
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
			formation_node.add_child(batch)
			ship_batches[formation_index].append(multimesh)

	var count := 0
	for formation_node in formations:
		for batch in formation_node.get_children():
			count += (batch as MultiMeshInstance3D).multimesh.instance_count
	print("Wu fleet group: %d identical formations, %d ships" % [FORMATION_CENTERS.size(), count])
	if mouse_validation:
		build_engine_plumes()
	return count == 600


func collect_engine_nozzles(node: Node3D, parent: Transform3D,
		scale_factor: float, nozzles: Array[Vector4]) -> void:
	var pose := parent * node.transform
	if node is MeshInstance3D and node.mesh and "recessed ion core" in String(node.name).to_lower():
		var bounds: AABB = pose * node.get_aabb()
		var center := bounds.get_center() * scale_factor
		var radius := minf(bounds.size.y, bounds.size.z) * scale_factor * 0.5
		nozzles.append(Vector4(center.x, center.y, center.z, radius))
	for child in node.get_children():
		if child is Node3D:
			collect_engine_nozzles(child, pose, scale_factor, nozzles)


func build_engine_plumes() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;
uniform vec4 faction_tint : source_color;
varying float nozzle_weight;
void vertex() {
	nozzle_weight = clamp(VERTEX.y + 0.5, 0.0, 1.0);
}
void fragment() {
	ALBEDO = mix(faction_tint.rgb, vec3(1.0), pow(nozzle_weight, 5.0) * 0.55);
	ALPHA = nozzle_weight * nozzle_weight * 0.9;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("faction_tint", FACTION_COLORS[fleet_faction])
	var plume := CylinderMesh.new()
	plume.top_radius = 1.0
	plume.bottom_radius = 0.0
	plume.height = 1.0
	plume.radial_segments = 8
	plume.rings = 0
	plume.cap_top = false
	plume.cap_bottom = false
	plume.material = material
	var nozzle_count := 0
	for role in roles:
		nozzle_count += role_nozzles[role].size()
	for formation_node in formations:
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = plume
		instances.instance_count = nozzle_count
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = instances
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batch.hide()
		formation_node.add_child(batch)
		engine_plumes.append(batch)


func update_ship_poses(index: int) -> void:
	var state := motion[index]
	var anchor_inverse := formations[index].transform.affine_inverse()
	var role_instances := PackedInt32Array()
	role_instances.resize(PATHS.size())
	var plume_instance := 0
	var visible_thrust := false
	var plumes := engine_plumes[index].multimesh
	for ship in roles.size():
		var role := roles[ship]
		var pose := anchor_inverse * Transform3D(Basis(Vector3.UP, state.headings[ship]), state.positions[ship])
		var batch: MultiMesh = ship_batches[index][role]
		batch.set_instance_transform(role_instances[role],
			Transform3D(pose.basis.scaled(Vector3.ONE * role_scales[role]), pose.origin))
		role_instances[role] += 1
		var velocity := state.velocities[ship]
		var thrust := clampf(velocity.dot(Vector3.RIGHT.rotated(Vector3.UP, state.headings[ship])) / FleetMotion.CRUISE, 0.0, 1.0)
		visible_thrust = visible_thrust or thrust > 0.02
		for nozzle: Vector4 in role_nozzles[role]:
			var length: float = LENGTHS[role] * lerpf(0.05, 0.19, thrust)
			var plume_basis := Basis(Vector3.FORWARD, PI * 0.5).scaled(
				Vector3(length, nozzle.w, nozzle.w) * (1.0 if thrust > 0.02 else 0.0))
			var center := Vector3(nozzle.x - length * 0.5, nozzle.y, nozzle.z)
			plumes.set_instance_transform(plume_instance, pose * Transform3D(plume_basis, center))
			plume_instance += 1
	engine_plumes[index].visible = visible_thrust

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
	if mouse_validation:
		var map := overlay as GroupMap
		var index := maxi(0, map.selected_index)
		return FLEET_FOCUS.lerp(motion[index].positions[0], weight)
	return FLEET_FOCUS + formations[INSPECTED_FORMATION].position * weight


func build_lighting() -> void:
	super.build_lighting()
	for child in get_children():
		if child is WorldEnvironment:
			child.environment.ambient_light_energy = 0.49


func build_hud() -> void:
	super.build_hud()
	if mouse_validation:
		scrubber.hide()
		var controls := time_label.get_parent() as Control
		controls.mouse_filter = Control.MOUSE_FILTER_IGNORE
		(controls.get_parent() as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		var help := controls.get_child(1) as Label
		help.text = "Wheel  Zoom   ·   Middle drag  Pan   ·   Left click  Select   ·   Right click / drag  Move / Face   ·   Space  Pause / Resume   ·   Esc  Deselect"


func show_frame(at: float) -> void:
	if mouse_validation:
		at = camera_zoom
		(overlay as GroupMap).flagship_view = at >= 60.0
		show_camera_frame(at)
		camera.position += camera_pan
		update_simulation_status()
		time_label.text = "Zoom   %d%%" % roundi(100.0 * inverse_lerp(WIDE_ZOOM, CLOSE_ZOOM, at))
	else:
		super.show_frame(at)
	sun.light_specular = 0.60
	(overlay as GroupMap).tactical = mouse_validation or (at >= 17.0 and at < 51.0)
	overlay.transition_marker_weight = maxf(1.0 - smoothstep(18.0, 30.0, at),
		smoothstep(105.0, 115.0, at))


func _unhandled_input(event: InputEvent) -> void:
	if mouse_validation and handle_map_mouse(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var step := 1.5 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1.5
			var current_zoom := camera_zoom if mouse_validation else time
			seek_zoom(current_zoom + step * event.factor)
			get_viewport().set_input_as_handled()
			return
		var map := overlay as GroupMap
		if event.button_index == MOUSE_BUTTON_LEFT:
			var requested := map.command_at(event.position)
			if requested != Order.NONE:
				if requested == Order.STOP:
					stop_formation(map.selected_index)
					map.order_mode = Order.NONE
				elif map.tactical:
					map.order_mode = Order.MOVE if requested == Order.MOVE else Order.FACE
				map.queue_redraw()
				get_viewport().set_input_as_handled()
				return
			if map.details_panel.has_point(event.position):
				get_viewport().set_input_as_handled()
				return
			if map.tactical and map.order_mode != Order.NONE:
				if mouse_validation and map.group_panel.has_point(event.position):
					get_viewport().set_input_as_handled()
					return
				issue_map_order(map, event.position, map.order_mode)
				get_viewport().set_input_as_handled()
				return
			if map.select_at(event.position):
				get_viewport().set_input_as_handled()
				return
	if not mouse_validation:
		super._unhandled_input(event)


func handle_map_mouse(event: InputEvent) -> bool:
	var map := overlay as GroupMap
	if event is InputEventMouseMotion:
		if move_gesture_index >= 0:
			if event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
				map.move_preview_end = event.position
				map.queue_redraw()
			else:
				clear_move_gesture()
			return true
		if panning and not (event.button_mask & MOUSE_BUTTON_MASK_MIDDLE):
			panning = false
		if not panning:
			return false
		var height := formations[map.selected_index].global_position.y if map.selected_index >= 0 else 0.0
		var previous: Variant = map_position(event.position - event.relative, height)
		var current: Variant = map_position(event.position, height)
		if previous is Vector3 and current is Vector3:
			camera_pan += previous - current
			show_frame(camera_zoom)
		return true
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning = event.pressed
			return true
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if map.selected_index >= 0 and not panning:
					begin_move_gesture(map, event.position)
			elif move_gesture_index >= 0:
				finish_move_gesture(map, event.position)
			return true
	return false


func begin_move_gesture(map: GroupMap, point: Vector2) -> void:
	if map.details_panel.has_point(point) or map.group_panel.has_point(point):
		return
	var node := formations[map.selected_index]
	var hit: Variant = map_position(point, node.global_position.y)
	if not hit is Vector3:
		return
	move_gesture_index = map.selected_index
	move_gesture_start = point
	move_gesture_target = fleet.to_local(hit)
	map.show_move_preview = true
	map.move_preview_start = point
	map.move_preview_end = point
	map.queue_redraw()


func finish_move_gesture(map: GroupMap, point: Vector2) -> void:
	var index := move_gesture_index
	var node := formations[index]
	var facing: Variant = null
	if move_gesture_start.distance_to(point) >= FACING_DRAG_THRESHOLD:
		var hit: Variant = map_position(point, node.global_position.y)
		if hit is Vector3:
			var direction := fleet.to_local(hit) - move_gesture_target
			if Vector2(direction.x, direction.z).length_squared() > 0.000001:
				facing = atan2(-direction.z, direction.x)
	motion[index].move_to(node, move_gesture_target, facing)
	destinations[index] = move_gesture_target
	map.order_mode = Order.NONE
	clear_move_gesture()


func clear_move_gesture() -> void:
	move_gesture_index = -1
	var map := overlay as GroupMap
	map.show_move_preview = false
	map.queue_redraw()


func cancel_map_gestures() -> void:
	panning = false
	clear_move_gesture()


func map_position(point: Vector2, height: float) -> Variant:
	var origin := camera.project_ray_origin(point)
	var ray := camera.project_ray_normal(point)
	return Plane(Vector3.UP, height).intersects_ray(origin, ray)


func issue_map_order(map: GroupMap, point: Vector2, order: int) -> void:
	var index := map.selected_index
	var node := formations[index]
	var hit: Variant = map_position(point, node.global_position.y)
	if not hit is Vector3:
		return
	var target := fleet.to_local(hit)
	if order == Order.MOVE:
		if mouse_validation:
			motion[index].move_to(node, target)
		else:
			face_target(node, target)
		destinations[index] = target
	else:
		stop_formation(index)
		if mouse_validation:
			motion[index].face(node, target)
		else:
			face_target(node, target)
	map.order_mode = Order.NONE
	map.queue_redraw()


func update_simulation_status() -> void:
	stage_label.text = "Fleets paused" if simulation_paused else "Fleet command controls"


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if mouse_validation and event.keycode == KEY_SPACE:
			simulation_paused = not simulation_paused
			update_simulation_status()
			get_viewport().set_input_as_handled()
			return
		var stops := {KEY_1: 0.0, KEY_2: 10.0, KEY_3: 20.0, KEY_4: 60.0}
		if stops.has(event.keycode):
			seek_zoom(stops[event.keycode])
			get_viewport().set_input_as_handled()
			return
		if event.keycode == KEY_ESCAPE:
			if mouse_validation:
				cancel_map_gestures()
			var map := overlay as GroupMap
			if mouse_validation or map.order_mode == Order.NONE:
				map.selected_index = -1
			map.order_mode = Order.NONE
			map.queue_redraw()
			get_viewport().set_input_as_handled()
			return
	if not mouse_validation:
		super._unhandled_key_input(event)


func seek_zoom(at: float) -> void:
	if mouse_validation:
		camera_zoom = clampf(at, WIDE_ZOOM, CLOSE_ZOOM)
		show_frame(camera_zoom)
		return
	paused = true
	time = clampf(at, 0.0, 60.0)
	show_frame(time)


func stop_formation(index: int) -> void:
	destinations.erase(index)
	if mouse_validation:
		motion[index].stop()
		engine_plumes[index].hide()


func face_target(node: Node3D, target: Vector3) -> void:
	var difference := target - node.position
	if Vector2(difference.x, difference.z).length_squared() > 0.001:
		node.rotation.y = atan2(-difference.z, difference.x)


func _process(delta: float) -> void:
	if mouse_validation:
		if simulation_paused:
			return
		for index in motion.size():
			var state := motion[index]
			if state.moving:
				state.advance(formations[index], delta)
				update_ship_poses(index)
				if not state.moving:
					destinations.erase(index)
				if camera_zoom >= 60.0 and move_gesture_index < 0 and not panning and index == (overlay as GroupMap).selected_index:
					show_frame(camera_zoom)
				overlay.queue_redraw()
		return
	super._process(delta)
	for index in destinations.keys():
		var node := formations[index]
		var target := destinations[index]
		node.position = node.position.move_toward(target, COMMAND_SPEED * delta)
		if node.position.is_equal_approx(target):
			stop_formation(index)
	if is_instance_valid(overlay):
		overlay.queue_redraw()
