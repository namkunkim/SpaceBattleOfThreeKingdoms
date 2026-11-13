extends Control

# 문서 기준과 실제 렌더러의 좌표를 쓰는 게임 내 배치도. 진형 명령은 보내지 않는다.
const FORM_NAMES := ["어린진", "학익진", "방원진", "안행진", "봉시진", "장사진", "팔진"]
const PURPOSE := ["중앙 돌파", "양익 포위", "종심 방어", "사격 전개", "축차 투입", "종렬 항진", "가변 대응"]
const ROLES := ["중앙 후방 · 함재기·강습정", "후방 화력선 · 관통 사격", "중후방 양측 · 장거리 포화", "전방 중앙 · 정면 교전",
	"후방 안쪽 · 수리·보급", "전열 뒤 양측 · 탐지·교란", "양익 외곽 · 요격·호위", "전방 양익 · 정찰·기습"]
const COLORS := [UiTheme.GOLD_HI, UiTheme.WARN, UiTheme.GOLD, UiTheme.ALLY, UiTheme.LIFE, UiTheme.CP, UiTheme.ALLY_HI, UiTheme.FOE_HI]
const EXAMPLE := [6, 4, 8, 14, 4, 4, 10, 6]

var deck: Control
var formation_picker: OptionButton
var fleet_picker: OptionButton
var plot: Control
var summary: Label
var legends: Array[Label] = []
var legend_buttons: Array[Button] = []
var selected_type := -1
var clear_button: Button
var chart_ids: Array = []
var chart_points: Array = []
var textures: Array[Texture2D] = []
var ship_icons: Array[TextureRect] = []
var back_screen := "title"
var back_state := "brief"
var body: BoxContainer
var key_grid: GridContainer
var _reference_mode := false
var _reference_squadrons: Array = []

func _init(d: Control, shu_squadrons: Variant = null) -> void:
	deck = d
	_reference_mode = shu_squadrons is Array
	if _reference_mode:
		_reference_squadrons = shu_squadrons
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := UiTheme.label("촉 함선으로 보는 진형" if _reference_mode else "함종별 진형 배치도", "", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	clear_button = Button.new()
	clear_button.text = "전체 표시"
	clear_button.custom_minimum_size = Vector2(112, 48)
	clear_button.pressed.connect(func():
		selected_type = -1
		_refresh_selection())
	header.add_child(clear_button)
	var close := Button.new()
	close.name = "CloseGuide"
	close.text = "돌아가기 · Esc"
	close.custom_minimum_size = Vector2(168, 48)
	close.pressed.connect(close_guide)
	header.add_child(close)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	column.add_child(choices)
	formation_picker = OptionButton.new()
	formation_picker.name = "FormationChoice"
	formation_picker.custom_minimum_size = Vector2(210, 48)
	for i in FORM_NAMES.size():
		formation_picker.add_item(FORM_NAMES[i] + " · " + PURPOSE[i])
	formation_picker.item_selected.connect(func(_i): _sync())
	choices.add_child(formation_picker)
	fleet_picker = OptionButton.new()
	fleet_picker.name = "FleetChoice"
	fleet_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fleet_picker.custom_minimum_size.y = 48
	fleet_picker.item_selected.connect(func(_i): _sync())
	choices.add_child(fleet_picker)
	summary = UiTheme.label("", "Muted", 14)
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	body = BoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 24)
	scroll.add_child(body)
	plot = Diagram.new(self)
	plot.name = "ShipDiagram"
	plot.custom_minimum_size = Vector2(0, 420)
	plot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plot.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(plot)
	key_grid = GridContainer.new()
	key_grid.add_theme_constant_override("h_separation", 16)
	key_grid.add_theme_constant_override("v_separation", 10)
	body.add_child(key_grid)
	for i in 8:
		var ship_type := "SHP-%02d" % (i + 1)
		var path := ScenarioRoster.report_hull_path("shu", ship_type)
		var texture: Texture2D = load(path)
		textures.append(texture)
		var button := Button.new()
		button.name = "ShipType%02d" % (i + 1)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(312, 56)
		button.tooltip_text = "클릭하여 해당 함종 위치 강조 · 다시 클릭하면 전체 표시"
		button.pressed.connect(_select_type.bind(i))
		legend_buttons.append(button)
		key_grid.add_child(button)
		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(row)
		row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		row.offset_left = 6
		row.offset_right = -6
		row.offset_top = 4
		row.offset_bottom = -4
		var chip := ColorRect.new()
		chip.color = COLORS[i]
		chip.custom_minimum_size.x = 4
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(chip)
		var icon := TextureRect.new()
		icon.texture = texture
		ship_icons.append(icon)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 32)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var label := UiTheme.label("", "", 13)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		legends.append(label)
		row.add_child(label)
	var help := "함종을 클릭하면 위치 강조 · 다시 클릭하거나 전체 표시로 해제 · 위쪽이 전방 ↑"
	if not _reference_mode:
		help += " · 열람 중 전투 정지"
	var note := UiTheme.label(help, "Muted", 12)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	resized.connect(_layout)

func open_guide() -> void:
	back_screen = deck.screen
	back_state = deck.battle.G.state
	deck.battle.G.state = "formation_guide"
	deck.show_screen("formation_guide")

func close_guide() -> void:
	if _reference_mode:
		deck.show_screen("menu")
		return
	deck.battle.G.state = back_state
	deck.show_screen(back_screen)

func on_show() -> void:
	selected_type = -1
	fleet_picker.clear()
	fleet_picker.add_item("예시 편성 · 56척")
	fleet_picker.set_item_metadata(0, -1)
	if _reference_mode:
		for index in _reference_squadrons.size():
			var squadron: Dictionary = _reference_squadrons[index]
			fleet_picker.add_item("%s · %d척" % [squadron.name, ScenarioRoster.ship_count(squadron)])
			fleet_picker.set_item_metadata(index + 1, index)
		fleet_picker.select(0)
		_layout()
		_sync()
		return
	var chosen := 0
	for sq in deck.src.squadrons():
		if sq.side != 0 or sq.dead or sq.counts.is_empty():
			continue
		fleet_picker.add_item(sq.name)
		var index := fleet_picker.item_count - 1
		fleet_picker.set_item_metadata(index, sq.id)
		if chosen == 0 and deck.battle.selected.any(func(f): return f.id == sq.id):
			chosen = index
			formation_picker.select(maxi(0, BattleRules.FORM_SHAPE.find(int(sq.formation))))
	fleet_picker.select(chosen)
	_layout()
	_sync()

func _layout() -> void:
	if body == null:
		return
	body.vertical = size.x < 980
	key_grid.columns = 2 if body.vertical and size.x >= 700 else 1

func _sync() -> void:
	var counts := {}
	var id: int = fleet_picker.get_selected_metadata()
	if id < 0:
		for i in 8:
			counts["SHP-%02d" % (i + 1)] = [EXAMPLE[i], 0, 0, 0]
	elif _reference_mode:
		for entry: Dictionary in _reference_squadrons[id].get("composition", []):
			var ship_type: String = entry.ship_type_id
			if not counts.has(ship_type):
				counts[ship_type] = [0, 0, 0, 0]
			counts[ship_type][0] += int(entry.count)
	else:
		counts = deck.src.squadron(id).get("counts", {})
	var faction: String = "shu" if _reference_mode else ("han" if id < 0 else deck.src.squadron(id).get("faction", "han"))
	faction = ScenarioRoster.FACTION_KEY.get(faction, faction)
	if faction not in ["wei", "shu", "wu"]:
		faction = "han"
	for i in 8:
		var ship_type := "SHP-%02d" % (i + 1)
		var path := "res://assets/ships/fleet-report-v25/han/imperial-falcon.png" if faction == "han" else ScenarioRoster.report_hull_path(faction, ship_type)
		textures[i] = load(path)
		ship_icons[i].texture = textures[i]
	chart_ids = deck.renderer._real_ship_ids(counts)
	var shape: int = BattleRules.FORM_SHAPE[formation_picker.selected]
	chart_points = deck.renderer._role_points(deck.renderer.formation_points(shape, chart_ids.size()), chart_ids)
	_refresh_selection()

func _select_type(index: int) -> void:
	selected_type = -1 if selected_type == index else index
	_refresh_selection()

func _refresh_selection() -> void:
	summary.text = "%s · %s · %d척 · %s" % [FORM_NAMES[formation_picker.selected], PURPOSE[formation_picker.selected], chart_ids.size(), fleet_picker.get_item_text(fleet_picker.selected)]
	if selected_type >= 0:
		var selected_id := "SHP-%02d" % (selected_type + 1)
		var count := chart_ids.count(selected_id)
		summary.text += " · %s %d척 %s" % [ScenarioRoster.SHIP_TYPES[selected_id].name, count, "강조" if count > 0 else "(편성에 없음)"]
	clear_button.disabled = selected_type < 0
	for i in 8:
		var type_id := "SHP-%02d" % (i + 1)
		legend_buttons[i].set_pressed_no_signal(selected_type == i)
		legends[i].text = "%s%s · %d척\n%s" % ["선택 · " if selected_type == i else "", ScenarioRoster.SHIP_TYPES[type_id].name, chart_ids.count(type_id), ROLES[i]]
	plot.queue_redraw()

func ship_alpha(index: int) -> float:
	return 1.0 if selected_type < 0 or selected_type == index else 0.18

func _input(event: InputEvent) -> void:
	if not _reference_mode and is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close_guide()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.BG_DEEP)

class Diagram extends Control:
	var guide: Control
	func _init(g: Control) -> void:
		guide = g
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)
	func _draw() -> void:
		UiDraw.text(self, Vector2(0, 24), "↑ 적 방향", "medium", 14, UiTheme.INK_2, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		if guide.chart_points.is_empty():
			return
		var bounds := Rect2(Vector2(guide.chart_points[0].z, guide.chart_points[0].x), Vector2.ZERO)
		for p: Vector3 in guide.chart_points:
			bounds = bounds.expand(Vector2(p.z, p.x))
		var scale_ := minf((size.x - 60) / (bounds.size.x + 35), (size.y - 76) / (bounds.size.y + 35))
		var center := bounds.get_center()
		var length := minf(48.0, FleetRenderer.GAP_FWD * scale_ * 0.88)
		for i in guide.chart_points.size():
			var p: Vector3 = guide.chart_points[i]
			var type: int = int(str(guide.chart_ids[i]).right(2)) - 1
			var factor: float = [1.12, 1.04, 0.98, 1.0, 0.92, 0.82, 0.72, 0.48][type]
			var len_ := length * factor
			var pos := Vector2(size.x * 0.5 + (p.z - center.x) * scale_, (size.y + 24) * 0.5 - (p.x - center.y) * scale_)
			var alpha: float = guide.ship_alpha(type)
			if guide.selected_type == type:
				draw_rect(Rect2(pos - Vector2(len_ * 0.125 + 5, len_ * 0.5 + 5), Vector2(len_ * 0.25 + 10, len_ + 10)), COLORS[type], false, 2.0)
			draw_set_transform(pos, PI * 0.5)
			var texture: Texture2D = guide.textures[type]
			if texture:
				var half_width := len_ * 0.125
				if guide._reference_mode:
					half_width = len_ * 0.5 * float(texture.get_height()) / float(texture.get_width())
				draw_texture_rect(texture, Rect2(-len_ * 0.5, -half_width, len_, half_width * 2), false, Color(1, 1, 1, alpha))
			draw_set_transform(Vector2.ZERO)
			draw_circle(pos + Vector2(0, len_ * 0.5 + 4), 2.5, Color(COLORS[type], alpha))
