extends RefCounted

const FEATURE := "red_cliffs_a04_trial_v1"

# This opt-in evaluates a proposed route against the active battle state.
# Candidate regions and hard blockers are explicit inputs in effective world units.
static func assess(sim: BattleSim, feature: String, fleet: FleetState, radius: float,
		target: Dictionary, blockers: Array[Rect2]) -> String:
	if feature != FEATURE:
		return "disabled"
	if sim == null or sim.profile_id != "red-cliffs-208-rt" or fleet == null or not sim.st.fleets.has(fleet):
		return "unsupported_battle"
	if not is_finite(radius) or radius <= 0.0:
		return "invalid_envelope"
	if not target.has_all(["kind", "id", "center", "radius"]) or not target.center is Vector2 or not (target.radius is float or target.radius is int):
		return "invalid_region"
	var center: Vector2 = target.center
	var region_radius: float = target.radius
	if not center.is_finite() or not is_finite(region_radius) or region_radius < radius:
		return "region_too_small"
	if target.kind == "supply":
		var authorized := false
		for base in sim.supply.bases:
			if base.key == target.id and base.side == fleet.side and sim.supply.allied(base.faction, fleet.faction):
				authorized = true
		if not authorized:
			return "supply_not_authorized"
	elif target.kind != "exit" or target.id != fleet.side:
		return "exit_not_authorized"
	if not inside_wall(fleet.pos, radius, sim.rs.world):
		return "spawn_outside_envelope"
	if not inside_wall(center, radius, sim.rs.world):
		return "target_outside_envelope"
	for blocker in blockers:
		# Rectangular dilation conservatively rejects paths around corners.
		if crosses_rect(fleet.pos, center, blocker.grow(radius)):
			return "obstructed"
	return "clear"


static func inside_wall(center: Vector2, radius: float, extent: Vector2) -> bool:
	return minf(minf(center.x, center.y), minf(extent.x - center.x, extent.y - center.y)) >= radius


static func crosses_rect(start: Vector2, finish: Vector2, rect: Rect2) -> bool:
	var low := 0.0
	var high := 1.0
	var delta := finish - start
	for axis in 2:
		if is_zero_approx(delta[axis]):
			if start[axis] < rect.position[axis] or start[axis] > rect.end[axis]:
				return false
			continue
		var a := (rect.position[axis] - start[axis]) / delta[axis]
		var b := (rect.end[axis] - start[axis]) / delta[axis]
		low = maxf(low, minf(a, b))
		high = minf(high, maxf(a, b))
		if low > high:
			return false
	return true


# Continuous closest approach for two linear traversals over the same interval.
static func simultaneous_clear(a_start: Vector2, a_end: Vector2, a_radius: float,
		b_start: Vector2, b_end: Vector2, b_radius: float) -> bool:
	var start := a_start - b_start
	var delta := a_end - b_end - start
	var fraction := 0.0
	if not delta.is_zero_approx():
		fraction = clampf(-start.dot(delta) / delta.length_squared(), 0.0, 1.0)
	return (start + delta * fraction).length() > a_radius + b_radius

