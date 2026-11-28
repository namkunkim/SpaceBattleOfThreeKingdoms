extends "res://shu_fleet_movement.gd"

const FleetMotion := preload("res://fleet_poc_motion.gd")
const FleetMarker := preload("res://shu_fleet_map_marker.gd")
const CAMERA_TILT_START := 120.0
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

var map_marker: FleetMarker
var marker_scale := 0.35
var formation_center := Vector3.ZERO
var marker_opacity := 1.0
var desired_roster := 0
var visible_roster := 0
var reveal_elapsed := 0.0
var tilt_elapsed := 0.0
var zoom_tween: Tween
var wheel_span := 0.0
var motion: FleetMotion
var focus := Vector2.ZERO
var span := 0.0
var selected := false
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
	motion = FleetMotion.new(fleet, slots, roles)
	motion.move_to(fleet, Vector3(ROUTE_END.x, 0.0, ROUTE_END.y))
	map_marker = FleetMarker.new(self, map_fleet_size, roles, ship_instances)
	for slot in slots:
		formation_center += slot
	formation_center /= slots.size()
	span = _overview_span()
	_build_tactics()
	_build_navigation()
	_update_camera()


func _process(delta: float) -> void:
	if motion == null:
		super._process(delta)
		return
	if motion.moving and not paused:
		motion.advance(fleet, delta * FLIGHT_TIME_SCALE)
		_sync_ships()
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


func _sync_ships() -> void:
	var local := fleet.transform.affine_inverse()
	for i in ship_instances.size():
		var ship: Dictionary = ship_instances[i]
		var world := Transform3D(Basis(Vector3.UP, motion.headings[i]), motion.positions[i])
		ship.mesh.set_instance_transform(ship.index, local * world * ship.model)


func _overview_span() -> float:
	return get_viewport().get_visible_rect().size.y / map.fit_zoom()


func _update_camera() -> void:
	var roster_progress := 1.0 - smoothstep(log(CAMERA_TILT_START), log(ROSTER_START_SPAN), log(span))
	desired_roster = ceili(roster_progress * map_marker.roster_roles.size())
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
	fleet.visible = blend > 0.001
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


func _zoom_at(pixel: Vector2, ratio: float) -> void:
	var anchor: Variant = _game_point(pixel)
	var prior_span := wheel_span if zoom_tween != null and zoom_tween.is_running() else span
	_cancel_zoom()
	wheel_span = clampf(prior_span * ratio, 21.0, _overview_span() * 1.35)
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
	if motion == null:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				_clear_gestures()
				_set_selected(false)
			KEY_SPACE:
				paused = not paused
			KEY_2, KEY_3, KEY_4:
				_cancel_zoom()
				focus = Vector2(fleet.position.x, fleet.position.z)
				span = {KEY_2: 410.0, KEY_3: 110.0, KEY_4: 21.0}[event.keycode]
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
				_cancel_zoom()
		MOUSE_BUTTON_LEFT:
			if event.pressed:
				if right_down or panning or (selected and _summary_area().has_point(point)):
					return
				if order != Order.NONE:
					_issue_order(point)
					return
				left_down = true
				gesture_start = point
				gesture_end = point
			elif left_down:
				left_down = false
				var hit := _fleet_area().has_point(point)
				if gesture_start.distance_to(point) >= DRAG_THRESHOLD:
					hit = Rect2(gesture_start, point - gesture_start).abs().intersects(_fleet_area())
				if hit or not event.shift_pressed:
					_set_selected(hit)
		MOUSE_BUTTON_RIGHT:
			if event.pressed:
				if panning or left_down or (not selected and not _fleet_area().has_point(point)):
					return
				right_down = true
				gesture_start = point
				gesture_end = point
			elif right_down:
				right_down = false
				_finish_right_click(point)


func _marker_center() -> Vector2:
	var center := fleet.to_global(formation_center)
	var anchor := fleet.position.lerp(center, smoothstep(0.70, 1.10, marker_scale))
	return camera.unproject_position(anchor)


func _fleet_area() -> Rect2:
	var center := camera.unproject_position(fleet.position)
	var area := Rect2(center, Vector2.ZERO)
	for i in (motion.positions.size() if fleet.visible else 0):
		area = area.expand(camera.unproject_position(motion.positions[i]))
	area = area.grow(13.0)
	if marker_opacity > 0.02:
		area = area.merge(map_marker.hit_area(_marker_center(), -fleet.rotation.y, marker_scale, visible_roster))
	return area


func _summary_area() -> Rect2:
	return Rect2() if marker_opacity > 0.02 else Rect2(20, 70, 216, 34)



func _finish_right_click(point: Vector2) -> void:
	var dragged := gesture_start.distance_to(point) >= DRAG_THRESHOLD
	if not dragged and (_fleet_area().has_point(gesture_start)
			or (selected and _summary_area().has_point(gesture_start))):
		_set_selected(true)
		panel.show()
		return
	if not selected or _summary_area().has_point(gesture_start):
		return
	var target: Variant = _game_point(gesture_start)
	if not _valid_target(target):
		return
	var facing: Variant = null
	var direction: Variant = _game_point(point)
	if dragged and direction is Vector3:
		var offset: Vector3 = direction - target
		if offset.length_squared() > 0.000001:
			facing = atan2(-offset.z, offset.x)
	motion.move_to(fleet, target, facing)
	_set_order(Order.NONE)


func _valid_target(point: Variant) -> bool:
	return point is Vector3 and MAP_SCRIPT.MAP.has_point(Vector2(point.x, point.z))


func _issue_order(pixel: Vector2) -> void:
	var point: Variant = _game_point(pixel)
	if not _valid_target(point):
		return
	if order == Order.MOVE:
		motion.move_to(fleet, point)
	elif order == Order.FACE:
		motion.face(fleet, point)
	_set_order(Order.NONE)


func _clear_gestures() -> void:
	left_down = false
	right_down = false
	panning = false


func _set_selected(value: bool) -> void:
	selected = value
	if not selected:
		panel.hide()
		_set_order(Order.NONE)


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
	if selected and not camera.is_position_behind(fleet.position):
		var fleet_pixel := camera.unproject_position(fleet.position)
		if view.has_point(fleet_pixel):
			anchor = fleet_pixel
	_zoom_at(anchor, ratio)


func _go_back() -> void:
	if span < CAMERA_TILT_START or (zoom_tween != null and zoom_tween.is_running()
			and wheel_span < CAMERA_TILT_START):
		_cancel_zoom()
		span = CAMERA_TILT_START
		_update_camera()
	else:
		_show_overview()


func _show_overview() -> void:
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
	var title := Label.new()
	title.text = "촉 함대 01  ·  60척  ·  8개 함종"
	title.add_theme_font_override("font", font)
	column.add_child(title)
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
	status_label = Label.new()
	status_label.add_theme_font_override("font", font)
	column.add_child(status_label)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	move_button = _make_button(buttons, "이동", font)
	face_button = _make_button(buttons, "방향 전환", font)
	move_button.toggle_mode = true
	face_button.toggle_mode = true
	move_button.pressed.connect(_toggle_order.bind(Order.MOVE))
	face_button.pressed.connect(_toggle_order.bind(Order.FACE))
	_make_button(buttons, "정지", font).pressed.connect(func() -> void:
		motion.stop()
		_set_order(Order.NONE))
	panel.hide()


func _update_status() -> void:
	if order == Order.MOVE:
		status_label.text = "지도에서 이동할 지점을 클릭하세요"
	elif order == Order.FACE:
		status_label.text = "지도에서 바라볼 방향을 클릭하세요"
	elif paused:
		status_label.text = "일시 정지"
	elif motion.turning:
		status_label.text = "선회 중"
	elif motion.moving:
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
	if motion == null:
		super._draw_fleet_overlay()
		return
	var font := ThemeDB.fallback_font
	var screen := get_viewport().get_visible_rect().size
	selection.draw_rect(Rect2(Vector2.ZERO, Vector2(screen.x, 52)), Color("#101a29"))
	selection.draw_string(font, Vector2(22, 33),
		"2D STRATEGIC MAP" if map_opacity > 0.5 else "3D FLEET VIEW",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#d8e7fb"))
	selection.draw_string(font, Vector2(280, 32),
		"Wheel: zoom   Middle drag: pan   Left: select   Right: orders   Space: pause",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#b7cadf"))
	if map_opacity > 0.001:
		_draw_active_route()
	var center := _marker_center()
	if marker_opacity > 0.001:
		map_marker.draw(selection, center, -fleet.rotation.y, map_formation,
			marker_scale, marker_opacity, visible_roster)
	if selected:
		var area := _fleet_area()
		if not fleet.visible:
			var hull := map_marker.hull_area(center, -fleet.rotation.y, marker_scale)
			area = map_marker.roster_area(hull, marker_scale, visible_roster).grow(3.0)
		selection.draw_rect(area, Color(JADE, 0.8), false, 1.0)
		var summary := _summary_area()
		if summary.has_area():
			selection.draw_rect(summary, Color("#101a29"))
			selection.draw_string(font, summary.position + Vector2(10, 23), "SHU 01  /  60 SHIPS",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 16, JADE)
	if left_down and gesture_start.distance_to(gesture_end) >= DRAG_THRESHOLD:
		var box := Rect2(gesture_start, gesture_end - gesture_start).abs()
		selection.draw_rect(box, Color(JADE, 0.12))
		selection.draw_rect(box, JADE, false, 1.0)
	if right_down and gesture_start.distance_to(gesture_end) >= DRAG_THRESHOLD:
		_draw_direction(gesture_start, gesture_end, JADE, 8.0)


func _draw_active_route() -> void:
	var lead := camera.unproject_position(fleet.position)
	if motion.moving and not motion.turning:
		var end := camera.unproject_position(motion.destination)
		selection.draw_dashed_line(lead, end, Color(JADE, 0.65 * map_opacity), 2.0, 12.0, true)
		selection.draw_circle(end, 4.0, Color(JADE, map_opacity), false, 1.0, true)
		if motion.has_arrival_yaw:
			var direction := Basis(Vector3.UP, motion.arrival_yaw).x
			var ahead := camera.unproject_position(motion.destination + direction)
			_draw_direction(end, end + (ahead - end).normalized() * 28.0, Color(JADE, map_opacity), 7.0)


func _draw_direction(start: Vector2, end: Vector2, color: Color, size: float) -> void:
	selection.draw_line(start, end, color, 2.0, true)
	_draw_arrowhead(end, (end - start).normalized(), color, size)


func _draw_arrowhead(tip: Vector2, heading: Vector2, color: Color, size: float) -> void:
	var base := tip - heading * size
	var wing := heading.orthogonal() * size * 0.55
	selection.draw_colored_polygon(PackedVector2Array([tip, base + wing, base - wing]), color)