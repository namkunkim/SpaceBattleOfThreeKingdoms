extends SceneTree

# M1 코어 단위 테스트(§9.2 1~3): 규칙 값, 결정론, 재생, 누산기, 명령 검증. 헤드리스, 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _fp_at(sim: BattleSim, tick: int) -> String:
	while sim.st.tick < tick and not sim.st.over:
		sim.step()
		sim.drain_events()
	return sim.fingerprint()

func _run() -> void:
	var rs := RuleSet.from_dict(PocSetup.profile().rules)
	# --- 방향(정면 <60°, 측면 <120°, 후면) ---
	var tp := Vector2(1000, 1000)
	if not TestCheck.ok(self, is_equal_approx(rs.flank_mul(tp + Vector2(100, 0), tp, 0.0), 1.0), "front"): return
	if not TestCheck.ok(self, is_equal_approx(rs.flank_mul(tp + Vector2(0, 100), tp, 0.0), 1.3), "flank"): return
	if not TestCheck.ok(self, is_equal_approx(rs.flank_mul(tp + Vector2(-100, 0), tp, 0.0), 1.6), "rear"): return
	# --- 화력식 ---
	if not TestCheck.ok(self, is_equal_approx(rs.power(1, false, true, false), 1.0), "power base"): return
	if not TestCheck.ok(self, is_equal_approx(rs.power(12, true, false, true), (1.0 + 0.07 * 11) * 1.35 * 0.75 * 0.7), "power all"): return
	# --- 틱 수 변환 ---
	if not TestCheck.ok(self, BattleRules.ticks(18.0, 10) == 180 and BattleRules.ticks(18.0, 20) == 360, "ticks"): return
	# --- 난수: 같은 키는 같은 값, 다른 키는 다름, 범위 ---
	var r1 := BattleRng.new("p|1")
	var r2 := BattleRng.new("p|1")
	if not TestCheck.ok(self, r1.u32(5, 7, 2) == r2.u32(5, 7, 2), "rng same"): return
	if not TestCheck.ok(self, r1.u32(5, 7, 2) != r1.u32(5, 8, 2) or r1.u32(5, 7, 2) != r1.u32(6, 7, 2), "rng differs"): return
	var mn := 1.0
	var mx := 0.0
	for i in 500:
		var u := r1.unit(i, 1)
		mn = minf(mn, u)
		mx = maxf(mx, u)
		if not TestCheck.ok(self, r1.bp(i, 1) >= 0 and r1.bp(i, 1) < 10000, "bp range"): return
	if not TestCheck.ok(self, mn >= 0.0 and mx < 1.0 and mx - mn > 0.9, "unit range %f %f" % [mn, mx]): return
	# --- 초기 편성 ---
	var sim := BattleSim.new(1)
	if not TestCheck.ok(self, sim.st.fleets.size() == 13 and sim.st.alive(0).size() == 6 and sim.st.alive(1).size() == 7, "fleets"): return
	if not TestCheck.ok(self, sim.st.flag(0) != null and sim.st.flag(1) != null, "flags"): return
	# --- CP: 3점 시작, 4.5초에 1점(45틱) ---
	if not TestCheck.ok(self, sim.st.cp == 30000, "cp start"): return
	for i in 45:
		sim.step()
	if not TestCheck.ok(self, sim.st.cp == 40000, "cp +1 in 4.5s: %d" % sim.st.cp): return
	# --- 명령 검증: 돌격은 CP 3 필요, 부족하면 거부 사건 ---
	var s2 := BattleSim.new(1)
	var ids := []
	for f in s2.st.alive(0):
		ids.append(f.id)
	s2.st.cp = 20000
	s2.queue(BattleSim.command(0, ids, "charge"))
	s2.step()
	var ev := s2.drain_events()
	var rej := false
	for e in ev:
		if e.kind == "rejected" and e.value == "cp_charge":
			rej = true
	if not TestCheck.ok(self, rej and s2.st.alive(0)[0].charge == 0, "charge rejected on low cp"): return
	s2.st.cp = 30000
	s2.queue(BattleSim.command(0, ids, "charge"))
	s2.step()
	if not TestCheck.ok(self, s2.st.cp <= 10000 + 100 and s2.st.alive(0)[0].charge > 0, "charge accepted cp=%d" % s2.st.cp): return
	# 쿨다운: 미사일 18초, 사정거리 안에 적이 없으면 거부
	var s3 := BattleSim.new(1)
	s3.st.cp = 100000
	s3.queue(BattleSim.command(0, [s3.st.fleets[0].id], "missile"))
	s3.step()
	var no_t := false
	for e in s3.drain_events():
		if e.kind == "rejected" and e.value == "missile_no_target":
			no_t = true
	if not TestCheck.ok(self, no_t and s3.st.cp == 100000, "missile no target"): return
	# 소유 검사: 상대 진영 전대에 명령하면 선택 없음으로 거부
	s3.queue(BattleSim.command(0, [s3.st.alive(1)[0].id], "stop"))
	s3.step()
	var own := false
	for e in s3.drain_events():
		if e.kind == "rejected" and e.value == "no_selection":
			own = true
	if not TestCheck.ok(self, own, "foreign fleet command rejected"): return
	# --- 증원: 95초 넘긴 첫 걸음(951틱 이내) ---
	var s4 := BattleSim.new(2)
	_fp_at(s4, 940)
	if not TestCheck.ok(self, not s4.st.reinf and s4.st.alive(1).size() == 7, "no reinf before 95s"): return
	_fp_at(s4, 952)
	if not TestCheck.ok(self, s4.st.reinf and s4.st.fleets.size() == 15 and absf(s4.st.reinf_ms - 95050) <= 50, "reinf at 95s ms=%d" % s4.st.reinf_ms): return
	# --- 결정론: 같은 시드, 같은 명령 → 100·600·종료 지문 일치 ---
	var AR = preload("res://tests/autoresolve.gd")
	var fps := []
	for run in 2:
		var a := BattleSim.new(7)
		var out := []
		while not a.st.over and a.st.tick < 2400:
			for c in AR.policy_commands("attack5", a.projection(0)):
				a.queue(c)
			a.step()
			a.drain_events()
			if a.st.tick == 100 or a.st.tick == 600:
				out.append(a.fingerprint())
		out.append(a.fingerprint())
		fps.append(out)
		if run == 1:
			fps.append(a.command_log.duplicate(true))
	if not TestCheck.ok(self, fps[0] == fps[1] and fps[0].size() == 3, "determinism %s" % str(fps[0].size())): return
	# 다른 시드는 다른 지문
	var o := BattleSim.new(8)
	if not TestCheck.ok(self, _fp_at(o, 600) != fps[0][1], "seed changes fingerprint"): return
	# --- 속도와 무관: 누산기를 어떻게 쪼개도 지문 같다 ---
	var base := BattleSim.new(7)
	_fp_at(base, 600)
	for hzfps in [1.0, 4.0]:
		var ck := TickClock.new()
		ck.set_speed(hzfps)
		var b := BattleSim.new(7)
		var guard := 0
		while b.st.tick < 600 and guard < 100000:
			guard += 1
			var n := ck.advance(1.0 / 60.0)
			for i in n:
				if b.st.tick < 600:
					b.step()
					b.drain_events()
		if not TestCheck.ok(self, b.fingerprint() == base.fingerprint(), "speed %s fingerprint" % hzfps): return
	# --- 누산기: ×1에서 1초 = 10틱, 상한 8, 정지 0, ×0.2 = 2틱/초 ---
	var c := TickClock.new()
	var total := 0
	for i in 60:
		total += c.advance(1.0 / 60.0)
	if not TestCheck.ok(self, total == 10 or total == 9, "x1 ticks/s %d" % total): return
	c = TickClock.new()
	if not TestCheck.ok(self, c.advance(2.0) == 8 and c.dropped > 0, "cap 8"): return
	c.set_speed(0.0)
	if not TestCheck.ok(self, c.advance(1.0) == 0, "paused"): return
	c = TickClock.new()
	c.set_speed(0.2)
	total = 0
	for i in 120:
		total += c.advance(1.0 / 60.0)
	if not TestCheck.ok(self, total == 4 or total == 3, "x0.2 ticks in 2s %d" % total): return
	# --- 재생: 명령 기록으로 다시 돌리면 지문 일치 ---
	var live := BattleSim.new(11)
	var ids2 := []
	for f in live.st.alive(0):
		ids2.append(f.id)
	var t := 0
	while t < 900 and not live.st.over:
		if t == 20:
			live.queue(BattleSim.command(0, ids2, "move", -1, Vector2(1500, 1100)))
		if t == 300:
			live.queue(BattleSim.command(0, ids2, "charge"))
		if t == 400:
			live.queue(BattleSim.command(0, ids2, "missile"))
		live.step()
		live.drain_events()
		t += 1
	var rp := BattleSim.replay(11, 10, live.command_log, live.st.tick)
	if not TestCheck.ok(self, live.command_log.size() == 3, "log size %d" % live.command_log.size()): return
	if not TestCheck.ok(self, rp.fingerprint() == live.fingerprint(), "replay fingerprint"): return
	# --- 투영: 구조와 정수 척 수 ---
	var pj := live.projection(0)
	if not TestCheck.ok(self, pj.squadrons.size() == live.st.fleets.size() and pj.tick == live.st.tick and pj.squadrons[0].ships_milli is int, "projection"): return
	# --- 승패 경로: 기함 격침 ---
	var s5 := BattleSim.new(3)
	s5.st.flag(0).ships = 100
	s5.apply_dmg(s5.st.flag(1), s5.st.flag(0), 1000.0)
	s5.step()
	if not TestCheck.ok(self, s5.st.over and not s5.st.win and s5.st.end_reason == "flagship_lost", "flagship loss path"): return
	# 승리 경로: 증원 뒤 전멸
	var s6 := BattleSim.new(3)
	s6.st.reinf = true
	for f in s6.st.alive(1):
		f.dead = true
		f.ships = 0
	s6.step()
	if not TestCheck.ok(self, s6.st.over and s6.st.win and s6.st.end_reason == "annihilation", "win path"): return
	# 전멸해도 증원 전이면 증원이 먼저 나온다
	var s7 := BattleSim.new(3)
	for f in s7.st.alive(1):
		f.dead = true
		f.ships = 0
	s7.step()
	if not TestCheck.ok(self, not s7.st.over and s7.st.reinf and s7.st.alive(1).size() == 2, "reinf before win"): return
	print("CORE_RULES_PASS")
	quit(0)
