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
var chart_ids: Array = []
var chart_points: Array = []
var textures: Array[Texture2D] = []
var back_screen := "title"
var back_state := "brief"
var body: BoxContainer
var key_grid: GridContainer

func _init(d: Control) -> void:
	deck = d
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
	var title := UiTheme.label("함종별 진형 배치도", "", 24)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
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
		var model: int = deck.renderer._model_class("SHP-%02d" % (i + 1))
		var texture: Texture2D = load("res://assets/ships/silhouette/%d.png" % model)
		textures.append(texture)
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(300, 48)
		key_grid.add_child(row)
		var chip := ColorRect.new()
		chip.color = COLORS[i]
		chip.custom_minimum_size.x = 4
		row.add_child(chip)
		var icon := TextureRect.new()
		icon.texture = texture
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(64, 32)
		row.add_child(icon)
		var label := UiTheme.label("", "", 13)
		legends.append(label)
		row.add_child(label)
	var note := UiTheme.label("이미지 위쪽이 전방 ↑ · 점 색상은 오른쪽 함종 범례와 대응 · 열람 중 전투 정지 · 고속정은 요격함 이미지 사용", "Muted", 12)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
	resized.connect(_layout)

func open_guide() -> void:
	back_screen = deck.screen
	back_state = deck.battle.G.state
	deck.battle.G.state = "formation_guide"
	deck.show_screen("formation_guide")

func close_guide() -> void:
	deck.battle.G.state = back_state
	deck.show_screen(back_screen)

func on_show() -> void:
	fleet_picker.clear()
	fleet_picker.add_item("예시 편성 · 56척")
	fleet_picker.set_item_metadata(0, -1)
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
	else:
		counts = deck.src.squadron(id).get("counts", {})
	chart_ids = deck.renderer._real_ship_ids(counts)
	var shape: int = BattleRules.FORM_SHAPE[formation_picker.selected]
	chart_points = deck.renderer._role_points(deck.renderer.formation_points(shape, chart_ids.size()), chart_ids)
	summary.text = "%s · %s · %d척 · %s" % [FORM_NAMES[formation_picker.selected], PURPOSE[formation_picker.selected], chart_ids.size(), fleet_picker.get_item_text(fleet_picker.selected)]
	for i in 8:
		var type_id := "SHP-%02d" % (i + 1)
		legends[i].text = "%s · %d척\n%s" % [ScenarioRoster.SHIP_TYPES[type_id].name, chart_ids.count(type_id), ROLES[i]]
	plot.queue_redraw()

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
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
			draw_set_transform(pos, PI * 0.5)
			draw_texture_rect(guide.textures[type], Rect2(-len_ * 0.5, -len_ * 0.125, len_, len_ * 0.25), false)
			draw_set_transform(Vector2.ZERO)
			draw_circle(pos + Vector2(0, len_ * 0.5 + 4), 2.5, COLORS[type])
