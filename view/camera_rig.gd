class_name CameraRig
extends RefCounted

# 전술 카메라: 전장 좌표(px) ↔ 3D 장면 ↔ 화면 좌표 변환과 이동·확대. 규칙을 모른다.
# 전장 좌표는 코어 좌표와 같은 비율로 늘린다(제안서 §3.2).

const WORLD := Vector2(3400.0, 2300.0)
const S := 0.05
const PITCH := deg_to_rad(68.0)

var limit := WORLD   # 카메라가 보여 줄 수 있는 전장 범위(프로필 전장 크기). 3D 배경판은 WORLD 크기 그대로다
var camera: Camera3D
var cam_pos := Vector2(900.0, 1150.0)
var cam_z := 0.9
var vsize := Vector2(1600.0, 900.0)

func attach(host: Node3D, viewport_size: Vector2) -> void:
	vsize = viewport_size
	camera = Camera3D.new()
	camera.fov = 48.0
	camera.far = 600.0
	host.add_child(camera)
	camera.current = true
	update()

func w3(p: Vector2, y: float = 0.0) -> Vector3:
	return Vector3((p.x - WORLD.x * 0.5) * S, y, (p.y - WORLD.y * 0.5) * S)

func update() -> void:
	var d := vsize.y * S / (2.0 * tan(deg_to_rad(24.0)) * cam_z)
	var target := w3(cam_pos)
	camera.global_position = target + Vector3(0.0, sin(PITCH), cos(PITCH)) * d
	camera.look_at(target, Vector3.UP)

func w2s(p: Vector2) -> Vector2:
	return camera.unproject_position(w3(p))

func s2w(sp: Vector2) -> Vector2:
	var o := camera.project_ray_origin(sp)
	var n := camera.project_ray_normal(sp)
	if absf(n.y) < 0.0001:
		return cam_pos
	var t := -o.y / n.y
	var hit := o + n * t
	return Vector2(hit.x / S + WORLD.x * 0.5, hit.z / S + WORLD.y * 0.5)

func clamp_cam() -> void:
	cam_pos.x = clampf(cam_pos.x, 0.0, limit.x)
	cam_pos.y = clampf(cam_pos.y, 0.0, limit.y)
	cam_z = clampf(cam_z, 0.35, 2.8)
	if camera == null:
		return
	# 화면 네 모서리가 전장 안에 있게 한다. 전장이 화면보다 작으면 그 축은 가운데에 둔다(원근이라 몇 번 반복).
	var corners := [Vector2.ZERO, Vector2(vsize.x, 0.0), Vector2(0.0, vsize.y), vsize]
	for _i in 4:
		update()
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for c in corners:
			var w := s2w(c)
			lo = lo.min(w)
			hi = hi.max(w)
		var d := Vector2.ZERO
		for a in 2:
			if hi[a] - lo[a] > limit[a]:
				d[a] = limit[a] * 0.5 - (lo[a] + hi[a]) * 0.5
			elif lo[a] < 0.0:
				d[a] = -lo[a]
			elif hi[a] > limit[a]:
				d[a] = limit[a] - hi[a]
		if d.length() < 0.5:
			break
		cam_pos += d

func zoom(mp: Vector2, factor: float) -> void:
	var before := s2w(mp)
	cam_z *= factor
	clamp_cam()
	update()
	var after := s2w(mp)
	cam_pos += before - after
	clamp_cam()
