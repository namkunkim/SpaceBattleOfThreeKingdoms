extends Control
# Read-only presentation of existing navigation and approved operation data.
# Never creates a battle host, writes coordinates, or advances simulation.
@export var detailed := false
var local_context := false
var story_focus: Array = []
const Sites := preload("res://view/world/red_cliffs_sites.gd")
const ATLAS := "res://data/galaxy_navigation.json"
const OPERATION := "res://data/scenarios/p05_p07_first_operation_dev_v1.json"
const SKY := "res://assets/world_atlas/red-cliffs-reference-sky.jpg"
const GALAXY := "res://assets/world_atlas/galaxy_navigation_terrain.png"
const TERRAIN := "res://assets/world_atlas/red-cliffs-terrain.png"
var data: Dictionary = {}
var sky: Texture2D
var terrain: Texture2D
var failure := ""
var prepared := false
var compact_scale := 1.0:
	set(value):
		compact_scale = value
		queue_redraw()
const GOLD := Color("#e6c18c")
const CYAN := Color("#8cddd9")
const MUTED := Color("#8a9cab")

const DataCheck := preload("res://scripts/entry/entry_map_data.gd")

func prepare() -> bool:
	# Invalidate previous success first. Failed reloads must never retain a map.
	prepared = false
	data = {}
	sky = null
	terrain = null
	failure = ""
	queue_redraw()
	var path := OPERATION if detailed else ATLAS
	if not FileAccess.file_exists(path):
		failure = "지도 정보를 찾을 수 없습니다."
		return false
	var candidate: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var invalid := DataCheck.validate(candidate, detailed)
	if not invalid.is_empty():
		failure = "지도 정보가 올바르지 않습니다: " + invalid
		return false
	var background := SKY if detailed else GALAXY
	if not ResourceLoader.exists(background, "Texture2D"):
		failure = "지도 배경을 불러올 수 없습니다."
		return false
	var next_sky := load(background) as Texture2D
	var next_terrain: Texture2D = null
	if detailed:
		if not ResourceLoader.exists(TERRAIN, "Texture2D"):
			failure = "적벽 지형을 불러올 수 없습니다."
			return false
		next_terrain = load(TERRAIN) as Texture2D
	if next_sky == null or (detailed and next_terrain == null):
		failure = "지도 이미지를 읽을 수 없습니다."
		return false
	# Publish only after schema, references and resources have all succeeded.
	data = candidate
	sky = next_sky
	terrain = next_terrain
	prepared = true
	return true

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	if not prepared: prepare()
	resized.connect(queue_redraw)

func _point(raw: Array) -> Vector2:
	return Vector2(float(raw[0]), float(raw[1]))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#080e18"))
	if not prepared:
		_text(Vector2(20, 40), failure, GOLD, 20)
		return
	if size.x <= 48.0 or size.y <= 44.0: return
	var bounds := _map_bounds()
	var field := _map_field(bounds.size)
	var scale_factor := field.size.x / bounds.size.x
	var backdrop := Rect2(Vector2.ZERO, size) if detailed or local_context else field
	draw_texture_rect(sky, backdrop, false, Color(0.65, 0.72, 0.85))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.08, 0.35) if detailed else Color(0.02, 0.04, 0.08, 0.15))
	if detailed:
		draw_texture_rect(terrain, field, false, Color(0.8, 0.9, 1, 0.9))
		_detail(field, scale_factor)
	elif local_context:
		_local_detail(field, scale_factor)
	else:
		_strategy(field, scale_factor)
	# Sensor-frame corner marks; purely visual.
	for corner in [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
		var at := Vector2(12 if corner.x > 0 else size.x - 12, 12 if corner.y > 0 else size.y - 12)
		draw_line(at, at + Vector2(corner.x * 22, 0), MUTED, 1)
		draw_line(at, at + Vector2(0, corner.y * 22), MUTED, 1)

func _map_bounds() -> Rect2:
	if local_context:
		return Sites.DETAIL_BOUNDS
	var extent := _point(data.space.size) if detailed else Vector2(float(data.width), float(data.height))
	return Rect2(Vector2.ZERO, extent)

func _map_field(extent: Vector2) -> Rect2:
	var available := size - Vector2(48, 44)
	var factor := maxf(0.0, minf(available.x / extent.x, available.y / extent.y))
	return Rect2((size - extent * factor) / 2.0, extent * factor)

func red_cliffs_position() -> Vector2:
	var bounds := _map_bounds()
	var field := _map_field(bounds.size)
	return field.position + _point(Sites.POINTS[0].position) * (field.size.x / bounds.size.x)

func _local_detail(field: Rect2, factor: float) -> void:
	var origin := field.position - Sites.DETAIL_BOUNDS.position * factor
	draw_texture_rect_region(sky, field, Sites.DETAIL_BOUNDS)
	var battle := origin + _point(Sites.POINTS[0].position) * factor
	var wulin := origin + _point(Sites.POINTS[1].position) * factor
	for route: Dictionary in data.routes:
		for index in range(1, route.points.size()):
			var from := _point(route.points[index - 1])
			var to := _point(route.points[index])
			if not Sites.DETAIL_BOUNDS.has_point(from):
				if not Sites.DETAIL_BOUNDS.has_point(to):
					continue
				from = _local_route_end(to, from)
			else:
				to = _local_route_end(from, to)
			draw_line(origin + from * factor, origin + to * factor, CYAN, 1.5, true)
	draw_dashed_line(wulin, battle, Color("#dc9c85"), 2.0, 6.0, true, true)
	draw_circle(wulin, 5.0, Color("#dc9c85"))
	draw_circle(battle, 6.0, GOLD)
	_text(wulin + Vector2(-34, -14), "오림 집결지", Color("#dc9c85"), 15)
	_text(battle + Vector2(-24, 27), "적벽 전장", GOLD, 15)

func _local_route_end(inside: Vector2, outside: Vector2) -> Vector2:
	var bounds: Rect2 = Sites.DETAIL_BOUNDS
	var direction := outside - inside
	var limit := 1.0
	for axis in range(2):
		if not is_zero_approx(direction[axis]):
			var edge := bounds.end[axis] if direction[axis] > 0.0 else bounds.position[axis]
			limit = minf(limit, (edge - inside[axis]) / direction[axis])
	return inside + direction * limit

func _strategy(field: Rect2, factor: float) -> void:
	var story := not story_focus.is_empty()
	var focused_positions := {}
	if story:
		for point: Dictionary in data.points:
			if str(point.get("id", "")) in story_focus:
				focused_positions[_point(point.position)] = true
	for route: Dictionary in data.routes:
		var points := PackedVector2Array()
		for p: Array in route.points:
			points.append(field.position + _point(p) * factor)
		if points.size() > 1:
			var tint := Color("#8ba9c58c") if compact_scale < 1.0 or story else Color("#55778965")
			draw_polyline(points, tint, 3 if compact_scale < 1.0 else 1, true)
		if story:
			_story_route(route.points, points, focused_positions)
	for point: Dictionary in data.points:
		var at := field.position + _point(point.position) * factor
		draw_circle(at, 2.0 if str(point.kind) == "항성계" else 1.1, Color("#93a6b280"))
	if story:
		_story_sites(field, factor)
		return
	for region: Dictionary in data.regions:
		var at := field.position + _point(region.position) * factor
		if region.name == "형초":
			continue
		if compact_scale < 1.0:
			draw_circle(at, 7, MUTED)
		else:
			_text(at, str(region.name) + " · 잠금", Color("#92a1b0"), 14)
	var wulin := field.position + _point(Sites.POINTS[1].position) * factor
	var battle := red_cliffs_position()
	var tint := Color("#dc9c85")
	draw_circle(battle, 8.0, GOLD, false, 1.5, true)
	draw_circle(wulin, 4.0, tint)
	if compact_scale < 1.0:
		_compact_label(wulin + Vector2(-24, -14), "오림", tint)
	else:
		_text(wulin + Vector2(-18, -12), "오림", tint, 15)
		_text(Vector2(26, size.y - 22), "천하 항로도     /     작전 가능 지역: 적벽", MUTED, 14)

func _story_route(raw_points: Array, points: PackedVector2Array, focused_positions: Dictionary) -> void:
	var start := -1
	for index in range(raw_points.size()):
		var position := _point(raw_points[index])
		if not focused_positions.has(position):
			continue
		if start >= 0:
			draw_polyline(points.slice(start, index + 1), Color(GOLD, 0.72), 2.0, true)
		start = index

func _story_sites(field: Rect2, factor: float) -> void:
	var targets: Array[Dictionary] = []
	var occupied: Array[Rect2] = []
	for point: Dictionary in data.points + Sites.POINTS:
		if str(point.get("id", "")) not in story_focus:
			continue
		var at := field.position + _point(point.position) * factor
		if point.id == Sites.RED_CLIFFS:
			at = red_cliffs_position()
		targets.append({"position": at, "name": str(point.get("name", ""))})
		occupied.append(Rect2(at - Vector2.ONE * 8.0, Vector2.ONE * 16.0))
	if Sites.RED_CLIFFS in story_focus and Sites.WULIN in story_focus:
		var wulin := field.position + _point(Sites.POINTS[1].position) * factor
		draw_dashed_line(wulin, red_cliffs_position(), Color(GOLD, 0.72), 2.0, 6.0, true, true)
	for target: Dictionary in targets:
		var at: Vector2 = target.position
		draw_circle(at, 10.0, Color(GOLD, 0.17), true, -1.0, true)
		draw_circle(at, 7.0, GOLD, false, 1.5, true)
		draw_circle(at, 2.5, GOLD, true, -1.0, true)
		_story_label(at, str(target.name), occupied)

func _story_label(at: Vector2, value: String, occupied: Array[Rect2]) -> void:
	const FONT_SIZE := 16
	var font := get_theme_default_font()
	var extent := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE) + Vector2(12, 6)
	for offset in [Vector2(12, -extent.y - 2), Vector2(12, 5),
			Vector2(-extent.x - 12, -extent.y - 2), Vector2(-extent.x - 12, 5)]:
		var label := Rect2(at + offset, extent)
		if not Rect2(Vector2.ZERO, size).grow(-8.0).encloses(label):
			continue
		if occupied.any(func(area: Rect2) -> bool: return area.grow(2.0).intersects(label)):
			continue
		occupied.append(label)
		draw_rect(label, Color("#101d2df5"))
		draw_rect(label, Color(GOLD, 0.64), false, 1.0)
		var baseline := label.position + Vector2(6.0, 3.0 + font.get_ascent(FONT_SIZE))
		draw_string(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, GOLD)
		return

func _detail(field: Rect2, factor: float) -> void:
	var nodes: Dictionary = data.space.nodes
	var line := PackedVector2Array()
	for id: String in data.space.routes.front.nodes:
		line.append(field.position + _point(nodes[id]) * factor)
	draw_polyline(line, Color("#8cddd938"), 8, true)
	draw_polyline(line, CYAN, 4 if compact_scale < 1.0 else 1.5, true)
	var labels := {"E": "연합 집결", "J": "진입 항로", "A": "전방 경유지", "C": "작전 목표"}
	for id: String in labels:
		var at := field.position + _point(nodes[id]) * factor
		var tint := GOLD if id == "C" else CYAN
		draw_circle(at, 5, tint)
		draw_arc(at, 10, 0, TAU, 32, tint, 1, true)
		if compact_scale < 1.0:
			if id == "E":
				_compact_label(at + Vector2(-124, 30), labels[id], tint)
			elif id == "C":
				_compact_label(at + Vector2(20, 24), labels[id], tint)
		else:
			_text(at + Vector2(15, 5), labels[id], tint, 18)
	var e := field.position + _point(nodes.E) * factor
	for i in range(3):
		var at := e + Vector2(-25 - i * 11, 22 + i * 3)
		draw_colored_polygon(PackedVector2Array([at+Vector2(5,-6), at+Vector2(-4,5), at+Vector2(4,3)]), CYAN)
	var r := field.position + _point(nodes.R) * factor
	var c := field.position + _point(nodes.C) * factor
	draw_dashed_line(r, c, Color("#ffc0a6"), 2.5, 9)
	var direction := (c - r).normalized()
	var tip := c - direction * 20.0
	var side := Vector2(-direction.y, direction.x)
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * 16.0 + side * 7.0, tip - direction * 16.0 - side * 7.0]), Color("#ffc0a6"))
	if compact_scale < 1.0:
		_compact_label(r + Vector2(20, -34), "적 접근", Color("#ffc4ae"))
	else:
		_text(r + Vector2(12, -18), "적 접근 방향", Color("#ffc0a6"), 18)
		_text(Vector2(26, size.y - 22), "적벽  /  전술 준비     •     정면 항로", MUTED, 14)

func _compact_label(position: Vector2, value: String, tint: Color) -> void:
	var font := get_theme_default_font()
	var font_size := ceili(12.0 / compact_scale)
	var padding := Vector2(10, 5)
	var bounds := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + padding * 2.0
	var origin := position.clamp(Vector2.ZERO, (size - bounds).max(Vector2.ZERO))
	draw_rect(Rect2(origin, bounds), Color("#080e18f5"))
	var baseline := origin + padding + Vector2(0, font.get_ascent(font_size))
	draw_string(font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

func _text(at: Vector2, value: String, tint: Color, font_size: int) -> void:
	var font := get_theme_default_font()
	draw_string_outline(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color("#060c14"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, tint)

