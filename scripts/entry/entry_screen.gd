extends Control
signal continuation_requested(origin: String)
signal detail_prepared(context: Dictionary)
signal sortie_requested
var campaign_enabled := false
var campaign_busy := false
var campaign_notice: Label
const Flow := preload("res://scripts/entry/entry_flow.gd")
const MapView := preload("res://scripts/entry/entry_map.gd")
const STORY := [
	"북부 성역을 통합한 조조의 함대가 장강 대항로를 따라 남하한다. 항로 끝에는 남부 성역으로 향하는 관문, 적벽이 있다.",
	"손권과 유비는 연합 함대를 결성했다. 적벽의 좁은 항로와 성운 경계에서 적의 진격을 저지해야 한다.",
	"적벽 전초 구역에서 교전 신호가 도착했다. 연합 전술 지휘관인 당신은 정지된 전술 상황을 인계받아 방어 준비를 확인한다."
]
@export_enum("new", "resume", "settlement") var entry_origin := "new"
@export var detail_scene := "res://scenes/entry/PreparedMap.tscn"
@export var auto_prompt_seconds := 2.0
var flow := Flow.new()
var body: VBoxContainer
var gate_remaining := 0.0
var buttons: Array[Button] = []
var prepared_count := 0

func _ready() -> void:
	flow.begin(entry_origin)
	_build()
	_render()
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

func _hero(title: String) -> void:
	var label := Label.new()
	label.text = title
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_override("font", load("res://assets/fonts/NotoSerifKR-SemiBold.otf"))
	label.add_theme_font_size_override("font_size", 64)
	label.add_theme_color_override("font_color", Color("#eedbc0"))
	body.add_child(label)

func _label(value: String, font_size := 22) -> void:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("#d4dee4") if font_size >= 20 else Color("#98aebc"))
	body.add_child(label)

func _button(value: String, action: String) -> void:
	var button := Button.new()
	button.text = value
	button.custom_minimum_size = Vector2(0, 54)
	button.add_theme_font_size_override("font_size", 18)
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
	body.add_child(button)
	buttons.append(button)

func request(action: String, token: int, region := Flow.REGION) -> bool:
	if gate_remaining > 0.0 or campaign_busy: return false
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
	_label("SPACE BATTLE OF THREE KINGDOMS     /     RED CLIFFS", 16)
	match flow.state:
		Flow.State.SELECT:
			_space()
			_label("시나리오  01     /     건안 13년", 18)
			_hero("적벽대전")
			_label("하나의 항로. 두 세력의 운명.", 28)
			_label("남하하는 조조의 함대에 맞서, 손권과 유비의 연합을 이끄십시오.\n형초의 항로에서 시작되는 첫 방어 작전.", 20)
			_space()
			_button("적벽대전 선택 · 시작", "start")
			if campaign_enabled: _button("기존 진행 · 이어하기 / 결산", "continue")
			_label("다른 시나리오 · 준비 중", 18)
		Flow.State.STORY:
			_space()
			_label("작전 서문   /   %02d · 03" % (flow.page + 1), 18)
			_hero(["남하", "연합", "적벽"][flow.page])
			_label(STORY[flow.page], 24)
			_space()
			_button("전략 맵으로" if flow.page == 2 else "다음", "next")
			_button("서사 건너뛰기", "skip")
		Flow.State.MAP, Flow.State.CONFIRM:
			_label("천하 항로도  /  적벽 작전", 26)
			var map := MapView.new()
			map.custom_minimum_size = Vector2(280, 260)
			map.size_flags_vertical = Control.SIZE_EXPAND_FILL
			body.add_child(map)
			if not map.prepared:
				flow.error = map.failure
				flow.retry_state = flow.state
				flow.state = Flow.State.ERROR
				flow.revision += 1
				_render.call_deferred()
				return
			if flow.state == Flow.State.MAP:
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
		buttons[0].grab_focus()
	if flow.state != Flow.State.READY:
		_label("방향키 · Tab  이동     Enter · A  선택     마우스 · 터치 지원", 14)

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
	body.add_child(detail)
	_label("임무: 연합 집결 위치와 적 접근 방향을 확인하고 적벽 항로 방어를 준비하십시오.", 20)
	_label("연합 집결지에서 정면 항로를 따라 작전 목표를 확인하십시오.", 18)
	if campaign_enabled:
		_button("출격 · 실제 전장 준비", "sortie")
		_button("기존 진행 · 이어하기 / 결산", "continue")
		campaign_notice = Label.new()
		campaign_notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		campaign_notice.text = "출격 후 실제 전장에서 시작을 눌러 전투를 진행합니다."
		body.add_child(campaign_notice)
	_button("게임 종료", "exit")
	buttons[0].grab_focus()
	prepared_count += 1
	detail_prepared.emit({"origin": flow.origin, "region_id": Flow.REGION, "scenario_id": Flow.SCENARIO, "battle_started": false})

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	gate_remaining = maxf(0.0, gate_remaining - delta)

var touch_button: Button
var touch_index := -1
func _input(event: InputEvent) -> void:
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
