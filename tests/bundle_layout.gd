extends SceneTree

# PoC 반영 E: 묶음 진형(Q109). 함대 여럿에 진형을 주면 함대 위치도 진형 모양으로 재배치된다.
#  1. 각 함대가 서로 다른 슬롯으로 평행 이동(방향 유지), 묶음 중심 유지, 함대끼리 좌우 순서 유지(엇갈림 없음)
#  2. 같은 속도 상한(가장 느린 함대)
#  3. 전장 경계 밖으로 나가지 않는다
#  4. 함대 하나에 주는 진형은 위치를 바꾸지 않는다

func _initialize() -> void:
	call_deferred("_run")

var _ok := true
func _check(c: bool, m: String) -> void:
	if not c:
		_ok = false
		print("FAIL: ", m)

func _run() -> void:
	var F := SalvoFixture
	var gun := [["SHP-04", 6]]
	var s := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 600, 300, gun), F.def("B", 640, 500, gun), F.def("C", 580, 700, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 1400, 450, gun)], 3)
	s.st.ai_timer = 1 << 40
	var ids := []
	for i in [1, 2, 3]:
		ids.append(s.st.fleets[i].id)
		s.st.fleets[i].heading = 0.0
	var fids: Array = s.salvo.formation_ids()
	var cen0 := (s.st.fleets[1].pos + s.st.fleets[2].pos + s.st.fleets[3].pos) / 3.0
	var order0 := [s.st.fleets[1].pos.y, s.st.fleets[2].pos.y, s.st.fleets[3].pos.y]
	s.issue(BattleSim.command(0, ids, "formation", -1, Vector2.ZERO, {"id": str(fids[1])}))
	var tos := []
	var cen := Vector2.ZERO
	for i in [1, 2, 3]:
		var f: FleetState = s.st.fleets[i]
		_check(f.has_move and f.strafe, "함대 %d 평행 재배치 명령" % i)
		tos.append(f.move_to)
		cen += f.move_to
	cen /= 3.0
	_check(tos[0].distance_to(tos[1]) > 20.0 and tos[1].distance_to(tos[2]) > 20.0 and tos[0].distance_to(tos[2]) > 20.0, "서로 다른 슬롯 %s" % str(tos))
	_check(cen.distance_to(cen0) < 2.0, "묶음 중심 유지 %s -> %s" % [cen0, cen])
	_check(tos[0].y < tos[1].y and tos[1].y < tos[2].y, "좌우 순서 유지(엇갈림 없음)")
	_check(is_equal_approx(s.st.fleets[1].speed_cap, s.st.fleets[2].speed_cap) and s.st.fleets[1].speed_cap > 0.0, "같은 속도 상한")
	for t in tos:
		_check(t.x >= 0 and t.y >= 0 and t.x <= s.rs.world.x and t.y <= s.rs.world.y, "전장 안")
	# 4. 함대 하나
	var s2 := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 600, 300, gun)], [F.def("적기함", 1500, 100, gun, true)], 3)
	var a: FleetState = s2.st.fleets[1]
	s2.issue(BattleSim.command(0, [a.id], "formation", -1, Vector2.ZERO, {"id": str(s2.salvo.formation_ids()[1])}))
	_check(not a.has_move, "함대 하나는 위치 불변")
	print("BUNDLE_LAYOUT_PASS" if _ok else "BUNDLE_LAYOUT_FAIL")
	quit(0 if _ok else 1)
