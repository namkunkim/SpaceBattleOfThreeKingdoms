extends SceneTree

const Policy := preload("res://core/battle/p05_p07_first_operation.gd")
const Dev := preload("res://core/battle/first_operation_dev.gd")
const Schedule := preload("res://view/fleet_render/p05_formation_schedule.gd")

class RouteSource extends BattleSource:
	var rows: Array[Dictionary] = []

	func squadrons() -> Array[Dictionary]:
		return rows
	func camera() -> Camera3D:
		return null
	func world_size() -> Vector2:
		return Vector2(1600.0, 900.0)
	func zoom() -> float:
		return 1.0
	func unit_scale() -> float:
		return CameraRig.S
	func to3(point: Vector2, y := 0.0) -> Vector3:
		return Vector3(point.x * CameraRig.S, y, point.y * CameraRig.S)
	func drain_salvo_fx() -> Array:
		return []
	func missiles() -> Array:
		return []
	func swarms() -> Array:
		return []

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := OS.get_environment("SBTK_P05_TRANSITION_PROFILE")
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").to_lower()
	if not _check(not profile.is_empty() and OS.get_user_data_dir().replace("\\", "/").to_lower() == expected, "isolated profile"):
		quit(1)
		return
	var source := RouteSource.new(null)
	var operation := Policy.load_source()
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Dev.INPUT_PATHS.roster))
	var bindings := {}
	for fleet: Dictionary in operation.definition.fleets:
		if fleet.id not in ["RC-LIU-SQ-01", "RC-LIU-SQ-02"]:
			continue
		var squad: Dictionary = roster.squadrons.filter(func(row): return row.id == fleet.id)[0]
		var counts := {}
		for row: Dictionary in squad.composition:
			counts[row.ship_type_id] = [int(row.count)]
		var id := bindings.size() + 1
		bindings[id] = fleet.id
		source.rows.append({"id": id, "side": 0, "faction": "liu", "flagship": squad.flagship,
			"counts": counts, "ships": fleet.ship_count, "max_ships": fleet.ship_count,
			"formation": _shape(fleet.formation_id), "formation_id": fleet.formation_id,
			"form_to": "", "form_left_s": 0.0, "heading": deg_to_rad(fleet.heading_deg),
			"pos": Vector2(400.0, 450.0 + id * 150.0), "flip": false, "dead": false,
			"target_id": -1, "firing_at": -1, "contact": ""})
	var renderer := FleetRenderer.new()
	root.add_child(renderer)
	renderer.setup(source)
	var legacy := source.rows[0].duplicate(true)
	legacy.id = 3
	legacy.pos += Vector2(0.0, 500.0)
	source.rows.append(legacy)
	if not _check(renderer.enable_p05_formation_routes(bindings), "explicit P05 binding accepted"):
		renderer.free()
		quit(1)
		return
	renderer.update(0.0)
	_check(renderer.vis[3].p05 == null, "unbound squad with identical roster remains on legacy renderer")
	source.rows.pop_back()
	for sq: Dictionary in source.rows:
		var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
		if not _check(v.p05 != null, "%s exact full roster enabled" % bindings[sq.id]):
			renderer.free()
			quit(1)
			return
	var schedule_peaks := {}
	for sq: Dictionary in source.rows:
		schedule_peaks[sq.id] = _check_schedule_acceleration(renderer.vis[sq.id].p05, bindings[sq.id])
	for cadence: Array in [[60, 0.0], [30, 0.0], [120, 0.0], [60, 0.35], [60, 5.0]]:
		for reverse in [false, true]:
			_measure(renderer, source, bindings, cadence[0], cadence[1], reverse, schedule_peaks)
	# Motion outside the certified fixed origin is allowed to use the ordinary renderer.
	source.rows[0].pos += Vector2.ONE
	renderer.update(1.0 / 60.0)
	_check(renderer.vis[1].p05 == null and renderer.vis[2].p05 != null, "moving fleet alone returns to ordinary rendering")
	renderer.free()
	source.rows[0].pos -= Vector2.ONE
	_measure_authority(source, bindings)
	print("P05_RENDERER_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)


func _measure_authority(source: RouteSource, bindings: Dictionary) -> void:
	var renderer := FleetRenderer.new()
	root.add_child(renderer)
	renderer.setup(source)
	var identity := "p05-clock-test"
	for sq: Dictionary in source.rows:
		sq.operation_id = identity
		sq.tick = 0
	if not _check(renderer.enable_p05_formation_routes(bindings, identity), "bind operation clock"):
		renderer.free()
		return
	renderer.update(0.0)
	if not _check(renderer.vis[1].p05 != null and renderer.vis[2].p05 != null, "both authority routes build"):
		renderer.free()
		return
	var tick := 0
	for reverse in [false, true]:
		var clear_chords := true
		var respects_clock := true
		for elapsed in range(1, 51):
			tick += 1
			var before := {}
			for sq: Dictionary in source.rows:
				var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
				before[sq.id] = _positions(v, sq)
				sq.tick = tick
				sq.form_left_s = float(50 - elapsed) / 10.0
				var target := v.p05_from if reverse else v.p05_to
				sq.form_to = target if elapsed < 50 else ""
				if elapsed == 50:
					sq.formation_id = target
					sq.formation = _shape(target)
			renderer.update(1.0 / 120.0 if elapsed % 2 == 0 else 0.4)
			for sq: Dictionary in source.rows:
				var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
				clear_chords = v.p05.clear(before[sq.id], _positions(v, sq), 0.0) and clear_chords
				var requested: float = sq.form_left_s if reverse else Schedule.DURATION - sq.form_left_s
				respects_clock = (v.p05_time >= requested if reverse else v.p05_time <= requested) and respects_clock
			if elapsed == 15:
				_check_authority_holds(renderer, source)
		_check(clear_chords and respects_clock, "authority samples respect clock and certified chords, reverse=%s" % reverse)
		_drain_authority(renderer, source, tick, reverse)
		tick = source.rows[0].tick
	# Jump from the original endpoint to a committed target in one snapshot.
	for sq: Dictionary in source.rows:
		var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
		sq.formation_id = v.p05_to
		sq.formation = _shape(v.p05_to)
		sq.tick = tick + 50
	renderer.update(5.0)
	_check(renderer.vis[1].p05_time < Schedule.DURATION and renderer.vis[2].p05_time < Schedule.DURATION,
		"skipped completion defers unsafe endpoint chord")
	_check_authority_holds(renderer, source)
	_drain_authority(renderer, source, tick + 50, false)
	_measure_terminal(renderer, source, tick + 150)
	renderer.free()


func _measure_terminal(renderer: FleetRenderer, source: RouteSource, tick: int) -> void:
	for sq: Dictionary in source.rows:
		var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
		sq.formation_id = v.p05_from
		sq.formation = _shape(v.p05_from)
		sq.tick = tick
		sq.terminal_tick = tick
	renderer.update(1.0 / 60.0)
	var frozen := source.rows.duplicate(true)
	var before := {}
	var deferred := true
	for sq: Dictionary in source.rows:
		var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
		before[sq.id] = _positions(v, sq)
		deferred = v.p05_time > 0.0 and deferred
	_check(deferred, "terminal completion first defers the unsafe reverse chord")
	renderer.update(0.0)
	for sq: Dictionary in source.rows:
		sq.tick += 1
	renderer.update(0.5)
	source.rows.assign(frozen.duplicate(true))
	for sq: Dictionary in source.rows:
		sq.formation_id = renderer.vis[sq.id].p05_to
	renderer.update(0.5)
	source.rows.assign(frozen.duplicate(true))
	var held := true
	for sq: Dictionary in source.rows:
		held = _positions(renderer.vis[sq.id], sq) == before[sq.id] and held
	_check(held, "terminal slots hold during pause and reject newer or changed snapshots")
	var complete := false
	var safe := true
	for frame in 100:
		renderer.update(1.0 / 60.0)
		complete = true
		for sq: Dictionary in source.rows:
			var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
			var rendered := _positions(v, sq)
			safe = v.p05.clear(before[sq.id], rendered, 0.0) and v.p05_tick == tick and safe
			before[sq.id] = rendered
			complete = v.p05_time == 0.0 and complete
		if complete:
			print("P05_TERMINAL_PRESENTATION updates=", frame + 1, " authority_tick=", tick)
			break
	_check(complete and safe and source.rows == frozen, "frozen terminal snapshot finishes safely without new ticks")


func _check_authority_holds(renderer: FleetRenderer, source: RouteSource) -> void:
	var before := {}
	var saved_time := {}
	for sq: Dictionary in source.rows:
		before[sq.id] = _positions(renderer.vis[sq.id], sq)
		saved_time[sq.id] = sq.form_left_s
	renderer.update(0.5)
	var held := true
	for sq: Dictionary in source.rows:
		held = _positions(renderer.vis[sq.id], sq) == before[sq.id] and held
		sq.tick -= 1
	renderer.update(0.5)
	for sq: Dictionary in source.rows:
		held = _positions(renderer.vis[sq.id], sq) == before[sq.id] and held
		sq.tick += 2
		sq.operation_id = "different-operation"
	renderer.update(0.5)
	for sq: Dictionary in source.rows:
		held = _positions(renderer.vis[sq.id], sq) == before[sq.id] and held
		sq.tick -= 1
		sq.operation_id = "p05-clock-test"
	_check(held, "duplicate, older and foreign-operation snapshots hold rendered slots")
	for sq: Dictionary in source.rows:
		sq.tick += 1
	renderer.update(0.0)
	held = true
	for sq: Dictionary in source.rows:
		held = _positions(renderer.vis[sq.id], sq) == before[sq.id] and held
		sq.form_left_s = NAN
	renderer.update(0.5)
	for sq: Dictionary in source.rows:
		var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
		held = _positions(v, sq) == before[sq.id] and v.p05_tick == sq.tick - 1 and held
		sq.tick -= 1
		sq.form_left_s = saved_time[sq.id]
	_check(held, "paused update and malformed remaining time preserve slots and clock")


func _drain_authority(renderer: FleetRenderer, source: RouteSource, tick: int, reverse: bool) -> void:
	var endpoint := 0.0 if reverse else Schedule.DURATION
	var complete := false
	var clear_chords := true
	for offset in range(1, 101):
		var before := {}
		for sq: Dictionary in source.rows:
			before[sq.id] = _positions(renderer.vis[sq.id], sq)
			sq.tick = tick + offset
		renderer.update(1.0 / 60.0)
		complete = true
		for sq: Dictionary in source.rows:
			var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
			clear_chords = v.p05.clear(before[sq.id], _positions(v, sq), 0.0) and clear_chords
			complete = v.p05_time == endpoint and complete
		if complete:
			break
	_check(complete and clear_chords, "later authority ticks finish on safe chords, reverse=%s" % reverse)


# The quintic f(u) = 6u^5 - 15u^4 + 10u^3 has its acceleration extrema
# at (3 ± sqrt(3))/6. The time-reversed route has the same peak magnitude.
func _check_schedule_acceleration(schedule: Schedule, fleet: String) -> float:
	var extremum := (3.0 - sqrt(3.0)) / 6.0
	var peak_factor := 10.0 * sqrt(3.0) / 3.0
	var peak := 0.0
	var peak_ship := ""
	var peak_phase := -1
	var derivative_matches := true
	for phase in range(schedule.knots.size() - 1):
		var begin := schedule.knots[phase]
		var duration := schedule.knots[phase + 1] - begin
		if not _check(duration > 0.0 and is_finite(duration), "%s positive finite phase duration" % fleet, false):
			return 0.0
		var step := duration / 64.0
		for u in [extremum, 1.0 - extremum]:
			var time: float = begin + duration * u
			var before := schedule.sample(time - step)
			var center := schedule.sample(time)
			var after := schedule.sample(time + step)
			for row: Dictionary in schedule.rows:
				var id: String = row.id
				var start: Vector2 = schedule.layouts[phase][id]
				var finish: Vector2 = schedule.layouts[phase + 1][id]
				var acceleration := (finish - start) * (peak_factor / (duration * duration))
				var position: Vector2 = center[id]
				var measured := ((Vector2(after[id]) - position) - (position - Vector2(before[id]))) / (step * step)
				var expected := acceleration if u < 0.5 else -acceleration
				# Central-difference truncation and single-precision Vector2 rounding.
				var rounding := 0.000001 * maxf(start.length(), finish.length()) / (step * step)
				derivative_matches = derivative_matches and measured.distance_to(expected) <= expected.length() * 0.003 + rounding
				var magnitude := acceleration.length()
				if magnitude > peak:
					peak = magnitude
					peak_ship = id
					peak_phase = phase
	_check(derivative_matches, "%s schedule samples match both signed acceleration extrema" % fleet)
	_check(peak > 0.0 and is_finite(peak), "%s schedule has a finite acceleration peak" % fleet)
	print("P05_SCHEDULE_ACCELERATION ", JSON.stringify({"fleet": fleet, "duration_s": Schedule.DURATION,
		"peak_acceleration": peak, "peak_ship": peak_ship, "peak_phase": peak_phase,
		"units": "tactical_units_per_second_squared"}))
	return peak


func _measure(renderer: FleetRenderer, source: RouteSource, ids: Dictionary, hz: int, skip: float,
		reverse: bool, schedule_peaks: Dictionary) -> void:
	var measures := {}
	for sq: Dictionary in source.rows:
		var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
		measures[sq.id] = {"previous": _positions(v, sq), "velocity": {}, "peak_speed": 0.0,
			"peak_acceleration": 0.0, "completed": -1.0, "deferred_frames": 0}
		sq.form_to = v.p05_from if reverse else v.p05_to
		sq.formation = _shape(sq.form_to)
	var elapsed := 0.0
	var skipped := false
	var last_dt := 1.0 / hz
	while elapsed < 8.0:
		var dt := 1.0 / hz
		if not skipped and skip > 0.0 and (elapsed >= 1.7 or skip == 5.0):
			dt = skip
			skipped = true
		if elapsed < Schedule.DURATION - 0.00000001:
			dt = minf(dt, Schedule.DURATION - elapsed)
		elapsed += dt
		if absf(elapsed - Schedule.DURATION) < 0.00000001:
			elapsed = Schedule.DURATION
		for sq: Dictionary in source.rows:
			sq.form_left_s = maxf(0.0, Schedule.DURATION - elapsed)
			if elapsed >= Schedule.DURATION and sq.form_to != "":
				sq.formation_id = sq.form_to
				sq.form_to = ""
		renderer.update(dt)
		var done := true
		for sq: Dictionary in source.rows:
			var v: FleetRenderer.FleetVis = renderer.vis[sq.id]
			var m: Dictionary = measures[sq.id]
			var rendered := _positions(v, sq)
			if not _check(v.p05.clear(m.previous, rendered, 0.0), "%s %dHz clear rendered chord at %.6fs" % [ids[sq.id], hz, elapsed], false):
				return
			for id: String in rendered:
				var velocity: Vector2 = (rendered[id] - m.previous[id]) / dt
				m.peak_speed = maxf(m.peak_speed, velocity.length())
				var old_velocity: Vector2 = m.velocity.get(id, Vector2.ZERO)
				var acceleration := (velocity - old_velocity) / ((last_dt + dt) * 0.5)
				m.peak_acceleration = maxf(m.peak_acceleration, acceleration.length())
				m.velocity[id] = velocity
			m.previous = rendered
			var target := 0.0 if reverse else Schedule.DURATION
			var desired := target if elapsed >= Schedule.DURATION else (Schedule.DURATION - elapsed if reverse else elapsed)
			if absf(desired - v.p05_time) > 0.000001:
				m.deferred_frames += 1
			if is_equal_approx(v.p05_time, target):
				if m.completed < 0.0:
					m.completed = elapsed
				var final := v.p05.sample(target)
				for id: String in rendered:
					if not _check(Vector2(rendered[id]).distance_to(final[id]) < 0.0001, "rendered endpoint matches scheduled slot " + id, false):
						return
			else:
				done = false
		last_dt = dt
		if done and elapsed > Schedule.DURATION + 1.0 / hz:
			break
	for sq: Dictionary in source.rows:
		var m: Dictionary = measures[sq.id]
		_check(m.completed >= 0.0 and (is_equal_approx(m.completed, Schedule.DURATION) if skip < 5.0 else m.completed > Schedule.DURATION and m.deferred_frames > 0), "%s %dHz route completed" % [ids[sq.id], hz])
		print("P05_RENDERER_OBSERVATION ", JSON.stringify({"fleet": ids[sq.id], "hz": hz,
			"skip_s": skip, "reverse": reverse, "completion_s": m.completed,
			"deferred_frames": m.deferred_frames, "peak_speed": m.peak_speed,
			"peak_acceleration": m.peak_acceleration,
			"schedule_peak_ratio": m.peak_acceleration / schedule_peaks[sq.id] if schedule_peaks[sq.id] > 0.0 else null}))


func _positions(v: FleetRenderer.FleetVis, sq: Dictionary) -> Dictionary:
	var positions := {}
	var unrotate := Basis(Vector3.UP, sq.heading + PI * 0.5)
	var center := Vector3(sq.pos.x * CameraRig.S, 0.0, sq.pos.y * CameraRig.S)
	for i in v.slots.size():
		var slot: FleetRenderer.Slot = v.slots[i]
		# Slot.pos is the origin submitted to MultiMesh, whose dummy backend cannot read it back.
		var position := unrotate * (slot.pos - center) / CameraRig.S
		positions[v.p05.rows[i].id] = Vector2(-position.z, position.x)
	return positions


func _shape(id: String) -> int:
	return BattleRules.FORM_SHAPE[int(id.get_slice("-", 1)) - 1]


func _check(ok: bool, label: String, print_pass := true) -> bool:
	if not ok:
		failures += 1
	if not ok or print_pass:
		print("P05_RENDERER_CHECK ", ok, " ", label)
	return ok
