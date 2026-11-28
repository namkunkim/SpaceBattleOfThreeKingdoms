extends RefCounted
## BattleFormation.cpp from the Unreal fleet-control POC, adapted to Godot's X/Z plane.

# Match the POC's 440-unit battleship to the existing 0.75-unit Wu model.
const UNIT := 0.75 / 440.0
const CRUISE := 1050.0 * UNIT
const TURN_RATE := deg_to_rad(20.0)
const GROUP_COUNT := 8
# Max speed, turn rate (degrees/s), acceleration, deceleration, in Wu role order.
# The POC has no siege role, so the siege ship uses the fire-support profile.
const PROFILES := [
	Vector4(1200, 55, 650, 850), Vector4(1150, 50, 550, 780),
	Vector4(1275, 70, 850, 1050), Vector4(1125, 45, 500, 700),
	Vector4(1275, 70, 850, 1050), Vector4(1350, 80, 900, 1100),
	Vector4(1300, 75, 850, 1050), Vector4(1450, 90, 1000, 1200),
]

var slots: Array[Vector3]
var roles: Array[int]
var positions := PackedVector3Array()
var velocities := PackedVector3Array()
var headings := PackedFloat64Array()
var destination := Vector3.ZERO
var speed := 0.0
var course := 0.0
var layout_yaw := 0.0
var arrival_yaw := 0.0
var has_arrival_yaw := false
var moving := false
var turning := false


func _init(anchor: Node3D, formation_slots: Array[Vector3], ship_roles: Array[int]) -> void:
	slots = formation_slots
	roles = ship_roles
	layout_yaw = anchor.rotation.y
	for slot in slots:
		positions.append(anchor.transform * slot)
		velocities.append(Vector3.ZERO)
		headings.append(layout_yaw)


func move_to(anchor: Node3D, target: Vector3, facing: Variant = null) -> void:
	destination = target
	var offset := target - anchor.position
	var at_destination := planar(offset).length() <= UNIT
	course = anchor.rotation.y if at_destination else atan2(-offset.z, offset.x)
	has_arrival_yaw = facing != null
	if has_arrival_yaw:
		arrival_yaw = facing
	turning = has_arrival_yaw and at_destination
	moving = true


func face(anchor: Node3D, target: Vector3) -> void:
	var offset := target - anchor.position
	if planar(offset).length() <= UNIT:
		return
	stop()
	arrival_yaw = atan2(-offset.z, offset.x)
	moving = true
	turning = true


func stop() -> void:
	speed = 0.0
	has_arrival_yaw = false
	velocities.fill(Vector3.ZERO)
	moving = false
	turning = false


func advance(anchor: Node3D, delta: float) -> void:
	var remaining := minf(delta, 0.2)
	while moving and remaining > 0.00000001:
		var step := minf(remaining, 1.0 / 30.0)
		advance_step(anchor, step)
		remaining -= step


func advance_step(anchor: Node3D, step: float) -> void:
	if turning:
		anchor.rotation.y = rotate_toward(anchor.rotation.y, arrival_yaw, TURN_RATE * step)
		var aligned := absf(angle_difference(anchor.rotation.y, arrival_yaw)) <= deg_to_rad(0.001)
		for i in slots.size():
			velocities[i] = Vector3.ZERO
			update_heading(i, anchor.rotation.y, step)
			aligned = aligned and absf(angle_difference(headings[i], arrival_yaw)) <= deg_to_rad(2.0)
		if aligned:
			headings.fill(arrival_yaw)
			stop()
		return

	var previous := Transform3D(Basis(Vector3.UP, layout_yaw), anchor.position)
	anchor.rotation.y = rotate_toward(anchor.rotation.y, course, TURN_RATE * step)
	layout_yaw = rotate_toward(layout_yaw, course, TURN_RATE * step)
	var remaining := planar(destination - anchor.position)
	var distance := remaining.length()
	if distance > UNIT:
		var error := rad_to_deg(absf(angle_difference(anchor.rotation.y, course)))
		var turn_speed := 1.0 - 0.45 * smoothstep(20.0, 100.0, error)
		var target_speed := minf(CRUISE * turn_speed, sqrt(2.0 * 400.0 * UNIT * distance))
		var rate := 420.0 if target_speed > speed else 900.0
		speed = move_toward(speed, target_speed, rate * UNIT * step)
		anchor.position += remaining * (minf(speed * step, distance) / distance)

	var anchor_arrived := planar(destination - anchor.position).length() <= UNIT
	if anchor_arrived:
		anchor.position = destination
		speed = 0.0

	var layout := Transform3D(Basis(Vector3.UP, layout_yaw), anchor.position)
	var previous_positions := positions.duplicate()
	var group_errors: Array[Vector3] = []
	var group_sizes: Array[int] = []
	group_errors.resize(GROUP_COUNT)
	group_errors.fill(Vector3.ZERO)
	group_sizes.resize(GROUP_COUNT)
	group_sizes.fill(0)
	if not anchor_arrived:
		for i in slots.size():
			var group := i % GROUP_COUNT
			group_errors[group] += layout * slots[i] - positions[i]
			group_sizes[group] += 1
		for group in GROUP_COUNT:
			group_errors[group] /= maxi(group_sizes[group], 1)

	var all_arrived := anchor_arrived
	for i in slots.size():
		var settled := advance_ship(i, anchor.rotation.y, previous, layout, previous_positions,
			group_errors[i % GROUP_COUNT], anchor_arrived, step)
		all_arrived = all_arrived and settled
	if all_arrived and absf(angle_difference(layout_yaw, course)) <= deg_to_rad(0.05):
		if has_arrival_yaw:
			turning = true
		else:
			stop()


func advance_ship(index: int, anchor_yaw: float, previous: Transform3D, layout: Transform3D,
		previous_positions: PackedVector3Array, group_error: Vector3, anchor_arrived: bool, step: float) -> bool:
	var profile: Vector4 = PROFILES[roles[index]]
	var slot := layout * slots[index]
	var error := slot - positions[index]
	var distance := planar(error).length()
	var ship_speed := planar(velocities[index]).length()
	update_heading(index, anchor_yaw, step)
	if anchor_arrived and distance <= 35.0 * UNIT and absf(error.y) <= 35.0 * UNIT and ship_speed <= 50.0 * UNIT:
		positions[index] = slot
		velocities[index] = Vector3.ZERO
		return absf(angle_difference(headings[index], anchor_yaw)) <= deg_to_rad(0.5)

	var anchor_velocity := (layout.origin - previous.origin) / step
	var slot_velocity := anchor_velocity + (slot - previous * slots[index] - anchor_velocity * step) * (0.7 / step)
	var separation := Vector3.ZERO
	for neighbor in slots.size():
		if neighbor == index:
			continue
		var away := previous_positions[index] - previous_positions[neighbor]
		var gap := away.length()
		var clearance := minf(340.0 * UNIT, 0.9 * slots[index].distance_to(slots[neighbor]))
		if gap > 0.00000001 and gap < clearance:
			separation += planar(away) * (4.0 * (clearance - gap) / gap)
	var desired := planar(slot_velocity) + planar(error) * 1.2 + planar(group_error) * 0.2
	desired += separation.limit_length(260.0 * UNIT)
	var catch_up := smoothstep(100.0 * UNIT, 220.0 * UNIT, distance)
	var cap := lerpf(CRUISE, profile.x * UNIT, catch_up)
	if anchor_arrived:
		cap = minf(cap, sqrt(2.0 * profile.w * UNIT * distance))
	var target_speed := minf(desired.length(), cap)
	var desired_velocity := desired.normalized() * target_speed
	var rate := profile.z if target_speed > ship_speed else profile.w
	velocities[index] += (desired_velocity - velocities[index]).limit_length(rate * UNIT * step)
	positions[index] += velocities[index] * step
	positions[index].y = move_toward(positions[index].y, slot.y, 220.0 * UNIT * step)
	return false


func update_heading(index: int, target: float, step: float) -> void:
	var profile: Vector4 = PROFILES[roles[index]]
	var weight := 1.0 - exp(-profile.y * step / 18.0)
	var limit := deg_to_rad(profile.y) * step
	var change := clampf(angle_difference(headings[index], target) * weight, -limit, limit)
	headings[index] = wrapf(headings[index] + change, -PI, PI)


static func planar(vector: Vector3) -> Vector3:
	return Vector3(vector.x, 0.0, vector.z)
