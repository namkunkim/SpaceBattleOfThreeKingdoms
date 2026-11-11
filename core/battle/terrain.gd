class_name BattleTerrain
extends RefCounted

# M6 지형 구역(제안서 §4.10). 사각형 구역 몇 개의 효과를 겹침 규칙으로 합친다.
# 수치는 combat.terrain(data/profiles/combat_m3.json)에서 온다. 구역은 ID 순으로 센다.
#   이동 비용: 겹치면 최댓값 · 센서(관측자 위치): 합을 [min, max]로 자름 · 은폐(표적 위치): 합
#   사거리: 사격선이 지나는 구역을 ID 순으로 차례로 곱함 · 사격각: 사격선이 지나는 구역의 합

var zones: Array = []
var _movement_field: Dictionary
var _extent: Vector2
var _blockers: Array[PackedVector2Array] = []
var _waypoints := PackedVector2Array()

func _init(cfg: Dictionary, extent := Vector2.ZERO) -> void:
	zones = cfg.get("zones", []).duplicate()
	zones.sort_custom(func(a, b): return str(a.id) < str(b.id))
	_movement_field = cfg.get("movement_field", {})
	_extent = extent
	var nav: Dictionary = _movement_field.get("navigation", {})
	for obstacle: Array in nav.get("blocked", []):
		var polygon := PackedVector2Array()
		for vertex: Array in obstacle:
			polygon.append(Vector2(float(vertex[0]), float(vertex[1])) * extent)
		if polygon.size() >= 3:
			_blockers.append(polygon)
	for anchor: Array in nav.get("waypoints", []):
		_waypoints.append(Vector2(float(anchor[0]), float(anchor[1])) * extent)

static func valid_movement_field(field: Dictionary) -> bool:
	var cols := int(field.get("columns", 0))
	var rows := int(field.get("rows", 0))
	var costs: Variant = field.get("move_cost_bp")
	return cols >= 2 and rows >= 2 and costs is Array and costs.size() == cols * rows \
		and costs.all(func(cost): return (cost is float or cost is int) and cost >= BattleRules.BP)

func _field_cost(p: Vector2) -> int:
	if _movement_field.is_empty() or _extent.x <= 0.0 or _extent.y <= 0.0:
		return BattleRules.BP
	var columns := int(_movement_field.columns)
	var rows := int(_movement_field.rows)
	var grid := (p / _extent).clamp(Vector2.ZERO, Vector2.ONE) * Vector2(columns - 1, rows - 1)
	var x := mini(int(grid.x), columns - 2)
	var y := mini(int(grid.y), rows - 2)
	var costs: Array = _movement_field.move_cost_bp
	var start := y * columns + x
	var upper := lerpf(float(costs[start]), float(costs[start + 1]), grid.x - x)
	var lower := lerpf(float(costs[start + columns]), float(costs[start + columns + 1]), grid.x - x)
	return roundi(lerpf(upper, lower, grid.y - y))

func can_traverse(from: Vector2, to: Vector2) -> bool:
	for polygon in _blockers:
		if Geometry2D.is_point_in_polygon(from, polygon) or Geometry2D.is_point_in_polygon(to, polygon):
			return false
		for i in polygon.size():
			var next := (i + 1) % polygon.size()
			if Geometry2D.segment_intersects_segment(from, to, polygon[i], polygon[next]) != null:
				return false
	return true

func next_waypoint(from: Vector2, to: Vector2) -> Vector2:
	if can_traverse(from, to):
		return to
	var nodes := PackedVector2Array([from, to])
	nodes.append_array(_waypoints)
	var count := nodes.size()
	var distance := PackedFloat64Array()
	distance.resize(count)
	distance.fill(INF)
	distance[0] = 0.0
	var previous := PackedInt32Array()
	previous.resize(count)
	previous.fill(-1)
	var visited := PackedByteArray()
	visited.resize(count)
	for step in count:
		var best := -1
		for i in count:
			if visited[i] == 0 and distance[i] < INF and (best == -1 or distance[i] < distance[best]):
				best = i
		if best == -1 or best == 1:
			break
		visited[best] = 1
		for i in range(1, count):
			var next_cost := distance[best] + nodes[best].distance_to(nodes[i])
			if visited[i] == 0 and next_cost < distance[i] and can_traverse(nodes[best], nodes[i]):
				distance[i] = next_cost
				previous[i] = best
	var index := 1
	while previous[index] > 0:
		index = previous[index]
	return nodes[index] if previous[index] == 0 else Vector2.INF

func is_empty() -> bool:
	return zones.is_empty() and _movement_field.is_empty()

static func _has(z: Dictionary, p: Vector2) -> bool:
	var r: Array = z.rect
	return p.x >= r[0] and p.x <= r[0] + r[2] and p.y >= r[1] and p.y <= r[1] + r[3]

# 선분 a→b가 구역 사각형과 만나는가(경계 포함, Liang–Barsky)
static func _hits(z: Dictionary, a: Vector2, b: Vector2) -> bool:
	var r: Array = z.rect
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [a.x - r[0], r[0] + r[2] - a.x, a.y - r[1], r[1] + r[3] - a.y]
	for i in 4:
		if p[i] == 0.0:
			if q[i] < 0.0:
				return false
		else:
			var t: float = q[i] / p[i]
			if p[i] < 0.0:
				t0 = maxf(t0, t)
			else:
				t1 = minf(t1, t)
	return t0 <= t1

func move_cost_bp(p: Vector2) -> int:
	var c := _field_cost(p)
	for z in zones:
		if _has(z, p):
			c = maxi(c, int(z.move_cost_bp))
	return c

func sensor_bp(p: Vector2, lo: int, hi: int) -> int:
	var s := 0
	for z in zones:
		if _has(z, p):
			s += int(z.sensor_bp)
	return clampi(s, lo, hi)

func conceal(p: Vector2) -> int:
	var c := 0
	for z in zones:
		if _has(z, p):
			c += int(z.conceal)
	return c

# 사격선 a→b의 사거리 배율
func range_mul(a: Vector2, b: Vector2) -> float:
	var m := 1.0
	for z in zones:
		if _hits(z, a, b):
			m *= float(z.range_bp) / float(BattleRules.BP)
	return m

# 사격선 a→b의 사격각 변화(도)
func arc_delta(a: Vector2, b: Vector2) -> float:
	var d := 0.0
	for z in zones:
		if _hits(z, a, b):
			d += float(z.arc_deg)
	return d
