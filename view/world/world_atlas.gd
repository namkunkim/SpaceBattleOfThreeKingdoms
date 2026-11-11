extends PanelContainer

const MAP_SIZE := Vector2(1672, 941)
const TERRAIN_PATH := "res://data/scenarios/base/world_terrain.json"
const FACTION_COLORS := {"wei": Color("74bdff"), "shu": Color("85d9ab"), "wu": Color("ff938b")}
const FACTION_LABELS := {"wei": Vector2(785, 100), "shu": Vector2(295, 457), "wu": Vector2(1170, 648)}
const ART := "res://assets/world_atlas/"
const POINTS := [
	Vector2(741,216), Vector2(961,239), Vector2(1091,177), Vector2(1397,215),
	Vector2(1428,338), Vector2(1143,281), Vector2(1117,90), Vector2(516,141),
	Vector2(371,265), Vector2(220,197), Vector2(191,519), Vector2(385,407),
	Vector2(959,643), Vector2(1034,405), Vector2(1305,749), Vector2(1306,501),
	Vector2(683,838), Vector2(1308,116), Vector2(327,684),
]
const REPRESENTATIVES := [
	"낙양", "허", "진류", "임치", "하비", "업", "계", "진양", "장안 서부", "무위",
	"성도", "남정", "양양", "완", "건업", "수춘", "교지", "양평", "익주군",
]
const THEATER := [1, 14, 13, 16, 15, 11]

var _names := {}
var _numbers := {}
var _owners := {}
var _routes: Array
var _terrain := {}
var _terrain_info: Label
var _tabs: TabContainer
var _picker: OptionButton
var _detail: TextureRect
var _back := 0
var _overview_map: TextureRect


func configure(world: Dictionary) -> void:
	_routes = world.get("routes", [])
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(TERRAIN_PATH))
	if data is Dictionary:
		_terrain = data
	for number in range(1, POINTS.size() + 1):
		_numbers[_id(number)] = number
	for system: Dictionary in world.get("systems", []):
		var id: String = system.id
		_names[id] = system.name
		_owners[id] = system.owner
	mouse_filter = Control.MOUSE_FILTER_STOP
	_tabs = TabContainer.new()
	add_child(_tabs)
	_make_overview()
	_make_briefing()
	_make_details()

func show_overview() -> void:
	_tabs.current_tab = 0

func back_to_overview() -> bool:
	if _tabs.current_tab == 0:
		return false
	show_overview()
	return true

func _make_overview() -> void:
	var frame := AspectRatioContainer.new()
	frame.name = "천하 전략맵"
	frame.clip_contents = true
	frame.ratio = MAP_SIZE.aspect()
	_tabs.add_child(frame)
	_overview_map = _image("galaxy-strategy-background.png")
	frame.add_child(_overview_map)
	_overview_map.draw.connect(_draw_overview)
	_overview_map.resized.connect(_overview_map.queue_redraw)
	for i in POINTS.size():
		var number := i + 1
		var representative: String = REPRESENTATIVES[i]
		var pin := Button.new()
		pin.name = _id(number)
		pin.flat = true
		pin.custom_minimum_size = Vector2(35, 35)
		pin.tooltip_text = _system_name(number) + " 상세 지도"
		pin.accessibility_name = pin.tooltip_text
		_place_on_map(pin, POINTS[i])
		pin.pressed.connect(_open_system.bind(number))
		var caption := UiTheme.label(representative, "Muted", 14)
		caption.add_theme_color_override("font_color", Color("d1e8f5"))
		caption.add_theme_color_override("font_outline_color", Color("07101b"))
		caption.add_theme_constant_override("outline_size", 5)
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pin.add_child(caption)
		caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		caption.offset_left = -25
		caption.offset_right = 25
		caption.offset_top = 0
	for faction: String in _terrain.get("factions", {}):
		var info: Dictionary = _terrain.factions[faction]
		var tag := UiTheme.label(info.name, "Title", 25)
		tag.add_theme_color_override("font_color", FACTION_COLORS[faction])
		tag.add_theme_color_override("font_outline_color", Color("07101b"))
		tag.add_theme_constant_override("outline_size", 6)
		tag.mouse_filter = Control.MOUSE_FILTER_STOP
		tag.tooltip_text = _terrain_text(info)
		_place_on_map(tag, FACTION_LABELS[faction])
	for feature: Dictionary in _terrain.get("landmarks", []):
		var number: int = _numbers[feature.system]
		var offset: Array = feature.map_offset
		var pin := Button.new()
		pin.name = feature.id
		pin.text = "◇ " + feature.name
		pin.tooltip_text = _terrain_text(feature)
		pin.accessibility_name = feature.name
		_place_on_map(pin, POINTS[number - 1] + Vector2(offset[0], offset[1]))
		pin.pressed.connect(_open_system.bind(number))


func _place_on_map(item: Control, point: Vector2) -> void:
	_overview_map.add_child(item)
	var anchor := point / MAP_SIZE
	var half := item.get_combined_minimum_size() * 0.5
	item.anchor_left = anchor.x
	item.anchor_right = anchor.x
	item.anchor_top = anchor.y
	item.anchor_bottom = anchor.y
	item.offset_left = -half.x
	item.offset_right = half.x
	item.offset_top = -half.y
	item.offset_bottom = half.y


func _draw_overview() -> void:
	var scale_factor := _overview_map.size.x / MAP_SIZE.x
	if scale_factor <= 0.0:
		return
	var origin := Vector2(838, 358) * scale_factor
	for radius in [95.0, 178.0, 285.0, 420.0, 550.0, 690.0, 815.0]:
		var ring := PackedVector2Array()
		for i in range(97):
			var direction := Vector2.from_angle(TAU * i / 96.0)
			ring.append(origin + direction * Vector2(1.0, 0.57) * radius * scale_factor)
		_overview_map.draw_polyline(ring, Color(0.52, 0.73, 0.86, 0.24), 1.0, true)
	for route: Dictionary in _routes:
		var a := int(_numbers.get(route.a, 0))
		var b := int(_numbers.get(route.b, 0))
		if a == 0 or b == 0:
			continue
		var p: Vector2 = POINTS[a - 1] * scale_factor
		var q: Vector2 = POINTS[b - 1] * scale_factor
		var tint := Color("f4b474") if route.get("yangtze", false) else Color("87cce5")
		_overview_map.draw_line(p, q, Color(tint, 0.10), 4.0, true)
		_overview_map.draw_line(p, q, Color(tint, 0.74), 1.0, true)
	for i in POINTS.size():
		if i == 12:
			continue # 적벽의 가스 행성은 배경 원화의 동일한 위치에 그려져 있다.
		var point: Vector2 = POINTS[i] * scale_factor
		var tint: Color = FACTION_COLORS.get(_owners.get(_id(i + 1)), Color("c6d5db"))
		var radius := (23.0 if i + 1 in [1, 11, 15] else 14.0) * scale_factor
		_overview_map.draw_circle(point, radius * 1.45, Color(tint, 0.12), true, -1.0, true)
		_overview_map.draw_circle(point, radius, tint.darkened(0.68), true, -1.0, true)
		for layer in range(1, 13):
			var light := layer / 13.0
			_overview_map.draw_circle(point + Vector2(-0.44, -0.5) * light * radius,
				radius * (1.0 - light), tint.darkened(0.68 - light * 0.58), true, -1.0, true)
		_overview_map.draw_arc(point, radius, PI, TAU, 28, Color(tint, 0.75), 1.0, true)


func _terrain_text(info: Dictionary) -> String:
	var context: String = info.get("region", "") if not info.has("mechanic") else ""
	var heading: String = info.name + " · " + info.english
	if not context.is_empty():
		heading += " · " + context
	var text: String = heading + "\n" + info.description
	if info.has("mechanic"):
		text += "\n" + info.mechanic
	return text


func _show_terrain(number: int) -> void:
	var id := _id(number)
	var lines := PackedStringArray()
	for info: Dictionary in _terrain.get("factions", {}).values():
		if id in info.systems:
			lines.append(_terrain_text(info))
	for feature: Dictionary in _terrain.get("landmarks", []):
		if feature.system == id:
			lines.append(_terrain_text(feature))
	_terrain_info.text = "\n\n".join(lines)
	_terrain_info.visible = not lines.is_empty()


func _make_briefing() -> void:
	var scroll := ScrollContainer.new()
	scroll.name = "적벽대전 정보"
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_tabs.add_child(scroll)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	body.add_child(UiTheme.label("건안 13년 겨울 (208) · 적벽 전야", "Title", 26))
	for line: String in [
		"사예 → 남양 → 양번관문 → 형주 태양계권 → 구지 궤도",
		"조조는 남양을 거쳐 형주 북부의 양양으로 남하합니다.",
		"손권은 오회와 형주 강하를 기반으로 합비회랑과 이릉협도를 방어합니다.",
		"유비는 형주 남부의 장사·무릉·계양·영릉에 임시 기반을 둡니다.",
	]:
		var label := UiTheme.label(line, "Muted", 16)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_child(label)
	var gallery := GridContainer.new()
	gallery.columns = 3
	body.add_child(gallery)
	for number: int in THEATER:
		var card := VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		gallery.add_child(card)
		var preview := _image(_id(number) + ".jpg")
		preview.custom_minimum_size.y = 135
		card.add_child(preview)
		var go := Button.new()
		go.name = "Briefing_" + _id(number)
		go.text = _system_name(number) + " 상세 지도"
		go.pressed.connect(_open_system.bind(number))
		card.add_child(go)

func _make_details() -> void:
	var panel := VBoxContainer.new()
	panel.name = "성계 상세"
	_tabs.add_child(panel)
	var bar := HBoxContainer.new()
	panel.add_child(bar)
	var hint := UiTheme.label("휠 ↓ 천하 전략맵", "Muted", 14)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(hint)
	_picker = OptionButton.new()
	_picker.name = "SystemPicker"
	bar.add_child(_picker)
	for i in POINTS.size():
		_picker.add_item(_system_name(i + 1))
	_picker.item_selected.connect(func(index: int): _show_image(index + 1))
	var back := Button.new()
	back.text = "이전 탭"
	back.pressed.connect(func(): _tabs.current_tab = _back)
	bar.add_child(back)
	_detail = _image("")
	_detail.name = "SystemIllustration"
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(_detail)
	_terrain_info = UiTheme.label("", "Muted", 16)
	_terrain_info.name = "StrategicTerrainInfo"
	_terrain_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_terrain_info)
	_show_image(13)

func _open_system(number: int) -> void:
	_back = _tabs.current_tab
	_show_image(number)
	_tabs.current_tab = 2

func _show_image(number: int) -> void:
	_picker.select(number - 1)
	_show_terrain(number)
	_detail.texture = load(ART + _id(number) + ".jpg") as Texture2D

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index not in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		return
	var zoom_in: bool = event.button_index == MOUSE_BUTTON_WHEEL_UP
	var handled := false
	match _tabs.current_tab:
		0:
			var point := _illustration_point(_overview_map, event.position)
			if zoom_in and point != Vector2.INF:
				var number := _nearest_system(point)
				if number != 0:
					_open_system(number)
					handled = true
		2:
			if not zoom_in and _illustration_point(_detail, event.position) != Vector2.INF:
				show_overview()
				handled = true
	if handled:
		get_viewport().set_input_as_handled()

func _illustration_point(image: TextureRect, viewport_point: Vector2) -> Vector2:
	if image.texture == null or not image.is_visible_in_tree():
		return Vector2.INF
	var texture_size := image.texture.get_size()
	var factor := minf(image.size.x / texture_size.x, image.size.y / texture_size.y)
	if factor <= 0.0:
		return Vector2.INF
	var art_size := texture_size * factor
	var art := Rect2((image.size - art_size) / 2.0, art_size)
	var local := image.get_global_transform_with_canvas().affine_inverse() * viewport_point
	return (local - art.position) / art.size if art.has_point(local) else Vector2.INF

func _nearest_system(point: Vector2) -> int:
	var best := 0
	var distance := 130.0
	for i in POINTS.size():
		var candidate := (point * MAP_SIZE).distance_to(POINTS[i])
		if candidate < distance:
			best = i + 1
			distance = candidate
	return best

func _id(number: int) -> String:
	return "SYS-%02d" % number

func _system_name(number: int) -> String:
	var id := _id(number)
	return str(_names.get(id, id))

func _image(file: String) -> TextureRect:
	var image := TextureRect.new()
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not file.is_empty():
		image.texture = load(ART + file) as Texture2D
	return image
