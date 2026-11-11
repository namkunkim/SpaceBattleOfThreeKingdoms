extends RefCounted

const SIZE := 112
const RADIUS := 50.0
const MAX_CACHED := 96
const LIGHT := Vector3(-0.57, -0.43, 0.70)
const OCEAN_DEEP := Color("0b2a51")
const OCEAN_SHALLOWS := Color("2c829a")
const FOREST := Color("42654a")
const DESERT := Color("c0a477")
const MOUNTAINS := Color("a09483")
const ICE := Color("d3e4e8")
const CLOUD := Color("eef3f6")
const NIGHT_LIGHT := Color("7593c0")
const WATER_GLINT := Color("a5c7d8")
const METHANE_HAZE := Color("a8cde1")
const STORM_DUST := Color("b76d59")
const ROCK_HIGHLIGHT := Color("bba991")

static var _textures: Dictionary[String, Texture2D] = {}
static var _water_glint_direction := (LIGHT + Vector3(0, 0, 1)).normalized()


static func texture(body: Dictionary) -> Texture2D:
	var name := str(body.get("name", ""))
	var color := Color.from_string(str(body.get("color", "")), Color("829db3"))
	var classification := str(body.get("classification", ""))
	var habitable := bool(body.get("habitable", false))
	var key := "%s|%s|%s|%s" % [name, color.to_html(), classification, habitable]
	if _textures.has(key):
		return _textures[key]

	var seed_value := hash(name + classification)
	var relief := _noise(seed_value, 1.72, 4)
	var weather := _noise(seed_value ^ 0x6137, 3.65, 3)
	var gas := classification.contains("거대형")
	var ice_giant := classification.begins_with("얼음")
	var craters := _craters(seed_value) if not habitable and not gas else PackedVector3Array()
	var tilt := (float(seed_value % 101) / 100.0 - 0.5) * 0.55
	var spin := Vector2.from_angle(tilt)
	var gas_storm := Vector2(-0.44 + float(seed_value % 81) / 100.0, 0.22)
	var atmosphere := Color("63bcff") if habitable else color.lerp(Color("8eaed1"), 0.42)
	var haze := 0.58 if habitable else (0.40 if gas else 0.075)
	var image := Image.create_empty(SIZE, SIZE, false, Image.FORMAT_RGBA8)

	for y in range(SIZE):
		for x in range(SIZE):
			var plane := (Vector2(x + 0.5, y + 0.5) - Vector2.ONE * SIZE * 0.5) / RADIUS
			var distance_squared := plane.length_squared()
			if distance_squared > 1.21:
				continue
			var distance := sqrt(distance_squared)
			if distance > 1.0:
				var horizon_light := smoothstep(-0.16, 0.65, plane.dot(Vector2(LIGHT.x, LIGHT.y)))
				var fringe := atmosphere
				fringe.a = haze * horizon_light * pow(1.0 - smoothstep(1.0, 1.10, distance), 2.3)
				image.set_pixel(x, y, fringe)
				continue

			var normal := Vector3(plane.x, plane.y, sqrt(1.0 - distance_squared))
			var latitude := Vector2(plane.x * spin.x - plane.y * spin.y, plane.x * spin.y + plane.y * spin.x)
			var surface_point := Vector3(latitude.x, latitude.y, normal.z)
			var sunlight := normal.dot(LIGHT)
			var albedo: Color
			if habitable:
				albedo = _terrestrial(surface_point, normal, sunlight, relief, weather)
			elif gas:
				albedo = _giant(surface_point, color, ice_giant, gas_storm, relief, weather)
			else:
				albedo = _rocky(normal, color, relief, weather, craters)

			var daylight := pow(maxf(sunlight, 0.0), 0.68)
			var twilight := smoothstep(-0.10, 0.20, sunlight) * 0.043
			var shaded := albedo * (0.059 + 1.03 * daylight + twilight)
			var reflected := pow(1.0 - normal.z, 2.0) * (1.0 - smoothstep(-0.60, 0.02, sunlight))
			shaded = shaded.lerp(albedo.lerp(NIGHT_LIGHT, 0.28) * 0.18, reflected * 0.42)
			var limb := pow(1.0 - normal.z, 2.8) * smoothstep(-0.16, 0.62, sunlight)
			shaded = shaded.lerp(atmosphere, limb * haze)
			shaded.a = 1.0 - smoothstep(0.985, 1.008, distance)
			image.set_pixel(x, y, shaded)

	image.generate_mipmaps()
	var result := ImageTexture.create_from_image(image)
	if _textures.size() >= MAX_CACHED:
		_textures.erase(_textures.keys()[0])
	_textures[key] = result
	return result


static func _noise(seed_value: int, frequency: float, octaves: int) -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	return noise


static func _terrestrial(point: Vector3, normal: Vector3, sunlight: float, relief: FastNoiseLite, weather: FastNoiseLite) -> Color:
	var continental_warp := weather.get_noise_3dv(point * 0.8) * 0.20
	var elevation := relief.get_noise_3dv(point + Vector3(continental_warp, -continental_warp, 0.0))
	var humidity := weather.get_noise_3dv(point * 1.65)
	var detail := weather.get_noise_3dv(point * 6.0)
	var water := OCEAN_DEEP.lerp(OCEAN_SHALLOWS, smoothstep(-0.22, 0.075, elevation))
	var aridity := smoothstep(-0.13, 0.36, -humidity + detail * 0.23)
	var land := FOREST.lerp(DESERT, aridity).darkened(maxf(0.0, -detail) * 0.34)
	var heights := smoothstep(0.17, 0.46, elevation + detail * 0.14)
	land = land.lerp(MOUNTAINS, heights).lerp(ICE, smoothstep(0.39, 0.63, elevation))
	var coastline := smoothstep(-0.008, 0.047, elevation)
	var surface := water.lerp(land, coastline)
	var ice_cap := smoothstep(0.79, 0.98, absf(point.y) + detail * 0.06)
	surface = surface.lerp(ICE, ice_cap * 0.89)

	# Fine cloud belts follow latitude while larger cells break up the bands.
	var circulation := Vector3(point.x + point.y * 0.43, point.y * 2.0, point.z)
	var cloud_density := weather.get_noise_3dv(circulation + Vector3(8, 5, 2))
	cloud_density += 0.28 * relief.get_noise_3dv(circulation * 2.4 + Vector3(3, 7, 5))
	var clouds := smoothstep(0.045, 0.39, cloud_density)
	var glint := pow(maxf(normal.dot(_water_glint_direction), 0.0), 28.0)
	glint *= (1.0 - coastline) * smoothstep(0.0, 0.40, sunlight)
	return surface.lerp(WATER_GLINT, glint * 0.32).lerp(CLOUD, clouds * 0.91)


static func _giant(point: Vector3, color: Color, icy: bool, storm: Vector2, relief: FastNoiseLite, weather: FastNoiseLite) -> Color:
	var wind := weather.get_noise_3dv(Vector3(point.x * 1.15, point.y * 3.8, point.z))
	var fine_wind := relief.get_noise_3dv(Vector3(point.x * 1.9, point.y * 9.0, point.z))
	var latitude := point.y + wind * 0.067 + fine_wind * 0.013
	var belt := 0.61 * sin(latitude * 18.0) + 0.24 * sin(latitude * 37.0 + 0.65)
	belt += 0.15 * sin(latitude * 68.0)
	var profile := clampf(0.51 + belt * (0.14 if icy else 0.31) + fine_wind * 0.12, 0.0, 1.0)
	var shadow := color.darkened(0.39 if icy else 0.48)
	var upper_cloud := color.lightened(0.45 if icy else 0.54)
	var surface := shadow.lerp(upper_cloud, profile)
	if icy:
		var methane_haze := smoothstep(0.43, 0.91, absf(point.y))
		return surface.lerp(METHANE_HAZE, methane_haze * 0.23)

	var vortex := (Vector2(point.x, point.y) - storm) / Vector2(0.20, 0.095)
	var radial := vortex.length()
	var eye := 1.0 - smoothstep(0.37, 1.10, radial + fine_wind * 0.16)
	var eddy := sin(13.0 * radial + vortex.angle() * 2.0) * 0.5 + 0.5
	var storm_color := color.lerp(STORM_DUST, 0.45 + eddy * 0.23)
	return surface.lerp(storm_color, eye * 0.68)


static func _craters(seed_value: int) -> PackedVector3Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var craters := PackedVector3Array()
	for i in range(12):
		var angle := rng.randf_range(0.0, TAU)
		var center := Vector2.from_angle(angle) * sqrt(rng.randf()) * 0.89
		craters.append(Vector3(center.x, center.y, rng.randf_range(0.048, 0.145)))
	return craters


static func _rocky(normal: Vector3, color: Color, relief: FastNoiseLite, weather: FastNoiseLite, craters: PackedVector3Array) -> Color:
	var shield := relief.get_noise_3dv(normal * 1.5)
	var highlands := 1.0 - absf(weather.get_noise_3dv(normal * 2.6))
	var dust := weather.get_noise_3dv(normal * 8.0)
	var plate := clampf(0.40 + shield * 0.62 + highlands * 0.26 + dust * 0.15, 0.0, 1.0)
	var light_stone := color.lightened(0.43).lerp(ROCK_HIGHLIGHT, 0.10)
	var surface := color.darkened(0.60).lerp(light_stone, plate)
	var point := Vector2(normal.x, normal.y)
	var crater_shadow := 0.0
	for crater in craters:
		var crater_offset := (point - Vector2(crater.x, crater.y)) / crater.z
		var radial_squared := crater_offset.length_squared()
		if radial_squared > 1.32:
			continue
		var radial := sqrt(radial_squared)
		var depression := 1.0 - smoothstep(0.34, 0.88, radial)
		var rim := smoothstep(0.54, 0.82, radial) * (1.0 - smoothstep(0.86, 1.15, radial))
		var slope := crater_offset.dot(Vector2(LIGHT.x, LIGHT.y))
		crater_shadow += depression * (-0.19 - slope * 0.24) + rim * (0.10 + slope * 0.28)
	return surface * clampf(1.0 + crater_shadow, 0.54, 1.42)
