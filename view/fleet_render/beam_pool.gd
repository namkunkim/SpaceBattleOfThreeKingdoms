class_name BeamPool
extends MultiMeshInstance3D

# 광선 풀. 광선마다 출발점·도착점을 매 프레임 갱신해 MultiMesh 하나로 그린다.

var capacity := 0
var _a := PackedVector3Array()
var _b := PackedVector3Array()
var _col := PackedColorArray()
var _head := PackedFloat32Array()
var _tail := PackedFloat32Array()
var _width := PackedFloat32Array()
var count := 0

func _init(cap: int) -> void:
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
	mat.shader = load("res://view/fleet_render/beam.gdshader")
	material_override = mat
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	custom_aabb = AABB(Vector3(-1e5, -1e5, -1e5), Vector3(2e5, 2e5, 2e5))
	_a.resize(cap)
	_b.resize(cap)
	_col.resize(cap)
	_head.resize(cap)
	_tail.resize(cap)
	_width.resize(cap)

func begin() -> void:
	count = 0

func add(a: Vector3, b: Vector3, head: float, tail: float, width: float, color: Color) -> void:
	if count >= capacity:
		return
	_a[count] = a
	_b[count] = b
	_head[count] = head
	_tail[count] = tail
	_width[count] = width
	_col[count] = color
	count += 1

func commit() -> void:
	var mm := multimesh
	for k in count:
		var ab := _b[k] - _a[k]
		mm.set_instance_transform(k, Transform3D(Basis(ab, Vector3.UP, Vector3.BACK), _a[k]))
		mm.set_instance_color(k, _col[k])
		mm.set_instance_custom_data(k, Color(_width[k], _head[k], _tail[k], _col[k].a))
	mm.visible_instance_count = count
