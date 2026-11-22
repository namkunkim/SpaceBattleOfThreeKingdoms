class_name BattleCommands
extends RefCounted

# 입력 → 명령. 이 파일은 코어 상태를 바꾸지 않고 명령 사전만 만들어 호스트의 issue()에 넘긴다.
# 명령 사전: {kind, ids: [전대 ID], target_id, point}. 진영·틱은 호스트가 붙인다.
# 검증과 자원 차감은 코어가 한다. 거부되면 사유 코드 사건이 돌아와 토스트가 된다.

const HexRules := preload("res://core/battle/hex_battle_rules.gd")
const HEX_RADIUS := HexRules.RADIUS
const HEX_WIDTH := HexRules.WIDTH
const HEX_ROW_HEIGHT := HexRules.ROW_HEIGHT

var host: Node
var hex_destinations := false

func _init(h: Node) -> void:
	host = h

static func make(kind: String, ids: Array, target_id := -1, point := Vector2.ZERO, args := {}) -> Dictionary:
	var c := {"kind": kind, "ids": ids, "target_id": target_id, "point": point}
	if not args.is_empty():
		c["args"] = args
	return c

func _ids(s: Array) -> Array:
	var out := []
	for f in s:
		out.append(f.id)
	return out

func do_cmd(id: String) -> void:
	if host.G.state != "play":
		return
	if id == "all":
		host.selected.assign(host.alive(0))
		host.inspect = null
		host.refresh_panel()
		return
	var s: Array = host.my_sel()
	if s.is_empty():
		host.toast("먼저 아군 함대를 선택하세요")
		return
	host.issue(make(id, _ids(s)))
	host.refresh_panel()

# 장수 특기(P8c): 단일 선택 함대의 슬롯 번호. 대상은 코어 target_pick 기본값(-1). 거부는 사유 코드 토스트
func do_skill(slot: int) -> void:
	var s: Array = host.my_sel()
	if host.G.state != "play" or s.size() != 1:
		return
	host.issue(make("skill", [s[0].id], -1, Vector2.ZERO, {"slot": slot}))
	host.refresh_panel()

# 진형 변경. 대상 전대 ID 배열 ids를 받는다(선택·그룹 어느 쪽이든 이 함수 하나로 보낸다). 가능 여부·시간은 코어가 판정한다.
func formation_to(ids: Array, fid: String) -> void:
	if host.G.state != "play" or ids.is_empty():
		return
	host.issue(make("formation", ids, -1, Vector2.ZERO, {"id": fid}))
	host.refresh_panel()

# 현재 선택에 진형 변경(진형 탭)
func do_formation(fid: String) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		host.toast("먼저 아군 함대를 선택하세요")
		return
	formation_to(_ids(s), fid)

# P7 보급 메뉴: 보급함 함대 sup_id가 target_id(-1 = 해제)를 먼저 처리 / 자동 보급 중지(on)·재개(!on)
func supply_first(sup_id: int, target_id: int) -> void:
	if host.G.state != "play":
		return
	host.issue(make("supply_first", [sup_id], target_id))
	host.refresh_panel()

func supply_hold(sup_id: int, on: bool) -> void:
	if host.G.state != "play":
		return
	host.issue(make("supply_hold", [sup_id], -1, Vector2.ZERO, {"on": on}))
	host.refresh_panel()

# 선택 전체가 현재 배치를 유지한 채 목표 지점으로 이동
func order_move(w: Vector2, strafe := false, facing_deg = null) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		return
	var requested := w
	w = move_destination(w, s)
	if host.sim.hex_combat:
		var resolved: Variant = null if w == Vector2.INF else w
		host.trace.write(host, "hex_destination", {"ids": _ids(s), "requested": requested, "resolved": resolved})
	if w == Vector2.INF:
		host.toast("도달 가능한 이동 칸이 없습니다")
		return
	var args := {}
	if strafe:
		args.strafe = true
	if facing_deg != null:
		args.facing_deg = facing_deg
	host.issue(make("move", _ids(s), -1, w, args))
	# 로그(logcat): 요청 지점과 코어가 실제로 받은 목적지(전장 경계에서 잘림)
	var dest := []
	for f in s:
		dest.append("f%d pos=%s to=%s" % [f.id, f.pos.round(), f.move_to.round()])
	print("[ORDER] move w=", w.round(), " field=", host.field(), " args=", args, " ", dest)
	host.marker = {"pos": w, "t": 1.2, "foe": false}

# 목적지를 전장 안으로 당긴다. 코어는 함대마다 따로 경계에 자르므로 그대로 두면 경계 밖 지점에서 대형이 한 줄로 뭉친다.
# 대형 전체(중심 기준 간격)가 들어가게 중심만 옮겨 간격을 지킨다.
func move_destination(w: Vector2, s: Array) -> Vector2:
	var e: float = host.sim.R.edge
	var terrain: BattleTerrain = host.sim.terrain if host.sim.hex_combat and not host.placing else null
	var positions: Array[Vector2] = []
	var cen := Vector2.ZERO
	for f in s:
		var p: Vector2 = host.sim.st.by_id(f.id).pos if terrain else f.pos
		positions.append(p)
		cen += p
	cen /= positions.size()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in positions:
		lo = lo.min(p - cen)
		hi = hi.max(p - cen)
	var fld: Vector2 = host.field()
	var minimum := Vector2.ONE * e - lo
	var maximum := fld - Vector2.ONE * e - hi
	var fitted := w.clamp(minimum, maximum)
	if hex_destinations:
		if terrain:
			return _reachable_hex_center(w, minimum, maximum, terrain, positions, cen)
		return nearest_hex_center(w, minimum, maximum, fitted)
	return fitted

static func _reachable_hex_center(w: Vector2, minimum: Vector2, maximum: Vector2, terrain: BattleTerrain, positions: Array[Vector2], formation_center: Vector2) -> Vector2:
	var nearest := nearest_hex_center(w, minimum, maximum, Vector2.INF)
	if nearest == Vector2.INF or _can_reach_formation(nearest, terrain, positions, formation_center):
		return nearest
	var candidates: Array[Vector2] = []
	for row in range(ceili(minimum.y / HEX_ROW_HEIGHT), floori(maximum.y / HEX_ROW_HEIGHT) + 1):
		var offset := float(posmod(row, 2)) * 0.5
		var first := ceili(minimum.x / HEX_WIDTH - offset)
		var last := floori(maximum.x / HEX_WIDTH - offset)
		for column in range(first, last + 1):
			candidates.append(Vector2((column + offset) * HEX_WIDTH, row * HEX_ROW_HEIGHT))
	candidates.sort_custom(func(a: Vector2, b: Vector2) -> bool:
		var da := w.distance_squared_to(a)
		var db := w.distance_squared_to(b)
		if da != db:
			return da < db
		return a.y < b.y if a.y != b.y else a.x < b.x)
	for point in candidates:
		if point != nearest and _can_reach_formation(point, terrain, positions, formation_center):
			return point
	return Vector2.INF

static func _can_reach_formation(point: Vector2, terrain: BattleTerrain, positions: Array[Vector2], formation_center: Vector2) -> bool:
	for start in positions:
		var dest := BattleRules.quant_v(point + (start - formation_center))
		if not terrain.can_traverse(dest, dest) or terrain.next_waypoint(start, dest) == Vector2.INF:
			return false
	return true

# Pointy-top hexes. On each legal row, only its nearest legal column can win.
# A formation too wide for any center still uses the standard boundary fit.
static func nearest_hex_center(w: Vector2, minimum: Vector2, maximum: Vector2, fallback: Vector2) -> Vector2:
	var nearest := fallback
	var best_distance := INF
	for row in range(ceili(minimum.y / HEX_ROW_HEIGHT), floori(maximum.y / HEX_ROW_HEIGHT) + 1):
		var offset := float(posmod(row, 2)) * 0.5
		var first := ceili(minimum.x / HEX_WIDTH - offset)
		var last := floori(maximum.x / HEX_WIDTH - offset)
		if first > last:
			continue
		var column := clampi(roundi(w.x / HEX_WIDTH - offset), first, last)
		var center := Vector2((column + offset) * HEX_WIDTH, row * HEX_ROW_HEIGHT)
		var distance := w.distance_squared_to(center)
		if distance < best_distance:
			nearest = center
			best_distance = distance
	return nearest

# 선택 전체가 제자리에서 월드 각도(rad) 방향으로 돌아선다
func order_face(rad: float) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		return
	host.issue(make("face", _ids(s), -1, Vector2.ZERO, {"facing_deg": rad_to_deg(rad)}))
	print("[ORDER] face deg=", snappedf(rad_to_deg(rad), 0.1), " n=", s.size())

func order_attack(t) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		return
	host.issue(make("attack", _ids(s), t.id))
	host.marker = {"pos": t.pos, "t": 1.2, "foe": true}
