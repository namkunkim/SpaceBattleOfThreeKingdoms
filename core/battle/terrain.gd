class_name BattleTerrain
extends RefCounted

# M6 지형 구역(제안서 §4.10). 사각형 구역 몇 개의 효과를 겹침 규칙으로 합친다.
# 수치는 combat.terrain(data/profiles/combat_m3.json)에서 온다. 구역은 ID 순으로 센다.
#   이동 비용: 겹치면 최댓값 · 센서(관측자 위치): 합을 [min, max]로 자름 · 은폐(표적 위치): 합
#   사거리: 사격선이 지나는 구역을 ID 순으로 차례로 곱함 · 사격각: 사격선이 지나는 구역의 합

var zones: Array = []

func _init(cfg: Dictionary) -> void:
	zones = cfg.get("zones", []).duplicate()
	zones.sort_custom(func(a, b): return str(a.id) < str(b.id))

func is_empty() -> bool:
	return zones.is_empty()

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
	var c := BattleRules.BP
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
