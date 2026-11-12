extends MarginContainer
## Visual archive based on the faction hull plates and scenario ship data.

signal back_requested
signal roster_requested

const SPEC_PATH := "res://data/scenarios/base/ship-types.json"
const FACTIONS := [
	["wei", "위 · 조조군", "중장갑과 규격화한 블록형 선체"],
	["shu", "촉 · 유비군", "노출 프레임과 정밀 장거리 화력"],
	["wu", "오 · 손권군", "매끄러운 선체와 고속 기동"],
]

var first_button: Button
var _faction := 0
var _ship := 0
var _specs: Array = []
var _scenario := {}
var _faction_buttons: Array[Button] = []
var _ship_buttons: Array[Button] = []
var _subtitle: Label
var _name: Label
var _role: Label
var _deployment: Label
var _artwork: TextureRect
var _weapons: Label


func _init() -> void:
	name = "FleetShipCatalog"
	for edge in ["left", "right"]:
		add_theme_constant_override("margin_" + edge, 48)
	for edge in ["top", "bottom"]:
		add_theme_constant_override("margin_" + edge, 32)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	column.add_child(header)
	var title := UiTheme.label("함대·전함 도감", "Display", 40)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var roster := _button(header, "적벽 함대 편성", roster_requested.emit)
	roster.name = "OpenScenarioRoster"
	var back := _button(header, "돌아가기", back_requested.emit)
	back.name = "CloseCatalog"
	var factions := HBoxContainer.new()
	factions.add_theme_constant_override("separation", 10)
	column.add_child(factions)
	for index in FACTIONS.size():
		var button := _button(factions, FACTIONS[index][1], _select_faction.bind(index))
		button.toggle_mode = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_faction_buttons.append(button)
	first_button = _faction_buttons[0]

	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
	if not raw is Array or raw.is_empty():
		column.add_child(UiTheme.label("함종 정보를 불러올 수 없습니다.", "Heading", 20, UiTheme.WARN))
		return
	_specs = raw
	_scenario = ScenarioRoster.load_scenario()
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)
	var ship_list := VBoxContainer.new()
	ship_list.add_theme_constant_override("separation", 6)
	body.add_child(ship_list)
	for index in _specs.size():
		var button := _button(ship_list, str(_specs[index].name), _select_ship.bind(index))
		button.custom_minimum_size = Vector2(202, 46)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		_ship_buttons.append(button)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(panel)
	var details := VBoxContainer.new()
	details.add_theme_constant_override("separation", 8)
	panel.add_child(details)
	_subtitle = UiTheme.label("", "Body", 16)
	details.add_child(_subtitle)
	_name = UiTheme.label("", "Title", 32)
	details.add_child(_name)
	_role = UiTheme.label("", "Body", 18)
	details.add_child(_role)
	var art_frame := Control.new()
	art_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art_frame.custom_minimum_size.y = 140
	art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details.add_child(art_frame)
	_artwork = TextureRect.new()
	_artwork.name = "FactionHull"
	_artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art_frame.add_child(_artwork)
	art_frame.resized.connect(func():
		var width := minf(760.0, art_frame.size.x)
		_artwork.position = Vector2((art_frame.size.x - width) * 0.5, 0)
		_artwork.size = Vector2(width, art_frame.size.y))
	_deployment = UiTheme.label("", "Strong", 16)
	details.add_child(_deployment)
	details.add_child(HSeparator.new())
	_weapons = UiTheme.label("", "Body", 17)
	_weapons.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_child(_weapons)
	_refresh()


func _button(parent: Control, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(128, 48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _select_faction(index: int) -> void:
	_faction = index
	_refresh()


func _select_ship(index: int) -> void:
	_ship = index
	_refresh()


func _refresh() -> void:
	for index in _faction_buttons.size():
		_faction_buttons[index].set_pressed_no_signal(index == _faction)
	if _specs.is_empty():
		return
	for index in _ship_buttons.size():
		_ship_buttons[index].set_pressed_no_signal(index == _ship)
	var faction: Array = FACTIONS[_faction]
	var spec: Dictionary = _specs[_ship]
	var faction_id: String = ScenarioRoster.FACTION_KEY.find_key(faction[0])
	var count := 0
	for squadron: Dictionary in ScenarioRoster.deployed(_scenario, faction_id, "표준"):
		for entry: Dictionary in squadron.get("composition", []):
			if entry.ship_type_id == spec.id:
				count += int(entry.count)
	_subtitle.text = faction[1] + "  ·  " + faction[2]
	_subtitle.add_theme_color_override("font_color", Factions.of(faction[0]).rim)
	_name.text = spec.name
	_role.text = "%s  ·  전장 %d m  ·  %s" % [spec.ship_class, int(spec.length_m), spec.role]
	var path := ScenarioRoster.report_hull_path(faction[0], spec.id)
	_artwork.texture = load(path) as Texture2D if ResourceLoader.exists(path, "Texture2D") else null
	_deployment.text = "적벽 전투 표준 편성 · %d척 배치" % count
	_weapons.text = "장비  ·  " + "  /  ".join(spec.weapon_specs)
