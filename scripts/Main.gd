extends Node2D

const BATTLESHIP_TOP: Texture2D = preload("res://assets/ships/concept_runtime/battleship_top_v2.png")
const FIRE_SUPPORT_TOP: Texture2D = preload("res://assets/ships/concept_runtime/fire_support_top_v2.png")
const SIEGE_SHIP_TOP: Texture2D = preload("res://assets/ships/concept_runtime/siege_ship_top_v2.png")
const ASSAULT_CARRIER_TOP: Texture2D = preload("res://assets/ships/concept_runtime/assault_carrier_top_v2.png")
const SUPPORT_SHIPS: Texture2D = preload("res://assets/ships/concept_atlases/support_ships_v1.png")
const SMALL_CRAFT: Texture2D = preload("res://assets/ships/concept_atlases/small_craft_v1.png")
const COMMANDER_SHEET: Texture2D = preload("res://assets/portraits/commanders_sheet_v1.png")
const BATTLEFIELD_BACKGROUND: Texture2D = preload("res://assets/backgrounds/red_cliffs_starfield_v1.png")
const COMBAT_VFX: Texture2D = preload("res://assets/vfx/fleet_combat_vfx_sheet_v1.png")
const VIEW := Rect2(38, 82, 1190, 650)
const PANEL_X := 1250.0
const BOTTOM_Y := 752.0
const FORMATIONS := ["횡진", "쐐기진", "방진"]
const FRIEND := Color("57c7ff")
const ALLY := Color("66e0b3")
const ENEMY := Color("ff726f")
const GOLD := Color("ffd675")
const POC_VERSION := "v0.9"
const FORMATION_TRANSITION_TIME := 1.4

var fleets: Array[Dictionary] = []
var selected := 0
var elapsed := 0.0
var paused := false
var stars: Array[Vector2] = []
var capture_mode := false
var capture_frames := 0
var playtest_mode := false
var playtest_frames := 0
var command_mode := "이동"
var salvo_source := -1
var salvo_target := -1
var salvo_started := -10.0

func _ready() -> void:
	DisplayServer.window_set_title("성한지 · 가시 함대전 POC")
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	playtest_mode = "--playtest" in OS.get_cmdline_user_args()
	_seed_stars()
	_fleets_setup()
	queue_redraw()

func _seed_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2080912
	for i in range(220):
		stars.append(Vector2(rng.randf_range(VIEW.position.x, VIEW.end.x), rng.randf_range(VIEW.position.y, VIEW.end.y)))

func _fleets_setup() -> void:
	fleets = [
		_fleet("F01", "유비 제1함대", "유비 · 제갈량", 0, "friend", Vector2(330, 420), -0.08, "횡진", 28, 91),
		_fleet("F02", "관우 기동함대", "관우 · 관평", 1, "friend", Vector2(260, 570), -0.18, "쐐기진", 22, 87),
		_fleet("A01", "손권 연합함대", "주유 · 노숙", 3, "ally", Vector2(430, 255), 0.08, "방진", 26, 94),
		_fleet("E01", "조조 전위함대", "조조 · 정욱", 4, "enemy", Vector2(900, 335), PI - 0.08, "횡진", 30, 82),
		_fleet("E02", "조조 우익함대", "조인 · 모개", 5, "enemy", Vector2(1010, 560), PI + 0.12, "쐐기진", 24, 78),
	]
	fleets[0].target = Vector2(650, 400)
	fleets[1].target = Vector2(590, 545)
	fleets[2].target = Vector2(670, 285)
	fleets[3].target = Vector2(730, 360)
	fleets[4].target = Vector2(770, 520)

func _fleet(id: String, title: String, commander: String, portrait: int, side: String, pos: Vector2, angle: float, formation: String, ships: int, morale: int) -> Dictionary:
	return {
		"id": id, "title": title, "commander": commander, "portrait": portrait, "side": side,
		"pos": pos, "angle": angle, "formation": formation, "ships": ships,
		"morale": morale, "target": pos, "speed": 24.0 if side != "enemy" else 17.0,
		"formation_from": formation, "formation_elapsed": FORMATION_TRANSITION_TIME,
		"shield": 0.76 if side != "enemy" else 0.61
	}

func _process(delta: float) -> void:
	elapsed += delta
	if not paused:
		for fleet in fleets:
			_move_fleet(fleet, delta)
			fleet.formation_elapsed = minf(FORMATION_TRANSITION_TIME, float(fleet.formation_elapsed) + delta)
	queue_redraw()
	if playtest_mode:
		_run_playtest()
	elif capture_mode:
		capture_frames += 1
		if capture_frames == 20:
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out/visible-fleet-poc"))
			var image := get_viewport().get_texture().get_image()
			image.save_png("res://out/visible-fleet-poc/visible-fleet-battle-1600x900.png")
			get_tree().quit()

func _run_playtest() -> void:
	playtest_frames += 1
	if playtest_frames == 5:
		var select_event := InputEventMouseButton.new()
		select_event.button_index = MOUSE_BUTTON_LEFT
		select_event.position = fleets[1].pos
		select_event.pressed = true
		_unhandled_input(select_event)
		assert(selected == 1)
	elif playtest_frames == 10:
		fleets[selected].speed = 72.0
		var move_event := InputEventMouseButton.new()
		move_event.button_index = MOUSE_BUTTON_RIGHT
		move_event.position = Vector2(590, 625)
		move_event.pressed = true
		_unhandled_input(move_event)
		assert((fleets[selected].target as Vector2).is_equal_approx(Vector2(590, 625)))
	elif playtest_frames == 45:
		var turn_event := InputEventKey.new()
		turn_event.keycode = KEY_E
		turn_event.pressed = true
		_unhandled_input(turn_event)
	elif playtest_frames == 55:
		var accepted := _handle_ui_click(Vector2(PANEL_X + 175, 565))
		assert(accepted)
		assert(String(fleets[selected].formation) == "방진")
	elif playtest_frames == 72:
		var command_accepted := _handle_ui_click(Vector2(540 + 2 * 142 + 63, 812))
		assert(command_accepted)
		assert(command_mode == "일제사격")
	elif playtest_frames == 78:
		var fire_event := InputEventMouseButton.new()
		fire_event.button_index = MOUSE_BUTTON_LEFT
		fire_event.position = fleets[3].pos
		fire_event.pressed = true
		_unhandled_input(fire_event)
		assert(salvo_source == selected)
		assert(salvo_target == 3)
		assert(float(fleets[3].shield) < 0.61)
	elif playtest_frames == 92:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out/visible-fleet-poc"))
		var salvo_image := get_viewport().get_texture().get_image()
		salvo_image.save_png("res://out/visible-fleet-poc/visible-fleet-salvo-command.png")
	elif playtest_frames == 145:
		paused = true
	elif playtest_frames == 150:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out/visible-fleet-poc"))
		var image := get_viewport().get_texture().get_image()
		image.save_png("res://out/visible-fleet-poc/visible-fleet-playtest-after-commands.png")
		print("VISIBLE_FLEET_POC_PLAYTEST_PASS selected=%s formation=%s position=%s" % [fleets[selected].id, fleets[selected].formation, fleets[selected].pos])
		get_tree().quit()

func _move_fleet(fleet: Dictionary, delta: float) -> void:
	var pos: Vector2 = fleet.pos
	var target: Vector2 = fleet.target
	var distance := pos.distance_to(target)
	if distance < 3.0:
		return
	var desired := pos.angle_to_point(target)
	fleet.angle = lerp_angle(float(fleet.angle), desired, minf(1.0, delta * 1.8))
	fleet.pos = pos.move_toward(target, minf(distance, float(fleet.speed) * delta))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_SPACE:
				paused = not paused
			KEY_Q:
				fleets[selected].angle = float(fleets[selected].angle) - 0.22
				fleets[selected].target = fleets[selected].pos
			KEY_E:
				fleets[selected].angle = float(fleets[selected].angle) + 0.22
				fleets[selected].target = fleets[selected].pos
			KEY_1, KEY_2, KEY_3:
				_set_formation(fleets[selected], FORMATIONS[int(event.keycode - KEY_1)])
		queue_redraw()
	if event is InputEventMouseButton and event.pressed:
		var mouse: Vector2 = event.position
		if event.button_index == MOUSE_BUTTON_LEFT:
			if _handle_ui_click(mouse):
				return
			_select_fleet(mouse)
		elif event.button_index == MOUSE_BUTTON_RIGHT and VIEW.has_point(mouse):
			fleets[selected].target = mouse
			queue_redraw()

func _handle_ui_click(mouse: Vector2) -> bool:
	for i in range(3):
		var rect := Rect2(PANEL_X + 20, 450 + i * 48, 310, 38)
		if rect.has_point(mouse):
			_set_formation(fleets[selected], FORMATIONS[i])
			queue_redraw()
			return true
	var pause_rect := Rect2(PANEL_X + 20, 660, 145, 44)
	if pause_rect.has_point(mouse):
		paused = not paused
		return true
	for i in range(6):
		var command_rect := Rect2(540 + i * 142, 782, 126, 62)
		if command_rect.has_point(mouse):
			command_mode = ["이동", "선회", "일제사격", "지속사격", "사격중지", "철수"][i]
			if command_mode == "사격중지":
				salvo_target = -1
				salvo_source = -1
				command_mode = "이동"
			queue_redraw()
			return true
	return false

func _set_formation(fleet: Dictionary, next_formation: String) -> void:
	if String(fleet.formation) == next_formation:
		return
	fleet.formation_from = fleet.formation
	fleet.formation = next_formation
	fleet.formation_elapsed = 0.0

func _select_fleet(mouse: Vector2) -> void:
	if command_mode == "일제사격" or command_mode == "지속사격":
		for i in range(fleets.size()):
			if fleets[i].side == "enemy" and (fleets[i].pos as Vector2).distance_to(mouse) < 70.0:
				_issue_salvo(selected, i)
				return
	var best := 60.0
	for i in range(fleets.size()):
		if fleets[i].side == "enemy":
			continue
		var d: float = (fleets[i].pos as Vector2).distance_to(mouse)
		if d < best:
			best = d
			selected = i
	queue_redraw()

func _issue_salvo(source_index: int, target_index: int) -> void:
	salvo_source = source_index
	salvo_target = target_index
	salvo_started = elapsed
	fleets[target_index].shield = maxf(0.0, float(fleets[target_index].shield) - 0.13)
	command_mode = "표적 교전"
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1600, 900), Color("050b17"))
	_draw_header()
	_draw_battlefield()
	_draw_right_panel()
	_draw_bottom_panel()

func _draw_header() -> void:
	draw_rect(Rect2(0, 0, 1600, 64), Color("091728"))
	draw_line(Vector2(0, 64), Vector2(1600, 64), Color("2d6585"), 2)
	_text(Vector2(38, 39), "성한지 · 적벽 성역 함대전 POC", 26, Color("e7f4ff"))
	_text(Vector2(520, 38), "TURN 08   ㅣ   교전 단계   ㅣ   전술 시간 03:42", 19, Color("8ecae6"))
	draw_rect(Rect2(930, 20, 270, 14), Color("162f46"), true)
	draw_rect(Rect2(930, 20, 198, 14), Color("48c9c2"), true)
	draw_rect(Rect2(930, 20, 270, 14), Color("6aa8c6"), false, 1)
	_text(Vector2(930, 55), "전술 우세도 73%", 12, Color("70d9e8"))
	_text(Vector2(1290, 38), "SPACE  %s" % ("재개" if paused else "일시정지"), 18, GOLD)

func _draw_battlefield() -> void:
	draw_rect(VIEW, Color("071221"), true)
	draw_texture_rect(BATTLEFIELD_BACKGROUND, VIEW, false, Color(0.70, 0.82, 0.90, 0.62))
	draw_rect(VIEW, Color(0.01, 0.035, 0.065, 0.30), true)
	draw_rect(VIEW, Color("28506a"), false, 2)
	_draw_nebula(Vector2(245, 235), 180, Color(0.08, 0.28, 0.48, 0.07))
	_draw_nebula(Vector2(965, 525), 230, Color(0.42, 0.12, 0.24, 0.07))
	_draw_nebula(Vector2(685, 305), 145, Color(0.12, 0.38, 0.34, 0.05))
	_draw_tactical_grid()
	for star in stars:
		var pulse := 0.45 + 0.25 * sin(elapsed * 0.8 + star.x)
		draw_circle(star, 0.7 if int(star.x) % 5 else 1.2, Color(0.55, 0.72, 0.9, pulse))
	# 장강 성운 띠
	var river := PackedVector2Array([Vector2(50, 525), Vector2(280, 470), Vector2(520, 500), Vector2(760, 440), Vector2(990, 470), Vector2(1210, 390)])
	draw_polyline(river, Color(0.12, 0.35, 0.48, 0.35), 42, true)
	draw_polyline(river, Color(0.22, 0.62, 0.72, 0.42), 2, true)
	# 전술 경계와 중심 목표
	draw_arc(Vector2(760, 410), 285, -1.15, 1.15, 64, Color(0.8, 0.18, 0.22, 0.75), 3)
	draw_circle(Vector2(690, 405), 7, GOLD, false, 2)
	_text(Vector2(704, 400), "화선 집중점", 14, GOLD)
	_draw_event_feed()
	for i in range(fleets.size()):
		_draw_fleet(fleets[i], i == selected)
	_draw_beams()
	_draw_radar()

func _draw_fleet(fleet: Dictionary, is_selected: bool) -> void:
	var pos: Vector2 = fleet.pos
	var angle: float = fleet.angle
	var color := _side_color(String(fleet.side))
	var offsets := _visual_formation_offsets(fleet)
	var target: Vector2 = fleet.target
	var moving := pos.distance_to(target) > 3.0
	if pos.distance_to(target) > 3.0:
		draw_dashed_line(pos, target, Color(color, 0.55), 2, 8)
		_draw_arrow(target, angle, color)
	if is_selected:
		draw_circle(pos, 72, Color(color, 0.12), true)
		_draw_vfx(pos, Vector2(158, 158), 3, Color(0.72, 1.0, 1.0, 0.18))
		draw_arc(pos, 74, 0, TAU, 64, GOLD, 2.5)
		draw_arc(pos, 165, 0, TAU, 72, Color(color, 0.22), 1.2)
		draw_circle(pos, 152, Color(color, 0.055), true)
	# 진형 외곽과 전진 방향
	var front := pos + Vector2(88, 0).rotated(angle)
	draw_line(pos, front, Color(color, 0.7), 2)
	_draw_arrow(front, angle, color)
	if is_selected or String(fleet.side) == "ally":
		_draw_squadron_fields(pos, angle, offsets, color)
	for j in range(offsets.size()):
		var ship_pos := pos + (offsets[j] as Vector2).rotated(angle)
		_draw_ship(ship_pos, angle, color, j == 0, j, moving, String(fleet.id))
	# 명패
	var label_pos := pos + Vector2(-68, -88)
	draw_rect(Rect2(label_pos - Vector2(7, 22), Vector2(168, 45)), Color(0.02, 0.06, 0.11, 0.88), true)
	draw_rect(Rect2(label_pos - Vector2(7, 22), Vector2(168, 45)), color if is_selected else Color(color, 0.7), false, 1.5)
	_draw_portrait(Rect2(label_pos + Vector2(-4, -18), Vector2(28, 35)), int(fleet.portrait), color)
	_text(label_pos + Vector2(31, 0), "%s  %d척" % [fleet.title, fleet.ships], 15, Color.WHITE)
	_text(label_pos + Vector2(31, 19), "%s · 사기 %d" % [fleet.formation, fleet.morale], 13, color)
	var bar_pos := label_pos + Vector2(31, 25)
	draw_rect(Rect2(bar_pos, Vector2(118, 4)), Color(0.08, 0.13, 0.18, 0.95), true)
	draw_rect(Rect2(bar_pos, Vector2(118.0 * float(fleet.shield), 4)), Color("45e0c4"), true)
	if float(fleet.formation_elapsed) < FORMATION_TRANSITION_TIME:
		var progress := float(fleet.formation_elapsed) / FORMATION_TRANSITION_TIME
		_text(label_pos + Vector2(31, 40), "대형 재편성 %d%%" % int(progress * 100.0), 11, GOLD)

func _draw_squadron_fields(pos: Vector2, angle: float, offsets: Array[Vector2], color: Color) -> void:
	var groups := int(ceil(float(offsets.size()) / 7.0))
	for group_index in range(groups):
		var from := group_index * 7
		var to := mini(offsets.size(), from + 7)
		var center := Vector2.ZERO
		for i in range(from, to):
			center += offsets[i]
		center /= float(to - from)
		var world_center := pos + center.rotated(angle)
		var radius := 26.0 + 3.0 * sin(elapsed * 1.7 + group_index)
		draw_circle(world_center, radius, Color(color, 0.045), true)
		draw_arc(world_center, radius, 0, TAU, 40, Color(color, 0.55), 1.6)
		draw_arc(world_center, radius - 4.0, -0.8, 1.4, 18, Color(0.75, 0.96, 1.0, 0.45), 1.2)

func _formation_offsets(formation: String, count: int) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for i in range(count):
		if formation == "횡진":
			var row := i / 10
			var col := i % 10
			result.append(Vector2(-row * 23.0, (col - 4.5) * 15.0 + row * 7.0))
		elif formation == "쐐기진":
			if i == 0:
				result.append(Vector2(38, 0))
			else:
				var rank := int((i + 1) / 2)
				var sign_y := -1.0 if i % 2 else 1.0
				result.append(Vector2(38 - rank * 14.0, sign_y * rank * 10.5))
		else:
			var col := i % 6
			var row := i / 6
			result.append(Vector2((col - 2.5) * 17.0, (row - 2.0) * 17.0))
	return result

func _visual_formation_offsets(fleet: Dictionary) -> Array[Vector2]:
	var target_offsets := _formation_offsets(String(fleet.formation), int(fleet.ships))
	if float(fleet.formation_elapsed) >= FORMATION_TRANSITION_TIME:
		return target_offsets
	var from_offsets := _formation_offsets(String(fleet.formation_from), int(fleet.ships))
	var t := smoothstep(0.0, 1.0, float(fleet.formation_elapsed) / FORMATION_TRANSITION_TIME)
	var result: Array[Vector2] = []
	for i in range(target_offsets.size()):
		result.append(from_offsets[i].lerp(target_offsets[i], t))
	return result

func _draw_ship(pos: Vector2, angle: float, color: Color, flagship: bool, ship_index: int, moving: bool, fleet_id: String) -> void:
	var class_index := _ship_class_index(fleet_id, ship_index)
	var length := 24.0 if flagship else (16.0 if class_index <= 3 else (12.5 if class_index <= 6 else 9.5))
	var width := 9.0 if flagship else (6.0 if class_index <= 3 else (4.8 if class_index <= 6 else 3.8))
	var forward := Vector2.RIGHT.rotated(angle)
	var lateral := forward.orthogonal()
	var aft := pos - forward * length
	# 항적과 엔진광
	if moving:
		draw_line(aft - forward * 4.0 + lateral * width * 0.45, aft - forward * (13.0 + length * 0.25) + lateral * width * 0.45, Color(color, 0.16), 1.2)
		draw_line(aft - forward * 4.0 - lateral * width * 0.45, aft - forward * (13.0 + length * 0.25) - lateral * width * 0.45, Color(color, 0.16), 1.2)
		draw_circle(aft + lateral * width * 0.46, width * 0.55, Color(0.25, 0.75, 1.0, 0.16), true)
		draw_circle(aft - lateral * width * 0.46, width * 0.55, Color(0.25, 0.75, 1.0, 0.16), true)
	# 선체 그림자와 다단 장갑 외곽
	var shadow := _ship_polygon(pos + Vector2(2.5, 3.0), angle, length, width)
	draw_colored_polygon(shadow, Color(0, 0, 0, 0.42))
	var hull := _ship_polygon(pos, angle, length, width)
	draw_colored_polygon(hull, color.darkened(0.28))
	draw_polyline(PackedVector2Array(Array(hull) + [hull[0]]), Color(color, 0.9), 1.1, true)
	# 함급별 상부 구조물: 전열함은 넓은 날개, 순양함은 장축 장갑, 구축함은 가는 선체.
	if flagship or class_index == 0:
		var wing_left := PackedVector2Array([pos - forward * length * 0.20, pos - forward * length * 0.58 + lateral * width * 1.65, pos + forward * length * 0.18 + lateral * width * 0.88])
		var wing_right := PackedVector2Array([pos - forward * length * 0.20, pos - forward * length * 0.58 - lateral * width * 1.65, pos + forward * length * 0.18 - lateral * width * 0.88])
		draw_colored_polygon(wing_left, color.darkened(0.42))
		draw_colored_polygon(wing_right, color.darkened(0.42))
	elif class_index < 3:
		draw_line(pos - forward * length * 0.70, pos + forward * length * 0.58, color.lightened(0.32), 1.8)
	# 독자 제작 프리렌더 함선을 절차형 충돌 실루엣 위에 합성한다.
	# 원본 해상도는 LOD의 근접 단계에서도 재사용할 수 있도록 충분히 크게 유지한다.
	var atlas := _ship_class_atlas(class_index)
	var source_rect := _ship_class_source_rect(class_index)
	var sprite_size := Vector2(length * 2.30, width * 2.50)
	var sprite_modulate := Color(0.95, 0.42, 0.42, 0.92) if color.is_equal_approx(ENEMY) else Color(0.62, 0.82, 0.96, 0.94)
	if color.is_equal_approx(ALLY):
		sprite_modulate = Color(0.56, 0.96, 0.79, 0.94)
	draw_set_transform(pos, angle, Vector2.ONE)
	draw_texture_rect_region(atlas, Rect2(-sprite_size * 0.5, sprite_size), source_rect, sprite_modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# 중앙 선수 장갑과 측 Robots/nacelles
	var spine := PackedVector2Array([
		pos + forward * length * 0.92,
		pos + forward * length * 0.10 + lateral * width * 0.34,
		pos - forward * length * 0.58 + lateral * width * 0.28,
		pos - forward * length * 0.58 - lateral * width * 0.28,
		pos + forward * length * 0.10 - lateral * width * 0.34,
	])
	draw_colored_polygon(spine, Color(color, 0.10))
	draw_line(pos - forward * length * 0.62 + lateral * width * 0.88, pos + forward * length * 0.12 + lateral * width * 0.74, Color(color, 0.28), 1.0)
	draw_line(pos - forward * length * 0.62 - lateral * width * 0.88, pos + forward * length * 0.12 - lateral * width * 0.74, Color(color, 0.28), 1.0)
	# 함교·주포
	draw_circle(pos + forward * length * 0.05, maxf(1.5, width * 0.24), Color("dff6ff"), true)
	if flagship or class_index == 0:
		draw_circle(pos + forward * length * 0.46 + lateral * width * 0.40, 1.4, GOLD, true)
		draw_circle(pos + forward * length * 0.46 - lateral * width * 0.40, 1.4, GOLD, true)
	if flagship:
		draw_arc(pos, length + 5.0, 0, TAU, 32, Color(GOLD, 0.65), 1.5)
		draw_line(pos - lateral * (width + 5.0), pos + lateral * (width + 5.0), Color(GOLD, 0.55), 1.0)
		_draw_flagship_crown(pos - forward * length * 0.10, forward, lateral, color)

func _ship_class_index(fleet_id: String, ship_index: int) -> int:
	if ship_index == 0:
		return {"F01": 0, "F02": 6, "A01": 3, "E01": 2, "E02": 1}.get(fleet_id, 0)
	if ship_index % 13 == 0:
		return 4 # 보급함
	if ship_index % 11 == 0:
		return 5 # 전자전함
	if ship_index % 7 == 0:
		return 6 # 요격함
	if ship_index % 5 == 0:
		return 7 # 고속정
	if ship_index % 4 == 0:
		return 9 # 전투기
	if ship_index % 3 == 0:
		return 8 # 수송기
	return 0 if ship_index % 2 == 0 else 1

func _ship_class_atlas(class_index: int) -> Texture2D:
	match class_index:
		0:
			return BATTLESHIP_TOP
		1:
			return FIRE_SUPPORT_TOP
		2:
			return SIEGE_SHIP_TOP
		3:
			return ASSAULT_CARRIER_TOP
	if class_index <= 6:
		return SUPPORT_SHIPS
	return SMALL_CRAFT

func _ship_class_source_rect(class_index: int) -> Rect2:
	if class_index <= 3:
		return Rect2(Vector2.ZERO, _ship_class_atlas(class_index).get_size())
	var atlas_cell := class_index - 4 if class_index <= 6 else class_index - 7
	return Rect2(atlas_cell * 724.0, 0.0, 724.0, 724.0)

func _draw_flagship_crown(pos: Vector2, forward: Vector2, lateral: Vector2, color: Color) -> void:
	draw_line(pos - lateral * 4.5, pos + lateral * 4.5, color.lightened(0.35), 2.4)
	draw_line(pos, pos + forward * 5.0, Color.WHITE, 1.6)
	draw_circle(pos + forward * 5.5, 1.8, GOLD, true)

func _ship_polygon(pos: Vector2, angle: float, length: float, width: float) -> PackedVector2Array:
	var local := PackedVector2Array([
		Vector2(length, 0), Vector2(length * 0.30, -width * 0.62),
		Vector2(-length * 0.18, -width), Vector2(-length * 0.78, -width * 0.72),
		Vector2(-length, -width * 0.36), Vector2(-length, width * 0.36),
		Vector2(-length * 0.78, width * 0.72), Vector2(-length * 0.18, width),
		Vector2(length * 0.30, width * 0.62)
	])
	for i in range(local.size()):
		local[i] = pos + local[i].rotated(angle)
	return local

func _draw_nebula(center: Vector2, radius: float, color: Color) -> void:
	for i in range(8, 0, -1):
		var ratio := float(i) / 8.0
		var layer := Color(color.r, color.g, color.b, color.a * (1.0 - ratio * 0.72))
		draw_circle(center, radius * ratio, layer, true)

func _draw_tactical_grid() -> void:
	var vanishing_x := 700.0
	for x in range(int(VIEW.position.x), int(VIEW.end.x) + 1, 80):
		var top_x := vanishing_x + (float(x) - vanishing_x) * 0.76
		draw_line(Vector2(top_x, VIEW.position.y), Vector2(x, VIEW.end.y), Color(0.20, 0.52, 0.66, 0.17), 1)
	for y in range(int(VIEW.position.y), int(VIEW.end.y) + 1, 80):
		draw_line(Vector2(VIEW.position.x, y), Vector2(VIEW.end.x, y), Color(0.20, 0.43, 0.56, 0.13), 1)

func _draw_explosion(pos: Vector2, radius: float) -> void:
	var pulse := 1.0 + 0.08 * sin(elapsed * 16.0)
	_draw_vfx(pos, Vector2(radius * 3.8, radius * 3.8) * pulse, 4, Color(1.0, 0.82, 0.62, 0.82))
	draw_circle(pos, radius * 1.7, Color(0.20, 0.65, 1.0, 0.08), true)
	draw_circle(pos, radius, Color(1.0, 0.36, 0.12, 0.22), true)
	draw_circle(pos, radius * 0.56, Color(1.0, 0.78, 0.34, 0.72), true)
	draw_circle(pos, radius * 0.22, Color(0.95, 0.98, 1.0, 0.95), true)
	for i in range(8):
		var ray := Vector2(radius * 1.55, 0).rotated(i * TAU / 8.0 + elapsed)
		draw_line(pos + ray * 0.35, pos + ray, Color(1.0, 0.58, 0.22, 0.55), 1.4)

func _draw_beams() -> void:
	var phase := fmod(elapsed, 2.4)
	var ambient_active := phase <= 1.45
	var pairs := [[0, 3], [2, 3], [1, 4]]
	for k in range(pairs.size()):
		if not ambient_active:
			continue
		var a: Vector2 = fleets[pairs[k][0]].pos
		var b: Vector2 = fleets[pairs[k][1]].pos
		if a.distance_to(b) > 470:
			continue
		var normal := (b - a).normalized().orthogonal()
		for n in range(3):
			var shift := normal * (n - 1) * 6.0
			draw_line(a + shift, b + shift, Color(0.08, 0.35, 0.52, 0.35), 4.2)
			draw_line(a + shift, b + shift, Color(0.35, 0.9, 1.0, 0.92), 1.4)
		# 광자탄과 유도탄이 화선을 따라 이동해 일제사격의 방향을 읽을 수 있게 한다.
		for shot in range(5):
			var shot_t := fmod(phase * 1.4 + float(shot) * 0.17 + float(k) * 0.11, 1.0)
			var projectile := a.lerp(b, shot_t) + normal * sin(shot_t * PI) * (10.0 + k * 5.0)
			draw_circle(projectile, 4.0, Color(0.18, 0.62, 1.0, 0.15), true)
			draw_circle(projectile, 1.7, Color("d9fbff"), true)
			_draw_oriented_vfx(projectile, (b - a).angle(), Vector2(26, 11), 1, Color(0.75, 0.96, 1.0, 0.72))
		if phase < 0.35:
			_draw_explosion(b, 18 + phase * 24)
	# 적의 붉은 대응 사격. 양측 화선 색을 분리해 교전 방향을 즉시 판독한다.
	var enemy_phase := fmod(elapsed + 0.65, 2.8)
	if enemy_phase < 1.25:
		var enemy_a: Vector2 = fleets[4].pos
		var enemy_b: Vector2 = fleets[1].pos
		var enemy_normal := (enemy_b - enemy_a).normalized().orthogonal()
		for n in range(2):
			var shift := enemy_normal * (n * 7.0 - 3.5)
			draw_line(enemy_a + shift, enemy_b + shift, Color(0.55, 0.04, 0.08, 0.35), 4.5)
			draw_line(enemy_a + shift, enemy_b + shift, Color("ff5964"), 1.25)
	# 플레이어가 하단 명령으로 지정한 일제사격 이벤트.
	if salvo_source >= 0 and salvo_target >= 0:
		var event_age := elapsed - salvo_started
		if event_age < 2.8:
			var source_pos: Vector2 = fleets[salvo_source].pos
			var target_pos: Vector2 = fleets[salvo_target].pos
			var event_normal := (target_pos - source_pos).normalized().orthogonal()
			for n in range(5):
				var shift := event_normal * (n - 2) * 5.0
				var flicker := 0.65 + 0.30 * sin(elapsed * 24.0 + n)
				draw_line(source_pos + shift, target_pos + shift, Color(0.04, 0.36, 0.65, 0.34), 7.0)
				draw_line(source_pos + shift, target_pos + shift, Color(0.30, 0.92, 1.0, flicker), 2.5)
				var bolt_t := fmod(event_age * 1.8 + n * 0.14, 1.0)
				var bolt_pos := (source_pos + shift).lerp(target_pos + shift, bolt_t)
				_draw_oriented_vfx(bolt_pos, (target_pos - source_pos).angle(), Vector2(34, 14), 1, Color(0.72, 0.96, 1.0, 0.92))
			_draw_target_bracket(target_pos, ENEMY)
			if event_age < 1.2:
				_draw_vfx(target_pos, Vector2(92, 92), 2, Color(0.72, 0.92, 1.0, 0.80))
				_draw_explosion(target_pos, 15.0 + event_age * 18.0)

func _vfx_source_rect(effect_index: int) -> Rect2:
	return Rect2((effect_index % 4) * 440.0, (effect_index / 4) * 440.0, 440.0, 440.0)

func _draw_vfx(pos: Vector2, size: Vector2, effect_index: int, modulate: Color = Color.WHITE) -> void:
	draw_texture_rect_region(COMBAT_VFX, Rect2(pos - size * 0.5, size), _vfx_source_rect(effect_index), modulate)

func _draw_oriented_vfx(pos: Vector2, angle: float, size: Vector2, effect_index: int, modulate: Color = Color.WHITE) -> void:
	draw_set_transform(pos, angle, Vector2.ONE)
	draw_texture_rect_region(COMBAT_VFX, Rect2(-size * 0.5, size), _vfx_source_rect(effect_index), modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_target_bracket(pos: Vector2, color: Color) -> void:
	var radius := 46.0 + sin(elapsed * 6.0) * 4.0
	for i in range(4):
		var start := i * PI * 0.5 + 0.12
		draw_arc(pos, radius, start, start + 0.55, 10, color, 2.5)
	_text(pos + Vector2(-38, 64), "LOCK · 집중사격", 12, color)

func _draw_event_feed() -> void:
	var panel := Rect2(VIEW.position + Vector2(16, 16), Vector2(330, 78))
	draw_rect(panel, Color(0.02, 0.05, 0.09, 0.72), true)
	draw_line(panel.position, panel.position + Vector2(0, panel.size.y), FRIEND, 3)
	_text(panel.position + Vector2(14, 22), "전술 통신 · 제갈량", 14, GOLD)
	_text(panel.position + Vector2(14, 45), "적 전위함대의 측면이 노출되었습니다.", 14, Color("d9edf5"))
	_text(panel.position + Vector2(14, 65), "관우 기동함대에 우회 기동을 권고합니다.", 12, Color("8ecae6"))

func _draw_radar() -> void:
	var center := Vector2(145, 635)
	draw_circle(center, 72, Color(0.02, 0.08, 0.13, 0.9), true)
	draw_circle(center, 72, Color("4e91b5"), false, 2)
	draw_circle(center, 45, Color(0.25, 0.55, 0.7, 0.35), false, 1)
	for fleet in fleets:
		var rel: Vector2 = ((fleet.pos as Vector2) - Vector2(630, 405)) * 0.11
		draw_circle(center + rel, 4 if fleet.side != "enemy" else 3, _side_color(String(fleet.side)))
	_text(Vector2(90, 724), "전술 레이더", 13, Color("8ecae6"))

func _draw_right_panel() -> void:
	draw_rect(Rect2(PANEL_X, 82, 330, 650), Color("0a1828"), true)
	draw_rect(Rect2(PANEL_X, 82, 330, 650), Color("28506a"), false, 2)
	var fleet := fleets[selected]
	_text(Vector2(PANEL_X + 20, 116), "선택 함대", 16, Color("8ecae6"))
	_text(Vector2(PANEL_X + 20, 148), String(fleet.title), 24, Color.WHITE)
	_text(Vector2(PANEL_X + 20, 176), String(fleet.commander), 16, GOLD)
	_text(Vector2(PANEL_X + 20, 214), "함선 %d척   사기 %d" % [fleet.ships, fleet.morale], 16, Color("c9e7f2"))
	_text(Vector2(PANEL_X + 20, 246), "함대 전력 배분", 16, Color("8ecae6"))
	var bars := [["엔진", 0.62], ["센서", 0.48], ["함포", 0.78], ["방어", 0.70]]
	for i in range(bars.size()):
		var y := 278.0 + i * 34.0
		_text(Vector2(PANEL_X + 20, y + 13), bars[i][0], 13, Color("b8ceda"))
		draw_rect(Rect2(PANEL_X + 75, y, 220, 14), Color("183145"), true)
		draw_rect(Rect2(PANEL_X + 75, y, 220 * float(bars[i][1]), 14), FRIEND if i < 2 else GOLD, true)
	_text(Vector2(PANEL_X + 20, 434), "진형 명령", 16, Color("8ecae6"))
	for i in range(3):
		var rect := Rect2(PANEL_X + 20, 450 + i * 48, 310, 38)
		var active: bool = String(fleet.formation) == FORMATIONS[i]
		draw_rect(rect, Color("204b63") if active else Color("10283b"), true)
		draw_rect(rect, GOLD if active else Color("315a70"), false, 1.5)
		_text(rect.position + Vector2(16, 25), "%d  %s" % [i + 1, FORMATIONS[i]], 16, Color.WHITE)
	_text(Vector2(PANEL_X + 20, 622), "우클릭: 이동점·도착 방향", 14, Color("9db6c3"))
	_text(Vector2(PANEL_X + 20, 646), "Q/E: 제자리 선회", 14, Color("9db6c3"))
	if command_mode == "일제사격" or command_mode == "지속사격":
		_text(Vector2(PANEL_X + 174, 688), "적 함대를 선택", 14, ENEMY)
	var pause_rect := Rect2(PANEL_X + 20, 660, 145, 44)
	draw_rect(pause_rect, Color("1b4e69"), true)
	_text(pause_rect.position + Vector2(21, 29), "▶ 재개" if paused else "Ⅱ 정지", 17, Color.WHITE)

func _draw_bottom_panel() -> void:
	draw_rect(Rect2(38, BOTTOM_Y, 1542, 122), Color("091728"), true)
	draw_rect(Rect2(38, BOTTOM_Y, 1542, 122), Color("28506a"), false, 2)
	var fleet := fleets[selected]
	_draw_portrait(Rect2(53, 766, 78, 94), int(fleet.portrait), GOLD)
	_text(Vector2(151, 792), String(fleet.commander), 18, Color.WHITE)
	_text(Vector2(151, 822), "지휘 91 ㅣ 감지 84 ㅣ 전술 94", 14, Color("9fc3d4"))
	var order_text := "현재 명령  %s" % command_mode
	if salvo_target >= 0:
		order_text += "  →  %s" % fleets[salvo_target].title
	else:
		order_text += "  →  화선 집중점"
	_text(Vector2(145, 850), order_text, 15, GOLD)
	var commands := ["이동", "선회", "일제사격", "지속사격", "사격중지", "철수"]
	for i in range(commands.size()):
		var rect := Rect2(540 + i * 142, 782, 126, 62)
		var active: bool = command_mode == commands[i] or (command_mode == "표적 교전" and i == 2)
		draw_rect(rect, Color("254d61") if active else Color("112b40"), true)
		draw_rect(rect, GOLD if active else Color("356a86"), false, 1.5)
		_text(rect.position + Vector2(18, 37), commands[i], 15, Color("d9edf5"))
	_text(Vector2(1420, 855), "POC %s" % POC_VERSION, 13, Color("6f98aa"))

func _draw_arrow(pos: Vector2, angle: float, color: Color) -> void:
	var tip := pos + Vector2(12, 0).rotated(angle)
	var a := pos + Vector2(-5, -6).rotated(angle)
	var b := pos + Vector2(-5, 6).rotated(angle)
	draw_colored_polygon(PackedVector2Array([tip, a, b]), color)

func _side_color(side: String) -> Color:
	if side == "enemy":
		return ENEMY
	if side == "ally":
		return ALLY
	return FRIEND

func _draw_portrait(destination: Rect2, portrait_index: int, border_color: Color) -> void:
	var column := portrait_index % 3
	var row := portrait_index / 3
	var source := Rect2(column * 512.0 + 5.0, row * 512.0 + 5.0, 502.0, 502.0)
	draw_texture_rect_region(COMMANDER_SHEET, destination, source)
	draw_rect(destination, border_color, false, 1.5)

func _text(pos: Vector2, value: String, size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
