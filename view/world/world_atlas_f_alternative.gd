extends PanelContainer

const StrategyMapArt := preload("res://view/world/strategy_map_art.gd")
const REFERENCE_DATA := "res://assets/world_atlas/reference-layout.json"
const GEOGRAPHY_DATA := "res://assets/world_atlas/geographic-positions.json"
const COORDINATE_DATA := "res://assets/world_atlas/illustration-coordinates.json"
const ZOOM_STEP := 1.2
const MAX_ZOOM := 4.0

var _names := {}
var _world_routes: Array
var _coordinate_systems: Dictionary
var _coordinate_dialog: AcceptDialog
var _coordinate_text: TextEdit
var _tab: Control
var _overview_view: Control
var _picker: OptionButton
var _zoom := 1.0
var _pan_button := MOUSE_BUTTON_NONE
var _overview_map: Control
var _map_art: Control


func configure(world: Dictionary) -> void:
	for system: Dictionary in world.get("systems", []):
		_names[str(system.get("id", ""))] = str(system.get("name", ""))
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tabs := TabContainer.new()
	add_child(tabs)
	_tab = Control.new()
	_tab.name = "천하 전략맵"
	tabs.add_child(_tab)
	_world_routes = world.get("routes", [])
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(COORDINATE_DATA))
	if parsed is Dictionary:
		_coordinate_systems = parsed.get("systems", {})
	_make_overview(world)
	_make_coordinate_dialog()

func _make_overview(world: Dictionary) -> void:
	_overview_view = Control.new()
	_overview_view.clip_contents = true
	_overview_view.gui_input.connect(_on_map_input)
	_tab.add_child(_overview_view)
	_overview_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overview_map = Control.new()
	_overview_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overview_view.add_child(_overview_map)
	_map_art = StrategyMapArt.new()
	_map_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var geography: Variant = JSON.parse_string(FileAccess.get_file_as_string(GEOGRAPHY_DATA))
	var reference: Variant = JSON.parse_string(FileAccess.get_file_as_string(REFERENCE_DATA))
	_map_art.configure(_coordinate_systems, geography if geography is Dictionary else {}, reference if reference is Dictionary else {}, world)
	_overview_map.add_child(_map_art)
	_map_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overview_view.resized.connect(_center_overview)
	_center_overview()

	var coordinates := Button.new()
	coordinates.text = "좌표 보기"
	coordinates.pressed.connect(_show_coordinates)
	_overview_view.add_child(coordinates)
	coordinates.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	coordinates.offset_left = -156
	coordinates.offset_right = -12
	coordinates.offset_top = 12
	coordinates.offset_bottom = 48

	var interstellar := CheckButton.new()
	interstellar.text = "성간 경로"
	interstellar.button_pressed = true
	interstellar.toggled.connect(_toggle_interstellar)
	_overview_view.add_child(interstellar)
	interstellar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	interstellar.offset_left = 12
	interstellar.offset_right = 148
	interstellar.offset_top = 12
	interstellar.offset_bottom = 48

func _toggle_interstellar(visible_on_map: bool) -> void:
	_map_art.show_interstellar = visible_on_map
	_map_art.queue_redraw()

func _overview_size() -> Vector2:
	var native_size := StrategyMapArt.ATLAS_SIZE
	var available := _overview_view.size / native_size
	return native_size * minf(available.x, available.y) * _zoom

func _center_overview() -> void:
	_overview_map.size = _overview_size()
	_overview_map.position = (_overview_view.size - _overview_map.size) * 0.5

func _position_overview(target: Vector2) -> void:
	var room := _overview_view.size - _overview_map.size
	_overview_map.position = Vector2(
		clampf(target.x, room.x, 0.0) if room.x < 0.0 else room.x * 0.5,
		clampf(target.y, room.y, 0.0) if room.y < 0.0 else room.y * 0.5
	)

func _zoom_overview(factor: float, point: Vector2) -> void:
	var previous := _zoom
	_zoom = clampf(_zoom * factor, 1.0, MAX_ZOOM)
	_map_art.queue_redraw()
	var target := point - (point - _overview_map.position) * (_zoom / previous)
	_overview_map.size = _overview_size()
	_position_overview(target)

func _on_map_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				_pan_button = event.button_index
			elif _pan_button == event.button_index:
				_pan_button = MOUSE_BUTTON_NONE
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_overview(ZOOM_STEP, event.position)
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_overview(1.0 / ZOOM_STEP, event.position)
		else:
			return
		_overview_view.accept_event()
	elif event is InputEventMouseMotion and _pan_button != MOUSE_BUTTON_NONE:
		if event.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_MIDDLE):
			_position_overview(_overview_map.position + event.relative)
			_overview_view.accept_event()
		else:
			_pan_button = MOUSE_BUTTON_NONE

func _make_coordinate_dialog() -> void:
	_coordinate_dialog = AcceptDialog.new()
	_coordinate_dialog.ok_button_text = "닫기"
	_coordinate_dialog.wrap_controls = true
	add_child(_coordinate_dialog)
	var body := VBoxContainer.new()
	body.custom_minimum_size = Vector2(700, 450)
	_coordinate_dialog.add_child(body)
	_picker = OptionButton.new()
	_picker.add_item("성간 이동로", 0)
	for number in range(1, _names.size() + 1):
		_picker.add_item(_system_name(number), number)
	_picker.item_selected.connect(_update_coordinate_report)
	body.add_child(_picker)
	_coordinate_text = TextEdit.new()
	_coordinate_text.editable = false
	_coordinate_text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_coordinate_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_coordinate_text)

func _show_coordinates() -> void:
	_update_coordinate_report(_picker.selected)
	_coordinate_dialog.popup_centered_ratio(0.8)

func _update_coordinate_report(index: int) -> void:
	var number := _picker.get_item_id(index)
	_coordinate_dialog.title = "천하 전략맵 좌표"
	_coordinate_text.text = _world_coordinate_report() if number == 0 else _local_coordinate_report(number)
	_coordinate_text.set_caret_line(0)
	_coordinate_text.set_caret_column(0)
	_coordinate_text.scroll_vertical = 0

func _world_coordinate_report() -> String:
	var rows := PackedStringArray([
		"성간 이동로 · 게임 월드 좌표 (X, Y)",
		"위 목록에서 성계를 선택하면 행성·관문 및 내부 이동로 좌표가 표시됩니다.",
		"",
	])
	for route: Dictionary in _world_routes:
		var from_id: String = route.get("a", "")
		var to_id: String = route.get("b", "")
		var path: Array = route.get("line", [])
		if from_id.is_empty() or to_id.is_empty() or path.is_empty():
			continue
		rows.append("%s  %s ↔ %s  [%s]" % [
			route.get("id", ""), _names.get(from_id, from_id),
			_names.get(to_id, to_id), route.get("kind", ""),
		])
		if StrategyMapArt.CORRIDOR_NAMES.has(route.get("id", "")):
			rows.append("  " + StrategyMapArt.corridor_name(route, _names))
		var points := PackedStringArray()
		for point: Array in path:
			points.append("(%.1f, %.1f)" % [point[0], point[1]])
		rows.append("  " + " → ".join(points))
	return "
".join(rows)

func _local_coordinate_report(number: int) -> String:
	var system: Dictionary = _coordinate_systems.get(_id(number), {})
	if system.is_empty():
		return "이 성계의 이미지 좌표를 불러오지 못했습니다."
	var rows := PackedStringArray([
		"상세 지도 표기에서 읽은 근사 좌표입니다. 원점은 왼쪽 위입니다.",
		"상세 좌표 500×282 기준 · 전략맵 좌표 %d×%d 픽셀" % [
			StrategyMapArt.ATLAS_SIZE.x, StrategyMapArt.ATLAS_SIZE.y,
		],
		"",
	])
	var all_points := {}
	for group: String in ["nodes", "gates"]:
		rows.append("행성 및 지점" if group == "nodes" else "관문 및 통로 입구")
		var points: Dictionary = system.get(group, {})
		all_points.merge(points)
		for label: String in points:
			var point: Array = points[label]
			rows.append("  %s  %s" % [label, _local_coordinate(number, point, label)])
		rows.append("")
	rows.append("성계 내부 이동로 · 원본 그림의 진행 방향을 따라 읽은 좌표")
	for path: Array in system.get("paths", []):
		var points := PackedStringArray()
		for stop: Variant in path:
			if stop is String:
				points.append("%s %s" % [stop, _local_coordinate(number, all_points[stop], stop)])
			else:
				points.append(_local_coordinate(number, stop))
		rows.append("  " + " → ".join(points))
	return "
".join(rows)

func _local_coordinate(number: int, point: Array, label: String = "") -> String:
	var sampled := "(%d, %d)" % [point[0], point[1]]
	if label.is_empty():
		return sampled
	var location: Dictionary = _map_art.geographic_location(_id(number), label)
	if location.is_empty():
		return sampled + " [원본 이미지]"
	var xy := Vector2(location.position[0], location.position[1])
	var map_pixel: Vector2 = _map_art.map_location(_id(number), label, xy) * StrategyMapArt.ATLAS_SIZE
	var reference: Dictionary = _map_art.reference_marker(_id(number), label)
	var basis := "게임 배치" if location.basis == "authored-local-offset" else "권역·관문 기준점"
	if not reference.is_empty():
		basis = "첨부 권역 기준점" if reference.match == "regional" else "첨부 도시 기준점"
	return "%s / 전략맵 (%d, %d) / 참고 경도·위도 (%.2f, %.2f) [%s]" % [
		sampled, roundi(map_pixel.x), roundi(map_pixel.y), 90.0 + xy.x / 848.0, 46.0 - xy.y / 1000.0, basis,
	]

func _id(number: int) -> String:
	return "SYS-%02d" % number

func _system_name(number: int) -> String:
	var id := _id(number)
	return str(_names.get(id, id))
