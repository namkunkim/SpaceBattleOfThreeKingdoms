extends Node3D

const DURATION := 34.0
const APPROACH_END := 7.4
const TILT_START := 9.0
const TILT_END := 16.5
const FIRE_DELAY := 6.2
const MISSILE_START := 11.6 + FIRE_DELAY
const SHU_LASER := 15.0 + FIRE_DELAY
const WEI_LASER := 16.35 + FIRE_DELAY
const SHU_IMPACT := WEI_LASER + 0.15
const SHU_MISSILE_REPEAT := 6.50
const WEI_MISSILE_REPEAT := 4.95
const JADE := Color("#64f1bd")
const AZURE := Color("#64aaff")
const WEI_ANCHOR := Vector3(630.0, 0.0, 0.0)
const STRATEGIC_CENTER := Vector3(1080.0, 0.0, -900.0)
const PARENT_MAP_SPAN := 27000.0
const HULLS := ["line", "carrier", "artillery", "supply", "siege", "interceptor", "ew", "fast"]
const LENGTHS := [0.75, 1.30, 0.90, 0.80, 1.05, 0.48, 0.40, 0.18]
const FORMATION_SCALE := 1.6
const FIRING_SLOTS := [0, 21, 24]

@export_range(14.0, 32.0, 0.5) var engagement_distance := 22.0

var camera := Camera3D.new()
var shu := Node3D.new()
var wei := Node3D.new()
var hud := Node2D.new()
var slots: Array[Vector3] = []
var roles: Array[int] = []
var elapsed := 0.0
var frame := 0
var movie := false
var review := false
var effects: Array[Dictionary] = []
var fleet_volleys: Array[Dictionary] = []
var fleet_missiles: Array[Dictionary] = []
var shu_lead := MeshInstance3D.new()
var shu_lead_model := Transform3D.IDENTITY
var shu_batches := {}
var last_spread_time := 0.0
var engine_materials: Array[StandardMaterial3D] = []
var engine_flares: Array[MeshInstance3D] = []
var damage_sparks: Array[MeshInstance3D] = []
var damage_glow: MeshInstance3D
var damage_light: OmniLight3D
var battle_audio := AudioStreamPlayer.new()
var audio_playback: AudioStreamPlaybackPolyphonic
var audio_cues: Array[Dictionary] = []
var tilt := 0.0
var start_point: Vector3
var hold_point: Vector3
var font: Font

func _ready() -> void:
	review = "--review-cut" in OS.get_cmdline_user_args()
	movie = review or "--movie-cut" in OS.get_cmdline_user_args()
	hold_point = WEI_ANCHOR - Vector3.RIGHT * engagement_distance
	start_point = hold_point - Vector3.RIGHT * 23.0
	var backdrop := preload("res://wu_map.gd").new()
	add_child(backdrop)
	backdrop.build_space()
	backdrop.build_lighting()
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-12, 146, 0)
	rim.light_color = Color("#c8dfff")
	rim.light_energy = 0.68
	add_child(rim)
	_build_formation()
	_build_fleet(shu, "shu", false)
	_build_fleet(wei, "wei", true)
	_build_effects()
	_build_damage_effects()
	_build_audio()
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(hud)
	hud.draw.connect(_draw_hud)
	font = ThemeDB.fallback_font
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.current = true
	_sample(0.0)

func _exit_tree() -> void:
	battle_audio.stop()
	audio_playback = null

func _process(delta: float) -> void:
	if review:
		var samples := [16.5, 18.05, 18.48, 18.83, 22.63, 22.82, 23.13, 24.45, 25.30]
		if frame >= samples.size():
			get_tree().quit()
			return
		_sample(samples[frame])
		frame += 1
	elif movie:
		if frame >= int(DURATION * 30.0):
			get_tree().quit()
			return
		_sample(frame / 30.0)
		frame += 1
	else:
		_sample(fmod(elapsed + delta, DURATION))

func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not movie:
		_sample(0.0)

func _sample(at: float) -> void:
	var previous := elapsed
	elapsed = at
	shu.position = start_point.lerp(hold_point, smoothstep(0.0, APPROACH_END, at))
	wei.position = WEI_ANCHOR
	tilt = smoothstep(TILT_START, TILT_END, at)
	var closing_view := smoothstep(0.45, 4.8, at)
	var midpoint := (shu.position + wei.position) * 0.5
	var focus := STRATEGIC_CENTER.lerp(midpoint, closing_view)
	var close_shot := smoothstep(16.55, 17.64, at) * (1.0 - smoothstep(19.04, 19.93, at))
	focus = focus.lerp(midpoint + Vector3(0.1, 0.05, 0), close_shot)
	var reply_shot := smoothstep(21.95, 22.48, at) * (1.0 - smoothstep(22.95, 23.47, at))
	focus += Vector3.RIGHT * (0.65 * reply_shot)
	var damage_shot := smoothstep(22.59, 23.04, at) * (1.0 - smoothstep(25.25, 26.45, at))
	focus = focus.lerp(hold_point + Vector3(-3.0, -0.16, 0.65), damage_shot)
	var angle := lerpf(lerpf(lerpf(0.93, 1.02, reply_shot), 1.14, close_shot), 1.03, damage_shot) * tilt
	var orbit := -0.13 + 0.22 * smoothstep(19.0, DURATION, at)
	var yaw := lerpf(lerpf(lerpf(orbit, 0.105, reply_shot), -0.47, close_shot), -0.46, damage_shot) * tilt
	var radial := Vector3(sin(yaw) * sin(angle), cos(angle), cos(yaw) * sin(angle))
	var right := Vector3(cos(yaw), 0, -sin(yaw))
	var local_span := (engagement_distance + lerpf(67.0, 46.0, tilt)) / 1.7777778
	var span := exp(lerpf(log(PARENT_MAP_SPAN), log(local_span), closing_view))
	span = lerpf(span, (engagement_distance + 13.0) / 1.7777778, close_shot)
	span = lerpf(span, (engagement_distance + 34.0) / 1.7777778, reply_shot)
	span = lerpf(span, 10.0, damage_shot)
	var strength := lerpf(lerpf(lerpf(0.15, 0.19, reply_shot), 0.30, close_shot), 0.28, damage_shot) * tilt
	var distance := span / (2.0 * strength + span / 100000.0)
	camera.transform = Transform3D(Basis(right, radial.cross(right), radial), focus + radial * distance)
	var near_clip := maxf(0.08, distance - 750.0)
	if strength <= 0.000001:
		camera.set_orthogonal(span, near_clip, distance + 52000.0)
	else:
		camera.set_frustum(span * near_clip / distance, Vector2.ZERO, near_clip, distance + 52000.0)
	shu.visible = tilt > 0.20
	wei.visible = shu.visible
	for group in [shu, wei]:
		for batch in group.get_children():
			batch.transparency = 1.0 - smoothstep(0.20, 0.62, tilt)
	_sample_damage(at)
	for effect in effects:
		_sample_effect(effect, at)
	for shot in fleet_volleys:
		_sample_fleet_volley(shot, at)
	for shot in fleet_missiles:
		_sample_fleet_missile(shot, at)
	_sample_audio(previous, at)
	hud.queue_redraw()

func _build_formation() -> void:
	slots.append(Vector3.ZERO)
	roles.append(0)
	for deck in 3:
		for row in 4:
			for column in 5:
				if deck == 1 and row == 0 and column == 2:
					continue
				var tier := float(deck - 1)
				var wing := float(column - 2)
				slots.append(Vector3(-4.0 - row * 1.7 - absf(wing) * 0.38 - absf(tier) * 1.5,
					tier * 1.25 + wing * 0.10, wing * 1.25 + tier * 2.8) * FORMATION_SCALE)
				roles.append((row + column + deck) % HULLS.size())

func _shu_ship_pose(index: int, at: float) -> Transform3D:
	var age := maxf(0.0, at - SHU_IMPACT)
	if index == 0:
		var kick := smoothstep(0.0, 0.16, age)
		var drift := smoothstep(0.12, 2.6, age)
		var roll := -kick * (0.27 + 0.39 * cos(age * 9.0) * exp(-age * 2.2))
		var pitch := kick * (0.10 + 0.20 * cos(age * 6.5) * exp(-age * 1.65))
		var attitude := Basis.from_euler(Vector3(roll, drift * 0.13, pitch))
		return Transform3D(attitude, Vector3(-0.62, -0.74, 1.16) * drift)
	var slot := slots[index]
	var side := 1.0 if slot.z >= 0.0 else -1.0
	var depth := clampf((-slot.x - 6.0) / 12.0, 0.0, 1.0)
	var delay := 0.35 + depth * 1.15 + (index % 5) * 0.035
	var evade := smoothstep(delay, delay + 1.2, age)
	var turn := sin(evade * PI) * side * 0.16
	var offset := Vector3(-0.72, (0.33 - depth * 0.5) * side,
		side * lerpf(2.75, 1.15, depth)) * evade
	return Transform3D(Basis(Vector3.UP, turn), slot + offset)

func _build_damage_effects() -> void:
	for n in 6:
		engine_flares.append(_flare(Color("#66eaca")))
	for n in 12:
		damage_sparks.append(_streak(Color("#ffc084").lerp(Color.WHITE, (n % 4) * 0.15), 2.5))
	damage_glow = _flare(Color("#ff884e"))
	damage_light = _flash_light(Color("#ffae76"))

func _sample_damage(at: float) -> void:
	var age := at - SHU_IMPACT
	var pose := _shu_ship_pose(0, at)
	shu_lead.transform = pose * shu_lead_model
	var throttle := 1.0 - smoothstep(0.02, 0.24, age)
	for material in engine_materials:
		material.emission_energy_multiplier = material.get_meta("operating_energy") * throttle
	var aft := shu.to_global(pose * Vector3(-0.575, -0.04, 0))
	for n in engine_flares.size():
		var nozzle := Vector3(-0.56, -0.045 + floorf(n / 3.0) * 0.065, (n % 3 - 1) * 0.093)
		_set_flare(engine_flares[n], shu.to_global(pose * nozzle), 0.28, throttle * 1.85)
	var burnout := exp(-maxf(age, 0.0) * 1.08)
	var flash := 0.0
	if age >= 0.0:
		flash = 1.8 * exp(-age * 9.0) + (0.42 + 0.22 * sin(age * 26.0)) * burnout
	_set_flare(damage_glow, aft, 0.42, flash)
	_set_flash(damage_light, aft, flash * 1.6)
	for n in damage_sparks.size():
		var spark_age := age - 0.21 - n * 0.043
		var piece := damage_sparks[n]
		if spark_age < 0.0 or spark_age > 1.25:
			piece.visible = false
			continue
		var spin := n * 2.39996
		var eject := pose.basis * Vector3(-0.75 - (n % 4) * 0.18, sin(spin) * 0.62, cos(spin) * 0.78)
		var head := aft + eject * spark_age
		_segment(piece, head - eject * minf(spark_age, 0.12), head, 0.018 * (1.0 - spark_age / 1.25))
	var spread_time := clampf(age, 0.0, 3.0)
	if not is_equal_approx(spread_time, last_spread_time):
		last_spread_time = spread_time
		for index in range(1, slots.size()):
			var hull: Dictionary = shu_batches[index]
			var ship_pose := _shu_ship_pose(index, SHU_IMPACT + spread_time)
			var model: Transform3D = hull.model
			hull.batch.set_instance_transform(hull.index, ship_pose * model)

func _add_shu_lead(mesh: ArrayMesh, relative: Transform3D) -> void:
	shu_lead.mesh = mesh
	shu_lead_model = relative
	shu_lead.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shu.add_child(shu_lead)
	for surface in mesh.get_surface_count():
		var original := mesh.surface_get_material(surface) as StandardMaterial3D
		if original == null or not original.resource_name.contains("Turquoise emitter"):
			continue
		var lamp := original.duplicate() as StandardMaterial3D
		lamp.set_meta("operating_energy", lamp.emission_energy_multiplier)
		shu_lead.set_surface_override_material(surface, lamp)
		engine_materials.append(lamp)

func _build_fleet(group: Node3D, prefix: String, reverse: bool) -> void:
	add_child(group)
	group.name = "WeiFleet" if reverse else "ShuFleet"
	group.rotation.y = PI if reverse else 0.0
	for role in HULLS.size():
		var reference := load("res://models/%s-%s.glb" % [prefix, HULLS[role]]) as PackedScene
		var model := reference.instantiate() as Node3D
		var bounds := AABB()
		var surfaces := {}
		var stack: Array[Node3D] = [model]
		var transforms := {model: model.transform}
		while not stack.is_empty():
			var part: Node3D = stack.pop_back()
			var transform_in_model: Transform3D = transforms[part]
			if part is MeshInstance3D and part.mesh:
				var section: AABB = transform_in_model * part.get_aabb()
				bounds = bounds.merge(section) if bounds.has_volume() else section
				for index in part.mesh.get_surface_count():
					var material: Material = part.get_active_material(index)
					if not surfaces.has(material):
						var surface := SurfaceTool.new()
						surface.begin(Mesh.PRIMITIVE_TRIANGLES)
						surface.set_material(material)
						surfaces[material] = surface
					var surface: SurfaceTool = surfaces[material]
					surface.append_from(part.mesh, index, transform_in_model)
			for child in part.get_children():
				if child is Node3D:
					transforms[child] = transform_in_model * child.transform
					stack.append(child)
		model.free()
		var merged := ArrayMesh.new()
		for surface in surfaces.values():
			surface.commit(merged)
		var hull_scale: float = LENGTHS[role] * FORMATION_SCALE / maxf(bounds.size.x, bounds.size.z)
		var orientation := Basis.IDENTITY
		if bounds.size.z > bounds.size.x:
			orientation = Basis(Vector3.UP, PI / 2.0)
		# Wei GLBs face -X. Normalize to formation-local +X before the fleet's world rotation.
		if reverse:
			orientation = Basis(Vector3.UP, PI) * orientation
		var basis := orientation.scaled(Vector3.ONE * hull_scale)
		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = merged
		var separate_lead := group == shu and role == 0
		multi.instance_count = roles.count(role) - (1 if separate_lead else 0)
		var ship := 0
		for i in slots.size():
			if roles[i] == role:
				var model_transform := Transform3D(basis, -(basis * bounds.get_center()))
				if separate_lead and i == 0:
					_add_shu_lead(merged, model_transform)
					continue
				multi.set_instance_transform(ship, Transform3D(Basis.IDENTITY, slots[i]) * model_transform)
				if group == shu:
					shu_batches[i] = {"batch": multi, "index": ship, "model": model_transform}
				ship += 1
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = multi
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(batch)
	print("%s: %d ships, %d hull classes" % [group.name, slots.size(), HULLS.size()])

func _world_slot(group: Node3D, slot: int, muzzle: bool) -> Vector3:
	return _ship_point(group, FIRING_SLOTS[slot], muzzle)

func _ship_point(group: Node3D, index: int, muzzle: bool, at: float = 0.0) -> Vector3:
	var length: float = LENGTHS[roles[index]] * FORMATION_SCALE
	var hardpoint := Vector3(length * (0.48 if muzzle else 0.36), length * 0.09, 0)
	var local := _shu_ship_pose(index, at) * hardpoint if group == shu else slots[index] + hardpoint
	var center := hold_point if group == shu else WEI_ANCHOR
	return center + group.basis * local

func _build_effects() -> void:
	for i in 3:
		_effect(shu, i, i, MISSILE_START + 0.16 * i, 1.15, true)
	_effect(shu, 0, 0, SHU_LASER, 0.35, false)
	_effect(wei, 0, 0, WEI_LASER, 0.36, false)
	_build_fleet_volleys()

func _build_fleet_volleys() -> void:
	var dart := CapsuleMesh.new()
	dart.radius = 0.023
	dart.height = 0.21
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color("#c4c8cc")
	shell.roughness = 0.38
	shell.metallic = 0.55
	var order: Array[int] = []
	for ship in slots.size():
		order.append(ship)
	order.sort_custom(func(a: int, b: int) -> bool: return slots[a].x > slots[b].x)
	for side in [shu, wei]:
		var enemy := wei if side == shu else shu
		var color := JADE if side == shu else AZURE
		var opening := SHU_LASER + 0.32 if side == shu else WEI_LASER + 0.24
		for rank in order.size():
			var ship := order[rank]
			var echelon := floori(rank / 20.0)
			var stagger := float((rank * 7) % 20) * 0.065
			var target: int = order[(rank * 13 + (4 if side == shu else 11)) % order.size()]
			var missile_start := MISSILE_START + 0.45 if side == shu else WEI_LASER + 0.62
			var missile_time := missile_start + echelon * 0.85 + stagger * 0.66
			_build_fleet_missile(side, ship, enemy, target, missile_time, echelon, color, dart, shell)
			var start := opening + echelon * 1.24 + stagger
			fleet_volleys.append({
				"ship": ship, "side": side, "target": target, "echelon": echelon, "start": start,
				"repeat": start + 4.1 + (ship % 5) * 0.12,
				"final": start + 6.65 + (ship % 4) * 0.085,
				"from": _ship_point(side, ship, true), "to": _ship_point(enemy, target, false),
				"emitter": _flare(color), "strike": _flare(Color("#ffbf87")),
				"beam": _streak(color.lerp(Color.WHITE, 0.12), 2.0)
			})

func _build_fleet_missile(side: Node3D, ship: int, enemy: Node3D, target: int, start: float,
		echelon: int, color: Color, dart: Mesh, material: Material) -> void:
	var hull := MeshInstance3D.new()
	hull.mesh = dart
	hull.material_override = material
	add_child(hull)
	var trail: Array[MeshInstance3D] = []
	for n in 6:
		var intensity := pow(1.0 - n / 6.0, 2.0)
		trail.append(_streak(color.lerp(Color("#ffcc92"), 0.68), intensity * 1.5))
	var life := 0.95 + (ship % 5) * 0.06
	var repeat := start + (SHU_MISSILE_REPEAT if side == shu else WEI_MISSILE_REPEAT) + (ship % 5) * 0.06
	var second_target := (target + 17) % slots.size()
	fleet_missiles.append({
		"ship": ship, "side": side, "target": target, "echelon": echelon, "start": start,
		"life": life, "repeat": repeat,
		"from": _ship_point(side, ship, true, start),
		"to": _ship_point(enemy, target, false, start + life),
		"repeat_from": _ship_point(side, ship, true, repeat),
		"repeat_to": _ship_point(enemy, second_target, false, repeat + life),
		"hull": hull, "trail": trail, "engine": _flare(Color("#ffc487")),
		"muzzle": _flare(color), "impact": _flare(Color("#ffbd83"))
	})

func _sample_fleet_missile(shot: Dictionary, at: float) -> void:
	var second_wave: bool = at >= shot.repeat
	var age: float = at - (shot.repeat if second_wave else shot.start)
	var life: float = shot.life
	var a: Vector3 = shot.repeat_from if second_wave else shot.from
	var b: Vector3 = shot.repeat_to if second_wave else shot.to
	var muzzle := exp(-age * 24.0) if age >= 0.0 and age < 0.21 else 0.0
	var impact_age := age - life
	var impact := exp(-impact_age * 13.0) if impact_age >= 0.0 and impact_age < 0.5 else 0.0
	_set_flare(shot.muzzle, a, 0.45, muzzle * 1.4)
	_set_flare(shot.impact, b, 0.63, impact * 1.8)
	_sample_missile(shot, age, life, a, b)

func _sample_fleet_volley(shot: Dictionary, at: float) -> void:
	var wave := 2 if at >= shot.final else (1 if at >= shot.repeat else 0)
	var start: float = shot.final if wave == 2 else (shot.repeat if wave == 1 else shot.start)
	var age := at - start
	var enemy := wei if shot.side == shu else shu
	var target: int = (shot.target + 13 * wave) % slots.size()
	var a := _ship_point(shot.side, shot.ship, true, at)
	var b := _ship_point(enemy, target, false, at)
	var muzzle := exp(-age * 19.0) if age >= 0.0 and age < 0.23 else 0.0
	var hit_age := age - 0.15
	var hit := exp(-hit_age * 14.0) if hit_age >= 0.0 and hit_age < 0.36 else 0.0
	_set_flare(shot.emitter, a, 0.55, muzzle * 1.8)
	_set_flare(shot.strike, b, 0.58, hit * 1.6)
	var beam: MeshInstance3D = shot.beam
	if age <= 0.065 or age >= 0.31:
		beam.visible = false
		return
	var travel := clampf((age - 0.065) / 0.085, 0.0, 1.0)
	var width := 0.030 * (1.0 - smoothstep(0.15, 0.31, age))
	_segment(beam, a, a.lerp(b, travel), width)

func _build_audio() -> void:
	var stream := AudioStreamPolyphonic.new()
	stream.polyphony = 16
	battle_audio.stream = stream
	battle_audio.volume_db = -3.0
	add_child(battle_audio)
	battle_audio.play()
	audio_playback = battle_audio.get_stream_playback() as AudioStreamPlaybackPolyphonic
	for i in 3:
		var launch := MISSILE_START + i * 0.16
		_cue(launch, preload("res://audio/missile_launch.wav"), -5.0 - i * 3.0, 1.08 + i * 0.05)
		_cue(launch + 1.15, preload("res://audio/missile_hit.wav"), -6.0 - i * 2.5, 0.87 + i * 0.08)
	_cue(SHU_LASER, preload("res://audio/laser_heavy.wav"), -5.0, 1.08)
	_cue(WEI_LASER, preload("res://audio/laser_heavy.wav"), -4.0, 0.88)
	_cue(SHU_IMPACT, preload("res://audio/missile_hit.wav"), -6.0, 0.76)
	_cue(SHU_IMPACT + 0.36, preload("res://audio/armor_hit.wav"), -11.0, 0.63)
	var shu_first := MISSILE_START + 0.45
	var wei_first := WEI_LASER + 0.62
	for side_start in [shu_first, wei_first, shu_first + SHU_MISSILE_REPEAT, wei_first + WEI_MISSILE_REPEAT]:
		for burst in 8:
			var at: float = side_start + burst * 0.33
			_cue(at, preload("res://audio/missile_launch.wav"), -17.0, 0.96 + (burst % 4) * 0.08)
			_cue(at + 1.08, preload("res://audio/missile_hit.wav"), -19.0, 0.85 + (burst % 3) * 0.09)
	for i in 35:
		var at := WEI_LASER + 0.29 + i * 0.305
		_cue(at, preload("res://audio/laser_light.wav"), -13.0 + (i % 3) * 1.5, 0.88 + (i % 5) * 0.085)
		if i % 3 == 1:
			_cue(at + 0.15, preload("res://audio/armor_hit.wav"), -15.0, 0.90 + (i % 4) * 0.09)

func _cue(at: float, stream: AudioStream, volume: float, pitch: float) -> void:
	audio_cues.append({"at": at, "stream": stream, "volume": volume, "pitch": pitch})

func _sample_audio(previous: float, current: float) -> void:
	if review or audio_playback == null or current < previous:
		return
	for cue in audio_cues:
		if cue.at > previous and cue.at <= current:
			audio_playback.play_stream(cue.stream, 0.0, cue.volume, cue.pitch)

func _effect(side: Node3D, source: int, target: int, start: float, life: float, missile: bool) -> void:
	var color := JADE if side == shu else AZURE
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("#a9b4bf")
	metal.metallic = 0.69
	metal.roughness = 0.36
	var hull: MeshInstance3D
	var trail: Array[MeshInstance3D] = []
	var beam: MeshInstance3D
	if missile:
		var dart := CapsuleMesh.new()
		dart.radius = 0.032
		dart.height = 0.29
		hull = MeshInstance3D.new()
		hull.mesh = dart
		hull.material_override = metal
		add_child(hull)
		for n in 12:
			var intensity := pow(1.0 - n / 12.0, 2.1)
			trail.append(_streak(Color("#ffc17d").lerp(Color("#92acba"), n / 12.0), intensity * 2.6))
	else:
		beam = _streak(color.lerp(Color.WHITE, 0.36), 3.5)
	var sparks: Array[MeshInstance3D] = []
	var scatter: Array[Vector3] = []
	var rng := RandomNumberGenerator.new()
	rng.seed = int(start * 1000.0)
	for n in 9:
		sparks.append(_streak(Color("#ffba71").lerp(Color.WHITE, rng.randf() * 0.7), 2.4))
		scatter.append(Vector3(rng.randfn(), rng.randfn(), rng.randfn()).normalized() * rng.randf_range(0.35, 2.5))
	effects.append({
		"from": _world_slot(side, source, true),
		"to": _world_slot(wei if side == shu else shu, target, false),
		"start": start, "life": life, "missile": missile,
		"hull": hull, "beam": beam, "trail": trail, "sparks": sparks, "scatter": scatter,
		"muzzle": _flare(color), "engine": _flare(Color("#ffab5e")) if missile else null,
		"impact": _flare(Color("#ffc795")), "source_light": _flash_light(color),
		"target_light": _flash_light(Color("#ffb176"))
	})

func _streak(color: Color, intensity: float) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.height = 1.0
	mesh.top_radius = 1.0
	mesh.bottom_radius = 0.62
	mesh.radial_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var material := ShaderMaterial.new()
	material.shader = preload("res://engagement_streak.gdshader")
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("energy", intensity)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _flare(color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = QuadMesh.new()
	var material := ShaderMaterial.new()
	material.shader = preload("res://engagement_flare.gdshader")
	material.set_shader_parameter("tint", color)
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)
	return node

func _flash_light(color: Color) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = color
	light.omni_range = 2.4
	light.omni_attenuation = 1.45
	add_child(light)
	return light

func _set_flare(flare: MeshInstance3D, point: Vector3, size: float, energy: float) -> void:
	flare.visible = energy > 0.01
	if flare.visible:
		flare.position = point
		flare.look_at(camera.position)
		flare.scale = Vector3(size, size, size)
		flare.material_override.set_shader_parameter("energy", energy)

func _set_flash(light: OmniLight3D, point: Vector3, energy: float) -> void:
	light.visible = energy > 0.01
	light.position = point
	light.light_energy = energy

func _segment(mesh: MeshInstance3D, a: Vector3, b: Vector3, width: float) -> void:
	var direction := b - a
	mesh.visible = direction.length_squared() > 0.000001 and width > 0.0001
	if mesh.visible:
		mesh.position = (a + b) * 0.5
		mesh.quaternion = Quaternion(Vector3.UP, direction.normalized())
		mesh.scale = Vector3(width, direction.length(), width)

func _missile_point(a: Vector3, b: Vector3, fraction: float) -> Vector3:
	var t := clampf(fraction, 0.0, 1.0)
	return a.lerp(b, t * (0.22 + 0.78 * t))

func _sample_effect(effect: Dictionary, at: float) -> void:
	var age: float = at - effect.start
	var life: float = effect.life
	var a: Vector3 = effect.from
	var b: Vector3 = effect.to
	var missile: bool = effect.missile
	var impact_age := age - (life if missile else 0.15)
	var muzzle := exp(-maxf(age, 0.0) * 22.0) if age >= 0.0 and age < 0.24 else 0.0
	var impact := exp(-impact_age * 10.0) if impact_age >= 0.0 and impact_age < 0.64 else 0.0
	_set_flare(effect.muzzle, a, 0.85 + (1.0 - muzzle) * 0.27, muzzle * 2.25)
	_set_flash(effect.source_light, a, muzzle * 2.8)
	_set_flare(effect.impact, b, 0.70 + clampf(impact_age, 0.0, 0.6) * 0.55, impact * 2.65)
	_set_flash(effect.target_light, b, impact * 3.3)
	for i in effect.sparks.size():
		var spark: MeshInstance3D = effect.sparks[i]
		if impact_age < 0.0 or impact_age >= 0.58:
			spark.visible = false
			continue
		var velocity: Vector3 = effect.scatter[i]
		var tip := b + velocity * impact_age
		_segment(spark, tip - velocity * minf(impact_age, 0.045), tip, 0.012 * (1.0 - impact_age / 0.58))
	if missile:
		_sample_missile(effect, age, life, a, b)
	else:
		var beam: MeshInstance3D = effect.beam
		var travel := (age - 0.075) / 0.075
		if travel <= 0.0 or age >= life:
			beam.visible = false
		else:
			var pulse := 1.0 - smoothstep(0.15, life, age)
			_segment(beam, a, a.lerp(b, minf(travel, 1.0)), 0.040 * pulse)

func _sample_missile(effect: Dictionary, age: float, life: float, a: Vector3, b: Vector3) -> void:
	var u := clampf(age / life, 0.0, 1.0)
	var head := _missile_point(a, b, u)
	var forward := (b - a).normalized()
	var hull: MeshInstance3D = effect.hull
	hull.visible = age >= 0.0 and age < life
	if hull.visible:
		hull.position = head
		hull.quaternion = Quaternion(Vector3.UP, forward)
	_set_flare(effect.engine, head - forward * 0.16, 0.53 if effect.trail.size() > 6 else 0.32, 2.1 if hull.visible else 0.0)
	for i in effect.trail.size():
		var node: MeshInstance3D = effect.trail[i]
		var end_age := age - float(i) * 0.028
		var start_age := end_age - 0.030
		if end_age <= 0.0 or start_age >= life:
			node.visible = false
			continue
		var tip := _missile_point(a, b, clampf(end_age / life, 0.0, 1.0)) - forward * 0.16
		var tail := _missile_point(a, b, clampf(start_age / life, 0.0, 1.0)) - forward * 0.16
		_segment(node, tail, tip, lerpf(0.047, 0.009, float(i) / float(effect.trail.size())))

func _ink(text: String, point: Vector2, size: int, color: Color) -> void:
	hud.draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _project(point: Vector3) -> Vector2:
	return camera.unproject_position(point)

func _arrow(point: Vector2, heading: Vector2, color: Color, size: float) -> void:
	var cross := heading.orthogonal()
	hud.draw_colored_polygon(PackedVector2Array([
		point + heading * size,
		point - heading * size * 0.58 + cross * size * 0.57,
		point - heading * size * 0.28,
		point - heading * size * 0.58 - cross * size * 0.57
	]), color)

func _map_line(a: Vector3, b: Vector3, color: Color) -> void:
	if not camera.is_position_behind(a) and not camera.is_position_behind(b):
		hud.draw_line(_project(a), _project(b), color, 1.0, true)

func _draw_hud() -> void:
	var screen := get_viewport().get_visible_rect().size
	var scale_factor := screen.x / 1920.0
	var frame_color := Color("#7790ab")
	var map_alpha := 1.0 - smoothstep(0.12, 0.80, tilt)
	if map_alpha > 0.0:
		var graticule := Color(0.38, 0.62, 0.80, 0.24 * map_alpha)
		for x in range(-22000, 22001, 2000):
			_map_line(Vector3(x, -1, -15000), Vector3(x, -1, 15000), graticule)
		for z in range(-15000, 15001, 2000):
			_map_line(Vector3(-22000, -1, z), Vector3(22000, -1, z), graticule)
		var route_start := _project(start_point)
		var route_end := _project(hold_point)
		hud.draw_dashed_line(route_start, route_end, Color(JADE, 0.65 * map_alpha), 2.0 * scale_factor, 13.0 * scale_factor, true)
		_arrow(route_start.lerp(route_end, 0.76), (route_end - route_start).normalized(), Color(JADE, map_alpha), 9.0 * scale_factor)
		hud.draw_arc(route_end, 22.0 * scale_factor, 0.0, TAU, 48, Color(JADE, 0.76 * map_alpha), 2.0 * scale_factor, true)
		var anchor := _project(wei.position)
		var contact := _project(shu.position)
		var separation := contact.distance_to(anchor)
		if separation > 72.0 * scale_factor:
			hud.draw_arc(anchor, 34.0 * scale_factor, 0.0, TAU, 64, Color(AZURE, 0.55 * map_alpha), 2.0 * scale_factor, true)
			for group in [shu, wei]:
				var color := JADE if group == shu else AZURE
				for slot in slots:
					var origin: Vector3 = group.to_global(slot)
					var point := _project(origin)
					var heading := (_project(origin + group.basis.x) - point).normalized()
					_arrow(point, heading, Color(color, map_alpha), (17.0 if slot == Vector3.ZERO else 5.0) * scale_factor)
		else:
			var sector := (anchor + contact) * 0.5
			hud.draw_circle(sector, 17.0 * scale_factor, Color(0.02, 0.055, 0.09, 0.9 * map_alpha))
			hud.draw_arc(sector, 17.0 * scale_factor, 0.0, TAU, 28, Color(0.68, 0.93, 1.0, map_alpha), 2.0 * scale_factor, true)
			_ink("SHU / WEI CONTACT SECTOR", sector + Vector2(24, -12) * scale_factor, roundi(23.0 * scale_factor), Color(0.68, 0.93, 1.0, map_alpha))
	hud.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_factor)
	hud.draw_rect(Rect2(0, 0, 1920, 113), Color(0.018, 0.032, 0.06, 0.90))
	hud.draw_rect(Rect2(0, 980, 1920, 100), Color(0.018, 0.032, 0.06, 0.90))
	hud.draw_line(Vector2(54, 112), Vector2(1866, 112), Color(frame_color, 0.53))
	hud.draw_line(Vector2(54, 981), Vector2(1866, 981), Color(frame_color, 0.53))
	_ink("SPACE BATTLE OF THREE KINGDOMS", Vector2(55, 46), 19, frame_color)
	_ink("SHU / WEI FLEET ENGAGEMENT", Vector2(55, 88), 36, Color("#f0f4ff"))
	var mode := "STRATEGIC OVERVIEW"
	if elapsed >= TILT_END:
		mode = "TACTICAL VIEW"
	elif elapsed >= TILT_START:
		mode = "TACTICAL TRANSITION"
	_ink(mode, Vector2(1515, 62), 23, Color("#d0dff4"))
	_ink("%05.2f s" % elapsed, Vector2(1747, 91), 18, frame_color)
	var phase := "SHU ADVANCING   /   WEI AT ANCHOR"
	var phase_color := Color("#d1e3f5")
	if elapsed >= WEI_LASER + 4.0:
		phase = "ALL SHIPS ENGAGED   /   STAGGERED VOLLEYS"
	elif elapsed >= SHU_IMPACT and elapsed < SHU_IMPACT + 2.9:
		phase = "SHU LEAD SHIP HIT   /   FORMATION OPENS"
		phase_color = Color("#ffbd83")
	elif elapsed >= WEI_LASER:
		phase = "WEI LASER RESPONSE"
		phase_color = AZURE
	elif elapsed >= SHU_LASER:
		phase = "SHU LASER VOLLEY"
		phase_color = JADE
	elif elapsed >= MISSILE_START:
		phase = "SHU MISSILE SALVO"
		phase_color = JADE
	elif elapsed >= APPROACH_END:
		phase = "SHU HOLDING AT ENGAGEMENT RANGE"
	_ink(phase, Vector2(55, 1028), 28, phase_color)
	_ink("FLEET SEPARATION  %04.1f u" % shu.position.distance_to(wei.position), Vector2(1490, 1027), 22, frame_color)
	hud.draw_line(Vector2(55, 1054), Vector2(1864, 1054), Color(frame_color, 0.35), 2.0)
	hud.draw_line(Vector2(55, 1054), Vector2(lerpf(55.0, 1864.0, elapsed / DURATION), 1054), phase_color, 3.0)
	_fleet_label(Vector2(57, 166), "SHU HAN", JADE)
	_fleet_label(Vector2(1617, 166), "CAO WEI", AZURE)
	hud.draw_set_transform(Vector2.ZERO)

func _fleet_label(point: Vector2, title: String, color: Color) -> void:
	hud.draw_rect(Rect2(point - Vector2(0, 24), Vector2(245, 40)), Color(0.016, 0.027, 0.044, 0.87))
	hud.draw_rect(Rect2(point - Vector2(0, 24), Vector2(4, 40)), color)
	_ink(title + "  /  60", point + Vector2(16, 4), 24, color)
