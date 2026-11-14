extends "res://view/fleet_render/p05_formation_schedule.gd"

const Route := preload("res://data/scenarios/p05/rc_liu_sq_01_presentation.tres")
const FLEET_ID := "RC-LIU-SQ-01"
const SOURCE := "FRM-03"
const TARGET := "FRM-01"
const RATE := 30
const STEP := 1.0 / RATE
const MOTION_SAMPLES := 145

var sample_index := 0
var phase := 1
var accumulated := 0.0


func prepare_frozen(roster: Array, boundary: float) -> bool:
	var data = JSON.parse_string(FileAccess.get_file_as_string(Candidate))
	if not data is Dictionary or not data.has(FLEET_ID):
		return false
	var route: Dictionary = data[FLEET_ID]
	if roster.size() != route.source.size():
		return false
	radius = boundary
	rows = roster
	var position := {}
	for row: Dictionary in rows:
		if not route.source.has(row.id):
			return false
		var point: Array = route.source[row.id]
		position[row.id] = Vector2(point[0], point[1])
	var nodes := {0: position.duplicate()}
	var moves: Array = route.moves
	for i in moves.size():
		var move: Array = moves[i]
		if i + 1 < moves.size() and move[0] != moves[i + 1][0]:
			var next: Array = moves[i + 1]
			var alternate := position.duplicate()
			alternate[next[0]] = Vector2(next[1][0], next[1][1])
			nodes[2 * i + 1] = alternate
		position[move[0]] = Vector2(move[1][0], move[1][1])
		nodes[2 * i + 2] = position.duplicate()
	layouts = [nodes[0]]
	knots = [0.0]
	var count := 0
	for edge in Route.get_meta("path"):
		var destination: Dictionary = nodes[int(edge.x)]
		if not clear(layouts.back(), destination):
			return false
		count += int(edge.y)
		layouts.append(destination)
		knots.append(float(count) / RATE)
	return count == MOTION_SAMPLES and layouts.back() == nodes[2 * moves.size()]


## One spatial sample at most per callback, even after a long frame.
## When blocked, time credit is bounded so delivering a new commit cannot jump ahead.
func consume(confirmed_seconds: float, dt: float) -> bool:
	if sample_index >= MOTION_SAMPLES or not is_finite(dt) or dt <= 0.0:
		return false
	accumulated += minf(dt, STEP)
	if confirmed_seconds + 0.000001 < knots[phase]:
		accumulated = minf(accumulated, STEP)
		return false
	if accumulated + 0.000001 < STEP:
		return false
	accumulated = clampf(accumulated - STEP, 0.0, STEP)
	sample_index += 1
	if sample_index >= roundi(knots[phase] * RATE):
		phase += 1
	return true


func sample(seconds: float) -> Dictionary:
	var index := clampi(knots.bsearch(seconds, false) - 1, 0, layouts.size() - 2)
	var u := clampf((seconds - knots[index]) / (knots[index + 1] - knots[index]), 0.0, 1.0)
	const RAMP := 0.01
	const PEAK := 4.0 / (1.0 - 2.0 * RAMP)
	const BOUNDS := [0.0, RAMP, 0.5 - RAMP, 0.5 + RAMP, 1.0 - RAMP, 1.0]
	const LEVELS := [0.0, PEAK, PEAK, -PEAK, -PEAK, 0.0]
	var fraction := 0.0
	var speed := 0.0
	for i in 5:
		var width: float = BOUNDS[i + 1] - BOUNDS[i]
		var time := clampf(u - BOUNDS[i], 0.0, width)
		var jerk: float = (LEVELS[i + 1] - LEVELS[i]) / width
		fraction += speed * time + LEVELS[i] * time * time / 2.0 + jerk * time * time * time / 6.0
		speed += LEVELS[i] * time + jerk * time * time / 2.0
	var points := {}
	for row: Dictionary in rows:
		var from: Vector2 = layouts[index][row.id]
		var to: Vector2 = layouts[index + 1][row.id]
		points[row.id] = to if u == 1.0 else from.lerp(to, clampf(fraction, 0.0, 1.0))
	return points
