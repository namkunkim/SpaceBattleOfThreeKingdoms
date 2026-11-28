extends "res://shu_fleet_movement.gd"

const FleetMotion := preload("res://fleet_poc_motion.gd")
const SingleFleetMotion := preload("res://single_fleet_motion.gd")
const FleetMarker := preload("res://shu_fleet_map_marker.gd")
const CAMERA_TILT_START := 120.0
const MIN_VIEW_SPAN := 21.0
const ROSTER_START_SPAN := 540.0
const ROSTER_REVEAL_INTERVAL := 0.045
const CAMERA_BLEND_DURATION := 0.30
const FLIGHT_TIME_SCALE := 10.0
const DRAG_THRESHOLD := 8.0
const PANEL_SIZE := Vector2(344, 216)
const ROLE_NAMES := ["전열함", "강습항모", "포격전함", "보급수리함",
	"공성함", "요격기", "전자전함", "고속공격함"]
enum Order { NONE, MOVE, FACE }

@export var map_fleet_size: FleetMarker.FleetSize = FleetMarker.FleetSize.LARGE
@export var map_formation: FleetMarker.Formation = FleetMarker.Formation.CIRCLE

@export var single_fleet_3d := false
@export var fleet_orders_enabled := true

class FleetUnit:
	var anchor: Node3D
	var motion: Variant
	var marker: FleetMarker
	var formation: FleetMarker.Formation
	var ships: Array[Dictionary]
	var roles: Array[int]
	var affiliation := "촉 함대"
	var ink := Color.WHITE
	var faction := "SHU"


var units: Array[FleetUnit] = []
var selected_units: Array[int] = []
var spread_positions: Dictionary[int, Vector2] = {}
var title_label: Label
var manifest_labels: Array[Label] = []
const EXTRA_STARTS: Array[Vector2] = [
	Vector2(-2470, 12), Vector2(-1660, 20), Vector2(-940, 25),
	Vector2(630, 12), Vector2(1440, 20), Vector2(2240, 12),
	Vector2(-60, -1480), Vector2(35, 725), Vector2(55, 1540),
]
var marker_scale := 0.35
var formation_center := Vector3.ZERO
var marker_opacity := 1.0
var desired_roster := 0
var visible_roster := 0
var reveal_elapsed := 0.0
var tilt_elapsed := 0.0
var zoom_tween: Tween
var wheel_span := 0.0
var focus := Vector2.ZERO
var span := 0.0
var paused := false
var order := Order.NONE
var panning := false
var left_down := false
var right_down := false
var gesture_start := Vector2.ZERO
var gesture_end := Vector2.ZERO
var panel := PanelContainer.new()
var move_button: Button
var face_button: Button
var status_label: Label


func _ready() -> void:
	super._ready()
	if recording or "--verify-fleet" in OS.get_cmdline_user_args():
		panel.free()
		return
	_initialize_fleets()
	span = _overview_span()
	_build_tactics()
	_build_navigation()
	if single_fleet_3d:
		_set_selection([0])
		focus = Vector2(fleet.position.x, fleet.position.z)
		span = 38.0
		tilt_elapsed = CAMERA_BLEND_DURATION
	_update_camera()


func _initialize_fleets() -> void:
	var markers: Dictionary[FleetMarker.FleetSize, FleetMarker] = {}
	for i in FleetMarker.FleetSize.size():
		var size: FleetMarker.FleetSize = i
		markers[size] = FleetMarker.new(self, size, roles, ship_instances)
	_add_unit(fleet, ship_instances, markers[map_fleet_size], map_formation)
	for i in range(0 if single_fleet_3d else EXTRA_STARTS.size()):
		var point := EXTRA_STARTS[i]
		var anchor := Node3D.new()
		anchor.position = Vector3(point.x, 0.0, point.y)
		add_child(anchor)
		var size: FleetMarker.FleetSize = i % FleetMarker.FleetSize.size()
		var formation: FleetMarker.Formation = i % FleetMarker.Formation.size()
		_add_unit(anchor, _copy_hulls(anchor, 20 * (size + 1)), markers[size], formation)
	if not single_fleet_3d:
		units[0].motion.move_to(fleet, Vector3(ROUTE_END.x, 0.0, ROUTE_END.y))
		for slot in slots:
			formation_center += slot
		formation_center /= slots.size()


func _process(delta: float) -> void:
	if units.is_empty():
		super._process(delta)
		return
	if not paused:
		for unit in units:
			if unit.motion.moving:
				unit.motion.advance(unit.anchor, delta if single_fleet_3d else delta * FLIGHT_TIME_SCALE)
				_sync_ships(unit)
	if visible_roster < desired_roster:
		reveal_elapsed += delta
		if reveal_elapsed >= ROSTER_REVEAL_INTERVAL:
			reveal_elapsed = minf(reveal_elapsed - ROSTER_REVEAL_INTERVAL, ROSTER_REVEAL_INTERVAL)
			visible_roster += 1
	else:
		reveal_elapsed = 0.0
		if span < CAMERA_TILT_START and tilt_elapsed < CAMERA_BLEND_DURATION:
			tilt_elapsed = minf(tilt_elapsed + delta, CAMERA_BLEND_DURATION)
			_update_camera()
	if panel.visible:
		_update_status()
	selection.queue_redraw()


func _add_unit(anchor: Node3D, ships: Array[Dictionary], marker: FleetMarker,
		formation: FleetMarker.Formation) -> void:
	var unit := FleetUnit.new()
	unit.anchor = anchor
	unit.ships = ships
	unit.marker = marker
	unit.formation = formation
	unit.roles = roles.slice(0, ships.size())
	var layout := slots if anchor == fleet else _formation_slots(ships.size(), formation)
	if single_fleet_3d:
		unit.motion = SingleFleetMotion.new(anchor, layout, unit.roles)
	else:
		unit.motion = FleetMotion.new(anchor, layout, unit.roles)
	_sync_ships(unit)
	units.append(unit)


func _formation_slots(count: int, formation: FleetMarker.Formation) -> Array[Vector3]:
	var positions: Array[Vector3] = [Vector3.ZERO]
	for i in range(1, count):
		var rank := floori(float(i - 1) / 3.0)
		var tier := (i - 1) % 3 - 1
		var point := _rank_position(rank, formation)
		positions.append(Vector3(point.x, tier * 1.25, point.y) * FORMATION_SCALE)
	return positions


func _rank_position(rank: int, formation: FleetMarker.Formation) -> Vector2:
	match formation:
		FleetMarker.Formation.COLUMN:
			return Vector2(-3.5 - rank * 2.0, 0.0)
		FleetMarker.Formation.WEDGE:
			var row := 0
			var column := rank
			while column > row:
				column -= row + 1
				row += 1
			return Vector2(-3.5 - row * 2.3, (column - row * 0.5) * 2.5)
		FleetMarker.Formation.FISH_SCALE:
			var row := rank >> 2
			var column := rank % 4
			return Vector2(-3.5 - row * 2.4 - absf(column - 1.5) * 0.5,
				(column - 1.5) * 2.3 + (row % 2) * 1.1)
		FleetMarker.Formation.CIRCLE:
			var ring := 0 if rank < 8 else 1
			var angle := TAU * float(rank if ring == 0 else rank - 8) / (8.0 if ring == 0 else 12.0)
			return Vector2(-8.0, 0.0) + Vector2.from_angle(angle) * (3.5 + ring * 2.6)
		_:
			var wing := -1.0 if rank % 2 == 0 else 1.0
			var distance := 1.0 + float(rank >> 1)
			return Vector2(-3.5 - distance * 0.65, wing * distance * 2.15)


func _copy_hulls(anchor: Node3D, count: int) -> Array[Dictionary]:
	var batches: Dictionary[MultiMesh, MultiMesh] = {}
	var sizes: Dictionary[MultiMesh, int] = {}
	var copies: Array[Dictionary] = []
	for i in count:
		var source: MultiMesh = ship_instances[i].mesh
		sizes[source] = sizes.get(source, 0) + 1
	for source in sizes:
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = source.mesh
		instances.instance_count = sizes[source]
		batches[source] = instances
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = instances
		batch.layers = 2
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		anchor.add_child(batch)
	for i in count:
		var original := ship_instances[i]
		copies.append({"mesh": batches[original.mesh], "index": original.index, "model": original.model})
	return copies



func _sync_ships(unit: FleetUnit) -> void:
	var local := unit.anchor.transform.affine_inverse()
	for i in unit.ships.size():
		var ship := unit.ships[i]
		var attitude := Basis(Vector3.UP, unit.motion.headings[i])
		if single_fleet_3d:
			var motion: SingleFleetMotion = unit.motion
			attitude = attitude * Basis(Vector3.BACK, motion.pitches[i]) * Basis(Vector3.RIGHT, motion.banks[i])
		var world := Transform3D(attitude, unit.motion.positions[i])
		ship.mesh.set_instance_transform(ship.index, local * world * ship.model)


func _overview_span() -> float:
	return get_viewport().get_visible_rect().size.y / map.fit_zoom()


func _update_camera() -> void:
	var roster_progress := 1.0 - smoothstep(log(CAMERA_TILT_START), log(ROSTER_START_SPAN), log(span))
	desired_roster = ceili(roster_progress * FleetMarker.EXTRA_HULLS[FleetMarker.FleetSize.LARGE])
	visible_roster = mini(visible_roster, desired_roster)
	if span >= CAMERA_TILT_START:
		tilt_elapsed = 0.0
	# Finish the 2D illustration before allowing a quick zoom to start tilting.
	var transition := smoothstep(0.0, CAMERA_BLEND_DURATION, tilt_elapsed)
	var view_span := lerpf(maxf(span, CAMERA_TILT_START), span, transition)
	var blend := 1.0 - smoothstep(45.0, CAMERA_TILT_START, view_span)
	var elevation := deg_to_rad(lerpf(90.0, 27.0, blend))
	var radial := Vector3(0.0, sin(elevation), cos(elevation))
	var target := Vector3(focus.x, 0.0, focus.y)
	var distance := view_span / lerpf(0.035, 0.56, blend)
	camera.transform = Transform3D(
		Basis(Vector3.RIGHT, radial.cross(Vector3.RIGHT), radial), target + radial * distance)
	var near_plane := maxf(0.3, distance - 2700.0)
	if blend <= 0.0:
		camera.set_orthogonal(view_span, near_plane, distance + 14000.0)
	else:
		camera.set_frustum(view_span * near_plane / distance, Vector2.ZERO, near_plane, distance + 14000.0)
	for unit in units:
		unit.anchor.visible = blend > 0.001
	var image_zoom := 1.0 - smoothstep(log(CAMERA_TILT_START), log(_overview_span()), log(view_span))
	marker_scale = lerpf(0.35, 1.12, image_zoom)
	marker_opacity = 1.0 - smoothstep(0.10, 0.42, blend)
	map_opacity = 1.0 - smoothstep(0.0, 0.75, blend)
	map.center = focus
	map.zoom = get_viewport().get_visible_rect().size.y / view_span
	map.modulate.a = map_opacity
	map.visible = map_opacity > 0.001
	map.queue_redraw()
	selection.queue_redraw()


func _game_point(pixel: Vector2) -> Variant:
	var origin := camera.project_ray_origin(pixel)
	var direction := camera.project_ray_normal(pixel)
	return Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)


func _minimum_view_span() -> float:
	return MIN_VIEW_SPAN


func _zoom_at(pixel: Vector2, ratio: float) -> void:
	spread_positions.clear()
	var anchor: Variant = _game_point(pixel)
	var prior_span := wheel_span if zoom_tween != null and zoom_tween.is_running() else span
	_cancel_zoom()
	wheel_span = clampf(prior_span * ratio, _minimum_view_span(), _overview_span() * 1.35)
	zoom_tween = create_tween()
	zoom_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	zoom_tween.tween_method(_apply_anchored_zoom.bind(pixel, anchor), span, wheel_span, 0.28)


func _apply_anchored_zoom(value: float, pixel: Vector2, anchor: Variant) -> void:
	span = value
	_update_camera()
	var after: Variant = _game_point(pixel)
	if anchor is Vector3 and after is Vector3:
		var offset: Vector3 = anchor - after
		focus += Vector2(offset.x, offset.z)
		_update_camera()


func _cancel_zoom() -> void:
	if zoom_tween != null:
		zoom_tween.kill()
		zoom_tween = null



func _unhandled_input(event: InputEvent) -> void:
	if units.is_empty():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_clear_gestures()
				_set_selection([])
			KEY_SPACE:
				if fleet_orders_enabled:
					paused = not paused
			KEY_2, KEY_3, KEY_4:
				spread_positions.clear()
				_cancel_zoom()
				var point := _active_unit().anchor.position
				focus = Vector2(point.x, point.z)
				span = {KEY_2: 410.0, KEY_3: 110.0, KEY_4: _minimum_view_span()}[event.keycode]
				_update_camera()
			KEY_HOME, KEY_1:
				_show_overview()
			_:
				return
	elif event is InputEventMouseMotion:
		if panning:
			var before: Variant = _game_point(event.position - event.relative)
			var after: Variant = _game_point(event.position)
			if before is Vector3 and after is Vector3:
				var offset: Vector3 = before - after
				focus += Vector2(offset.x, offset.z)
				_update_camera()
		elif left_down or right_down:
			gesture_end = event.position
		else:
			return
	elif event is InputEventMouseButton:
		_handle_button(event)
	else:
		return
	get_viewport().set_input_as_handled()


func _handle_button(event: InputEventMouseButton) -> void:
	var point := event.position
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN:
			if event.pressed:
				var step := -1.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0
				_zoom_at(point, pow(1.26, step * maxf(0.2, event.factor)))
		MOUSE_BUTTON_MIDDLE:
			panning = event.pressed and not left_down and not right_down
			if panning:
				spread_positions.clear()
				_cancel_zoom()
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				if right_down or panning or (not selected_units.is_empty() and _summary_area().has_point(point)):
					return
				if order != Order.NONE:
					_issue_order(point)
					return
				left_down = true
				gesture_start = point
				gesture_end = point
			elif left_down:
				left_down = false
				_select_on_release(point, event.shift_pressed)
		MOUSE_BUTTON_RIGHT:
			if not fleet_orders_enabled:
				return
			if event.pressed:
				if panning or left_down or (selected_units.is_empty() and _units_at(point).is_empty()):
					return
				right_down = true
				gesture_start = point
				gesture_end = point
			elif right_down:
				right_down = false
				_finish_right_click(point)


func _active_unit() -> FleetUnit:
	return units[0 if selected_units.is_empty() else selected_units.back()]


func _marker_center(index: int) -> Vector2:
	if spread_positions.has(index):
		return spread_positions[index]
	var anchor := units[index].anchor
	var center := anchor.to_global(formation_center)
	var point := anchor.position.lerp(center, smoothstep(0.70, 1.10, marker_scale))
	return camera.unproject_position(point)


func _unit_marker_scale(index: int) -> float:
	return minf(marker_scale, 0.45) if spread_positions.has(index) else marker_scale


func _unit_roster(index: int) -> int:
	return 0 if spread_positions.has(index) else mini(visible_roster, units[index].marker.roster_roles.size())


func _fleet_area(index: int) -> Rect2:
	var unit := units[index]
	if camera.is_position_behind(unit.anchor.position):
		return Rect2()
	var area := Rect2(camera.unproject_position(unit.anchor.position), Vector2.ZERO)
	if unit.anchor.visible:
		for position in unit.motion.positions:
			if not camera.is_position_behind(position):
				area = area.expand(camera.unproject_position(position))
		area = area.grow(13.0)
	if marker_opacity > 0.02:
		var marker_area := unit.marker.hit_area(_marker_center(index), -unit.anchor.rotation.y,
			_unit_marker_scale(index), _unit_roster(index))
		area = area.merge(marker_area) if area.has_area() else marker_area
	return area


func _units_at(point: Vector2) -> Array[int]:
	var hits: Array[int] = []
	for i in units.size():
		if _fleet_area(i).has_point(point):
			hits.append(i)
	# When choosing from a spread, its compact symbols take precedence.
	for index in hits:
		if spread_positions.has(index):
			return [index]
	return hits


func _spread_choices(indices: Array[int], point: Vector2) -> void:
	spread_positions.clear()
	var radius := maxf(58.0, 16.0 * indices.size())
	var screen := get_viewport().get_visible_rect().grow(-(radius + 35.0))
	var center := point.clamp(screen.position, screen.end)
	for i in indices.size():
		var angle := TAU * float(i) / indices.size()
		spread_positions[indices[i]] = center + Vector2.from_angle(angle) * radius


func _select_on_release(point: Vector2, additive: bool) -> void:
	var hits: Array[int] = []
	if gesture_start.distance_to(point) >= DRAG_THRESHOLD:
		var box := Rect2(gesture_start, point - gesture_start).abs()
		for i in units.size():
			if box.intersects(_fleet_area(i)):
				hits.append(i)
	else:
		hits = _units_at(point)
		if hits.size() > 1 and marker_opacity > 0.02:
			_spread_choices(hits, point)
			return
		if hits.size() > 1:
			var nearest := hits[0]
			for index in hits:
				if _marker_center(index).distance_squared_to(point) < _marker_center(nearest).distance_squared_to(point):
					nearest = index
			hits = [nearest]
	var result: Array[int] = []
	if additive:
		result.assign(selected_units)
	for index in hits:
		if not result.has(index):
			result.append(index)
	_set_selection(result)


func _summary_area() -> Rect2:
	return Rect2() if marker_opacity > 0.02 else Rect2(20, 70, 216, 34)


func _finish_right_click(point: Vector2) -> void:
	var dragged := gesture_start.distance_to(point) >= DRAG_THRESHOLD
	var hits := _units_at(gesture_start)
	if not dragged and hits.size() > 1 and marker_opacity > 0.02:
		_spread_choices(hits, gesture_start)
		return
	if not dragged and (not hits.is_empty()
			or (not selected_units.is_empty() and _summary_area().has_point(gesture_start))):
		if not hits.is_empty() and not selected_units.has(hits[0]):
			_set_selection([hits[0]])
		spread_positions.clear()
		panel.show()
		return
	if selected_units.is_empty() or _summary_area().has_point(gesture_start):
		return
	spread_positions.clear()
	var target: Variant = _game_point(gesture_start)
	if not _valid_target(target):
		return
	var facing: Variant = null
	var direction: Variant = _game_point(point)
	if dragged and direction is Vector3:
		var offset: Vector3 = direction - target
		if offset.length_squared() > 0.000001:
			facing = atan2(-offset.z, offset.x)
	_move_selected(target, facing)
	_set_order(Order.NONE)


func _move_selected(target: Vector3, facing: Variant = null) -> void:
	var origin := _active_unit().anchor.position
	# Preserve relative fleet positions when issuing one group destination.
	for index in selected_units:
		if not _valid_target(target + units[index].anchor.position - origin):
			return
	for index in selected_units:
		var unit := units[index]
		var destination := target + unit.anchor.position - origin
		unit.motion.move_to(unit.anchor, destination, facing)


func _valid_target(point: Variant) -> bool:
	return point is Vector3 and MAP_SCRIPT.MAP.has_point(Vector2(point.x, point.z))


func _issue_order(pixel: Vector2) -> void:
	var point: Variant = _game_point(pixel)
	if not _valid_target(point):
		return
	if order == Order.MOVE:
		_move_selected(point)
	elif order == Order.FACE:
		for index in selected_units:
			var unit := units[index]
			unit.motion.face(unit.anchor, point)
	_set_order(Order.NONE)


func _clear_gestures() -> void:
	left_down = false
	right_down = false
	panning = false


func _set_selection(indices: Array[int]) -> void:
	selected_units = indices
	spread_positions.clear()
	if selected_units.is_empty():
		panel.hide()
		_set_order(Order.NONE)
	else:
		title_label.text = ("%s %02d  ·  %d척" %
			[_active_unit().affiliation, selected_units[0] + 1, _selected_ship_count()]
			if selected_units.size() == 1 else "함대 %d개 선택  ·  %d척" %
				[selected_units.size(), _selected_ship_count()])
		for role in manifest_labels.size():
			manifest_labels[role].text = "%s  %d" % [ROLE_NAMES[role],
				_selected_ship_count(role)]


func _selected_ship_count(role := -1) -> int:
	var count := 0
	for index in selected_units:
		var manifest := units[index].roles
		count += manifest.size() if role < 0 else manifest.count(role)
	return count


func _set_order(value: Order) -> void:
	order = value
	move_button.set_pressed_no_signal(order == Order.MOVE)
	face_button.set_pressed_no_signal(order == Order.FACE)


func _toggle_order(value: Order) -> void:
	_set_order(Order.NONE if order == value else value)


func _build_navigation() -> void:
	var toolbar := HBoxContainer.new()
	toolbar.name = "MapNavigation"
	selection.get_parent().add_child(toolbar)
	toolbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	toolbar.offset_left = -199.0
	toolbar.offset_right = -18.0
	toolbar.offset_top = 10.0
	toolbar.offset_bottom = 42.0
	toolbar.alignment = BoxContainer.ALIGNMENT_END
	toolbar.add_theme_constant_override("separation", 6)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR", "sans-serif"])
	var back := _make_button(toolbar, "뒤로", font, Vector2(72.0, 32.0))
	back.tooltip_text = "3D에서는 2D 지도로, 2D에서는 전체 지도로 돌아갑니다"
	back.pressed.connect(_go_back)
	var zoom_out := _make_button(toolbar, "−", font, Vector2(42.0, 32.0))
	zoom_out.tooltip_text = "축소"
	zoom_out.pressed.connect(_zoom_from_toolbar.bind(1.26))
	var zoom_in := _make_button(toolbar, "+", font, Vector2(42.0, 32.0))
	zoom_in.tooltip_text = "확대"
	zoom_in.pressed.connect(_zoom_from_toolbar.bind(1.0 / 1.26))


func _zoom_from_toolbar(ratio: float) -> void:
	var view := get_viewport().get_visible_rect()
	var anchor := view.get_center()
	var anchor_node := _active_unit().anchor
	if not selected_units.is_empty() and not camera.is_position_behind(anchor_node.position):
		var fleet_pixel := camera.unproject_position(anchor_node.position)
		if view.has_point(fleet_pixel):
			anchor = fleet_pixel
	_zoom_at(anchor, ratio)


func _go_back() -> void:
	spread_positions.clear()
	if span < CAMERA_TILT_START or (zoom_tween != null and zoom_tween.is_running()
			and wheel_span < CAMERA_TILT_START):
		_cancel_zoom()
		span = CAMERA_TILT_START
		_update_camera()
	else:
		_show_overview()


func _show_overview() -> void:
	spread_positions.clear()
	_cancel_zoom()
	focus = Vector2.ZERO
	span = _overview_span()
	_update_camera()


func _build_tactics() -> void:
	selection.get_parent().add_child(panel)
	panel.position = Vector2(20, 109)
	panel.custom_minimum_size = PANEL_SIZE
	var column := VBoxContainer.new()
	panel.add_child(column)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic", "Noto Sans CJK KR", "sans-serif"])
	title_label = Label.new()
	title_label.add_theme_font_override("font", font)
	column.add_child(title_label)
	var formation := Label.new()
	formation.text = "기함 선도 · 3개 고도층"
	formation.add_theme_font_override("font", font)
	column.add_child(formation)
	var manifest := GridContainer.new()
	manifest.columns = 2
	column.add_child(manifest)
	for role in ROLE_NAMES.size():
		var label := Label.new()
		label.text = "%s  %d" % [ROLE_NAMES[role], roles.count(role)]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_override("font", font)
		manifest.add_child(label)
		manifest_labels.append(label)
	status_label = Label.new()
	status_label.add_theme_font_override("font", font)
	column.add_child(status_label)
	var buttons := HBoxContainer.new()
	buttons.visible = fleet_orders_enabled
	status_label.visible = fleet_orders_enabled
	column.add_child(buttons)
	move_button = _make_button(buttons, "이동", font)
	face_button = _make_button(buttons, "방향 전환", font)
	move_button.toggle_mode = true
	face_button.toggle_mode = true
	move_button.pressed.connect(_toggle_order.bind(Order.MOVE))
	face_button.pressed.connect(_toggle_order.bind(Order.FACE))
	_make_button(buttons, "정지", font).pressed.connect(func() -> void:
		for index in selected_units:
			units[index].motion.stop()
		_set_order(Order.NONE))
	panel.hide()


func _update_status() -> void:
	if order == Order.MOVE:
		status_label.text = "지도에서 이동할 지점을 클릭하세요"
	elif order == Order.FACE:
		status_label.text = "지도에서 바라볼 방향을 클릭하세요"
	elif paused:
		status_label.text = "일시 정지"
	elif single_fleet_3d:
		status_label.text = _active_unit().motion.status_text()
	elif _active_unit().motion.turning:
		status_label.text = "선회 중"
	elif _active_unit().motion.moving:
		status_label.text = "이동 중"
	else:
		status_label.text = "대기 중"


func _make_button(parent: HBoxContainer, title: String, font: Font,
		minimum_size := Vector2(106, 30)) -> Button:
	var button := Button.new()
	button.text = title
	button.add_theme_font_override("font", font)
	button.custom_minimum_size = minimum_size
	parent.add_child(button)
	return button


func _draw_fleet_overlay() -> void:
	if units.is_empty():
		super._draw_fleet_overlay()
		return
	_draw_fleet_labels()
	var font := ThemeDB.fallback_font
	var screen := get_viewport().get_visible_rect().size
	selection.draw_rect(Rect2(Vector2.ZERO, Vector2(screen.x, 52)), Color("#101a29"))
	selection.draw_string(font, Vector2(22, 33),
		"2D STRATEGIC MAP" if map_opacity > 0.5 else "3D FLEET VIEW",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#d8e7fb"))
	selection.draw_string(font, Vector2(280, 32), _navigation_hint(),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7cadf"))
	var view := get_viewport().get_visible_rect()
	if single_fleet_3d or map_opacity > 0.001:
		for unit in units:
			_draw_active_route(unit)
	for i in units.size():
		var unit := units[i]
		if camera.is_position_behind(unit.anchor.position):
			continue
		var center := _marker_center(i)
		var area := _fleet_area(i)
		if not view.intersects(area.grow(1.0)):
			continue
		if marker_opacity > 0.001:
			unit.marker.draw(selection, center, -unit.anchor.rotation.y, unit.formation,
				_unit_marker_scale(i), marker_opacity, _unit_roster(i), _marker_color(unit))
		if selected_units.has(i):
			var ink := JADE if unit.ink == Color.WHITE else unit.ink
			selection.draw_rect(area, Color(ink, 0.8), false, 1.0)
	_draw_fleet_impacts()
	if not selected_units.is_empty():
		var summary := _summary_area()
		if summary.has_area():
			var label := ("%s %02d  /  %d SHIPS" %
				[_active_unit().faction, selected_units[0] + 1, _selected_ship_count()]
				if selected_units.size() == 1 else "%d FLEETS  /  %d SHIPS" %
					[selected_units.size(), _selected_ship_count()])
			selection.draw_rect(summary, Color("#101a29"))
			selection.draw_string(font, summary.position + Vector2(10, 23), label,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, JADE)
	if left_down and gesture_start.distance_to(gesture_end) >= DRAG_THRESHOLD:
		var box := Rect2(gesture_start, gesture_end - gesture_start).abs()
		selection.draw_rect(box, Color(JADE, 0.12))
		selection.draw_rect(box, JADE, false, 1.0)
	if right_down and gesture_start.distance_to(gesture_end) >= DRAG_THRESHOLD:
		_draw_direction(gesture_start, gesture_end, JADE, 8.0)


func _navigation_hint() -> String:
	return ("Wheel: zoom   Middle drag: pan   Left: select   Right: orders   Space: pause"
		if fleet_orders_enabled else "Wheel: zoom   Middle drag: pan   Left: select   2: map   3: 3D")


func _marker_color(unit: FleetUnit) -> Color:
	return unit.ink


func _draw_fleet_labels() -> void:
	pass


func _draw_fleet_impacts() -> void:
	pass


func _draw_active_route(unit: FleetUnit) -> void:
	var motion: Variant = unit.motion
	if camera.is_position_behind(unit.anchor.position) or camera.is_position_behind(motion.destination):
		return
	var lead := camera.unproject_position(unit.anchor.position)
	var ink := JADE if unit.ink == Color.WHITE else unit.ink
	var show_route: bool = motion.has_fleet_order() if single_fleet_3d else motion.moving and not motion.turning
	if show_route:
		var end := camera.unproject_position(motion.destination)
		var opacity := maxf(0.74, map_opacity) if single_fleet_3d else map_opacity
		selection.draw_dashed_line(lead, end, Color(ink, 0.65 * opacity), 2.0, 12.0, true)
		selection.draw_circle(end, 4.0, Color(ink, opacity), false, 1.0, true)
		if motion.has_arrival_yaw:
			var direction := Basis(Vector3.UP, motion.arrival_yaw).x
			var ahead := camera.unproject_position(motion.destination + direction)
			_draw_direction(end, end + (ahead - end).normalized() * 28.0, Color(ink, opacity), 7.0)


func _draw_direction(start: Vector2, end: Vector2, color: Color, size: float) -> void:
	selection.draw_line(start, end, color, 2.0, true)
	_draw_arrowhead(end, (end - start).normalized(), color, size)


func _draw_arrowhead(tip: Vector2, heading: Vector2, color: Color, size: float) -> void:
	var base := tip - heading * size
	var wing := heading.orthogonal() * size * 0.55
	selection.draw_colored_polygon(PackedVector2Array([tip, base + wing, base - wing]), color)