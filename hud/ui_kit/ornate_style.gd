class_name OrnateStyle
extends StyleBox

# 흑칠 패널: 세로 그라데이션 바탕, 금선 테두리, 안쪽 가는 선, 위쪽 중앙 광택선, 모서리 장식.

@export var top := UiTheme.BG_TOP
@export var bottom := UiTheme.BG_BOTTOM
@export var border := UiTheme.GOLD_LINE
@export var accent := UiTheme.GOLD
@export var corners := true
@export var glint := true

func _draw(ci: RID, r: Rect2) -> void:
	var rs := RenderingServer
	var p := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	rs.canvas_item_add_polygon(ci, p, PackedColorArray([top, top, bottom, bottom]))
	# 바깥 테두리
	var ring := PackedVector2Array([r.position + Vector2(0.5, 0.5), Vector2(r.end.x - 0.5, r.position.y + 0.5), r.end - Vector2(0.5, 0.5), Vector2(r.position.x + 0.5, r.end.y - 0.5), r.position + Vector2(0.5, 0.5)])
	rs.canvas_item_add_polyline(ci, ring, PackedColorArray([border]), 1.0)
	# 안쪽 가는 선
	var ir := r.grow(-4.0)
	if ir.size.x > 8.0 and ir.size.y > 8.0:
		var inner := PackedVector2Array([ir.position, Vector2(ir.end.x, ir.position.y), ir.end, Vector2(ir.position.x, ir.end.y), ir.position])
		rs.canvas_item_add_polyline(ci, inner, PackedColorArray([Color(accent, 0.12)]), 1.0)
	if glint and r.size.x > 60.0:
		var y := r.position.y + 0.5
		var x0 := r.position.x + r.size.x * 0.16
		var x1 := r.end.x - r.size.x * 0.16
		rs.canvas_item_add_polyline(ci, PackedVector2Array([Vector2(x0, y), Vector2((x0 + x1) * 0.5, y), Vector2(x1, y)]), PackedColorArray([Color(UiTheme.GOLD_HI, 0.0), Color(UiTheme.GOLD_HI, 0.75), Color(UiTheme.GOLD_HI, 0.0)]), 1.0)
	if corners:
		_corner(ci, r.position, Vector2(1, 1))
		_corner(ci, Vector2(r.end.x, r.position.y), Vector2(-1, 1))
		_corner(ci, Vector2(r.position.x, r.end.y), Vector2(1, -1))
		_corner(ci, r.end, Vector2(-1, -1))

func _corner(ci: RID, o: Vector2, d: Vector2) -> void:
	var rs := RenderingServer
	var c := accent
	var a := o + Vector2(-2.0, -2.0) * d
	rs.canvas_item_add_polyline(ci, PackedVector2Array([a + Vector2(0, 20) * d, a + Vector2(0, 6) * d, a + Vector2(6, 0) * d, a + Vector2(20, 0) * d]), PackedColorArray([c]), 1.6, true)
	var b := o + Vector2(2.5, 2.5) * d
	rs.canvas_item_add_polyline(ci, PackedVector2Array([b + Vector2(0, 14) * d, b + Vector2(0, 6) * d, b + Vector2(6, 0) * d, b + Vector2(14, 0) * d]), PackedColorArray([Color(c, 0.55)]), 1.0, true)
	var dm := o + Vector2(0.5, 0.5) * d
	rs.canvas_item_add_polygon(ci, PackedVector2Array([dm + Vector2(0, -3), dm + Vector2(3, 0), dm + Vector2(0, 3), dm + Vector2(-3, 0)]), PackedColorArray([UiTheme.GOLD_HI]))
