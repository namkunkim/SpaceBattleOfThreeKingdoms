extends Control

const SAMPLE_SIZE := Vector2(500, 282)
const ATLAS_SIZE := Vector2(6144, 2969)
# Fallback when the reference layout cannot be loaded.
const WORLD_CENTER := Vector2(19400, 14900)
const WORLD_HEIGHT := 24400.0

# Representative planet portraits sampled from the original charts, at 500×282 scale.
const PORTRAITS := [
	["하동", 8], ["허", 9], ["태산", 9], ["동래", 9], ["하비", 8],
	["발해", 9], ["어양", 8], ["진양", 9], ["장안서부", 8], ["돈황", 8],
	["성도", 9], ["남정", 9], ["구지", 9], ["완", 9], ["건업", 8],
	["수춘", 9], ["교지", 9], ["양평", 9], ["월수", 9],
]

const CORRIDOR_NAMES := {
	"RTE-006": "함곡회랑", "RTE-014": "관도관문",
	"RTE-019": "정형회랑", "RTE-021": "노룡회랑",
	"RTE-026": "무관회랑", "RTE-027": "검각회랑",
	"RTE-028": "이릉협도", "RTE-029": "남중산도", "RTE-035": "합비회랑",
}

var show_interstellar := true
var _interstellar_paths: Array[Dictionary] = []
var _local_data: Dictionary
var _geography: Dictionary
var _reference: Dictionary
var _reference_center := Vector2.ZERO
var _reference_scale := 0.0
var _system_points := {}
var _portraits := {}
var _lines: Array[PackedVector2Array] = []
var _markers: Array[Dictionary] = []
var _systems: Array[Dictionary] = []
var _route_names: Array[Dictionary] = []

func configure(local_data: Dictionary, geography: Dictionary, reference: Dictionary, world: Dictionary) -> void:
	_local_data = local_data
	_geography = geography
	_reference = reference
	_fit_reference(world)
	for system: Dictionary in world.get("systems", []):
		var position := _system_point(system.id, _point(system.pos))
		_system_points[system.id] = position
		_systems.append({"name": system.name, "point": position})
		_cache_portrait(system.id)
		_add_system(system.id)
	for label: String in _geography.get("gates", {}):
		_route_names.append({"name": label, "point": project(_point(_geography.gates[label]))})
	for route: Dictionary in world.get("routes", []):
		_add_interstellar_path(route)

func project(world_point: Vector2) -> Vector2:
	if _reference_scale > 0.0:
		return _place_reference(_reference_pixel(world_point))
	var extent := Vector2(WORLD_HEIGHT * ATLAS_SIZE.aspect(), WORLD_HEIGHT)
	return (world_point - WORLD_CENTER) / extent + Vector2(0.5, 0.5)

func _place_reference(point: Vector2) -> Vector2:
	return (point - _reference_center) * _reference_scale / ATLAS_SIZE + Vector2(0.5, 0.5)

func _fit_reference(world: Dictionary) -> void:
	if _reference.get("affine", []).size() != 2:
		return
	var bounds := Rect2(_reference_pixel(WORLD_CENTER), Vector2.ZERO)
	for system: Dictionary in world.get("systems", []):
		bounds = bounds.expand(_reference_pixel(_point(system.pos)))
	for id: String in _geography.get("cities", {}):
		for label: String in _geography.cities[id]:
			var marker := reference_marker(id, label)
			var pixel := _point(marker.point) if not marker.is_empty() else _reference_pixel(_point(_geography.cities[id][label].position))
			bounds = bounds.expand(pixel)
	for gate: Array in _geography.get("gates", {}).values():
		bounds = bounds.expand(_reference_pixel(_point(gate)))
	for route: Dictionary in world.get("routes", []):
		for point: Array in route.get("line", []):
			bounds = bounds.expand(_reference_pixel(_point(point)))
	if bounds.has_area():
		_reference_center = bounds.get_center()
		_reference_scale = minf(ATLAS_SIZE.x * 0.91 / bounds.size.x, ATLAS_SIZE.y * 0.87 / bounds.size.y)

func _reference_pixel(world_point: Vector2) -> Vector2:
	var baseline := _affine_pixel(world_point)
	var displacement := Vector2.ZERO
	var total := 0.0
	for anchor: Dictionary in _reference.get("supports", []):
		var source := _point(anchor.world)
		var target := _point(anchor.point)
		var distance := source.distance_squared_to(world_point)
		if distance <= 0.01:
			return target
		var weight := 1.0 / pow(distance + 160000.0, 1.45)
		displacement += (target - _affine_pixel(source)) * weight
		total += weight
	return baseline + displacement / total if total > 0.0 else baseline

func _affine_pixel(world_point: Vector2) -> Vector2:
	var x: Array = _reference.affine[0]
	var y: Array = _reference.affine[1]
	return Vector2(
		x[0] + x[1] * world_point.x + x[2] * world_point.y,
		y[0] + y[1] * world_point.x + y[2] * world_point.y
	)

func reference_marker(id: String, label: String) -> Dictionary:
	return _reference.get("cities", {}).get(id, {}).get(label, {})

func map_location(id: String, label: String, world_point: Vector2) -> Vector2:
	var marker := reference_marker(id, label)
	if _reference_scale > 0.0 and not marker.is_empty():
		return _place_reference(_point(marker.point))
	return project(world_point)

func _system_point(id: String, world_point: Vector2) -> Vector2:
	for label: String in _reference.get("cities", {}).get(id, {}):
		var location := geographic_location(id, label)
		if not location.is_empty() and _point(location.position).distance_squared_to(world_point) <= 0.01:
			return map_location(id, label, world_point)
	return project(world_point)

func geographic_location(id: String, label: String) -> Dictionary:
	var city: Dictionary = _geography.get("cities", {}).get(id, {}).get(label, {})
	if not city.is_empty():
		return city
	var local_gates: Dictionary = _local_data.get(id, {}).get("gates", {})
	if local_gates.has(label) and _geography.get("gates", {}).has(label):
		return {"position": _geography.gates[label], "basis": "corridor-anchor"}
	return {}

func _add_system(id: String) -> void:
	var local: Dictionary = _local_data.get(id, {})
	var local_points: Dictionary = local.get("nodes", {}).duplicate()
	local_points.merge(local.get("gates", {}))
	var locations := {}
	for name: String in local_points:
		var location := geographic_location(id, name)
		if not location.is_empty():
			locations[name] = map_location(id, name, _point(location.position))
	var index := id.get_slice("-", 1).to_int() - 1
	for name: String in local.get("nodes", {}):
		if not locations.has(name):
			continue
		var city := geographic_location(id, name)
		_markers.append({
			"point": locations[name], "name": city.get("name", name),
			"portrait": _portraits.get(id) if name == PORTRAITS[index][0] else null,
		})
	for path: Array in local.get("paths", []):
		var previous := ""
		var samples := PackedVector2Array()
		for stop: Variant in path:
			if stop is Array:
				if not previous.is_empty():
					samples.append(_point(stop))
				continue
			if not locations.has(stop):
				continue
			if not previous.is_empty():
				var start: Vector2 = locations[previous]
				var end: Vector2 = locations[stop]
				var trace := PackedVector2Array([start])
				_append_path_samples(trace, samples, _point(local_points[previous]), _point(local_points[stop]), start, end)
				trace.append(end)
				_lines.append(trace)
			previous = stop
			samples.clear()

func _append_path_samples(
		line: PackedVector2Array, samples: PackedVector2Array,
		source_start: Vector2, source_end: Vector2, start: Vector2, end: Vector2
) -> void:
	var axis := source_end - source_start
	var length_squared := axis.length_squared()
	if is_zero_approx(length_squared):
		return
	var cross := axis.orthogonal()
	var span := end - start
	for sample in samples:
		var offset := sample - source_start
		var along := clampf(offset.dot(axis) / length_squared, 0.0, 1.0)
		var side := clampf(offset.dot(cross) / length_squared, -0.20, 0.20)
		line.append(start + span * along + span.orthogonal() * side)

func _add_interstellar_path(route: Dictionary) -> void:
	var line := PackedVector2Array()
	for point: Array in route.get("line", []):
		line.append(project(_point(point)))
	if line.size() >= 2:
		var first: Vector2 = _system_points.get(route.a, line[0])
		var last: Vector2 = _system_points.get(route.b, line[-1])
		var start_offset := first - line[0]
		var end_offset := last - line[-1]
		for index in line.size():
			line[index] += start_offset.lerp(end_offset, float(index) / (line.size() - 1))
		_interstellar_paths.append({
			"id": route.id, "line": line, "kind": route.kind, "yangtze": route.yangtze,
			"from": route.a, "to": route.b,
		})

func _point(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])

static func corridor_name(route: Dictionary, names: Dictionary) -> String:
	var id: String = route.get("id", "")
	if CORRIDOR_NAMES.has(id):
		return CORRIDOR_NAMES[id]
	return "%s–%s %s" % [names.get(route.a, route.a), names.get(route.b, route.b), id]

func _cache_portrait(id: String) -> void:
	var index := id.get_slice("-", 1).to_int() - 1
	if index < 0 or index >= PORTRAITS.size():
		return
	var definition: Array = PORTRAITS[index]
	var local: Dictionary = _local_data.get(id, {})
	var nodes: Dictionary = local.get("nodes", {})
	if not nodes.has(definition[0]):
		return
	var source := load("res://assets/world_atlas/%s.jpg" % id) as Texture2D
	if source == null:
		return
	var image := source.get_image()
	if image == null:
		return
	var scale_to_image := Vector2(image.get_size()) / SAMPLE_SIZE
	var center := _point(nodes[definition[0]]) * scale_to_image
	var radius := Vector2.ONE * float(definition[1]) * scale_to_image
	_portraits[id] = ImageTexture.create_from_image(
		image.get_region(Rect2i(Vector2i(center - radius), Vector2i(radius * 2.0)))
	)

func _draw() -> void:
	if show_interstellar:
		for route in _interstellar_paths:
			var color := Color(0.37, 0.69, 0.76, 0.45)
			if route.yangtze:
				color = Color(0.40, 0.87, 0.83, 0.80)
			elif route.kind == "회랑" or route.kind.begins_with("고속항로"):
				color = Color(0.88, 0.63, 0.32, 0.66)
			_draw_trace(route.line, color, 1.3)
	for trace in _lines:
		_draw_trace(trace, Color(0.63, 0.80, 0.85, 0.67), 1.1)
	for marker in _markers:
		var center: Vector2 = marker.point * size
		if marker.portrait == null:
			draw_circle(center, 2.1, Color("e5f1ef"), true, -1, true)
		else:
			_draw_portrait(marker.portrait, center)

	var occupied: Array[Rect2] = []
	for system in _systems:
		_draw_name(system.name, system.point * size + Vector2(0, 23), 15, Color("a5d9e5"), occupied)
	for gate in _route_names:
		_draw_name(gate.name, gate.point * size - Vector2(0, 6), 11, Color("e1bf86"), occupied)
	for marker in _markers:
		var clearance := 12.0 if marker.portrait != null else 5.0
		_draw_name(marker.name, marker.point * size - Vector2(0, clearance), 12, Color("f1f4eb"), occupied)

func _draw_trace(trace: PackedVector2Array, color: Color, width: float) -> void:
	var scaled := PackedVector2Array()
	for point in trace:
		scaled.append(point * size)
	draw_polyline(scaled, color, width, true)

func _draw_name(label: String, point: Vector2, font_size: int, color: Color, occupied: Array[Rect2]) -> void:
	var width := UiDraw.text_w(label, "regular", font_size) + 6.0
	for offset: Vector2 in [Vector2.ZERO, Vector2(0, 29), Vector2(15, 0), Vector2(-15, 0), Vector2(20, 23), Vector2(-20, 23)]:
		var baseline := point + offset
		var bounds := Rect2(baseline - Vector2(width * 0.5, font_size), Vector2(width, font_size + 4.0))
		if not Rect2(Vector2.ZERO, size).encloses(bounds):
			continue
		if occupied.any(func(other: Rect2) -> bool: return other.intersects(bounds)):
			continue
		occupied.append(bounds)
		UiDraw.text(self, baseline, label, "regular", font_size, color, HORIZONTAL_ALIGNMENT_CENTER, 0.0, 3)
		break

func _draw_portrait(portrait: Texture2D, center: Vector2) -> void:
	var radius := 8.0
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 32:
		var direction := Vector2.from_angle(TAU * i / 32.0)
		vertices.append(center + direction * radius)
		uvs.append((direction + Vector2.ONE) * 0.5)
	draw_polygon(vertices, PackedColorArray([Color.WHITE]), uvs, portrait)
	draw_arc(center, radius + 0.8, 0.0, TAU, 32, Color(0.66, 0.86, 0.86, 0.65), 0.8, true)
