extends RefCounted

# Fleet movement settings from fleet_simulator.html. Godot yaw is positive toward -Z.
const LENGTHS := [0.75, 1.30, 0.90, 0.80, 1.05, 0.48, 0.40, 0.18]
const STEP := 1.0 / 90.0
const EXTRA_DELAYS := [0.0, 0.18, 0.32, 0.50]

class Leg:
	var start: Vector3
	var target: Vector3
	var delta: Vector3
	var bend: Vector3
	var delay: float
	var duration: float
	var start_yaw: float
	var start_pitch: float
	var final_yaw: float
	var turn_start: float
	var turn_end: float
	var rear := false
	var samples := PackedVector3Array()

	func progress(time: float) -> float:
		return clampf((time - delay) / duration, 0.0, 1.0)

	func position_at(time: float) -> Vector3:
		var q := ease_flight(progress(time))
		var lift := 4.0 * q * (1.0 - q) if rear else 16.0 * q * q * (1.0 - q) * (1.0 - q)
		return start + delta * q + bend * lift

	func attitude_at(time: float) -> Vector3:
		var u := progress(time)
		var turn := ease_flight(inverse_lerp(turn_start, turn_end, u))
		var yaw := lerp_angle(start_yaw, final_yaw, turn)
		var pitch := start_pitch * (1.0 - turn)
		var q := ease_flight(u)
		var slope := 4.0 * (1.0 - 2.0 * q) if rear else 32.0 * q * (1.0 - q) * (1.0 - 2.0 * q)
		var tangent := delta + bend * slope
		var authority := ease_flight(tangent.length() / 2.0) * ease_flight((u - 0.05) / 0.22) \
			* (1.0 - ease_flight((u - 0.44) / 0.30))
		var horizontal := Vector3(tangent.x, 6.0, tangent.z).length()
		var lateral := tangent.dot(Basis(Vector3.UP, yaw).z)
		yaw -= authority * (0.23 if turn_start > 0.0 else 0.42) * lateral / horizontal
		pitch += clampf(atan2(tangent.y, horizontal) - pitch, -0.34, 0.34) * authority
		return Vector3(yaw, pitch, authority)


	static func ease_flight(value: float) -> float:
		var t := clampf(value, 0.0, 1.0)
		return t * t * t * (10.0 + t * (-15.0 + 6.0 * t))


static func footprint(poses: PackedVector3Array, radii: PackedFloat32Array) -> Vector3:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for i in poses.size():
		var center := Vector2(poses[i].x, poses[i].z)
		var radius := Vector2.ONE * radii[i]
		low = low.min(center - radius)
		high = high.max(center + radius)
	var middle := (low + high) * 0.5
	return Vector3(middle.x, 0.0, middle.y)


static func formation(slots: Array[Vector3], radii: PackedFloat32Array, goal: Vector3,
		yaw: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	var basis := Basis(Vector3.UP, yaw)
	for slot in slots:
		result.append(basis * slot)
	var shift := goal - footprint(result, radii)
	for i in result.size():
		result[i] += shift
	return result


static func plan(starts: PackedVector3Array, targets: PackedVector3Array, roles: Array[int],
		radii: PackedFloat32Array, yaws: PackedFloat32Array, pitches: PackedFloat32Array,
		yaw_rates: PackedFloat64Array, pitch_rates: PackedFloat64Array, final_yaw: float,
		rear: bool, route_yaw: float, align_after: bool) -> Array[Leg]:
	var paths: Array[Leg] = []
	var longest := 0.0
	var attitude_time := 0.0
	var parallel := true
	var first_delta := targets[0] - starts[0]
	for i in starts.size():
		var delta := targets[i] - starts[i]
		longest = maxf(longest, delta.length())
		parallel = parallel and delta.distance_to(first_delta) < 0.19
		if not align_after:
			var rotation := absf(angle_difference(yaws[i], final_yaw))
			attitude_time = maxf(attitude_time, 2.55 * rotation + 1.6 * absf(pitches[i]) + 1.7)
	var step := clampf(longest / 640.0, 0.11, 3.0)
	var rear_time := 1.95 * absf(angle_difference(route_yaw, final_yaw)) + 0.6 if rear else 0.0
	var base_time := maxf(maxf(3.7, attitude_time), maxf(rear_time / 0.49,
		maxf(1.875 * (longest + 10.0) / 9.7, sqrt(5.8 * (longest + 10.0) / 4.4))))

	var bends: Array[Vector2] = [Vector2.ZERO]
	for level in range(1, 18):
		for direction: float in [1.0, -1.0]:
			var amount := direction * float(level)
			bends.append(Vector2(0.0, amount * 1.45))
			bends.append(Vector2(amount * 1.32, 0.0))
			bends.append(Vector2(-amount * 0.83, amount * 1.12))
			bends.append(Vector2(amount * 0.83, amount * 1.12))
	var options := PackedVector3Array()
	if rear:
		for delay: float in EXTRA_DELAYS:
			for bend in bends:
				options.append(Vector3(bend.x, bend.y, delay))
	else:
		for bend in bends:
			for delay: float in EXTRA_DELAYS:
				options.append(Vector3(bend.x, bend.y, delay))
	for i in starts.size():
		var leg := Leg.new()
		leg.start = starts[i]
		leg.target = targets[i]
		leg.delta = targets[i] - starts[i]
		leg.rear = rear
		leg.duration = base_time + (i % 9) * (0.004 if parallel else 0.095)
		leg.final_yaw = final_yaw
		leg.turn_end = 0.96 if rear else 0.82
		leg.turn_start = leg.turn_end - rear_time / leg.duration if rear else 0.0
		var side := Vector3(leg.delta.x, 0.0, leg.delta.z).normalized().cross(Vector3.UP)
		if side.is_zero_approx():
			side = Vector3.BACK
		for option in options:
			leg.bend = side * option.x + Vector3.UP * option.y
			leg.start_yaw = yaws[i]
			leg.start_pitch = pitches[i]
			var ready := (i % 7) * (0.004 if parallel else 0.045)
			if rear:
				var departure := leg.delta + 4.0 * leg.bend
				var planar := Vector2(departure.x, departure.z).length()
				leg.start_yaw = atan2(-departure.z, departure.x) if planar > 0.01 else route_yaw
				leg.start_pitch = atan2(departure.y, maxf(0.01, planar))
				ready = _launch_delay(Vector2(yaws[i], pitches[i]), Vector2(yaw_rates[i], pitch_rates[i]),
					Vector2(leg.start_yaw, leg.start_pitch), angular_limit(roles[i]))
			leg.delay = ready + option.z
			var count := ceili((leg.delay + leg.duration) / step) + 1
			leg.samples.resize(count)
			for sample in count:
				leg.samples[sample] = leg.position_at(sample * step)
			var clear := true
			for j in paths.size():
				var other := paths[j]
				var gap := minf(leg.start.distance_to(other.start), leg.target.distance_to(other.target))
				var radius := radii[i] + radii[j]
				var margin := clampf(gap - radius - 0.04, 0.11, 0.40)
				if not _clear(leg.samples, other.samples, radius + margin):
					clear = false
					break
			if clear:
				paths.append(leg)
				break
		if paths.size() != i + 1:
			return []
	for leg in paths:
		leg.samples.clear()
	return paths


static func angular_limit(role: int) -> float:
	return lerpf(1.55, 0.86, LENGTHS[role] / 1.4)


static func _launch_delay(pose: Vector2, rates: Vector2, target: Vector2, limit: float) -> float:
	for step in 1200:
		var error := Vector2(angle_difference(pose.x, target.x), target.y - pose.y)
		if absf(error.x) <= 0.009 and absf(error.y) <= 0.009 \
				and absf(rates.x) <= 0.05 and absf(rates.y) <= 0.05:
			return step * STEP
		rates.x = move_toward(rates.x, clampf(error.x * 5.0, -limit, limit), 4.0 * STEP)
		rates.y = move_toward(rates.y, clampf(error.y * 5.0, -limit, limit), 4.0 * STEP)
		pose += rates * STEP
	return 1200 * STEP


static func _clear(a: PackedVector3Array, b: PackedVector3Array, clearance: float) -> bool:
	var end_a := a.size() - 1
	var end_b := b.size() - 1
	var limit := clearance * clearance
	var previous := a[0] - b[0]
	for i in range(1, maxi(end_a, end_b) + 1):
		var difference := a[mini(i, end_a)] - b[mini(i, end_b)]
		var displacement := difference - previous
		var segment := clampf(-previous.dot(displacement) / (displacement.length_squared() + 1e-12), 0.0, 1.0)
		if (previous + segment * displacement).length_squared() < limit:
			return false
		previous = difference
	return true
