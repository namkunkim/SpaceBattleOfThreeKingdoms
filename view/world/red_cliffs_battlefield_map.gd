extends Control

const ORBIT_ART := "res://assets/world_atlas/red-cliffs-reference-sky.jpg"
var _profile: Dictionary
var _orbit: Texture2D
var _terrain_overlay: Texture2D

func display(brief: BattleBrief) -> bool:
	_profile = brief.profile()
	if not _profile.is_empty():
		var cfg: Dictionary = _profile.combat.get("terrain", {})
		var path := str(cfg.get("movement_field", {}).get("overlay", ""))
		_terrain_overlay = load(path) as Texture2D if not path.is_empty() else null
	if _orbit == null and ResourceLoader.exists(ORBIT_ART):
		_orbit = load(ORBIT_ART) as Texture2D
	queue_redraw()
	return not _profile.is_empty()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("070d16"))
	if _profile.is_empty():
		_text(Vector2(24, 34), "적벽 전투 프로필을 불러올 수 없습니다.", Color("f6c4ae"), 17)
		return
	var rules: Dictionary = _profile.rules
	var extent := Vector2(float(rules.world_w), float(rules.world_h))
	var scale_factor := minf((size.x - 120.0) / extent.x, (size.y - 104.0) / extent.y)
	if scale_factor <= 0.0:
		return
	var field := Rect2((size - extent * scale_factor) / 2.0, extent * scale_factor)
	draw_rect(field, Color("101c2b"))
	if _orbit != null:
		draw_texture_rect(_orbit, field, false, Color(0.88, 0.9, 0.96))
	if _terrain_overlay != null:
		draw_texture_rect(_terrain_overlay, field, false)
	for x in range(200, int(extent.x), 200):
		for y in range(200, int(extent.y), 200):
			var p := field.position + Vector2(x, y) * scale_factor
			var grid := Color("6b9cb94d")
			draw_line(p - Vector2(3, 0), p + Vector2(3, 0), grid)
			draw_line(p - Vector2(0, 3), p + Vector2(0, 3), grid)
		var tick := Vector2(field.position.x + x * scale_factor, field.position.y)
		draw_line(tick, tick + Vector2(0, 5), Color("6b9cb980"))
	draw_rect(field, Color("607c965b"), false, 1.0)
	_corner_brackets(field, Color("b2ceda"), 18.0)
	var top := field.position - Vector2(0, 15)
	_text(top, "구지 궤도  /  건안 13년 겨울", Color("f2dec0"), 17)
	var status := "전장 좌표  %d × %d  ·  %s" % [int(extent.x), int(extent.y), _profile.difficulty]
	var status_width := get_theme_default_font().get_string_size(status, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
	_text(Vector2(field.end.x - status_width, top.y), status, Color("a7bccd"), 14)

func _corner_brackets(rect: Rect2, tint: Color, span: float) -> void:
	for x: float in [rect.position.x, rect.end.x]:
		for y: float in [rect.position.y, rect.end.y]:
			var p := Vector2(x, y)
			var horizontal := span if x == rect.position.x else -span
			var vertical := span if y == rect.position.y else -span
			draw_polyline(PackedVector2Array([p + Vector2(horizontal, 0), p, p + Vector2(0, vertical)]), tint, 1.5, true)

func _text(at: Vector2, value: String, tint: Color, font_size: int) -> void:
	var font := get_theme_default_font()
	draw_string_outline(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, 4, Color("08111d"))
	draw_string(font, at, value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, tint)
