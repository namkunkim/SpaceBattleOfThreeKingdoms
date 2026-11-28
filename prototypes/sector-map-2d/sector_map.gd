extends Node2D

const MAP := Rect2(-3200.0, -2100.0, 6400.0, 4200.0)
const CLEAR := Vector2(285.0, 235.0)
const MAX_ZOOM := 12.0
const CENTRAL_SYSTEM := Vector2(72.0, -42.0)
const GAS_COLORS := [Color("#627ba3"), Color("#876686"), Color("#508e87"), Color("#927056")]

var random := RandomNumberGenerator.new()
var coverage := FastNoiseLite.new()
var strands := FastNoiseLite.new()
var gas: ImageTexture
var stars := PackedVector2Array()
var stones: Array[Dictionary] = []
var systems: Array[Dictionary] = []
var center := Vector2.ZERO
var zoom := 1.0
var dragging := false
var show_controls := true

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	get_viewport().size_changed.connect(queue_redraw)
	var args := OS.get_cmdline_user_args()
	if "--verify-map" in args or "--sample-map" in args or "--capture-tour" in args:
		random.seed = 683210
	else:
		random.randomize()
	generate_map()
	zoom = fit_zoom()
	if "--verify-map" in args:
		verify_map()
	elif "--sample-map" in args:
		save_samples()

func horizontal_axis(x: float) -> float:
	return sin(x * 0.0019) * 115.0 + sin(x * 0.0049) * 36.0

func vertical_axis(y: float) -> float:
	return sin(y * 0.0026) * 124.0 - sin(y * 0.0061) * 31.0

func lane_clearance(point: Vector2) -> float:
	var horizontal_width := CLEAR.y + 35.0 * sin(point.x * 0.0031 + 0.8)
	var vertical_width := CLEAR.x + 47.0 * sin(point.y * 0.0039 - 0.7)
	return maxf(horizontal_width - absf(point.y - horizontal_axis(point.x)),
		vertical_width - absf(point.x - vertical_axis(point.y)))

func clear_lane(point: Vector2) -> bool:
	return lane_clearance(point) >= 0.0

func density(point: Vector2) -> float:
	var warp := Vector2(strands.get_noise_2dv(point + Vector2(1700.0, 230.0)),
		strands.get_noise_2dv(point + Vector2(-640.0, 1830.0))) * 145.0
	var warped := point + warp
	var broad := coverage.get_noise_2dv(warped * Vector2(0.74, 1.12))
	var fine := strands.get_noise_2dv(warped)
	return smoothstep(-0.31, 0.37, broad + fine * 0.25)

func stone_banding(point: Vector2) -> float:
	var bend := coverage.get_noise_2dv(point * 0.55 + Vector2(918.0, 257.0)) * 480.0
	var ridge := strands.get_noise_2dv(Vector2(point.x * 0.72, point.y + bend))
	return lerpf(0.28, 0.92, smoothstep(-0.37, 0.42, ridge))

func generate_map() -> void:
	coverage.seed = random.randi_range(1, 2000000000)
	coverage.frequency = 0.0015
	coverage.fractal_octaves = 3
	strands.seed = random.randi_range(1, 2000000000)
	strands.frequency = 0.007
	strands.fractal_octaves = 4
	for i in 2300:
		stars.append(random_point())
	for i in 19000:
		var p := random_point()
		var edge_density := smoothstep(5.0, 130.0, -lane_clearance(p))
		if edge_density <= 0.0 or random.randf() > pow(density(p + Vector2(144.0, -73.0)), 2.0) * edge_density * stone_banding(p):
			continue
		stones.append({"p": p, "radius": 0.8 + pow(random.randf(), 1.85) * 12.4,
			"angle": random.randf_range(0.0, TAU), "shape": random.randf(),
			"shade": random.randf_range(0.35, 0.88)})
	add_system(CENTRAL_SYSTEM)
	for pass_index in 2:
		for arm in 4:
			if systems.size() >= 8:
				break
			var track := -1.0 if (arm + pass_index) % 2 == 0 else 1.0
			place_system(arm, track)
	for attempt in 32:
		if systems.size() >= 8:
			break
		var track := -1.0 if attempt % 2 == 0 else 1.0
		place_system(random.randi_range(0, 3), track)
	build_gas()

func place_system(arm: int, track: float) -> void:
	var direction := -1.0 if arm % 2 == 0 else 1.0
	for attempt in 64:
		var p: Vector2
		if arm < 2:
			var x := direction * random.randf_range(380.0, 2960.0)
			p = Vector2(x, horizontal_axis(x) + random.randf_range(-100.0, 100.0))
		else:
			var y := direction * random.randf_range(330.0, 1860.0)
			p = Vector2(vertical_axis(y) + track * random.randf_range(114.0, 151.0), y)
		if lane_clearance(p) < 110.0:
			continue
		var separated := true
		for existing in systems:
			if p.distance_to(existing.p) < 470.0:
				separated = false
				break
		if not separated:
			continue
		add_system(p)
		return

func add_system(p: Vector2) -> void:
	var orbits: Array[float] = []
	for orbit in random.randi_range(3, 5):
		orbits.append(random.randf_range(0.0, TAU))
	systems.append({"p": p, "orbits": orbits,
		"color": Color("#ffd391").lerp(Color("#b6dcff"), random.randf()),
		"name": "SYS %02d" % (systems.size() + 1)})

func random_point() -> Vector2:
	return Vector2(random.randf_range(MAP.position.x, MAP.end.x),
		random.randf_range(MAP.position.y, MAP.end.y))

func build_gas() -> void:
	var dimensions := Vector2i(1728, 1134)
	var image := Image.create_empty(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	for y in dimensions.y:
		for x in dimensions.x:
			var uv := (Vector2(x, y) + Vector2(0.5, 0.5)) / Vector2(dimensions)
			var p := MAP.position + uv * MAP.size
			var boundary := -lane_clearance(p)
			if boundary <= 15.0:
				continue
			var cloud := density(p)
			var contour := coverage.get_noise_2dv(p * 0.75 + Vector2(440, -960)) * 40.0
			var stream := Vector2(p.x * 0.69 + p.y * 0.45, p.y * 2.0 + p.x * 0.28 + contour)
			var grain := strands.get_noise_2dv(stream * 3.7)
			var thread := smoothstep(0.01, 0.61, grain) * smoothstep(0.29, 0.78, cloud)
			var filament := 0.5 + strands.get_noise_2dv(p * 2.0) * 0.5
			var vacancy := smoothstep(-0.43, 0.24, coverage.get_noise_2dv(p * 0.43 + Vector2(760.0, -360.0)))
			var alpha := pow(cloud, 2.05) * (0.11 + filament * 0.30 + thread * 0.29) * lerpf(0.32, 1.0, vacancy)
			var ragged_edge := 42.0 + smoothstep(-0.28, 0.42, coverage.get_noise_2dv(p + Vector2(925.0, 0.0))) * 270.0
			alpha *= smoothstep(15.0, ragged_edge, boundary)
			var temperature := smoothstep(-0.49, 0.48, coverage.get_noise_2dv(p * 0.58 + Vector2(2250, -740)))
			var tint := Color("#475d78").lerp(Color("#79695f"), temperature)
			tint = tint.lightened(thread * 0.14)
			tint.a = alpha
			image.set_pixel(x, y, tint)
	gas = ImageTexture.create_from_image(image)

func fit_zoom() -> float:
	var size := get_viewport_rect().size
	return minf(size.x / MAP.size.x, (size.y - 82.0) / MAP.size.y) * 0.94

func world_at(pixel: Vector2) -> Vector2:
	return center + (pixel - get_viewport_rect().size * 0.5) / zoom

func zoom_at(pixel: Vector2, amount: float) -> void:
	var anchor := world_at(pixel)
	zoom = clampf(zoom * amount, fit_zoom() * 0.70, MAX_ZOOM)
	center += anchor - world_at(pixel)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(event.position, pow(1.24, maxf(0.2, event.factor)))
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(event.position, pow(1.24, -maxf(0.2, event.factor)))
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
	elif event is InputEventMouseMotion and dragging:
		center -= event.relative / zoom
		queue_redraw()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_HOME:
		center = Vector2.ZERO
		zoom = fit_zoom()
		queue_redraw()

func _draw() -> void:
	var screen := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, screen), Color("#060912"))
	if gas == null:
		return
	var visible := Rect2(world_at(Vector2.ZERO), screen / zoom).grow(24.0)
	draw_set_transform(screen * 0.5 - center * zoom, 0.0, Vector2.ONE * zoom)
	draw_rect(MAP, Color("#0b1020"))
	for i in stars.size():
		var p := stars[i]
		if visible.has_point(p):
			var strength := 0.20 + float(i % 7) * 0.073
			draw_circle(p, (0.45 + float(i % 3) * 0.14) / zoom, Color(0.69, 0.79, 0.91, strength))
	draw_texture_rect(gas, MAP, false)
	draw_rect(MAP, Color("#3c4d68"), false, 1.0 / zoom)
	for stone in stones:
		var p: Vector2 = stone.p
		if visible.has_point(p):
			draw_stone(stone)
	for system in systems:
		if visible.grow(130.0).has_point(system.p):
			draw_system(system)
	draw_set_transform(Vector2.ZERO)
	draw_rect(Rect2(0.0, 0.0, screen.x, 52.0), Color(0.022, 0.033, 0.058, 0.95))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(22.0, 33.0), "DEEP SPACE  /  SECTOR MAP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 19, Color("#e8eef9"))
	if not show_controls:
		return
	draw_string(font, Vector2(22.0, screen.y - 18.0), "Scroll  Zoom     Drag  Pan     Home  Overview",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("#aebcd4"))

const ROCK_SHAPES := 12

static func rock_variant(value: float) -> int:
	return clampi(floori(value * ROCK_SHAPES), 0, ROCK_SHAPES - 1)

static func rock_outline(variant: int) -> PackedVector2Array:
	var shape := (float(variant) + 0.5) / ROCK_SHAPES
	var corners := 5 + floori(shape * 5.0)
	var stretch := lerpf(0.95, 1.75, shape)
	var thickness := lerpf(0.78, 0.47, shape)
	var outline := PackedVector2Array()
	for corner in corners:
		var direction := (corner + 0.13 * sin(corner * 2.4 + shape * 8.0)) * TAU / corners
		var irregularity := 0.78 + 0.24 * sin(corner * 2.77 + shape * 27.0)
		outline.append(Vector2(cos(direction) * stretch, sin(direction) * thickness) * irregularity)
	return outline


func draw_stone(stone: Dictionary) -> void:
	var p: Vector2 = stone.p
	var radius: float = stone.radius
	var tint := Color("#8993a9").darkened(1.0 - float(stone.shade))
	if radius * zoom < 2.0:
		draw_circle(p, maxf(radius, 0.42 / zoom), tint)
		return
	var hull := PackedVector2Array()
	var shape: float = stone.shape
	var angle: float = stone.angle
	var outline := rock_outline(rock_variant(shape))
	var corners := outline.size()
	for point in outline:
		hull.append(p + point.rotated(angle) * radius)
	var base_colors := PackedColorArray([tint.darkened(0.30)])
	for corner in corners:
		draw_primitive(PackedVector2Array([p, hull[corner], hull[(corner + 1) % corners]]),
			base_colors, PackedVector2Array())
	var crest := p + Vector2(-0.22, -0.17).rotated(angle) * radius
	for side in 3:
		var index := (side + floori(shape * 11.0)) % corners
		draw_primitive(PackedVector2Array([crest, hull[index], hull[(index + 1) % corners]]),
			PackedColorArray([tint.lightened(0.12 + 0.10 * side)]), PackedVector2Array())
	if radius * zoom > 8.0:
		draw_line(hull[1], crest, tint.darkened(0.47), 0.9 / zoom, true)
		draw_line(crest, hull[corners - 1], tint.lightened(0.22), 0.65 / zoom, true)

func draw_system(system: Dictionary) -> void:
	var p: Vector2 = system.p
	var tint: Color = system.color
	var orbits: Array[float] = system.orbits
	var font := ThemeDB.fallback_font
	if zoom < 0.65:
		draw_circle(p, 7.0 / zoom, Color(0.95, 0.77, 0.54, 0.14))
		draw_circle(p, 3.3 / zoom, tint, true, -1.0, true)
		draw_string(font, p + Vector2(10.0, -6.0) / zoom, system.name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, roundi(13.0 / zoom), Color("#c7d2e5"))
		return
	for i in orbits.size():
		var radius := 20.0 + i * 19.0
		draw_arc(p, radius, 0.0, TAU, 72, Color(0.40, 0.59, 0.78, 0.30), 0.75 / zoom, true)
		var body := p + Vector2.from_angle(orbits[i]) * radius
		var color: Color = GAS_COLORS[i % GAS_COLORS.size()].lightened(0.29)
		draw_circle(body, 2.2 + float(i % 3) * 0.9, color, true, -1.0, true)
		if zoom >= 2.0:
			draw_circle(body + Vector2(-0.6, -0.6), 1.1, color.lightened(0.35), true, -1.0, true)
	for i in range(5, 1, -1):
		draw_circle(p, i * 2.5, Color(tint, 0.035), true, -1.0, true)
	draw_circle(p, 5.2, tint, true, -1.0, true)

func verify_map() -> void:
	assert(stones.size() > 1000 and systems.size() == 8)
	assert(systems[0].p == CENTRAL_SYSTEM and lane_clearance(systems[0].p) >= 110.0)
	for stone in stones:
		assert(not clear_lane(stone.p))
	for system in systems:
		assert(clear_lane(system.p))
	var image := gas.get_image()
	var mid := image.get_size() / 2
	for x in image.get_width():
		assert(is_zero_approx(image.get_pixel(x, mid.y).a))
	for y in image.get_height():
		assert(is_zero_approx(image.get_pixel(mid.x, y).a))
	var cursor := get_viewport_rect().size * Vector2(0.73, 0.31)
	var before := world_at(cursor)
	var wheel := InputEventMouseButton.new()
	wheel.position = cursor
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.factor = 1.0
	var old_zoom := zoom
	_unhandled_input(wheel)
	assert(zoom > old_zoom)
	assert(world_at(cursor).distance_to(before) < 0.02)
	print("Verified: ", stones.size(), " asteroids, ", systems.size(), " solar systems, clear axes, cursor-anchored zoom")
	get_tree().quit()

func save_samples() -> void:
	await RenderingServer.frame_post_draw
	var err := get_viewport().get_texture().get_image().save_png("res://sector-overview.png")
	if err != OK:
		get_tree().quit(1)
		return
	var cluster := Vector2.ZERO
	var peak := -1.0
	for stone in stones:
		var p: Vector2 = stone.p
		var value := density(p)
		if value > peak and MAP.grow(-300.0).has_point(p):
			peak = value
			cluster = p
	center = cluster
	zoom = 4.2
	queue_redraw()
	await RenderingServer.frame_post_draw
	err = get_viewport().get_texture().get_image().save_png("res://sector-terrain.png")
	if err != OK:
		get_tree().quit(1)
		return
	center = systems[0].p
	zoom = 4.0
	queue_redraw()
	await RenderingServer.frame_post_draw
	err = get_viewport().get_texture().get_image().save_png("res://sector-system.png")
	get_tree().quit(0 if err == OK else 1)
