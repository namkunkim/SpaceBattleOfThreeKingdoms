extends Control

# P7 보급·수리 메뉴 패널(명령 데크의 "보급"/"수리" 탭이 켠다). 코어 투영의 supply.menu를 읽어 보여 줄 뿐이다.
# 자동 보급은 그대로 두고, 여기서는 "이 함대 먼저"(우선 대상 지정)만 보낸다. 중지/재개 버튼은 데크 탭의 명령 버튼이 맡는다.
# 새 수치는 만들지 않는다: 레벨 = 코어 보충 횟수(3/2/1), 처리량 = 선체 구간(100/50/25%).

const W := preload("res://hud/ui_kit/deck_widgets.gd")
const SIZE := Vector2(440, 292)
const MAX_ROWS := 3

var deck: Node
var mode := "supply"   # supply | repair
var _sig := ""
var _box: VBoxContainer
var _bg: Control

func setup(d: Node) -> void:
	deck = d
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg = W.DrawPanel.new(Callable(), UiTheme.ornate())
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE   # 패널 빈 곳의 클릭은 전장으로 통과한다. 버튼만 막는다
	add_child(_bg)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_box = VBoxContainer.new()
	add_child(_box)
	_box.position = Vector2(12, 8)
	_box.size = SIZE - Vector2(24, 16)
	_box.add_theme_constant_override("separation", 2)
	_box.mouse_filter = Control.MOUSE_FILTER_IGNORE

# ------------------------------------------------------------ 문구(순수 함수, 헤드리스로 시험한다)
static func level_text(m: Dictionary) -> String:
	var t := "보급 레벨 %d/%d (처리량 %d%%, 보충 %d회)" % [m.level, m.level_max, int(m.rate_bp) / 100, m.level]
	if m.has("politics") and int(m.politics) >= 0:
		t += " · 보급대장 %s 정치 %d" % [m.get("chief", ""), m.politics]
	elif m.has("chief") and m.chief != "":
		t += " · 보급대장 %s" % m.chief
	return t

static func stock_text(m: Dictionary) -> String:
	return "재고 탄약 %d/%d · 물자 %d/%d" % [m.stock_ammo, m.ammo_max, m.stock_materials, m.materials_max]

static func dock_text(m: Dictionary) -> String:
	return "처리 자리 %d/%d 사용 중 · 남은 %d" % [m.docks_used, m.docks, maxi(0, int(m.docks) - int(m.docks_used))]

static func need_text(t: Dictionary, md: String) -> String:
	var parts := PackedStringArray()
	if md == "repair":
		parts.append("수리 필요 %d척" % t.repair if int(t.repair) > 0 else "수리 불필요")
	else:
		if int(t.charges) > 0:
			parts.append("횟수 -%d" % t.charges)
		if int(t.ammo) > 0:
			parts.append("탄약 -%d" % t.ammo)
		if parts.is_empty():
			parts.append("보충 불필요")
	if t.serving:
		parts.append("처리 중 %d초" % ceili(float(t.left_s)))
	elif not t.still:
		parts.append("이동 중")
	return " · ".join(parts)

# 탭별 목록: 수리 = 수리 필요 함대를 수리할 척 수 많은 순, 보급 = 횟수·탄약 결손이 있거나 처리 중인 함대(가까운 순)
static func shown(m: Dictionary, md: String) -> Array:
	var out := []
	for t in m.targets:
		if md == "repair":
			if int(t.repair) > 0:
				out.append(t)
		elif int(t.charges) > 0 or int(t.ammo) > 0:
			out.append(t)
	if md == "repair":
		out.sort_custom(func(a, b): return a.repair > b.repair if a.repair != b.repair else a.dist < b.dist)
	return out

# ------------------------------------------------------------ 갱신(초당 10회 이하로 불린다)
# 구조(함대·대상 목록·지정·중지)가 바뀔 때만 위젯을 다시 만들고, 숫자는 제자리에서 고친다(누르는 중에 버튼이 사라지지 않게).
var _lines: Array = []   # [Label, Callable(v) -> String]
var _rows := {}          # 대상 ID -> Label

func refresh(v: Dictionary) -> void:
	if v.is_empty():
		visible = false
		return
	visible = true
	var m: Dictionary = v.menu
	var ids := []
	for t in shown(m, mode):
		ids.append(int(t.id))
	var sig := "%s|%d|%s|%d|%s" % [mode, v.id, m.hold, m.first, ids]
	if sig != _sig:
		_sig = sig
		_build(v, m)
	for ln in _lines:
		ln[0].text = ln[1].call(v.menu)
	for t in shown(m, mode):
		if _rows.has(int(t.id)):
			_rows[int(t.id)].text = "%s  %s" % [v.names.get(int(t.id), "?"), need_text(t, mode)]

func _build(v: Dictionary, m: Dictionary) -> void:
	for c in _box.get_children():
		_box.remove_child(c)
		c.queue_free()
	_lines.clear()
	_rows.clear()
	var title := _label("%s · %s" % [v.name, "수리" if mode == "repair" else "보급"], "Strong", 14)
	_box.add_child(title)
	_line(level_text, "Body")
	_line(dock_text if mode == "repair" else stock_text, "Body")
	if mode == "repair":
		_line(stock_text, "Muted")
	if m.hold:
		_box.add_child(_label("자동 보급 중지됨", "Strong", 12))
	var list := shown(m, mode)
	for k in mini(MAX_ROWS, list.size()):
		_box.add_child(_row(v, m, list[k]))
	if list.is_empty():
		_box.add_child(_label("수리가 필요한 함대가 없습니다" if mode == "repair" else "보급이 필요한 함대가 없습니다", "Muted", 12))
	elif list.size() > MAX_ROWS:
		_box.add_child(_label("외 %d개 함대" % (list.size() - MAX_ROWS), "Muted", 12))

func _line(fn: Callable, variation: String) -> void:
	var l := _label("", variation, 12)
	_box.add_child(l)
	_lines.append([l, fn])

func _label(text: String, variation: String, size: int) -> Label:
	var l := UiTheme.label(text, variation, size)
	l.custom_minimum_size = Vector2(0, 18)
	return l

func _row(v: Dictionary, m: Dictionary, t: Dictionary) -> Control:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	var l := UiTheme.label("", "Body", 12)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(l)
	_rows[int(t.id)] = l
	var first: bool = int(m.first) == int(t.id)
	var b := Button.new()
	b.text = "먼저 해제" if first else "먼저"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(78, 48)
	for st in ["normal", "pressed"]:
		b.add_theme_stylebox_override(st, UiTheme.flat(Color(0.04, 0.06, 0.08, 0.78), UiTheme.LINE))
	b.add_theme_stylebox_override("hover", UiTheme.flat(Color(0.07, 0.1, 0.12, 0.88), UiTheme.GOLD))
	b.add_theme_font_size_override("font_size", 13)
	b.set_meta("target_id", int(t.id))
	b.pressed.connect(func(): deck.battle.cmds.supply_first(int(v.id), -1 if first else int(t.id)))
	h.add_child(b)
	return h
