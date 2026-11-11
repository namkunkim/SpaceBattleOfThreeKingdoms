extends RefCounted

const TRACK := 2.0
const SAFETY := 1.0
const DT := 0.1
const SPEED := 20.0
const TURN := deg_to_rad(36.0) * DT
const EPS := 0.00001

var data: Dictionary
var route_id := ""
var points: Array[Vector2] = []
var offsets: Array[Vector2] = []
var radii: Array[float] = []
var state: Dictionary = {}
var neck := false
var inaccessible_service := false


func _init(manifest: Dictionary) -> void:
	data = manifest


static func vec(v: Array) -> Vector2:
	return Vector2(v[0], v[1])


func node(id: String) -> Vector2:
	return vec(data.nodes[id])


func _positions(plan: Vector2) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for offset in offsets:
		positions.append(plan + offset)
	return positions


func _radius(id: String) -> float:
	return float(data.radii[id]) + TRACK + SAFETY


func start(id: String, use_neck := false, bad_service := false) -> String:
	if id not in ["EJAC", "EJBDC", "RC"]:
		return "unknown_route"
	var entry: Vector2 = node("R" if id == "RC" else "E")
	var spawn_radius: float = float(data.regions.R_DEPLOY if id == "RC" else data.regions.E_DEPLOY)
	var next_offsets: Array[Vector2] = [Vector2.ZERO]
	var next_radii: Array[float] = [_radius("RC-CAO-SQ-05")]
	if id != "RC":
		var offset := Vector2(0.0, float(data.offset))
		next_offsets = [-offset, offset]
		next_radii = [_radius("RC-LIU-SQ-01"), _radius("RC-LIU-SQ-02")]
	for i in next_offsets.size():
		if next_offsets[i].length() + next_radii[i] > spawn_radius:
			return "entry_clearance"
		if not _inside_world(entry + next_offsets[i], next_radii[i]):
			return "entry_world"
	if next_offsets.size() == 2 and next_offsets[0].distance_to(next_offsets[1]) < next_radii[0] + next_radii[1]:
		return "entry_interfleet"
	route_id = id
	neck = use_neck
	inaccessible_service = bad_service
	offsets = next_offsets
	radii = next_radii
	points.clear()
	for p in data.witness[id].points:
		points.append(vec(p))
	state = {"plan": entry, "positions": _positions(entry), "index": 0,
		"heading": (points[1] - entry).angle(), "tick": 0, "moving": false,
		"returning": false, "visits": [], "complete": false}
	return ""


func _inside_world(p: Vector2, radius: float) -> bool:
	var w := vec(data.world)
	var inset := maxf(radius, float(data.edge))
	return p.x >= inset and p.y >= inset and p.x <= w.x - inset and p.y <= w.y - inset


func snapshot() -> Dictionary:
	return state.duplicate(true)


func at_stop() -> bool:
	return state.plan == points[state.index]


func step(perturbation: Array[Vector2] = []) -> String:
	if state.complete or state.index >= points.size() - 1:
		return "finished"
	var index: int = state.index
	var target := points[index + 1]
	var plan: Vector2 = state.plan
	var desired_heading := (target - points[index]).angle()
	var next := snapshot()
	next.tick += 1
	if absf(angle_difference(state.heading, desired_heading)) > EPS:
		next.heading = rotate_toward(state.heading, desired_heading, TURN)
		next.moving = false
	else:
		next.plan = plan.move_toward(target, SPEED * DT)
		next.moving = next.plan != target
		if not next.moving:
			next.index += 1
	next.positions = _positions(next.plan)
	if not perturbation.is_empty():
		if perturbation.size() != next.positions.size():
			return "position_arity"
		for i in next.positions.size():
			next.positions[i] += perturbation[i]
	var problem := _swept(next, points[index], target)
	if problem != "":
		return problem
	state = next
	return ""


func _swept(next: Dictionary, a: Vector2, b: Vector2) -> String:
	var defender := node("C")
	var defender_radius := _radius("RC-CAO-SQ-04")
	var corridor: float = float(data.corridor)
	for i in offsets.size():
		var old: Vector2 = state.positions[i]
		var new: Vector2 = next.positions[i]
		if not new.is_finite() or new.distance_to(next.plan + offsets[i]) > TRACK:
			return "tracking_budget"
		if old.distance_to(new) > SPEED * DT + 0.001:
			return "step_speed"
		# Exact actual endpoints plus separate numeric reserve. The candidate
		# nominal disks used for all other checks already include TRACK.
		var swept_radius := radii[i] - TRACK
		for p: Vector2 in [old, new]:
			if not _inside_world(p, swept_radius):
				return "world_boundary"
			if p.distance_to(Geometry2D.get_closest_point_to_segment(p, a, b)) + swept_radius > corridor:
				return "corridor_clearance"
		if defender.distance_to(Geometry2D.get_closest_point_to_segment(defender, old, new)) < defender_radius + swept_radius:
			return "defender_clearance"
		if neck and route_id == "EJAC" and ((a == node("J") and b == node("A")) or (b == node("J") and a == node("A"))):
			var j := node("J")
			var axis := j.direction_to(node("A"))
			var first := (old - j).dot(axis)
			var last := (new - j).dot(axis)
			var stations: Array = data.witness.negative.throat_station_bounds
			if maxf(first, last) + swept_radius >= float(stations[0]) and minf(first, last) - swept_radius <= float(stations[1]):
				var transverse := axis.orthogonal()
				var cross := maxf(absf((old - j).dot(transverse)), absf((new - j).dot(transverse)))
				if cross + swept_radius > float(data.witness.negative.throat_half_width):
					return "throat_clearance"
	if offsets.size() == 2:
		var old_gap: Vector2 = state.positions[1] - state.positions[0]
		var new_gap: Vector2 = next.positions[1] - next.positions[0]
		var minimum_gap := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, old_gap, new_gap).length()
		if minimum_gap < radii[0] + radii[1] - 2.0 * TRACK:
			return "interfleet_clearance"
	return ""


func visit(kind: String) -> String:
	if state.complete or state.moving or not at_stop():
		return "not_stopped"
	if kind in state.visits:
		return "already_visited"
	var center: Vector2
	var radius: float
	match kind:
		"service":
			if route_id == "RC":
				return "no_service"
			var service_node := node("A" if route_id == "EJAC" else "B")
			if not state.plan.is_equal_approx(service_node):
				return "wrong_service_stop"
			center = vec(data.witness.negative.inaccessible_service_center) if inaccessible_service else service_node
			radius = float(data.witness.negative.inaccessible_service_radius if inaccessible_service else data.regions.SUPPLY)
		"goal":
			if state.returning or state.index != points.size() - 1:
				return "wrong_goal_stop"
			center = node("C")
			radius = float(data.regions.C_GOAL)
		"exit":
			if not state.returning or state.index != points.size() - 1:
				return "wrong_exit_stop"
			center = node("E")
			radius = float(data.regions.E_EXIT)
		_:
			return "unknown_region"
	for p: Vector2 in state.positions:
		if p.distance_to(center) + SAFETY > radius:
			return kind + "_inaccessible"
	var next := snapshot()
	next.visits.append(kind)
	next.complete = kind == "exit" or (route_id == "RC" and kind == "goal")
	state = next
	return ""


func return_to_e() -> String:
	if route_id == "RC" or state.returning or not "goal" in state.visits or state.moving:
		return "cannot_return"
	points.reverse()
	var next := snapshot()
	next.index = 0
	next.returning = true
	state = next
	return ""
