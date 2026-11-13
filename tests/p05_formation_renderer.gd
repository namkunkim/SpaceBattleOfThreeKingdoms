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
	for cadence: Array in [[60, 0.0], [30, 0.0], [120, 0.0], [60, 0.35], [60, 5.0]]:
		for reverse in [false, true]:
			_measure(renderer, source, bindings, cadence[0], cadence[1], reverse)
	# Motion outside the certified fixed origin is allowed to use the ordinary renderer.
	source.rows[0].pos += Vector2.ONE
	renderer.update(1.0 / 60.0)
	_check(renderer.vis[1].p05 == null and renderer.vis[2].p05 != null, "moving fleet alone returns to ordinary rendering")
	renderer.free()
	print("P05_RENDERER_RESULT failures=", failures)
	quit(0 if failures == 0 else 1)


func _measure(renderer: FleetRenderer, source: RouteSource, ids: Dictionary, hz: int, skip: float, reverse: bool) -> void:
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
			"peak_acceleration": m.peak_acceleration}))


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
