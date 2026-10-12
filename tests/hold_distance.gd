extends SceneTree

# Q68·R1 돌격함 없는 함대의 교전 거리 유지(P4). 유지 거리 = range_band_hold.engagement_distance(170).
#  1. 강습모함 없는 함대는 이동 명령으로 적 170 안에 못 들어간다(양쪽이 마주 가도, 멈춘 뒤 위치 진동 없음)
#  2. 돌격: 강습모함 없는 함대는 charge_none 거부, 보유 함대는 돌격으로 170 안(강습 거리)까지 붙는다
#  3. 그룹 이동: 한 함대가 유지 거리로 서면 그룹 전체가 함께 선다
#  4. 아군 함대끼리 겹침은 그대로 허용 / 5. 이미 안쪽이면 멀어지는 걸음은 허용
#  6. 실제 시나리오(step): 후퇴 명령 함대는 정지하지 않음 / idle 화공 함대는 170에서 멈춤 / feign·open 창 안에서는 접근 허용

const HOLD := 170.0

func _initialize() -> void:
	call_deferred("_run")

func _mk(ally: Array, foe: Array) -> BattleSim:
	var s := SalvoFixture.sim(ally, foe, 3)
	s.rs.scenario["realtime_rules"] = {"range_band_hold": {"engagement_distance": HOLD}}
	s.assault = AssaultCore.new(s, SalvoFixture.combat().assault)   # 강습 규칙(시나리오 없는 시험 전장에는 기본으로 없다)
	s.endless = true
	return s

func _rc() -> BattleSim:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	var s := BattleSim.new(1, BattleRules.TICK_HZ, p)
	s.st.ai_timer = 1 << 40   # AI 끔
	s.endless = true
	for f in s.st.fleets:
		f.pos = Vector2(1500, 850) if f.side == 1 else Vector2(100, 850)   # 시험 함대 밖은 멀리
	return s

func _rf(s: BattleSim, sq: String) -> FleetState:
	for f in s.st.fleets:
		if f.sq_id == sq:
			return f
	return null

func _move(s: BattleSim, f: FleetState, p: Vector2) -> void:
	s.issue(BattleSim.command(f.side, [f.id], "move", -1, p))

func _rej(s: BattleSim) -> Array:
	var out := []
	for e in s.drain_events():
		if e.kind == "rejected":
			out.append(e.value)
	return out

func _run() -> void:
	var F := SalvoFixture
	var gun := [["SHP-04", 6]]
	# --- 1. 마주 가기: 둘 다 강습모함 없음 ---
	var s := _mk([F.def("본대", 100, 800, gun, true), F.def("A", 400, 450, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 900, 450, gun)])
	var a: FleetState = s.st.fleets[1]
	var z: FleetState = s.st.fleets[3]
	_move(s, a, Vector2(900, 450))
	s.issue(BattleSim.command(1, [z.id], "move", -1, Vector2(400, 450)))
	var dmin := 1e9
	var last := []
	for i in 900:
		s.step()
		s.drain_events()
		dmin = minf(dmin, a.pos.distance_to(z.pos))
		if i >= 800:
			last.append([a.pos, z.pos])
	if not TestCheck.ok(self, dmin >= HOLD - 0.01 and dmin < HOLD + 60.0, "마주 가도 유지 거리에서 선다: 최소 %.1f" % dmin): return
	var still := true
	for p in last:
		still = still and p[0] == last[0][0] and p[1] == last[0][1]
	if not TestCheck.ok(self, still, "멈춘 뒤 위치 진동 없음"): return

	# --- 2. 돌격 ---
	var c := _mk([F.def("본대", 100, 800, gun, true), F.def("무모함", 400, 450, gun), F.def("모함", 410, 380, [["SHP-04", 4], ["SHP-01", 2]])], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 600, 380, [["SHP-04", 1]])])
	var plain: FleetState = c.st.fleets[1]
	var carr: FleetState = c.st.fleets[2]
	c.issue(BattleSim.command(0, [plain.id], "charge"))
	if not TestCheck.ok(self, _rej(c) == ["charge_none"], "강습모함 없는 함대의 돌격은 charge_none"): return
	if not TestCheck.ok(self, plain.charge == 0 and c.salvo.hold_distance(plain) and not c.salvo.hold_distance(carr), "hold_distance: 강습모함 유무"): return
	c.issue(BattleSim.command(0, [carr.id], "attack", c.st.fleets[4].id))
	c.issue(BattleSim.command(0, [carr.id], "charge"))
	if not TestCheck.ok(self, _rej(c).is_empty() and carr.charge > 0, "강습모함 보유 함대는 돌격 가능"): return
	var zc: FleetState = c.st.fleets[4]
	var dc := 1e9
	for i in 200:
		c.step()
		c.drain_events()
		dc = minf(dc, carr.pos.distance_to(zc.pos))
	if not TestCheck.ok(self, dc < HOLD - 10.0, "돌격 함대는 유지 거리 안까지 붙는다: %.1f" % dc): return

	# --- 3. 그룹 동반 정지 / 4. 아군 겹침 ---
	var g := _mk([F.def("본대", 100, 800, gun, true), F.def("A1", 400, 400, gun), F.def("A2", 400, 500, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 600, 400, gun)])
	var a1: FleetState = g.st.fleets[1]
	var a2: FleetState = g.st.fleets[2]
	var zg: FleetState = g.st.fleets[4]
	g.issue(BattleSim.command(0, [a1.id, a2.id], "move", -1, Vector2(900, 450)))
	for i in 300:
		g.step()
		g.drain_events()
	if not TestCheck.ok(self, not a1.has_move and not a2.has_move and a1.pos.distance_to(zg.pos) >= HOLD - 0.01, "그룹: 한 함대가 서면 함께 선다"): return
	if not TestCheck.ok(self, a2.pos.x < 600.0 and absf(a1.pos.x - a2.pos.x) < 30.0 and a2.pos.distance_to(zg.pos) > HOLD, "그룹: 나머지는 유지 거리 밖에서 같이 멈춤 %s %s" % [a1.pos, a2.pos]): return
	var o := _mk([F.def("본대", 100, 800, gun, true), F.def("B1", 400, 405, gun), F.def("B2", 400, 415, gun)], [F.def("적기함", 1500, 100, gun, true)])
	_move(o, o.st.fleets[1], Vector2(460, 410))
	_move(o, o.st.fleets[2], Vector2(460, 410))
	for i in 300:
		o.step()
		o.drain_events()
	if not TestCheck.ok(self, o.st.fleets[1].pos.distance_to(o.st.fleets[2].pos) <= 10.0, "아군 함대끼리는 겹칠 수 있다"): return

	# --- 5. 안쪽에서 멀어지는 걸음은 허용 ---
	var w := _mk([F.def("본대", 100, 800, gun, true), F.def("W", 500, 450, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 600, 450, gun)])
	var wf: FleetState = w.st.fleets[1]
	_move(w, wf, Vector2(100, 450))
	for i in 400:
		w.step()
		w.drain_events()
	if not TestCheck.ok(self, wf.pos.x < 480.0, "유지 거리 안에서 물러나는 이동은 막히지 않는다: %.1f" % wf.pos.x): return
	# --- 6. 실제 시나리오 ---
	# (a) 후퇴 명령: 탈출 방향에 적이 있어도 이동 명령이 지워지지 않고 계속 간다
	var r := _rc()
	var rf := _rf(r, "RC-LIU-SQ-02")
	var ex: Vector2 = r.morale.exit_point(0)
	var dir: Vector2 = (ex - rf.pos).normalized()
	var foe := _rf(r, "RC-CAO-SQ-03")
	rf.pos = ex - dir * 300.0
	foe.pos = rf.pos + dir * 100.0
	var d0 := rf.pos.distance_to(ex)
	r.issue(BattleSim.command(0, [rf.id], "retreat"))
	for i in 300:
		r.step()
		r.drain_events()
	if not TestCheck.ok(self, rf.has_move and rf.pos.distance_to(ex) < d0 - 20.0, "후퇴 중에는 적이 탈출 방향에 있어도 정지하지 않는다: %.1f -> %.1f" % [d0, rf.pos.distance_to(ex)]): return
	# (b)(c) 화공 함대: idle은 170에서 멈추고, feign과 열린 창(open)은 접근한다
	for mode in ["idle", "feign", "open"]:
		var q := _rc()
		var h := _rf(q, "RC-SUN-SQ-03")
		var zq := _rf(q, "RC-CAO-SQ-03")
		h.pos = Vector2(300, 300)
		zq.pos = Vector2(500, 300)
		h.equip = ""   # 뇌격 운용 함대는 M3로 따로 면제라 화공 예외만 보도록 장비를 뗀다
		q.chain.mode = mode
		if mode == "open":
			q.chain.win_start = 0
			q.chain.win_end = 1 << 30
		q.issue(BattleSim.command(0, [h.id], "move", -1, zq.pos))
		var dm := 1e9
		for i in 600:
			q.step()
			q.drain_events()
			dm = minf(dm, h.pos.distance_to(zq.pos))
		var want_in: bool = mode != "idle"
		if not TestCheck.ok(self, (dm < HOLD - 10.0) == want_in, "화공 함대 %s: 최소 거리 %.1f" % [mode, dm]): return
	# M1 미탐지 적에는 멈추지 않는다 / M2 정지 토스트(쿨다운) / M3 뇌격 운용 함대는 면제
	for case in ["seen", "torpedo"]:
		var u := _rc()
		var uf := _rf(u, "RC-LIU-SQ-02")
		var uz := _rf(u, "RC-CAO-SQ-03")
		uf.pos = Vector2(300, 300)
		uz.pos = Vector2(500, 300)
		if case == "torpedo":
			uf.equip = "FAST-EQ-TORPEDO"
		u.issue(BattleSim.command(0, [uf.id], "move", -1, uz.pos))
		var du := 1e9
		var toasts := 0
		for i in 700:
			u.step()
			for e in u.drain_events():
				if e.kind == "rejected" and e.value == "hold_distance":
					toasts += 1
			du = minf(du, uf.pos.distance_to(uz.pos))
		match case:
			"seen":
				if not TestCheck.ok(self, du >= HOLD - 0.01 and toasts == 1, "접촉 있는 적: 170에서 멈추고 토스트 1회: %.1f, %d회" % [du, toasts]): return
			"torpedo":
				if not TestCheck.ok(self, du < HOLD - 10.0 and toasts == 0, "뇌격 운용 함대는 유지 거리 면제: %.1f" % du): return
	# M1: 같은 걸음이라도 접촉 기록에 없는 적은 막지 않는다
	var m1 := _rc()
	var mf := _rf(m1, "RC-LIU-SQ-02")
	var mz := _rf(m1, "RC-CAO-SQ-03")
	mf.pos = Vector2(300, 300)
	mz.pos = Vector2(450, 300)
	for i in 30:
		m1.step()
		m1.drain_events()
	var seen_blk: Vector2 = m1._hold_blocker(mf, Vector2(250, 300))
	m1.detect.contacts[0].erase(mz.id)
	var unseen_blk: Vector2 = m1._hold_blocker(mf, Vector2(250, 300))
	if not TestCheck.ok(self, seen_blk != Vector2.INF and unseen_blk == Vector2.INF, "접촉 기록 있을 때만 유지 거리 정지 판정: %s %s" % [seen_blk, unseen_blk]): return
	print("HOLD_DISTANCE_PASS")
	quit(0)
