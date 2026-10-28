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
	# 함대 수와 무관하게 전체 진형이 만들어지며 슬롯을 중복하지 않는다.
	for kind in BattleRules.FORM_SHAPE:
		for n in [1, 2, 3, 4, 5, 7, 12, 29, 40]:
			var pts := BundleLayout.offsets(n, kind, 100.0)
			var center := Vector2.ZERO
			_check(pts.size() == n, "진형 %d / %d개 슬롯" % [kind, n])
			for i in n:
				center += pts[i]
				for j in i:
					_check(pts[i].distance_to(pts[j]) > 1.0, "진형 %d / %d개 슬롯 중복 없음" % [kind, n])
			_check(center.length() < 0.1, "슬롯 중심 유지")
	var arc := BundleLayout.offsets(3, 5, 100.0)
	_check(arc[0].x > arc[1].x and arc[2].x > arc[1].x and is_equal_approx(arc[0].x, arc[2].x), "3함대 학익: 양익이 중앙보다 전방")
	var ring := BundleLayout.offsets(4, 4, 100.0)
	for p in ring:
		_check(is_equal_approx(p.length(), ring[0].length()), "4함대 방원: 전체 원주 배치")
	var F := SalvoFixture
	var gun := [["SHP-04", 6]]
	var s := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 600, 300, gun), F.def("B", 640, 450, gun), F.def("C", 580, 600, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 1400, 450, gun)], 3)
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
	_check(tos[0].x > tos[1].x and tos[2].x > tos[1].x, "선택 3함대가 실제 학익 목표를 받음")
	_check(not s.st.fleets[0].has_move, "비선택 함대는 재배치하지 않음")
	# 실제 틱을 진행해 재배치가 완료되는지 확인한다. 사격은 이 기하 시험에서 끈다.
	for f in s.st.fleets:
		f.wait = 1 << 40
	for i in 2000:
		s.step()
		s.drain_events()
	for i in [1, 2, 3]:
		var f: FleetState = s.st.fleets[i]
		_check(not f.has_move and f.pos.distance_to(tos[i - 1]) <= s.R.arrive_r, "학익 재배치 도착 %d" % i)
	# 전장보다 큰 진형도 개별 경계 잘림으로 여러 함대가 한 점에 겹치지 않는다.
	var many := []
	for i in 40:
		var f := FleetState.new()
		f.id = i
		f.pos = Vector2(20, 20 + i)
		f.form.assign([Vector2(200, 0)])
		many.append(f)
	for kind in BattleRules.FORM_SHAPE:
		var slots := BundleLayout.slots(many, kind, 20.0, 10.0, Vector2(1600, 900))
		for i in 40:
			var p: Vector2 = slots[i]
			_check(p.x >= 10 and p.x <= 1590 and p.y >= 10 and p.y <= 890, "대규모 진형 경계 유지")
			for j in i:
				_check(p.distance_to(slots[j]) > 1.0, "대규모 진형 경계에서 슬롯 중복 없음")
	# 4. 함대 하나
	var s2 := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 600, 300, gun)], [F.def("적기함", 1500, 100, gun, true)], 3)
	var a: FleetState = s2.st.fleets[1]
	s2.issue(BattleSim.command(0, [a.id], "formation", -1, Vector2.ZERO, {"id": str(s2.salvo.formation_ids()[1])}))
	_check(not a.has_move, "함대 하나는 위치 불변")
	# 일부 함대가 팔진 조건을 충족하지 못하면 허용된 함대들만 공동 배치한다.
	var s3 := F.sim([F.def("본대", 300, 300, gun, true), F.def("A", 400, 450, gun), F.def("제외", 500, 600, gun)], [F.def("적", 1500, 100, gun, true)], 3)
	for i in [0, 1]:
		s3.st.fleets[i].cmd_stat = 95
		s3.st.fleets[i].traits = ["신기묘산"]
	var rejected: FleetState = s3.st.fleets[2]
	var reject_to := rejected.move_to
	s3.issue(BattleSim.command(0, [0, 1, 2], "formation", -1, Vector2.ZERO, {"id": "FRM-07"}))
	_check(s3.st.fleets[0].has_move and s3.st.fleets[1].has_move and s3.st.fleets[0].move_grp == s3.st.fleets[1].move_grp, "조건 충족 함대만 공동 배치")
	_check(not rejected.has_move and rejected.move_to == reject_to and rejected.form_to == "", "조건 미달 함대는 재배치에서 제외")
	print("BUNDLE_LAYOUT_PASS" if _ok else "BUNDLE_LAYOUT_FAIL")
	quit(0 if _ok else 1)
