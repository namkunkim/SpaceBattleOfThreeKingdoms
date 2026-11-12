extends Control

signal red_cliffs_requested

const Sites := preload("res://view/world/red_cliffs_sites.gd")
const PLANET := preload("res://view/world/navigation_planet.gd")
const DATA_PATH := "res://data/galaxy_navigation.json"
const IMAGE_PATH := "res://assets/world_atlas/galaxy_navigation_terrain.png"
const FACILITY_PATHS := {
	"orbital": "res://assets/world_atlas/navigation_orbital_station.png",
	"relay": "res://assets/world_atlas/navigation_relay_station.png",
	"fortress": "res://assets/world_atlas/navigation_fortress_satellite_oblique.png",
	"defense": "res://assets/world_atlas/navigation_defense_platform.png",
}
const FACILITY_WIDTHS := {"orbital": 35.0, "relay": 224.0, "fortress": 61.5, "defense": 22.0}
const FORTRESS_HEIGHT := 36.25
const FORTRESS_SPAN_KM := 120
const FORTRESS_EDGE_PADDING := 6.0
const MIN_PLANET_DIAMETER := 18.0
const CYAN := Color("91e9ff")
const GOLD := Color("e7be83")
const INK := Color("ecf7ff")
const MUTED := Color("a5bcd4")
const MAP_CENTER := Vector2(800, 450)
const CLEARANCE := Vector2(690, 345)
const DETAIL_MAGNIFICATION := 3.2
const DETAIL_THRESHOLD := 3.0
const LABEL_THRESHOLD := 1.25


class Surface extends Control:
	var atlas: Control

	func _draw() -> void:
		atlas._paint(self)

	func _gui_input(event: InputEvent) -> void:
		if atlas._handle_map_input(event):
			accept_event()


var _data: Dictionary = {}
var _points: Dictionary = {}
var _background: Texture2D
var _facility_textures: Dictionary = {}
var _planet_radii: Dictionary = {}
var _map_size := Vector2(1600, 900)
var _surface: Surface
var _heading: Label
var _status: Label
var _legend: Label
var _back: Button
var _popup: PanelContainer
var _popup_items: VBoxContainer
var _font: Font
var _label_areas: Array[Dictionary] = []
var _detail: Dictionary = {}
var _must_visit_station := false
var _detail_terrain: Array[Dictionary] = []
var _zoom := 1.0
var _pan := Vector2.ZERO
var _overview_zoom := 1.0
var _overview_pan := Vector2.ZERO
var _mouse_down := false
var _press := Vector2.ZERO
var _dragged := false
var _touches: Dictionary = {}


func configure(_world: Dictionary) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if not parsed is Dictionary or not parsed.has("points"):
		push_error("Navigation atlas data could not be loaded: " + DATA_PATH)
		return
	_data = parsed
	for site: Dictionary in Sites.POINTS:
		_data.points.push_front(site)
	_points.clear()
	_map_size = Vector2(float(_data.width), float(_data.height))
	for point: Dictionary in _data.points:
		_points[point.id] = point
	_background = load(IMAGE_PATH) as Texture2D
	for kind: String in FACILITY_PATHS:
		var asset: String = FACILITY_PATHS[kind]
		if ResourceLoader.exists(asset, "Texture2D"):
			_facility_textures[kind] = load(asset) as Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = get_theme_default_font()
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for edge in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + edge, 28)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 4)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 8)
	layout.add_child(bar)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(titles)
	_heading = _make_label("", 34, INK)
	titles.add_child(_heading)
	_status = _make_label("", 15, MUTED)
	titles.add_child(_status)
	_back = _add_button(bar, "전체 항로도", func(): back_to_overview())
	_add_button(bar, "−", func(): _zoom_at(_surface.size * 0.5, 1.0 / 1.25))
	_add_button(bar, "+", func(): _zoom_at(_surface.size * 0.5, 1.25))
	_add_button(bar, "화면 맞춤", _fit)

	_surface = Surface.new()
	_surface.atlas = self
	_surface.mouse_filter = Control.MOUSE_FILTER_STOP
	_surface.clip_contents = true
	_surface.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_surface.resized.connect(_on_surface_resized)
	_surface.mouse_exited.connect(func(): _surface.tooltip_text = "")
	layout.add_child(_surface)
	_legend = _make_label("", 15, MUTED)
	_legend.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	layout.add_child(_legend)

	_popup = PanelContainer.new()
	_popup.z_index = 10
	_popup.mouse_filter = Control.MOUSE_FILTER_STOP
	_popup.add_theme_stylebox_override("panel", _panel_style())
	_popup_items = VBoxContainer.new()
	_popup.add_child(_popup_items)
	add_child(_popup)
	_popup.hide()
	visibility_changed.connect(_on_visibility_changed)
	_refresh_header()


func _make_label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _add_button(parent: Control, title: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(58, 58)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101b2e")
	style.border_color = Color("456887")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func show_overview() -> void:
	_must_visit_station = false
	_detail = {}
	_detail_terrain.clear()
	_overview_zoom = 1.0
	_overview_pan = Vector2.ZERO
	_fit()
	_refresh_header()


func back_to_overview() -> bool:
	if _popup.visible:
		_popup.hide()
		return true
	if _detail.is_empty():
		return false
	_must_visit_station = false
	_detail = {}
	_detail_terrain.clear()
	_zoom = _overview_zoom
	_pan = _overview_pan
	_on_surface_resized()
	_refresh_header()
	return true


func _fit() -> void:
	_zoom = 1.0
	_pan = Vector2.ZERO
	if is_instance_valid(_popup):
		_popup.hide()
	if is_instance_valid(_surface):
		_surface.queue_redraw()
	_refresh_header()


func _refresh_header() -> void:
	if not is_instance_valid(_heading):
		return
	var overview := _detail.is_empty()
	_heading.text = "우주 삼국지 전체 항로도" if overview else str(_detail.caption)
	_back.visible = not overview
	if overview:
		_status.text = "항성계 51곳 · 요새 위성 10곳 · %d%%" % roundi(_zoom * 100)
		_legend.text = "항로  ━    외부 세력 항로  ┄    중계 정거장  ▣    요새 위성  ⬡    가스 성운  ●    먼지대  ●    |    선택하여 상세 보기 · 끌어서 이동"
		return
	var detail: Dictionary = _detail.detail
	var kind := str(_detail.kind)
	if kind == "요새 위성":
		_status.text = "%s · 최장 폭 약 %d km · 연결 진입로 %d곳 · %d%%" % [
			kind, FORTRESS_SPAN_KM, detail.approaches.size(), roundi(_zoom * 100)
		]
		_legend.text = "요새를 선택하여 시설과 무장 확인 · 외곽 방어 포대 · 검은 공간은 통행 가능"
	else:
		_status.text = "%s · 연결 진입로 %d곳 · %d%%" % [kind, detail.approaches.size(), roundi(_zoom * 100)]
		_legend.text = "검은 공간은 통행 가능 · 진입로를 선택하여 이동 · 행성을 선택하여 정보 보기"


func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		_popup.hide()
		_mouse_down = false
		_touches.clear()


func _on_surface_resized() -> void:
	_clamp_pan()
	if is_instance_valid(_surface):
		_surface.queue_redraw()


func _base_scale() -> float:
	return maxf(0.001, minf(_surface.size.x / _map_size.x, _surface.size.y / _map_size.y))


func _map_scale() -> float:
	return _base_scale() * _zoom


func _map_origin() -> Vector2:
	return (_surface.size - _map_size * _map_scale()) * 0.5 + _pan


func _map_to_screen(point: Vector2) -> Vector2:
	return _map_origin() + point * _map_scale()


func _screen_to_map(point: Vector2) -> Vector2:
	return (point - _map_origin()) / _map_scale()


func _clamp_pan() -> void:
	if not is_instance_valid(_surface):
		return
	var reach := ((_map_size * _map_scale() - _surface.size) * 0.5).max(Vector2.ZERO)
	_pan = _pan.clamp(-reach, reach)


func _zoom_at(position: Vector2, factor: float) -> void:
	if not _detail.is_empty() and factor < 1.0 and is_equal_approx(_zoom, 1.0):
		back_to_overview()
		return
	if _detail.is_empty() and factor > 1.0 and _zoom * factor >= DETAIL_THRESHOLD:
		var point := _nearest_point(position, 23.0, false)
		if point.has("detail"):
			_open_detail(point)
			return
	var pinned := _screen_to_map(position)
	_zoom = clampf(_zoom * factor, 1.0, 5.0)
	_pan = position - pinned * _map_scale() - (_surface.size - _map_size * _map_scale()) * 0.5
	_clamp_pan()
	_popup.hide()
	_surface.queue_redraw()
	_refresh_header()


func _focus_point(point: Dictionary) -> void:
	_zoom = maxf(_zoom, 2.0)
	_pan = (MAP_CENTER - _vector(point.position)) * _map_scale()
	_clamp_pan()
	_popup.hide()
	_surface.queue_redraw()
	_refresh_header()


func _pan_by(amount: Vector2) -> void:
	_pan += amount
	_clamp_pan()
	_surface.queue_redraw()


func _handle_map_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return false
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			_zoom_at(event.position, 1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.25)
			return true
		if event.button_index == MOUSE_BUTTON_LEFT:
			_mouse_down = event.pressed
			if event.pressed:
				_press = event.position
				_dragged = false
			elif not _dragged:
				_tap(event.position)
			return true
	if event is InputEventMouseMotion:
		if event.device == InputEvent.DEVICE_ID_EMULATION:
			return false
		if _mouse_down:
			_dragged = _dragged or event.position.distance_to(_press) > 8.0
			if _dragged:
				_popup.hide()
				_pan_by(event.relative)
		else:
			_update_tooltip(event.position)
		return true
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 1:
				_press = event.position
				_dragged = false
			else:
				_dragged = true
		else:
			_touches.erase(event.index)
			if _touches.is_empty() and not _dragged:
				_tap(event.position)
		return true
	if event is InputEventScreenDrag and _touches.has(event.index):
		var previous: Vector2 = _touches[event.index]
		_touches[event.index] = event.position
		if _touches.size() == 1:
			_dragged = _dragged or event.position.distance_to(_press) > 8.0
			if _dragged:
				_popup.hide()
				_pan_by(event.position - previous)
		elif _touches.size() == 2:
			for index in _touches:
				if index != event.index:
					var other: Vector2 = _touches[index]
					var distance := previous.distance_to(other)
					if distance > 6.0:
						_zoom_at((previous + other) * 0.5, event.position.distance_to(other) / distance)
					_pan_by((event.position - previous) * 0.5)
		return true
	if event is InputEventMagnifyGesture:
		_zoom_at(event.position, event.factor)
		return true
	if event is InputEventPanGesture:
		_pan_by(-event.delta * 8.0)
		return true
	return false


func _open_detail(point: Dictionary) -> void:
	if _detail.is_empty():
		_overview_zoom = _zoom
		_overview_pan = _pan
	_must_visit_station = false
	_detail = point
	_prepare_terrain(point)
	_fit()


func _vector(coordinates: Array) -> Vector2:
	return Vector2(float(coordinates[0]), float(coordinates[1]))


func _polyline(coordinates: Array) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point: Array in coordinates:
		points.append(_vector(point))
	return points


func _prepare_terrain(point: Dictionary) -> void:
	_detail_terrain.clear()
	var detail: Dictionary = point.detail
	var center := _vector(detail.center)
	var origin := _vector(point.position)
	var image_rect := Rect2(center - origin * DETAIL_MAGNIFICATION, _map_size * DETAIL_MAGNIFICATION)
	var image_area := PackedVector2Array([
		image_rect.position, Vector2(image_rect.end.x, image_rect.position.y),
		image_rect.end, Vector2(image_rect.position.x, image_rect.end.y)
	])
	var map_area := PackedVector2Array([Vector2.ZERO, Vector2(_map_size.x, 0), _map_size, Vector2(0, _map_size.y)])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(point.id)
	for coordinates: Array in detail.terrain:
		var polygon := _polyline(coordinates)
		for visible_area in Geometry2D.intersect_polygons(polygon, map_area):
			var textured: Array[Dictionary] = []
			for region in Geometry2D.intersect_polygons(visible_area, image_area):
				var uv := PackedVector2Array()
				for vertex in region:
					uv.append((vertex - image_rect.position) / image_rect.size)
				textured.append({"points": region, "uv": uv})
			var dust := PackedVector2Array()
			var rocks := PackedVector2Array()
			var bounds := Rect2(visible_area[0], Vector2.ZERO)
			for vertex in visible_area:
				bounds = bounds.expand(vertex)
			for index in range(100):
				var sample := bounds.position + bounds.size * Vector2(rng.randf(), rng.randf())
				if Geometry2D.is_point_in_polygon(sample, visible_area):
					(dust if index % 7 else rocks).append(sample)
			_detail_terrain.append({"points": visible_area, "textured": textured, "dust": dust, "rocks": rocks})


func _nearest_point(position: Vector2, radius: float, include_labels := true) -> Dictionary:
	if include_labels:
		for label in _label_areas:
			if (label.rect as Rect2).has_point(position):
				return _points[label.id]
	var chosen: Dictionary = {}
	var nearest := radius
	for point: Dictionary in _points.values():
		var distance := _map_to_screen(_vector(point.position)).distance_to(position)
		if distance < nearest:
			nearest = distance
			chosen = point
	return chosen


func _update_tooltip(position: Vector2) -> void:
	if _detail.is_empty():
		var point := _nearest_point(position, 18.0)
		_surface.tooltip_text = "" if point.is_empty() else "%s · %s" % [point.name, point.kind]
		return
	var map_position := _screen_to_map(position)
	if _fortress_at(map_position):
		_surface.tooltip_text = "요새 시설과 무장"
		return
	var destinations := _approach_at(map_position)
	if _must_visit_station and not destinations.is_empty():
		_surface.tooltip_text = "정거장을 거쳐 출항"
	else:
		_surface.tooltip_text = " · ".join(_destination_names(destinations))


func _tap(position: Vector2) -> void:
	if _popup.visible:
		_popup.hide()
		if _detail.is_empty():
			return
	if _detail.is_empty():
		var point := _nearest_point(position, 23.0)
		if point.get("id") == Sites.RED_CLIFFS:
			red_cliffs_requested.emit()
			return
		if not point.is_empty():
			_open_popup(position, "%s · %s" % [point.name, point.kind])
			if point.has("detail"):
				_add_button(_popup_items, "상세 지도 열기", func(): _open_detail(point))
			_add_button(_popup_items, "이 지점 확대", func(): _focus_point(point))
			_finish_popup(position)
		return

	var map_position := _screen_to_map(position)
	var marker_targets := _marker_approach_at(map_position)
	if not marker_targets.is_empty():
		_visit_approach(marker_targets, position)
		return
	if _fortress_at(map_position):
		_show_fortress_information(position)
		return
	var detail: Dictionary = _detail.detail
	var object := _nearest_detail_object(map_position, detail)
	if not object.is_empty():
		if object == detail.get("station", {}):
			_show_station_routes(position)
		else:
			_show_planet_information(position, object)
		return
	_visit_approach(_approach_at(map_position), position)


func _fortress_at(position: Vector2) -> bool:
	if _detail.kind != "요새 위성":
		return false
	var center := _vector(_detail.detail.center)
	return _facility_rect(center, "fortress").grow(4.0 / _map_scale()).has_point(position)


func _show_fortress_information(position: Vector2) -> void:
	_open_popup(position, "%s · 요새 사양" % _detail.name)
	var specifications := [
		"최장 폭 약 %d km" % FORTRESS_SPAN_KM,
		"함대 격납고 여러 곳에서 전함 동시 입출항",
		"외장 포대 · 레이저포, 미사일 발사대, 레일건",
		"내장 추진기관으로 요새 자체 기동",
		"초대형 주포로 장거리 대함대 포격",
	]
	for specification: String in specifications:
		_popup_items.add_child(_make_label(specification, 17, MUTED))
	_finish_popup(position)


func _nearest_detail_object(position: Vector2, detail: Dictionary) -> Dictionary:
	var objects: Array = detail.get("planets", []).duplicate()
	if detail.has("station"):
		objects.append(detail.station)
	var chosen: Dictionary = {}
	var nearest := INF
	for body: Dictionary in objects:
		var center := _vector(body.position)
		var radius := float(_planet_radii.get(center, body.get("radius", 17.5)))
		var distance := position.distance_to(center)
		if distance <= maxf(radius, 18.0 / _map_scale()) and distance < nearest:
			nearest = distance
			chosen = body
	return chosen


func _show_planet_information(position: Vector2, body: Dictionary) -> void:
	_open_popup(position, str(body.name))
	var description := str(body.classification)
	if body.habitable:
		_must_visit_station = true
		description += " · 거주 가능"
	_popup_items.add_child(_make_label(description, 17, MUTED))
	if body.habitable:
		_offer_station()
	_finish_popup(position)


func _offer_station() -> void:
	var station: Dictionary = _detail.detail.station
	var position := _map_to_screen(_vector(station.position))
	_add_button(_popup_items, "정거장으로 이동", func(): _show_station_routes(position))


func _show_station_routes(position: Vector2) -> void:
	_must_visit_station = false
	var detail: Dictionary = _detail.detail
	_open_popup(position, str(detail.station.name))
	_popup_items.add_child(_make_label("외부 항로 선택", 17, MUTED))
	var destinations: Dictionary = {}
	for approach: Dictionary in detail.approaches:
		for id: String in approach.destinations:
			destinations[id] = true
	for id: String in destinations:
		var target: Dictionary = _points[id]
		_add_button(_popup_items, str(target.name), func(): _open_detail(target))
	_finish_popup(position)


func _visit_approach(destinations: Array, position: Vector2) -> void:
	if destinations.is_empty():
		return
	if _must_visit_station:
		_open_popup(position, "정거장 경유")
		_popup_items.add_child(_make_label("항성계 밖으로 나가려면 정거장을 거쳐야 합니다.", 17, MUTED))
		_offer_station()
		_finish_popup(position)
		return
	if destinations.size() == 1:
		_open_detail(_points[destinations[0]])
		return
	_open_popup(position, "연결 진입로")
	for id: String in destinations:
		var target: Dictionary = _points[id]
		_add_button(_popup_items, str(target.name), func(): _open_detail(target))
	_finish_popup(position)


func _open_popup(_position: Vector2, title: String) -> void:
	for child in _popup_items.get_children():
		_popup_items.remove_child(child)
		child.queue_free()
	_popup_items.add_child(_make_label(title, 19, INK))


func _finish_popup(position: Vector2) -> void:
	_add_button(_popup_items, "닫기", _popup.hide)
	_popup.reset_size()
	var origin := get_global_transform().affine_inverse() * (_surface.get_global_transform() * position)
	_popup.position = (origin + Vector2(12, 8)).clamp(Vector2.ZERO, (size - _popup.get_combined_minimum_size()).max(Vector2.ZERO))
	_popup.show()


func _destination_names(destinations: Array) -> PackedStringArray:
	var names := PackedStringArray()
	for id: String in destinations:
		names.append(str(_points[id].name))
	return names


func _approach_marker(approach: Dictionary) -> Vector2:
	var direction := Vector2.from_angle(float(approach.angle))
	if _detail.kind == "요새 위성":
		var side := 0 if direction.x < 0.0 else -1
		var contours: Array = _detail.detail.contours
		return Vector2(110 if side == 0 else _map_size.x - 110,
			(_vector(contours[0][side]).y + _vector(contours[1][side]).y) * 0.5)
	var edge := minf((MAP_CENTER.x - 80.0) / maxf(absf(direction.x), 0.001),
		(MAP_CENTER.y - 45.0) / maxf(absf(direction.y), 0.001))
	return MAP_CENTER + direction * edge


func _marker_approach_at(position: Vector2) -> Array:
	var nearest := 30.0
	var destinations: Array = []
	for approach: Dictionary in _detail.detail.approaches:
		var distance := position.distance_to(_approach_marker(approach)) * _map_scale()
		if distance < nearest:
			nearest = distance
			destinations = approach.destinations
	return destinations


func _approach_at(position: Vector2) -> Array:
	var marker_targets := _marker_approach_at(position)
	if not marker_targets.is_empty():
		return marker_targets
	if _detail.kind == "요새 위성":
		return []
	var offset := position - MAP_CENTER
	if Vector2(offset.x / CLEARANCE.x, offset.y / CLEARANCE.y).length() < 1.0:
		return []
	for approach: Dictionary in _detail.detail.approaches:
		if absf(angle_difference(offset.angle(), float(approach.angle))) <= float(approach.halfWidth):
			return approach.destinations
	return []


func _paint(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, canvas.size), Color("080f1b"))
	_label_areas.clear()
	if _data.is_empty():
		return
	canvas.draw_set_transform(_map_origin(), 0, Vector2.ONE * _map_scale())
	if _detail.is_empty():
		_draw_overview(canvas)
	else:
		_draw_detail(canvas)
	canvas.draw_set_transform(Vector2.ZERO)
	if _detail.is_empty():
		_draw_overview_labels(canvas)
	else:
		_draw_detail_labels(canvas)


func _draw_overview(canvas: Control) -> void:
	if _background:
		canvas.draw_texture_rect(_background, Rect2(Vector2.ZERO, _map_size), false)
	for route: Dictionary in _data.routes:
		var path := _polyline(route.points)
		if route.type == "external":
			for index in range(1, path.size()):
				canvas.draw_dashed_line(path[index - 1], path[index], GOLD, 2.0, 6.0, true, true)
		else:
			canvas.draw_polyline(path, Color("153f59"), 5.0, true)
			canvas.draw_polyline(path, CYAN, 1.9, true)
	for point: Dictionary in _data.points:
		var center := _vector(point.position)
		match str(point.kind):
			"전장":
				canvas.draw_circle(center, 8.0, GOLD, false, 1.6, true)
				canvas.draw_circle(center, 4.0, GOLD, true, -1.0, true)
			"집결지":
				canvas.draw_circle(center, 4.0, Color.from_string(point.color, GOLD), true, -1.0, true)
			"중계 정거장":
				_draw_station(canvas, center, 5.5, CYAN)
			"요새 위성":
				_draw_fortress(canvas, center, 6.0)
			"외부 세력":
				canvas.draw_circle(center, 5.0, GOLD, false, 1.4, true)
				canvas.draw_circle(center, 2.0, GOLD, true, -1.0, true)
			_:
				var color := Color.from_string(str(point.color), CYAN)
				canvas.draw_circle(center, 7.0, Color(color, 0.23), true, -1.0, true)
				canvas.draw_colored_polygon(PackedVector2Array([
					center + Vector2(0, -5), center + Vector2(4, 0),
					center + Vector2(0, 5), center + Vector2(-4, 0)
				]), Color("edfaff"))


func _draw_station(canvas: Control, center: Vector2, radius: float, color: Color) -> void:
	var square := Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2)
	canvas.draw_rect(square, Color("11243c"))
	canvas.draw_rect(square, color, false, maxf(1.2, radius * 0.14))
	canvas.draw_circle(center, radius * 0.32, color, true, -1.0, true)


func _draw_fortress(canvas: Control, center: Vector2, radius: float) -> void:
	var hex := PackedVector2Array()
	for index in range(7):
		hex.append(center + Vector2.from_angle(TAU * index / 6.0) * radius)
	canvas.draw_colored_polygon(hex, Color("211b2b"))
	canvas.draw_polyline(hex, GOLD, maxf(1.2, radius * 0.12), true)
	canvas.draw_circle(center, radius * 0.28, GOLD, true, -1.0, true)


func _draw_detail(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, _map_size), Color.BLACK)
	for terrain: Dictionary in _detail_terrain:
		canvas.draw_colored_polygon(terrain.points, Color("111b2c"))
		if _background:
			for texture: Dictionary in terrain.textured:
				canvas.draw_polygon(texture.points, PackedColorArray([Color.WHITE]), texture.uv, _background)
		for speck in terrain.dust:
			canvas.draw_circle(speck, 1.5, Color(0.52, 0.77, 0.86, 0.50), true, -1.0, true)
		for rock in terrain.rocks:
			canvas.draw_circle(rock, 3.4, Color(0.70, 0.53, 0.43, 0.8), true, -1.0, true)
	var detail: Dictionary = _detail.detail
	for contour: Array in detail.contours:
		canvas.draw_polyline(_polyline(contour), Color(0.46, 0.72, 0.83, 0.45), 1.35, true)

	var center := _vector(detail.center)
	if not detail.has("planets"):
		var kind := "fortress" if _detail.kind == "요새 위성" else "relay"
		if kind == "fortress":
			for platform in _defense_positions(center, detail.contours):
				_draw_facility(canvas, platform, "defense")
		_draw_facility(canvas, center, kind)
		return

	var station := _vector(detail.station.position)
	_update_planet_radii(detail, station)
	for body: Dictionary in detail.planets:
		var orbit := PackedVector2Array()
		for index in range(97):
			var direction := Vector2.from_angle(TAU * index / 96.0)
			orbit.append(center + direction * Vector2(1.0, 0.52) * float(body.orbit))
		var color := Color(0.38, 0.8, 0.58, 0.60) if body.habitable else Color(0.52, 0.66, 0.83, 0.32)
		canvas.draw_polyline(orbit, color, 1.15, true)
	for asteroid: Array in detail.asteroids:
		canvas.draw_circle(_vector(asteroid), 0.95, Color(0.68, 0.60, 0.47, 0.65))
	for star: Dictionary in detail.stars:
		_draw_star(canvas, star)
	for body: Dictionary in detail.planets:
		var position := _vector(body.position)
		_draw_planet(canvas, body, _planet_radii[position])
	_draw_facility(canvas, station, "orbital")


func _facility_rect(center: Vector2, kind: String) -> Rect2:
	var texture: Texture2D = _facility_textures.get(kind)
	var dimensions := Vector2.ONE
	if texture:
		dimensions = texture.get_size()
	var longest := maxf(dimensions.x, dimensions.y)
	var scale := float(FACILITY_WIDTHS[kind]) / longest
	if kind == "fortress":
		scale = minf(scale, FORTRESS_HEIGHT / dimensions.y)
		scale = _fit_fortress_scale(center, dimensions, scale)
	var extent := dimensions * scale
	return Rect2(center - extent * 0.5, extent)


func _fit_fortress_scale(center: Vector2, dimensions: Vector2, target: float) -> float:
	var contours: Array = _detail.detail.contours
	var low := 0.0
	var high := target
	for iteration in range(9):
		var scale := high if iteration == 0 else (low + high) * 0.5
		var half := dimensions * scale * 0.5
		var box := Rect2(center - half, half * 2.0).grow(FORTRESS_EDGE_PADDING)
		if _corridor_edge_clears(contours[0], box, true) and _corridor_edge_clears(contours[1], box, false):
			if iteration == 0:
				return target
			low = scale
		else:
			high = scale
	return low


func _corridor_edge_clears(contour: Array, box: Rect2, upper: bool) -> bool:
	for index in range(1, contour.size()):
		var a := _vector(contour[index - 1])
		var b := _vector(contour[index])
		var start := maxf(a.x, box.position.x)
		var end := minf(b.x, box.end.x)
		if start > end:
			continue
		var y0 := lerpf(a.y, b.y, inverse_lerp(a.x, b.x, start))
		var y1 := lerpf(a.y, b.y, inverse_lerp(a.x, b.x, end))
		if (upper and maxf(y0, y1) > box.position.y) or (not upper and minf(y0, y1) < box.end.y):
			return false
	return true


func _corridor_height_at(contour: Array, x: float) -> float:
	for index in range(1, contour.size()):
		var a := _vector(contour[index - 1])
		var b := _vector(contour[index])
		if x <= b.x:
			return lerpf(a.y, b.y, inverse_lerp(a.x, b.x, x))
	return _vector(contour[-1]).y


func _defense_positions(center: Vector2, contours: Array) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var fortress := _facility_rect(center, "fortress").grow(18.0)
	for offset in [-294.0, -195.0, 195.0, 294.0]:
		var x := center.x + float(offset)
		var upper := _corridor_height_at(contours[0], x)
		var lower := _corridor_height_at(contours[1], x)
		var fraction := 0.29 if positions.size() % 2 == 0 else 0.71
		for depth in [fraction, 0.5]:
			var position := Vector2(x, lerpf(upper, lower, depth))
			var box := _facility_rect(position, "defense").grow(8.0)
			if fortress.intersects(box):
				continue
			if _corridor_edge_clears(contours[0], box, true) and _corridor_edge_clears(contours[1], box, false):
				positions.append(position)
				break
	return positions


func _draw_facility(canvas: Control, center: Vector2, kind: String) -> void:
	var texture: Texture2D = _facility_textures.get(kind)
	if texture:
		canvas.draw_texture_rect(texture, _facility_rect(center, kind), false)
	elif kind == "fortress":
		_draw_fortress(canvas, center, _facility_rect(center, kind).size.y * 0.5)
	elif kind == "defense":
		_draw_fortress(canvas, center, 11.0)
	else:
		_draw_station(canvas, center, 10.0 if kind == "orbital" else 24.0, CYAN)


func _planet_art_scale(body: Dictionary) -> float:
	return 1.88 if body.ringed else 1.0


func _update_planet_radii(detail: Dictionary, station: Vector2) -> void:
	_planet_radii.clear()
	var minimum := MIN_PLANET_DIAMETER * 0.5 / _map_scale()
	var station_radius := _facility_rect(station, "orbital").size.length() * 0.5
	for body: Dictionary in detail.planets:
		var position := _vector(body.position)
		var radius := float(body.radius)
		var art_scale := _planet_art_scale(body)
		var extent := radius * art_scale
		var room := position.distance_to(station) - station_radius - extent
		for star: Dictionary in detail.stars:
			room = minf(room, position.distance_to(_vector(star.position)) - float(star.radius) - extent)
		for other: Dictionary in detail.planets:
			var other_position := _vector(other.position)
			if other_position == position:
				continue
			var gap := position.distance_to(other_position) - float(other.radius) * _planet_art_scale(other) - extent
			room = minf(room, gap * 0.5)
		var growth := maxf(0.0, room - 1.5) / art_scale
		_planet_radii[position] = clampf(minimum, radius, radius + growth)


func _draw_star(canvas: Control, star: Dictionary) -> void:
	var center := _vector(star.position)
	var color := Color.from_string(str(star.color), GOLD)
	var radius := float(star.radius)
	for index in range(8, 0, -1):
		canvas.draw_circle(center, radius * (1.0 + index * 0.25), Color(color, 0.035), true, -1.0, true)
	canvas.draw_circle(center, radius, color, true, -1.0, true)
	canvas.draw_circle(center - Vector2(0.12, 0.12) * radius, radius * 0.68, Color("fff9df"), true, -1.0, true)


func _draw_planet(canvas: Control, body: Dictionary, radius: float) -> void:
	var center := _vector(body.position)
	if body.ringed:
		_draw_ring_half(canvas, center, radius, false)
	var texture := PLANET.texture(body)
	if texture:
		canvas.draw_texture_rect(texture, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false)
	if body.ringed:
		_draw_ring_half(canvas, center, radius, true)
	if body.habitable:
		canvas.draw_circle(center, radius + 2.2, Color(0.4, 0.93, 0.68, 0.75), false, 1.4, true)


func _draw_ring_half(canvas: Control, center: Vector2, radius: float, near_side: bool) -> void:
	var bands := [
		[1.20, 1.43, Color(0.68, 0.56, 0.42, 0.68)],
		[1.46, 1.68, Color(0.83, 0.72, 0.54, 0.82)],
		[1.72, 1.88, Color(0.72, 0.65, 0.56, 0.57)],
	]
	var start := 0.0 if near_side else PI
	var flattening := Vector2(1.0, 0.29)
	for band: Array in bands:
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for index in range(25):
			var direction := Vector2.from_angle(start + PI * index / 24.0)
			var offset := (direction * flattening).rotated(-0.29) * radius
			outer.append(center + offset * float(band[1]))
			inner.append(center + offset * float(band[0]))
		inner.reverse()
		outer.append_array(inner)
		var color: Color = band[2]
		if not near_side:
			color.a *= 0.65
		canvas.draw_colored_polygon(outer, color)


func _draw_overview_labels(canvas: Control) -> void:
	var taken: Array[Rect2] = []
	if _zoom < LABEL_THRESHOLD:
		for region: Dictionary in _data.regions:
			_draw_label(canvas, str(region.name), _map_to_screen(_vector(region.position)), 18, CYAN)
	for point: Dictionary in _data.points:
		var external: bool = point.kind == "외부 세력" or point.kind == "동이권 태양계"
		var operation_site: bool = point.id in [Sites.RED_CLIFFS, Sites.WULIN]
		if not (external or operation_site) and _zoom < LABEL_THRESHOLD:
			continue
		var position := _map_to_screen(_vector(point.position))
		if not Rect2(Vector2.ZERO, canvas.size).grow(12.0).has_point(position):
			continue
		var color := GOLD if external or point.kind == "요새 위성" else INK
		if operation_site:
			color = Color.from_string(point.color, GOLD)
		var caption := str(point.caption)
		var offsets := [Vector2(0, -17), Vector2(0, 17), Vector2(26, -13), Vector2(-26, -13)]
		if point.id == Sites.RED_CLIFFS:
			offsets.push_front(Vector2(0, 17))
		for offset in offsets:
			var box := _label_rect(caption, position + offset, 14)
			if taken.any(func(other: Rect2): return other.grow(2.0).intersects(box)):
				continue
			_draw_label(canvas, caption, position + offset, 14, color)
			taken.append(box)
			_label_areas.append({"rect": box, "id": point.id})
			break


func _draw_detail_labels(canvas: Control) -> void:
	var detail: Dictionary = _detail.detail
	var taken: Array[Rect2] = []
	if not detail.has("planets"):
		var kind := "fortress" if _detail.kind == "요새 위성" else "relay"
		var art := _screen_rect(_facility_rect(_vector(detail.center), kind))
		_draw_object_label(canvas, str(_detail.name), art, 17, INK, taken, [art])
	else:
		var station_art := _screen_rect(_facility_rect(_vector(detail.station.position), "orbital"))
		var obstacles: Array[Rect2] = [station_art]
		var planet_art: Array[Rect2] = []
		for body: Dictionary in detail.planets:
			var position := _vector(body.position)
			var radius: float = _planet_radii[position]
			var extent := Vector2(1.88, 1.0) * radius if body.ringed else Vector2.ONE * radius
			var art := _screen_rect(Rect2(position - extent, extent * 2.0))
			obstacles.append(art)
			planet_art.append(art)
		for star: Dictionary in detail.stars:
			var radius := Vector2.ONE * float(star.radius)
			obstacles.append(_screen_rect(Rect2(_vector(star.position) - radius, radius * 2.0)))
		_draw_object_label(canvas, str(detail.station.name), station_art, 14, CYAN, taken, obstacles)
		for index in range(detail.planets.size()):
			var body: Dictionary = detail.planets[index]
			var color := Color("a6efc1") if body.habitable else INK
			_draw_object_label(canvas, str(body.name), planet_art[index], 14, color, taken, obstacles)


func _screen_rect(map_rect: Rect2) -> Rect2:
	return Rect2(_map_to_screen(map_rect.position), map_rect.size * _map_scale())


func _draw_object_label(canvas: Control, value: String, art: Rect2, font_size: int,
		color: Color, taken: Array[Rect2], obstacles: Array[Rect2]) -> void:
	var distance := (art.size + _label_rect(value, Vector2.ZERO, font_size).size) * 0.5 + Vector2.ONE * 5.0
	var viewport := Rect2(Vector2.ZERO, canvas.size)
	for direction in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		var position: Vector2 = art.get_center() + direction * distance
		var label := _label_rect(value, position, font_size)
		if not viewport.encloses(label):
			continue
		if taken.any(func(other: Rect2): return other.grow(2.0).intersects(label)):
			continue
		if obstacles.any(func(other: Rect2): return other.grow(2.0).intersects(label)):
			continue
		_draw_label(canvas, value, position, font_size, color)
		taken.append(label)
		return


func _label_rect(value: String, center: Vector2, font_size: int) -> Rect2:
	var dimensions := _font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) + Vector2(12, 5)
	return Rect2(center - dimensions * 0.5, dimensions)


func _draw_label(canvas: Control, value: String, center: Vector2, font_size: int, color: Color) -> void:
	var box := _label_rect(value, center, font_size)
	canvas.draw_rect(box, Color(0.035, 0.085, 0.15, 0.90))
	canvas.draw_rect(box, Color(color, 0.56), false, 1.0)
	var baseline := box.position + Vector2(6, 2.5 + _font.get_ascent(font_size))
	canvas.draw_string(_font, baseline, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
