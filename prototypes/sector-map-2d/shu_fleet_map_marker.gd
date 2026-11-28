extends RefCounted

enum FleetSize { SMALL, MEDIUM, LARGE }
enum Formation { COLUMN, WEDGE, FISH_SCALE, CIRCLE, CRANE_WING }

# Role indices follow HULLS in shu_fleet_movement.gd.
const ROLES := [[0, 5, 7], [0, 2, 3, 5, 7], [1, 0, 2, 4, 6, 3, 5, 7]]
const LAYOUTS := [
	[Vector2.ZERO, Vector2(-0.8, -1.0), Vector2(-0.8, 1.0)],
	[Vector2.ZERO, Vector2(-0.7, -1.2), Vector2(-0.8, 1.2),
		Vector2(-1.9, -0.7), Vector2(-1.9, 0.7)],
	[Vector2.ZERO, Vector2(-0.1, -1.5), Vector2(-0.1, 1.5),
		Vector2(-1.7, -1.1), Vector2(-1.7, 1.1), Vector2(-1.6, 0.0),
		Vector2(1.5, -0.9), Vector2(1.5, 0.9)],
]
const DIAMETERS := [76.0, 91.0, 110.0]
const VIEWS := [4.2, 5.2, 6.0]
const GLYPH_OFFSET := 13.0
const EXTRA_HULLS := [4, 6, 8]
const THUMB_SIZE := 22.0
const THUMB_VIEW_SPAN := 2.25

var viewport: SubViewport
var diameter: float
var footprint := Rect2()
var roster_roles: Array[int]
var roster_textures: Array[ViewportTexture] = []


func _init(parent: Node, fleet_size: FleetSize, ship_roles: Array[int], ships: Array[Dictionary]) -> void:
	diameter = DIAMETERS[fleet_size]
	viewport = _create_preview(parent, VIEWS[fleet_size], 192)

	var lineup: Array = ROLES[fleet_size]
	for i in lineup.size():
		var ship := ships[ship_roles.find(lineup[i])]
		var model := MeshInstance3D.new()
		model.mesh = ship.mesh.mesh
		var offset: Vector2 = LAYOUTS[fleet_size][i]
		var transform: Transform3D = ship.model
		if fleet_size == FleetSize.LARGE and i == 0:
			transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.18), Vector3.ZERO) * transform
		transform.origin += Vector3(offset.x, 0.0, offset.y)
		var bounds := transform * model.mesh.get_aabb()
		var pixels: float = diameter / VIEWS[fleet_size]
		var rect := Rect2(Vector2(bounds.position.x, bounds.position.z) * pixels,
			Vector2(bounds.size.x, bounds.size.z) * pixels)
		footprint = footprint.merge(rect) if footprint.has_area() else rect
		model.transform = transform
		viewport.add_child(model)
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	_build_roster(parent, lineup, EXTRA_HULLS[fleet_size], ship_roles, ships)



func _build_roster(parent: Node, lineup: Array, count: int, roles: Array[int],
		ships: Array[Dictionary]) -> void:
	for i in count:
		roster_roles.append(lineup[i % lineup.size()])
	roster_textures.resize(ROLES[FleetSize.LARGE].size())
	for role in roster_textures.size():
		var preview := _create_preview(parent, THUMB_VIEW_SPAN, 64)
		var source := ships[roles.find(role)]
		var hull := MeshInstance3D.new()
		hull.mesh = source.mesh.mesh
		hull.transform = source.model
		preview.add_child(hull)
		roster_textures[role] = preview.get_texture()
		preview.render_target_update_mode = SubViewport.UPDATE_ONCE


func _roster_point(index: int, hull: Rect2, scale_factor: float) -> Vector2:
	# Place each new pair on opposite sides of the image.
	var capacity := roster_roles.size()
	var seat := (index >> 1) + (index % 2) * (capacity >> 1)
	var angle := TAU * float(seat) / capacity
	var radius := maxf(hull.size.length() * 0.5 + 10.0 * scale_factor, 36.0 * scale_factor)
	return hull.get_center() + Vector2.from_angle(angle) * radius



func roster_area(hull: Rect2, scale_factor: float, count: int) -> Rect2:
	var area := hull
	var half := Vector2.ONE * THUMB_SIZE * scale_factor * 0.5
	for i in count:
		var point := _roster_point(i, hull, scale_factor)
		area = area.merge(Rect2(point - half, half * 2.0))
	return area



static func _create_preview(parent: Node, view_span: float, resolution: int) -> SubViewport:
	var preview := SubViewport.new()
	preview.size = Vector2i(resolution, resolution)
	preview.own_world_3d = true
	preview.transparent_bg = true
	preview.msaa_3d = Viewport.MSAA_2X
	parent.add_child(preview)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("#e1efff")
	environment.environment.ambient_light_energy = 0.85
	preview.add_child(environment)
	var lamp := DirectionalLight3D.new()
	lamp.rotation_degrees = Vector3(-60.0, 28.0, 0.0)
	lamp.light_energy = 1.5
	preview.add_child(lamp)
	var camera := Camera3D.new()
	preview.add_child(camera)
	camera.transform = Transform3D(Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP), Vector3.UP * 12.0)
	camera.set_orthogonal(view_span, 0.1, 30.0)
	camera.make_current()
	return preview


func hull_area(center: Vector2, yaw: float, scale_factor: float) -> Rect2:
	return Transform2D(yaw, Vector2.ONE * scale_factor, 0.0, center) * footprint


func hit_area(center: Vector2, yaw: float, scale_factor: float, count: int) -> Rect2:
	var area := roster_area(hull_area(center, yaw, scale_factor), scale_factor, count)
	var glyph := Rect2(_symbol_position(center, area) - Vector2(9.0, 9.0), Vector2(18.0, 18.0))
	return area.merge(glyph).grow(7.0)


func _symbol_position(center: Vector2, hull: Rect2) -> Vector2:
	return Vector2(center.x, hull.position.y - GLYPH_OFFSET)


func draw(canvas: Node2D, center: Vector2, yaw: float, formation: Formation,
		scale_factor: float, alpha: float, count: int) -> void:
	canvas.draw_set_transform(center, yaw, Vector2.ONE * scale_factor)
	var size := Vector2.ONE * diameter
	canvas.draw_texture_rect(viewport.get_texture(), Rect2(-size * 0.5, size), false,
		Color(1.0, 1.0, 1.0, alpha))
	canvas.draw_set_transform(Vector2.ZERO)
	var hull := hull_area(center, yaw, scale_factor)
	var thumb := Vector2.ONE * THUMB_SIZE * scale_factor
	for i in count:
		var point := _roster_point(i, hull, scale_factor)
		canvas.draw_set_transform(point, yaw)
		canvas.draw_texture_rect(roster_textures[roster_roles[i]], Rect2(-thumb * 0.5, thumb),
			false, Color(1.0, 1.0, 1.0, alpha))
	canvas.draw_set_transform(Vector2.ZERO)
	_draw_symbol(canvas, _symbol_position(center, roster_area(hull, scale_factor, count)), formation, alpha)


func _draw_symbol(canvas: Node2D, point: Vector2, formation: Formation, alpha: float) -> void:
	var ink := Color(1.0, 1.0, 1.0, alpha)
	var triangle := PackedVector2Array([point + Vector2(0, -7),
		point + Vector2(8, 7), point + Vector2(-8, 7)])
	match formation:
		Formation.COLUMN:
			canvas.draw_line(point + Vector2(0, -8), point + Vector2(0, 8), ink, 2.5, true)
		Formation.WEDGE:
			triangle.append(triangle[0])
			canvas.draw_polyline(triangle, ink, 2.0, true)
		Formation.FISH_SCALE:
			canvas.draw_colored_polygon(triangle, ink)
		Formation.CIRCLE:
			canvas.draw_circle(point, 7.0, ink, false, 2.0, true)
			canvas.draw_circle(point, 2.5, ink, true, -1, true)
		Formation.CRANE_WING:
			canvas.draw_arc(point - Vector2(0, 3), 8.0, 0.0, PI, 24, ink, 2.4, true)