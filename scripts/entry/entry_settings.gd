extends Control
## The start screen's reference library and device settings.

signal closed

const DeckScreens := preload("res://hud/ui_kit/deck_screens.gd")
const Roster := preload("res://hud/ui_kit/roster_screen.gd")
const FormationGuide := preload("res://hud/ui_kit/formation_guide.gd")
const Catalog := preload("res://scripts/entry/entry_ship_catalog.gd")
const NavigationAtlas := preload("res://view/world/navigation_atlas.gd")
const EntryMap := preload("res://scripts/entry/entry_map.gd")
const PAD_KEYS := {
	JOY_BUTTON_A: KEY_ENTER, JOY_BUTTON_B: KEY_ESCAPE,
	JOY_BUTTON_DPAD_UP: KEY_UP, JOY_BUTTON_DPAD_DOWN: KEY_DOWN,
	JOY_BUTTON_DPAD_LEFT: KEY_LEFT, JOY_BUTTON_DPAD_RIGHT: KEY_RIGHT,
}

var renderer: FleetRenderer
var sound: UiSound
var _pages := {}
var _page_focus := {}
var _page := ""
var _menu_focus: Button
var _catalog_focus: Button
var _map_focus: Button
var _atlas: Control
var _detail_focus: Button
var _portraits := {}


func _ready() -> void:
	name = "EntrySettings"
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiTheme.build().duplicate() as Theme
	var focus := UiTheme.flat(Color.TRANSPARENT, UiTheme.GOLD_HI, 2)
	for type in ["Button", "CheckButton", "OptionButton", "HSlider"]:
		theme.set_stylebox("focus", type, focus)
	var background := TextureRect.new()
	background.texture = preload("res://assets/world_atlas/red-cliffs-reference-sky.jpg")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	var shade := ColorRect.new()
	shade.color = Color("#080e18e8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	show_screen("menu")


func show_screen(next: String) -> void:
	if not _pages.has(next):
		var page := _build_page(next)
		add_child(page)
		page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_pages[next] = page
	if _pages.has(_page):
		var current: Control = _pages[_page]
		var focused := get_viewport().gui_get_focus_owner()
		if focused and current.is_ancestor_of(focused):
			_page_focus[_page] = focused
		current.hide()
	_page = next
	var active: Control = _pages[next]
	active.show()
	if active.has_method("on_show"):
		active.on_show()
	var previous_focus: Control = _page_focus.get(next)
	if is_instance_valid(previous_focus) and previous_focus.is_visible_in_tree():
		previous_focus.grab_focus()
		return
	match next:
		"menu": _menu_focus.grab_focus()
		"catalog": _catalog_focus.grab_focus()
		"roster": active.find_child("CloseRoster", true, false).grab_focus()
		"formation_guide": active.formation_picker.grab_focus()
		"atlas": _map_focus.grab_focus()
		"map_detail": _detail_focus.grab_focus()


func _build_page(next: String) -> Control:
	match next:
		"catalog":
			var catalog := Catalog.new()
			catalog.roster_requested.connect(show_screen.bind("roster"))
			catalog.back_requested.connect(show_screen.bind("menu"))
			_catalog_focus = catalog.first_button
			return catalog
		"roster":
			var roster := Roster.new(self, _portrait_tex)
			roster.reveal = true
			roster.back_to = "catalog"
			return roster
		"formation_guide":
			renderer = FleetRenderer.new()
			add_child(renderer)
			var shu_squadrons := ScenarioRoster.squadrons_of(ScenarioRoster.load_scenario(), "liu_bei")
			return FormationGuide.new(self, shu_squadrons)
		"atlas":
			_atlas = NavigationAtlas.new()
			_atlas.name = "ReferenceAtlas"
			_atlas.configure({})
			_atlas.red_cliffs_requested.connect(show_screen.bind("map_detail"))
			var page := VBoxContainer.new()
			_map_focus = _button(page, "설정으로 돌아가기", show_screen.bind("menu"))
			_map_focus.size_flags_horizontal = Control.SIZE_SHRINK_END
			_atlas.size_flags_vertical = Control.SIZE_EXPAND_FILL
			page.add_child(_atlas)
			return _frame(page)
		"map_detail":
			var page := VBoxContainer.new()
			_detail_focus = _button(page, "천하 지도로 돌아가기", show_screen.bind("atlas"))
			_detail_focus.size_flags_horizontal = Control.SIZE_SHRINK_END
			var map := EntryMap.new()
			map.detailed = true
			map.size_flags_vertical = Control.SIZE_EXPAND_FILL
			page.add_child(map)
			return _frame(page)
		"preferences":
			sound = UiSound.new()
			sound.play_one_shots = DisplayServer.get_name() != "headless"
			add_child(sound)
			return DeckScreens.SettingsScreen.new(self, "menu", true)
	return _build_menu()


func _build_menu() -> Control:
	var page := Control.new()
	var panel := ScreenKit.centered(page, Vector2(660, 486), UiTheme.ornate())
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	var margin := _frame(content, 38, 30)
	panel.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_child(UiTheme.label("설정", "Display", 48))
	var separator := HSeparator.new()
	content.add_child(separator)
	_menu_focus = _button(content, "함대·전함 도감", show_screen.bind("catalog"))
	_button(content, "촉 함선으로 보는 진형", show_screen.bind("formation_guide"))
	_button(content, "천하 지도", show_screen.bind("atlas"))
	_button(content, "화면·진행·소리 설정", show_screen.bind("preferences"))
	_button(content, "시작 화면으로 돌아가기", closed.emit)
	return page


func _frame(content: Control, horizontal := 28, vertical := 18) -> MarginContainer:
	var frame := MarginContainer.new()
	for edge in ["left", "right"]:
		frame.add_theme_constant_override("margin_" + edge, horizontal)
	for edge in ["top", "bottom"]:
		frame.add_theme_constant_override("margin_" + edge, vertical)
	frame.add_child(content)
	return frame


func _button(parent: Control, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size = Vector2(0, 54)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 19)
	button.pressed.connect(action)
	parent.add_child(button)
	return button


func _portrait_tex(index: int) -> Texture2D:
	if _portraits.has(index):
		return _portraits[index]
	var path := Commanders.portrait_path(index)
	var image := load(path) as Texture2D if not path.is_empty() else null
	if image == null:
		return null
	var portrait := AtlasTexture.new()
	portrait.atlas = image
	portrait.region = Rect2(0, 0, image.get_width(), image.get_width())
	_portraits[index] = portrait
	return portrait


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventJoypadButton:
		return
	if not PAD_KEYS.has(event.button_index):
		return
	# Forward controller presses to the focused Control, including slider and popup behavior.
	get_viewport().set_input_as_handled()
	var key := InputEventKey.new()
	key.keycode = PAD_KEYS[event.button_index]
	key.pressed = event.pressed
	Input.parse_input_event.call_deferred(key)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	match _page:
		"menu": closed.emit()
		"roster": show_screen("catalog")
		"map_detail": show_screen("atlas")
		"atlas":
			if not _atlas.back_to_overview():
				show_screen("menu")
		"preferences": _pages.preferences._cancel()
		_: show_screen("menu")
