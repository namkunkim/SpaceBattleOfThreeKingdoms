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
		custom_minimum_size = Vector2(44, 40)
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
	var blocked := false
	var pinned := false
	func _init(c: Dictionary, d: Node) -> void:
		cmd = c
		deck = d
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(78, 80)
		tooltip_text = " "
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var hov := is_hovered() or pinned
		var top := Color(0.11, 0.16, 0.25) if hov else Color(0.086, 0.13, 0.2)
		var bot := Color(0.05, 0.075, 0.12)
		draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, 0), r.end, Vector2(0, r.end.y)]), PackedColorArray([top, top, bot, bot]))
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
		custom_minimum_size = Vector2(0, 40)
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

# 그룹 탭: 로마 숫자 + 소속 지휘관 초상
class GroupButton extends Button:
	var n := 1
	var deck: Node
	func _init(i: int, d: Node) -> void:
		n = i
		deck = d
		focus_mode = Control.FOCUS_NONE
		custom_minimum_size = Vector2(82, 44)
		tooltip_text = "그룹 %s 선택 (%d) · 길게 누르거나 Ctrl+%d로 저장" % [["I", "II", "III", "IV"][i - 1], i, i]
	func _draw() -> void:
		var b: Node = deck.battle
		var g: Array = b.group_fleets(n)
		var on: bool = not g.is_empty() and b.same_sel(g)
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.07, 0.1, 0.15, 0.94))
		draw_rect(r.grow(-0.5), UiTheme.ALLY if on else (UiTheme.GOLD_LO if is_hovered() else UiTheme.LINE), false, 1.0)
		if on:
			draw_rect(Rect2(0, size.y - 2, size.x, 2), UiTheme.ALLY)
		var col := UiTheme.ALLY_HI if on else (UiTheme.INK_2 if not g.is_empty() else UiTheme.INK_4)
		UiDraw.text(self, Vector2(6, size.y * 0.5 + 5), ["I", "II", "III", "IV"][n - 1], "serif_bold", 13, col, HORIZONTAL_ALIGNMENT_CENTER, 22)
		var x := 30.0
		for f in g.slice(0, 3):
			draw_texture_rect(b._portrait_tex(f.portrait), Rect2(x, 8, 22, 22), false)
			draw_rect(Rect2(x, 8, 22, 22), Color(0, 0, 0, 0.6), false, 1.0)
			x += 16.0
		if g.is_empty():
			UiDraw.text(self, Vector2(30, size.y * 0.5 + 4), "비어 있음", "regular", 10, UiTheme.INK_4)
