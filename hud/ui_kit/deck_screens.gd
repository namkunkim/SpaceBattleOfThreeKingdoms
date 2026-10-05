extends RefCounted

# 전투 밖 화면: 타이틀(전투 허브), 브리핑, 일시정지, 설정, 결과.
# 타이틀과 브리핑 뒤에는 실제 3D 전장이 그대로 보인다(POC "brief" 상태의 카메라 흔들림).

const W := preload("res://hud/ui_kit/deck_widgets.gd")

static func build_all(deck: Control) -> Dictionary:
	var out := {
		"title": TitleScreen.new(deck),
		"brief": BriefScreen.new(deck),
		"pause": PauseScreen.new(deck),
		"settings": SettingsScreen.new(deck, "title"),
		"settings_pause": SettingsScreen.new(deck, "pause"),
		"result": ResultScreen.new(deck),
		"roster": preload("res://hud/ui_kit/roster_screen.gd").new(deck),
	}
	for k in out:
		deck.add_child(out[k])
		out[k].visible = false
	return out

# ------------------------------------------------------------ 타이틀
class TitleScreen extends Control:
	var deck: Control
	var t := 0.0
	func _init(d: Control) -> void:
		deck = d
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var col := VBoxContainer.new()
		col.position = Vector2(118, 470)
		col.add_theme_constant_override("separation", 4)
		add_child(col)
		var go := ScreenKit.menu_button("출격 준비", true)
		go.custom_minimum_size = Vector2(280, 54)
		go.pressed.connect(func(): deck.show_screen("brief"))
		col.add_child(go)
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(0, 10)
		col.add_child(spacer)
		for spec in [["설정", func(): deck.show_screen("settings")], ["종료", func(): deck.get_tree().quit()]]:
			var b := ScreenKit.menu_button(spec[0])
			b.custom_minimum_size = Vector2(280, 52)
			b.pressed.connect(spec[1])
			col.add_child(b)
		var card := W.DrawPanel.new(_draw_card, UiTheme.ornate())
		add_child(card)
		card.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		card.offset_left = -500
		card.offset_top = -268
		card.offset_right = -56
		card.offset_bottom = -56
	func _process(delta: float) -> void:
		delta = UiDraw.real_dt(delta)
		t += delta
		queue_redraw()
	func _draw() -> void:
		var vs := size
		# 왼쪽을 어둡게 눌러 글자를 읽히게 하고 오른쪽 전장은 살린다
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(vs.x * 0.62, 0), Vector2(vs.x * 0.62, vs.y), Vector2(0, vs.y)]), PackedColorArray([Color(0.01, 0.015, 0.03, 0.92), Color(0.01, 0.015, 0.03, 0.0), Color(0.01, 0.015, 0.03, 0.0), Color(0.01, 0.015, 0.03, 0.92)]))
		draw_rect(Rect2(0, vs.y - 120, vs.x, 120), Color(0.0, 0.0, 0.0, 0.35))
		var x := 118.0
		UiDraw.text(self, Vector2(x, 196), "星 漢 志", "serif_wide", 18, UiTheme.GOLD)
		UiDraw.text(self, Vector2(x - 4, 300), "성한지", "serif_bold", 96, UiTheme.INK, HORIZONTAL_ALIGNMENT_LEFT, -1, 0)
		UiDraw.text(self, Vector2(x, 348), "적벽 회랑 전투", "serif", 26, UiTheme.GOLD_HI)
		ScreenKit.rule(self, Vector2(x, 374), Vector2(x + 380, 374))
		UiDraw.text(self, Vector2(x, 410), "성간 삼국의 함대가 적벽 회랑에서 맞선다.", "regular", 15, UiTheme.INK_2)
		UiDraw.text(self, Vector2(x, 434), "기함을 지키며 위 원정군을 회랑에서 몰아내라.", "regular", 15, UiTheme.INK_2)
		UiDraw.text(self, Vector2(x, vs.y - 30), "개발 빌드 · 전투 규칙 POC · 표현 계층 ui-fleet-visuals", "regular", 11, UiTheme.INK_4)
		var a := 0.5 + 0.5 * sin(t * 1.4)
		UiDraw.text(self, Vector2(vs.x - 56, vs.y - 290), "적 함대 접근 중", "medium", 12, Color(UiTheme.FOE_HI, 0.5 + a * 0.5), HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	func _draw_card(c: Control) -> void:
		UiDraw.text(c, Vector2(24, 34), "시 나 리 오", "eyebrow", 11, UiTheme.GOLD)
		UiDraw.text(c, Vector2(24, 70), "적벽 회랑 전투", "serif_bold", 24, UiTheme.INK)
		UiDraw.seal(c, Rect2(c.size.x - 108, 24, 38, 38), 0)
		UiDraw.text(c, Vector2(c.size.x - 61, 49), "對", "serif", 13, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
		UiDraw.seal(c, Rect2(c.size.x - 52, 24, 38, 38), 1)
		var rows := [["편성", "촉한 연합 6개 함대  대  위 원정군 7개 함대"], ["승리", "위 원정군 전멸 (증원 포함)"], ["패배", "기함 유비 격침"], ["지휘", "직접 지휘 · 실시간 · 일시정지 가능"]]
		var y := 108.0
		for r in rows:
			UiDraw.text(c, Vector2(24, y), r[0], "semibold", 12, UiTheme.GOLD)
			UiDraw.text(c, Vector2(70, y), r[1], "regular", 13, UiTheme.INK_2)
			y += 26.0
	func on_show() -> void:
		pass

# ------------------------------------------------------------ 브리핑
class BriefScreen extends Control:
	var deck: Control
	var panel: Control
	func _init(d: Control) -> void:
		deck = d
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		panel = ScreenKit.centered(self, Vector2(1180, 680), UiTheme.ornate())
		panel.painter = _draw_panel
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		panel.add_child(hb)
		hb.position = Vector2(1180 - 24 - 580, 680 - 24 - 54)
		hb.size = Vector2(580, 54)
		hb.alignment = BoxContainer.ALIGNMENT_END
		var roster := Button.new()
		roster.text = "정본 편성"
		roster.custom_minimum_size = Vector2(160, 54)
		roster.focus_mode = Control.FOCUS_NONE
		roster.pressed.connect(func(): deck.screens["roster"].open_roster(false))
		hb.add_child(roster)
		var back := Button.new()
		back.text = "뒤로"
		back.custom_minimum_size = Vector2(120, 54)
		back.focus_mode = Control.FOCUS_NONE
		back.pressed.connect(func(): deck.show_screen("title"))
		hb.add_child(back)
		var go := ScreenKit.menu_button("출  격", true)
		go.custom_minimum_size = Vector2(220, 54)
		go.pressed.connect(func(): deck.begin_battle())
		hb.add_child(go)
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, 0.78))
	func _draw_panel(c: Control) -> void:
		var b: Node = deck.battle
		UiDraw.text(c, Vector2(36, 48), "촉 한 연 합 함 대 · 작 전 브 리 핑", "eyebrow", 11, UiTheme.GOLD)
		UiDraw.text(c, Vector2(36, 92), "적벽 회랑 전투", "serif_bold", 34, UiTheme.INK)
		UiDraw.seal(c, Rect2(c.size.x - 132, 38, 44, 44), 0)
		UiDraw.text(c, Vector2(c.size.x - 78, 67), "對", "serif", 14, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
		UiDraw.seal(c, Rect2(c.size.x - 68, 38, 44, 44), 1)
		c.draw_line(Vector2(36, 114), Vector2(c.size.x - 36, 114), Color(UiTheme.GOLD, 0.22))
		# 왼쪽: 작전 개요와 규칙
		var x := 36.0
		var y := 150.0
		UiDraw.text(c, Vector2(x, y), "작 전 개 요", "eyebrow", 11, UiTheme.GOLD)
		var body := ["사령관 유비 제독. 위 원정군 7개 분함대가 회랑을 건너오고 있습니다.", "교전 중 적 증원이 측면에서 나타날 수 있습니다.", "기함을 지키면서 적 함대를 모두 격파하십시오."]
		y += 30.0
		for line in body:
			UiDraw.text(c, Vector2(x, y), line, "regular", 14, UiTheme.INK_2)
			y += 24.0
		y += 18.0
		UiDraw.text(c, Vector2(x, y), "교 전 규 칙", "eyebrow", 11, UiTheme.GOLD)
		y += 14.0
		var rv: Dictionary = deck.src.rules()
		var rules := [["target", RuleText.flank_rule(rv)], ["flag", RuleText.cmd_range_rule(rv)], ["charge", RuleText.cost_rule(rv)]]
		if RuleText.defense_rule(rv) != "":
			rules.append(["def", RuleText.defense_rule(rv)])
		for r in rules:
			y += 34.0
			c.draw_rect(Rect2(x, y - 21, 28, 28), Color(0.05, 0.08, 0.12))
			c.draw_rect(Rect2(x, y - 21, 28, 28), Color(UiTheme.GOLD, 0.35), false, 1.0)
			UiDraw.icon(c, r[0], Rect2(x + 4, y - 17, 20, 20), UiTheme.GOLD_HI, 1.4)
			UiDraw.text(c, Vector2(x + 40, y - 2), r[1], "regular", 13, UiTheme.INK_2)
		y += 44.0
		UiDraw.text(c, Vector2(x, y), "조 작", "eyebrow", 11, UiTheme.GOLD)
		var ctl := ["마우스  클릭 선택 · 드래그 범위 선택 · 빈 곳 클릭 이동 · 적 클릭 공격", "            우클릭 드래그·방향키 화면 이동 · 휠 확대 · Space 일시정지", "터치      탭 선택 · 함대에서 끌어 놓기 = 이동/공격 · 되돌리면 취소", "            빈 곳 끌기 화면 이동 · 두 손가락 확대 · 길게 눌러 추가 선택"]
		for line in ctl:
			y += 24.0
			UiDraw.text(c, Vector2(x, y), line, "regular", 13, UiTheme.INK_3)
		# 오른쪽: 편성
		_roster(c, Vector2(600, 150), "아 군 편 성", b.ALLY_DEF, 0)
		_roster(c, Vector2(890, 150), "적 정 보", b.FOE_DEF, 1)
		UiDraw.icon(c, "warn", Rect2(890, 576, 18, 18), UiTheme.WARN, 1.5)
		UiDraw.text(c, Vector2(914, 590), "측면 증원 가능성", "medium", 12, UiTheme.WARN)
	func _roster(c: Control, o: Vector2, title: String, defs: Array, side: int) -> void:
		var b: Node = deck.battle
		UiDraw.text(c, o, title, "eyebrow", 11, UiTheme.GOLD)
		var y := o.y + 16.0
		var total := 0
		for d in defs:
			total += int(d.ships)
		UiDraw.text(c, Vector2(o.x + 260, o.y), "%d척%s" % [total, "" if side == 0 else " 추정"], "medium", 11, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
		for d in defs:
			var r := Rect2(o.x, y, 260, 50)
			c.draw_rect(r, Color(0.05, 0.08, 0.12, 0.85) if side == 0 else Color(0.11, 0.05, 0.04, 0.85))
			c.draw_rect(Rect2(r.position, Vector2(2, r.size.y)), UiTheme.side_color(side))
			c.draw_texture_rect(b._portrait_tex(d.p), Rect2(r.position + Vector2(7, 5), Vector2(40, 40)), false)
			UiDraw.text(c, r.position + Vector2(56, 22), d.name, "serif_bold", 15, UiTheme.INK)
			var nw := UiDraw.text_w(d.name, "serif_bold", 15)
			UiDraw.text(c, r.position + Vector2(62 + nw, 22), Commanders.zi(d.name), "serif", 11, UiTheme.GOLD_HI)
			UiDraw.text(c, r.position + Vector2(56, 41), d.role, "regular", 11, UiTheme.INK_3)
			UiDraw.text(c, Vector2(r.end.x - 10, r.position.y + 22), ("%d척" if side == 0 else "약 %d척") % int(d.ships), "semibold", 12, UiTheme.INK_2, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
			if d.get("flag", false):
				UiDraw.text(c, Vector2(r.end.x - 10, r.position.y + 41), "기함", "medium", 11, UiTheme.GOLD_HI, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
			y += 56.0
	func on_show() -> void:
		panel.queue_redraw()

# ------------------------------------------------------------ 일시정지
class PauseScreen extends Control:
	var deck: Control
	func _init(d: Control) -> void:
		deck = d
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var p := ScreenKit.centered(self, Vector2(860, 470), UiTheme.ornate())
		p.painter = _draw_panel
		var col := VBoxContainer.new()
		col.position = Vector2(36, 150)
		col.add_theme_constant_override("separation", 2)
		p.add_child(col)
		var specs := [["계속", func(): deck.resume()], ["설정", func(): deck.show_screen("settings_pause")], ["처음부터", func(): deck.restart()], ["타이틀로", func(): deck.to_title()], ["종료", func(): deck.get_tree().quit()]]
		for i in specs.size():
			var b := ScreenKit.menu_button(specs[i][0], i == 0)
			b.custom_minimum_size = Vector2(300, 56 if i == 0 else 52)
			b.pressed.connect(specs[i][1])
			col.add_child(b)
			if i == 0:
				var sp := Control.new()
				sp.custom_minimum_size = Vector2(0, 8)
				col.add_child(sp)
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, 0.72))
	func _draw_panel(c: Control) -> void:
		var b: Node = deck.battle
		UiDraw.text(c, Vector2(36, 50), "S Y S T E M", "eyebrow", 11, UiTheme.GOLD)
		UiDraw.text(c, Vector2(36, 98), "작전 일시정지", "serif_bold", 32, UiTheme.INK)
		var tt := int(b.G.t)
		UiDraw.text(c, Vector2(c.size.x - 36, 98), "교전 %02d:%02d" % [tt / 60, tt % 60], "serif", 18, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
		c.draw_line(Vector2(36, 122), Vector2(c.size.x - 36, 122), Color(UiTheme.GOLD, 0.22))
		var x := 420.0
		c.draw_line(Vector2(x - 30, 146), Vector2(x - 30, c.size.y - 36), Color(UiTheme.GOLD, 0.15))
		UiDraw.text(c, Vector2(x, 160), "단 축 키", "eyebrow", 11, UiTheme.GOLD)
		var keys := [["S", "정지"], ["D", "방어진형"], ["C", "돌격"], ["R", "기함 집결"], ["G", "후퇴"], ["M", "미사일"], ["F", "함재기"], ["A", "전 함대 선택"], ["1–9", "편성 선택 · Ctrl+숫자 저장"], ["Space", "일시정지"]]
		if not deck.src.has_command("def"):
			keys = keys.filter(func(k): return k[0] != "D")
		var y := 192.0
		for i in keys.size():
			var cx := x + (i % 2) * 210.0
			var cy := y + (i / 2) * 32.0
			var kw := maxf(28.0, UiDraw.text_w(keys[i][0], "semibold", 12) + 14.0)
			c.draw_rect(Rect2(cx, cy - 17, kw, 24), Color(0.06, 0.09, 0.14))
			c.draw_rect(Rect2(cx, cy - 17, kw, 24), Color(0.25, 0.32, 0.43), false, 1.0)
			UiDraw.text(c, Vector2(cx, cy), keys[i][0], "semibold", 12, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, kw)
			UiDraw.text(c, Vector2(cx + kw + 10, cy), keys[i][1], "regular", 13, UiTheme.INK_2)
		# Q53: 창을 벗어나 자동으로 멈췄을 때 안내
		if deck.guard.auto_paused:
			UiDraw.diamond(c, Vector2(x + 5, c.size.y - 49), 4.0, UiTheme.GOLD)
			UiDraw.text(c, Vector2(x + 18, c.size.y - 44), "자리를 비워 자동으로 멈췄습니다. 전황은 그대로입니다.", "regular", 13, UiTheme.INK_2)
	func on_show() -> void:
		queue_redraw()

# ------------------------------------------------------------ 설정
class SettingsScreen extends Control:
	const PAGES := ["화면", "진행", "소리"]
	var deck: Control
	var back_to := "title"
	var scale_btns: Array = []
	var full_chk: CheckButton
	var glow_chk: CheckButton
	var fast_chk: CheckButton
	var slow_btns: Array = []
	var vib_chk: CheckButton
	var pending_slow := 0
	var density_btns: Array = []
	var vol_sliders := {}
	var pending_density := 1
	var pending_scale := 1.0
	var tabs: Array = []
	var pages: Array = []
	func _init(d: Control, back: String) -> void:
		deck = d
		back_to = back
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var p := ScreenKit.centered(self, Vector2(600, 580), UiTheme.ornate())
		p.painter = func(c: Control):
			UiDraw.text(c, Vector2(36, 50), "설 정", "eyebrow", 11, UiTheme.GOLD)
			UiDraw.text(c, Vector2(36, 94), "설정", "serif_bold", 28, UiTheme.INK)
			c.draw_line(Vector2(36, 166), Vector2(c.size.x - 36, 166), Color(UiTheme.GOLD, 0.22))
		var tb := HBoxContainer.new()
		tb.position = Vector2(36, 112)
		tb.size = Vector2(528, 52)
		p.add_child(tb)
		for i in PAGES.size():
			var t := DeckWidgets.TabButton.new(PAGES[i])
			t.custom_minimum_size = Vector2(0, 52)
			t.pressed.connect(_show_page.bind(i))
			tb.add_child(t)
			tabs.append(t)
		for i in PAGES.size():
			var vb := VBoxContainer.new()
			vb.position = Vector2(36, 186)
			vb.size = Vector2(528, 220)
			vb.add_theme_constant_override("separation", 14)
			p.add_child(vb)
			pages.append(vb)
		# 화면
		var row := _row(pages[0], "UI 크기")
		for sc in GameSettings.UI_SCALES:
			var b := _choice("%d%%" % roundi(sc * 100.0), row)
			b.pressed.connect(func():
				pending_scale = sc
				_sync())
			scale_btns.append([b, sc])
		# 표시 함선 밀도(리뷰 C-1·C-4): 화면 숫자는 언제나 실제 척 수, 보이는 배는 고정 배율
		var drow := _row(pages[0], "함선 표시")
		for i in 3:
			var b := _choice(["낮음", "보통", "높음"][i], drow)
			b.pressed.connect(func():
				pending_density = i
				_sync())
			density_btns.append(b)
		full_chk = _check(pages[0], "전체 화면")
		glow_chk = _check(pages[0], "빛 번짐 효과 (광선·폭발 발광)")
		# 진행
		fast_chk = _check(pages[1], "조용한 구간 자동 ×4 (교전이 시작되면 원래 배속)")
		var srow := _row(pages[1], "선택 감속 ×0.2")
		for i in 3:
			var b := _choice(["선택하면", "조작 중에만", "끔"][i], srow)
			b.custom_minimum_size.x = 110
			b.pressed.connect(func():
				pending_slow = i
				_sync())
			slow_btns.append(b)
		pages[1].add_child(UiTheme.label("선택하면: 명령하거나 5초 동안 입력이 없으면 풀림 · 조작 중에만: 누르고 있거나 끄는 동안", "Muted"))
		vib_chk = _check(pages[1], "진동 (경보·결정·아군 손실·길게 누르기)")
		# 소리
		for it in [["master", "전체 음량"], ["sfx", "전투 효과음"], ["ui", "UI·알림음"]]:
			var r := _row(pages[2], it[1])
			var sl := HSlider.new()
			sl.min_value = 0.0
			sl.max_value = 1.0
			sl.step = 0.05
			sl.custom_minimum_size = Vector2(300, 52)
			sl.focus_mode = Control.FOCUS_NONE
			sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			sl.value_changed.connect(func(v: float): _preview_volume(it[0], v))
			r.add_child(sl)
			vol_sliders[it[0]] = sl
		pages[2].add_child(UiTheme.label("지금은 임시 합성음입니다. 경보·결정·아군 손실은 화면 표시와 진동을 함께 냅니다.", "Muted"))
		var hint := UiTheme.label("설정은 이 기기에 저장됩니다.", "Muted")
		hint.position = Vector2(36, 580 - 30 - 36)
		p.add_child(hint)
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 12)
		hb.alignment = BoxContainer.ALIGNMENT_END
		hb.position = Vector2(600 - 36 - 300, 580 - 30 - 52)
		hb.size = Vector2(300, 52)
		p.add_child(hb)
		var cancel := Button.new()
		cancel.text = "취소"
		cancel.custom_minimum_size = Vector2(110, 52)
		cancel.focus_mode = Control.FOCUS_NONE
		cancel.pressed.connect(_cancel)
		hb.add_child(cancel)
		var ok := ScreenKit.menu_button("저장", true)
		ok.custom_minimum_size = Vector2(170, 52)
		ok.pressed.connect(_save)
		hb.add_child(ok)
		_show_page(0)
	func _row(parent: Control, title: String) -> HBoxContainer:
		var row := HBoxContainer.new()
		var lbl := UiTheme.label(title, "Strong")
		lbl.custom_minimum_size = Vector2(160, 0)
		row.add_child(lbl)
		parent.add_child(row)
		return row
	func _choice(text: String, row: Control) -> Button:
		var b := Button.new()
		b.text = text
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(80, 52)
		row.add_child(b)
		return b
	func _check(parent: Control, text: String) -> CheckButton:
		var c := CheckButton.new()
		c.text = text
		c.focus_mode = Control.FOCUS_NONE
		c.custom_minimum_size = Vector2(0, 52)
		parent.add_child(c)
		return c
	func _show_page(i: int) -> void:
		for k in pages.size():
			pages[k].visible = k == i
			tabs[k].on = k == i
			tabs[k].queue_redraw()
	# 음량은 움직이는 대로 들려 주고, 취소하면 저장값으로 되돌린다.
	func _preview_volume(key: String, v: float) -> void:
		_set_vol(key, v)
		UiSound.apply_volume()
		if deck.sound and visible:
			deck.sound.play("volley" if key == "sfx" else "button")
	static func _get_vol(key: String) -> float:
		match key:
			"master": return GameSettings.vol_master
			"sfx": return GameSettings.vol_sfx
		return GameSettings.vol_ui
	static func _set_vol(key: String, v: float) -> void:
		match key:
			"master": GameSettings.vol_master = v
			"sfx": GameSettings.vol_sfx = v
			_: GameSettings.vol_ui = v
	func _sync() -> void:
		for it in scale_btns:
			it[0].button_pressed = is_equal_approx(it[1], pending_scale)
		for i in density_btns.size():
			density_btns[i].button_pressed = i == pending_density
		for i in slow_btns.size():
			slow_btns[i].button_pressed = i == pending_slow
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.015, 0.03, 0.78))
	var _orig_vol := {}
	func on_show() -> void:
		GameSettings.load_cfg()
		pending_scale = GameSettings.ui_scale
		full_chk.button_pressed = GameSettings.fullscreen
		glow_chk.button_pressed = GameSettings.glow
		fast_chk.button_pressed = GameSettings.auto_fast
		pending_slow = GameSettings.slow_mode
		vib_chk.button_pressed = GameSettings.vibrate
		pending_density = GameSettings.ship_density
		for k in vol_sliders:
			_orig_vol[k] = _get_vol(k)
			vol_sliders[k].set_value_no_signal(_orig_vol[k])
		_show_page(0)
		_sync()
	func _cancel() -> void:
		for k in _orig_vol:
			_set_vol(k, _orig_vol[k])
		UiSound.apply_volume()
		deck.show_screen(back_to)
	func _save() -> void:
		GameSettings.ui_scale = pending_scale
		GameSettings.fullscreen = full_chk.button_pressed
		GameSettings.glow = glow_chk.button_pressed
		GameSettings.auto_fast = fast_chk.button_pressed
		GameSettings.slow_mode = pending_slow
		GameSettings.vibrate = vib_chk.button_pressed
		for k in vol_sliders:
			_set_vol(k, vol_sliders[k].value)
		if GameSettings.ship_density != pending_density:
			GameSettings.ship_density = pending_density
			deck.renderer.reset()
		GameSettings.save_cfg()
		GameSettings.apply(get_window())
		UiSound.apply_volume()
		deck.apply_glow()
		deck.show_screen(back_to)

# ------------------------------------------------------------ 결과
class ResultScreen extends Control:
	var deck: Control
	var t := 0.0
	func _init(d: Control) -> void:
		deck = d
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 14)
		add_child(hb)
		hb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		hb.offset_left = -230
		hb.offset_right = 230
		hb.offset_top = -110
		hb.offset_bottom = -56
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		var title := Button.new()
		title.text = "타이틀로"
		title.custom_minimum_size = Vector2(150, 54)
		title.focus_mode = Control.FOCUS_NONE
		title.pressed.connect(func(): deck.to_title())
		hb.add_child(title)
		var again := ScreenKit.menu_button("다시 출격", true)
		again.custom_minimum_size = Vector2(240, 54)
		again.pressed.connect(func(): deck.restart())
		hb.add_child(again)
	func _process(delta: float) -> void:
		delta = UiDraw.real_dt(delta)
		t += delta
		queue_redraw()
	func on_show() -> void:
		t = 0.0
	func _draw() -> void:
		var b: Node = deck.battle
		var vs := size
		var win: bool = b.G.end_win
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.01, 0.015, 0.03, 0.84))
		var k := clampf(t / 0.6, 0.0, 1.0)
		var cx := vs.x * 0.5
		var acc := UiTheme.GOLD_HI if win else UiTheme.FOE
		UiDraw.text(self, Vector2(cx, 96), "작 전 성 공" if win else "작 전 실 패", "eyebrow", 12, Color(UiTheme.GOLD, k), HORIZONTAL_ALIGNMENT_CENTER, 0.0)
		UiDraw.text(self, Vector2(cx, 190), "승  리" if win else "패  배", "serif_bold", 92, Color(acc, k), HORIZONTAL_ALIGNMENT_CENTER, 0.0)
		ScreenKit.rule(self, Vector2(cx - 260, 218), Vector2(cx + 260, 218))
		UiDraw.text(self, Vector2(cx, 254), b.G.end_text, "serif", 16, Color(UiTheme.INK_2, k), HORIZONTAL_ALIGNMENT_CENTER, 0.0)
		var tt := int(b.G.t)
		var alive_a := 0
		for f in b.fleets:
			if f.side == 0 and not f.dead:
				alive_a += 1
		var stats := [["격침한 적 함정", "%d" % roundi(b.G.killed)], ["잃은 아군 함정", "%d" % roundi(b.G.lost)], ["교전 시간", "%d:%02d" % [tt / 60, tt % 60]], ["생존 함대", "%d / %d" % [alive_a, b.ALLY_DEF.size()]]]
		var cw := 200.0
		var x0 := cx - (cw * 4 + 36) * 0.5
		for i in 4:
			var r := Rect2(x0 + i * (cw + 12), 290, cw, 92)
			draw_style_box(UiTheme.ornate(false), r)
			UiDraw.text(self, r.position + Vector2(0, 34), stats[i][0], "regular", 12, UiTheme.INK_3, HORIZONTAL_ALIGNMENT_CENTER, cw)
			UiDraw.text(self, r.position + Vector2(0, 72), stats[i][1], "serif_bold", 28, UiTheme.INK, HORIZONTAL_ALIGNMENT_CENTER, cw)
		_column(Vector2(cx - 430, 420), 0)
		_column(Vector2(cx + 20, 420), 1)
	func _column(o: Vector2, side: int) -> void:
		var b: Node = deck.battle
		UiDraw.text(self, o, "촉 한 연 합 함 대" if side == 0 else "위 원 정 군", "eyebrow", 11, UiTheme.GOLD)
		var y := o.y + 14.0
		var i := 0
		for f in b.fleets:
			if f.side != side:
				continue
			var col := i % 2
			var r := Rect2(o.x + col * 208, y + (i / 2) * 46, 200, 40)
			draw_rect(r, Color(0.05, 0.08, 0.12, 0.85) if side == 0 else Color(0.11, 0.05, 0.04, 0.85))
			draw_texture_rect(b._portrait_tex(f.portrait), Rect2(r.position + Vector2(4, 4), Vector2(32, 32)), false, Color(1, 1, 1, 0.35) if f.dead else Color.WHITE)
			UiDraw.text(self, r.position + Vector2(44, 17), f.fname, "serif_bold", 13, UiTheme.INK_4 if f.dead else UiTheme.INK)
			if f.dead:
				UiDraw.text(self, Vector2(r.end.x - 8, r.position.y + 17), "궤멸", "medium", 11, UiTheme.FOE, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
			else:
				UiDraw.text(self, Vector2(r.end.x - 8, r.position.y + 17), "%d척" % ceili(f.ships), "medium", 11, UiTheme.INK_2, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
			draw_rect(Rect2(r.position + Vector2(44, 26), Vector2(148, 4)), UiTheme.SLOT)
			draw_rect(Rect2(r.position + Vector2(44, 26), Vector2(148 * f.ships / f.max_ships, 4)), UiTheme.side_color(side) if side == 1 else UiTheme.LIFE)
			i += 1
