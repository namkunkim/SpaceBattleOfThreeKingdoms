extends Control

# 전투 전 편성 화면(O4, BATTLE_DECISIONS §T Q73~Q82, docs/ui/FLEET-ORGANIZATION-SCREEN.md, 목업 v1 3열).
# 브리핑 → 편성 → 전투. 편집은 유비군만(Q76). 검증·자동 편성·한도·초과 단계는 Organization만 쓴다(규칙을 다시 짜지 않는다).
# 장수 배정: 칸이나 풀 장수를 하나 누르고 다른 칸이나 풀 장수를 누르면 맞바꾼다(터치·마우스 공통).
# 화면은 함대 목록을 편성(org)에서 읽는다. 함대 수가 늘어도(조조 추가 함대, O2) 유비군 함대만 보인다.

const PLAYER := "liu_bei"
const ROLES := [["admiral", "제독"], ["vice", "부제독"], ["assault", "참모 · 강습"], ["siege", "참모 · 공성"], ["supply", "참모 · 보급"]]
const REASON := {
	Organization.DUP_OFFICER: "같은 장수가 두 칸에 있습니다",
	Organization.FOREIGN_OFFICER: "유비군 장수가 아닙니다",
	Organization.FLAG_ADMIRAL: "기함 제독은 바꿀 수 없습니다",
	Organization.FLAG_OFF: "기함 함대는 출전해야 합니다",
	Organization.NO_FLEET: "출전 함대가 없습니다",
	Organization.NO_ADMIRAL: "제독이 없습니다",
	Organization.NO_SHIPS: "함선이 0척입니다",
	Organization.BAD_STAFF: "참모 보직이 잘못됐습니다",
	Organization.BAD_SHIP: "함종이 잘못됐습니다",
	Organization.UNKNOWN_FLEET: "알 수 없는 함대입니다",
	Organization.MISSING_FLEET: "함대가 빠졌습니다",
	Organization.BAD_FLEET: "편성 형식이 잘못됐습니다",
}
const BTN_H := 56.0   # 태블릿 48dp(touch_targets: 2560×1600 274dpi에서 52단위 이상)

var deck: Control
var scn := {}
var prof := {}
var org := {}
var officers := {}   # 유비군 가용 장수 ID → 능력치
var names := {}      # 함대 ID → 시나리오 함대 이름
var sel := -1        # org.fleets 인덱스(유비군 함대)
var picked := {}     # {fleet: 인덱스 | -1(풀), role, id}
var errors := []

var fleets_box: VBoxContainer
var detail: VBoxContainer
var pool_box: VBoxContainer
var search: LineEdit
var sum_label: Label
var msg: Label
var confirm: Button

func _init(d: Control) -> void:
	deck = d
	ScreenKit.full(self)
	var content := Control.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(content)
	var safe := SafeArea.new()
	safe.name = "SafeArea"
	add_child(safe)
	safe.ready.connect(func(): safe.setup(content))
	var mc := MarginContainer.new()
	mc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for k in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + k, 20)
	content.add_child(mc)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 12)
	mc.add_child(col)
	# 머리
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 16)
	col.add_child(head)
	head.add_child(_label("함대 편성", "Title"))
	var sub := _label("적벽 208 · 유비군 · 손권군·조조군은 자동 편성", "Muted")
	sub.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sub)
	head.add_child(_label("브리핑  ›  편성  ›  전투", "Muted"))
	head.add_child(_button("뒤로", 120, func(): deck.show_screen("brief")))
	# 3열
	var cols := HBoxContainer.new()
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 14)
	col.add_child(cols)
	fleets_box = _column(cols, "함 대  ·  출 전", 330)
	detail = _column(cols, "", 0)
	var right := _column(cols, "대 기 풀", 340)
	search = LineEdit.new()
	search.placeholder_text = "이름·특성 검색"
	search.custom_minimum_size.y = BTN_H
	search.text_changed.connect(func(_t): _refresh())
	right.get_parent().get_parent().get_child(0).add_sibling(search)
	pool_box = right
	sum_label = _label("", "Body")
	sum_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.get_parent().get_parent().add_child(sum_label)
	# 아래
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 12)
	col.add_child(foot)
	msg = _label("", "Body")
	msg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_child(msg)
	foot.add_child(_button("정사 편성으로 초기화", 220, func():
		org = start_org(prof, scn, false)
		picked = {}
		_refresh()))
	foot.add_child(_button("자동 편성", 160, func():
		org = Organization.auto_fill(org, PLAYER, scn, prof)
		picked = {}
		_refresh()))
	confirm = ScreenKit.menu_button("확정 · 출격", true)
	confirm.custom_minimum_size = Vector2(220, BTN_H)
	confirm.pressed.connect(confirm_org)
	foot.add_child(confirm)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, 0.9))

# 게임 흐름의 편성(Q81): 손권·조조(플레이어 아닌 세력)는 언제나 자동 편성. 유비군은 player_auto면 자동, 아니면 정사 편성.
# 조조 비율(target_cost_ratio)은 연합도 한도까지 찬다는 전제라 건너뛰기는 세 세력 모두 자동 편성이다(O3 기준선과 같은 조건).
static func start_org(profile: Dictionary, scenario: Dictionary, player_auto := true) -> Dictionary:
	var o := Organization.default_org(profile)
	for f in scenario.factions:
		if f.control != "player" or player_auto:
			o = Organization.auto_fill(o, f.id, scenario, profile)
	return o

func _load() -> void:
	var b: Node = deck.battle
	scn = ProfileLoader.read_json(ProfileLoader.read_json(b.profile_def).scenario_path)
	prof = ScenarioProfile.load_profile(b.profile_def, b.difficulty)

# 브리핑 "자동 편성으로 시작"(건너뛰기): 화면을 거치지 않고 세 세력 자동 편성으로 전투
func start_auto() -> void:
	_load()
	deck.begin_battle(start_org(prof, scn))

# 브리핑에서 연다. 지금 전투에 걸린 편성(없으면 세 세력 자동 편성 = 건너뛰기와 같은 편성)에서 시작한다.
func open_org() -> void:
	var b: Node = deck.battle
	_load()
	officers = Organization._officers(scn, PLAYER)
	names = {}
	for sq in scn.squadrons:
		names[sq.id] = sq.name
	org = b.org.duplicate(true) if not b.org.is_empty() else start_org(prof, scn)
	sel = -1
	picked = {}
	search.text = ""
	deck.show_screen("org")
	_refresh()

func mine() -> Array:
	var out := []
	for i in org.fleets.size():
		if org.fleets[i].faction_id == PLAYER:
			out.append(i)
	return out

# ------------------------------------------------------------ 편성 조작(테스트도 이 함수들을 쓴다)
func is_flag(i: int) -> bool:
	return Organization._flags(scn).has(org.fleets[i].squadron_id)

func toggle(i: int) -> void:
	var fl: Dictionary = org.fleets[i]
	if is_flag(i):
		return   # Q77: 기함 함대는 끌 수 없다
	fl.on = not fl.on
	if not fl.on:   # 끈 함대의 장수·함선은 대기 풀로
		fl.admiral = ""
		fl.vice = ""
		fl.staff = []
		fl.composition = []
	picked = {}
	_refresh()

func slot_id(i: int, role: String) -> String:
	var fl: Dictionary = org.fleets[i]
	if role == "admiral" or role == "vice":
		return fl[role]
	for s in fl.staff:
		if s.post == role:
			return s.id
	return ""

func _set_slot(i: int, role: String, id: String) -> void:
	var fl: Dictionary = org.fleets[i]
	if role == "admiral" or role == "vice":
		fl[role] = id
		return
	fl.staff = fl.staff.filter(func(s): return s.post != role)
	if id != "":
		fl.staff.append({"post": role, "id": id})
	fl.staff.sort_custom(func(x, y): return Organization.POST_ORDER.find(x.post) < Organization.POST_ORDER.find(y.post))

func _locked(i: int, role: String) -> bool:
	return i >= 0 and role == "admiral" and is_flag(i)

# 칸(fleet ≥ 0) 또는 풀 장수(fleet = -1)를 누른다. 두 번째 누름에서 맞바꾼다.
func press(i: int, role: String, id := "") -> void:
	if i >= 0:
		id = slot_id(i, role)
	if _locked(i, role):
		return
	var cur := {"fleet": i, "role": role, "id": id}
	if picked.is_empty():
		if i >= 0 or id != "":
			picked = cur
	elif picked == cur:
		picked = {}
	elif i < 0 and picked.fleet < 0:
		picked = cur   # 풀 → 풀: 고른 장수만 바꾼다
	else:
		if picked.fleet >= 0:
			_set_slot(picked.fleet, picked.role, id)
		if i >= 0:
			_set_slot(i, role, picked.id)
		picked = {}
	_refresh()

# 확정: 버튼이 검증 통과 뒤에만 켜져도 apply 결과를 먼저 본다(REVIEW-O1b #2). 실패하면 잠그고 사유를 보인다
func confirm_org() -> void:
	var applied := Organization.apply(prof, org, scn)
	if applied.has("errors"):
		_refresh()
		errors = applied.errors
		confirm.disabled = true
		msg.text = "확정할 수 없음 — " + " · ".join(errors.map(reason_text))
		msg.add_theme_color_override("font_color", UiTheme.FOE)
		return
	deck.begin_battle(org.duplicate(true))

func unassign() -> void:
	if picked.is_empty() or picked.fleet < 0:
		return
	_set_slot(picked.fleet, picked.role, "")
	picked = {}
	_refresh()

func cap_left(i: int) -> int:
	var fl: Dictionary = org.fleets[i]
	return Organization.limit_of(fl, scn, prof) - Organization.cost_of(fl, prof)

func ship_count(i: int, t: String) -> int:
	for c in org.fleets[i].composition:
		if c.ship_type_id == t:
			return int(c.count)
	return 0

# 함선 ±(Q80: 함대 예산 = 지휘 한도. +는 한도까지만)
func add_ship(i: int, t: String, d: int) -> void:
	var fl: Dictionary = org.fleets[i]
	if d > 0 and cap_left(i) < int(prof.combat.ship_types[t].cost):
		return
	var entry := {}
	for c in fl.composition:
		if c.ship_type_id == t:
			entry = c
	if entry.is_empty():
		if d < 0:
			return
		entry = {"ship_type_id": t, "count": 0}
		if t == Organization.FILLER:
			entry.mission_equipment_id = Organization.FILLER_EQUIP
		fl.composition.append(entry)
	entry.count = int(entry.count) + d
	if entry.count <= 0:
		fl.composition.erase(entry)
	_refresh()

# ------------------------------------------------------------ 그리기
func reason_text(e: Dictionary) -> String:
	var who: String = names.get(e.squadron_id, "") if e.squadron_id != "" else "유비군"
	return "%s: %s" % [who, REASON.get(e.code, e.code)]

func tier_text(i: int) -> String:
	var t := Organization.tier_of(org.fleets[i], scn, prof)
	if t == 0:
		return ""
	var fx: Dictionary = scn.realtime_rules.commander_succession.confusion.effect_per_stage
	return "지휘 한도 초과 %d단계: 기동 %+d%% · 명중 %+d%% · 진형 전환 %+d%%" % [t, t * int(fx.move_pct), t * int(fx.hit_pct), t * int(fx.formation_change_pct)]

# 함선이 지휘 한도보다 적다(가장 싼 함종 하나도 더 들어간다). 정사 편성은 한도의 약 1/3이라 조조 비율 전제보다 약하다
func under_text(i: int) -> String:
	var fl: Dictionary = org.fleets[i]
	var cheapest := 1 << 30
	for t in prof.combat.ship_types:
		cheapest = mini(cheapest, int(prof.combat.ship_types[t].cost))
	if not fl.on or Organization.limit_of(fl, scn, prof) <= 0 or cap_left(i) < cheapest:
		return ""
	return "함선이 지휘 한도보다 적습니다(비용 %d / 한도 %d). 조조군은 한도까지 채웁니다" % [Organization.cost_of(fl, prof), Organization.limit_of(fl, scn, prof)]

func _refresh() -> void:
	var mine_i := mine()
	if sel < 0 or not mine_i.has(sel):
		sel = mine_i[0] if not mine_i.is_empty() else -1
	errors = Organization.validate(org, scn, prof)
	_fill_fleets(mine_i)
	_fill_detail()
	_fill_pool()
	confirm.disabled = not errors.is_empty()
	if errors.is_empty():
		var ships := 0
		var n := 0
		for i in mine_i:
			if org.fleets[i].on:
				n += 1
				for c in org.fleets[i].composition:
					ships += int(c.count)
		msg.text = "확정 가능 · 출전 %d개 함대 · 총 %d척" % [n, ships]
		msg.add_theme_color_override("font_color", UiTheme.INK_2)
	else:
		msg.text = "확정할 수 없음 — " + " · ".join(errors.map(reason_text))
		msg.add_theme_color_override("font_color", UiTheme.FOE)

func _fill_fleets(mine_i: Array) -> void:
	_clear(fleets_box)
	for i in mine_i:
		var fl: Dictionary = org.fleets[i]
		var card := PanelContainer.new()
		var st := UiTheme.flat(UiTheme.SLOT, UiTheme.GOLD if i == sel else UiTheme.LINE, 2 if i == sel else 1, 4)
		st.set_content_margin_all(10)
		card.add_theme_stylebox_override("panel", st)
		card.modulate.a = 1.0 if fl.on else 0.55
		card.gui_input.connect(_select.bind(i))
		fleets_box.add_child(card)
		var v := VBoxContainer.new()
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(v)
		var top := HBoxContainer.new()
		top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(top)
		var nm := _label(names.get(fl.squadron_id, fl.squadron_id) + ("  · 기함" if is_flag(i) else ""), "Heading")
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(nm)
		var tog := _button("출전" if fl.on else "대기", 96, toggle.bind(i))
		tog.disabled = is_flag(i)
		tog.tooltip_text = "기함 함대는 끌 수 없습니다" if is_flag(i) else ""
		if fl.on:
			tog.theme_type_variation = "PrimaryButton"
		top.add_child(tog)
		if not fl.on:
			v.add_child(_label("출전하지 않음 · 장수·함선은 대기 풀로", "Muted", UiTheme.INK_3))
			continue
		var cost := Organization.cost_of(fl, prof)
		var lim := Organization.limit_of(fl, scn, prof)
		var ships := 0
		for c in fl.composition:
			ships += int(c.count)
		v.add_child(_label("제독 %s · %d척 · 비용 %d / %s" % [_name(fl.admiral), ships, cost, str(lim) if lim > 0 else "—"], "Muted", UiTheme.INK_3))
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.custom_minimum_size.y = 6
		bar.max_value = maxi(1, lim)
		bar.value = mini(cost, lim)
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", UiTheme.flat(Color(0.04, 0.06, 0.09), Color(0.04, 0.06, 0.09)))
		bar.add_theme_stylebox_override("fill", UiTheme.flat(UiTheme.FOE if cost > lim else UiTheme.ALLY, Color(0, 0, 0, 0)))
		v.add_child(bar)
		for e in errors:
			if e.squadron_id == fl.squadron_id:
				v.add_child(_label("⚠ " + REASON.get(e.code, e.code), "Body", UiTheme.FOE))
		if under_text(i) != "":
			v.add_child(_label("△ " + under_text(i), "Body", UiTheme.WARN))
		if tier_text(i) != "":
			v.add_child(_label("△ " + tier_text(i), "Body", UiTheme.WARN))

func _fill_detail() -> void:
	_clear(detail)
	if sel < 0:
		return
	var fl: Dictionary = org.fleets[sel]
	detail.add_child(_label(names.get(fl.squadron_id, fl.squadron_id), "Title"))
	if not fl.on:
		detail.add_child(_label("대기 중인 함대입니다. 왼쪽에서 출전을 켜면 편성할 수 있습니다.", "Body", UiTheme.INK_2))
		return
	detail.add_child(_label("지 휘 부  —  칸을 누르고 다른 칸이나 풀 장수를 누르면 맞바꿉니다", "Eyebrow"))
	var slots := GridContainer.new()
	slots.columns = 5
	slots.add_theme_constant_override("h_separation", 8)
	detail.add_child(slots)
	for r in ROLES:
		var id := slot_id(sel, r[0])
		var lock := _locked(sel, r[0])
		var b := _button("%s%s\n%s" % [r[1], "  (고정)" if lock else "", _card(id, true) if id != "" else "비어 있음"], 0, press.bind(sel, r[0]))
		b.custom_minimum_size.y = 108
		b.clip_text = true
		b.add_theme_font_size_override("font_size", 13)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.disabled = lock
		b.tooltip_text = "기함 제독은 바꿀 수 없습니다" if lock else ""
		if picked.get("fleet", -2) == sel and picked.role == r[0]:
			b.theme_type_variation = "PrimaryButton"
		slots.add_child(b)
	detail.add_child(_label("전 함  —  함종 제한 없음 · 함대 예산 = 지휘 한도", "Eyebrow"))
	var grid := GridContainer.new()   # 함종 8종을 두 열로(1600×900에서 스크롤 없이)
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 28)
	detail.add_child(grid)
	for t in ScenarioRoster.SHIP_TYPES:
		var cost := int(prof.combat.ship_types[t].cost)
		var n := ship_count(sel, t)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(row)
		var nm := _label("%s   %d점" % [ScenarioRoster.SHIP_TYPES[t].name, cost], "Serif")
		nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nm)
		var minus := _button("−", 64, add_ship.bind(sel, t, -1))
		minus.disabled = n == 0
		row.add_child(minus)
		var num := _label(str(n), "Heading")
		num.custom_minimum_size.x = 48
		num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(num)
		var plus := _button("+", 64, add_ship.bind(sel, t, 1))
		plus.disabled = cap_left(sel) < cost
		row.add_child(plus)
		var sub := _label("= %d" % (cost * n), "Muted")
		sub.custom_minimum_size.x = 70
		sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(sub)
	var lim := Organization.limit_of(fl, scn, prof)
	detail.add_child(_label("비용 %d / 지휘 한도 %s  ·  한도 = %d + 제독 통솔 × %d  ·  넘겨도 되지만 불이익" % [Organization.cost_of(fl, prof),
		str(lim) if lim > 0 else "—", int(prof.combat.command.limit_base), int(prof.combat.command.limit_per_command)], "Body", UiTheme.INK_2))
	if under_text(sel) != "":
		detail.add_child(_label("△ " + under_text(sel), "Body", UiTheme.WARN))
	if tier_text(sel) != "":
		detail.add_child(_label("△ " + tier_text(sel), "Body", UiTheme.WARN))

func _fill_pool() -> void:
	_clear(pool_box)
	if not picked.is_empty() and picked.fleet >= 0 and picked.id != "":
		var back := _button("↩ 고른 장수를 대기 풀로", 0, unassign)
		pool_box.add_child(back)
	var used := {}
	for i in mine():
		if org.fleets[i].on:
			for id in Organization._people(org.fleets[i]):
				used[id] = true
	var q := search.text.strip_edges()
	var ids := officers.keys().filter(func(id): return not used.has(id) and (q == "" or q in str(officers[id].name) or q in " ".join(officers[id].get("traits", []))))
	ids.sort_custom(func(a, b): return int(officers[a].command) > int(officers[b].command) or (int(officers[a].command) == int(officers[b].command) and a < b))
	for id in ids:
		var b := _button(_card(id), 0, press.bind(-1, "", id))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if picked.get("fleet", -2) == -1 and picked.id == id:
			b.theme_type_variation = "PrimaryButton"
		pool_box.add_child(b)
	if ids.is_empty():
		pool_box.add_child(_label("미배치 장수가 없습니다. 함대를 대기로 돌리면 그 장수가 여기로 옵니다.", "Muted", UiTheme.INK_3))
	var c := 0
	var l := 0
	for i in mine():
		if org.fleets[i].on:
			c += Organization.cost_of(org.fleets[i], prof)
			l += Organization.limit_of(org.fleets[i], scn, prof)
	sum_label.text = "비용 / 한도 합  %d / %d\n세력 예산은 없습니다. 함대마다 지휘 한도까지 채웁니다." % [c, l]

# ------------------------------------------------------------ 부품
func _name(id: String) -> String:
	return str(officers[id].name) if officers.has(id) else "—"

# 장수 카드 문구. compact = 직책 칸(좁아서 능력치를 두 줄로)
func _card(id: String, compact := false) -> String:
	var o: Dictionary = officers.get(id, {})
	if o.is_empty():
		return id
	var tr: Array = o.get("traits", [])
	return ("%s%s\n통%d 무%d 지%d\n정%d 매%d" if compact else "%s%s\n통%d 무%d 지%d 정%d 매%d") % [o.name, " · " + str(tr[0]) if not tr.is_empty() else "",
		int(o.command), int(o.might), int(o.intellect), int(o.politics), int(o.charm)]

func _select(e: InputEvent, i: int) -> void:
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		sel = i
		picked = {}
		_refresh.call_deferred()

func _column(parent: Control, title: String, w: float) -> VBoxContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiTheme.flat(Color(0.05, 0.08, 0.11, 0.92), UiTheme.LINE, 1, 6))
	p.custom_minimum_size.x = w
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL if w == 0 else Control.SIZE_FILL
	parent.add_child(p)
	var mc := MarginContainer.new()
	for k in ["left", "right", "top", "bottom"]:
		mc.add_theme_constant_override("margin_" + k, 12)
	p.add_child(mc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	mc.add_child(v)
	v.add_child(_label(title, "Eyebrow"))
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 8)
	sc.add_child(box)
	return box

func _label(text: String, variation: String, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _button(text: String, w: float, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(w, BTN_H)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(cb)
	return b

static func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()
