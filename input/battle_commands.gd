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
func order_move(w: Vector2) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		return
	host.issue(make("move", _ids(s), -1, w))
	host.marker = {"pos": w, "t": 1.2, "foe": false}

func order_attack(t) -> void:
	var s: Array = host.my_sel()
	if s.is_empty():
		return
	host.issue(make("attack", _ids(s), t.id))
	host.marker = {"pos": t.pos, "t": 1.2, "foe": true}
