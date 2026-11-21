extends RefCounted
## Four identity-preserving routes; authority owns the 50-tick timer.
const Schedule := preload("res://view/fleet_render/p05_formation_schedule.gd")
const Policy := preload("res://core/battle/p05_p07_first_operation.gd")
const TICKS := 50
const SECONDS := 5.0

var schedule: RefCounted
var reverse_schedule: RefCounted
var source_id := ""
var target_id := ""
var fleet_id := ""

func prepare(fleet: String, roster: Array, boundary: float) -> bool:
	schedule = null
	var definition := Policy.load_source()
	if not definition.ok or fleet not in ["RC-LIU-SQ-01", "RC-LIU-SQ-02"]:
		return false
	var approved: Dictionary = {}
	for row: Dictionary in definition.definition.fleets:
		if row.id == fleet:
			approved = row
	if approved.is_empty() or roster.size() != int(approved.ship_count) or boundary != float(approved.outer_radius):
		return false
	var identities := {}
	for row: Variant in roster:
		if not row is Dictionary or not row.get("id") is String or identities.has(row.id) \
				or not row.get("half") is Vector2 or not row.half.is_finite() or row.half.x <= 0 or row.half.y <= 0:
			return false
		identities[row.id] = true
	var candidate := Schedule.new()
	if not candidate.prepare(fleet, roster.duplicate(true), boundary):
		return false
	fleet_id = fleet
	source_id = approved.formation_id
	target_id = approved.allowed_formations[1]
	schedule = candidate
	reverse_schedule = Schedule.new()
	reverse_schedule.rows = candidate.rows.duplicate(true)
	reverse_schedule.radius = candidate.radius
	reverse_schedule.layouts = candidate.layouts.duplicate(true)
	reverse_schedule.layouts.reverse()
	reverse_schedule.knots.clear()
	for i in range(candidate.knots.size() - 1, -1, -1):
		reverse_schedule.knots.append(SECONDS - candidate.knots[i])
	return true

func accepts(source: String, target: String) -> bool:
	return schedule != null and ((source == source_id and target == target_id) or (source == target_id and target == source_id))

## Deterministic checkpoint/loss pose. Surviving identities are never renumbered.
func sample(source: String, target: String, elapsed_ticks: int, survivors: Array = []) -> Dictionary:
	if not accepts(source, target) or elapsed_ticks < 0 or elapsed_ticks > TICKS:
		return {}
	var seconds := float(elapsed_ticks) / 10.0
	var path: RefCounted = schedule if source == source_id else reverse_schedule
	return _select(path.sample(seconds), survivors)

## Display cursor may lag authority to preserve safe chords across phase knots.
## Call again against the same confirmed tick to finish those knots.
func advance(source: String, target: String, elapsed_ticks: int, cursor: float) -> Dictionary:
	if not accepts(source, target) or elapsed_ticks < 0 or elapsed_ticks > TICKS \
			or not is_finite(cursor) or cursor < 0.0 or cursor > SECONDS:
		return {"ok": false}
	var confirmed := float(elapsed_ticks) / 10.0
	if cursor > confirmed + 0.000000001:
		return {"ok": false}
	cursor = minf(cursor, confirmed)
	var path: RefCounted = schedule if source == source_id else reverse_schedule
	var position: Dictionary = path.sample(cursor)
	var next: float = path.advance(cursor, confirmed, position)
	return {"ok": true, "cursor": next, "positions": path.sample(next)}

func _select(points: Dictionary, survivors: Array) -> Dictionary:
	if survivors.is_empty():
		return points
	var selected := {}
	for id: Variant in survivors:
		if not id is String or not points.has(id) or selected.has(id):
			return {}
		selected[id] = points[id]
	return selected
