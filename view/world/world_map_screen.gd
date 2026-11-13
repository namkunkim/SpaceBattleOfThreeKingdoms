class_name WorldMapScreen
extends Control

# 천하 지도 화면(홈). docs/battle-core/WORLD-MAP-LINK.md §2·§4.
# 흐름: 천하 Z0 → 형주 Z2(시나리오 카드) → 출격 연출 Z3 → 전장(직접 지휘) 또는 자동 해결 → 결산(권역 색·결말·후일담).
# 화면 단위 1600×900(stretch expand). 누르는 것은 모두 58 단위 이상(11" 태블릿 48dp, tests/world_link.gd 검사).
# 천하 지도는 상태를 저장하지 않는다. 결과는 연출로만 보여 준다(캠페인 없음).

const WORLD_PATH := "res://data/scenarios/base/world_208.json"
const W := preload("res://hud/ui_kit/deck_widgets.gd")
const CARD_W := 468.0
const M := 28.0
const BTN_H := 58.0
const LEVEL_TITLE := {"z0": "천하", "z2": "형주 성역", "z3": "구지 궤도"}
const LEVEL_SUB := {"z0": "19성계 · 건안 13년의 세력", "z2": "4권역 · 누가 어디를 쥐었나", "z3": "태양계권 · 적벽 전장"}
const OWNER_NAME := {"wei": "조조", "wu": "손권", "shu": "유비", "contested": "경합", "none": "미개척"}
const KIND_TITLE := {"alliance_win": "연합 승리", "alliance_limited": "제한적 승리", "cao_win": "조조 승리"}
# 출격 연출: [시작 초, 카메라 단계, 자막]
const SORTIE := [
	[0.0, "z2", "형주. 항로가 모이는 천하의 목구멍."],
	[1.8, "z3", "구지의 궤도. 조조의 대군이 오림에 머물렀다."],
	[4.2, "", "손권과 유비의 함대가 적벽에서 그를 맞는다."],
	[6.6, "end", ""],
]

var world: Dictionary
var canvas: WorldCanvas
var hud: Control
var sound: UiSound
var state := "browse"          # browse | sortie | resolve | result
var brief: BattleBrief
var resolver: AutoResolver
var outcome: BattleOutcome

var _atlas: Control
var _atlas_backdrop: ColorRect
var _header: Control
var _title: Label
var _sub: Label
var _crumbs := {}
var _card: PanelContainer
var _result: PanelContainer
var _cta: PanelContainer
var _chip: PanelContainer
var _chip_label: Label
var _chip_t := 0.0
var _caption: PanelContainer
var _caption_label: Label
var _skip: Button
var _resolve: Control
var _resolve_cancel: Button
var _resolve_retry: Button
var _legend: Control
var _diff_btns := {}
var _mode_btns := {}
var _diff_note: Label
var _mode_note: Label
var _product_sortie: Button
var _sortie_t := 0.0
var _sortie_i := 0
var _sortie_origin := {}
var _restore_job: RefCounted
var _import_dialog: FileDialog
var _replay_dialog: FileDialog
var _replay_overlay: ColorRect
var _replay_input_lock := false
var _replay_hud_visible := true
var _replay_focus: Control
var _restore_overlay: Control
var _restore_label: Label
var _restore_input_lock := false
const OperationHost := preload("res://scripts/first_operation_host.gd")
const ReplayCodec := preload("res://scripts/first_operation_replay_codec.gd")
const ReplayViewer := preload("res://scenes/FirstOperationReplayViewer.tscn")
const FirstOperationAutoWorker := preload("res://scripts/world/first_operation_auto_worker.gd")

var _operation_worker: FirstOperationAutoWorker
var _operation_auto_origin := {}
var _operation_auto_progress := {}
var _operation_auto_cancelling := false
var _operation_auto_pending: BattleOutcome
var _operation_auto_save_error := ""
var _title_button: Button
var _atlas_resume_button: Button
var _difficulty := "표준"
var _mode := "direct"
var _res_labels := {}
var _was_flying := false

func _ready() -> void:
	theme = UiTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	GameSettings.apply(get_window())
	if DisplayServer.get_name() != "headless":
		get_window().title = GameLocale.text("성한지 — 적벽")
	world = read_world()
	var link := _link()
	if link:
		_difficulty = link.last_difficulty
		_mode = link.last_mode
	canvas = WorldCanvas.new()
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(canvas)
	canvas.setup(world)
	canvas.system_tapped.connect(_on_system)
	canvas.region_tapped.connect(_on_region)
	canvas.marker_tapped.connect(_on_marker)
	canvas.level_changed.connect(_on_level)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var safe := SafeArea.new()
	safe.name = "SafeArea"
	add_child(safe)
	safe.setup(hud)
	sound = UiSound.new()
	# Keep event history without starting audio playback in a headless map.
	sound.play_one_shots = DisplayServer.get_name() != "headless"
	sound.name = "UiSound"
	add_child(sound)
	_atlas_backdrop = ColorRect.new()
	_atlas_backdrop.color = Color("090f18")
	_atlas_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(_atlas_backdrop)
	_atlas_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_atlas_backdrop.hide()
	_atlas = preload("res://view/world/navigation_atlas.gd").new()
	_atlas.name = "WorldAtlas"
	_atlas.configure(world)
	_atlas.red_cliffs_requested.connect(_open_atlas_red_cliffs)
	hud.add_child(_atlas)
	_atlas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_atlas.offset_bottom = -M - 108
	_atlas.hide()
	_build_header()
	_build_legend()
	_build_card()
	_build_result()
	_build_cta()
	_title_button = _btn("타이틀로", false, 144)
	hud.add_child(_title_button)
	_title_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_title_button.offset_left = -M - 144
	_title_button.offset_right = -M
	_title_button.offset_top = -M - BTN_H
	_title_button.offset_bottom = -M
	_title_button.hide()
	_title_button.pressed.connect(_return_to_title)
	_build_atlas_resume()
	_build_chip()
	_build_caption()
	_build_resolve()
	await get_tree().process_frame
	var restore: Dictionary = link.take_map_restore() if link else {}
	if not restore.is_empty():
		if restore.result_visible:
			_show_result(restore.outcome, false)
		else:
			_enter_browse()
		outcome = restore.outcome
		canvas.jump_to(restore.level)
		_restore_sortie_origin(restore)
		return
	var o: BattleOutcome = link.take_outcome() if link else null
	if o:
		_show_result(o)
	else:
		var restored: Dictionary = link.restore_operation_settlement() if link else {"ok": true, "outcome": null}
		if restored.ok and restored.outcome != null:
			_show_result(restored.outcome)
			return
		if link:
			var native: Dictionary = link.restore_native_o07_settlement()
			if native.ok and native.outcome != null:
				_show_result(native.outcome)
				return
			if restored.ok:
				restored = native
		_enter_browse()
		_cta.visible = true
		_update_inset()
		canvas.jump_to("z0")
		canvas.arrows = "advance"
		if not restored.ok:
			_show_chip(OperationHost.error_text(restored))

static func read_world() -> Dictionary:
	var f := FileAccess.open(WORLD_PATH, FileAccess.READ)
	if f == null:
		push_error("천하 지도 데이터가 없다: " + WORLD_PATH)
		return {}
	var d: Variant = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

func _link() -> Node:
	return get_node_or_null("/root/WorldLink")

# ------------------------------------------------------------ 조립
func _panel(style: StyleBox = null) -> PanelContainer:
	var p := PanelContainer.new()
	var st: StyleBox = style if style else UiTheme.ornate()
	st.content_margin_left = 24
	st.content_margin_right = 24
	st.content_margin_top = 22
	st.content_margin_bottom = 22
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(p)
	return p

func _wrap(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 10
	return l

func _btn(text: String, primary := false, w := 0.0) -> Button:
	var b: Button
	if primary:
		b = ScreenKit.menu_button(text, true)
	else:
		b = Button.new()   # 보조 버튼은 테두리가 있는 기본 버튼(터치 목표가 눈에 보이게)
		b.text = text
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.custom_minimum_size = Vector2(w, BTN_H)
	b.add_theme_font_size_override("font_size", 20 if primary else 17)
	b.pressed.connect(func(): sound.play("button"))
	return b

func _toggle(text: String, group: ButtonGroup) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.button_group = group
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, BTN_H)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 17)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b

func _section(parent: Control, text: String) -> void:
	var l := UiTheme.label(text, "Eyebrow", 13)
	parent.add_child(l)

func _build_header() -> void:
	var col := VBoxContainer.new()
	_header = col
	col.position = Vector2(M, 22)
	col.add_theme_constant_override("separation", 2)
	hud.add_child(col)
	col.add_child(UiTheme.label(str(world.get("era", "")), "Eyebrow", 13))
	_title = UiTheme.label("천하", "Title", 34)
	col.add_child(_title)
	_sub = UiTheme.label("", "Muted", 15)
	col.add_child(_sub)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	col.add_child(row)
	var g := ButtonGroup.new()
	for l in ["z0", "z2", "z3"]:
		var b := _toggle(["천하", "형주", "구지"][["z0", "z2", "z3"].find(l)], g)
		b.custom_minimum_size = Vector2(104, BTN_H)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		b.pressed.connect(func(): _go_level(l))
		row.add_child(b)
		_crumbs[l] = b

func _build_legend() -> void:
	_legend = W.DrawPanel.new(_draw_legend, UiTheme.ornate(false))
	hud.add_child(_legend)
	_legend.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_legend.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_legend.offset_left = M
	_legend.offset_right = M + 214
	_legend.offset_top = -M - 168
	_legend.offset_bottom = -M

func _draw_legend(c: Control) -> void:
	var rows := [["wei", "조조"], ["wu", "손권"], ["shu", "유비"], ["contested", "경합"], ["other", "그 밖의 세력"]]
	var y := 26.0
	for r in rows:
		var col := WorldCanvas.faction_color(r[0])
		if r[0] in ["wei", "wu", "shu"]:
			UiDraw.faction_glyph(c, Vector2(26, y - 5), 7.0, r[0], col)
		else:
			c.draw_circle(Vector2(26, y - 5), 6.0, col)
		UiDraw.text(c, Vector2(46, y), r[1], "medium", 15, UiTheme.INK_2)
		y += 27.0

func _build_card() -> void:
	_card = _panel()
	_anchor_right(_card)
	var development := OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10 if development else 8)
	_card.add_child(v)
	v.add_child(UiTheme.label("시나리오 · 건안 13년 겨울", "Eyebrow", 13))
	v.add_child(UiTheme.label("적벽", "Display", 52))
	_add_restore_actions(v)
	var go := _btn("출  격", true)
	go.custom_minimum_size.y = 66
	go.pressed.connect(func(): sortie())
	if development:
		var routes := HBoxContainer.new()
		v.add_child(routes)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		routes.add_child(go)
		var labels := {"front": "PC 개발 · 정면", "flank": "PC 개발 · 우회"}
		for route_id: String in labels:
			var dev := _btn(labels[route_id])
			dev.name = "FirstOperationDev_" + route_id
			dev.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			dev.pressed.connect(func(): sortie(-1, route_id))
			routes.add_child(dev)
		var automatic := HBoxContainer.new()
		v.add_child(automatic)
		var auto_labels := {"front": "자동 해결 · 정면", "flank": "자동 해결 · 우회"}
		for route_id: String in auto_labels:
			var auto := _btn(auto_labels[route_id])
			auto.name = "FirstOperationAuto_" + route_id
			auto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			auto.pressed.connect(_start_operation_auto.bind(route_id))
			automatic.add_child(auto)
	v.add_child(_wrap(UiTheme.label("유비와 손권의 연합 함대가 오림에 머문 조조의 대군을 맞는다. 사기를 꺾어 이기고, 제한은 20분이다.", "Body", 16)))
	v.add_child(HSeparator.new())
	_section(v, "난이도")
	var dr := HBoxContainer.new()
	dr.add_theme_constant_override("separation", 6)
	v.add_child(dr)
	var dg := ButtonGroup.new()
	for d in BattleBrief.difficulties():
		var b := _toggle(d, dg)
		b.pressed.connect(func(): _set_difficulty(d))
		dr.add_child(b)
		_diff_btns[d] = b
	_diff_note = _wrap(UiTheme.label("", "Muted", 14))
	_diff_note.custom_minimum_size.y = 40
	v.add_child(_diff_note)
	_section(v, "지휘")
	var mr := HBoxContainer.new()
	mr.add_theme_constant_override("separation", 6)
	v.add_child(mr)
	var mg := ButtonGroup.new()
	for m in [["direct", "직접 지휘"], ["auto", "자동 해결"]]:
		var b := _toggle(m[1], mg)
		b.pressed.connect(func(): _set_mode(m[0]))
		mr.add_child(b)
		_mode_btns[m[0]] = b
	_mode_note = _wrap(UiTheme.label("", "Muted", 14))
	_mode_note.custom_minimum_size.y = 40
	v.add_child(_mode_note)
	_section(v, "승패")
	for row in [["승리", "조조 기함 격파 · 조조 도주 · 조조군 사기 붕괴"], ["패배", "유비 기함 상실 · 연합 사기 붕괴"], ["20분", "남은 전력 비율이 높은 쪽 (같으면 조조)"]]:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 12)
		var k := UiTheme.label(row[0], "Strong", 15, UiTheme.GOLD)
		k.custom_minimum_size.x = 44
		h.add_child(k)
		var d := _wrap(UiTheme.label(row[1], "Body", 15))
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(d)
		v.add_child(h)
	_section(v, "what-if 카드 · 준비 중")
	var wr := HBoxContainer.new()
	wr.add_theme_constant_override("separation", 6)
	v.add_child(wr)
	for c in BattleBrief.what_if_cards():
		var b := Button.new()
		b.text = str(c.name).split(" 「")[0]
		b.disabled = true
		b.tooltip_text = str(c.effect)
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, BTN_H)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", 15)
		wr.add_child(b)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	if not development:
		var actions := HBoxContainer.new()
		actions.add_theme_constant_override("separation", 10)
		v.add_child(actions)
		go.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(go)
		_product_sortie = _btn("첫 작전 · 정면", true)
		_product_sortie.name = "FirstOperationProduct"
		_product_sortie.custom_minimum_size.y = go.custom_minimum_size.y
		_product_sortie.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_product_sortie.pressed.connect(_sortie_first_operation)
		actions.add_child(_product_sortie)
	_set_difficulty(_difficulty)
	_set_mode(_mode)
	_card.visible = false

func _anchor_right(p: Control) -> void:
	p.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	p.offset_left = -CARD_W - M
	p.offset_right = -M
	p.offset_top = M
	p.offset_bottom = -M

func _build_result() -> void:
	_result = _panel()
	_anchor_right(_result)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	_result.add_child(v)
	_res_labels.eyebrow = UiTheme.label("", "Eyebrow", 13)
	v.add_child(_res_labels.eyebrow)
	_res_labels.title = UiTheme.label("", "Display", 46)
	v.add_child(_res_labels.title)
	_add_restore_actions(v)
	_res_labels.ending = _wrap(UiTheme.label("", "Serif", 19))
	v.add_child(_res_labels.ending)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 4)
	v.add_child(grid)
	_res_labels.legacy_grid = grid
	for k in [["time", "교전 시간"], ["loss_a", "연합 손실"], ["loss_f", "조조군 손실"], ["cao", "조조"]]:
		grid.add_child(UiTheme.label(k[1], "Muted", 15))
		var l := UiTheme.label("", "Strong", 16)
		grid.add_child(l)
		_res_labels[k[0]] = l
	v.add_child(HSeparator.new())
	v.add_child(UiTheme.label("형주의 변화", "Eyebrow", 13))
	_res_labels.regions = _wrap(UiTheme.label("", "Body", 15))
	v.add_child(_res_labels.regions)
	v.add_child(HSeparator.new())
	v.add_child(UiTheme.label("후일담", "Eyebrow", 13))
	_res_labels.line = _wrap(UiTheme.label("", "Serif", 17, UiTheme.INK_2))
	v.add_child(_res_labels.line)
	_res_labels.src = _wrap(UiTheme.label("", "Muted", 13))
	v.add_child(_res_labels.src)
	var sp := Control.new()
	sp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sp)
	_res_labels.seed = UiTheme.label("", "Muted", 13)
	v.add_child(_res_labels.seed)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	v.add_child(row)
	var world_b := _btn("천하 보기")
	world_b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world_b.pressed.connect(_result_to_world)
	row.add_child(world_b)
	var same := _btn("같은 판 다시")
	same.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	same.pressed.connect(func(): sortie(outcome.seed if outcome else -1))
	row.add_child(same)
	_res_labels.same = same
	var again := _btn("새 판", true)
	again.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	again.pressed.connect(func(): sortie())
	row.add_child(again)
	_res_labels.again = again
	_result.visible = false

func _build_cta() -> void:
	_cta = _panel()
	_cta.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_cta.offset_left = -330
	_cta.offset_right = 330
	_cta.offset_top = -M - 108
	_cta.offset_bottom = -M
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	_cta.add_child(h)
	var l := _wrap(UiTheme.label("형주를 얻은 조조가 장강을 따라 내려온다. 손권과 유비는 적벽에서 맞서기로 했다.", "Serif", 17))
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	h.add_child(l)
	var product_replay_available := OS.has_feature("windows") and not OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG)
	if product_replay_available:
		var watch := _watch_replay_action(false)
		watch.custom_minimum_size.x = 140
		h.add_child(watch)
	var b := _btn("적벽으로", true, 168)
	b.name = "OpenRedCliffs"
	if product_replay_available:
		b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(_open_atlas_red_cliffs)
	h.add_child(b)
	_cta.visible = false

func _build_atlas_resume() -> void:
	if not OperationHost.product_save_supported() \
			or OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG):
		return
	var path := OperationHost.PRODUCT_SLOT_PATH
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".previous"):
		return
	_atlas_resume_button = _resume_action(false)
	_atlas_resume_button.focus_mode = Control.FOCUS_ALL
	hud.add_child(_atlas_resume_button)
	_atlas_resume_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_atlas_resume_button.offset_right = _title_button.offset_left - 12.0
	_atlas_resume_button.offset_left = _atlas_resume_button.offset_right - 176.0
	_atlas_resume_button.offset_top = _title_button.offset_top
	_atlas_resume_button.offset_bottom = _title_button.offset_bottom
	_atlas_resume_button.hide()


func _open_atlas_red_cliffs() -> void:
	if state != "browse" or not _sortie_available():
		return
	var link := _link()
	if link == null or link.open_entry_detail() != OK:
		_show_chip("적벽 상세를 열지 못했습니다. 다시 눌러 주세요.")


func _return_to_title() -> void:
	if not _title_button.visible or not _sortie_available():
		return
	if get_tree().change_scene_to_file("res://scenes/entry/EntryBoot.tscn") != OK:
		_show_chip("타이틀로 돌아가지 못했습니다. 다시 눌러 주세요.")

func _build_chip() -> void:
	_chip = _panel(UiTheme.ornate(false))
	_chip.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_chip.offset_left = -240
	_chip.offset_right = 240
	_chip.offset_top = M
	_chip.offset_bottom = M + 64
	_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chip_label = UiTheme.label("", "Strong", 17)
	_chip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_chip.add_child(_chip_label)
	_chip.visible = false

func _build_caption() -> void:
	_caption = _panel(UiTheme.ornate(false))
	_caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_caption.offset_left = -420
	_caption.offset_right = 420
	_caption.offset_top = -M - 96
	_caption.offset_bottom = -M
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption_label = UiTheme.label("", "Serif", 24)
	_caption_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.add_child(_caption_label)
	_caption.visible = false
	_skip = _btn("건너뛰기", false, 150)
	hud.add_child(_skip)
	_skip.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_skip.offset_left = -M - 150
	_skip.offset_right = -M
	_skip.offset_top = -M - BTN_H
	_skip.offset_bottom = -M
	_skip.pressed.connect(_finish_sortie)
	_skip.visible = false

func _build_resolve() -> void:
	var p := _panel()
	p.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	p.offset_left = -340
	p.offset_right = 340
	p.offset_top = -M - 236
	p.offset_bottom = -M
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	p.add_child(v)
	var bars := W.DrawPanel.new(_draw_resolve, null)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.custom_minimum_size = Vector2(0, 120)
	v.add_child(bars)
	_resolve_retry = _btn("결산 저장 다시 시도", true)
	_resolve_retry.name = "RetryAutoSettlement"
	_resolve_retry.pressed.connect(_publish_pending_operation_settlement)
	_resolve_retry.hide()
	v.add_child(_resolve_retry)
	_resolve_cancel = _btn("중단하고 돌아가기", false)
	_resolve_cancel.name = "CancelAutoResolve"
	_resolve_cancel.pressed.connect(_cancel_resolve)
	v.add_child(_resolve_cancel)
	_resolve = p
	_resolve.set_meta("bars", bars)
	_resolve.visible = false

func _draw_resolve(c: Control) -> void:
	if _operation_auto_pending != null:
		UiDraw.text(c, Vector2(0, 32), "작전 완료 · 결산 저장 대기", "serif_bold", 22, UiTheme.INK)
		UiDraw.text(c, Vector2(0, 70), _operation_auto_save_error, "medium", 16, UiTheme.INK_2)
		return
	if _operation_worker != null:
		var progress := _operation_auto_progress
		var route := "정면" if brief.operation_request().route_id == "front" else "우회"
		var title := "중단 중" if _operation_auto_cancelling else "자동 해결 · " + route
		UiDraw.text(c, Vector2(0, 32), title, "serif_bold", 22, UiTheme.INK)
		UiDraw.text(c, Vector2(0, 70), "Tick %d / %d   %.1f s" % [progress.tick, progress.limit_ticks, progress.clock_ms / 1000.0], "medium", 18, UiTheme.INK_2)
		c.draw_rect(Rect2(0, 114, c.size.x, 4), UiTheme.SLOT)
		c.draw_rect(Rect2(0, 114, c.size.x * float(progress.tick) / progress.limit_ticks, 4), UiTheme.GOLD)
		return
	if resolver == null:
		return
	var w := c.size.x
	var cs := resolver.clock_s()
	UiDraw.text(c, Vector2(0, 16), "자동 해결 · %s" % brief.difficulty, "eyebrow", 13, UiTheme.GOLD)
	UiDraw.text(c, Vector2(0, 46), "지휘관들이 싸우고 있다", "serif_bold", 22, UiTheme.INK)
	UiDraw.text(c, Vector2(w, 46), "%02d:%02d / %02d:00" % [int(cs) / 60, int(cs) % 60, int(resolver.limit_s()) / 60], "semibold", 18, UiTheme.INK_2, HORIZONTAL_ALIGNMENT_RIGHT)
	var bp: Array = resolver.army_bp()
	for i in 2:
		var y := 66.0 + i * 22.0
		var key := "wu" if i == 0 else "wei"
		UiDraw.text(c, Vector2(0, y + 13), "연합 사기" if i == 0 else "조조군 사기", "medium", 14, UiTheme.INK_2)
		UiDraw.seg_bar(c, Rect2(104, y + 2, w - 104, 12), clampf(float(bp[i]) / 10000.0, 0.0, 1.0), 20, Factions.of(key).color)
	c.draw_rect(Rect2(0, 114, w, 4), UiTheme.SLOT)
	c.draw_rect(Rect2(0, 114, w * resolver.progress(), 4), UiTheme.GOLD)

# ------------------------------------------------------------ 상태 전환
func _enter_browse() -> void:
	state = "browse"
	canvas.input_lock = false
	canvas.battle_live = false
	_caption.visible = false
	_skip.visible = false
	_resolve.visible = false
	_legend.visible = true
	_update_card()

func _update_card() -> void:
	if canvas.flying():
		return   # 비행이 끝나면 _process가 다시 부른다
	var l := canvas.level()
	var show := state == "browse" and l != "z0" and l != ""
	_card.visible = show and not _result.visible
	_cta.visible = state == "browse" and l == "z0" and not _result.visible
	_update_inset()

func _update_inset() -> void:
	var right := CARD_W + M * 2 if (_card.visible or _result.visible) else 0.0
	var bottom := 280.0 if _resolve.visible else (150.0 if _cta.visible else 50.0)
	canvas.inset = Vector4(120, 150, right, bottom)

func _go_level(l: String) -> void:
	if state == "sortie" or state == "resolve":
		return
	sound.play("tab")
	if state == "result" and l == "z0":
		_result_to_world()
		return
	if state == "browse":
		_card.visible = l != "z0"
		_cta.visible = l == "z0"
		_update_inset()
	canvas.fly_to(l, 1.1)

func open_card() -> void:
	if state != "browse":
		return
	_card.visible = true
	_cta.visible = false
	canvas.arrows = ""
	_update_inset()
	canvas.fly_to("z2", 1.3)

func _on_level(l: String) -> void:
	_title.text = LEVEL_TITLE.get(l, "")
	_sub.text = LEVEL_SUB.get(l, "")
	for k in _crumbs:
		(_crumbs[k] as Button).set_pressed_no_signal(k == l)
	if state == "browse":
		_update_card()

func _on_system(id: String) -> void:
	if state != "browse" and state != "result":
		return
	sound.play("tab")
	if id == world.focus.system and state == "browse":
		open_card()
		return
	var s: Dictionary = canvas.sys_by_id[id]
	var who: String = s.holder if s.holder != "" else OWNER_NAME.get(s.owner, "")
	_show_chip("%s · %s %s · %s" % [s.name, s.display_name, s.grade, who])

func _on_region(id: String) -> void:
	if state != "browse" and state != "result":
		return
	sound.play("tab")
	for r in world.regions:
		if r.id == id:
			_show_chip("%s · %s · %s" % [r.name, r.label, OWNER_NAME.get(canvas.owners_rgn.get(id, ""), "")])

func _on_marker() -> void:
	if state != "browse":
		return
	sound.play("tab")
	if canvas.level() == "z0":
		open_card()
	else:
		canvas.fly_to("z3", 1.2)

func _show_chip(text: String) -> void:
	_chip_label.text = text
	_chip.visible = true
	_chip_t = 2.6

func _set_difficulty(d: String) -> void:
	_difficulty = d
	for k in _diff_btns:
		(_diff_btns[k] as Button).set_pressed_no_signal(k == d)
	_diff_note.text = BattleBrief.difficulty_note(d)
	_update_product_sortie()

func _set_mode(m: String) -> void:
	_mode = m
	for k in _mode_btns:
		(_mode_btns[k] as Button).set_pressed_no_signal(k == m)
	_mode_note.text = "전장에서 직접 지휘한다. 지금 전장은 시연 편성으로 진행된다." if m == "direct" \
		else "지휘관 AI가 적벽 편성으로 끝까지 싸우고 결과만 보여 준다. 수십 초 걸릴 수 있다."
	_update_product_sortie()

func _update_product_sortie() -> void:
	if _product_sortie != null:
		_product_sortie.disabled = not _product_sortie_allowed()

func _product_sortie_allowed() -> bool:
	return _mode == BattleBrief.Product.REQUEST.mode and _difficulty == "표준"

func _sortie_first_operation() -> void:
	if state != "browse" or not _card.visible or not _product_sortie_allowed() or not _sortie_available():
		return
	var candidate := make_brief(BattleBrief.Product.REQUEST.seed)
	candidate.select_first_operation_product()
	_begin_sortie(candidate)

func make_brief(seed := -1) -> BattleBrief:
	var b := BattleBrief.new()
	b.seed = seed if seed >= 0 else randi() % 1000000
	b.difficulty = _difficulty
	b.mode = _mode
	b.edge_labels = (world.get("edge_labels", {}) as Dictionary).duplicate()
	b.anchor = {"system": world.focus.system, "region": world.focus.region, "body": world.focus.body}
	return b

# 출격: 연출(건너뛰기 가능) 뒤 전장 또는 자동 해결
func _add_restore_actions(container: Container) -> void:
	var development := OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG)
	if not development and not OS.has_feature("windows"):
		return
	var row := HBoxContainer.new()
	container.add_child(row)
	if development or OperationHost.product_save_supported():
		row.add_child(_resume_action(development))
	if development:
		var imported := _btn("Import battle\u2026")
		imported.name = "ImportBattle"
		imported.pressed.connect(_select_import_file)
		row.add_child(imported)
	row.add_child(_watch_replay_action(development))
	for button: Button in row.get_children():
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if development:
			button.add_theme_font_size_override("font_size", 14)


func _resume_action(development: bool) -> Button:
	var resume := _btn("Resume saved battle" if development else "첫 작전 이어하기")
	resume.name = "ResumeSavedBattle" if development else "ResumeProductBattle"
	resume.pressed.connect(_resume_saved_battle.bind(not development))
	return resume


func _watch_replay_action(development: bool) -> Button:
	var watch := _btn("Watch replay…" if development else "리플레이 보기…")
	watch.name = "WatchReplay"
	watch.pressed.connect(_select_replay_file)
	watch.focus_mode = Control.FOCUS_ALL
	return watch


func _select_replay_file() -> void:
	if (_replay_dialog != null or _replay_overlay != null or _restore_job != null
			or _import_dialog != null or state not in ["browse", "result"]):
		return
	_replay_focus = get_viewport().gui_get_focus_owner()
	_replay_dialog = FileDialog.new()
	_replay_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_replay_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_replay_dialog.title = "Watch replay"
	_replay_dialog.filters = PackedStringArray(["*" + ReplayCodec.EXTENSION + " ; Space Battle replay"])
	add_child(_replay_dialog)
	_replay_dialog.canceled.connect(_cancel_replay_dialog)
	_replay_dialog.file_selected.connect(_replay_file_selected)
	_replay_dialog.popup_centered_ratio(0.7)
	_replay_dialog.get_line_edit().grab_focus()


func _close_replay_dialog() -> void:
	if _replay_dialog != null:
		_replay_dialog.hide()
		_replay_dialog.queue_free()
		_replay_dialog = null


func _cancel_replay_dialog() -> void:
	_close_replay_dialog()
	_restore_replay_focus()


func _replay_file_selected(path: String) -> void:
	if _replay_dialog == null:
		return
	_close_replay_dialog()
	var viewer := ReplayViewer.instantiate()
	_replay_input_lock = canvas.input_lock
	_replay_hud_visible = hud.visible
	hud.hide()
	canvas.input_lock = true
	_replay_overlay = ColorRect.new()
	_replay_overlay.color = Color("#101925")
	_replay_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_replay_overlay.focus_mode = Control.FOCUS_ALL
	add_child(_replay_overlay)
	_replay_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_replay_overlay.add_child(viewer)
	_replay_overlay.grab_focus()
	viewer.exit_requested.connect(_close_replay_overlay)
	var product_only := not OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG)
	var opened: Dictionary = viewer.open_file(path, product_only)
	if not opened.ok:
		_close_replay_overlay()
		_show_chip(OperationHost.error_text(opened))


func _close_replay_overlay() -> void:
	if _replay_overlay == null:
		return
	remove_child(_replay_overlay)
	_replay_overlay.queue_free()
	_replay_overlay = null
	hud.visible = _replay_hud_visible
	canvas.input_lock = _replay_input_lock
	_restore_replay_focus()


func _restore_replay_focus() -> void:
	if is_instance_valid(_replay_focus) and _replay_focus.is_visible_in_tree():
		_replay_focus.grab_focus()
	_replay_focus = null


func _select_import_file() -> void:
	if _restore_job != null or _import_dialog != null or state not in ["browse", "result"]:
		return
	_import_dialog = OperationHost.external_save_dialog(false)
	add_child(_import_dialog)
	_import_dialog.canceled.connect(_close_import_dialog)
	_import_dialog.file_selected.connect(_import_file_selected)
	_import_dialog.popup_centered_ratio(0.7)
	_import_dialog.get_line_edit().grab_focus()

func _close_import_dialog() -> void:
	if _import_dialog != null:
		_import_dialog.queue_free()
		_import_dialog = null

func _import_file_selected(path: String) -> void:
	if _import_dialog == null:
		return
	_close_import_dialog()
	var imported := OperationHost.read_external_battle(path)
	if imported.ok:
		_restore_saved_packet(imported.payload)
	else:
		_show_chip(OperationHost.error_text(imported))

func _resume_saved_battle(product := false) -> void:
	if _restore_job != null or _import_dialog != null or state not in ["browse", "result"]:
		return
	var saved := OperationHost.read_saved_battle(product)
	if not saved.ok:
		_show_chip(OperationHost.error_text(saved))
		return
	_restore_saved_packet(saved.payload)

func _restore_saved_packet(packet: Dictionary) -> void:
	var link := _link()
	if link == null:
		_show_chip("operation_backend_unavailable / runtime")
		return
	var pending := OperationHost.begin_restore(packet, make_brief())
	if not pending.ok:
		_show_chip(OperationHost.error_text(pending))
		return
	var job: RefCounted = pending.job
	_restore_job = job
	_restore_input_lock = canvas.input_lock
	canvas.input_lock = true
	_show_restore_progress(int(packet.tick))
	while _restore_job == job:
		await get_tree().process_frame
		if _restore_job != job:
			return
		var next: Dictionary = job.step(OperationHost.RESTORE_BUDGET_USEC)
		if not next.ok:
			job.cancel()
			_finish_map_restore()
			_show_chip(OperationHost.error_text(next))
			return
		if next.done:
			_finish_map_restore()
			var checked := OperationHost.validate_restored_owner(next.owner, pending.brief)
			if not checked.ok:
				_show_chip(OperationHost.error_text(checked))
				return
			var error: Error = link.go_battle(pending.brief, _capture_sortie_origin(), next.owner)
			if error != OK:
				next.owner.close()
				_show_chip("world_resume_rejected / %d" % error)
				return
			state = "leaving"
			return
		_restore_label.text = OperationHost.restore_progress(next.tick, next.total)

func _show_restore_progress(total: int) -> void:
	_restore_overlay = CenterContainer.new()
	_restore_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_restore_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	hud.add_child(_restore_overlay)
	var panel := _panel()
	panel.reparent(_restore_overlay, false)
	var box := VBoxContainer.new()
	panel.add_child(box)
	_restore_label = UiTheme.label(OperationHost.restore_progress(0, total), "Body", 18)
	box.add_child(_restore_label)
	var cancel := _btn("Cancel restore")
	cancel.name = "CancelMapRestore"
	cancel.pressed.connect(_cancel_map_restore)
	box.add_child(cancel)

func _finish_map_restore() -> void:
	_restore_job = null
	canvas.input_lock = _restore_input_lock
	_restore_overlay.hide()
	_restore_overlay.queue_free()
	_restore_overlay = null
	_restore_label = null

func _cancel_map_restore() -> void:
	if _restore_job == null:
		return
	_restore_job.cancel()
	_finish_map_restore()
	_show_chip("Restore cancelled")

func _capture_sortie_origin() -> Dictionary:
	return {
		"state": state,
		"brief": brief,
		"outcome": outcome,
		"difficulty": _difficulty,
		"mode": _mode,
		"level": "z2" if _card.visible and canvas.level() == "z0" else canvas.level(),
		"card_visible": _card.visible,
		"result_visible": _result.visible,
		"cta_visible": _cta.visible,
		"legend_visible": _legend.visible,
		"input_lock": canvas.input_lock,
		"arrows": canvas.arrows,
		"owners": canvas.owners_rgn.duplicate(),
	}

func sortie(seed := -1, development_route := "") -> void:
	if not _sortie_available():
		return
	var candidate := make_brief(seed)
	if not development_route.is_empty():
		candidate.select_first_operation_dev(development_route)
	_begin_sortie(candidate)

func _sortie_available() -> bool:
	return _restore_job == null and _import_dialog == null and state != "sortie" and state != "resolve"

func _begin_sortie(candidate: BattleBrief) -> void:
	_sortie_origin = _capture_sortie_origin()
	brief = candidate
	sound.play("confirm_heavy")
	state = "sortie"
	_card.visible = false
	_result.visible = false
	_cta.visible = false
	_chip.visible = false
	_legend.visible = false
	canvas.input_lock = true
	canvas.arrows = "sortie"
	canvas.set_region_owners(_initial_owners(), false)
	_update_inset()
	_sortie_t = 0.0
	_sortie_i = 0
	_caption.visible = true
	_skip.visible = true

func _initial_owners() -> Dictionary:
	var o := {}
	for r in world.regions:
		o[r.id] = r.owner
	return o

func _step_sortie(delta: float) -> void:
	_sortie_t += delta
	while _sortie_i < SORTIE.size() and _sortie_t >= float(SORTIE[_sortie_i][0]):
		var s: Array = SORTIE[_sortie_i]
		_sortie_i += 1
		if s[1] == "end":
			_finish_sortie()
			return
		if s[1] != "":
			canvas.fly_to(s[1], 1.6 if s[1] == "z2" else 2.2)
		_caption_label.text = s[2]

func _finish_sortie() -> void:
	if state != "sortie":
		return
	_caption.visible = false
	_skip.visible = false
	var link := _link()
	var origin := _sortie_origin
	_sortie_origin = {}
	var operation := not brief.operation_request().is_empty()
	if operation or (brief.mode == "direct" and link):
		state = "leaving"
		var error: Error = link.go_battle(brief, origin) if link else ERR_UNAVAILABLE
		if error != OK:
			_restore_sortie_origin(origin)
			if operation and error == ERR_UNAVAILABLE:
				_show_chip("PC 개발 작전을 지금은 시작할 수 없습니다.")
				return
			_show_chip("전장에 들어갈 수 없습니다. 다시 출격해 주세요.")
		return
	_start_resolve()

func _restore_sortie_origin(origin: Dictionary) -> void:
	state = origin.state
	brief = origin.brief
	_card.visible = origin.card_visible
	_result.visible = origin.result_visible
	_cta.visible = origin.cta_visible
	_legend.visible = origin.legend_visible
	canvas.input_lock = origin.input_lock
	canvas.arrows = origin.arrows
	canvas.set_region_owners(origin.owners, false)
	_update_inset()

func _start_operation_auto(route_id: String) -> void:
	if not OS.get_cmdline_user_args().has(BattleBrief.FIRST_OPERATION_DEV_ARG):
		return
	if state not in ["browse", "result"] or _restore_job != null or _import_dialog != null:
		return
	var candidate := make_brief(208)
	candidate.select_first_operation_dev(route_id)
	var worker := FirstOperationAutoWorker.new()
	var started := worker.start(candidate.operation_request())
	if not started.ok:
		_show_chip(OperationHost.error_text(started))
		return
	_operation_worker = worker
	_operation_auto_origin = _capture_sortie_origin()
	_operation_auto_progress = {"tick": 0, "clock_ms": 0, "limit_ticks": FirstOperationAutoWorker.LIMIT_TICKS}
	_operation_auto_cancelling = false
	brief = candidate
	state = "resolve"
	_card.hide()
	_result.hide()
	_cta.hide()
	_chip.hide()
	canvas.input_lock = true
	canvas.arrows = ""
	_resolve.show()
	_update_inset()

func _poll_operation_auto() -> void:
	var result := _operation_worker.poll()
	if result.get("status") in ["running", "cancelling"]:
		_operation_auto_progress = result.progress
		return
	_operation_worker = null
	if result.get("status") == "completed":
		var settled := BattleOutcome.from_operation(result.settlement, brief, result.settlement.clock_ms)
		if settled != null:
			settled.mode = "auto"
			_operation_auto_pending = settled
			_publish_pending_operation_settlement()
			return
		result = {"ok": false, "error": "invalid_worker_settlement", "path": "worker.settlement"}
	_restore_operation_auto_origin()
	if not result.ok:
		_show_chip(OperationHost.error_text(result))


func _publish_pending_operation_settlement() -> void:
	if state != "resolve" or _operation_auto_pending == null:
		return
	var published: Dictionary = _link().publish_operation_settlement(_operation_auto_pending)
	if not published.ok:
		_operation_auto_save_error = OperationHost.error_text(published)
		_resolve.offset_top = -M - 300
		_resolve_retry.show()
		_resolve_cancel.text = "저장하지 않고 돌아가기"
		(_resolve.get_meta("bars") as Control).queue_redraw()
		return
	_clear_pending_operation_settlement()
	_show_result(published.outcome, published.applied)


func _clear_pending_operation_settlement() -> void:
	_operation_auto_pending = null
	_operation_auto_save_error = ""
	_operation_auto_origin = {}
	_resolve_retry.hide()
	_resolve.offset_top = -M - 236
	_resolve_cancel.text = "중단하고 돌아가기"


func _restore_operation_auto_origin() -> void:
	var origin := _operation_auto_origin
	_clear_pending_operation_settlement()
	_resolve.hide()
	_restore_sortie_origin(origin)

func _start_resolve() -> void:
	resolver = AutoResolver.new(brief)
	if not resolver.start():
		_show_chip("자동 해결을 시작하지 못했다: " + resolver.error)
		resolver = null
		_enter_browse()
		return
	state = "resolve"
	canvas.arrows = ""
	canvas.battle_live = true
	_resolve.visible = true
	_update_inset()
	canvas.fly_to("z2", 1.4)

func _cancel_resolve() -> void:
	if state != "resolve":
		return
	if _operation_auto_pending != null:
		_restore_operation_auto_origin()
		return
	if _operation_worker != null:
		_operation_auto_cancelling = true
		_operation_worker.request_cancel()
		return
	_close_legacy_resolver()
	_enter_browse()
	_card.visible = true
	_update_inset()

func _show_result(o: BattleOutcome, animate := true) -> void:
	outcome = o
	_close_legacy_resolver()
	state = "result"
	canvas.input_lock = false
	canvas.battle_live = false
	canvas.arrows = ""
	_resolve.visible = false
	_card.visible = false
	_cta.visible = false
	_legend.visible = true
	_update_inset()
	var operation := not o.settlement_id.is_empty()
	_res_labels.same.visible = not operation
	_res_labels.again.visible = not operation
	_res_labels.legacy_grid.visible = not operation
	if operation:
		var native := o.mode == "o07_native"
		if native:
			_res_labels.eyebrow.text = "O07 operation settlement"
		elif o.is_product_operation:
			_res_labels.eyebrow.text = "PC operation settlement"
		else:
			_res_labels.eyebrow.text = "PC development operation"
		_res_labels.title.text = KIND_TITLE.get(o.kind, "") if native else {"objective_success": "\ubaa9\ud45c \ub2ec\uc131", "withdrawal_success": "\ucca0\uc218 \uc131\uacf5", "failure": "\uc791\uc804 \uc2e4\ud328"}[o.kind]
		_res_labels.title.add_theme_color_override("font_color", Factions.of("wu").rim if o.win else Factions.of("wei").rim)
		_res_labels.ending.text = o.reason
		_res_labels.regions.text = ""
		_res_labels.line.text = ""
		_res_labels.src.text = o.settlement_id
		_res_labels.seed.text = "%d ms / seed %d" % [roundi(o.t_s * 1000), o.seed] if native else "%.1f s / seed %d" % [o.t_s, o.seed]
		_result.visible = true
		_update_inset()
		if animate:
			canvas.jump_to("z2")
		return
	_res_labels.eyebrow.text = "%s · %s · %s" % [o.grade, "직접 지휘" if o.mode == "direct" else "자동 해결", o.difficulty]
	_res_labels.title.text = KIND_TITLE.get(o.kind, "")
	_res_labels.title.add_theme_color_override("font_color", Factions.of("wu").rim if o.win else Factions.of("wei").rim)
	_res_labels.ending.text = o.ending_text()
	_res_labels.time.text = "%d분 %02d초" % [int(o.t_s) / 60, int(o.t_s) % 60]
	var has := o.cao_status != ""
	_res_labels.loss_a.text = "%d%%" % o.loss_pct.alliance if has else "—"
	_res_labels.loss_f.text = "%d%%" % o.loss_pct.foe if has else "—"
	_res_labels.cao.text = EpilogueText.CAO_STATUS.get(o.cao_status, "—") if has else "—"
	var ln := o.line_text()
	_res_labels.line.text = ln[0]
	_res_labels.src.text = ln[1]
	_res_labels.seed.text = "시드 %d" % o.seed
	var after: Dictionary = world.outcome_owners.get(o.kind, {})
	var lines := PackedStringArray()
	for r in world.regions:
		var to: String = after.get(r.id, r.owner)
		if to != r.owner:
			lines.append("%s (%s)  %s → %s" % [r.name, r.label, OWNER_NAME.get(r.owner, ""), OWNER_NAME.get(to, "")])
	_res_labels.regions.text = "\n".join(lines) if not lines.is_empty() else "형주의 주인은 바뀌지 않았다."
	_result.visible = true
	_update_inset()
	if not animate:
		return
	canvas.set_region_owners(_initial_owners(), false)
	canvas.jump_to("z2")
	sound.play("decision")
	get_tree().create_timer(0.6).timeout.connect(func():
		if state == "result":
			canvas.set_region_owners(world.outcome_owners.get(o.kind, _initial_owners()), true))

func _result_to_world() -> void:
	_result.visible = false
	_enter_browse()
	_card.visible = false
	_cta.visible = true
	_update_inset()
	canvas.fly_to("z0", 1.3)

# ------------------------------------------------------------ 진행
func _process(delta: float) -> void:
	var fl := canvas.flying()
	var show_atlas := state == "browse" and canvas.level() == "z0" and not fl and not _card.visible
	_title_button.visible = show_atlas and _sortie_available()
	if _atlas_resume_button != null:
		_atlas_resume_button.visible = show_atlas
		_atlas_resume_button.disabled = not _sortie_available() or _replay_dialog != null or _replay_overlay != null
	if _atlas.visible != show_atlas:
		_atlas.visible = show_atlas
		_atlas_backdrop.visible = show_atlas
		_header.visible = not show_atlas
		canvas.visible = not show_atlas
		_legend.visible = not show_atlas and state != "sortie"
		if show_atlas:
			_atlas.show_overview()
	if _was_flying and not fl and state == "browse":
		_update_card()
	_was_flying = fl
	if _chip.visible:
		_chip_t -= delta
		if _chip_t <= 0.0:
			_chip.visible = false
	if state == "sortie":
		_step_sortie(delta)
	elif state == "resolve" and _operation_worker != null:
		_poll_operation_auto()
		(_resolve.get_meta("bars") as Control).queue_redraw()
	elif state == "resolve" and resolver:
		(_resolve.get_meta("bars") as Control).queue_redraw()
		if resolver.poll():
			_show_result(resolver.outcome)

# 안드로이드 뒤로 가기·Esc: 한 단계 축소
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		back()

func _unhandled_input(ev: InputEvent) -> void:
	if ev.is_action_pressed("ui_cancel"):
		back()
		get_viewport().set_input_as_handled()

func back() -> void:
	if _replay_dialog != null:
		_cancel_replay_dialog()
		return
	if _replay_overlay != null:
		_close_replay_overlay()
		return
	if _restore_job != null:
		_cancel_map_restore()
		return
	if _operation_worker != null or _operation_auto_pending != null:
		_cancel_resolve()
		return
	match state:
		"sortie":
			_finish_sortie()
		"result":
			_result_to_world()
		"browse":
			if _atlas.visible and _atlas.back_to_overview():
				return
			var l := canvas.level()
			if l == "z3":
				_go_level("z2")
			elif l == "z2":
				_go_level("z0")

func _exit_tree() -> void:
	if _operation_worker != null:
		_operation_worker.cancel_and_join()
		_operation_worker = null
	if _restore_job != null:
		_restore_job.cancel()
		_restore_job = null
	_close_legacy_resolver()

func _close_legacy_resolver() -> void:
	if resolver != null:
		resolver.close()
		resolver = null
