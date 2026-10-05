class_name BattleHud
extends RefCounted

# POC HUD: 상단 CP·시계·속도, 교신 로그, 토스트, 함대 정보 패널, 그룹 탭, 명령 버튼, 브리핑·일시정지·종료 오버레이.
# 규칙을 계산하지 않는다. 호스트(전투 노드)의 화면 모델과 명령 함수만 쓴다.
# 상품화 HUD(hud/ui_kit)가 있으면 이 HUD의 CanvasLayer가 통째로 숨겨진다.

const C_ALLY := Color("5fe0cf")
const C_FOE := Color("ff7550")
const C_LIFE := Color("63d47e")
const C_GOLD := Color("f0c24b")
const C_INK := Color("dbe7e1")
const C_MUTE := Color("8ea29a")
const C_RIVET := Color("3d4f47")

var b: Node                     # 호스트(전투 노드)
var ui: Control                 # 라벨·그리기 컨트롤(FleetLabels). HUD 위젯은 이 아래에 붙는다.
var vsize := Vector2(1600.0, 900.0)
var radar: Control
var cp_fills: Array[ColorRect] = []
var cp_num: Label
var clock_label: Label
var speed_btn: Button
var log_box: VBoxContainer
var toast_label: Label
var panel_root: Control
var p_portrait: TextureRect
var p_name: Label
var p_role: Label
var p_ships: Label
var p_bar: ProgressBar
var p_chips: Label
var p_hint: Label
var cmd_btns := {}
var group_btns: Array[Button] = []
var brief_ov: Control
var menu_ov: Control
var end_ov: Control
var toast_tween: Tween

static func style(bg: Color, border: Color, radius := 6, bw := 1) -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = bg
	st.border_color = border
	st.set_border_width_all(bw)
	st.set_corner_radius_all(radius)
	return st

func _panel(parent: Node, pos: Vector2, sz: Vector2, bg: Color, border: Color, radius := 6) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = sz
	p.add_theme_stylebox_override("panel", style(bg, border, radius))
	parent.add_child(p)
	return p

func _label(parent: Node, text: String, pos: Vector2, size: int, color: Color, width := -1.0) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if width > 0.0:
		l.size = Vector2(width, size * 1.4)
		l.clip_text = true
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _button(parent: Node, text: String, pos: Vector2, sz: Vector2, size: int, bg: Color, border: Color) -> Button:
	var bt := Button.new()
	bt.text = text
	bt.position = pos
	bt.size = sz
	bt.focus_mode = Control.FOCUS_NONE
	bt.add_theme_font_size_override("font_size", size)
	bt.add_theme_stylebox_override("normal", style(bg, border, 4))
	bt.add_theme_stylebox_override("hover", style(bg.lightened(0.18), C_ALLY, 4))
	bt.add_theme_stylebox_override("pressed", style(bg.darkened(0.2), C_ALLY, 4))
	bt.add_theme_stylebox_override("disabled", style(bg.darkened(0.4), border, 4))
	parent.add_child(bt)
	return bt

func build(host: Node, ui_control: Control, viewport_size: Vector2, radar_control: Control) -> void:
	b = host
	ui = ui_control
	vsize = viewport_size
	radar = radar_control
	# ---- 상단 중앙: 커맨드 포인트 + SYSTEM ----
	var top := _panel(ui, Vector2(vsize.x * 0.5 - 200.0, 6.0), Vector2(400.0, 38.0), Color("18211e"), C_RIVET, 6)
	var hex := ColorRect.new()
	hex.color = C_GOLD
	hex.position = Vector2(10.0, 12.0)
	hex.size = Vector2(14.0, 14.0)
	top.add_child(hex)
	for i in 10:
		var back := ColorRect.new()
		back.color = Color("1a2a44")
		back.position = Vector2(32.0 + i * 22.0, 14.0)
		back.size = Vector2(20.0, 10.0)
		top.add_child(back)
		var fill := ColorRect.new()
		fill.color = Color("5f8fea")
		fill.size = Vector2(0.0, 10.0)
		back.add_child(fill)
		cp_fills.append(fill)
	cp_num = _label(top, "0", Vector2(256.0, 9.0), 16, Color("b9cdfa"))
	var sys := _button(top, "SYSTEM", Vector2(300.0, 6.0), Vector2(90.0, 26.0), 12, Color("2b3a34"), Color("5d7268"))
	sys.pressed.connect(b._toggle_menu)

	# ---- 상단 우측: 시계 + 속도 ----
	clock_label = _label(ui, "00:00", Vector2(vsize.x - 130.0, 10.0), 16, C_MUTE)
	speed_btn = _button(ui, "×1", Vector2(vsize.x - 66.0, 6.0), Vector2(54.0, 28.0), 13, Color("2b3a34"), Color("5d7268"))
	speed_btn.pressed.connect(b._toggle_speed)

	# ---- 상단 좌측: 교신 로그 ----
	log_box = VBoxContainer.new()
	log_box.position = Vector2(12.0, 8.0)
	log_box.size = Vector2(320.0, 200.0)
	log_box.add_theme_constant_override("separation", 4)
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(log_box)

	toast_label = _label(ui, "", Vector2(0.0, vsize.y - 210.0), 15, C_GOLD, vsize.x)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.modulate.a = 0.0

	# ---- 하단 좌측: 레이더 ----
	var rw := _panel(ui, Vector2(12.0, vsize.y - 152.0), Vector2(140.0, 140.0), Color("101714"), C_RIVET, 70)
	radar.position = Vector2(6.0, 6.0)
	radar.size = Vector2(128.0, 128.0)
	radar.clip_contents = true
	rw.add_child(radar)

	# ---- 하단 중앙: 함대 정보 패널 ----
	panel_root = _panel(ui, Vector2(vsize.x * 0.5 - 280.0, vsize.y - 116.0), Vector2(560.0, 108.0), Color("1c2723"), C_RIVET, 6)
	p_portrait = TextureRect.new()
	p_portrait.position = Vector2(10.0, 10.0)
	p_portrait.size = Vector2(88.0, 88.0)
	p_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	p_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	panel_root.add_child(p_portrait)
	p_name = _label(panel_root, "", Vector2(108.0, 8.0), 18, Color("f1f6f3"), 440.0)
	p_role = _label(panel_root, "", Vector2(108.0, 32.0), 12, C_MUTE, 440.0)
	p_ships = _label(panel_root, "", Vector2(108.0, 50.0), 13, Color("c9d8d1"), 440.0)
	p_bar = ProgressBar.new()
	p_bar.position = Vector2(108.0, 72.0)
	p_bar.size = Vector2(440.0, 7.0)
	p_bar.show_percentage = false
	p_bar.add_theme_stylebox_override("background", style(Color("0a1210"), Color("2d3b35"), 2))
	p_bar.add_theme_stylebox_override("fill", style(C_LIFE, C_LIFE, 2, 0))
	panel_root.add_child(p_bar)
	p_chips = _label(panel_root, "", Vector2(108.0, 84.0), 12, C_MUTE, 440.0)
	p_hint = _label(panel_root, "", Vector2(20.0, 26.0), 14, C_MUTE, 520.0)
	p_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	p_hint.clip_text = false

	# ---- 하단 우측: 그룹 탭 + 명령 ----
	var gx := vsize.x - 12.0 - 156.0
	for i in 4:
		var gb := _button(ui, ["I", "II", "III", "IV"][i], Vector2(gx + i * 39.0, vsize.y - 12.0 - 100.0 - 6.0 - 34.0), Vector2(34.0, 34.0), 12, Color("2f5ea8"), Color("7fb3ff"))
		gb.tooltip_text = "그룹 %s 선택 (%d) · 길게 누르면 저장" % [["I", "II", "III", "IV"][i], i + 1]
		var idx := i + 1
		gb.button_down.connect(b._group_down.bind(idx))
		gb.button_up.connect(b._group_up.bind(idx))
		group_btns.append(gb)
	var cmd_panel := _panel(ui, Vector2(vsize.x - 12.0 - 210.0, vsize.y - 12.0 - 100.0), Vector2(210.0, 100.0), Color("1c2723"), C_RIVET, 6)
	for i in b.CMDS.size():
		var c: Dictionary = b.CMDS[i]
		var warm := Color("35507a")
		if c.id == "missile" or c.id == "fighter":
			warm = Color("7a3a4c")
		elif c.id == "charge":
			warm = Color("7a6230")
		var label := "%s\n%s" % [["정지", "방어", "미사일", "함재기", "돌격", "집결", "후퇴", "전체"][i], c.key]
		var cb := _button(cmd_panel, label, Vector2(7.0 + (i % 4) * 49.0, 7.0 + (i / 4) * 47.0), Vector2(46.0, 44.0), 10, warm, Color("4a5e56"))
		cb.tooltip_text = "%s (%s)%s" % [c.name, c.key, (" · CP %d" % c.cost) if c.cost > 0 else ""]
		cb.pressed.connect(b.do_cmd.bind(c.id))
		cmd_btns[c.id] = cb

	# ---- 오버레이 ----
	brief_ov = _overlay(
		"손유 연합함대 · 작전 브리핑",
		"적벽 전투",
		"연합 총지휘 유비. 조조군 7개 분함대가 적벽으로 건너오고 있습니다. 교전 중 적 증원이 측면에서 나타날 가능성이 있습니다. 기함을 지키면서 적 함대를 모두 격파하십시오.\n\n"
		+ "• 측면·배후 공격: 적의 옆구리를 치면 화력 +30%, 뒤를 잡으면 +60%.\n"
		+ "• 지휘 범위: 기함 주위 원 밖의 함대는 화력이 25% 떨어집니다.\n"
		+ "• 커맨드 포인트: 상단 게이지로 미사일, 함재기, 돌격 명령을 쓸 수 있습니다.\n\n"
		+ "선택: 함대 클릭 · 드래그 범위 선택 · 그룹 I–IV (Ctrl+숫자로 지정)\n"
		+ "명령: 빈 곳 클릭/우클릭 = 이동 · 적 함대 클릭 = 공격 · Esc = 선택 해제\n"
		+ "화면: 우클릭 드래그 또는 방향키 = 이동 · 휠 = 확대 · 레이더 클릭 = 점프 · Space = 일시정지",
		[["출격", b._start]])
	menu_ov = _overlay("SYSTEM", "일시정지",
		"S 정지 · D 방어진형 · M 미사일 · F 함재기\nC 돌격 · R 기함으로 집결 · G 후퇴 · A 전 함대 선택\n그룹 탭을 길게 누르면 현재 선택을 그 탭에 저장합니다.",
		[["계속", b._close_menu], ["처음부터", b._restart], ["종료", b._quit]])
	menu_ov.visible = false
	end_ov = _overlay("전투 종료", "승리", "", [["다시 출격", b._restart]])
	end_ov.visible = false

func _overlay(eyebrow: String, title: String, body: String, buttons: Array) -> Control:
	var ov := ColorRect.new()
	ov.color = Color(0.01, 0.015, 0.03, 0.82)
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(ov)
	var card := _panel(ov, Vector2(vsize.x * 0.5 - 310.0, vsize.y * 0.5 - 250.0), Vector2(620.0, 500.0), Color("141c19"), C_RIVET, 8)
	var eb := _label(card, eyebrow, Vector2(28.0, 24.0), 12, C_ALLY)
	var t := _label(card, title, Vector2(28.0, 46.0), 34, Color("f3f8f5"))
	var bd := _label(card, body, Vector2(28.0, 100.0), 14, Color("c3d3cb"), 564.0)
	bd.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bd.clip_text = false
	bd.size = Vector2(564.0, 300.0)
	ov.set_meta("eyebrow", eb)
	ov.set_meta("title", t)
	ov.set_meta("body", bd)
	var x := 28.0
	for spec in buttons:
		var bt := _button(card, spec[0], Vector2(x, 428.0), Vector2(140.0, 46.0), 16, Color("1f8f81") if x < 30.0 else Color("2b3a34"), C_ALLY)
		bt.pressed.connect(spec[1])
		x += 152.0
	return ov

# ============================================================ 갱신
func reset() -> void:
	speed_btn.text = "×1"
	for c in log_box.get_children():
		c.queue_free()

func toast(text: String) -> void:
	toast_label.text = text
	if toast_tween:
		toast_tween.kill()
	toast_label.modulate.a = 1.0
	toast_tween = toast_label.create_tween()
	toast_tween.tween_interval(1.5)
	toast_tween.tween_property(toast_label, "modulate:a", 0.0, 0.3)

func add_log(text: String, kind: String, f) -> void:
	var row := PanelContainer.new()
	var border := C_ALLY
	if kind == "foe":
		border = C_FOE
	elif kind == "sys":
		border = C_GOLD
	row.add_theme_stylebox_override("panel", style(Color(0.05, 0.11, 0.10, 0.85) if kind != "foe" else Color(0.16, 0.06, 0.05, 0.85), border, 2))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(hb)
	if f:
		var tr := TextureRect.new()
		tr.texture = b._portrait_tex(f.portrait)
		tr.custom_minimum_size = Vector2(26.0, 26.0)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		hb.add_child(tr)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 12)
	l.add_theme_color_override("font_color", C_INK)
	hb.add_child(l)
	log_box.add_child(row)
	log_box.move_child(row, 0)
	while log_box.get_child_count() > 6:
		log_box.get_child(log_box.get_child_count() - 1).queue_free()
		log_box.remove_child(log_box.get_child(log_box.get_child_count() - 1))
	var tw := row.create_tween()
	tw.tween_interval(6.5)
	tw.tween_property(row, "modulate:a", 0.0, 0.6)
	tw.tween_callback(row.queue_free)

func show_end(win: bool, text: String, killed: float, lost: float, clock_s: float) -> void:
	end_ov.visible = true
	(end_ov.get_meta("eyebrow") as Label).text = "작전 성공" if win else "작전 실패"
	(end_ov.get_meta("title") as Label).text = "적벽을 지켜냈습니다" if win else "기함 격침"
	var t := int(clock_s)
	(end_ov.get_meta("body") as Label).text = "%s\n\n격침한 적 함정  %d\n잃은 아군 함정  %d\n교전 시간  %d:%02d" % [text, roundi(killed), roundi(lost), t / 60, t % 60]

func chips_for(f) -> String:
	var c: Array[String] = []
	if f.is_flag:
		c.append("[기함]")
	if f.defense:
		c.append("[방어진형]")
	if f.charge_t > 0.0:
		c.append("[돌격 %ds]" % ceili(f.charge_t))
	if not f.in_cmd:
		c.append("[지휘 범위 밖]")
	c.append("[미사일 %s]" % (("%ds" % ceili(f.missile_cd)) if f.missile_cd > 0.0 else "준비"))
	c.append("[함재기 %s]" % (("%ds" % ceili(f.fighter_cd)) if f.fighter_cd > 0.0 else "준비"))
	return " ".join(c)

func refresh_panel() -> void:
	if p_name == null:
		return
	var s: Array = b.my_sel()
	var single = null
	if s.size() == 1:
		single = s[0]
	elif s.is_empty() and b.inspect and not b.inspect.dead:
		single = b.inspect
	p_portrait.visible = single != null
	p_name.visible = single != null or s.size() > 1
	p_role.visible = p_name.visible
	p_ships.visible = p_name.visible
	p_bar.visible = p_name.visible
	p_chips.visible = single != null
	p_hint.visible = not p_name.visible
	if single:
		var foe: bool = single.side == 1
		p_portrait.texture = b._portrait_tex(single.portrait)
		p_name.text = "%s 함대" % single.fname
		p_role.text = single.role + (" · 적" if foe else "")
		p_ships.text = "Lv.%02d      %d / %d척" % [single.lv, ceili(single.ships), int(single.max_ships)]
		p_bar.value = single.ships / single.max_ships * 100.0
		p_bar.add_theme_stylebox_override("fill", style(C_FOE if foe else C_LIFE, C_FOE if foe else C_LIFE, 2, 0))
		if foe:
			p_chips.text = ("[방어진형] " if single.defense else "") + ("[기함]" if single.is_flag else "")
		else:
			p_chips.text = chips_for(single)
		_shift_panel(108.0)
	elif s.size() > 1:
		var tot := 0.0
		var mx := 0.0
		var names: Array[String] = []
		for f in s:
			tot += f.ships
			mx += f.max_ships
			names.append(f.fname)
		p_name.text = "%d개 함대 선택" % s.size()
		p_role.text = " · ".join(names)
		p_ships.text = "%d / %d척" % [ceili(tot), int(mx)]
		p_bar.value = tot / mx * 100.0
		p_bar.add_theme_stylebox_override("fill", style(C_LIFE, C_LIFE, 2, 0))
		_shift_panel(16.0)
	else:
		var a: Array = b.alive(0)
		var e: Array = b.alive(1)
		var at := 0.0
		var et := 0.0
		for f in a:
			at += f.ships
		for f in e:
			et += f.ships
		p_hint.text = "함대를 선택하세요.  아군 %d개 함대 · %d척\n적 %d개 함대 · %d척 확인" % [a.size(), ceili(at), e.size(), ceili(et)]
	paint_groups()

func _shift_panel(x: float) -> void:
	for l in [p_name, p_role, p_ships, p_chips]:
		l.position.x = x
	p_bar.position.x = x
	p_bar.size.x = 548.0 - x
	for l in [p_name, p_role, p_ships, p_chips]:
		l.size.x = 548.0 - x

func paint_groups() -> void:
	for i in 4:
		var g: Array = b.group_fleets(i + 1)
		var gb := group_btns[i]
		gb.modulate = Color(1, 1, 1, 0.45 if g.is_empty() else (1.0 if b.same_sel(g) else 0.8))

func paint_cmds() -> void:
	var s: Array = b.my_sel()
	for c in b.CMDS:
		var cb: Button = cmd_btns[c.id]
		var dis := false
		if c.id != "all" and s.is_empty():
			dis = true
		if c.cost > 0 and b.G.cp < c.cost:
			dis = true
		if c.id == "missile" and not s.is_empty():
			var m := 999.0
			for f in s:
				m = minf(m, f.missile_cd)
			if m > 0.0:
				dis = true
		if c.id == "fighter" and not s.is_empty():
			var m := 999.0
			for f in s:
				m = minf(m, f.fighter_cd)
			if m > 0.0:
				dis = true
		cb.modulate = Color(0.55, 0.55, 0.55, 1.0) if dis else Color.WHITE
	for i in 10:
		cp_fills[i].size.x = 20.0 * clampf(b.G.cp - i, 0.0, 1.0)
	cp_num.text = str(int(b.G.cp))
	var t := int(b.G.t)
	clock_label.text = "%02d:%02d" % [t / 60, t % 60]
