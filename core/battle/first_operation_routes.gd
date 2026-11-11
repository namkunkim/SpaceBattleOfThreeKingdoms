extends RefCounted

const FRONT_ENGAGEMENT_OFFSET := Vector2(56, 18)
const FRONT_RESERVE_ENGAGEMENT_POINT := Vector2(1355, 505)

var _policy: RefCounted
var _definition: Dictionary
var _route: String
var _points: Dictionary
var _roster := {}

func _init(policy: RefCounted, definition: Dictionary, route: String) -> void:
	_policy = policy
	_definition = definition
	_route = route
	_points = {route: policy.route_points(route), "reinforcement": policy.route_points("reinforcement")}
	if route == "front":
		# Tactical stopping point inside the last leg's swept clearance.
		# The policy retains the authored approach point and validates every step.
		_points.front[-1] += FRONT_ENGAGEMENT_OFFSET
		# The reserve still enters at R and follows the validated R–C leg.
		# This stop puts it in both allied firing arcs without overlapping C.
		_points.reinforcement[-1] = FRONT_RESERVE_ENGAGEMENT_POINT
	for row in definition.fleets:
		_roster[row.id] = row

func points(route := "") -> Array:
	return _points[_route if route.is_empty() else route].duplicate()

func start(route: String, proceed: bool) -> Dictionary:
	return {"center": _points[route][0], "reached": 0, "next": 1,
		"goal": _points[route].size() - 1 if proceed else 0, "reverse": false}

func target(point: Vector2) -> int:
	for i in range(1, _points[_route].size()):
		if point.distance_to(_points[_route][i]) <= _definition.space.center_tolerance:
			return i
	return -1

func order(progress: Dictionary, goal: int) -> void:
	progress.goal = goal
	progress.next = progress.reached + 1

func reverse(progress: Dictionary) -> void:
	progress.reverse = true
	progress.goal = 0
	progress.next = progress.reached
	if progress.center.is_equal_approx(_points[_route][progress.reached]):
		progress.next -= 1

func stop(progress: Dictionary) -> void:
	progress.goal = -1

func advance(fleets: Array[FleetState], progress: Dictionary, elapsed_ms: int) -> Dictionary:
	var next := progress.duplicate(true)
	var moves := {}
	for fleet in fleets:
		if fleet.dead or fleet.out:
			continue
		moves[fleet.sq_id] = {
			"from": fleet.pos, "to": fleet.pos, "heading_from": fleet.heading,
			"heading_to": fleet.heading, "formation_id": fleet.formation_id,
		}
	if moves.is_empty():
		return {"ok": true, "moves": moves, "progress": next}
	_plan_group(fleets, moves, next, _route, elapsed_ms)
	if next.has("reinforcement"):
		_plan_group(fleets, moves, next, "reinforcement", elapsed_ms)
	var verdict: Dictionary = _policy.validate_movement(moves, 0, elapsed_ms)
	if not verdict.ok:
		return verdict
	return {"ok": true, "moves": moves, "progress": next}

func _plan_group(fleets: Array[FleetState], moves: Dictionary, progress: Dictionary, route: String, elapsed_ms: int) -> void:
	var state: Dictionary = progress[route]
	if state.goal < 0:
		return
	if state.goal == state.reached and state.center.is_equal_approx(_points[route][state.goal]):
		if _route == "front" and not state.reverse and state.goal == _points[route].size() - 1:
			_face_engagement(fleets, moves, route, state.center, elapsed_ms)
		return
	var index: int = state.next
	var points_for_route: Array = _points[route]
	if index < 0 or index >= points_for_route.size():
		return
	var center: Vector2 = state.center
	var destination: Vector2 = points_for_route[index]
	var seconds := elapsed_ms / 1000.0
	var maximum_turn := deg_to_rad(float(_definition.space.motion.max_turn_deg_per_s)) * seconds
	var heading := (destination - center).angle()
	var group: Array[FleetState] = []
	var turning := false
	for fleet in fleets:
		if not moves.has(fleet.sq_id) or not _on_route(fleet, route):
			continue
		group.append(fleet)
		turning = turning or absf(angle_difference(fleet.heading, heading)) > 0.00001
	if group.is_empty():
		return
	var step := float(_definition.space.motion.max_speed_per_s) * seconds * 0.999
	var next_center := center if turning else center.move_toward(destination, step)
	for fleet in group:
		var move: Dictionary = moves[fleet.sq_id]
		var offset: Array = _roster[fleet.sq_id].offset_xy
		move.plan_from = center
		move.plan_to = next_center
		move.route_id = route
		move.reverse = state.reverse
		move.leg = points_for_route.size() - 2 - index if state.reverse else index - 1
		if turning:
			move.heading_to = rotate_toward(fleet.heading, heading, maximum_turn)
		else:
			move.to = next_center + Vector2(offset[0], offset[1])
	state.center = next_center
	if next_center == destination:
		state.reached = index
		state.next += -1 if state.reverse else 1

func _face_engagement(fleets: Array[FleetState], moves: Dictionary, route: String,
		center: Vector2, elapsed_ms: int) -> void:
	var node: Array = _definition.space.nodes.C
	var objective := Vector2(node[0], node[1])
	var reinforcement: Vector2 = _points.reinforcement[-1]
	var turn := deg_to_rad(float(_definition.space.motion.max_turn_deg_per_s)) * elapsed_ms / 1000.0
	for fleet in fleets:
		if not _on_route(fleet, route) or not moves.has(fleet.sq_id):
			continue
		var aim := fleet.pos.angle_to_point(objective)
		if route == "front":
			aim = (fleet.pos.direction_to(objective) + fleet.pos.direction_to(reinforcement)).angle()
		var move: Dictionary = moves[fleet.sq_id]
		move.plan_from = center
		move.plan_to = center
		move.route_id = route
		move.leg = _points[route].size() - 2
		move.heading_to = rotate_toward(fleet.heading, aim, turn)

func _on_route(fleet: FleetState, route: String) -> bool:
	return (_roster[fleet.sq_id].spawn == "R") if route == "reinforcement" else fleet.side == 0
