class_name BundleLayout
extends RefCounted

# 묶음 진형(PoC E, Q109): 함대 여럿에 같은 진형을 주면 함대들의 위치도 그 진형 모양으로 재배치한다.
# 슬롯 = 진형 모양(BattleRules.formation_offsets)의 앞 n개 점. 간격은 구성 함대 크기 + gap. 묶음 중심·방향은 그대로.
# 함대끼리 엇갈리지 않게 좌우(방향의 수직) 순서대로 슬롯에 배정한다. 전장 밖이면 중심을 안쪽으로 옮기고, 그래도 넘으면 경계로 자른다.
# ponytail: 전장보다 긴 줄을 여러 줄로 접는 것은 진형 모양 자체(횡진 2열 등)에 맡긴다. 10개 이상 함대의 접기는 필요해지면 추가.

# fleets: 대상 함대 배열, kind: 배치도 번호, 반환: {함대 id: 목표 위치}
static func slots(fleets: Array, kind: int, gap: float, edge: float, world: Vector2) -> Dictionary:
	var n := fleets.size()
	var out := {}
	if n == 0:
		return out
	var cen := Vector2.ZERO
	var ext := 0.0
	for f in fleets:
		cen += f.pos
		for p in f.form:
			ext = maxf(ext, p.length())
	cen /= n
	var h: float = fleets[0].heading
	var step := 2.0 * ext + gap
	var pts := BattleRules.formation_offsets(kind, step)
	var sel: Array[Vector2] = []
	for i in n:
		sel.append(pts[i % pts.size()])
	var c := Vector2.ZERO
	for p in sel:
		c += p
	c /= n
	var abs_pts: Array[Vector2] = []
	for p in sel:
		abs_pts.append(cen + (p - c).rotated(h))
	# 전장 안으로 중심 이동
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in abs_pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var sh := Vector2.ZERO
	if lo.x < edge:
		sh.x = edge - lo.x
	elif hi.x > world.x - edge:
		sh.x = world.x - edge - hi.x
	if lo.y < edge:
		sh.y = edge - lo.y
	elif hi.y > world.y - edge:
		sh.y = world.y - edge - hi.y
	var side := Vector2(-sin(h), cos(h))
	var fs := fleets.duplicate()
	fs.sort_custom(func(a, b): return (a.pos - cen).dot(side) < (b.pos - cen).dot(side))
	var ps := abs_pts.duplicate()
	ps.sort_custom(func(a, b): return (a - cen).dot(side) < (b - cen).dot(side))
	for i in n:
		var q: Vector2 = ps[i] + sh
		out[fs[i].id] = BattleRules.quant_v(Vector2(clampf(q.x, edge, world.x - edge), clampf(q.y, edge, world.y - edge)))
	return out
