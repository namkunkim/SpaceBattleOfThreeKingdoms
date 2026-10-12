extends SceneTree

# Q72 레이저 회피(P5): 이동 중 표적의 방어항 1개. 전열·요격만, 미사일·함재기·뇌격 제외, 정지 0, 클램프, 수치는 data(combat.evasion).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var F := SalvoFixture
	var gun := [["SHP-04", 6]]
	var s := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 400, 450, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 600, 450, [["SHP-04", 6], ["SHP-01", 2]])], 3)
	var sal = s.salvo
	var a: FleetState = s.st.fleets[1]
	var z: FleetState = s.st.fleets[3]
	var ev: Dictionary = sal.C.evasion
	# --- 1. 데이터 ---
	if not TestCheck.ok(self, ev.categories == ["line_fire", "intercept"] and int(ev.max_bp) > 0 and int(ev.bp_per_speed) > 0, "combat.evasion 데이터"): return
	# --- 2. 정지 0 / 이동 중 > 0 ---
	z.moving = false
	var still := {}
	for cat in ["line_fire", "intercept", "artillery", "fighter", "torpedo"]:
		still[cat] = sal.hit_bp(a, z, cat)
	if not TestCheck.ok(self, sal.evasion_bp(z, "line_fire") == 0, "정지 중 회피 0"): return
	z.moving = true
	var e: int = sal.evasion_bp(z, "line_fire")
	if not TestCheck.ok(self, e > 0 and e <= int(ev.max_bp) and e == mini(int(ev.max_bp), int(z.speed * float(ev.bp_per_speed))), "이동 중 회피 = 속도 x bp_per_speed, 상한 이하: %d" % e): return
	if not TestCheck.ok(self, sal.hit_bp(a, z, "line_fire") == still.line_fire - e, "전열 명중률이 회피만큼 준다"): return
	# --- 3. 레이저 계열만 ---
	for cat in ["artillery", "fighter", "torpedo"]:
		if not TestCheck.ok(self, sal.evasion_bp(z, cat) == 0 and sal.hit_bp(a, z, cat) == still[cat], "%s에는 회피가 걸리지 않는다" % cat): return
	if not TestCheck.ok(self, sal.evasion_bp(z, "intercept") == e and sal.hit_bp(a, z, "intercept") == still.intercept - e, "요격도 회피 대상"): return
	# --- 4. 클램프(상한 큰 값도 최소 명중률 아래로 못 간다) / 속도 상한 / 수치는 data에서 ---
	z.speed = 1000.0
	if not TestCheck.ok(self, sal.evasion_bp(z, "line_fire") == int(ev.max_bp), "회피는 max_bp에서 막힌다"): return
	var big := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 400, 450, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 600, 450, gun)], 3, "", func(cb): cb.evasion.max_bp = 100000; cb.evasion.bp_per_speed = 100000)
	var bz: FleetState = big.st.fleets[3]
	bz.moving = true
	if not TestCheck.ok(self, big.salvo.evasion_bp(bz, "line_fire") > 20000 and big.salvo.hit_bp(big.st.fleets[1], bz, "line_fire") == int(big.salvo.C.hit.min_bp), "data 수치가 바뀌면 따라가고 명중률은 min_bp에서 막힌다"): return
	# --- 5. 실제 이동: moving 플래그 ---
	var m := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 400, 450, gun)], [F.def("적기함", 1500, 100, gun, true)], 3)
	var ma: FleetState = m.st.fleets[1]
	m.issue(BattleSim.command(0, [ma.id], "move", -1, Vector2(500, 450)))
	m.step()
	if not TestCheck.ok(self, ma.moving, "이동 명령 중 moving"): return
	for i in 1500:
		m.step()
		m.drain_events()
	if not TestCheck.ok(self, not ma.moving and not ma.has_move, "도착 뒤 moving 해제"): return
	# --- 6. 결정론: 같은 시드 같은 지문 ---
	var fp := []
	for i in 2:
		var d := F.sim([F.def("본대", 100, 800, gun, true), F.def("A", 400, 450, gun)], [F.def("적기함", 1500, 100, gun, true), F.def("Z", 700, 450, gun)], 7)
		d.issue(BattleSim.command(0, [d.st.fleets[1].id], "move", -1, Vector2(650, 460)))
		F.run(d, 60.0)
		fp.append(d.fingerprint())
	if not TestCheck.ok(self, fp[0] == fp[1], "같은 시드 재생 지문 동일"): return
	print("evasion OK")
	quit(0)
