extends Control

var sweep := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	sweep = fmod(sweep + delta * 0.55, TAU)
	queue_redraw()

func _draw() -> void:
	var center := Vector2(108.0, 102.0)
	var radius := 88.0
	draw_circle(center, radius, Color(0.015, 0.10, 0.16, 0.92))
	for ring in [0.34, 0.67, 1.0]:
		draw_arc(center, radius * ring, 0.0, TAU, 72, Color(0.12, 0.65, 0.88, 0.55), 1.2)
	draw_line(center - Vector2(radius, 0.0), center + Vector2(radius, 0.0), Color(0.10, 0.45, 0.65, 0.42), 1.0)
	draw_line(center - Vector2(0.0, radius), center + Vector2(0.0, radius), Color(0.10, 0.45, 0.65, 0.42), 1.0)
	var sweep_end := center + Vector2(cos(sweep), sin(sweep)) * radius
	draw_line(center, sweep_end, Color(0.35, 0.92, 1.0, 0.80), 2.0)
	var friendly := [Vector2(-22, 38), Vector2(8, 49), Vector2(35, 30)]
	var hostile := [Vector2(-30, -35), Vector2(4, -48), Vector2(39, -30)]
	for point in friendly:
		_draw_contact(center + point, Color("43e0ff"), false)
	for point in hostile:
		_draw_contact(center + point, Color("ff6758"), true)
	draw_circle(center, 5.0, Color("ffe05a"))

func _draw_contact(at: Vector2, color: Color, hostile: bool) -> void:
	var direction := -1.0 if hostile else 1.0
	var points := PackedVector2Array([
		at + Vector2(0.0, -6.0 * direction),
		at + Vector2(-5.0, 5.0 * direction),
		at + Vector2(5.0, 5.0 * direction),
	])
	draw_colored_polygon(points, color)
