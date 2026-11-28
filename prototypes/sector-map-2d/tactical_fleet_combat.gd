extends RefCounted

enum Weapon { LASER, MISSILE, RAILGUN }

const WEAPON_COLORS := [Color("#6ddcff"), Color("#ffb65d"), Color("#f9dd98")]
const DAMAGE := [2.4, 4.5, 3.5]
const SHIP_LIFE := 100.0
const FORMATION_COLOR := Color("#ff5661")

var capacity := PackedFloat32Array()
var life := PackedFloat32Array()
var active_impacts: Dictionary[int, bool] = {}


func reset(shu_count: int, wei_count: int) -> void:
	capacity = PackedFloat32Array([shu_count * SHIP_LIFE, wei_count * SHIP_LIFE])
	life = capacity.duplicate()
	active_impacts.clear()


func life_fraction(side: int) -> float:
	return life[side] / capacity[side]


func resolve_hits(shots: Array[Dictionary], shu_count: int) -> void:
	var impacts: Dictionary[int, bool] = {}
	for shot in shots:
		if not shot.impact:
			continue
		var emitter: int = shot.emitter
		impacts[emitter] = true
		if not active_impacts.has(emitter):
			var side := int(shot.target >= shu_count)
			life[side] = maxf(0.0, life[side] - DAMAGE[_weapon(shot)] * float(shot.get("damage_scale", 1.0)))
	active_impacts = impacts


func draw_shot(canvas: Node2D, shot: Dictionary, start: Vector2, target: Vector2, opacity: float) -> void:
	var weapon := _weapon(shot)
	var phase: float = shot.progress
	var color: Color = WEAPON_COLORS[weapon]
	var axis := (target - start).normalized()
	if shot.impact:
		_draw_impact(canvas, target, axis, weapon, color, phase, opacity)
		return
	match weapon:
		Weapon.LASER:
			var alpha := opacity * sin(PI * phase)
			canvas.draw_line(start, target, Color(color, alpha * 0.24), 3.2, true)
			canvas.draw_line(start, target, Color(color.lerp(Color.WHITE, 0.40), alpha), 1.1, true)
		Weapon.MISSILE:
			var emitter: int = shot.emitter
			var height := (11.0 + 4.0 * (emitter % 4)) * (-1.0 if emitter % 2 == 0 else 1.0)
			var arc := axis.orthogonal() * height
			for i in 8:
				var age := float(i) / 8.0
				var a := maxf(0.0, phase - 0.01 - i * 0.024)
				var b := maxf(0.0, phase - 0.01 - (i + 1) * 0.024)
				var near_point := start.lerp(target, a) + arc * sin(PI * a)
				var far_point := start.lerp(target, b) + arc * sin(PI * b)
				canvas.draw_line(near_point, far_point, Color(0.63, 0.67, 0.72, opacity * 0.24 * pow(1.0 - age, 1.7)),
					lerpf(1.15, 2.2, age), true)
			var nose := start.lerp(target, phase) + arc * sin(PI * phase)
			var previous := maxf(0.0, phase - 0.01)
			var pointing := (nose - (start.lerp(target, previous) + arc * sin(PI * previous))).normalized()
			canvas.draw_line(nose, nose - pointing * 3.0, Color(color, opacity * 0.92), 1.2, true)
			canvas.draw_circle(nose, 1.05, Color("#fff4d0", opacity), true, -1.0, true)
		Weapon.RAILGUN:
			var head := start.lerp(target, phase)
			var tail := start.lerp(target, maxf(0.0, phase - 0.067))
			canvas.draw_line(tail, head, Color(color, opacity * 0.9), 1.25, true)
			canvas.draw_circle(head, 0.9, Color(Color.WHITE, opacity), true, -1.0, true)


func _weapon(shot: Dictionary) -> Weapon:
	return shot.weapon


func _draw_impact(canvas: Node2D, point: Vector2, axis: Vector2, weapon: Weapon,
		color: Color, phase: float, opacity: float) -> void:
	var fade := opacity * (1.0 - phase)
	var normal := axis.orthogonal()
	match weapon:
		Weapon.LASER:
			var radius := 4.0 + phase * 16.0
			var angle := normal.angle()
			canvas.draw_arc(point, radius, angle - 1.0, angle + 1.0, 12,
				Color(color, fade), 2.0, true)
			canvas.draw_arc(point, radius, angle + PI - 1.0, angle + PI + 1.0, 12,
				Color(color, fade), 2.0, true)
			canvas.draw_circle(point, 4.0 * (1.0 - phase), Color(color, fade), true, -1.0, true)
		Weapon.MISSILE:
			var radius := 5.0 + phase * 24.0
			canvas.draw_circle(point, radius, Color(color, fade * 0.18), true, -1.0, true)
			canvas.draw_arc(point, radius, 0.0, TAU, 24, Color(color, fade), 2.5, true)
			canvas.draw_circle(point, 7.0 * (1.0 - phase), Color("#fff1c4", fade), true, -1.0, true)
		Weapon.RAILGUN:
			for i in range(-2, 3):
				var spark := (axis + normal * i * 0.45).normalized()
				canvas.draw_line(point + spark * phase * 14.0, point + spark * (7.0 + phase * 22.0),
					Color(color, fade), 2.0 if i == 0 else 1.0, true)
			canvas.draw_circle(point, 3.0 * (1.0 - phase), Color(Color.WHITE, fade), true, -1.0, true)
