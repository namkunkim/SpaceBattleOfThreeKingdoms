class_name OrnateStyle
extends StyleBox

# 먹빛 반투명 판: 가는 먹선 테두리 하나. 모서리 장식·안쪽 선·광택선 없음(적벽 시각 언어).
# 이름은 호환용으로 남겼다(UiTheme.ornate() 사용처가 많다). corners 인자는 무시한다.

@export var top := UiTheme.BG_TOP
@export var bottom := UiTheme.BG_BOTTOM
@export var border := UiTheme.GOLD_LINE
@export var accent := UiTheme.GOLD
@export var corners := false
@export var glint := false

func _draw(ci: RID, r: Rect2) -> void:
	var rs := RenderingServer
	var p := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	rs.canvas_item_add_polygon(ci, p, PackedColorArray([top, top, bottom, bottom]))
	var ring := PackedVector2Array([r.position + Vector2(0.5, 0.5), Vector2(r.end.x - 0.5, r.position.y + 0.5), r.end - Vector2(0.5, 0.5), Vector2(r.position.x + 0.5, r.end.y - 0.5), r.position + Vector2(0.5, 0.5)])
	rs.canvas_item_add_polyline(ci, ring, PackedColorArray([border]), 1.0)
