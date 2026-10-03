class_name UiDraw
extends RefCounted

# HUD 공용 그리기. 아이콘은 28×28 격자의 선 그림으로 정의하고 원하는 크기로 그린다.

const ICONS := {
	"stop": [[[7, 7], [21, 7], [21, 21], [7, 21], [7, 7]]],
	"def": [[[14, 3], [22, 6.2], [22, 12.5], [20, 18], [14, 23], [8, 18], [6, 12.5], [6, 6.2], [14, 3]], [[14, 8], [14, 18]], [[10, 12.5], [18, 12.5]]],
	"charge": [[[4, 8], [11, 14], [4, 20]], [[12, 8], [19, 14], [12, 20]], [[20, 8], [24, 14], [20, 20]]],
	"rally": [[[14, 3], [14, 9]], [[14, 19], [14, 25]], [[3, 14], [9, 14]], [[19, 14], [25, 14]], [[11, 6], [14, 9], [17, 6]], [[11, 22], [14, 19], [17, 22]], [[6, 11], [9, 14], [6, 17]], [[22, 11], [19, 14], [22, 17]]],
	"retreat": [[[12, 7], [5, 14], [12, 21]], [[5, 14], [23, 14]], [[23, 9], [23, 19]]],
	"all": [[[5, 5], [12, 5], [12, 12], [5, 12], [5, 5]], [[16, 5], [23, 5], [23, 12], [16, 12], [16, 5]], [[5, 16], [12, 16], [12, 23], [5, 23], [5, 16]], [[16, 16], [23, 16], [23, 23], [16, 23], [16, 16]]],
	"missile": [[[6, 22], [16, 12]], [[16, 12], [18.5, 5.5], [22, 9], [16, 12]], [[8, 16], [5, 17], [6, 14]], [[12, 20], [11, 23], [14, 22]]],
	"fighter": [[[14, 4], [16.5, 13], [14, 15], [11.5, 13], [14, 4]], [[5, 15], [14, 13], [23, 15]], [[10, 22], [14, 15], [18, 22]]],
	"pause": [[[10, 7], [10, 21]], [[18, 7], [18, 21]]],
	"gear": [[[14, 3], [14, 7]], [[14, 21], [14, 25]], [[3, 14], [7, 14]], [[21, 14], [25, 14]], [[6.2, 6.2], [9, 9]], [[19, 19], [21.8, 21.8]], [[21.8, 6.2], [19, 9]], [[9, 19], [6.2, 21.8]]],
	"warn": [[[14, 4], [25, 23], [3, 23], [14, 4]], [[14, 11], [14, 17]], [[14, 19.5], [14, 20.5]]],
	"flag": [[[7, 24], [7, 4]], [[7, 5], [21, 5], [17, 10], [21, 15], [7, 15]]],
	"target": [[[14, 3], [14, 9]], [[14, 19], [14, 25]], [[3, 14], [9, 14]], [[19, 14], [25, 14]]],
}

static func icon(ci: CanvasItem, name: String, rect: Rect2, color: Color, width := 1.6) -> void:
	var paths: Array = ICONS.get(name, [])
	var k := minf(rect.size.x, rect.size.y) / 28.0
	var o := rect.position + (rect.size - Vector2(28, 28) * k) * 0.5
	for path in paths:
		var pts := PackedVector2Array()
		for p in path:
			pts.append(o + Vector2(p[0], p[1]) * k)
		ci.draw_polyline(pts, color, width, true)
	if name == "rally" or name == "gear" or name == "target":
		ci.draw_arc(o + Vector2(14, 14) * k, (3.0 if name != "gear" else 5.0) * k, 0.0, TAU, 20, color, width, true)

# 진영 인장: 사각 바탕에 한자 한 글자.
static func seal(ci: CanvasItem, rect: Rect2, side: int, glyph := "") -> void:
	var deep := UiTheme.ALLY_DEEP if side == 0 else UiTheme.FOE_DEEP
	var mid := Color("2b8f84") if side == 0 else Color("b8442a")
	var rim := Color("7fe9dc") if side == 0 else Color("ff9f80")
	ci.draw_rect(rect, deep)
	ci.draw_rect(rect.grow(-2.0), mid.lerp(deep, 0.35))
	ci.draw_rect(rect.grow(-0.5), rim, false, 1.0)
	ci.draw_rect(rect.grow(-3.5), Color(rim, 0.45), false, 1.0)
	var g := glyph if glyph != "" else ("蜀" if side == 0 else "魏")
	var f := UiTheme.font("serif_bold")
	var fs := int(rect.size.y * 0.56)
	var w := f.get_string_size(g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var asc := f.get_ascent(fs)
	var dsc := f.get_descent(fs)
	ci.draw_string(f, Vector2(rect.position.x + (rect.size.x - w) * 0.5, rect.position.y + (rect.size.y + asc - dsc) * 0.5), g, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f4fffd") if side == 0 else Color("fff0e8"))

# 진영 기호: 촉 = 사각, 위 = 마름모. 레이더·명패에서 색 외의 구분.
static func side_glyph(ci: CanvasItem, c: Vector2, r: float, side: int, color: Color, filled := true) -> void:
	var pts: PackedVector2Array
	if side == 0:
		pts = PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, r)])
	else:
		pts = PackedVector2Array([c + Vector2(0, -r * 1.25), c + Vector2(r * 1.25, 0), c + Vector2(0, r * 1.25), c + Vector2(-r * 1.25, 0)])
	if filled:
		ci.draw_colored_polygon(pts, color)
	else:
		pts.append(pts[0])
		ci.draw_polyline(pts, color, 1.2, true)

# 10칸 또는 20칸 기울인 분할 막대
static func seg_bar(ci: CanvasItem, rect: Rect2, frac: float, n: int, on: Color, off := UiTheme.SLOT, rtl := false, skew := 3.0) -> void:
	var gap := 2.0
	var w := (rect.size.x - gap * (n - 1)) / n
	var lit := clampi(roundi(frac * n), 0, n)
	for i in n:
		var k := (n - 1 - i) if rtl else i
		var x := rect.position.x + k * (w + gap)
		var col := on if i < lit else off
		var pts := PackedVector2Array([Vector2(x + skew, rect.position.y), Vector2(x + w + skew, rect.position.y), Vector2(x + w, rect.end.y), Vector2(x, rect.end.y)])
		ci.draw_colored_polygon(pts, col)
		if i < lit:
			ci.draw_line(Vector2(x + skew, rect.position.y + 0.5), Vector2(x + w + skew, rect.position.y + 0.5), on.lightened(0.45), 1.0)

static func diamond(ci: CanvasItem, c: Vector2, r: float, color: Color, filled := true) -> void:
	if r < 0.5:
		return
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	if filled:
		ci.draw_colored_polygon(pts, color)
	else:
		pts.append(pts[0])
		ci.draw_polyline(pts, color, 1.2, true)

static func text(ci: CanvasItem, pos: Vector2, s: String, font_name: String, size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0, outline := 0) -> void:
	var f := UiTheme.font(font_name)
	var p := pos
	var al := align
	var wd := width
	# Godot는 폭이 없으면 정렬을 무시한다. 폭 없이 오른쪽·가운데 정렬을 쓰면 기준점에서 직접 민다.
	if wd <= 0.0 and al != HORIZONTAL_ALIGNMENT_LEFT:
		var sw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		p.x -= sw if al == HORIZONTAL_ALIGNMENT_RIGHT else sw * 0.5
		al = HORIZONTAL_ALIGNMENT_LEFT
		wd = -1.0
	if outline > 0:
		ci.draw_string_outline(f, p, s, al, wd, size, outline, Color(0, 0, 0, 0.75 * color.a))
	ci.draw_string(f, p, s, al, wd, size, color)

static func text_w(s: String, font_name: String, size: int) -> float:
	return UiTheme.font(font_name).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x

static func dashed_poly(ci: CanvasItem, pts: PackedVector2Array, color: Color, width: float, dash: float, gap: float, offset := 0.0) -> void:
	# 파선 조각을 모아 한 번에 그린다(선 하나씩 그리면 2D 명령이 수백 개가 된다).
	var segs := PackedVector2Array()
	var acc := -offset
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var seg := a.distance_to(b)
		if seg <= 0.0:
			continue
		var d := (b - a) / seg
		var t := 0.0
		while t < seg:
			var cyc := fposmod(acc + t, dash + gap)
			if cyc < dash:
				var l := minf(dash - cyc, seg - t)
				segs.append(a + d * t)
				segs.append(a + d * (t + l))
				t += l
			else:
				t += (dash + gap) - cyc
		acc += seg
	if segs.size() >= 2:
		ci.draw_multiline(segs, color, width)

# 칸 구분선만 그리는 가벼운 막대(명패처럼 매 프레임 많이 그리는 곳에 쓴다)
static func cheap_bar(ci: CanvasItem, rect: Rect2, frac: float, n: int, on: Color, off := UiTheme.SLOT) -> void:
	ci.draw_rect(rect, off)
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(frac, 0.0, 1.0), rect.size.y)), on)
	var lines := PackedVector2Array()
	for i in range(1, n):
		var x := rect.position.x + rect.size.x * i / n
		lines.append(Vector2(x, rect.position.y))
		lines.append(Vector2(x, rect.end.y))
	ci.draw_multiline(lines, Color(0.0, 0.0, 0.0, 0.7), 1.5)
