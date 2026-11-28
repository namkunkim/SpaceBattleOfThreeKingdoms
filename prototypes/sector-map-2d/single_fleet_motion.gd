extends RefCounted

const Paths := preload("res://single_fleet_paths.gd")
const BRAKE_RATE := 0.95
const HEADING_SIMILAR := deg_to_rad(30.0)
const FRONT_LIMIT := deg_to_rad(45.0)
const REAR_LIMIT := deg_to_rad(135.0)
const REVERSED := deg_to_rad(165.0)
const CRUISE_SPEED := 14.0
const BRAKING := 8.0
const RESPONSE := [2.4, 1.9, 2.2, 2.0, 1.8, 4.2, 3.1, 4.8]

enum Phase { IDLE, BRAKE, ROUTE, ALIGN, REJOIN }
enum Maneuver { STANDARD, FORWARD, FLANK, FRONT_REVERSE, REAR_LONG }

class ShipRoute:
	var waypoints := PackedVector3Array()
	var next := 0
	var velocity := Vector3.ZERO
	var departure_altitude_sign := 1.0
	var cleared_departure_gate := false
	var entry_altitude_sign := 1.0
	var cleared_entry_gate := false

var position: Vector3
var destination: Vector3
var yaw := 0.0
var speed := 0.0
var moving := false
var turning := false
var has_arrival_yaw := false
var arrival_yaw := 0.0
var phase := Phase.IDLE
var maneuver := Maneuver.STANDARD
var plan_failed := false
var positions := PackedVector3Array()
var headings := PackedFloat32Array()
var pitches := PackedFloat32Array()
var banks := PackedFloat32Array()

var _slots: Array[Vector3]
var _roles: Array[int]
var _slot_samples := PackedVector3Array()
var _slot_velocities := PackedVector3Array()
var _bow_rates := PackedFloat64Array()
var _pitch_rates := PackedFloat64Array()
var _radii := PackedFloat32Array()
var _clearance := PackedFloat32Array()
var _ship_routes: Dictionary[int, ShipRoute] = {}
var _legs: Array[Paths.Leg] = []
var _clock := 0.0
var _end := 0.0
var _clock_rate := 1.0
var _align_on_arrival := false
var _requested_facing: Variant = null


func _init(anchor: Node3D, slots: Array[Vector3], roles: Array[int]) -> void:
	_roles = roles
	_slots = slots
	for i in slots.size():
		positions.append(anchor.transform * slots[i])
		_slot_velocities.append(Vector3.ZERO)
		headings.append(anchor.rotation.y)
		pitches.append(0.0)
		banks.append(0.0)
		_bow_rates.append(0.0)
		_pitch_rates.append(0.0)
		_radii.append(0.16 + Paths.LENGTHS[roles[i]] * 0.32)
		var gap := INF
		for j in slots.size():
			if i != j:
				gap = minf(gap, slots[i].distance_to(slots[j]))
		_clearance.append(minf(1.2, 0.66 * gap))
	_slot_samples = positions.duplicate()
	yaw = anchor.rotation.y
	position = Paths.footprint(_slot_samples, _radii)
	destination = position
	anchor.position = position


func move_to(_anchor: Node3D, point: Vector3, facing: Variant = null) -> void:
	destination = Vector3(point.x, position.y, point.z)
	_requested_facing = facing
	has_arrival_yaw = facing != null
	if has_arrival_yaw:
		arrival_yaw = float(facing)
	plan_failed = false
	moving = true
	turning = false
	if not _legs.is_empty() and _clock < _end:
		phase = Phase.BRAKE
	else:
		_begin_plan()


func face(anchor: Node3D, point: Vector3) -> void:
	var offset := point - position
	if offset.length_squared() > 0.0036:
		move_to(anchor, position, atan2(-offset.z, offset.x))


# An independent route temporarily takes priority over the corresponding reserved formation slot.
func set_ship_route(index: int, waypoints: PackedVector3Array) -> bool:
	if index < 0 or index >= positions.size() or waypoints.is_empty():
		return false
	for point in waypoints:
		if not point.is_finite():
			return false
	if not _ship_routes.has(index):
		var route := ShipRoute.new()
		route.velocity = _slot_velocities[index]
		route.departure_altitude_sign = -1.0 if waypoints[0].y < _slot_samples[index].y else 1.0
		_ship_routes[index] = route
	var route := _ship_routes[index]
	route.waypoints = waypoints.duplicate()
	route.next = 0
	route.entry_altitude_sign = -1.0 if waypoints[-1].y < _slot_samples[index].y else 1.0
	route.cleared_entry_gate = false
	if phase == Phase.IDLE:
		phase = Phase.REJOIN
	moving = true
	return true


func stop() -> void:
	for route in _ship_routes.values():
		route.next = route.waypoints.size()
		route.velocity = Vector3.ZERO
	_legs.clear()
	_slot_velocities.fill(Vector3.ZERO)
	_bow_rates.fill(0.0)
	_pitch_rates.fill(0.0)
	speed = 0.0
	phase = Phase.IDLE
	turning = false
	has_arrival_yaw = false
	moving = false


func advance(anchor: Node3D, delta: float) -> void:
	if delta <= 0.0:
		return
	var steps := maxi(1, ceili(delta / Paths.STEP))
	var step := delta / steps
	for i in steps:
		if not moving:
			break
		match phase:
			Phase.BRAKE, Phase.ROUTE:
				_advance_flight(step)
			Phase.ALIGN:
				_align(step)
			Phase.REJOIN:
				_advance_independent_routes(step)
	anchor.position = position
	anchor.rotation.y = yaw


func has_fleet_order() -> bool:
	return phase == Phase.BRAKE or phase == Phase.ROUTE


func status_text() -> String:
	if plan_failed:
		return "함선 간격을 확보할 항로가 없습니다"
	match phase:
		Phase.BRAKE:
			return "감속 후 새 항로 준비 중"
		Phase.ALIGN:
			return "제자리 방향 정렬 중"
		Phase.ROUTE:
			match maneuver:
				Maneuver.FORWARD: return "선수를 유지한 전방 이동"
				Maneuver.FLANK: return "선수를 유지한 측면 이동"
				Maneuver.FRONT_REVERSE: return "전방 이동 후 방향 반전"
				Maneuver.REAR_LONG: return "함선별 정렬 후 후방 장거리 이동"
			return "개별 항로로 이동 중"
		Phase.REJOIN:
			return "개별 항로 진행 중"
	return "대기 중"


func _begin_plan() -> void:
	var displacement := destination - position
	var current := _average_heading()
	var translating := displacement.length() > 0.06
	var travel_yaw := atan2(-displacement.z, displacement.x) if translating else current
	arrival_yaw = float(_requested_facing) if has_arrival_yaw else travel_yaw
	var travel_angle := absf(angle_difference(current, travel_yaw))
	var finish_angle := absf(angle_difference(current, arrival_yaw))
	maneuver = Maneuver.STANDARD
	if translating:
		var similar := finish_angle <= HEADING_SIMILAR
		if travel_angle <= FRONT_LIMIT and similar:
			maneuver = Maneuver.FORWARD
		elif has_arrival_yaw and travel_angle <= FRONT_LIMIT and finish_angle >= REVERSED:
			maneuver = Maneuver.FRONT_REVERSE
		elif has_arrival_yaw and travel_angle > FRONT_LIMIT and travel_angle < REAR_LIMIT and similar:
			maneuver = Maneuver.FLANK
		elif has_arrival_yaw and similar and travel_angle >= REAR_LIMIT 				and displacement.length() >= maxf(65.0, 3.0 * _length_along(current)):
			maneuver = Maneuver.REAR_LONG
	_align_on_arrival = maneuver in [Maneuver.FORWARD, Maneuver.FRONT_REVERSE, Maneuver.FLANK]
	var targets := Paths.formation(_slots, _radii, destination, arrival_yaw)
	var reshaping := false
	if has_arrival_yaw:
		for i in targets.size():
			reshaping = reshaping or targets[i].distance_to(_slot_samples[i]) > 0.06
	if not translating and not reshaping:
		_legs.clear()
		if has_arrival_yaw:
			phase = Phase.ALIGN
			turning = true
		else:
			_finish_flight()
		return
	_legs = Paths.plan(_slot_samples, targets, _roles, _radii, headings, pitches, _bow_rates,
		_pitch_rates, arrival_yaw, maneuver == Maneuver.REAR_LONG, travel_yaw, _align_on_arrival)
	if _legs.is_empty():
		plan_failed = true
		_finish_flight()
		return
	_clock = 0.0
	_end = 0.0
	for path in _legs:
		_end = maxf(_end, path.delay + path.duration)
	_clock_rate = 1.0
	phase = Phase.ROUTE


func _advance_flight(delta: float) -> void:
	var braking := phase == Phase.BRAKE
	if braking:
		var next_rate := move_toward(_clock_rate, 0.0, BRAKE_RATE * delta)
		_clock = minf(_end, _clock + (_clock_rate + next_rate) * 0.5 * delta)
		_clock_rate = next_rate
	else:
		_clock = minf(_end, _clock + delta)
	var settled := true
	var actual_turning := false
	var previous_position := position
	for i in _legs.size():
		var path := _legs[i]
		var target := path.position_at(_clock)
		if _move_ship(i, target, delta):
			if _align_on_arrival:
				if _clock >= path.delay + path.duration:
					var docked := _steer_attitude(i, path.final_yaw, 0.0, delta)
					settled = settled and docked
					actual_turning = actual_turning or not docked
				else:
					headings[i] = path.start_yaw
					pitches[i] = path.start_pitch
					_bow_rates[i] = 0.0
					_pitch_rates[i] = 0.0
				banks[i] = 0.0
			elif path.rear and _clock < path.delay:
				_steer_attitude(i, path.start_yaw, path.start_pitch, delta)
				banks[i] = 0.0
			else:
				var attitude := path.attitude_at(_clock)
				_bow_rates[i] = angle_difference(headings[i], attitude.x) / delta
				_pitch_rates[i] = (attitude.y - pitches[i]) / delta
				headings[i] = attitude.x
				pitches[i] = attitude.y
				banks[i] = clampf(_bow_rates[i] * 0.23, -0.27, 0.27) * attitude.z
	position = Paths.footprint(_slot_samples, _radii)
	speed = position.distance_to(previous_position) / delta
	yaw = _average_heading()
	turning = not braking and _clock >= _end and actual_turning
	if braking and (_clock_rate <= 0.0 or _clock >= _end):
		_slot_velocities.fill(Vector3.ZERO)
		speed = 0.0
		_begin_plan()
	elif not braking and _clock >= _end and settled:
		position = destination
		yaw = arrival_yaw
		_finish_flight()


func _align(delta: float) -> void:
	var aligned := true
	for i in headings.size():
		var ready := _steer_attitude(i, arrival_yaw, 0.0, delta)
		aligned = aligned and ready
	yaw = _average_heading()
	if aligned:
		_finish_flight()


func _steer_attitude(i: int, desired_yaw: float, pitch: float, delta: float) -> bool:
	var limit := Paths.angular_limit(_roles[i])
	var error := angle_difference(headings[i], desired_yaw)
	var pitch_error := pitch - pitches[i]
	if absf(error) < 0.009 and absf(pitch_error) < 0.009 			and absf(_bow_rates[i]) < 0.05 and absf(_pitch_rates[i]) < 0.05:
		headings[i] = desired_yaw
		pitches[i] = pitch
		_bow_rates[i] = 0.0
		_pitch_rates[i] = 0.0
		return true
	_bow_rates[i] = move_toward(_bow_rates[i], clampf(error * 5.0, -limit, limit), 4.0 * delta)
	_pitch_rates[i] = move_toward(_pitch_rates[i], clampf(pitch_error * 5.0, -limit, limit), 4.0 * delta)
	headings[i] += _bow_rates[i] * delta
	pitches[i] = clampf(pitches[i] + _pitch_rates[i] * delta, -PI * 0.5, PI * 0.5)
	return false


func _average_heading() -> float:
	var direction := Vector2.ZERO
	for angle in headings:
		direction += Vector2.from_angle(angle)
	return direction.angle() if direction.length_squared() > 0.0001 else yaw


func _length_along(heading: float) -> float:
	var axis := Basis(Vector3.UP, heading).x
	var front := -INF
	var rear := INF
	for ship in _slot_samples:
		var distance := ship.dot(axis)
		front = maxf(front, distance)
		rear = minf(rear, distance)
	return front - rear


func _move_ship(index: int, target: Vector3, delta: float) -> bool:
	var velocity := (target - _slot_samples[index]) / delta
	_slot_samples[index] = target
	_slot_velocities[index] = velocity
	if _ship_routes.has(index):
		if not _follow_ship_route(index, target, velocity, delta):
			return false
		_ship_routes.erase(index)
	positions[index] = target
	return true


func _finish_flight() -> void:
	_legs.clear()
	_slot_velocities.fill(Vector3.ZERO)
	speed = 0.0
	turning = false
	if _ship_routes.is_empty():
		stop()
	else:
		phase = Phase.REJOIN


func _advance_independent_routes(delta: float) -> void:
	for index in _ship_routes.keys():
		_move_ship(index, _slot_samples[index], delta)
	if _ship_routes.is_empty():
		stop()


func _follow_ship_route(index: int, slot: Vector3, slot_velocity: Vector3, delta: float) -> bool:
	var route := _ship_routes[index]
	while route.next < route.waypoints.size() and positions[index].distance_to(route.waypoints[route.next]) < 0.4:
		route.next += 1
	var rejoining := route.next >= route.waypoints.size()
	var target := slot
	var free_flight := false
	var departing := not route.cleared_departure_gate
	if departing:
		# Keep the moving slot's horizontal pose while leaving the occupied decks.
		target.y = position.y + route.departure_altitude_sign * 4.5
		route.cleared_departure_gate = absf(positions[index].y - position.y) > 3.8
	elif rejoining:
		if not route.cleared_entry_gate:
			target.y = position.y + route.entry_altitude_sign * 5.0
			route.cleared_entry_gate = positions[index].distance_to(target) < 0.14 \
				and route.velocity.distance_to(slot_velocity) < 0.5
	else:
		target = route.waypoints[route.next]
		free_flight = true
	var offset := target - positions[index]
	var response: float = RESPONSE[_roles[index]]
	var top_speed := CRUISE_SPEED * (1.10 + response * 0.06)
	var desired := (slot_velocity + offset * 2.2).limit_length(top_speed)
	if free_flight:
		desired = offset.normalized() * minf(top_speed, sqrt(2.0 * BRAKING * offset.length()))

	# Deflect around nearby hulls in 3D while the formation itself keeps its course.
	var separation := Vector3.ZERO
	for neighbor in positions.size():
		if neighbor == index:
			continue
		var away := positions[index] - positions[neighbor]
		var clearance := maxf(_clearance[index], _clearance[neighbor])
		var lookahead := away + (desired - _neighbor_velocity(neighbor, slot_velocity)) * 0.18
		if away.length_squared() < clearance * clearance * 9.0:
			var closing := smoothstep(0.0, clearance * 0.45, away.length() - lookahead.length())
			var pressure := closing * (1.0 - smoothstep(clearance, clearance * 1.45, lookahead.length()))
			separation += away.normalized() * (desired.length() * pressure)
	desired = (desired + separation.limit_length(top_speed)).limit_length(top_speed)
	route.velocity = route.velocity.move_toward(desired, (BRAKING + response) * delta)
	var candidate := positions[index] + route.velocity * delta
	if departing:
		route.velocity.x = slot_velocity.x
		route.velocity.z = slot_velocity.z
		candidate.x = slot.x
		candidate.z = slot.z
	for neighbor in positions.size():
		if neighbor == index:
			continue
		var clearance := maxf(_clearance[index], _clearance[neighbor])
		var gap := candidate.distance_to(positions[neighbor])
		if gap < clearance and gap < positions[index].distance_to(positions[neighbor]):
			route.velocity = route.velocity.move_toward(Vector3.ZERO, BRAKING * delta)
			if departing:
				candidate.y = positions[index].y
				route.velocity.y = 0.0
			else:
				candidate = positions[index]
			break
	positions[index] = candidate
	var target_bow: float = headings[index]
	if rejoining and route.cleared_entry_gate:
		target_bow = yaw
	elif Vector2(route.velocity.x, route.velocity.z).length_squared() > 0.16:
		target_bow = atan2(-route.velocity.z, route.velocity.x)
	headings[index] = rotate_toward(headings[index], target_bow, deg_to_rad(35.0 + 12.0 * response) * delta)
	return rejoining and route.cleared_entry_gate and positions[index].distance_squared_to(slot) < 0.0025 \
		and route.velocity.distance_to(slot_velocity) < 0.5 and absf(angle_difference(headings[index], yaw)) < 0.025


func _neighbor_velocity(index: int, fleet_velocity: Vector3) -> Vector3:
	if _ship_routes.has(index):
		return _ship_routes[index].velocity
	return fleet_velocity
