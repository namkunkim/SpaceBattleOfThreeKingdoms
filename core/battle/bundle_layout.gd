class_name BundleLayout
extends RefCounted

# 묶음 진형(PoC E, Q109): 함대 여럿에 같은 진형을 주면 함대들의 위치도 그 진형 모양으로 재배치한다.
# 슬롯은 선택 함대 수에 맞춰 진형 전체를 만든다. 간격은 구성 함대 크기 + gap. 묶음 중심·방향은 그대로.
# 함대끼리 엇갈리지 않게 좌우(방향의 수직) 순서대로 슬롯에 배정한다. 전장에 맞게 전체 크기와 중심을 조정한다.

# 함선 28척 배치의 앞부분을 자르면 학익은 한쪽 날개, 방원은 불완전한 원이 된다.
# 함대 수에 맞는 슬롯을 생성하고 중심을 맞춘다. 28개를 넘어도 슬롯을 재사용하지 않는다.
# 배치도 기하 정본. 전투 규칙 계수와 분리하며 파일 I/O는 ProfileLoader만 담당한다.
const LAYOUT_PATH := "res://data/bundle-layout.json"
static var _layout: Dictionary = {}
static var _layout_loaded := false
static var _layout_valid := false

static func _valid_layout(data: Dictionary) -> bool:
	if data.size() != BattleRules.FORM_COUNT:
		return false
	for kind in BattleRules.FORM_COUNT:
		var entry: Variant = data.get(str(kind))
		if not entry is Dictionary or entry.size() != 5:
			return false
		if not entry.get("pattern") is String or entry.pattern not in ["wedge", "ring", "arc", "grid"]:
			return false
		if not entry.get("columns_mode") is String or entry.columns_mode not in ["auto", "half", "pair"]:
			return false
		for field in ["forward_scale", "shear", "stagger"]:
			var value: Variant = entry.get(field)
			if not value is float or not is_finite(value):
				return false
	return true

static func _load_layout() -> bool:
	if not _layout_loaded:
		_layout = ProfileLoader.read_json(LAYOUT_PATH)
		_layout_valid = _valid_layout(_layout)
		_layout_loaded = true
		if not _layout_valid:
			push_error("묶음 진형 기하 데이터가 없거나 잘못되었다: " + LAYOUT_PATH)
	return _layout_valid

static func offsets(n: int, kind: int, step: float) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	if not _load_layout():
		return pts
	# 알려진 배치도 누락은 로더가 거부한다. 범위 밖 kind만 기존 기본 방진으로 처리한다.
	var shape: Dictionary = _layout[str(kind)] if kind >= 0 and kind < BattleRules.FORM_COUNT else {"pattern": "grid", "columns_mode": "auto", "forward_scale": 0.0, "shear": 0.0, "stagger": 0.0}
	for i in n:
		var p := Vector2.ZERO
		match shape.pattern:
			"wedge": # 봉시·안행: 양익을 대칭으로 배치
				var side := float(i) - float(n - 1) * 0.5
				p = Vector2(absf(side) * float(shape.forward_scale), side)
			"ring": # 방원: 선택 수 전체로 원을 완성
				var radius := 1.0 / (2.0 * sin(PI / n)) if n > 1 else 0.0
				p = Vector2.from_angle(TAU * i / maxi(1, n)) * radius
			"arc": # 학익: 양끝이 앞으로 굽은 양익
				var side := float(i) - float(n - 1) * 0.5
				var span := maxf(1.0, float(n - 1) * 0.5)
				p = Vector2(side * side / span * float(shape.forward_scale), side)
			_:
				var cols := ceili(sqrt(float(n)))
				if shape.columns_mode == "half":
					cols = ceili(float(n) / 2.0)
				elif shape.columns_mode == "pair":
					cols = mini(n, 2)
				var row := i / cols
				var row_size := mini(cols, n - row * cols)
				p = Vector2(-row, float(i % cols) - float(row_size - 1) * 0.5)
				if float(shape.shear) != 0.0:
					p.x -= p.y * float(shape.shear)
				elif float(shape.stagger) != 0.0:
					p.y += float(shape.stagger) if row % 2 else -float(shape.stagger)
		pts.append(p * step)
	var center := Vector2.ZERO
	for p in pts:
		center += p
	center /= maxi(1, n)
	for i in pts.size():
		pts[i] -= center
	return pts

# 좌우가 같으면(종대) 앞뒤 순서로 가른다
static func _less(la: float, lb: float, aa: float, ab: float) -> bool:
	return la < lb if absf(la - lb) > 1.0 else aa < ab

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
		for p in f.form_t:
			ext = maxf(ext, p.length())
	cen /= n
	var h: float = fleets[0].heading + (PI if fleets[0].flip else 0.0)   # 반전한 함대는 배치의 앞이 뒤를 향한다
	var step := 2.0 * ext + gap
	var sel := offsets(n, kind, step)
	var abs_pts: Array[Vector2] = []
	for p in sel:
		abs_pts.append(cen + p.rotated(h))
	# 전장 안으로 중심 이동
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in abs_pts:
		lo = lo.min(p)
		hi = hi.max(p)
	# 전장보다 크면 전체를 같은 비율로 줄인다. 개별 좌표를 자르면 슬롯이 겹친다.
	var span := hi - lo
	var scale := minf(1.0, minf((world.x - 2.0 * edge) / maxf(span.x, 0.001), (world.y - 2.0 * edge) / maxf(span.y, 0.001)))
	if scale < 1.0:
		for i in abs_pts.size():
			abs_pts[i] = cen + (abs_pts[i] - cen) * scale
		lo = cen + (lo - cen) * scale
		hi = cen + (hi - cen) * scale
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
	var fwd := Vector2.from_angle(h)
	fs.sort_custom(func(a, b): return _less((a.pos - cen).dot(side), (b.pos - cen).dot(side), (a.pos - cen).dot(fwd), (b.pos - cen).dot(fwd)))
	var ps := abs_pts.duplicate()
	ps.sort_custom(func(a, b): return _less((a - cen).dot(side), (b - cen).dot(side), (a - cen).dot(fwd), (b - cen).dot(fwd)))
	for i in n:
		var q: Vector2 = ps[i] + sh
		out[fs[i].id] = BattleRules.quant_v(Vector2(clampf(q.x, edge, world.x - edge), clampf(q.y, edge, world.y - edge)))
	return out
