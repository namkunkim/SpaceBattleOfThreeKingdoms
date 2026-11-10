extends PanelContainer

const ART := "res://assets/world_atlas/"
const POINTS := [
	Vector2(806,342), Vector2(952,374), Vector2(1077,325), Vector2(1270,270),
	Vector2(1250,366), Vector2(1005,271), Vector2(1137,204), Vector2(841,233),
	Vector2(672,319), Vector2(410,251), Vector2(458,503), Vector2(594,403),
	Vector2(840,497), Vector2(880,414), Vector2(1170,471), Vector2(1063,416),
	Vector2(573,798), Vector2(1288,148), Vector2(454,650),
]
const REPRESENTATIVES := [
	"낙양", "허", "진류", "임치", "하비", "업", "계", "진양", "장안 서부", "무위",
	"성도", "남정", "양양", "완", "건업", "수춘", "교지", "양평", "익주군",
]
const EXTRA := [2, 5, 7, 16, 19]
const THEATER := [1, 14, 13, 16, 15, 11]

var _names := {}
var _tabs: TabContainer
var _picker: OptionButton
var _detail: TextureRect
var _back := 0
var _overview_map: TextureRect


func configure(world: Dictionary) -> void:
	for system: Dictionary in world.get("systems", []):
		_names[str(system.get("id", ""))] = str(system.get("name", ""))
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
	frame.ratio = 1670.0 / 940.0
	_tabs.add_child(frame)
	_overview_map = _image("overview.png")
	frame.add_child(_overview_map)
	var map := _overview_map
	for i in POINTS.size():
		var number := i + 1
		var pin := Button.new()
		pin.name = _id(number)
		pin.text = "◇ " + _system_name(number) if number in EXTRA else ""
		pin.flat = number not in EXTRA
		pin.custom_minimum_size = Vector2(35, 35)
		pin.tooltip_text = _system_name(number) + " 상세 지도"
		pin.accessibility_name = pin.tooltip_text
		map.add_child(pin)
		var point: Vector2 = POINTS[i] / Vector2(1670, 940)
		pin.anchor_left = point.x
		pin.anchor_right = point.x
		pin.anchor_top = point.y
		pin.anchor_bottom = point.y
		var half := pin.get_combined_minimum_size() / 2.0
		pin.offset_left = -half.x
		pin.offset_right = half.x
		pin.offset_top = -half.y
		pin.offset_bottom = half.y
		pin.pressed.connect(_open_system.bind(number))
		var representative: String = REPRESENTATIVES[number - 1]
		if not representative.is_empty():
			var caption := UiTheme.label(representative, "Muted", 13)
			caption.add_theme_color_override("font_color", Color("b0e5ef"))
			caption.add_theme_color_override("font_outline_color", Color("07101b"))
			caption.add_theme_constant_override("outline_size", 5)
			caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
			pin.add_child(caption)
			caption.position = Vector2(0, half.y * 2.0 - 3.0)

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
	_show_image(13)

func _open_system(number: int) -> void:
	_back = _tabs.current_tab
	_show_image(number)
	_tabs.current_tab = 2

func _show_image(number: int) -> void:
	_picker.select(number - 1)
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
		var candidate := (point * Vector2(1670, 940)).distance_to(POINTS[i])
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
