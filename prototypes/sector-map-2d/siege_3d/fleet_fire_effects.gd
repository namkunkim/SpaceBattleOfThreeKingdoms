extends Node3D
## Renders the shared fleet fire stream in the sector 3D view.

const Combat := preload("res://tactical_fleet_combat.gd")
const SMOKE_COLOR := Color(0.63, 0.67, 0.72)
const SMOKE_STEPS := 10
const SMOKE_SHADER := """
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
void fragment() {
	float edge = abs(UV.y * 2.0 - 1.0);
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a * (1.0 - smoothstep(0.0, 1.0, edge));
}
"""

var battle_fx := ImmediateMesh.new()
var fx_material := StandardMaterial3D.new()
var smoke_mesh := ImmediateMesh.new()
var smoke_material := ShaderMaterial.new()
var glow_mesh := ImmediateMesh.new()
var glow_material := ShaderMaterial.new()
var hit_lights: Array[OmniLight3D] = []
var camera_position := Vector3.ZERO
var camera_basis := Basis.IDENTITY


func _ready() -> void:
	fx_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fx_material.vertex_color_use_as_albedo = true
	fx_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_attach_mesh(battle_fx)
	var shader := Shader.new()
	shader.code = SMOKE_SHADER
	smoke_material.shader = shader
	_attach_mesh(smoke_mesh)
	_build_flashes()


func _attach_mesh(mesh: ImmediateMesh) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


func clear() -> void:
	battle_fx.clear_surfaces()
	smoke_mesh.clear_surfaces()
	glow_mesh.clear_surfaces()
	for light in hit_lights:
		light.hide()


func render(shots: Array[Dictionary], poses: Array[Transform3D], view_camera: Camera3D,
		scale_fx: float) -> void:
	clear()
	if poses.is_empty() or shots.is_empty():
		return
	camera_position = to_local(view_camera.global_position)
	camera_basis = global_basis.inverse() * view_camera.global_basis
	battle_fx.surface_begin(Mesh.PRIMITIVE_TRIANGLES, fx_material)
	smoke_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, smoke_material)
	glow_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES, glow_material)
	var lights_used := 0
	for shot in shots:
		var origin: Vector3 = shot.get("origin", poses[int(shot.source)].origin)
		var target: Vector3 = shot.get("aim", poses[int(shot.target)].origin)
		var progress: float = shot.progress
		if shot.impact:
			lights_used += _draw_impact(target, shot.weapon, progress, lights_used)
			continue
		match shot.weapon:
			Combat.Weapon.LASER:
				var pulse := sin(progress * PI)
				var beam := Color("#406b8d").lerp(Color("#bce8ff"), pulse)
				_ribbon(battle_fx, origin, target, 0.017 * scale_fx * lerpf(0.68, 1.0, pulse), beam, beam)
			Combat.Weapon.MISSILE:
				_draw_missile(origin, target, progress, shot.emitter, scale_fx)
			Combat.Weapon.RAILGUN:
				var head := origin.lerp(target, progress)
				var tail := origin.lerp(target, maxf(progress - 0.042, 0.0))
				_ribbon(battle_fx, head, tail, 0.010 * scale_fx, Color("#ffe7b2"), Color("#ad7750"))
				if progress < 0.10:
					_glow(origin, 0.30, Color(1.0, 0.74, 0.41, 1.0 - progress / 0.10))
	# Keep surfaces valid on frames with an empty layer or shots exactly at launch.
	for mesh in [battle_fx, smoke_mesh]:
		mesh.surface_set_color(Color.TRANSPARENT)
		for i in 3:
			mesh.surface_set_uv(Vector2.ZERO)
			mesh.surface_add_vertex(poses[0].origin)
		mesh.surface_end()
	_glow(poses[0].origin, 0.001, Color.TRANSPARENT)
	glow_mesh.surface_end()


func _draw_missile(origin: Vector3, target: Vector3, t: float, emitter: int, scale_fx: float) -> void:
	var nose := _missile_path(origin, target, t, emitter)
	var behind := _missile_path(origin, target, maxf(0.0, t - 0.014), emitter)
	var axis := (nose - behind).normalized()
	var engine := nose - axis * 0.15
	var flame_end := engine - axis * 0.16
	_ribbon(battle_fx, nose, engine, 0.015 * scale_fx, Color("#d9dce0"), Color("#858f9c"))
	_ribbon(battle_fx, engine, flame_end, 0.021 * scale_fx, Color("#fff4d0"), Color("#e17833"))
	_glow(engine, 0.20, Color(1.0, 0.71, 0.35, 0.92))

	for i in SMOKE_STEPS:
		var age_a := float(i) / SMOKE_STEPS
		var age_b := float(i + 1) / SMOKE_STEPS
		var a := maxf(0.0, t - 0.012 - age_a * 0.30)
		var b := maxf(0.0, t - 0.012 - age_b * 0.30)
		var alpha_a := 0.26 * pow(1.0 - age_a, 1.7)
		var alpha_b := 0.26 * pow(1.0 - age_b, 1.7)
		_ribbon(smoke_mesh, _missile_path(origin, target, a, emitter),
			_missile_path(origin, target, b, emitter), lerpf(0.03, 0.10, age_a) * scale_fx,
			Color(SMOKE_COLOR, alpha_a), Color(SMOKE_COLOR, alpha_b))


func _missile_path(origin: Vector3, target: Vector3, t: float, emitter: int) -> Vector3:
	var pos := origin.lerp(target, t)
	var arc := sin(t * PI)
	pos.y += arc * (1.3 + 0.52 * (emitter % 6))
	pos.z += arc * sin(emitter) * 2.1
	return pos


func _draw_impact(at: Vector3, weapon: Combat.Weapon, progress: float, lights_used: int) -> int:
	var missile := weapon == Combat.Weapon.MISSILE
	var decay := sin(minf(1.0, progress * 7.0) * PI * 0.5) * pow(1.0 - progress, 0.55)
	var burst := (0.45 if missile else 0.19) * (1.0 - progress)
	var up := camera_basis.y * burst
	var right := camera_basis.x * burst
	_ribbon(battle_fx, at - up, at + up, burst * 0.16, Color("#dd8844"), Color("#ffd49a"))
	_ribbon(battle_fx, at - right, at + right, burst * 0.18, Color("#dd8844"), Color("#ffd49a"))
	_glow(at, (1.10 if missile else 0.51) * (0.55 + decay), Color(1.0, 0.58, 0.22, decay))
	if lights_used < hit_lights.size() and decay > 0.15:
		var light := hit_lights[lights_used]
		light.position = at + Vector3.UP * 0.35
		light.light_energy = decay * (2.3 if missile else 0.75)
		light.show()
		return 1
	return 0


func _ribbon(mesh: ImmediateMesh, a: Vector3, b: Vector3, radius: float,
		start_color: Color, end_color: Color) -> void:
	if a.is_equal_approx(b) or radius <= 0.0:
		return
	var across := (b - a).cross(camera_position - a).normalized() * radius
	var corners := [a - across, a + across, b + across, b - across]
	for i in [0, 1, 2, 0, 2, 3]:
		mesh.surface_set_color(start_color if i < 2 else end_color)
		mesh.surface_set_uv(Vector2(0.0 if i < 2 else 1.0, 0.0 if i == 0 or i == 3 else 1.0))
		mesh.surface_add_vertex(corners[i])


func _build_flashes() -> void:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;
void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float core = exp(-r*r*47.0);
	vec3 tint = mix(COLOR.rgb, vec3(1.0,0.96,0.82), core);
	ALBEDO = tint;
	ALPHA = (core + exp(-r*r*7.0)*0.82) * (1.0-smoothstep(0.75,1.0,r)) * COLOR.a;
}
"""
	glow_material.shader = shader
	_attach_mesh(glow_mesh)
	for i in 4:
		var light := OmniLight3D.new()
		light.light_color = Color("#ffb564")
		light.omni_range = 8.0
		light.visible = false
		add_child(light)
		hit_lights.append(light)

func _glow(point: Vector3, radius: float, color: Color) -> void:
	var right := camera_basis.x * radius
	var up := camera_basis.y * radius
	glow_mesh.surface_set_color(color)
	for uv in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.ZERO, Vector2.ONE, Vector2.DOWN]:
		glow_mesh.surface_set_uv(uv)
		glow_mesh.surface_add_vertex(point + right * (uv.x * 2.0 - 1.0) + up * (1.0 - uv.y * 2.0))
