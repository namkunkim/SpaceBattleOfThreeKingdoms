extends RefCounted

enum Weapon { LASER, MISSILE, RAILGUN }

const WEAPON_COLORS := [Color("#6ddcff"), Color("#ffb65d"), Color("#f9dd98")]
const DAMAGE := [2.4, 4.5, 3.5]
const SHIP_LIFE := 100.0
const FORMATION_COLOR := Color("#ff5661")
const OVERVIEW_FLASH_HOLD := 0.12
const OVERVIEW_FLASH_DURATION := 0.38
const OVERVIEW_FLASH_INTERVAL := 0.52

var capacity := PackedFloat32Array()
var life := PackedFloat32Array()
var active_impacts: Dictionary[int, bool] = {}
var overview_hits: Array[Dictionary] = [{}, {}]
var overview_hit_age := PackedFloat32Array([INF, INF])


func reset(shu_count: int, wei_count: int) -> void:
	capacity = PackedFloat32Array([shu_count * SHIP_LIFE, wei_count * SHIP_LIFE])
	life = capacity.duplicate()
	active_impacts.clear()
	for side in 2:
		overview_hits[side] = {}
		overview_hit_age[side] = INF


func life_fraction(side: int) -> float:
	return life[side] / capacity[side]


func resolve_hits(shots: Array[Dictionary], shu_count: int, delta := 0.0) -> void:
	for side in 2:
		overview_hit_age[side] += delta
	var impacts: Dictionary[int, bool] = {}
	for shot in shots:
		if not shot.impact:
			continue
		var emitter: int = shot.emitter
		impacts[emitter] = true
		if not active_impacts.has(emitter):
			var side := int(shot.target >= shu_count)
			life[side] = maxf(0.0, life[side] - DAMAGE[_weapon(shot)] * float(shot.get("damage_scale", 1.0)))
			if overview_hit_age[side] >= OVERVIEW_FLASH_INTERVAL:
				overview_hits[side] = shot
				overview_hit_age[side] = 0.0
	active_impacts = impacts


func draw_shot(canvas: Node2D, shot: Dictionary, start: Vector2, target: Vector2,
		opacity: float, scale_factor: float) -> void:
	var weapon := _weapon(shot)
	var phase: float = shot.progress
	var offset := target - start
	var distance := offset.length()
	var axis := offset.normalized()
	if axis.is_zero_approx():
		axis = Vector2.RIGHT if int(shot.source) < int(shot.target) else Vector2.LEFT
	if shot.impact:
		_draw_impact(canvas, target, axis, phase, opacity, scale_factor)
		return
	var color: Color = WEAPON_COLORS[weapon]
	var head := start.lerp(target, phase)
	match weapon:
		Weapon.LASER:
			var pulse := clampf((phase - 0.84) / 0.16, 0.0, 1.0)
			if pulse <= 0.0:
				return
			head = target - axis * minf((1.0 - pulse) * 16.0 * scale_factor, distance)
			var length := minf(11.0 * scale_factor, start.distance_to(head))
			canvas.draw_line(head - axis * length, head,
				Color(color.lerp(Color.WHITE, 0.7), opacity * sin(PI * pulse) * 0.78), maxf(0.85, scale_factor), true)
		Weapon.MISSILE:
			var emitter: int = shot.emitter
			var height := (9.0 + 3.0 * (emitter % 4)) * (-1.0 if emitter % 2 == 0 else 1.0)
			var arc := axis.orthogonal() * height * scale_factor
			head += arc * sin(PI * phase)
			var back := maxf(0.0, phase - 0.016)
			var previous := start.lerp(target, back) + arc * sin(PI * back)
			var tail := head - (head - previous).normalized() * minf(13.0 * scale_factor, distance * phase)
			canvas.draw_line(tail, head, Color("#b4c2d0", opacity * 0.34), maxf(0.85, scale_factor), true)
			canvas.draw_circle(head, maxf(0.65, 0.9 * scale_factor), Color(color.lerp(Color.WHITE, 0.52), opacity * 0.82),
				true, -1.0, true)
		Weapon.RAILGUN:
			var length := minf(9.0 * scale_factor, distance * phase)
			canvas.draw_line(head - axis * length, head,
				Color(color.lerp(Color.WHITE, 0.58), opacity * 0.66), maxf(0.85, 0.9 * scale_factor), true)


func draw_overview_flash(canvas: Node2D, point: Vector2, side: int, opacity: float, scale_factor: float) -> void:
	var age := overview_hit_age[side]
	if age >= OVERVIEW_FLASH_DURATION:
		return
	var overview_weight := 1.0 - smoothstep(0.30, 0.65, scale_factor)
	var flash := opacity * overview_weight * (1.0 - smoothstep(OVERVIEW_FLASH_HOLD, OVERVIEW_FLASH_DURATION, age))
	if flash <= 0.0:
		return
	# Hold the flash briefly even when the underlying impact sample has ended.
	canvas.draw_circle(point, maxf(1.7, 4.0 * scale_factor), Color("#d5e7ff", flash * 0.55), true, -1.0, true)
	canvas.draw_circle(point, maxf(1.0, 1.9 * scale_factor), Color(Color.WHITE, flash), true, -1.0, true)


func _weapon(shot: Dictionary) -> Weapon:
	return shot.weapon


func _draw_impact(canvas: Node2D, point: Vector2, axis: Vector2, phase: float,
		opacity: float, scale_factor: float) -> void:
	var flash_window := lerpf(0.56, 0.34, smoothstep(0.30, 1.0, scale_factor))
	var age := phase / flash_window
	if age >= 1.0:
		return
	var fade := opacity * pow(1.0 - age, 1.8)
	var halo_radius := maxf(1.7, (4.0 - age) * scale_factor)
	var core_radius := maxf(1.0, (1.9 - age * 0.65) * scale_factor)
	var flash_brightness := lerpf(1.32, 1.0, smoothstep(0.30, 0.85, scale_factor))
	var flash_opacity := minf(opacity, fade * flash_brightness)
	canvas.draw_circle(point, halo_radius, Color("#d5e7ff", fade * flash_brightness * 0.26), true, -1.0, true)
	canvas.draw_circle(point, core_radius, Color(Color.WHITE, flash_opacity), true, -1.0, true)
	var normal := axis.orthogonal()
	var spark_length := maxf(2.1, (6.0 - age * 2.5) * scale_factor)
	for i in [-1, 1]:
		var spark := (axis + normal * float(i) * 0.24).normalized()
		var inner := point + spark * (1.0 + age * 3.0) * scale_factor
		var outer := inner + spark * spark_length
		canvas.draw_line(inner, outer, Color(Color.WHITE, fade * 0.63),
			maxf(0.85, 0.8 * scale_factor), true)
