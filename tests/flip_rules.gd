extends SceneTree

# PoC 반영 B: 제자리 반전 + 접적 평행 이동 + 도착 후 진형 정렬(코어 이동 규칙).
#  1. 접적 아님: 목적지가 뒤쪽(90° 초과)이면 선회 대신 제자리 반전한다(함선 위치 유지, 반전 동안 멈춤, 도착함)
#  2. 접적: 이동 중 진형 방향 그대로, 적 쪽 ±45°는 전진 속도, 옆은 평행 속도(60%)
#  3. 접적 도착 후 적이 뒤쪽이면 제자리 반전으로 적 쪽을 향한다
#  4. 같은 입력은 같은 지문(결정론)

func _initialize() -> void:
	call_deferred("_run")

var _ok := true
func _check(c: bool, m: String) -> void:
	if not c:
		_ok = false
		print("FAIL: ", m)

func _mk(foe_x: float) -> BattleSim:
	var F := SalvoFixture
	var gun := [["SHP-04", 6]]
	var s := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 900, 450, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", foe_x, 450, gun)], 3)
	s.st.ai_timer = 1 << 40
	s.endless = true
	return s

func _run1(foe_x: float, dest: Vector2, n: int) -> Array:
	var s := _mk(foe_x)
	var a: FleetState = s.st.fleets[1]
	a.heading = 0.0
	var p0 := BattleRules.ship_pos(a.pos, a.heading, a.form, 3)
	s.issue(BattleSim.command(0, [a.id], "move", -1, dest))
	var out := {"p0": p0, "flipped": false, "moved_in_flip": false, "min_dh": 9.0}
	var last_pos := a.pos
	for i in n:
		s.step()
		if a.flip_wait > 0:
			out.flipped = true
			if a.pos.distance_to(last_pos) > 0.01:
				out.moved_in_flip = true
		last_pos = a.pos
		out.min_dh = minf(out.min_dh, absf(BattleRules.ang_diff(a.heading, 0.0)))
	return [s, a, out]

func _run() -> void:
	# 1. 접적 아님(적 2000 이상 멀리): 뒤쪽 목적지 -> 제자리 반전
	var r := _run1(5000.0, Vector2(840, 450), 600)
	var a: FleetState = r[1]
	var o: Dictionary = r[2]
	_check(o.flipped, "뒤쪽 이동은 제자리 반전")
	_check(a.flip, "반전 상태 표시")
	_check(not o.moved_in_flip, "반전 동안 멈춤")
	_check(absf(BattleRules.ang_diff(a.heading, PI)) < 0.05, "방향 180° 반전 %.2f" % a.heading)
	_check(a.pos.distance_to(Vector2(840, 450)) < 15.0, "반전 뒤 목적지 도착 %s" % a.pos)
	# 반전 직후 함선 위치 유지
	var s2 := _mk(5000.0)
	var b: FleetState = s2.st.fleets[1]
	b.heading = 0.0
	var before := BattleRules.ship_pos(b.pos, b.heading, b.form, 3)
	s2.issue(BattleSim.command(0, [b.id], "move", -1, Vector2(840, 450)))
	var pos_ok := false
	for i in 20:
		s2.step()
		if b.flip:
			pos_ok = BattleRules.ship_pos(b.pos, b.heading, b.form, 3).distance_to(before) < 0.5
			break
	_check(pos_ok, "반전해도 함선 세계 위치 그대로")
	# 2. 접적: 적이 앞(x=1100)에 있고 옆(위)으로 이동 -> 방향 유지, 속도 60%
	var s := _mk(1100.0)
	var c: FleetState = s.st.fleets[1]
	c.heading = 0.0
	s.issue(BattleSim.command(0, [c.id], "move", -1, Vector2(900, 250)))
	var p0 := c.pos
	for i in 20:
		s.step()
	var side_speed := c.pos.distance_to(p0) / (20.0 / BattleRules.TICK_HZ)
	_check(absf(c.heading) < 1e-6, "접적 이동 중 진형 방향 유지")
	var s3 := _mk(1100.0)
	var d: FleetState = s3.st.fleets[1]
	d.heading = 0.0
	s3.issue(BattleSim.command(0, [d.id], "move", -1, Vector2(1000, 450)))
	var q0 := d.pos
	for i in 20:
		s3.step()
	var fwd_speed := d.pos.distance_to(q0) / (20.0 / BattleRules.TICK_HZ)
	_check(absf(side_speed / fwd_speed - 0.6) < 0.05, "옆 이동 속도 60%% (%.2f)" % (side_speed / maxf(fwd_speed, 0.001)))
	# 3. 적이 뒤쪽(x=500)에 있는 접적 도착: 제자리 반전으로 적 쪽
	var s4 := _mk(500.0)
	var e: FleetState = s4.st.fleets[1]
	e.heading = 0.0
	s4.issue(BattleSim.command(0, [e.id], "move", -1, Vector2(900, 400)))
	for i in 600:
		s4.step()
	_check(e.flip and absf(BattleRules.ang_diff(e.heading, PI)) < 0.6, "도착 뒤 적 쪽으로 정렬(반전) %.2f" % e.heading)
	# 4. 결정론
	var f1 := BattleFingerprint.of(s4.st, null, "")
	var s5 := _mk(500.0)
	var g: FleetState = s5.st.fleets[1]
	g.heading = 0.0
	s5.issue(BattleSim.command(0, [g.id], "move", -1, Vector2(900, 400)))
	for i in 600:
		s5.step()
	_check(BattleFingerprint.of(s5.st, null, "") == f1, "결정론")
	print("FLIP_RULES_PASS" if _ok else "FLIP_RULES_FAIL")
	quit(0 if _ok else 1)
