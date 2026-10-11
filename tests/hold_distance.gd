extends SceneTree

# Q68·R1 돌격함 없는 함대의 교전 거리 유지(P4). 유지 거리 = range_band_hold.engagement_distance(170).
#  1. 강습모함 없는 함대는 이동 명령으로 적 170 안에 못 들어간다(양쪽이 마주 가도, 멈춘 뒤 위치 진동 없음)
#  2. 돌격: 강습모함 없는 함대는 charge_none 거부, 보유 함대는 돌격으로 170 안(강습 거리)까지 붙는다
#  3. 그룹 이동: 한 함대가 유지 거리로 서면 그룹 전체가 함께 선다
#  4. 아군 함대끼리 겹침은 그대로 허용 / 5. 이미 안쪽이면 멀어지는 걸음은 허용
#  6. 화공 운용 함대(황개)의 접근 예외는 tests/stratagem_rules.gd가 흐름으로 확인한다

const HOLD := 170.0

func _initialize() -> void:
	call_deferred("_run")

func _mk(ally: Array, foe: Array) -> BattleSim:
	var s := SalvoFixture.sim(ally, foe, 3)
	s.rs.scenario["realtime_rules"] = {"range_band_hold": {"engagement_distance": HOLD}}
	s.assault = AssaultCore.new(s, SalvoFixture.combat().assault)   # 강습 규칙(시나리오 없는 시험 전장에는 기본으로 없다)
	s.endless = true
	return s

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
	print("HOLD_DISTANCE_PASS")
	quit(0)
