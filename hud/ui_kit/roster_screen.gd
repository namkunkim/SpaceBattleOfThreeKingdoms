extends Control

# 정본 편성 화면(인수 메모 "다음 할 일" 5). 브리핑에서 연다.
# - 연합(유비군·손권군): 세력 → 전단 → 전대(지휘관·참모·기함·함종 카운터)를 전부 보인다. 모든 난이도에서 같다.
# - 조조군(리뷰 W-3): 전투 전에는 기록상 규모, 총사령, 지휘관 명단, 불참 인물만 보인다.
#   전대 수·구성·척 수·투입 시각은 숨긴다(안개와 파도의 긴장). reveal = true(결산·재생)일 때만 고른 난이도의
#   실제 배치(deploy_min_difficulty, count_factor 적용, 리뷰 W-2)를 보인다.
# 지금 POC 전투(적벽 회랑)는 이 편성이 아니다. 코어가 시나리오를 읽게 되면 같은 자료로 전투가 열린다.

const COL_W := 352.0
const CARD_H := 54.0

var deck: Control
var panel: Control
var data := {}
var reveal := false
var difficulty := "표준"
var back_to := "brief"
var _diff_btns: Array = []

func _init(d: Control) -> void:
	deck = d
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	panel = ScreenKit.centered(self, Vector2(1180, 730), UiTheme.ornate())
	panel.painter = _draw_panel
	var back := Button.new()
	back.text = "돌아가기"
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(150, 52)
	back.position = Vector2(1180 - 36 - 150, 32)
	back.pressed.connect(func(): deck.show_screen(back_to))
	panel.add_child(back)
	# 난이도(전부 공개일 때만 보인다)
	var hb := HBoxContainer.new()
	hb.position = Vector2(1180 - 36 - 150 - 16 - 4 * 92, 32)
	hb.add_theme_constant_override("separation", 4)
	panel.add_child(hb)
	for n in ["입문", "표준", "상급", "극한"]:
		var b := Button.new()
		b.text = n
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(88, 52)
		b.pressed.connect(func():
			difficulty = n
			_sync())
		hb.add_child(b)
		_diff_btns.append(b)

# 브리핑: open_roster(false). 결산·재생: open_roster(true, 난이도)
func open_roster(full: bool, diff := "표준", back := "brief") -> void:
	reveal = full
	difficulty = diff
	back_to = back
	deck.show_screen("roster")

func on_show() -> void:
	data = ScenarioRoster.load_scenario()
	_sync()

func _sync() -> void:
	for b in _diff_btns:
		b.visible = reveal
		b.button_pressed = b.text == difficulty
	panel.queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, 0.82))

func _draw_panel(c: Control) -> void:
	UiDraw.text(c, Vector2(36, 48), "정 본 편 성", "eyebrow", 11, UiTheme.GOLD)
	if data.is_empty():
		UiDraw.text(c, Vector2(36, 92), "시나리오 자료를 읽지 못했습니다", "serif_bold", 24, UiTheme.WARN)
		return
	UiDraw.text(c, Vector2(36, 92), str(data.get("title", "")), "serif_bold", 30, UiTheme.INK)
	var note := "시나리오 자료 그대로의 편성입니다. 지금 시험 전투(POC)는 이 편성이 아닙니다."
	if reveal:
		note = "전부 공개 · %s 난이도의 배치입니다(조조군 규모 배율과 투입 난이도 적용)." % difficulty
	UiDraw.text(c, Vector2(36, 118), note, "regular", 12, UiTheme.INK_3)
	c.draw_line(Vector2(36, 132), Vector2(c.size.x - 36, 132), Color(UiTheme.GOLD, 0.22))
	var x := 36.0
	for fac in data.get("factions", []):
		if fac.id == "cao_cao" and not reveal:
			_hidden_enemy(c, Vector2(x, 152), fac)
		else:
			_faction(c, Vector2(x, 152), fac)
		x += COL_W + 18.0

func _head(c: Control, o: Vector2, fac: Dictionary, sub: String) -> void:
	var key: String = ScenarioRoster.FACTION_KEY.get(fac.id, "shu")
	UiDraw.faction_seal(c, Rect2(o, Vector2(32, 32)), key)
	UiDraw.text(c, o + Vector2(42, 15), str(fac.name), "serif_bold", 17, UiTheme.INK)
	UiDraw.text(c, o + Vector2(42, 32), sub, "regular", 11, UiTheme.INK_3)

func _faction(c: Control, o: Vector2, fac: Dictionary) -> void:
	var key: String = ScenarioRoster.FACTION_KEY.get(fac.id, "shu")
	var fi := Factions.of(key)
	var sqs := ScenarioRoster.deployed(data, fac.id, difficulty)
	var ids := {}
	var total := 0
	for s in sqs:
		ids[s.id] = s
		total += ScenarioRoster.ship_count(s)
	_head(c, o, fac, "%s · %d개 전대 · %d척" % [ScenarioRoster.CONTROL_LABEL.get(fac.get("control", ""), ""), sqs.size(), total])
	var y := o.y + 50.0
	for g in ScenarioRoster.groups_of(data, fac.id):
		var shown: Array = g.squadron_ids.filter(func(sid): return ids.has(sid))
		if shown.is_empty():
			continue
		UiDraw.text(c, Vector2(o.x, y + 12), str(g.name), "semibold", 12, fi.color)
		y += 20.0
		for sid in shown:
			_card(c, Rect2(o.x, y, COL_W, CARD_H), ids[sid], key, sid == g.flagship_squadron_id)
			y += CARD_H + 4.0
		y += 4.0
	_not_deployed(c, Vector2(o.x, y), fac)

# 조조군(전투 전): 기록상 규모, 총사령, 기록상 종군 장수, 불참 인물만
# 장수 명단은 지휘관·부지휘관·참모를 합쳐 중복 없이 보인다. 전대 지휘관만 모으면 이름 수가 곧 전대 수가 된다(리뷰 X-1).
func _hidden_enemy(c: Control, o: Vector2, fac: Dictionary) -> void:
	_head(c, o, fac, "적 · 정찰 전에는 전대 수·구성·척 수를 알 수 없음")
	var hs: Dictionary = data.get("historical_scale", {}).get("cao_cao", {})
	var y := o.y + 66.0
	UiDraw.text(c, Vector2(o.x, y), "기 록 상 규 모", "eyebrow", 11, UiTheme.GOLD)
	for line in [str(hs.get("claimed", "")), str(hs.get("estimate", ""))]:
		if line == "":
			continue
		y += 22.0
		for part in _wrap(line, COL_W):
			UiDraw.text(c, Vector2(o.x, y), part, "regular", 12, UiTheme.INK_2)
			y += 18.0
		y -= 18.0
	y += 40.0
	UiDraw.text(c, Vector2(o.x, y), "총 사 령", "eyebrow", 11, UiTheme.GOLD)
	y += 24.0
	UiDraw.text(c, Vector2(o.x, y), str(fac.get("supreme_commander", "")), "serif_bold", 15, UiTheme.INK)
	y += 36.0
	UiDraw.text(c, Vector2(o.x, y), "기 록 상 종 군 장 수", "eyebrow", 11, UiTheme.GOLD)
	var names := ScenarioRoster.officers(data, fac.id)
	y += 24.0
	for part in _wrap(", ".join(names), COL_W):
		UiDraw.text(c, Vector2(o.x, y), part, "regular", 13, UiTheme.INK_2)
		y += 20.0
	y += 16.0
	UiDraw.icon(c, "warn", Rect2(o.x, y - 4, 16, 16), UiTheme.WARN, 1.4)
	UiDraw.text(c, Vector2(o.x + 22, y + 9), "전 병력이 한 번에 오지 않을 수 있습니다", "medium", 12, UiTheme.WARN)
	_not_deployed(c, Vector2(o.x, y + 20), fac)

func _not_deployed(c: Control, o: Vector2, fac: Dictionary) -> void:
	var nd: Array = fac.get("not_deployed", [])
	if nd.is_empty():
		return
	var names := PackedStringArray()
	for p in nd:
		names.append(str(p.name))
	UiDraw.text(c, o + Vector2(0, 14), "불참: " + ", ".join(names), "regular", 11, UiTheme.INK_4)

func _wrap(s: String, width: float) -> PackedStringArray:
	var out := PackedStringArray()
	var line := ""
	for w in s.split(" "):
		var t := (line + " " + w).strip_edges()
		if UiDraw.text_w(t, "regular", 12) > width and line != "":
			out.append(line)
			line = w
		else:
			line = t
	if line != "":
		out.append(line)
	return out

func _card(c: Control, r: Rect2, s: Dictionary, key: String, flag: bool) -> void:
	var fi := Factions.of(key)
	c.draw_rect(r, Color(0.05, 0.08, 0.12, 0.88))
	c.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), fi.color)
	var cmd: Dictionary = s.get("commander", {})
	var portrait: int = Commanders.PORTRAIT.get(str(cmd.get("id", "")), -1)
	var pr := Rect2(r.position + Vector2(8, 6), Vector2(44, 44))
	if portrait >= 0:
		c.draw_texture_rect(deck.battle._portrait_tex(portrait), pr, false)
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
