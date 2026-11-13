extends SceneTree

const Sweep := preload("res://scripts/p05_formation_transition.gd")
const Policy := preload("res://core/battle/p05_p07_first_operation.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Dev := preload("res://core/battle/first_operation_dev.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	var profile := OS.get_environment("SBTK_P05_TRANSITION_PROFILE")
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").to_lower()
	var actual := OS.get_user_data_dir().replace("\\", "/").to_lower()
	if _check(not profile.is_empty() and expected == actual, "isolated profile"):
		_adversarial()
		_red_cliffs()
	print("P05_FORMATION_TRANSITION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _red_cliffs() -> void:
	var loaded := Policy.load_source()
	if not _check(loaded.ok, "pinned operation definition"):
		return
	for key in ["roster", "combat_rules"]:
		if not _check(FileAccess.get_sha256(Dev.INPUT_PATHS[key]) == Product.INPUT_SHA256[key], "pinned " + key):
			return
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Dev.INPUT_PATHS.roster))
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Dev.INPUT_PATHS.combat_rules))
	var timing: Dictionary = combat.combat.formation_rules
	var formation_ids: Array = combat.combat.formations.keys()
	formation_ids.sort()
	_check(timing.transition_s == 5 and timing.untrained_transition_s == 5, "existing trained and untrained transition is 5 seconds")
	var renderer := FleetRenderer.new()
	_check(renderer._role_layout.source == FleetRenderer.RoleLayout.DOCUMENT_PATH, "uses versioned renderer role layout")
	for squad: Dictionary in roster.squadrons:
		if squad.id not in ["RC-LIU-SQ-01", "RC-LIU-SQ-02"]:
			continue
		var fleet: Dictionary = loaded.definition.fleets.filter(func(row): return row.id == squad.id)[0]
		_fleet(renderer, squad, fleet, formation_ids, roundi(timing.transition_s * 1000))
	renderer.free()


func _fleet(renderer: FleetRenderer, squad: Dictionary, fleet: Dictionary, formation_ids: Array, duration_ms: int) -> void:
	var counts := {}
	for entry: Dictionary in squad.composition:
		counts[entry.ship_type_id] = [int(entry.count)]
	var types := renderer._real_ship_ids(counts)
	_check(types.size() == int(fleet.ship_count), "%s full roster" % squad.id)
	var source := _points(renderer, fleet.formation_id, types, formation_ids)
	var destination := _points(renderer, "FRM-01" if fleet.formation_id == "FRM-03" else "FRM-03", types, formation_ids)
	var classes := types.map(func(type): return renderer._model_class(type))
	var assignments := renderer._assign_real(source, classes, squad.flagship, true)
	var ordinals := {}
	var rows: Array = []
	for i in types.size():
		var type: String = types[i]
		ordinals[type] = ordinals.get(type, 0) + 1
		var assignment: Dictionary = assignments[i]
		# Fixture x is forward, z is lateral. Renderer-local x is lateral, -z is forward. The ship plane's
		# local x is the length; renderer yaw aligns it with fleet forward.
		# Use the centered MODEL_LEN portion only. PLANE_K includes the trail.
		var scale: float = FleetRenderer.CLASS_LEN[assignment.cls] / FleetRenderer.MODEL_LEN
		if assignment.get("flag", false):
			scale *= 1.8
		var half: Vector2 = Vector2(FleetRenderer.MODEL_LEN * FleetRenderer.HULL_STRETCH.x,
			FleetRenderer.SHIP_WIDTH * FleetRenderer.HULL_STRETCH.z) * (0.5 * scale / CameraRig.S)
		rows.append({"id": "%s/%s/%d" % [squad.id, type, ordinals[type]],
			"from": Vector2(source[i].x, source[i].z), "to": Vector2(destination[i].x, destination[i].z), "half": half})
	var expected_counts := [13, 7] if squad.id == "RC-LIU-SQ-01" else [2, 10]
	_report_endpoint(rows, "from", fleet.formation_id, fleet.outer_radius, expected_counts[0])
	_report_endpoint(rows, "to", "FRM-01" if fleet.formation_id == "FRM-03" else "FRM-03",
		fleet.outer_radius, expected_counts[1])
	_check_adjusted_route(rows, squad.id, fleet.outer_radius, duration_ms)
	var frozen := rows.duplicate(true)
	var forward := Sweep.validate(rows, fleet.outer_radius)
	var reversed := rows.map(func(row): return {"id": row.id, "from": row.to, "to": row.from, "half": row.half})
	var backward := Sweep.validate(reversed, fleet.outer_radius)
	_check(forward == Sweep.validate(rows, fleet.outer_radius) and rows == frozen, "%s deterministic and read-only" % squad.id)
	var witness := ["SHP-04/1", "SHP-04/3" if squad.id == "RC-LIU-SQ-01" else "SHP-04/5"]
	var expected_pair := witness.map(func(id): return squad.id + "/" + id)
	_check(forward.get("error") == "swept_overlap" and backward.get("error") == "swept_overlap"
		and forward.ships == expected_pair and backward.ships == expected_pair
		and is_equal_approx(forward.fraction + backward.fraction, 1.0), "%s deterministic overlap in both directions" % squad.id)
	print("P05_FORMATION_OBSERVATION ", JSON.stringify({"fleet": squad.id, "ships": rows.size(),
		"from": fleet.formation_id, "duration_ms": duration_ms, "forward": forward, "reverse": backward}))


func _check_adjusted_route(rows: Array, fleet: String, radius: float, duration_ms: int) -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		"res://tests/fixtures/p05/adjusted_formation_route.json"))
	var route: Dictionary = fixture[fleet]
	var current := {}
	var destination := {}
	var original := {}
	var used_slots := {}
	var source_offset := 0.0
	var destination_offset := 0.0
	for row: Dictionary in rows:
		original[_short_id(row.id)] = row
	for short_id: String in original:
		var row: Dictionary = original[short_id]
		var slot_id: String = route.dest[short_id][0]
		var slot: Dictionary = original[slot_id]
		if not _check(not used_slots.has(slot_id) and slot.half == row.half
				and slot_id.get_slice("/", 0) == short_id.get_slice("/", 0), "%s unique same-hull slot for %s" % [fleet, short_id]):
			return
		used_slots[slot_id] = true
		current[short_id] = Vector2(route.source[short_id][0], route.source[short_id][1])
		var point: Array = route.dest[short_id][1]
		destination[short_id] = Vector2(point[0], point[1])
		source_offset = maxf(source_offset, Vector2(current[short_id]).distance_to(row.from))
		destination_offset = maxf(destination_offset, Vector2(destination[short_id]).distance_to(slot.to))
	var offset_limit := 5.661 if fleet == "RC-LIU-SQ-01" else 2.475
	_check(source_offset <= offset_limit and destination_offset <= offset_limit,
		"%s proposed endpoint shifts stay within measured limits" % fleet)
	var segment_start := current.duplicate()
	var layouts: Array = [segment_start]
	var distance := 0.0
	var corner_radius := 0.0
	for move: Array in route.moves:
		var moving: String = move[0]
		var next := Vector2(move[1][0], move[1][1])
		var segment: Array = []
		for row: Dictionary in rows:
			var short_id := _short_id(row.id)
			var start: Vector2 = current[short_id]
			var end: Vector2 = next if short_id == moving else start
			segment.append({"id": row.id, "from": start, "to": end, "half": row.half})
			corner_radius = maxf(corner_radius, maxf((end.abs() + row.half).length(), (start.abs() + row.half).length()))
		var reversed := segment.map(func(row):
			return {"id": row.id, "from": row.to, "to": row.from, "half": row.half})
		var forward := Sweep.validate(segment, radius)
		var reverse := Sweep.validate(reversed, radius)
		if not _check_segment(forward, reverse, fleet, moving):
			return
		distance += Vector2(current[moving]).distance_to(next)
		current[moving] = next
		layouts.append(current.duplicate())
	_check(current == destination and not route.moves.is_empty() and current != segment_start,
		"%s candidate reaches adjusted destination through collision-free segments in both directions" % fleet)
	print("P05_ADJUSTED_ROUTE_OBSERVATION ", JSON.stringify({"fleet": fleet, "segments": route.moves.size(),
		"max_source_offset": source_offset, "max_destination_offset": destination_offset, "corner_radius": corner_radius, "approved_radius": radius, "sequential_distance": distance,
		"constant_moving_speed_for_duration": distance / (duration_ms / 1000.0)}))
	_check_timed_route(rows, fleet, radius, duration_ms, layouts)


# A phase moves all participating ships simultaneously, linearly between two known-safe layouts.
# The base core timer supplies the duration. Renderer Slot.pos also follows Slot.home through a
# smoothing filter, so this certificate describes the scheduled coordinates themselves.
# Salvo.transition_ticks defines the deadline, not a slot velocity or acceleration limit.
# Report the scheduled speed for review; the fleet-center speed does not constrain these slots.
func _check_timed_route(rows: Array, fleet: String, radius: float, duration_ms: int, layouts: Array) -> void:
	# Shortest path over the ordered layouts. An edge exists only when its simultaneous sweep
	# passes, and its cost is the longest ship movement (the minimum time at a common speed).
	var costs: Array[float] = []
	costs.resize(layouts.size())
	costs.fill(INF)
	costs[0] = 0.0
	var previous: Array[int] = []
	previous.resize(layouts.size())
	previous.fill(-1)
	for first in layouts.size() - 1:
		if not is_finite(costs[first]):
			continue
		for last in range(first + 1, layouts.size()):
			var phase := _phase(rows, layouts[first], layouts[last])
			var cost := costs[first] + _phase_distance(phase)
			if cost < costs[last] and _phase_clear(phase, radius):
				costs[last] = cost
				previous[last] = first
	var phases: Array = []
	var last := layouts.size() - 1
	if not _check(previous[last] >= 0, "%s timed route connects both endpoints" % fleet):
		return
	while last > 0:
		var first := previous[last]
		phases.append(_phase(rows, layouts[first], layouts[last]))
		last = first
	phases.reverse()

	var phase_weights: Array[float] = []
	var total_weight := 0.0
	var parallel_phases := 0
	for phase: Array in phases:
		var moving := 0
		for row: Dictionary in phase:
			if row.from != row.to:
				moving += 1
		if moving > 1:
			parallel_phases += 1
		var longest := _phase_distance(phase)
		phase_weights.append(longest)
		total_weight += longest
	if not _check(total_weight > 0.0 and parallel_phases > 0, "%s timed route uses simultaneous motion" % fleet):
		return

	# Integer microseconds give exactly 0 and the pinned duration at the first and last knots.
	# Allocate time proportionally to the longest movement in each phase, then check all velocities.
	var duration_us := duration_ms * 1000
	var knots: Array[int] = [0]
	var elapsed_weight := 0.0
	var peak_speed := 0.0
	for i in phases.size():
		elapsed_weight += phase_weights[i]
		var finish := duration_us if i == phases.size() - 1 else roundi(duration_us * elapsed_weight / total_weight)
		if not _check(finish > knots[-1], "%s phase %d has positive duration" % [fleet, i]):
			return
		peak_speed = maxf(peak_speed, phase_weights[i] * 1000000.0 / (finish - knots[-1]))
		knots.append(finish)
	var initial := _timed_positions(phases, knots, 0)
	var final := _timed_positions(phases, knots, duration_us)
	_check(initial == layouts.front() and final == layouts.back() and knots[-1] == 5000000,
		"%s adjusted route reaches exact endpoints at 0 and 5 seconds" % fleet)
	var reversed_phases: Array = []
	var reversed_knots: Array[int] = [0]
	for i in range(phases.size() - 1, -1, -1):
		reversed_phases.append(_reverse_phase(phases[i]))
		reversed_knots.append(duration_us - knots[i])
	_check(_timed_positions(reversed_phases, reversed_knots, 0) == layouts.back()
		and _timed_positions(reversed_phases, reversed_knots, duration_us) == layouts.front(),
		"%s reverse timed route reaches exact endpoints at 0 and 5 seconds" % fleet)
	var playback_matches := true
	for i in phases.size():
		var sample := roundi((knots[i] + knots[i + 1]) * 0.5)
		var forward_position := _timed_positions(phases, knots, sample)
		var reverse_position := _timed_positions(reversed_phases, reversed_knots, duration_us - sample)
		for id: String in forward_position:
			playback_matches = playback_matches and Vector2(forward_position[id]).distance_to(reverse_position[id]) < 0.00002
	_check(playback_matches, "%s forward and reverse agree inside every timed phase" % fleet)
	print("P05_TIMED_ROUTE_OBSERVATION ", JSON.stringify({"fleet": fleet, "phases": phases.size(),
		"simultaneous_phases": parallel_phases, "duration_us": knots[-1], "peak_slot_speed": peak_speed,
		"minimum_phase_us": _minimum_phase_time(knots)}))


func _phase(rows: Array, start: Dictionary, finish: Dictionary) -> Array:
	var phase: Array = []
	for row: Dictionary in rows:
		var short_id := _short_id(row.id)
		phase.append({"id": row.id, "from": start[short_id], "to": finish[short_id], "half": row.half})
	return phase


func _phase_distance(phase: Array) -> float:
	var longest := 0.0
	for row: Dictionary in phase:
		longest = maxf(longest, row.from.distance_to(row.to))
	return longest


func _phase_clear(phase: Array, radius: float) -> bool:
	if not Sweep.validate(phase, radius).ok:
		return false
	return Sweep.validate(_reverse_phase(phase), radius).ok


func _reverse_phase(phase: Array) -> Array:
	return phase.map(func(row):
		return {"id": row.id, "from": row.to, "to": row.from, "half": row.half})


func _timed_positions(phases: Array, knots: Array[int], time_us: int) -> Dictionary:
	var i := 0
	while i < phases.size() - 1 and time_us > knots[i + 1]:
		i += 1
	var fraction := float(time_us - knots[i]) / (knots[i + 1] - knots[i])
	var positions := {}
	for row: Dictionary in phases[i]:
		# Avoid rounding error at the final knot.
		var position: Vector2 = row.to if fraction == 1.0 else Vector2(row.from).lerp(row.to, fraction)
		positions[_short_id(row.id)] = position
	return positions


func _minimum_phase_time(knots: Array[int]) -> int:
	var shortest := knots[-1]
	for i in range(1, knots.size()):
		shortest = mini(shortest, knots[i] - knots[i - 1])
	return shortest



func _short_id(id: String) -> String:
	return id.get_slice("/", 1) + "/" + id.get_slice("/", 2)


func _check_segment(forward: Dictionary, reverse: Dictionary, fleet: String, moving: String) -> bool:
	if forward.ok and reverse.ok:
		return true
	return _check(false, "%s invalid candidate segment for %s: %s / %s" % [fleet, moving, forward, reverse])



func _report_endpoint(rows: Array, endpoint: String, formation: String, radius: float, expected_count: int) -> void:
	var overlaps := 0
	var equal_hull_witness := {}
	var required_radius := 0.0
	for i in rows.size():
		var a: Dictionary = rows[i]
		var position: Vector2 = a[endpoint]
		required_radius = maxf(required_radius, (Vector2(absf(position.x), absf(position.y)) + a.half).length())
		for j in range(i + 1, rows.size()):
			var b: Dictionary = rows[j]
			var delta: Vector2 = position - b[endpoint]
			var penetration: Vector2 = a.half + b.half - Vector2(absf(delta.x), absf(delta.y))
			if penetration.x <= 0.0 or penetration.y <= 0.0:
				continue
			overlaps += 1
			if equal_hull_witness.is_empty() and a.half == b.half and a.id.get_slice("/", 1) == b.id.get_slice("/", 1):
				equal_hull_witness = {"ships": [a.id, b.id], "half": [a.half.x, a.half.y],
					"penetration": [penetration.x, penetration.y]}
	var stationary := rows.map(func(row):
		return {"id": row.id, "from": row[endpoint], "to": row[endpoint], "half": row.half})
	var result := Sweep.validate(stationary, radius)
	var fleet: String = rows[0].id.get_slice("/", 0)
	_check(overlaps == expected_count and not equal_hull_witness.is_empty()
		and result.get("error") == "swept_overlap", "%s %s endpoint overlaps while stationary" % [fleet, formation])
	print("P05_ENDPOINT_OBSERVATION ", JSON.stringify({"fleet": fleet, "formation": formation,
		"pairs": overlaps, "equal_hull_witness": equal_hull_witness,
		"required_radius": required_radius, "approved_radius": radius}))



func _points(renderer: FleetRenderer, formation_id: String, types: Array, formation_ids: Array) -> Array:
	var index := formation_ids.find(formation_id)
	return renderer._role_points(renderer.formation_points(BattleRules.FORM_SHAPE[index], types.size()), types)


func _adversarial() -> void:
	var a := {"id": "a", "from": Vector2(-4, 0), "to": Vector2(4, 0), "half": Vector2.ONE}
	var b := {"id": "b", "from": Vector2(4, 0), "to": Vector2(-4, 0), "half": Vector2.ONE}
	var cross := Sweep.validate([a, b], 10.0)
	_check(cross.get("error") == "swept_overlap" and cross.get("fraction") == 0.5, "separated endpoints cross in between")
	b.from.y = 2.0
	b.to.y = 2.0
	_check(Sweep.validate([a, b], 10.0).ok, "edge contact permitted")
	_check(Sweep.validate([a, a], 10.0).get("error") == "invalid_ship", "duplicate identity rejected")
	_check(Sweep.validate([a], 5.0).get("error") == "outer_radius", "hull corner outside approved radius rejected")
	b.from.y = 1.99
	b.to.y = 1.99
	_check(Sweep.validate([a, b], 10.0).get("error") == "swept_overlap", "interior overlap just inside contact rejected")


func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print("P05_FORMATION_CHECK ", condition, " ", label)
	return condition
