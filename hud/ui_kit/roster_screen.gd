extends Control

# 정본 편성 화면(인수 메모 "다음 할 일" 5). 브리핑에서 연다.
# 시나리오 JSON의 세력 → 전단 → 전대(지휘관·참모·기함·함종 카운터)를 그대로 보여 준다.
# 지금 POC 전투(적벽 회랑)는 이 편성이 아니다. 코어가 시나리오를 읽게 되면 같은 자료로 전투가 열린다.

const COL_W := 352.0
const CARD_H := 54.0

var deck: Control
var panel: Control
var data := {}

func _init(d: Control) -> void:
	deck = d
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	panel = ScreenKit.centered(self, Vector2(1180, 730), UiTheme.ornate())
	panel.painter = _draw_panel
	var back := Button.new()
	back.text = "브리핑으로"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(150, 52)
	back.position = Vector2(1180 - 36 - 150, 32)
	back.pressed.connect(func(): deck.show_screen("brief"))
	panel.add_child(back)

func on_show() -> void:
	data = ScenarioRoster.load_scenario()
	panel.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, 0.82))

func _draw_panel(c: Control) -> void:
	UiDraw.text(c, Vector2(36, 48), "정 본 편 성", "eyebrow", 11, UiTheme.GOLD)
	if data.is_empty():
		UiDraw.text(c, Vector2(36, 92), "시나리오 자료를 읽지 못했습니다", "serif_bold", 24, UiTheme.WARN)
		return
	UiDraw.text(c, Vector2(36, 92), str(data.get("title", "")), "serif_bold", 30, UiTheme.INK)
	UiDraw.text(c, Vector2(36, 118), "시나리오 자료 그대로의 편성입니다. 지금 시험 전투(적벽 회랑)는 이 편성이 아닙니다.", "regular", 12, UiTheme.INK_3)
	c.draw_line(Vector2(36, 132), Vector2(c.size.x - 36, 132), Color(UiTheme.GOLD, 0.22))
	var x := 36.0
	for fac in data.get("factions", []):
		_faction(c, Vector2(x, 152), fac)
		x += COL_W + 18.0

func _faction(c: Control, o: Vector2, fac: Dictionary) -> void:
	var key: String = ScenarioRoster.FACTION_KEY.get(fac.id, "shu")
	var fi := Factions.of(key)
	UiDraw.faction_seal(c, Rect2(o, Vector2(32, 32)), key)
	UiDraw.text(c, o + Vector2(42, 15), str(fac.name), "serif_bold", 17, UiTheme.INK)
	var sqs := ScenarioRoster.squadrons_of(data, fac.id)
	var total := 0
	for s in sqs:
		total += ScenarioRoster.ship_count(s)
	UiDraw.text(c, o + Vector2(42, 32), "%s · %d개 전대 · %d척" % [ScenarioRoster.CONTROL_LABEL.get(fac.get("control", ""), ""), sqs.size(), total], "regular", 11, UiTheme.INK_3)
	var y := o.y + 50.0
	for g in ScenarioRoster.groups_of(data, fac.id):
		UiDraw.text(c, Vector2(o.x, y + 12), str(g.name), "semibold", 12, fi.color)
		y += 20.0
		for sid in g.squadron_ids:
			var s := ScenarioRoster.squadron(data, sid)
			if not s.is_empty():
				_card(c, Rect2(o.x, y, COL_W, CARD_H), s, key, sid == g.flagship_squadron_id)
				y += CARD_H + 4.0
		y += 4.0
	# 출전하지 않은 인물
	var nd: Array = fac.get("not_deployed", [])
	if not nd.is_empty():
		var names := PackedStringArray()
		for p in nd:
			names.append(str(p.name))
		UiDraw.text(c, Vector2(o.x, y + 14), "불참: " + ", ".join(names), "regular", 11, UiTheme.INK_4)

func _card(c: Control, r: Rect2, s: Dictionary, key: String, flag: bool) -> void:
	var fi := Factions.of(key)
	c.draw_rect(r, Color(0.05, 0.08, 0.12, 0.88))
	c.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), fi.color)
	var cmd: Dictionary = s.get("commander", {})
	var who := _person_by_name(str(cmd.get("name", "")))
	var pr := Rect2(r.position + Vector2(8, 6), Vector2(44, 44))
	if int(who.get("portrait", -1)) >= 0:
		c.draw_texture_rect(deck.battle._portrait_tex(int(who.portrait)), pr, false)
	else:
		UiDraw.faction_seal(c, pr, key, str(cmd.get("name", "?")).left(1))
	UiDraw.text(c, r.position + Vector2(60, 20), str(s.name), "serif_bold", 14, UiTheme.INK)
	if flag:
		UiDraw.text(c, r.position + Vector2(66 + UiDraw.text_w(str(s.name), "serif_bold", 14), 19), "旗艦", "serif_bold", 11, UiTheme.GOLD_HI)
	UiDraw.text(c, Vector2(r.end.x - 10, r.position.y + 20), "%d척" % ScenarioRoster.ship_count(s), "semibold", 13, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	var staff := PackedStringArray()
	for p in s.get("staff", []):
		staff.append(str(p.name))
	var line := "지휘 %s" % cmd.get("name", "")
	if not staff.is_empty():
		line += " · 참모 " + ", ".join(staff)
	UiDraw.text(c, r.position + Vector2(60, 36), line, "regular", 11, UiTheme.INK_2)
	UiDraw.text(c, r.position + Vector2(60, 50), ScenarioRoster.composition_text(s), "regular", 11, UiTheme.INK_3)

static func _person_by_name(n: String) -> Dictionary:
	for k in Commanders.PEOPLE:
		if Commanders.PEOPLE[k].name == n:
			return Commanders.PEOPLE[k]
	return {}
