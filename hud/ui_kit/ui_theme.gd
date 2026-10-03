class_name UiTheme
extends RefCounted

# 디자인 토큰과 Godot Theme. 흑칠(짙은 남흑) 바탕 + 금장 테두리 + 진영 홀로그램 색.
# 진영은 색만으로 구분하지 않는다: 촉 = 사각·蜀 인장, 위 = 마름모·魏 인장.

const BG_TOP := Color(0.082, 0.11, 0.157, 0.94)
const BG_BOTTOM := Color(0.031, 0.043, 0.07, 0.96)
const BG_DEEP := Color(0.02, 0.03, 0.05, 0.97)
const GOLD := Color("c9a45c")
const GOLD_HI := Color("f3dda4")
const GOLD_LO := Color("6d5631")
const GOLD_LINE := Color(0.79, 0.64, 0.36, 0.38)
const INK := Color("eef2f4")
const INK_2 := Color("b9c4cd")
const INK_3 := Color("7f8b97")
const INK_4 := Color("56616d")
const ALLY := Color("5fe0cf")
const ALLY_HI := Color("c4f8f0")
const ALLY_DEEP := Color("0e3d39")
const FOE := Color("ff7550")
const FOE_HI := Color("ffd3bd")
const FOE_DEEP := Color("4d140b")
const LIFE := Color("86e39a")
const WARN := Color("f2b84b")
const CP := Color("86aaff")
const SLOT := Color("141c27")
const LINE := Color("2a3649")

const FONT_DIR := "res://assets/fonts/"

static var _fonts := {}
static var _theme: Theme

static func font(name: String) -> Font:
	if _fonts.has(name):
		return _fonts[name]
	var f: Font
	match name:
		"regular": f = load(FONT_DIR + "Pretendard-Regular.otf")
		"medium": f = load(FONT_DIR + "Pretendard-Medium.otf")
		"semibold": f = load(FONT_DIR + "Pretendard-SemiBold.otf")
		"bold": f = load(FONT_DIR + "Pretendard-Bold.otf")
		"serif": f = load(FONT_DIR + "NotoSerifKR-SemiBold.otf")
		"serif_bold": f = load(FONT_DIR + "NotoSerifKR-Bold.otf")
		"eyebrow":
			var v := FontVariation.new()
			v.base_font = font("semibold")
			v.spacing_glyph = 3
			f = v
		"serif_wide":
			var v := FontVariation.new()
			v.base_font = font("serif")
			v.spacing_glyph = 4
			f = v
		_: f = font("regular")
	if f is FontFile:
		(f as FontFile).antialiasing = TextServer.FONT_ANTIALIASING_GRAY
		(f as FontFile).hinting = TextServer.HINTING_LIGHT
		(f as FontFile).subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	_fonts[name] = f
	return f

static func flat(bg: Color, border: Color, bw := 1, radius := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.anti_aliasing = true
	return s

static func vflat(top: Color, bottom: Color, border: Color, bw := 1) -> StyleBoxFlat:
	# StyleBoxFlat은 단색이므로 위쪽 색을 쓰고 아래쪽 색은 그림자로 근사한다.
	var s := flat(top.lerp(bottom, 0.45), border, bw)
	return s

static func ornate(corners := true, deep := false) -> OrnateStyle:
	var s := OrnateStyle.new()
	s.corners = corners
	if deep:
		s.top = BG_DEEP
		s.bottom = BG_DEEP
	s.set_content_margin_all(12)
	return s

static func build() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font("regular")
	t.default_font_size = 14
	t.set_color("font_color", "Label", INK)
	# 버튼
	var normal := flat(Color(0.07, 0.1, 0.15), LINE)
	var hover := flat(Color(0.11, 0.16, 0.25), GOLD)
	var pressed := flat(Color(0.05, 0.08, 0.12), GOLD_HI)
	var disabled := flat(Color(0.05, 0.07, 0.1), Color(0.16, 0.2, 0.26))
	for st in [normal, hover, pressed, disabled]:
		st.content_margin_left = 14
		st.content_margin_right = 14
		st.content_margin_top = 6
		st.content_margin_bottom = 6
	t.set_stylebox("normal", "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_stylebox("disabled", "Button", disabled)
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", INK_2)
	t.set_color("font_hover_color", "Button", INK)
	t.set_color("font_pressed_color", "Button", GOLD_HI)
	t.set_color("font_disabled_color", "Button", INK_4)
	t.set_font("font", "Button", font("medium"))
	t.set_font_size("font_size", "Button", 14)
	# 주 버튼(금장)
	t.set_type_variation("PrimaryButton", "Button")
	var pn := flat(Color(0.2, 0.15, 0.07), GOLD)
	var ph := flat(Color(0.3, 0.22, 0.09), GOLD_HI)
	var pp := flat(Color(0.14, 0.1, 0.05), GOLD_HI)
	for st in [pn, ph, pp]:
		st.content_margin_left = 22
		st.content_margin_right = 22
		st.content_margin_top = 10
		st.content_margin_bottom = 10
		st.shadow_color = Color(0.79, 0.64, 0.36, 0.18)
		st.shadow_size = 6
	t.set_stylebox("normal", "PrimaryButton", pn)
	t.set_stylebox("hover", "PrimaryButton", ph)
	t.set_stylebox("pressed", "PrimaryButton", pp)
	t.set_color("font_color", "PrimaryButton", GOLD_HI)
	t.set_color("font_hover_color", "PrimaryButton", Color.WHITE)
	t.set_font("font", "PrimaryButton", font("serif_bold"))
	t.set_font_size("font_size", "PrimaryButton", 18)
	# 메뉴 버튼(투명, 좌측 금선)
	t.set_type_variation("MenuButton2", "Button")
	var mn := StyleBoxFlat.new()
	mn.bg_color = Color(0, 0, 0, 0)
	mn.content_margin_left = 18
	mn.content_margin_top = 8
	mn.content_margin_bottom = 8
	var mh := flat(Color(0.79, 0.64, 0.36, 0.1), Color(0, 0, 0, 0), 0)
	mh.border_width_left = 2
	mh.border_color = GOLD
	mh.content_margin_left = 18
	mh.content_margin_top = 8
	mh.content_margin_bottom = 8
	t.set_stylebox("normal", "MenuButton2", mn)
	t.set_stylebox("hover", "MenuButton2", mh)
	t.set_stylebox("pressed", "MenuButton2", mh)
	t.set_color("font_color", "MenuButton2", INK_2)
	t.set_color("font_hover_color", "MenuButton2", GOLD_HI)
	t.set_font("font", "MenuButton2", font("serif"))
	t.set_font_size("font_size", "MenuButton2", 19)
	# 패널·툴팁
	t.set_stylebox("panel", "Panel", ornate())
	t.set_stylebox("panel", "PanelContainer", ornate())
	t.set_stylebox("panel", "TooltipPanel", ornate(false))
	t.set_color("font_color", "TooltipLabel", INK_2)
	t.set_font("font", "TooltipLabel", font("regular"))
	t.set_font_size("font_size", "TooltipLabel", 13)
	# 라벨 변형
	_label_var(t, "Eyebrow", font("eyebrow"), 11, GOLD)
	_label_var(t, "Title", font("serif_bold"), 26, INK)
	_label_var(t, "Display", font("serif_bold"), 54, INK)
	_label_var(t, "Heading", font("serif_bold"), 18, INK)
	_label_var(t, "Serif", font("serif"), 15, INK)
	_label_var(t, "Muted", font("regular"), 12, INK_3)
	_label_var(t, "Body", font("regular"), 14, INK_2)
	_label_var(t, "Strong", font("semibold"), 14, INK)
	# 체크박스·옵션
	t.set_color("font_color", "CheckBox", INK_2)
	t.set_color("font_hover_color", "CheckBox", INK)
	t.set_stylebox("normal", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckBox", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckBox", StyleBoxEmpty.new())
	# 스크롤·슬라이더
	t.set_stylebox("slider", "HSlider", flat(SLOT, LINE))
	t.set_stylebox("grabber_area", "HSlider", flat(GOLD_LO, GOLD_LO))
	t.set_stylebox("grabber_area_highlight", "HSlider", flat(GOLD, GOLD))
	_theme = t
	return t

static func _label_var(t: Theme, name: String, f: Font, size: int, col: Color) -> void:
	t.set_type_variation(name, "Label")
	t.set_font("font", name, f)
	t.set_font_size("font_size", name, size)
	t.set_color("font_color", name, col)

static func side_color(side: int) -> Color:
	return ALLY if side == 0 else FOE

static func side_hi(side: int) -> Color:
	return ALLY_HI if side == 0 else FOE_HI

static func label(text: String, variation := "", size := 0, color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if size > 0:
		l.add_theme_font_size_override("font_size", size)
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
