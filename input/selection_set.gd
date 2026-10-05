class_name SelectionSet
extends RefCounted

# 선택 집합과 그룹 번호 처리(순수 로직). 마우스·터치·전대 띠·그룹 버튼이 모두 여기를 거친다.
# 선택은 호스트 `selected`(전대 객체 배열), 그룹은 `groups`({번호: [전대 id]})에 둔다. 코어 상태가 아니다.
# 전대와 함대(기함 전대 포함)는 같은 전대 항목이라 혼합·여럿 모두 같은 집합이다. 그룹 진형·총사령(§8)도 이 집합을 읽는다.

const SLOTS := 5   # HUD 그룹 번호 버튼 수(키보드는 1~9)

static func toggle(sel: Array, f) -> void:
	if sel.has(f):
		sel.erase(f)
	else:
		sel.append(f)

static func add_all(sel: Array, fs: Array) -> void:
	for f in fs:
		if not sel.has(f):
			sel.append(f)

# 화면 사각형 안에 있는 전대(to_screen: 전장 좌표 → 화면 좌표)
static func in_rect(fleets: Array, r: Rect2, to_screen: Callable) -> Array:
	var out := []
	for f in fleets:
		if not f.dead and r.has_point(to_screen.call(f.pos)):
			out.append(f)
	return out

static func ids(sel: Array) -> Array:
	var out := []
	for f in sel:
		if not f.dead:
			out.append(f.id)
	return out

# 격침·퇴각으로 사라진 전대는 그룹에서 뺀다. 비면 번호를 비운다. lookup: id → 전대(없으면 null)
static func prune(groups: Dictionary, lookup: Callable) -> void:
	for n in groups.keys():
		var keep := []
		for id in groups[n]:
			var f = lookup.call(id)
			if f and not f.dead:
				keep.append(id)
		if keep.is_empty():
			groups.erase(n)
		else:
			groups[n] = keep

static func same(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for f in a:
		if not b.has(f):
			return false
	return true
