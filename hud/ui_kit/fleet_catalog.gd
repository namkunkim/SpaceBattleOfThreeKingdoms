extends Control

# 통합 함대 보고서 v2.5의 함종 순서와 원본 도판.
const FACTIONS := {"wei": "조위", "shu": "촉한", "wu": "동오"}
const HULL_ORDER := [
	FleetRenderer.CARRIER, FleetRenderer.SIEGE, FleetRenderer.FIRE, FleetRenderer.LINE,
	FleetRenderer.SUPPLY, FleetRenderer.EW, FleetRenderer.ESCORT, FleetRenderer.FAST_HULL,
]
const ENTRIES := {
	"wei": [
		["강습모함", "1,300 m · 모함", "함재기와 강습정을 운용하는 이동 기지.", "res://assets/concepts/fleet-reports/report-images/wei/01-2569342c42c0.jpg"],
		["공성함", "1,050 m · 공성함", "궤도 요새와 방어망을 상대하는 중장갑 함선.", "res://assets/concepts/fleet-reports/report-images/wei/03-698002a1e3a0.jpg"],
		["포격함", "900 m · 주력함", "장거리 화력 지원을 담당한다.", "res://assets/concepts/fleet-reports/report-images/wei/05-85b0807ef8b4.jpg"],
		["전열함", "750 m · 주력함", "정면 교전에서 전열을 유지하는 중장갑 주력함.", "res://assets/concepts/fleet-reports/report-images/wei/07-941f5c283a82.jpg"],
		["보급함", "800 m · 지원함", "함대에 물자를 공급하고 손상된 함선을 현장에서 수리한다.", "res://assets/concepts/fleet-reports/report-images/wei/09-862703a4170a.jpg"],
		["전자전함", "400 m · 초계함", "탐지와 통신 교란을 맡는다.", "res://assets/concepts/fleet-reports/report-images/wei/11-84d1f4645f8d.jpg"],
		["요격함", "480 m · 초계함", "고속 요격과 주력함 호위를 담당한다.", "res://assets/concepts/fleet-reports/report-images/wei/13-ee6053d11eba.jpg"],
		["고속정", "180 m · 소형정", "단거리 정찰·연락과 기습에 쓰이는 경량 기동정.", "res://assets/concepts/fleet-reports/report-images/wei/15-109d7fd98e0b.jpg"],
	],
	"shu": [
		["강습모함", "1,300 m", "박막형 비대칭 프레임, 노출된 주황색 냉각 그리드와 비취색 장갑.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/assault-carrier.jpg"],
		["공성함", "1,050 m", "노출된 외골격과 축전부, 선수로 모이는 프레임.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/siege-ship.jpg"],
		["익주 프로토타입 포격함", "900 m", "선체를 따라 이어지는 가속 레일, 우현 주황색 방열판과 좌측 함교 모듈.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/yizhou-artillery.jpg"],
		["전열함", "750 m", "양쪽 가변 날개, 비취색 적층 장갑과 후방 추진기.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/line-of-battle.jpg"],
		["보급함", "800 m", "개방형 정비 크래들, 전방 인양 장치와 적재 램프.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/supply-repair.jpg"],
		["전자전함", "400 m", "가오리형 곡면 외피, 팔진도 안테나 마스트와 정면 교란 디스크.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/electronic-warfare.jpg"],
		["요격함", "480 m", "단검형 선수, 중앙 중공 트러스와 청록색 후방 추진기.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/interceptor.jpg"],
		["고속정", "180 m", "납작한 화살촉형 선체, 매립형 선수 포트와 소형 후방 추진기.", "res://assets/concepts/fleet-reports/shu-han-six-view-v2/fast-attack.jpg"],
	],
	"wu": [
		["강습모함", "1,300 m", "쌍동체와 자기장 돛, 후방 고층 함교", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/assault-carrier.jpg"],
		["공성함", "1,050 m", "삼각형 선수와 바둑판형 매립 발사구", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/siege-ship.jpg"],
		["포격함", "900 m", "직선형 장거리 플랫폼과 중앙 해치 뱅크", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/artillery-dreadnought.jpg"],
		["전열함 · 장강 하이드로", "750 m", "매끈한 티타늄·청동 장갑과 후방 집중 추진", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/changjiang-hydro.jpg"],
		["보급함", "800 m", "밀폐형 청동 사일로와 전면 도킹 나셀", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/supply-repair.jpg"],
		["전자전함", "400 m", "물방울형 외피와 매립 레이돔", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/electronic-warfare.jpg"],
		["요격함", "480 m", "제비형 실루엣과 후방 4연장 추진기", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/interceptor.jpg"],
		["고속정", "180 m", "소형 곡면 캡슐과 후방 추진기 두 기", "res://assets/concepts/fleet-reports/eastern-wu-six-view-v2/fast-attack.jpg"],
	],
}

var _deck: Control
var _back_screen := "title"
var _faction := "wei"
var _ship := 0
var _battle_view := false
var _ship_buttons: Array[Button] = []
var _name: Label
var _meta: Label
var _description: Label
var _stats: Label
var _armament: Label
var _phases: Label
var _art: TextureRect
var _plate_button: Button
var _hull_button: Button

func _init(deck: Control) -> void:
	_deck = deck
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var margin := MarginContainer.new()
	add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 14)
	margin.add_child(layout)

	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := UiTheme.label("함대 도감", "", 30, UiTheme.GOLD_HI)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.name = "CloseFleetCatalog"
	close.text = "돌아가기 · Esc"
	close.custom_minimum_size = Vector2(168, 48)
	close.pressed.connect(_close)
	header.add_child(close)

	var factions := HBoxContainer.new()
	factions.add_theme_constant_override("separation", 8)
	layout.add_child(factions)
	var faction_group := ButtonGroup.new()
	for faction: String in FACTIONS:
		var tab := _tab(FACTIONS[faction], faction_group)
		tab.name = "Faction_" + faction
		tab.custom_minimum_size.x = 112
		tab.button_pressed = faction == _faction
		tab.pressed.connect(_select_faction.bind(faction))
		factions.add_child(tab)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(body)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.x = 226
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var ship_group := ButtonGroup.new()
	for i in HULL_ORDER.size():
		var id := "SHP-%02d" % (i + 1)
		var button := _tab(ScenarioRoster.SHIP_TYPES[id].name, ship_group)
		button.name = id
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 52
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 76)
		button.pressed.connect(_select_ship.bind(i))
		_ship_buttons.append(button)
		list.add_child(button)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiTheme.ornate())
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(panel)
	var detail := VBoxContainer.new()
	detail.add_theme_constant_override("separation", 8)
	panel.add_child(detail)

	var heading := HBoxContainer.new()
	detail.add_child(heading)
	_name = UiTheme.label("", "", 24)
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(_name)
	var view_group := ButtonGroup.new()
	_plate_button = _tab("원본 도판", view_group)
	_plate_button.pressed.connect(_select_view.bind(false))
	heading.add_child(_plate_button)
	_hull_button = _tab("전투 외형", view_group)
	_hull_button.pressed.connect(_select_view.bind(true))
	heading.add_child(_hull_button)

	_meta = UiTheme.label("", "Muted", 14)
	detail.add_child(_meta)
	_art = TextureRect.new()
	_art.name = "ShipArtwork"
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(_art)
	_description = UiTheme.label("", "", 16)
	_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_description)
	_stats = UiTheme.label("", "", 16, UiTheme.GOLD_HI)
	_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_stats)
	_armament = UiTheme.label("", "", 14)
	_armament.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_armament)
	_phases = UiTheme.label("", "Muted", 13)
	_phases.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_phases)
	layout.add_child(UiTheme.label("외형·설명은 통합 함대 보고서 v2.5 기준 · 전투 기본 능력치는 같은 함종이면 진영 공통", "Muted", 13))

func _tab(text: String, group: ButtonGroup) -> Button:
	var button := Button.new()
	button.text = text
	button.toggle_mode = true
	button.button_group = group
	button.custom_minimum_size = Vector2(92, 42)
	return button

func open_catalog() -> void:
	_back_screen = _deck.screen
	_deck.show_screen("fleet_catalog")

func on_show() -> void:
	_select_faction(_faction)

func _select_faction(faction: String) -> void:
	_faction = faction
	for i in _ship_buttons.size():
		_ship_buttons[i].icon = load(_hull_path(i)) as Texture2D
	_select_ship(_ship)

func _select_ship(index: int) -> void:
	_ship = index
	_ship_buttons[index].button_pressed = true
	var entry: Array = ENTRIES[_faction][_ship]
	_name.text = entry[0]
	_meta.text = "%s  /  %s" % [FACTIONS[_faction], entry[1]]
	_description.text = entry[2]
	_update_stats("SHP-%02d" % (index + 1))
	_select_view(_battle_view)

func _update_stats(id: String) -> void:
	var combat: Dictionary = _deck.src.combat
	var stats: Dictionary = combat.get("ship_types", {}).get(id, {})
	if stats.is_empty():
		_stats.text = "이 전투 규칙에는 함종 능력치가 없습니다."
		_armament.text = ""
		_phases.text = ""
		return

	var detection: Dictionary = combat.get("detection", {})
	var hull := int(stats.cost) * int(combat.hull.points_per_cost)
	var speed := float(stats.speed_per_turn) / float(combat.movement.turn_div)
	_stats.text = "척당 편성 비용 %d  ·  선체 %d  ·  기본 기동 %.1f/초  ·  탐지 %d  ·  전자전 %d" % [
		stats.cost, hull, speed, detection.get("ship_sensor", {}).get(id, 0), detection.get("ship_ew", {}).get(id, 0),
	]
	var names := {"artillery": "포격", "line_fire": "전열 사격", "intercept": "요격", "torpedo": "어뢰", "fighter": "함재기"}
	var weapons: Array[String] = []
	for category: String in combat.weapons:
		var weapon: Dictionary = combat.weapons[category]
		if weapon.platforms.has(id):
			weapons.append(_weapon_text(names.get(category, category), weapon, weapon.platforms[id]))
		if id == combat.get("fast_craft", {}).get("ship_type_id", ""):
			for equipment: String in weapon.equipment:
				weapons.append(_weapon_text(names.get(category, category) + " 장비", weapon, weapon.equipment[equipment]))
	var supply: Dictionary = combat.get("supply", {})
	if id == supply.get("ship_type_id", ""):
		weapons.append("보급 반경 %d · 척당 처리량 %d" % [supply.ship_radius, supply.capacity_per_ship])
	_armament.text = "기본 탑재 무장 없음" if weapons.is_empty() else "  /  ".join(weapons)
	var phase: Dictionary = stats.phase
	_phases.text = "교전 단계 배율   접촉 ×%.1f · 포격 ×%.1f · 교전 ×%.1f · 강습 ×%.1f · 결착 ×%.1f" % [
		phase.contact, phase.barrage, phase.engagement, phase.assault, phase.resolution,
	]

func _weapon_text(label: String, weapon: Dictionary, platform: Dictionary) -> String:
	return "%s · 사거리 %d · 기본 피해 %d · 명중 %.0f%%" % [
		label, platform.range, weapon.base_damage, float(weapon.base_accuracy_bp) / 100.0,
	]

func _select_view(battle_view: bool) -> void:
	_battle_view = battle_view
	_plate_button.button_pressed = not battle_view
	_hull_button.button_pressed = battle_view
	var path: String = _hull_path(_ship) if battle_view else ENTRIES[_faction][_ship][3]
	_art.texture = load(path) as Texture2D

func _hull_path(index: int) -> String:
	return "%s%s/%s.png" % [FleetRenderer.HULL_ROOT, _faction, FleetRenderer.HULL_ROLES[HULL_ORDER[index]]]

func _close() -> void:
	_deck.show_screen(_back_screen)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.BG_DEEP)
