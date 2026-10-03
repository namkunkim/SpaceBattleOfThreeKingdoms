class_name FxPool
extends MultiMeshInstance3D

# 연출 스프라이트 풀. 수명이 있는 입자를 매 프레임 MultiMesh 하나로 그린다.
# kind 값은 fx_sprite.gdshaderinc 의 설명을 따른다.

enum { GLOW, FIRE, RING, SHIELD, FLARE, SMOKE, EMBER }

var capacity := 0
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _col := PackedColorArray()
var _size := PackedFloat32Array()
var _grow := PackedFloat32Array()
var _age := PackedFloat32Array()
var _life := PackedFloat32Array()
var _kind := PackedInt32Array()
var _seed := PackedFloat32Array()
var _alpha := PackedFloat32Array()
var _drag := PackedFloat32Array()
var count := 0

func _init(cap: int, additive: bool) -> void:
	capacity = cap
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = cap
	mm.visible_instance_count = 0
	multimesh = mm
	var mat := ShaderMaterial.new()
	mat.shader = load("res://view/fleet_render/fx_sprite_add.gdshader" if additive else "res://view/fleet_render/fx_sprite_mix.gdshader")
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))
	for arr in [_pos, _vel]:
		arr.resize(cap)
	_col.resize(cap)
	for arr in [_size, _grow, _age, _life, _seed, _alpha, _drag]:
		arr.resize(cap)
	_kind.resize(cap)

func spawn(kind: int, pos: Vector3, size: float, life: float, color: Color, alpha := 1.0, vel := Vector3.ZERO, grow := 0.0, drag := 0.0) -> void:
	if count >= capacity:
		return
	var i := count
	count += 1
	_kind[i] = kind
	_pos[i] = pos
	_vel[i] = vel
	_size[i] = size
	_grow[i] = grow
	_life[i] = maxf(life, 0.001)
	_age[i] = 0.0
	_col[i] = color
	_alpha[i] = alpha
	_seed[i] = randf()
	_drag[i] = drag

func clear() -> void:
	count = 0
	multimesh.visible_instance_count = 0

func step(dt: float) -> void:
	var i := 0
	while i < count:
		_age[i] += dt
		if _age[i] >= _life[i]:
			_remove(i)
			continue
		_pos[i] += _vel[i] * dt
		if _drag[i] > 0.0:
			_vel[i] *= maxf(0.0, 1.0 - _drag[i] * dt)
		i += 1
	var mm := multimesh
	for k in count:
		var t := _age[k] / _life[k]
		var s := _size[k] * (1.0 + _grow[k] * t)
		mm.set_instance_transform(k, Transform3D(Basis.from_scale(Vector3(s, s, s)), _pos[k]))
		mm.set_instance_color(k, _col[k])
		mm.set_instance_custom_data(k, Color(float(_kind[k]), t, _seed[k], _alpha[k]))
	mm.visible_instance_count = count

func _remove(i: int) -> void:
	var j := count - 1
	_kind[i] = _kind[j]
	_pos[i] = _pos[j]
	_vel[i] = _vel[j]
	_size[i] = _size[j]
	_grow[i] = _grow[j]
	_life[i] = _life[j]
	_age[i] = _age[j]
	_col[i] = _col[j]
	_alpha[i] = _alpha[j]
	_seed[i] = _seed[j]
	_drag[i] = _drag[j]
	count = j
