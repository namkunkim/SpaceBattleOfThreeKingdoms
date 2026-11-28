extends SceneTree

const MOTION := preload("res://single_fleet_motion.gd")
const PATHS := preload("res://single_fleet_paths.gd")
const SCENE := preload("res://shu_single_fleet_3d.tscn")
const FRAME := 1.0 / 60.0

var scene: Node3D
var anchor: Node3D
var motion: MOTION
var origin: Vector3
var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	scene = SCENE.instantiate()
	root.add_child(scene)
	scene.set_process(false)
	check(scene.units.size() == 1 and scene.selected_units == [0], "scene has one selected fleet")
	anchor = scene.units[0].anchor
	motion = scene.units[0].motion
	origin = motion.positions[0]
	check(motion.positions.size() == 60 and scene.map_opacity < 0.01, "60 hulls start in 3D")
	check(anchor.position.distance_to(motion.positions[0]) > 5.0, "the order origin is the footprint center")
	run_case("09 HTML forward", Vector3(90, 0, 18), 0.0, MOTION.Maneuver.FORWARD)
	run_case("forward with small arrival turn", Vector3(90, 0, 18), deg_to_rad(20.0), MOTION.Maneuver.FORWARD)
	run_case("forward without facing", Vector3(85, 0, 0), null, MOTION.Maneuver.FORWARD)
	run_case("starboard", Vector3(0, 0, 73), deg_to_rad(-20.0), MOTION.Maneuver.FLANK)
	run_case("diagonal port", Vector3(35, 0, -65), 0.0, MOTION.Maneuver.FLANK)
	run_case("front reverse", Vector3(95, 0, 0), PI, MOTION.Maneuver.FRONT_REVERSE)
	run_case("rear long", Vector3(-100, 0, 0), 0.0, MOTION.Maneuver.REAR_LONG)
	run_case("rear short", Vector3(-28, 0, 0), 0.0, MOTION.Maneuver.STANDARD)
	run_case("align while moving", Vector3(43, 0, 3), -PI * 0.5, MOTION.Maneuver.STANDARD)
	run_case("same footprint reverse", Vector3.ZERO, PI, MOTION.Maneuver.STANDARD)
	test_redirect()
	test_independent_route()
	if failures.is_empty():
		print("PASS: HTML scenario rules, reserved paths, footprint-center arrival, braking, pause and independent routes.")
	quit(0 if failures.is_empty() else 1)


func reset_case() -> void:
	anchor.position = origin
	anchor.rotation.y = 0.0
	motion = MOTION.new(anchor, scene.slots, scene.units[0].roles)
	scene.units[0].motion = motion


func run_case(label: String, offset: Vector3, requested: Variant, expected: int) -> void:
	reset_case()
	var goal := anchor.position + offset
	scene._move_selected(goal, requested)
	check(motion.maneuver == expected, label + " classifies like the HTML simulator")
	check(not motion.plan_failed and motion._legs.size() == 60, label + " reserves 60 paths")
	if motion._legs.is_empty():
		return
	var legs: Array[PATHS.Leg] = motion._legs.duplicate()
	var final_yaw := motion.arrival_yaw
	var preserve := expected in [MOTION.Maneuver.FORWARD, MOTION.Maneuver.FLANK, MOTION.Maneuver.FRONT_REVERSE]
	var drift_before_docking := 0.0
	var moving_turn := 0.0
	var early_launch := false
	var last_launch := 0.0
	var minimum_clearance := INF
	for path in legs:
		last_launch = maxf(last_launch, path.delay)
	for i in 7200:
		if not motion.moving:
			break
		motion.advance(anchor, FRAME)
		var time := motion._clock
		for j in legs.size():
			var path: PATHS.Leg = legs[j]
			if time >= path.delay and time < path.delay + path.duration:
				var rotation := absf(angle_difference(0.0, motion.headings[j]))
				moving_turn = maxf(moving_turn, rotation)
				if preserve:
					drift_before_docking = maxf(drift_before_docking, rotation)
			if expected == MOTION.Maneuver.REAR_LONG and time < last_launch - 0.05:
				early_launch = early_launch or motion.positions[j].distance_to(path.start) > 0.006
		if i % 8 == 0:
			minimum_clearance = minf(minimum_clearance, hull_clearance())
	if preserve:
		check(drift_before_docking < 0.0001, label + " holds each bow until its slot is reached")
	if expected == MOTION.Maneuver.REAR_LONG:
		check(early_launch and last_launch > 0.2, label + " ready ships start without waiting for the fleet")
		check(moving_turn >= deg_to_rad(165.0), label + " first travels sternward bow-first")
	if expected == MOTION.Maneuver.STANDARD and absf(final_yaw) > 0.3:
		check(moving_turn > absf(final_yaw) * 0.75, label + " changes bow direction in flight")
	check(minimum_clearance > 0.08, label + " maintains hull clearance")
	check(not motion.moving and not motion.plan_failed and motion.speed == 0.0, label + " settles")
	check(anchor.position.distance_to(goal) < 0.01, label + " anchor reaches chosen center")
	check(PATHS.footprint(motion.positions, motion._radii).distance_to(goal) < 0.01, label + " true footprint reaches goal")
	var expected_slots := PATHS.formation(scene.slots, motion._radii, goal, final_yaw)
	for j in motion.positions.size():
		if motion.positions[j].distance_to(expected_slots[j]) > 0.01 				or absf(angle_difference(motion.headings[j], final_yaw)) > 0.01:
			check(false, label + " all ships are in their own final slots and headings")
			break
	print("%s: hull gap %.3f; last launch %.2f s; settled at %.2f s."
		% [label, minimum_clearance, last_launch, motion._clock])


func test_redirect() -> void:
	reset_case()
	var first_goal := anchor.position + Vector3(22, 0, 0)
	var event := InputEventMouseButton.new()
	event.position = scene.camera.unproject_position(first_goal)
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	scene._handle_button(event)
	event.pressed = false
	scene._handle_button(event)
	check(motion.destination.distance_to(first_goal) < 0.01, "actual 3D right-click uses new path")
	for i in 160:
		motion.advance(anchor, FRAME)
	var before := motion.positions.duplicate()
	var start := anchor.position
	var target := start + Vector3(10, 0, -28)
	var speed_before := motion.speed
	scene._move_selected(target, PI * 0.5)
	check(motion.phase == MOTION.Phase.BRAKE and motion.positions == before,
		"redirect brakes on original paths without a position jump")
	motion.advance(anchor, FRAME)
	check(anchor.position.x > start.x and motion.speed < speed_before + 0.2, "live flight carries through first braking step")
	scene.paused = true
	var clock := motion._clock
	scene._process(0.4)
	check(clock == motion._clock, "pause retains the current flight phase")
	scene.paused = false
	run_to_stop()
	check(anchor.position.distance_to(target) < 0.01, "redirect reaches its latest destination")
	scene._go_back()
	check(scene.map_opacity > 0.99 and scene.selected_units == [0], "existing camera transition works")


func test_independent_route() -> void:
	reset_case()
	var ship_start := motion.positions[0]
	var waypoints := PackedVector3Array([ship_start + Vector3(0, 5, 0), ship_start + Vector3(3, 6, 4)])
	check(motion.set_ship_route(0, waypoints), "accepts independent route")
	var target := anchor.position + Vector3(24, 0, 0)
	scene._move_selected(target)
	var high := 0.0
	for i in 2400:
		if not motion.moving:
			break
		motion.advance(anchor, FRAME)
		high = maxf(high, motion.positions[0].y)
	check(high > 5.0 and not motion.moving and motion._ship_routes.is_empty(), "detached ship travels and rejoins")
	check(anchor.position.distance_to(target) < 0.01, "independent route retains fleet destination")


func run_to_stop() -> void:
	for i in 7200:
		if not motion.moving:
			return
		motion.advance(anchor, FRAME)
	check(false, "movement settles within 120 seconds")


func hull_clearance() -> float:
	var distance := INF
	for i in motion.positions.size():
		for j in range(i + 1, motion.positions.size()):
			var gap := motion.positions[i].distance_to(motion.positions[j]) - motion._radii[i] - motion._radii[j]
			distance = minf(distance, gap)
	return distance


func check(condition: bool, label: String) -> void:
	if not condition:
		failures.append(label)
		push_error(label)
