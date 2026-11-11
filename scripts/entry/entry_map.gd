extends Control
# Read-only presentation of existing navigation and approved operation data.
# Never creates a battle host, writes coordinates, or advances simulation.
@export var detailed := false
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
	var extent := _point(data.space.size) if detailed else Vector2(float(data.width), float(data.height))
	var field := Rect2(Vector2(24, 22), size - Vector2(48, 44))
	var scale_factor := minf(field.size.x / extent.x, field.size.y / extent.y)
	field = Rect2((size - extent * scale_factor) / 2.0, extent * scale_factor)
	draw_texture_rect(sky, Rect2(Vector2.ZERO, size), false, Color(0.65, 0.72, 0.85))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.08, 0.15))
	if detailed:
		draw_texture_rect(terrain, field, false, Color(0.8, 0.9, 1, 0.9))
		_detail(field, scale_factor)
	else:
		_strategy(field, scale_factor)
	# Sensor-frame corner marks; purely visual.
	for corner in [Vector2(1,1), Vector2(-1,1), Vector2(1,-1), Vector2(-1,-1)]:
		var at := Vector2(12 if corner.x > 0 else size.x - 12, 12 if corner.y > 0 else size.y - 12)
		draw_line(at, at + Vector2(corner.x * 22, 0), MUTED, 1)
		draw_line(at, at + Vector2(0, corner.y * 22), MUTED, 1)

func _strategy(field: Rect2, factor: float) -> void:
	for route: Dictionary in data.routes:
		var points := PackedVector2Array()
		for p: Array in route.points: points.append(field.position + _point(p) * factor)
		if points.size() > 1: draw_polyline(points, Color("#8ba9c58c") if compact_scale < 1.0 else Color("#55778965"), 3 if compact_scale < 1.0 else 1, true)
	for point: Dictionary in data.points:
		var at := field.position + _point(point.position) * factor
		draw_circle(at, 2.0 if str(point.kind) == "항성계" else 1.1, Color("#93a6b280"))
	for region: Dictionary in data.regions:
		var at := field.position + _point(region.position) * factor
		var active: bool = region.name == "형초"
		if compact_scale < 1.0:
			if active:
				draw_circle(at, 32, Color("#e6c18c40"))
				draw_arc(at, 22, 0, TAU, 48, GOLD, 4, true)
				_compact_label(at + Vector2(34, -28), "적벽 작전", GOLD)
			else:
				draw_circle(at, 7, MUTED)
		elif active:
			draw_circle(at, 33, Color("#e6c18c20"))
			draw_arc(at, 24, 0, TAU, 48, GOLD, 1.5, true)
			draw_polyline(PackedVector2Array([at + Vector2(18,-18), at + Vector2(55,-48), at + Vector2(80,-48)]), GOLD, 1, true)
			_text(at + Vector2(85, -43), "적벽 작전", GOLD, 20)
			_text(at + Vector2(85, -22), "형초 권역", MUTED, 14)
		else:
			_text(at, str(region.name) + " · 잠금", Color("#92a1b0"), 14)
	if compact_scale >= 1.0:
		_text(Vector2(26, size.y - 22), "천하 항로도     /     작전 가능 지역: 적벽", MUTED, 14)

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
			_text(at + Vector2(15, 5), labels[id], tint, 15)
	var e := field.position + _point(nodes.E) * factor
	for i in range(3):
		var at := e + Vector2(-25 - i * 11, 22 + i * 3)
		draw_colored_polygon(PackedVector2Array([at+Vector2(5,-6), at+Vector2(-4,5), at+Vector2(4,3)]), CYAN)
	var r := field.position + _point(nodes.R) * factor
	var c := field.position + _point(nodes.C) * factor
	draw_dashed_line(r, c, Color("#dc9c85"), 1.5, 7)
	if compact_scale < 1.0:
		_compact_label(r + Vector2(20, -34), "적 접근", Color("#ffc4ae"))
	else:
		_text(r + Vector2(-85, -18), "적 접근 방향", Color("#dc9c85"), 15)
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

