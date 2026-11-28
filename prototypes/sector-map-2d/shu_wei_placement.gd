extends "res://shu_fleet_controls.gd"

const FirePlayback := preload("res://siege_3d/fleet_fire_playback.gd")
const FireEffects := preload("res://siege_3d/fleet_fire_effects.gd")
const TacticalCombat := preload("res://tactical_fleet_combat.gd")

const WEI := Color("#ff996c")
const START_SPAN := 150.0
const LIFE_GAUGE_WIDTH := 64.0
const LIFE_GAUGE_HEIGHT := 7.0
const LIFE_GAUGE_GAP := 1.0
const CLOSE_SPAN := 58.0
const ANGLE_BLEND_START_SPAN := 26.0
const CLOSE_CAMERA_DIRECTION := Vector3(-29.0, 13.5, 22.0)
const CLOSE_CAMERA_DISTANCE_FACTOR := 1.65
const ORBIT_YAW_SPEED := 0.006
const ORBIT_PITCH_SPEED := 0.0045
const ORBIT_MIN_PITCH := deg_to_rad(6.0)
const ORBIT_MAX_PITCH := deg_to_rad(78.0)

var label_font := SystemFont.new()
var fire_playback := FirePlayback.new()
var map_fire_effects := FireEffects.new()
var tactical_combat := TacticalCombat.new()
var combat_poses: Array[Transform3D] = []
var muzzle_offsets := PackedFloat32Array()
var muzzle_history := {}
var orbit_dragging := false
var orbit_pivot := Vector2.ZERO
var orbit_yaw := 0.0
var orbit_pitch := 0.0


func _ready() -> void:
	super._ready()
	if units.is_empty():
		return
	_set_selection([])
	label_font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR", "sans-serif"])
	add_child(map_fire_effects)
	map_fire_effects.hide()
	_build_fire_playback()
	_frame_fleets(START_SPAN)


func _initialize_fleets() -> void:
	fleet.position = Vector3(-13.0, 0.0, 12.0)
	var shu_marker := FleetMarker.new(self, map_fleet_size, roles, ship_instances)
	shu_marker.space_under_symbol = LIFE_GAUGE_HEIGHT + LIFE_GAUGE_GAP
	_add_unit(fleet, ship_instances, shu_marker, map_formation)

	var wei := Node3D.new()
	wei.position = Vector3(13.0, 0.0, 12.0)
	wei.rotation.y = PI
	add_child(wei)
	var wei_ships := _copy_hulls(wei, 20)
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color(WEI, 0.40)
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for batch: MultiMeshInstance3D in wei.get_children():
		batch.material_overlay = paint
	var wei_marker := FleetMarker.new(self, FleetMarker.FleetSize.MEDIUM, roles, ship_instances)
	wei_marker.space_under_symbol = LIFE_GAUGE_HEIGHT + LIFE_GAUGE_GAP
	_add_unit(wei, wei_ships, wei_marker, FleetMarker.Formation.WEDGE)
	units[0].ink = JADE
	units[1].affiliation = "위 함대"
	units[1].faction = "WEI"
	units[1].ink = WEI


func _build_fire_playback() -> void:
	fire_playback.shu_count = units[0].ships.size()
	fire_playback.wei_count = units[1].ships.size()
	for unit in units:
		for role in unit.roles:
			muzzle_offsets.append(LENGTHS[role] * FORMATION_SCALE * 0.5)
	add_child(fire_playback)
	tactical_combat.reset(fire_playback.shu_count, fire_playback.wei_count)


func _process(delta: float) -> void:
	super._process(delta)
	if not fire_playback.is_inside_tree():
		return
	var is_3d := units[0].anchor.visible
	if not paused:
		# Sample short impact windows even when a frame is delayed.
		var steps := maxi(1, ceili(delta * 60.0))
		for i in steps:
			var previous := fire_playback.elapsed
			fire_playback.advance(delta / steps, is_3d)
			if fire_playback.elapsed < previous:
				tactical_combat.reset(fire_playback.shu_count, fire_playback.wei_count)
			tactical_combat.resolve_hits(fire_playback.active_shots, fire_playback.shu_count)
	if is_3d:
		_sync_combat_poses()
		_draw_live_weapons()


func _sync_combat_poses() -> void:
	combat_poses.clear()
	for unit in units:
		var motion: SingleFleetMotion = unit.motion
		for i in unit.ships.size():
			var attitude := Basis(Vector3.UP, motion.headings[i]) * Basis(Vector3.BACK, motion.pitches[i]) \
				* Basis(Vector3.RIGHT, motion.banks[i])
			combat_poses.append(Transform3D(attitude, motion.positions[i]))


func _draw_live_weapons() -> void:
	var shots: Array[Dictionary] = []
	var next_muzzles := {}
	for sampled in fire_playback.active_shots:
		var shot := sampled.duplicate()
		var source: int = shot.source
		var emitter: int = shot.emitter
		var last: Dictionary = muzzle_history.get(emitter, {})
		var pose := combat_poses[source]
		var bow := pose.origin + pose.basis.x * muzzle_offsets[source]
		if last.get("source") == source and float(last.phase) <= float(shot.phase):
			bow = last.point
		next_muzzles[emitter] = {"source": source, "phase": shot.phase, "point": bow}
		shot.origin = bow
		shots.append(shot)
	muzzle_history = next_muzzles
	map_fire_effects.render(shots, combat_poses, camera, 2.35)


func _fleet_midpoint() -> Vector3:
	return units[0].anchor.position.lerp(units[1].anchor.position, 0.5)


func _update_camera() -> void:
	super._update_camera()
	if not fire_playback.is_inside_tree():
		return
	if span >= ANGLE_BLEND_START_SPAN:
		orbit_yaw = 0.0
		orbit_pitch = 0.0
	var is_3d := units[0].anchor.visible
	map_fire_effects.visible = is_3d
	if not is_3d:
		fire_playback.stop_audio()
		muzzle_history.clear()
		return

	var close_weight := 1.0 - smoothstep(MIN_VIEW_SPAN, ANGLE_BLEND_START_SPAN, span)
	close_weight *= smoothstep(0.0, CAMERA_BLEND_DURATION, tilt_elapsed)
	if close_weight <= 0.0:
		return
	var target := Vector3(focus.x, 0.0, focus.y)
	var offset := camera.position - target
	var direction := offset.normalized().slerp(_close_camera_direction(), close_weight)
	var right := Vector3.UP.cross(direction).normalized()
	var distance := offset.length() * lerpf(1.0, CLOSE_CAMERA_DISTANCE_FACTOR, close_weight)
	camera.transform = Transform3D(Basis(right, direction.cross(right), direction),
		target + direction * distance)


func _at_orbit_zoom() -> bool:
	return is_equal_approx(span, MIN_VIEW_SPAN) and tilt_elapsed >= CAMERA_BLEND_DURATION


func _close_camera_direction() -> Vector3:
	var base := CLOSE_CAMERA_DIRECTION.normalized()
	var pitch := asin(base.y)
	pitch = clampf(pitch + orbit_pitch, ORBIT_MIN_PITCH, ORBIT_MAX_PITCH)
	var yaw := atan2(base.x, base.z) + orbit_yaw
	return Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))


func _handle_camera_orbit(event: InputEvent) -> bool:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed:
			if orbit_dragging:
				orbit_dragging = false
				return true
			return false
		orbit_dragging = event.alt_pressed and _at_orbit_zoom() and not (left_down or right_down or panning)
		if orbit_dragging:
			_cancel_zoom()
			var midpoint := _fleet_midpoint()
			orbit_pivot = Vector2(midpoint.x, midpoint.z)
		return orbit_dragging
	if event is InputEventMouseMotion and orbit_dragging:
		if not (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
			orbit_dragging = false
			return false
		if event.alt_pressed and _at_orbit_zoom():
			focus = orbit_pivot
			orbit_yaw = wrapf(orbit_yaw - event.relative.x * ORBIT_YAW_SPEED, -PI, PI)
			var default_pitch := asin(CLOSE_CAMERA_DIRECTION.normalized().y)
			orbit_pitch = clampf(orbit_pitch - event.relative.y * ORBIT_PITCH_SPEED,
				ORBIT_MIN_PITCH - default_pitch, ORBIT_MAX_PITCH - default_pitch)
			_update_camera()
		return true
	return false


func _navigation_hint() -> String:
	if _at_orbit_zoom():
		return "Alt + left drag: orbit   C: reset view   Left: select   Right: orders   Middle: pan   F: fire"
	if units[0].anchor.visible:
		return "Wheel: zoom   Middle drag: pan   Left: select   Right: orders   F: fire   4: close angle"
	return "Wheel: zoom   Middle drag: pan   Left: select   Right: move   F: fire   Space: pause   R: replay"


func _go_back() -> void:
	if is_equal_approx(span, MIN_VIEW_SPAN):
		_frame_fleets(CLOSE_SPAN)
	else:
		super._go_back()


func _unhandled_input(event: InputEvent) -> void:
	if _handle_camera_orbit(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and not units.is_empty():
		match event.keycode:
			KEY_2, KEY_3:
				_frame_fleets(START_SPAN if event.keycode == KEY_2 else CLOSE_SPAN)
			KEY_4:
				var center := get_viewport().get_visible_rect().get_center()
				_zoom_at(center, MIN_VIEW_SPAN / span)
			KEY_C:
				if _at_orbit_zoom():
					orbit_yaw = 0.0
					orbit_pitch = 0.0
					_update_camera()
			KEY_SPACE:
				paused = not paused
				fire_playback.set_audio_paused(paused)
			KEY_F:
				var from_wei: bool = not selected_units.is_empty() and selected_units.back() == 1
				var source := fire_playback.shu_count if from_wei else 0
				var target := 0 if from_wei else fire_playback.shu_count
				fire_playback.fire_salvo(source, target)
			KEY_R:
				fire_playback.restart()
				tactical_combat.reset(fire_playback.shu_count, fire_playback.wei_count)
				muzzle_history.clear()
			_:
				super._unhandled_input(event)
				return
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)


func _set_selection(indices: Array[int]) -> void:
	super._set_selection(indices)
	if not selected_units.is_empty() and marker_opacity > 0.5:
		panel.show()


func _frame_fleets(view_span: float) -> void:
	spread_positions.clear()
	_cancel_zoom()
	var midpoint := _fleet_midpoint()
	focus = Vector2(midpoint.x, midpoint.z)
	span = view_span
	_update_camera()


func _unit_marker_scale(index: int) -> float:
	if spread_positions.has(index):
		return super._unit_marker_scale(index)
	return clampf(START_SPAN / span, 0.30, 1.35)


func _life_gauge_rect(index: int) -> Rect2:
	var unit := units[index]
	var scale_factor := _unit_marker_scale(index)
	var center := _marker_center(index)
	var hull := unit.marker.hull_area(center, -unit.anchor.rotation.y, scale_factor)
	var content := unit.marker.roster_area(hull, scale_factor, _unit_roster(index))
	var symbol := unit.marker.symbol_position(center, content, scale_factor)
	var offset := Vector2(-LIFE_GAUGE_WIDTH * 0.5, FleetMarker.SYMBOL_HALF_HEIGHT + LIFE_GAUGE_GAP)
	return Rect2(symbol + offset * scale_factor,
		Vector2(LIFE_GAUGE_WIDTH, LIFE_GAUGE_HEIGHT) * scale_factor)


func _marker_color(_unit: FleetUnit) -> Color:
	return TacticalCombat.FORMATION_COLOR


func _tactical_point(ship_id: int, centers: PackedVector2Array) -> Vector2:
	var side := int(ship_id >= fire_playback.shu_count)
	var unit := units[side]
	var local_id := ship_id - fire_playback.shu_count * side
	var ship_at: Vector3 = unit.motion.positions[local_id]
	var offset := camera.unproject_position(ship_at) - camera.unproject_position(unit.anchor.position)
	return centers[side] + (offset * 0.48).limit_length(28.0 * _unit_marker_scale(side))


func _draw_fleet_labels() -> void:
	var show_life := marker_opacity > 0.01 and tactical_combat.life.size() == units.size()
	if show_life:
		var centers := PackedVector2Array([_marker_center(0), _marker_center(1)])
		if centers[0].distance_to(centers[1]) > 56.0:
			for shot in fire_playback.active_shots:
				var origin := _tactical_point(shot.source, centers)
				var target := _tactical_point(shot.target, centers)
				tactical_combat.draw_shot(selection, shot, origin, target, marker_opacity)
	var view := get_viewport().get_visible_rect()
	for i in units.size():
		var area := _fleet_area(i)
		if not view.intersects(area):
			continue
		if show_life:
			var gauge := _life_gauge_rect(i)
			var scale_factor := _unit_marker_scale(i)
			selection.draw_rect(gauge, Color(Color("#451d2b"), marker_opacity))
			var fill := gauge.grow(-scale_factor)
			fill.size.x *= tactical_combat.life_fraction(i)
			selection.draw_rect(fill, Color(TacticalCombat.FORMATION_COLOR, marker_opacity))
			selection.draw_rect(gauge, Color(Color("#9c4655"), marker_opacity), false, scale_factor)
			continue
		var unit := units[i]
		var caption := unit.affiliation
		var width := label_font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		var x := clampf(area.get_center().x - width * 0.5, 12.0,
			maxf(12.0, view.end.x - width - 12.0))
		var y := clampf(area.end.y + 17.0, 82.0, view.end.y - 17.0)
		selection.draw_rect(Rect2(x - 6.0, y - 16.0, width + 12.0, 24.0), Color("#101a29"))
		selection.draw_string(label_font, Vector2(x, y), caption, HORIZONTAL_ALIGNMENT_LEFT,
			-1, 16, unit.ink)
