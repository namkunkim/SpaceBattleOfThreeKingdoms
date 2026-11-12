extends Control
signal continuation_requested(origin: String)
signal detail_prepared(context: Dictionary)
signal sortie_requested
var campaign_enabled := false
var campaign_busy := false
var campaign_notice: Label
const Flow := preload("res://scripts/entry/entry_flow.gd")
const MapView := preload("res://scripts/entry/entry_map.gd")
const Prologue := preload("res://hud/ui_kit/prologue_text.gd")
const EntrySettings := preload("res://scripts/entry/entry_settings.gd")
const PROLOGUE_ILLUSTRATIONS := [
	"res://assets/prologue/01-empire.png",
	"res://assets/prologue/02-fracture.png",
	"res://assets/prologue/03-advance.png",
	"res://assets/prologue/04-surrender.png",
	"res://assets/prologue/05-alliance-request.png",
	"res://assets/prologue/06-allied-rendezvous.png",
	"res://assets/prologue/07-linked-fleet.png",
	"res://assets/prologue/08-huang-gai-letter.png",
]
@export_enum("new", "resume", "settlement") var entry_origin := "new"
@export var detail_scene := "res://scenes/entry/PreparedMap.tscn"
@export var auto_prompt_seconds := 2.0
var flow := Flow.new()
var body: VBoxContainer
var _layout_scale := 1.0
var gate_remaining := 0.0
var buttons: Array[Button] = []
var prepared_count := 0
var _settings_overlay: EntrySettings
var _settings_focus: Control

func _ready() -> void:
	flow.begin(entry_origin)
	_build()
	_update_layout_scale()
	_render()
	get_window().size_changed.connect(_update_layout_scale)
	if flow.state == Flow.State.BYPASS:
		continuation_requested.emit(entry_origin)

func _build() -> void:
	var ui := Theme.new()
	ui.default_font = load("res://assets/fonts/Pretendard-Regular.otf")
	ui.default_font_size = 18
	theme = ui
	var backdrop := TextureRect.new()
	backdrop.texture = load("res://assets/world_atlas/red-cliffs-reference-sky.jpg")
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.07, 0.69)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right"]:
		margin.add_theme_constant_override("margin_" + side, 36)
	for side in ["top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	margin.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	scroll.add_child(body)


func _update_layout_scale() -> void:
	var logical_size := get_viewport_rect().size
	var physical_size := Vector2(get_window().size)
	var scale := minf(physical_size.x / maxf(logical_size.x, 1.0),
		physical_size.y / maxf(logical_size.y, 1.0))
	_layout_scale = maxf(scale, 0.25) if scale < 0.6 else 1.0
	for child in body.get_children():
		_apply_layout(child)

func _apply_layout(control: Control) -> void:
	var compact := _layout_scale < 1.0
	if control.has_meta("hide_in_compact"):
		control.visible = not compact
	if control is Label:
		var normal_size: int = control.get_meta("normal_font_size", 18)
		var compact_size := 20.0 if normal_size >= 50 else (14.0 if normal_size >= 26 else 12.0)
		control.add_theme_font_size_override("font_size",
			maxi(normal_size, ceili(compact_size / _layout_scale)) if compact else normal_size)
	elif control is Button:
		control.add_theme_font_size_override("font_size", ceili(13.0 / _layout_scale) if compact else 18)
		control.custom_minimum_size.y = ceilf(30.0 / _layout_scale) if compact else 54.0
	elif control is MapView:
		control.compact_scale = _layout_scale

func _style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 24
	style.content_margin_right = 24
	return style

func _space() -> void:
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	space.custom_minimum_size.y = 16
	body.add_child(space)

func _hero(title: String, parent: Control = null) -> void:
	var label := Label.new()
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifKR-SemiBold.otf"))
	label.set_meta("normal_font_size", 64)
	label.add_theme_color_override("font_color", Color("#eedbc0"))
	_apply_layout(label)
	(parent if parent != null else body).add_child(label)

func _label(value: String, font_size := 22, hide_in_compact := false, parent: Control = null) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.set_meta("normal_font_size", font_size)
	if hide_in_compact:
		label.set_meta("hide_in_compact", true)
	label.add_theme_color_override("font_color", Color("#d4dee4") if font_size >= 20 else Color("#adc1ce"))
	_apply_layout(label)
	(parent if parent != null else body).add_child(label)
	return label

func _button(value: String, action: String, parent: Control = null) -> Button:
	var button := Button.new()
	button.text = value
	_apply_layout(button)
	button.add_theme_color_override("font_color", Color("#ecd4ae"))
	button.add_theme_stylebox_override("normal", _style(Color("#10212de8"), Color("#7a705b")))
	button.add_theme_stylebox_override("hover", _style(Color("#203845"), Color("#e6c18c")))
	button.add_theme_stylebox_override("pressed", _style(Color("#314350"), Color("#e6c18c")))
	button.add_theme_stylebox_override("focus", _style(Color("#00000000"), Color("#ffe4b5")))
	button.focus_mode = Control.FOCUS_ALL
	var token := flow.revision
	button.pressed.connect(func(): request(action, token))
	# Native screen-touch support without changing project input settings.
	button.gui_input.connect(func(event: InputEvent):
		if event is InputEventScreenTouch and not event.pressed:
			if Rect2(Vector2.ZERO, button.size).has_point(event.position):
				request(action, token)
				button.accept_event())
	(parent if parent != null else body).add_child(button)
	buttons.append(button)
	return button

func request(action: String, token: int, region := Flow.REGION) -> bool:
	if gate_remaining > 0.0 or campaign_busy or is_instance_valid(_settings_overlay): return false
	if action == "settings" and token == flow.revision and flow.state == Flow.State.SELECT:
		_open_settings()
		return true
	if campaign_enabled and token == flow.revision:
		if action == "sortie" and flow.state == Flow.State.READY:
			campaign_busy = true
			gate_remaining = 0.25
			for button in buttons: button.disabled = true
			sortie_requested.emit()
			return true
		if action == "continue" and flow.state in [Flow.State.SELECT, Flow.State.READY]:
			campaign_busy = true
			gate_remaining = 0.25
			for button in buttons: button.disabled = true
			continuation_requested.emit("resume")
			return true
	if not flow.act(action, token, region): return false
	gate_remaining = 0.25
	_render()
	return true

func _render() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	buttons.clear()
	_label("SPACE BATTLE OF THREE KINGDOMS     /     RED CLIFFS", 16, true)
	match flow.state:
		Flow.State.SELECT:
			_space()
			_hero("적벽대전")
			_label("조조가 남진하고, 손권과 유비는 형초에서 함대를 모은다.", 22)
			_space()
			_button("적벽대전 시작", "start")
			_button("설정", "settings")
		Flow.State.STORY:
			_render_story()
		Flow.State.MAP, Flow.State.CONFIRM:
			_label("천하 항로도  /  적벽 작전", 26)
			var map := MapView.new()
			map.custom_minimum_size = Vector2(280, 260)
			map.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_apply_layout(map)
			body.add_child(map)
			if not map.prepared:
				flow.error = map.failure
				flow.retry_state = flow.state
				flow.state = Flow.State.ERROR
				flow.revision += 1
				_render.call_deferred()
				return
			if flow.state == Flow.State.MAP and campaign_enabled:
				var marker := _button("적벽", "inspect", map)
				marker.name = "RedCliffsMarker"
				var place_marker := func():
					marker.size = Vector2(78, 54)
					marker.position = map.red_cliffs_position() + Vector2(-9, -13)
				map.resized.connect(place_marker)
				place_marker.call()
			elif flow.state == Flow.State.MAP:
				_button("◎ 적벽 · 교전 신호 확인", "enter")
				var token := flow.revision
				get_tree().create_timer(maxf(auto_prompt_seconds, 0.3)).timeout.connect(func():
					request("enter", token))
			else:
				_label("긴급 교신  /  적벽에서 전투 발생", 26)
				_label("적 함대와 교전이 시작되었습니다. 적벽 상세 맵으로 진입하시겠습니까?\n예: 준비 상태로 진입 / 아니오: 게임이 종료됩니다.", 20)
				_button("예 · 상세 맵 진입", "yes")
				_button("아니오 · 게임 종료", "no")
		Flow.State.LOADING:
			_label("적벽 상세 맵을 불러오는 중…")
			_load_detail.call_deferred(flow.revision)
		Flow.State.ERROR:
			_label("작전 정보를 불러오지 못했습니다.", 28)
			_label(flow.error, 18)
			_button("재시도", "retry")
			_button("게임 종료", "exit")
		Flow.State.BYPASS:
			_label("기존 진행 복귀 경로입니다. 새 서사와 전투 문의를 생략합니다.")
			_label("독립 실행에는 저장 재개/결산 연결이 없습니다. 통합 라우터에서 기존 경로를 연결하세요.", 18)
			_button("게임 종료", "exit")
		Flow.State.EXIT:
			_label("게임을 종료합니다…")
			get_tree().quit(0)
	if not buttons.is_empty():
		(buttons.back() if flow.state == Flow.State.STORY else buttons[0]).grab_focus()
	if flow.state != Flow.State.READY:
		_label("방향키 · Tab  이동     Enter · A  선택     마우스 · 터치 지원", 14, true)

func _render_story() -> void:
	var chapter: Array = Prologue.PAGES[flow.page]
	var columns := HBoxContainer.new()
	columns.name = "PrologueChapter"
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation", 26)
	body.add_child(columns)

	var art_frame := PanelContainer.new()
	art_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var art_style := _style(Color("#080e18"), Color("#52677a"))
	art_style.content_margin_left = 1
	art_style.content_margin_right = 1
	art_style.content_margin_top = 1
	art_style.content_margin_bottom = 1
	art_frame.add_theme_stylebox_override("panel", art_style)
	columns.add_child(art_frame)
	var illustration := TextureRect.new()
	illustration.name = "PrologueIllustration"
	illustration.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	illustration.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	illustration.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art_path: String = PROLOGUE_ILLUSTRATIONS[flow.page]
	if ResourceLoader.exists(art_path, "Texture2D"):
		illustration.texture = load(art_path) as Texture2D
	art_frame.add_child(illustration)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 568
	sidebar.add_theme_constant_override("separation", 12)
	columns.add_child(sidebar)
	_label("서막   /   %02d · %02d" % [flow.page + 1, Prologue.PAGES.size()], 18, false, sidebar)
	_hero(chapter[0], sidebar)
	var prose := _label(chapter[1], 25, false, sidebar)
	prose.add_theme_constant_override("line_spacing", 8)
	var map := MapView.new()
	map.name = "PrologueAtlas"
	map.story_focus = chapter[2]
	map.custom_minimum_size.y = 248
	map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(map)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 12)
	body.add_child(actions)
	_button("서사 건너뛰기", "skip", actions)
	_button("전략 맵으로" if flow.page == Prologue.PAGES.size() - 1 else "다음", "next", actions)

func _open_settings() -> void:
	_settings_focus = get_viewport().gui_get_focus_owner()
	touch_button = null
	touch_index = -1
	_settings_overlay = EntrySettings.new()
	_settings_overlay.closed.connect(_close_settings)
	body.hide()
	add_child(_settings_overlay)
	_settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _close_settings() -> void:
	_settings_overlay.hide()
	_settings_overlay.queue_free()
	_settings_overlay = null
	body.show()
	if is_instance_valid(_settings_focus):
		_settings_focus.grab_focus()
	else:
		buttons[0].grab_focus()
	_settings_focus = null


func _load_detail(token: int) -> void:
	if flow.state != Flow.State.LOADING or token != flow.revision: return
	var packed: PackedScene = null
	if ResourceLoader.exists(detail_scene, "PackedScene"):
		packed = load(detail_scene) as PackedScene
	var detail: Node = packed.instantiate() if packed != null else null
	if not detail is Control:
		if detail != null: detail.free()
		flow.loaded(token, false, "적벽 지도 파일을 확인한 뒤 다시 시도해 주세요.")
		_render()
		return
	if not detail.has_method("prepare") or not detail.prepare():
		var message: String = str(detail.get("failure")) if detail.has_method("prepare") else "지도 형식이 올바르지 않습니다."
		detail.free()
		flow.loaded(token, false, message)
		_render()
		return
	flow.loaded(token, true)
	_render()
	_label("적벽  /  전술 준비", 28)
	_label("작전 대기     •     전투는 시작되지 않았습니다", 18)
	_apply_layout(detail)
	if campaign_enabled:
		var local_map := MapView.new()
		local_map.name = "RedCliffsLocalMap"
		local_map.local_context = true
		local_map.custom_minimum_size = Vector2(280, 190)
		_apply_layout(local_map)
		body.add_child(local_map)
	body.add_child(detail)
	_label("임무: 연합 집결 위치와 적 접근 방향을 확인하고 적벽 항로 방어를 준비하십시오.", 20)
	_label("연합 집결지에서 정면 항로를 따라 작전 목표를 확인하십시오.", 18, true)
	if campaign_enabled:
		_button("출격 · 실제 전장 준비", "sortie")
		_button("항로도로 돌아가기", "map")
		_button("기존 진행 · 이어하기 / 결산", "continue")
		campaign_notice = Label.new()
		campaign_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		campaign_notice.text = "출격 후 실제 전장에서 시작을 눌러 전투를 진행합니다."
		_apply_layout(campaign_notice)
		body.add_child(campaign_notice)
	_button("게임 종료", "exit")
	buttons[0].grab_focus()
	prepared_count += 1
	detail_prepared.emit({"origin": flow.origin, "region_id": Flow.REGION, "scenario_id": Flow.SCENARIO, "battle_started": false})

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(_settings_overlay):
		return
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	gate_remaining = maxf(0.0, gate_remaining - delta)

var touch_button: Button
var touch_index := -1
func _input(event: InputEvent) -> void:
	if is_instance_valid(_settings_overlay):
		return
	if event is InputEventJoypadButton and event.pressed and not buttons.is_empty():
		var focused := get_viewport().gui_get_focus_owner()
		var index := buttons.find(focused)
		if event.button_index == JOY_BUTTON_A:
			if focused is Button and buttons.has(focused): focused.pressed.emit()
		elif event.button_index in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_RIGHT]:
			buttons[(index + 1) % buttons.size()].grab_focus()
		elif event.button_index in [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_LEFT]:
			buttons[posmod(index - 1, buttons.size())].grab_focus()
		get_viewport().set_input_as_handled()
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			for button in buttons:
				if button.get_global_rect().has_point(event.position):
					touch_button = button
					touch_index = event.index
					break
		elif not event.pressed and event.index == touch_index:
			var selected := touch_button
			touch_button = null
			touch_index = -1
			if is_instance_valid(selected) and not selected.is_queued_for_deletion() and selected.get_global_rect().has_point(event.position):
				selected.pressed.emit()
		get_viewport().set_input_as_handled()




func campaign_rejected(message: String) -> void:
	campaign_busy = false
	for button in buttons: button.disabled = false
	if is_instance_valid(campaign_notice): campaign_notice.text = message
	else: _label(message, 18)
	if not buttons.is_empty(): buttons[0].grab_focus()

func restore_prepared_entry() -> void:
	flow.state = Flow.State.LOADING
	flow.revision += 1
	gate_remaining = 0.25
	_render()
