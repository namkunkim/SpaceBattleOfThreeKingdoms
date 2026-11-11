extends Control

const ZOOM_STEP := 1.45
const MAX_ZOOM := 16.0

var _region: Dictionary
var _cell_size := 200.0
var _battle_body := ""
var _planet_art: Dictionary
var _bounds: Rect2
var _center: Vector2
var _zoom := 1.0
var _density_glow: GradientTexture2D
var _overview_terrain: Texture2D
var _overview_bounds: Rect2
var _navigation: Dictionary
var _navigation_art: Texture2D
var _reference_sky: Texture2D
var _navigation_overview_art: Texture2D

func display(region: Dictionary, cell_size: float, battle_body := "") -> void:
	_region = region
	_cell_size = cell_size
	_battle_body = battle_body
	_bounds = Rect2(_point(region.boundary[0]), Vector2.ZERO)
	for vertex: Array in region.boundary:
		_bounds = _bounds.expand(_point(vertex))
	reset_zoom()
	_build_overview_terrain()
	_navigation = {}
	if not _battle_body.is_empty():
		var field := ProfileLoader.read_json("res://data/scenarios/base/red-cliffs-movement-field.json")
		_navigation = field.get("navigation", {})
		if not _navigation.is_empty():
			_navigation_art = load(str(field.overlay)) as Texture2D
			if _reference_sky == null:
				_reference_sky = load("res://assets/world_atlas/red-cliffs-reference-sky.jpg") as Texture2D
				_navigation_overview_art = load("res://assets/world_atlas/red-cliffs-navigation-overview.png") as Texture2D
	if _density_glow == null:
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.42, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.38), Color(1, 1, 1, 0)])
		_density_glow = GradientTexture2D.new()
		_density_glow.gradient = gradient
		_density_glow.fill = GradientTexture2D.FILL_RADIAL
		_density_glow.fill_from = Vector2(0.5, 0.5)
		_density_glow.fill_to = Vector2(1.0, 0.5)

func reset_zoom() -> bool:
	var changed := _zoom > 1.0
	_zoom = 1.0
	_center = _bounds.get_center()
	queue_redraw()
	return changed

func zoom_at(local: Vector2, zoom_in: bool) -> bool:
	if _region.is_empty() or (not zoom_in and _zoom <= 1.0):
		return false
	var base := _fit_scale()
	if base <= 0.0:
		return false
	var offset := local - size / 2.0
	var anchor := _center + offset / (base * _zoom)
	var next_zoom := clampf(_zoom * (ZOOM_STEP if zoom_in else 1.0 / ZOOM_STEP), 1.0, MAX_ZOOM)
	if next_zoom <= 1.001:
		reset_zoom()
	else:
		_zoom = next_zoom
		_center = anchor - offset / (base * _zoom)
		queue_redraw()
	return true

func _fit_scale() -> float:
	return minf((size.x - 60.0) / maxf(_bounds.size.x, 1.0), (size.y - 60.0) / maxf(_bounds.size.y, 1.0))

func _point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))

func _draw() -> void:
	if _region.is_empty():
		return
	var scale_factor := _fit_scale() * _zoom
	if scale_factor > 0.0:
		_draw_terrain(size / 2.0 - _center * scale_factor, scale_factor)

func _world_polygon() -> PackedVector2Array:
	var points := PackedVector2Array()
	for vertex: Array in _region.boundary:
		points.append(_point(vertex))
	return points

func _draw_terrain(origin: Vector2, scale_factor: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("050a13"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20804
	var detail := _zoom >= 1.8
	if not _navigation.is_empty() and _reference_sky != null:
		draw_texture_rect(_reference_sky, Rect2(Vector2.ZERO, size), false, Color(0.75, 0.80, 0.93) if detail else Color(0.39, 0.49, 0.68))
	else:
		for index in 520:
			var point := Vector2(rng.randf() * size.x, rng.randf() * size.y)
			var light := rng.randf_range(0.12, 0.65)
			draw_circle(point, rng.randf_range(0.35, 1.15), Color(0.65, 0.79, 0.95, light), true, -1, true)
	if not detail and _overview_terrain != null and _navigation.is_empty():
		var area := Rect2(origin + _overview_bounds.position * scale_factor, _overview_bounds.size * scale_factor)
		_draw_clipped_texture(_overview_terrain, area, Color.WHITE)
	if not _navigation.is_empty():
		# Put the existing solar coordinates inside the southern navigable opening.
		var solar := _point(_region.position)
		var extent := Vector2(maxf(_bounds.size.x, _bounds.size.y * 1.9), _bounds.size.y)
		var corner := solar - extent * Vector2(0.50, 0.69)
		var area := Rect2(origin + corner * scale_factor, extent * scale_factor)
		if detail and _navigation_art != null:
			_draw_clipped_texture(_navigation_art, area, Color.WHITE)
			_draw_navigation_terrain(area)
		elif _navigation_overview_art != null:
			_draw_clipped_texture(_navigation_overview_art, area, Color.WHITE)
	if detail:
		if _navigation.is_empty() or _navigation_art == null:
			_draw_local_terrain(origin, scale_factor, rng)
		_draw_orbital_dust(origin, scale_factor)
	_draw_bodies(origin, scale_factor)

func _draw_navigation_terrain(area: Rect2) -> void:
	for obstacle: Array in _navigation.blocked:
		var polygon := PackedVector2Array()
		for vertex: Array in obstacle:
			polygon.append(area.position + _point(vertex) * area.size)
		var screen := PackedVector2Array([Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)])
		for visible: PackedVector2Array in Geometry2D.intersect_polygons(polygon, screen):
			draw_colored_polygon(visible, Color("2368aa16"))

func _draw_local_terrain(origin: Vector2, scale_factor: float, rng: RandomNumberGenerator) -> void:
	var polygon := _world_polygon()
	for cell: Array in _region.density_preview:
		var world_center := _point(cell) + Vector2.ONE * _cell_size / 2.0
		if not Geometry2D.is_point_in_polygon(world_center, polygon):
			continue
		var center := origin + world_center * scale_factor
		var density := float(cell[2]) / 255.0
		var gas := float(cell[3]) / 255.0
		var spread := _cell_size * scale_factor
		if not Rect2(-Vector2.ONE * spread, size + Vector2.ONE * spread * 2.0).has_point(center):
			continue
		var tint := Color("9e7969").lerp(Color("709dcc"), gas)
		var footprint := Vector2(1.95, 1.30) * spread
		var halo := Rect2(center - footprint / 2.0, footprint)
		_draw_clipped_texture(_density_glow, halo, Color(tint, density * 0.36))
		rng.seed = hash(world_center)
		for dust in int(12 + density * 160):
			var offset := Vector2(rng.randfn(0, 0.40), rng.randfn(0, 0.21)) * spread
			var radius := rng.randf_range(3.0, 21.0) * scale_factor
			var opacity := density * rng.randf_range(0.035, 0.11)
			if Rect2(Vector2.ZERO, size).grow(-radius).has_point(center + offset):
				draw_circle(center + offset, radius, Color(tint, opacity), true, -1, true)
		rng.seed = hash(world_center) ^ 208
		for rock in int(6 + density * 55):
			var offset := Vector2(rng.randfn(0, 0.38), rng.randfn(0, 0.25)) * spread
			_draw_rock(center + offset, rng.randf_range(2.0, 15.0) * scale_factor, rng)
func _draw_bodies(origin: Vector2, scale_factor: float) -> void:
	for body: Dictionary in _region.bodies:
		var point := origin + _point(body.position) * scale_factor
		var diameter := clampf(_body_diameter(body) * scale_factor, 3.0, 52.0)
		if not Rect2(Vector2.ZERO, size).grow(-diameter).has_point(point):
			continue
		if body.kind == "star":
			for i in range(11, 0, -1):
				draw_circle(point, diameter * (0.3 + float(i) / 15.0), Color(1.0, 0.69, 0.32, 0.036), true, -1, true)
			draw_circle(point, diameter * 0.26, Color("fff1c7"), true, -1, true)
			continue
		var art := _planet_texture(body)
		var extent := Vector2.ONE * diameter
		draw_texture_rect(art, Rect2(point - extent / 2.0, extent), false)

func _draw_clipped_texture(texture: Texture2D, area: Rect2, tint: Color) -> void:
	var clipped := area.intersection(Rect2(Vector2.ZERO, size))
	if not clipped.has_area():
		return
	var texture_size := texture.get_size()
	var source := Rect2((clipped.position - area.position) / area.size, clipped.size / area.size)
	source.position *= texture_size
	source.size *= texture_size
	draw_texture_rect_region(texture, clipped, source, tint)

func _build_overview_terrain() -> void:
	_overview_terrain = null
	var samples := {}
	var polygon := _world_polygon()
	for cell: Array in _region.density_preview:
		var corner := _point(cell)
		if Geometry2D.is_point_in_polygon(corner + Vector2.ONE * _cell_size / 2.0, polygon):
			var key := Vector2i((corner / _cell_size).floor())
			samples[key] = Vector2(float(cell[2]), float(cell[3])) / 255.0
	if samples.is_empty():
		return
	_overview_bounds = _bounds.grow(_cell_size)
	var dimensions := Vector2i((_overview_bounds.size / maxf(_overview_bounds.size.x, _overview_bounds.size.y) * 300.0).ceil())
	dimensions = dimensions.max(Vector2i(2, 2))
	var image := Image.create_empty(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	for y in dimensions.y:
		for x in dimensions.x:
			var world := _overview_bounds.position + (Vector2(x + 0.5, y + 0.5) / Vector2(dimensions)) * _overview_bounds.size
			var cell := world / _cell_size
			var base := Vector2i(cell.floor())
			var density := 0.0
			var gas := 0.0
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var key := base + Vector2i(dx, dy)
					if not samples.has(key):
						continue
					var delta := (cell - Vector2(key) - Vector2(0.5, 0.5)) / Vector2(1.90, 0.76)
					var weight := exp(-delta.length_squared() * 1.7)
					var material: Vector2 = samples[key]
					density += material.x * weight
					gas += material.y * weight
			density *= 1.0 + 0.065 * sin(cell.x * 8.0 + sin(cell.y * 5.0)) + 0.04 * sin(cell.y * 13.0 + cell.x * 4.0)
			var edge := smoothstep(0.172, 0.211, density)
			if edge <= 0.001:
				continue
			var inner := smoothstep(0.23, 0.84, density)
			var palette := Color("12488d").lerp(Color("328cce"), clampf(gas / maxf(density, 0.01), 0.0, 1.0))
			var contour := smoothstep(0.176, 0.204, density) * (1.0 - smoothstep(0.213, 0.265, density))
			palette = palette.lerp(Color("73c7fa"), maxf(contour * 0.52, inner * 0.48))
			palette.a = edge * lerpf(0.60, 0.92, inner)
			image.set_pixel(x, y, palette)
	_overview_terrain = ImageTexture.create_from_image(image)

func _draw_orbital_dust(origin: Vector2, scale_factor: float) -> void:
	var environment: Dictionary = _region.get("local_environment", {})
	if environment.is_empty():
		return
	var center := _point(environment.position)
	var radius := float(environment.radius)
	var density: Array = environment.density_percent
	var rng := RandomNumberGenerator.new()
	rng.seed = int(environment.seed)
	var lanes: Array = _region.get("navigation_lanes", [])
	for index in roundi((float(density[0]) + float(density[1])) * 25.0):
		var angle := rng.randf() * TAU
		var radial := sqrt(rng.randf()) * radius
		var world := center + Vector2.from_angle(angle) * radial
		if _in_navigation_clearance(world, lanes):
			continue
		var point := origin + world * scale_factor
		var tint := Color(0.56, 0.65, 0.74, rng.randf_range(0.075, 0.24))
		var grain := rng.randf_range(0.8, 3.6) * scale_factor
		if Rect2(Vector2.ZERO, size).grow(-grain).has_point(point):
			draw_circle(point, grain, tint, true, -1, true)
		if rng.randf() < 0.15:
			_draw_rock(point, rng.randf_range(1.4, 4.5) * scale_factor, rng)

func _in_navigation_clearance(world: Vector2, lanes: Array) -> bool:
	for lane: Dictionary in lanes:
		var points: Array = lane.points
		for index in range(1, points.size()):
			var nearest := Geometry2D.get_closest_point_to_segment(world, _point(points[index - 1]), _point(points[index]))
			if nearest.distance_to(world) <= float(lane.half_width):
				return true
	return false

func _draw_rock(at: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
	var points := PackedVector2Array()
	for index in 6:
		var direction := Vector2.from_angle(float(index) * TAU / 6.0)
		points.append(at + direction * rng.randf_range(0.65, 1.25) * radius)
	var shade := Color("272630").lerp(Color("655d59"), rng.randf())
	if not Rect2(Vector2.ZERO, size).grow(-radius * 1.25).has_point(at):
		return
	draw_colored_polygon(points, shade)
	draw_colored_polygon(PackedVector2Array([points[3], points[4], points[5], at + Vector2(-radius * 0.14, 0)]), shade.lightened(0.20))
	draw_line(points[3], points[4], Color("aa9986"), 0.65, true)

func _body_diameter(body: Dictionary) -> float:
	if body.id == _battle_body:
		return 33.0
	if str(body.id).ends_with("JUPITER"):
		return 49.0
	if body.kind == "star":
		return 44.0
	return 12.0 if body.kind == "moon" else 20.0

func _planet_texture(body: Dictionary) -> Texture2D:
	var id := str(body.id)
	if _planet_art.has(id):
		return _planet_art[id]
	var color := Color("7e7b77")
	if body.kind == "terran":
		color = Color("3e80af")
	elif id.ends_with("JUPITER"):
		color = Color("c8a17b")
	elif id.ends_with("VENUS"):
		color = Color("d1a66f")
	elif id.ends_with("-02"):
		color = Color("b56347")
	var image := Image.create_empty(48, 48, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = id.hash()
	noise.frequency = 0.16
	for y in 48:
		for x in 48:
			var point := (Vector2(x, y) + Vector2(0.5, 0.5)) / 24.0 - Vector2.ONE
			var squared := point.length_squared()
			if squared >= 1.0:
				continue
			var height := sqrt(1.0 - squared)
			var light := clampf(-0.58 * point.x - 0.5 * point.y + 0.64 * height, 0.0, 1.0)
			var material := color
			var grain := noise.get_noise_2d(x, y)
			if body.kind == "terran":
				if grain > 0.09:
					material = Color("809678")
				if noise.get_noise_2d(x + 30.0, y * 2.4) > 0.22:
					material = material.lerp(Color("dce9f0"), 0.73)
			elif id.ends_with("JUPITER"):
				material = material.lerp(Color("e7d2ac"), 0.28 + sin(y * 1.3 + grain) * 0.19)
			var pixel := material * (0.16 + light * (0.8 + grain * 0.18))
			if body.kind == "terran":
				pixel = pixel.lerp(Color("70afd3"), pow(1.0 - height, 3.0) * light * 0.5)
			pixel.a = clampf((1.0 - squared) * 19.0, 0.0, 1.0)
			image.set_pixel(x, y, pixel)
	var texture := ImageTexture.create_from_image(image)
	_planet_art[id] = texture
	return texture
