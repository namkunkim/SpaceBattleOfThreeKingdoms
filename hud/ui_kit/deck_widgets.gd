class_name DeckWidgets
extends RefCounted

# 명령 데크에서 쓰는 작은 부품들.

# 그리기 콜백으로 그리는 패널. mouse_filter STOP으로 전장 클릭을 막는다.
class DrawPanel extends Control:
	var painter: Callable
	var style: StyleBox
	func _init(p: Callable, st: StyleBox = null) -> void:
		painter = p
		style = st
		mouse_filter = Control.MOUSE_FILTER_STOP
	func _draw() -> void:
		if style:
			draw_style_box(style, Rect2(Vector2.ZERO, size))
		if painter.is_valid():
			painter.call(self)

# 아이콘 버튼(배속·건너뛰기·일시정지·설정)
class IconButton extends Button:
	var icon_name := ""
	var caption := ""
	var active := false
	func _init(icon_n: String, cap := "") -> void:
		icon_name = icon_n
		caption = cap
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(52, 52)
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if active:
			draw_rect(Rect2(0, size.y - 2, size.x, 2), UiTheme.GOLD)
			draw_rect(r, UiTheme.GOLD, false, 1.0)
		var col := UiTheme.GOLD_HI if active else (UiTheme.INK if is_hovered() else UiTheme.INK_2)
		if disabled:
			col = UiTheme.INK_4
		if icon_name != "":
			UiDraw.icon(self, icon_name, Rect2(size * 0.5 - Vector2(9, 9), Vector2(18, 18)), col, 1.7)
		if caption != "":
			UiDraw.text(self, Vector2(0, size.y * 0.5 + 5.0), caption, "semibold", 13, col, HORIZONTAL_ALIGNMENT_CENTER, size.x)

# 명령 버튼: 아이콘 + 이름 + 단축키 + 지휘력 소모 + 재사용 대기
class CmdButton extends Button:
	var cmd: Dictionary
	var deck: Node
	var cool := 0.0
	var cool_text := ""
	var count_text := ""   # 남은 사용 횟수 "3/3"(미사일·함재기, salvo 규칙)
	var blocked := false
	var pinned := false
	var hold_k := 0.0   # 길게 눌러 확정 진행(0~1)
	func _init(c: Dictionary, d: Node) -> void:
		cmd = c
		deck = d
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(78, 80)
		tooltip_text = " "
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var hov := is_hovered() or pinned
		draw_rect(r, Color(0.07, 0.1, 0.12, 0.88) if hov else Color(0.04, 0.06, 0.08, 0.78))
		draw_rect(r.grow(-0.5), UiTheme.GOLD if hov else UiTheme.LINE, false, 1.0)
		var tint: Color = UiTheme.INK
		match cmd.get("tone", ""):
			"warm": tint = UiTheme.GOLD_HI
			"hot": tint = UiTheme.FOE_HI
		if blocked:
			tint = UiTheme.INK_4
		var ir := Rect2(size.x * 0.5 - 14, 14, 28, 28)
		UiDraw.icon(self, cmd.icon, ir, Color(tint, 0.3) if cool > 0.0 else tint, 1.7)
		UiDraw.text(self, Vector2(0, size.y - 14), cmd.label, "medium", 12, tint if not blocked else UiTheme.INK_4, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		UiDraw.text(self, Vector2(size.x - 6, 13), cmd.key, "regular", 10, UiTheme.INK_4, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
		var cost: int = cmd.get("cost", 0)
		for i in cost:
			UiDraw.diamond(self, Vector2(9 + i * 8, 9), 3.0, UiTheme.CP if not blocked else Color(UiTheme.CP, 0.35))
		if count_text != "":
			UiDraw.text(self, Vector2(size.x - 6, 26), count_text, "bold", 12, UiTheme.INK_4 if blocked else UiTheme.CP, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
		if hold_k > 0.0:
			var cc := ir.get_center()
			draw_arc(cc, 21.0, 0.0, TAU, 32, Color(UiTheme.GOLD, 0.25), 2.0, true)
			draw_arc(cc, 21.0, -PI * 0.5, -PI * 0.5 + TAU * hold_k, 32, UiTheme.GOLD_HI, 2.6, true)
		elif cmd.get("confirm", false):
			# 길게 눌러 확정하는 명령 표시: 아이콘 아래 작은 점 세 개
			for i in 3:
				draw_circle(Vector2(size.x * 0.5 - 6 + i * 6, 47), 1.2, Color(tint, 0.55))
		if cool > 0.0:
			draw_rect(Rect2(0, size.y - 3, size.x, 3), Color(0.1, 0.14, 0.21))
			draw_rect(Rect2(0, size.y - 3, size.x * (1.0 - cool), 3), UiTheme.CP)
			UiDraw.text(self, Vector2(0, 36), cool_text, "bold", 17, Color("cddaff"), HORIZONTAL_ALIGNMENT_CENTER, size.x, 3)
	func _make_custom_tooltip(_for_text: String) -> Object:
		return deck.make_cmd_tooltip(cmd)

# 탭 버튼
class TabButton extends Button:
	var on := false
	func _init(t: String) -> void:
		text = ""
		set_meta("label", t)
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(0, 52)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	func _draw() -> void:
		var col := UiTheme.GOLD_HI if on else (UiTheme.INK if is_hovered() else UiTheme.INK_3)
		UiDraw.text(self, Vector2(0, size.y * 0.5 + 6), get_meta("label"), "serif_wide", 15, col, HORIZONTAL_ALIGNMENT_CENTER, size.x)
		if on:
			var w := size.x * 0.5
			draw_rect(Rect2(size.x * 0.25, size.y - 2, w, 2), UiTheme.GOLD)
