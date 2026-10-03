extends Control

# 명령 데크: 전투 HUD 전체와 화면 흐름(타이틀 → 브리핑 → 전투 → 일시정지/결과).
# 전투 규칙과 입력은 POC(FleetBattle3D.gd)가 그대로 처리한다. 여기서는 읽고, 명령은 POC 함수로 넘긴다.
# 화면 배치는 제안서 v0.2 §7.1을 따른다. 코어에 아직 없는 값(사기, 국면, 탄약·열)은 자리를 두지 않는다.

const W := preload("res://hud/ui_kit/deck_widgets.gd")
const Screens := preload("res://hud/ui_kit/deck_screens.gd")
const Pacing := preload("res://hud/ui_kit/battle_pacing.gd")
const Guard := preload("res://hud/ui_kit/session_guard.gd")
const Undo := preload("res://hud/ui_kit/order_undo.gd")
const Card := preload("res://hud/ui_kit/decision_card.gd")
const Strip := preload("res://hud/ui_kit/squadron_strip.gd")

# 이름·아이콘만 여기 둔다. 효과 문구와 수치는 규칙 값(BattleSource.rules → RuleText.cmd)에서 만든다.
# confirm: 되돌릴 수 없거나 비용이 큰 명령은 길게 눌러 확정한다(EXPERIENCE-DESIGN §6 U3). 단축키는 바로 실행.
const CMD_INFO := {
	"stop": {"label": "정지", "icon": "stop", "desc": "이동과 공격 명령을 멈추고 그 자리에서 대기합니다. 사거리 안의 적은 계속 사격합니다."},
	"def": {"label": "방어진형", "icon": "def"},
	"charge": {"label": "돌격", "icon": "charge", "tone": "warm", "confirm": true},
	"rally": {"label": "기함 집결", "icon": "rally"},
	"retreat": {"label": "후퇴", "icon": "retreat", "confirm": true},
	"all": {"label": "전체 선택", "icon": "all", "desc": "살아 있는 아군 함대를 모두 선택합니다."},
	"missile": {"label": "미사일", "icon": "missile", "tone": "hot"},
	"fighter": {"label": "함재기", "icon": "fighter", "tone": "hot"},
}
const TABS := [["태세", ["stop", "def", "charge", "rally", "retreat", "all"]], ["무장", ["missile", "fighter"]]]

var battle: Node
var src: BattleSource
var renderer: FleetRenderer
var overlay: TacticalOverlay
var hud: Control
var screens := {}
var screen := ""
var t := 0.0

var top_bar: Control
var cp_bar: Control
var sys_bar: HBoxContainer
var speed_btns: Array = []
var pause_btn: Control
var skip_btn: Control
var pacing: Node
var hold_tip: HoldTip
var undo_bar: Control
var decision_card: Control
var strip: Control
var sound: UiSound
const CONFIRM_HOLD := 0.6   # 길게 눌러 확정(리뷰 U3)
var _confirm_btn: Control = null
var _confirm_t := 0.0
var _confirm_fired := false
var _tag_flash := 0.0   # 배속이 바뀌면 상단 상태 문구가 반짝인다(리뷰 U8)
var guard: Node
var objectives: Control
var log_box: VBoxContainer
var cut: Control
var cut_data := {}
var cut_tween: Tween
var cut_cool := 0.0
var radar: RadarScope
var info: Control
var groups_row: HBoxContainer
var cmd_panel: Control
var cmd_tabs: Array = []
var cmd_grid: GridContainer
var cmd_buttons: Array = []
var tab_index := 0
var toast: Control
var toast_text := ""
var toast_tween: Tween
var log_items: Array = []
var _redraw_acc := 0.0

func setup(b: Node, s: BattleSource, r: FleetRenderer) -> void:
	battle = b
	src = s
	renderer = r
	theme = UiTheme.build()
	pacing = Pacing.new()
	pacing.name = "BattlePacing"
	add_child(pacing)
	pacing.setup(self, src)
	pacing.changed.connect(func(): _tag_flash = 0.8)
	guard = Guard.new()
	guard.name = "SessionGuard"
	add_child(guard)
	guard.setup(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay = TacticalOverlay.new()
	add_child(overlay)
	overlay.setup(battle)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	_build_top()
	_build_sys()
	_build_log()
	_build_cut()
	_build_radar()
	_build_info()
	_build_commands()
	_build_toast()
	# 명령 되돌리기 알림: 정보 패널 바로 위(결정 카드가 오면 그 위로 올린다)
	undo_bar = Undo.new()
	hud.add_child(undo_bar)
	_anchor(undo_bar, Control.PRESET_CENTER_BOTTOM, Vector2(420, 52), Vector2(0, -180))
	undo_bar.setup(self, src)
	# 결정 카드: 정보 패널 자리(화면 아래 가운데, 엄지 영역). 뜨면 정보 패널을 가리고 되돌리기 알림을 그 위로 올린다.
	decision_card = Card.new()
	hud.add_child(decision_card)
	_anchor(decision_card, Control.PRESET_CENTER_BOTTOM, Vector2(720, 210), Vector2(0, -14))
	decision_card.setup(self)
	decision_card.visibility_changed.connect(func():
		info.visible = not decision_card.visible
		undo_bar.offset_top = -(decision_card.size.y + 14 + 10 + 52) if decision_card.visible else -(158 + 14 + 10 + 52)
		undo_bar.offset_bottom = undo_bar.offset_top + 52)
	# 터치 길게 누르기 툴팁: HUD 위, 전환 화면 아래
	hold_tip = HoldTip.new()
	add_child(hold_tip)
	for c in sys_bar.get_children():
		hold_tip.register(c)
	for c in cmd_buttons:
		hold_tip.register(c)
	screens = Screens.build_all(self)
	_build_sound()
	battle.battle_event.connect(_on_event)
	GameSettings.apply(get_window())
	get_window().title = "성한지 — 적벽 회랑"
	show_screen("title")

# ------------------------------------------------------------ 화면 흐름
func show_screen(name: String) -> void:
	screen = name
	for k in screens:
		var sc: Control = screens[k]
		if k == name:
			sc.visible = true
			sc.modulate.a = 0.0
			create_tween().set_ignore_time_scale().tween_property(sc, "modulate:a", 1.0, 0.25)
			if sc.has_method("on_show"):
				sc.on_show()
		else:
			sc.visible = false
	var in_battle := name == "" or name == "pause" or name == "settings_pause" or name == "result"
	hud.visible = in_battle and name != "result"
	overlay.visible = in_battle and name != "result"

func begin_battle() -> void:
	if battle.G.state != "brief":
		battle.init_game()
	_clear_log()
	battle._start()
	show_screen("")
	_cutin_fleet(battle.flag(0), Commanders.OPEN_LINE)

func restart() -> void:
	_clear_log()
	battle._restart()
	show_screen("")

func to_title() -> void:
	battle.init_game()
	_clear_log()
	show_screen("title")

func resume() -> void:
	if battle.G.state == "pause":
		battle._close_menu()
	guard.clear()
	show_screen("")

func open_pause() -> void:
	if battle.G.state == "play":
		battle._toggle_menu()

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	t += delta
	_tag_flash = maxf(0.0, _tag_flash - delta)
	_confirm_tick(delta)
	cut_cool = maxf(0.0, cut_cool - delta)
	var st: String = battle.G.get("state", "")
	if st == "pause" and screen == "":
		show_screen("pause")
	elif st == "play" and (screen == "pause" or screen == "settings_pause"):
		guard.clear()
		show_screen("")
	elif st == "end" and screen != "result":
		show_screen("result")
	if hud.visible:
		_age_log(delta)
		# 패널은 초당 10회만 다시 그린다(전장 오버레이와 레이더는 따로 갱신).
		_redraw_acc += delta
		if _redraw_acc >= 0.1:
			_redraw_acc = 0.0
			_refresh_cmds()
			for c in [top_bar, cp_bar, objectives, info, toast]:
				c.queue_redraw()
			for g in groups_row.get_children():
				g.queue_redraw()
			for i in speed_btns.size():
				speed_btns[i].active = pacing.user_speed == i + 1 and pacing.mode == pacing.Mode.USER
				speed_btns[i].queue_redraw()
			skip_btn.disabled = not pacing.can_skip()
			skip_btn.tooltip_text = "다음 교전·경보까지 건너뛰기" + (" · " + pacing.next_stop_hint() if pacing.quiet else " (조용한 구간에서만)")
			skip_btn.active = pacing.mode == pacing.Mode.SKIP
			skip_btn.queue_redraw()

func _anchor(c: Control, preset: int, sz: Vector2, off := Vector2.ZERO) -> void:
	c.set_anchors_preset(preset)
	c.custom_minimum_size = sz
	c.size = sz
	var ax := c.anchor_left
	var ay := c.anchor_top
	c.offset_left = -sz.x * ax + off.x
	c.offset_top = -sz.y * ay + off.y
	c.offset_right = c.offset_left + sz.x
	c.offset_bottom = c.offset_top + sz.y

# ------------------------------------------------------------ 상단 전황
func _build_top() -> void:
	top_bar = W.DrawPanel.new(_draw_top, UiTheme.ornate())
	hud.add_child(top_bar)
	_anchor(top_bar, Control.PRESET_CENTER_TOP, Vector2(820, 78), Vector2(0, 12))
	cp_bar = W.DrawPanel.new(_draw_cp)
	cp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(cp_bar)
	_anchor(cp_bar, Control.PRESET_CENTER_TOP, Vector2(380, 26), Vector2(0, 96))

func _side_totals(side: int) -> Vector3:
	var cur := 0.0
	var mx := 0.0
	var n := 0
	for f in battle.fleets:
		if f.side == side:
			mx += f.max_ships
			if not f.dead:
				cur += f.ships
				n += 1
	return Vector3(cur, mx, n)

func _draw_top(c: Control) -> void:
	var a := _side_totals(0)
	var e := _side_totals(1)
	var w := c.size.x
	# 촉한
	UiDraw.seal(c, Rect2(18, 17, 44, 44), 0)
	UiDraw.text(c, Vector2(74, 34), "촉한 연합함대", "serif_bold", 15, UiTheme.INK)
	var fa := a.x / maxf(1.0, a.y)
	UiDraw.text(c, Vector2(318, 34), "%d척 · %d%%" % [roundi(a.x), roundi(fa * 100.0)], "semibold", 12, UiTheme.INK_2, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	UiDraw.seg_bar(c, Rect2(74, 44, 244, 9), fa, 20, UiTheme.ALLY)
	UiDraw.text(c, Vector2(74, 68), "%d개 함대 건재" % int(a.z), "regular", 11, UiTheme.INK_3)
	# 위
	UiDraw.seal(c, Rect2(w - 62, 17, 44, 44), 1)
	UiDraw.text(c, Vector2(w - 74, 34), "위 원정군", "serif_bold", 15, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	var fe := e.x / maxf(1.0, e.y)
	UiDraw.text(c, Vector2(w - 318, 34), "%d%% · %d척" % [roundi(fe * 100.0), roundi(e.x)], "semibold", 12, UiTheme.INK_2)
	UiDraw.seg_bar(c, Rect2(w - 318, 44, 244, 9), fe, 20, UiTheme.FOE, UiTheme.SLOT, true)
	UiDraw.text(c, Vector2(w - 74, 68), ("별동대 출현 · " if battle.G.reinf else "") + "%d개 함대 확인" % int(e.z), "regular", 11, UiTheme.WARN if battle.G.reinf else UiTheme.INK_3, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	# 가운데: 상태와 시계
	var mx := w * 0.5
	c.draw_line(Vector2(mx - 112, 14), Vector2(mx - 112, 64), Color(UiTheme.GOLD, 0.18))
	c.draw_line(Vector2(mx + 112, 14), Vector2(mx + 112, 64), Color(UiTheme.GOLD, 0.18))
	var st: String = battle.G.state
	var tag: String = pacing.status_tag()
	var tc := UiTheme.WARN if not pacing.quiet else UiTheme.ALLY_HI
	if pacing.slow:
		tc = UiTheme.CP
	if st == "pause":
		tc = UiTheme.INK_2
	elif pacing.next_stop_hint() != "":
		tag += "  ·  " + pacing.next_stop_hint()
	if _tag_flash > 0.0:
		var k := _tag_flash / 0.8
		var tw := UiDraw.text_w(tag, "semibold", 11) + 20.0
		c.draw_rect(Rect2(mx - tw * 0.5, 18, tw, 17), Color(UiTheme.GOLD, 0.22 * k))
		tc = tc.lerp(UiTheme.GOLD_HI, k)
	UiDraw.text(c, Vector2(mx, 30), tag, "semibold", 11, tc, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	var tt := int(battle.G.t)
	UiDraw.text(c, Vector2(mx, 62), "%02d:%02d" % [tt / 60, tt % 60], "serif", 28, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	# 결정 분기 진행(EXPERIENCE-DESIGN §5). 코어에 분기가 없으면 그리지 않는다.
	var dp := src.decision_progress()
	if not dp.is_empty():
		UiDraw.text(c, Vector2(mx + 56, 61), "결정 %d/%d" % [dp.done, dp.total], "semibold", 11, UiTheme.GOLD_HI)

func _draw_cp(c: Control) -> void:
	var w := c.size.x
	var cp: float = battle.G.cp
	var g := c.size.y
	c.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, g), Vector2(0, g)]), PackedColorArray([Color(0.03, 0.05, 0.08, 0.0), Color(0.03, 0.05, 0.08, 0.0), Color(0.03, 0.05, 0.08, 0.0), Color(0.03, 0.05, 0.08, 0.0)]))
	c.draw_rect(Rect2(40, 2, w - 80, g - 4), Color(0.03, 0.05, 0.08, 0.82))
	UiDraw.text(c, Vector2(52, 17), "지휘력", "semibold", 11, UiTheme.INK_3)
	for i in 10:
		var center := Vector2(112 + i * 20, g * 0.5)
		var fill := clampf(cp - i, 0.0, 1.0)
		UiDraw.diamond(c, center, 6.5, Color(0.07, 0.1, 0.16))
		UiDraw.diamond(c, center, 6.5, Color(0.17, 0.23, 0.34), false)
		if fill >= 1.0:
			UiDraw.diamond(c, center, 5.5, UiTheme.CP)
			UiDraw.diamond(c, center + Vector2(-1, -1), 2.0, Color(0.9, 0.94, 1.0, 0.8))
		elif fill > 0.0:
			UiDraw.diamond(c, center, 5.5 * fill, Color(UiTheme.CP, 0.6))
	UiDraw.text(c, Vector2(w - 50, 18), str(int(cp)), "bold", 14, Color("cddaff"), HORIZONTAL_ALIGNMENT_RIGHT, 0.0)

# ------------------------------------------------------------ 우측 상단
func _build_sys() -> void:
	var holder := PanelContainer.new()
	var st := UiTheme.ornate(false)
	st.set_content_margin_all(6)
	holder.add_theme_stylebox_override("panel", st)
	hud.add_child(holder)
	_anchor(holder, Control.PRESET_TOP_RIGHT, Vector2(248, 52), Vector2(-16, 16))
	sys_bar = HBoxContainer.new()
	sys_bar.add_theme_constant_override("separation", 4)
	holder.add_child(sys_bar)
	for i in 2:
		var b := W.IconButton.new("", "×%d" % (i + 1))
		b.tooltip_text = "배속 ×%d" % (i + 1)
		b.pressed.connect(func(): pacing.set_user_speed(i + 1))
		sys_bar.add_child(b)
		speed_btns.append(b)
	# Q52: 조용한 구간에서만 누를 수 있다. 교전·경보가 생기거나 전장을 만지면 멈춘다.
	skip_btn = W.IconButton.new("skip")
	skip_btn.tooltip_text = "다음 교전·경보까지 건너뛰기 (조용한 구간에서만)"
	skip_btn.pressed.connect(func(): pacing.skip())
	sys_bar.add_child(skip_btn)
	var pb := W.IconButton.new("pause")
	pb.tooltip_text = "일시정지 (Space)"
	pb.pressed.connect(open_pause)
	sys_bar.add_child(pb)
	var gb := W.IconButton.new("gear")
	gb.tooltip_text = "설정"
	gb.pressed.connect(func():
		open_pause()
		show_screen("settings_pause"))
	sys_bar.add_child(gb)
	objectives = W.DrawPanel.new(_draw_objectives, UiTheme.ornate())
	hud.add_child(objectives)
	_anchor(objectives, Control.PRESET_TOP_RIGHT, Vector2(272, 112), Vector2(-16, 76))

func _draw_objectives(c: Control) -> void:
	UiDraw.text(c, Vector2(18, 26), "작 전 목 표", "eyebrow", 11, UiTheme.GOLD)
	var pf = battle.flag(0)
	var total := 0
	var down := 0
	for f in battle.fleets:
		if f.side == 1:
			total += 1
			if f.dead:
				down += 1
	var rows := [
		[true, "기함 유비 생존", "유지 중" if pf else "실패", UiTheme.LIFE if pf else UiTheme.FOE],
		[false, "위 원정군 격파  %d / %d" % [down, total], "진행" if down < total else "완료", UiTheme.WARN if down < total else UiTheme.LIFE],
		[false, "별동대 대응", "경보" if battle.G.reinf else "대기", UiTheme.FOE if battle.G.reinf else UiTheme.INK_3],
	]
	var y := 50.0
	for r in rows:
		UiDraw.diamond(c, Vector2(23, y - 4), 4.0, UiTheme.GOLD, r[0])
		if not r[0]:
			UiDraw.diamond(c, Vector2(23, y - 4), 4.0, UiTheme.GOLD, false)
		UiDraw.text(c, Vector2(36, y), r[1], "regular", 12, UiTheme.INK_2)
		UiDraw.text(c, Vector2(c.size.x - 16, y), r[2], "medium", 11, r[3], HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
		y += 22.0

# ------------------------------------------------------------ 교신 기록
func _build_log() -> void:
	log_box = VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 5)
	log_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(log_box)
	log_box.position = Vector2(16, 40)
	log_box.size = Vector2(372, 10)
	var head := W.DrawPanel.new(func(c: Control):
		UiDraw.text(c, Vector2(4, 14), "교 신", "eyebrow", 11, UiTheme.GOLD)
		c.draw_line(Vector2(44, 10), Vector2(c.size.x, 10), Color(UiTheme.GOLD, 0.2)))
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(head)
	head.position = Vector2(16, 14)
	head.size = Vector2(372, 20)

func _clear_log() -> void:
	for it in log_items:
		it.node.queue_free()
	log_items.clear()

func add_log_entry(kind: String, text: String, fleet_id: int) -> void:
	var f = battle.by_id(fleet_id) if fleet_id >= 0 else null
	var stamp := int(battle.G.t)
	var item := W.DrawPanel.new(func(c: Control):
		var col := UiTheme.ALLY
		var bg := Color(0.05, 0.09, 0.11, 0.9)
		if kind == "foe":
			col = UiTheme.FOE
			bg = Color(0.13, 0.05, 0.04, 0.9)
		elif kind == "sys":
			col = UiTheme.WARN
			bg = Color(0.13, 0.1, 0.03, 0.9)
		c.draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(c.size.x, 0), c.size, Vector2(0, c.size.y)]), PackedColorArray([bg, Color(bg, 0.25), Color(bg, 0.25), bg]))
		c.draw_rect(Rect2(0, 0, 2, c.size.y), col)
		if f:
			c.draw_texture_rect(battle._portrait_tex(f.portrait), Rect2(6, 5, 34, 34), false)
			c.draw_rect(Rect2(6, 5, 34, 34), Color(1, 1, 1, 0.12), false, 1.0)
		else:
			c.draw_rect(Rect2(6, 5, 34, 34), Color(col, 0.4), false, 1.0)
			UiDraw.icon(c, "warn", Rect2(11, 10, 24, 24), col, 1.6)
		UiDraw.text(c, Vector2(50, 20), text, "medium", 13, UiTheme.INK)
		UiDraw.text(c, Vector2(50, 36), "%02d:%02d · %s" % [stamp / 60, stamp % 60, f.fname + " 함대" if f else "작전 통보"], "regular", 11, UiTheme.INK_3))
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.custom_minimum_size = Vector2(372, 44)
	log_box.add_child(item)
	log_box.move_child(item, 0)
	item.modulate.a = 0.0
	item.position.x = -20
	var tw := item.create_tween().set_ignore_time_scale()
	tw.tween_property(item, "modulate:a", 1.0, 0.3)
	log_items.append({"node": item, "age": 0.0})
	while log_items.size() > 4:
		var old = log_items.pop_front()
		old.node.queue_free()

func _age_log(dt: float) -> void:
	var keep := []
	for it in log_items:
		it.age += dt
		if it.age > 9.0:
			it.node.modulate.a = maxf(0.0, 1.0 - (it.age - 9.0) / 0.8)
			if it.age > 9.8:
				it.node.queue_free()
				continue
		keep.append(it)
	log_items = keep

# ------------------------------------------------------------ 지휘관 컷인
func _build_cut() -> void:
	cut = W.DrawPanel.new(_draw_cut, UiTheme.ornate(false))
	cut.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(cut)
	_anchor(cut, Control.PRESET_BOTTOM_LEFT, Vector2(456, 112), Vector2(16, -248))
	cut.modulate.a = 0.0

func _draw_cut(c: Control) -> void:
	if cut_data.is_empty():
		return
	var side: int = cut_data.side
	var pi_: int = cut_data.portrait
	var pr := Rect2(3, 3, 150, c.size.y - 6)
	# 초상 상반신을 잘라 넣고 오른쪽을 사선으로 깎는다
	var src_r := Rect2((pi_ % 3) * 512.0 + 60.0, (pi_ / 3) * 512.0 + 20.0, 380.0, 268.0)
	c.draw_texture_rect_region(battle.sheet, pr, src_r)
	c.draw_colored_polygon(PackedVector2Array([Vector2(125, 3), Vector2(154, 3), Vector2(154, c.size.y - 3), Vector2(100, c.size.y - 3)]), UiTheme.BG_BOTTOM)
	c.draw_rect(Rect2(0, 0, 3, c.size.y), UiTheme.side_color(side))
	UiDraw.text(c, Vector2(160, 34), cut_data.name, "serif_bold", 18, UiTheme.INK)
	var nw := UiDraw.text_w(cut_data.name, "serif_bold", 18)
	UiDraw.text(c, Vector2(168 + nw, 34), cut_data.sub, "regular", 11, UiTheme.INK_3)
	var lines: PackedStringArray = _wrap(cut_data.line, 280.0, "serif", 15)
	var y := 60.0
	for i in lines.size():
		var s := lines[i]
		if i == 0:
			s = "“" + s
		if i == lines.size() - 1:
			s += "”"
		UiDraw.text(c, Vector2(160, y), s, "serif", 15, UiTheme.INK)
		y += 23.0

func _wrap(s: String, width: float, font_name: String, size: int) -> PackedStringArray:
	var out := PackedStringArray()
	var cur := ""
	for word in s.split(" "):
		var trial := word if cur == "" else cur + " " + word
		if UiDraw.text_w(trial, font_name, size) > width and cur != "":
			out.append(cur)
			cur = word
		else:
			cur = trial
	if cur != "":
		out.append(cur)
	return out

func _cutin_fleet(f, line: String) -> void:
	if f == null:
		return
	_cutin(f.fname, (f.role + " · " + Commanders.zi(f.fname)).trim_suffix(" · "), f.portrait, f.side, line)

func _cutin(name: String, sub: String, portrait: int, side: int, line: String) -> void:
	if cut_cool > 0.0:
		return
	cut_cool = 6.0
	cut_data = {"name": name, "sub": sub, "portrait": portrait, "side": side, "line": line}
	cut.queue_redraw()
	if cut_tween:
		cut_tween.kill()
	var base_x := cut.offset_left
	cut.position.x = base_x - 60.0
	cut.modulate.a = 0.0
	cut_tween = create_tween().set_ignore_time_scale()
	cut_tween.set_parallel(true)
	cut_tween.tween_property(cut, "modulate:a", 1.0, 0.35)
	cut_tween.tween_property(cut, "position:x", base_x, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	cut_tween.chain().tween_interval(4.2)
	cut_tween.chain().tween_property(cut, "modulate:a", 0.0, 0.5)

func _on_event(kind: String, text: String, fleet_id: int) -> void:
	if kind == "toast":
		show_toast(text)
		sound.play("denied")   # POC 알림 띠는 거의 다 "할 수 없음" 안내다
		return
	add_log_entry(kind, text, fleet_id)
	var f = battle.by_id(fleet_id) if fleet_id >= 0 else null
	if kind == "sys":
		sound.play("alert")
	elif kind == "foe" and f and f.side == 0:
		sound.play("fleet_lost")
	elif text.contains("격파") or text.contains("궤멸"):
		sound.play("fleet_destroyed")
	if kind == "sys":
		_cutin("제갈량", "군사 · 孔明", 2, 0, Commanders.REINF_LINE)
	elif kind == "foe" and f:
		var pf = battle.flag(0)
		if pf:
			_cutin_fleet(pf, Commanders.LOSS_LINES[0] % f.fname)
	elif f and f.side == 0 and text.contains("격파"):
		_cutin_fleet(f, Commanders.KILL_LINES[randi() % Commanders.KILL_LINES.size()])
	elif f and text.contains("돌격"):
		_cutin_fleet(f, Commanders.CHARGE_LINES[randi() % Commanders.CHARGE_LINES.size()])

# ------------------------------------------------------------ 레이더
func _build_radar() -> void:
	radar = RadarScope.new()
	hud.add_child(radar)
	radar.setup(battle)
	_anchor(radar, Control.PRESET_BOTTOM_LEFT, Vector2(208, 208), Vector2(14, -14))

# ------------------------------------------------------------ 하단 정보 패널
func _build_info() -> void:
	info = W.DrawPanel.new(_draw_info, UiTheme.ornate())
	hud.add_child(info)
	_anchor(info, Control.PRESET_CENTER_BOTTOM, Vector2(640, 158), Vector2(0, -14))

func _draw_info(c: Control) -> void:
	var sel: Array = battle.my_sel()
	var single = null
	if sel.size() == 1:
		single = sel[0]
	elif sel.is_empty() and battle.inspect and not battle.inspect.dead:
		single = battle.inspect
	if single:
		_info_single(c, single)
	elif sel.size() > 1:
		_info_multi(c, sel)
	else:
		_info_none(c)

func _frame(c: Control, r: Rect2, tex: Texture2D, faction: String) -> void:
	var cut_k := 14.0
	var outer := PackedVector2Array([r.position + Vector2(cut_k, 0), Vector2(r.end.x, r.position.y), r.end - Vector2(0, cut_k), r.end - Vector2(cut_k, 0), Vector2(r.position.x, r.end.y), r.position + Vector2(0, cut_k)])
	c.draw_colored_polygon(outer, UiTheme.GOLD_LO)
	c.draw_texture_rect(tex, r.grow(-3.0), false)
	# 모서리를 잘라 낸 금장 틀
	c.draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(cut_k + 3, 0), r.position + Vector2(0, cut_k + 3)]), UiTheme.BG_TOP)
	c.draw_colored_polygon(PackedVector2Array([r.end, r.end - Vector2(cut_k + 3, 0), r.end - Vector2(0, cut_k + 3)]), UiTheme.BG_BOTTOM)
	outer.append(outer[0])
	c.draw_polyline(outer, UiTheme.GOLD, 1.6, true)
	var inner := PackedVector2Array()
	for p in outer:
		inner.append(r.get_center() + (p - r.get_center()) * 0.96)
	c.draw_polyline(inner, Color(UiTheme.GOLD_HI, 0.35), 1.0, true)
	c.draw_polygon(PackedVector2Array([Vector2(r.position.x + 3, r.end.y - 34), Vector2(r.end.x - 3, r.end.y - 34), Vector2(r.end.x - 3 - cut_k * 0.8, r.end.y - 3), Vector2(r.position.x + 3, r.end.y - 3)]), PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.02, 0.03, 0.05, 0.92), Color(0.02, 0.03, 0.05, 0.92)]))
	UiDraw.faction_seal(c, Rect2(r.end.x - 31, r.position.y + 8, 22, 22), faction)

func _info_single(c: Control, f) -> void:
	var foe: bool = f.side == 1
	var pr := Rect2(13, 13, 132, 132)
	_frame(c, pr, battle._portrait_tex(f.portrait), src.faction(f.id))
	UiDraw.text(c, pr.position + Vector2(10, pr.size.y - 12), f.role.get_slice(" · ", 0), "medium", 11, UiTheme.GOLD_HI)
	var x := 162.0
	UiDraw.text(c, Vector2(x, 42), f.fname, "serif_bold", 26, UiTheme.INK)
	var nw := UiDraw.text_w(f.fname, "serif_bold", 26)
	UiDraw.text(c, Vector2(x + nw + 10, 40), Commanders.zi(f.fname), "serif", 14, UiTheme.GOLD_HI)
	var meta: String = "%s · 숙련 Lv.%d" % [battle.FORM_NAMES[f.form_id % battle.FORM_NAMES.size()], f.lv]
	if f.defense:
		meta += " · 방어진형"
	elif f.charge_t > 0.0:
		meta += " · 돌격"
	UiDraw.text(c, Vector2(c.size.x - 18, 40), (("적 · " if foe else "") + meta), "regular", 12, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	# 함선 막대: 남은 수 + 방금 잃은 몫(빗금)
	var frac: float = f.ships / f.max_ships
	var bar := Rect2(x + 44, 60, c.size.x - x - 44 - 104, 9)
	UiDraw.text(c, Vector2(x, 69), "함선", "regular", 12, UiTheme.INK_3)
	c.draw_rect(bar, Color(0.04, 0.06, 0.09))
	c.draw_rect(bar, Color(0.14, 0.19, 0.26), false, 1.0)
	c.draw_rect(Rect2(bar.position + Vector2(1, 1), Vector2((bar.size.x - 2) * frac, bar.size.y - 2)), UiTheme.FOE if foe else UiTheme.LIFE)
	var shown_frac: float = f.shown / f.max_ships
	if shown_frac > frac:
		c.draw_rect(Rect2(bar.position + Vector2(1 + (bar.size.x - 2) * frac, 1), Vector2((bar.size.x - 2) * (shown_frac - frac), bar.size.y - 2)), Color(UiTheme.FOE, 0.5))
	for i in range(1, 10):
		var xx := bar.position.x + bar.size.x * i / 10.0
		c.draw_line(Vector2(xx, bar.position.y + 1), Vector2(xx, bar.end.y - 1), Color(0, 0, 0, 0.55))
	UiDraw.text(c, Vector2(c.size.x - 18, 70), "%d" % ceili(f.ships), "bold", 15, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	UiDraw.text(c, Vector2(c.size.x - 52, 70), "/ %d척" % int(f.max_ships), "regular", 11, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	# 함종 구성(표시 함선 기준)
	var comp: Array = renderer.composition(f.id)
	var cx := x
	for it in comp:
		var label: String = it[0]
		UiDraw.text(c, Vector2(cx, 96), label, "regular", 11, UiTheme.INK_3)
		var lw := UiDraw.text_w(label, "regular", 11)
		UiDraw.text(c, Vector2(cx + lw + 4, 96), str(it[1]), "semibold", 12, UiTheme.INK_2)
		cx += lw + UiDraw.text_w(str(it[1]), "semibold", 12) + 16
	# 상태 칩
	var chips: Array = []
	if f.is_flag:
		chips.append(["기함", UiTheme.GOLD_HI])
	if not foe:
		chips.append(["지휘 범위 안" if f.in_cmd else "지휘 범위 밖 · 화력 %s" % RuleText._pct(src.rules().out_of_cmd_fire).replace("-", "−"), UiTheme.ALLY_HI if f.in_cmd else UiTheme.WARN])
		chips.append(["미사일 준비" if f.missile_cd <= 0.0 else "미사일 %d초" % ceili(f.missile_cd), UiTheme.CP if f.missile_cd <= 0.0 else UiTheme.INK_2])
		chips.append(["함재기 준비" if f.fighter_cd <= 0.0 else "함재기 %d초" % ceili(f.fighter_cd), UiTheme.CP if f.fighter_cd <= 0.0 else UiTheme.INK_2])
	if f.charge_t > 0.0:
		chips.append(["돌격 %d초" % ceili(f.charge_t), UiTheme.GOLD_HI])
	if f.fire_t and not f.fire_t.dead:
		var dir := src.attack_dir(f.id, f.fire_t.id)
		chips.append(["%s 교전 중%s" % [f.fire_t.fname, RuleText.flank_chip(src.rules(), dir)], UiTheme.GOLD_HI if dir != "front" else UiTheme.INK_2])
	var chx := x
	var chy := 112.0
	for ch in chips:
		var tw := UiDraw.text_w(ch[0], "medium", 11) + 16.0
		if chx + tw > c.size.x - 14:
			chx = x
			chy += 24.0
		var r := Rect2(chx, chy, tw, 20)
		c.draw_rect(r, Color(0.05, 0.08, 0.12, 0.95))
		c.draw_rect(r, Color(ch[1], 0.45), false, 1.0)
		UiDraw.text(c, r.position + Vector2(8, 14), ch[0], "medium", 11, ch[1])
		chx += tw + 6.0

func _info_multi(c: Control, sel: Array) -> void:
	var tot := 0.0
	var mx := 0.0
	for f in sel:
		tot += f.ships
		mx += f.max_ships
	UiDraw.text(c, Vector2(20, 34), "선 택 함 대", "eyebrow", 11, UiTheme.GOLD)
	UiDraw.text(c, Vector2(20, 64), "%d개 함대" % sel.size(), "serif_bold", 24, UiTheme.INK)
	UiDraw.text(c, Vector2(c.size.x - 18, 62), "%d / %d척" % [ceili(tot), int(mx)], "semibold", 14, UiTheme.INK_2, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	var x := 20.0
	for f in sel.slice(0, 8):
		var r := Rect2(x, 78, 66, 66)
		c.draw_texture_rect(battle._portrait_tex(f.portrait), r, false)
		c.draw_rect(r, UiTheme.GOLD_LO if not f.is_flag else UiTheme.GOLD_HI, false, 1.2)
		c.draw_rect(Rect2(r.position.x, r.end.y - 18, r.size.x, 18), Color(0.02, 0.03, 0.05, 0.85))
		UiDraw.text(c, Vector2(r.position.x + 4, r.end.y - 5), f.fname, "serif_bold", 11, UiTheme.INK)
		c.draw_rect(Rect2(r.position.x, r.end.y + 2, r.size.x * f.ships / f.max_ships, 3), UiTheme.LIFE)
		x += 74.0

func _info_none(c: Control) -> void:
	var a := _side_totals(0)
	var e := _side_totals(1)
	UiDraw.text(c, Vector2(c.size.x * 0.5, 50), "함대를 선택하십시오", "serif_bold", 20, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	UiDraw.text(c, Vector2(c.size.x * 0.5, 78), "함대 클릭 · 드래그로 범위 선택 · 그룹 I–IV · A 전 함대", "regular", 12, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	UiDraw.text(c, Vector2(c.size.x * 0.5 - 20, 116), "아군 %d개 함대 · %d척" % [int(a.z), roundi(a.x)], "semibold", 13, UiTheme.ALLY_HI, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	UiDraw.text(c, Vector2(c.size.x * 0.5 + 20, 116), "적 %d개 함대 · %d척 확인" % [int(e.z), roundi(e.x)], "semibold", 13, UiTheme.FOE_HI)
	UiDraw.diamond(c, Vector2(c.size.x * 0.5, 111), 3.0, UiTheme.GOLD)

# ------------------------------------------------------------ 명령 패널
func _build_commands() -> void:
	cmd_panel = W.DrawPanel.new(Callable(), UiTheme.ornate())
	hud.add_child(cmd_panel)
	_anchor(cmd_panel, Control.PRESET_BOTTOM_RIGHT, Vector2(364, 238), Vector2(-16, -14))
	var vb := VBoxContainer.new()
	vb.position = Vector2(8, 6)
	vb.size = Vector2(348, 226)
	vb.add_theme_constant_override("separation", 8)
	cmd_panel.add_child(vb)
	var tabs := HBoxContainer.new()
	vb.add_child(tabs)
	for i in TABS.size():
		var tb := W.TabButton.new(TABS[i][0])
		tb.pressed.connect(_set_tab.bind(i))
		tabs.add_child(tb)
		cmd_tabs.append(tb)
	var sep := ColorRect.new()
	sep.color = Color(UiTheme.GOLD, 0.2)
	sep.custom_minimum_size = Vector2(0, 1)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(sep)
	cmd_grid = GridContainer.new()
	cmd_grid.columns = 4
	cmd_grid.add_theme_constant_override("h_separation", 7)
	cmd_grid.add_theme_constant_override("v_separation", 7)
	var mc := MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 4)
	mc.add_theme_constant_override("margin_right", 4)
	mc.add_child(cmd_grid)
	vb.add_child(mc)
	groups_row = HBoxContainer.new()
	groups_row.add_theme_constant_override("separation", 6)
	hud.add_child(groups_row)
	_anchor(groups_row, Control.PRESET_BOTTOM_RIGHT, Vector2(346, 44), Vector2(-16, -262))
	# 전대 띠(U4): 그룹 탭 바로 위. 탭 선택, 길게 눌러 추가, 끌어서 명령
	strip = Strip.new()
	hud.add_child(strip)
	_anchor(strip, Control.PRESET_BOTTOM_RIGHT, Vector2(346, 60), Vector2(-16, -312))
	strip.setup(self)
	for i in 4:
		var g := W.GroupButton.new(i + 1, self)
		g.button_down.connect(battle._group_down.bind(i + 1))
		g.button_up.connect(battle._group_up.bind(i + 1))
		groups_row.add_child(g)
	_set_tab(0)

func _set_tab(i: int) -> void:
	tab_index = i
	for k in cmd_tabs.size():
		cmd_tabs[k].on = k == i
		cmd_tabs[k].queue_redraw()
	for b in cmd_buttons:
		b.queue_free()
	cmd_buttons.clear()
	var rules := src.rules()
	for id in TABS[i][1]:
		if not src.has_command(id):
			continue
		var spec: Dictionary = CMD_INFO[id].duplicate()
		spec.merge(RuleText.cmd(rules, id), true)
		spec["id"] = id
		for c in battle.CMDS:
			if c.id == id:
				spec["key"] = c.key
				spec["cost"] = c.cost
		var b := W.CmdButton.new(spec, self)
		if spec.get("confirm", false):
			b.set_meta("hold_confirm", true)
			b.button_down.connect(_confirm_start.bind(b))
			b.button_up.connect(_confirm_end.bind(b))
		else:
			b.pressed.connect(func(): battle.do_cmd(id))
		cmd_grid.add_child(b)
		cmd_buttons.append(b)
		if sound:
			_hook_buttons(b)
		if hold_tip:
			hold_tip.register(b)

# 길게 눌러 확정: 누르는 동안 버튼에 고리가 차고, 다 차면 명령을 실행한다. 일찍 떼면 취소.
# ------------------------------------------------------------ 효과음 훅
func _build_sound() -> void:
	sound = UiSound.new()
	sound.name = "UiSound"
	add_child(sound)
	_hook_buttons(self)
	renderer.fx_event.connect(func(k: String): sound.play(k))
	pacing.changed.connect(func():
		if src.state() == "pause":
			sound.play("pause"))
	decision_card.visibility_changed.connect(func():
		if decision_card.visible:
			sound.play("decision"))

# 모든 버튼: 누르면 "button"(탭은 "tab"). 명령 버튼은 길게 눌러 확정할 때 "confirm_heavy"를 따로 낸다.
func _hook_buttons(n: Node) -> void:
	if n is BaseButton and not n.has_meta("sound_hooked"):
		n.set_meta("sound_hooked", true)
		var ev := "tab" if n is W.TabButton else "button"
		(n as BaseButton).button_down.connect(func(): sound.play(ev))
	for c in n.get_children():
		_hook_buttons(c)

func _confirm_start(b: Control) -> void:
	_confirm_btn = b
	_confirm_t = 0.0
	_confirm_fired = false

func _confirm_end(b: Control) -> void:
	if _confirm_btn != b:
		return
	if not _confirm_fired:
		show_toast("%s: 길게 눌러 확정합니다" % b.cmd.label)
	b.hold_k = 0.0
	b.queue_redraw()
	_confirm_btn = null

func _confirm_tick(delta: float) -> void:
	if _confirm_btn == null or _confirm_fired:
		return
	if not is_instance_valid(_confirm_btn) or not _confirm_btn.is_visible_in_tree():
		_confirm_btn = null
		return
	_confirm_t += delta
	_confirm_btn.hold_k = clampf(_confirm_t / CONFIRM_HOLD, 0.0, 1.0)
	_confirm_btn.queue_redraw()
	if _confirm_t >= CONFIRM_HOLD:
		_confirm_fired = true
		_confirm_btn.hold_k = 0.0
		hold_tip.hide_tip()
		sound.play("confirm_heavy")
		battle.do_cmd(_confirm_btn.cmd.id)

func _refresh_cmds() -> void:
	var s: Array = battle.my_sel()
	for b in cmd_buttons:
		var id: String = b.cmd.id
		var cost: int = b.cmd.cost
		var blocked: bool = (id != "all" and s.is_empty()) or (cost > 0 and battle.G.cp < cost)
		var cool := 0.0
		var cd_max := 0.0
		if not s.is_empty() and (id == "missile" or id == "fighter"):
			var m := 999.0
			for f in s:
				m = minf(m, f.missile_cd if id == "missile" else f.fighter_cd)
			cd_max = 18.0 if id == "missile" else 26.0
			if m > 0.0:
				cool = m / cd_max
				b.cool_text = str(ceili(m))
		b.cool = cool
		b.blocked = blocked
		b.queue_redraw()

func make_cmd_tooltip(cmd: Dictionary) -> Control:
	var p := PanelContainer.new()
	var st := UiTheme.ornate(false)
	st.set_content_margin_all(14)
	p.add_theme_stylebox_override("panel", st)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	p.add_child(vb)
	var hb := HBoxContainer.new()
	vb.add_child(hb)
	var title := UiTheme.label(cmd.label, "Heading", 16, UiTheme.GOLD_HI)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)
	hb.add_child(UiTheme.label("[%s]" % cmd.key, "Muted"))
	var d := UiTheme.label(cmd.desc, "Body", 13)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(270, 0)
	vb.add_child(d)
	for e in cmd.get("fx", []):
		var row := HBoxContainer.new()
		var k := UiTheme.label(e[0], "Body", 12)
		k.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(k)
		row.add_child(UiTheme.label(e[1], "Strong", 12, UiTheme.LIFE if e[2] else UiTheme.FOE))
		vb.add_child(row)
	var foot := []
	if cmd.has("foot"):
		foot.append(cmd.foot)
	if cmd.get("cost", 0) > 0:
		foot.append("지휘력 %d 소모" % cmd.cost)
	if not foot.is_empty():
		var sep := ColorRect.new()
		sep.color = Color(UiTheme.GOLD, 0.2)
		sep.custom_minimum_size = Vector2(0, 1)
		vb.add_child(sep)
		vb.add_child(UiTheme.label(" · ".join(foot), "Muted", 11, Color("cddaff")))
	return p

# ------------------------------------------------------------ 알림 띠
func _build_toast() -> void:
	toast = W.DrawPanel.new(func(c: Control):
		if toast_text == "":
			return
		var w := c.size.x
		var h := c.size.y
		var mid := Color(0.16, 0.1, 0.02, 0.92)
		c.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w * 0.5, 0), Vector2(w, 0), Vector2(w, h), Vector2(w * 0.5, h), Vector2(0, h)]), PackedColorArray([Color(mid, 0), mid, Color(mid, 0), Color(mid, 0), mid, Color(mid, 0)]))
		c.draw_line(Vector2(w * 0.15, 0), Vector2(w * 0.85, 0), Color(UiTheme.WARN, 0.5))
		c.draw_line(Vector2(w * 0.15, h), Vector2(w * 0.85, h), Color(UiTheme.WARN, 0.5))
		UiDraw.icon(c, "warn", Rect2(w * 0.5 - UiDraw.text_w(toast_text, "semibold", 15) * 0.5 - 30, h * 0.5 - 10, 20, 20), UiTheme.WARN, 1.6)
		UiDraw.text(c, Vector2(0, h * 0.5 + 5.5), toast_text, "semibold", 15, UiTheme.WARN, HORIZONTAL_ALIGNMENT_CENTER, w))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(toast)
	_anchor(toast, Control.PRESET_CENTER_TOP, Vector2(640, 36), Vector2(0, 130))
	toast.modulate.a = 0.0

func apply_glow() -> void:
	for c in battle.get_children():
		if c is WorldEnvironment:
			(c as WorldEnvironment).environment.glow_enabled = GameSettings.glow

func show_toast(text: String) -> void:
	toast_text = text
	toast.queue_redraw()
	if toast_tween:
		toast_tween.kill()
	toast.modulate.a = 1.0
	toast_tween = create_tween().set_ignore_time_scale()
	toast_tween.tween_interval(2.0)
	toast_tween.tween_property(toast, "modulate:a", 0.0, 0.4)
