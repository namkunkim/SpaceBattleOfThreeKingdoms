class_name BattleCommands
extends RefCounted

# 입력 → 명령. 이 파일은 코어 상태를 바꾸지 않고 명령 사전만 만들어 호스트의 issue()에 넘긴다.
# 명령 사전: {kind, ids: [전대 ID], target_id, point}. 진영·틱은 호스트가 붙인다.
# 검증과 자원 차감은 코어가 한다. 거부되면 사유 코드 사건이 돌아와 토스트가 된다.

var host: Node

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

# 선택 전체가 현재 배치를 유지한 채 목표 지점으로 이동
func order_move(w: Vector2, strafe := false, facing_deg = null) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		return
	w = _fit_to_field(w, s)
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
func _fit_to_field(w: Vector2, s: Array) -> Vector2:
	var e: float = host.sim.R.edge
	var cen := Vector2.ZERO
	for f in s:
		cen += f.pos
	cen /= s.size()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for f in s:
		lo = lo.min(f.pos - cen)
		hi = hi.max(f.pos - cen)
	var fld: Vector2 = host.field()
	return Vector2(clampf(w.x, e - lo.x, fld.x - e - hi.x), clampf(w.y, e - lo.y, fld.y - e - hi.y))

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
