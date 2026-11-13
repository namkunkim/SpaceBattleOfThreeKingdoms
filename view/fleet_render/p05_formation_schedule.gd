extends RefCounted

const Sweep := preload("res://scripts/p05_formation_transition.gd")
const Candidate := "res://data/scenarios/p05/adjusted_formation_route.json"
const DURATION := 5.0

var radius: float
var rows: Array
var layouts: Array = []
var knots: Array[float] = [0.0]

# The input rows preserve the renderer's slot order, identities, and hull sizes.
func prepare(fleet: String, roster: Array, boundary: float) -> bool:
	var fixture = JSON.parse_string(FileAccess.get_file_as_string(Candidate))
	if not fixture is Dictionary or not fixture.has(fleet):
		return false
	var route: Dictionary = fixture[fleet]
	if roster.size() != route.source.size():
		return false
	radius = boundary
	rows = roster
	var position := {}
	for row: Dictionary in rows:
		if not route.source.has(row.id):
			return false
		var source: Array = route.source[row.id]
		position[row.id] = Vector2(source[0], source[1])
	var ordered: Array = [position.duplicate()]
	for move: Array in route.moves:
		position[move[0]] = Vector2(move[1][0], move[1][1])
		ordered.append(position.duplicate())
	for row: Dictionary in rows:
		var destination: Array = route.dest[row.id][1]
		if position[row.id] != Vector2(destination[0], destination[1]):
			return false

	# Minimize the sum of phase lengths measured by the farthest ship in each phase.
	var costs: Array[float] = []
	costs.resize(ordered.size())
	costs.fill(INF)
	costs[0] = 0.0
	var previous: Array[int] = []
	previous.resize(ordered.size())
	previous.fill(-1)
	for first in ordered.size() - 1:
		if not is_finite(costs[first]):
			continue
		for last in range(first + 1, ordered.size()):
			var longest := 0.0
			for row: Dictionary in rows:
				var a: Vector2 = ordered[first][row.id]
				longest = maxf(longest, a.distance_to(ordered[last][row.id]))
			var cost := costs[first] + longest
			if cost < costs[last] and clear(ordered[first], ordered[last]):
				costs[last] = cost
				previous[last] = first
	var last := ordered.size() - 1
	if not is_finite(costs[last]) or costs[last] <= 0.0:
		return false
	# Quintic peak acceleration scales with distance / seconds².
	var weights: Array[float] = []
	knots = [DURATION]
	while last > 0:
		layouts.push_front(ordered[last])
		var prior := previous[last]
		weights.push_front(sqrt(costs[last] - costs[prior]))
		last = prior
	layouts.push_front(ordered[0])
	var total := 0.0
	for weight in weights:
		total += weight
	knots = [0.0]
	for i in weights.size():
		knots.append(DURATION if i == weights.size() - 1 else knots[-1] + DURATION * weights[i] / total)
	return true


func clear(start: Dictionary, finish: Dictionary, margin := 0.001) -> bool:
	var sweep: Array = []
	for row: Dictionary in rows:
		sweep.append({"id": row.id, "half": row.half + Vector2(margin, margin), "from": start[row.id], "to": finish[row.id]})
	return Sweep.validate(sweep, radius).ok


func sample(seconds: float) -> Dictionary:
	var phase := knots.bsearch(seconds, false) - 1
	phase = clampi(phase, 0, layouts.size() - 2)
	var u := clampf((seconds - knots[phase]) / (knots[phase + 1] - knots[phase]), 0.0, 1.0)
	# The common quintic parameter preserves each certified sweep. Velocity and
	# acceleration vanish at the knots, including the stationary endpoints.
	var blend := u * u * u * (10.0 + u * (-15.0 + 6.0 * u))
	var result := {}
	for row: Dictionary in rows:
		var a: Vector2 = layouts[phase][row.id]
		var b: Vector2 = layouts[phase + 1][row.id]
		result[row.id] = b if u == 1.0 else a.lerp(b, blend)
	return result


func advance(seconds: float, requested: float, position: Dictionary) -> float:
	var desired := clampf(requested, 0.0, DURATION)
	if desired == seconds or clear(position, sample(desired)):
		return desired
	# Rendering a chord across several phases may cut through another hull.
	# Keep the next certified knot visible instead of publishing that chord.
	var index := knots.bsearch(seconds, desired < seconds)
	if desired < seconds:
		index -= 1
	var next := knots[clampi(index, 0, knots.size() - 1)]
	if (desired - seconds) * (next - desired) > 0.0 or not clear(position, sample(next)):
		return seconds
	return next
