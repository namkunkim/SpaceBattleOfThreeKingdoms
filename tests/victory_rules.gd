extends SceneTree

# M4 완료 기준(제안서 §9): §4.12 모든 종료 경로, 전대·군 사기, 강제 퇴각 이동, 탈출 지점, 코스트 70%, 20분 시계, CP 제거.
# 적벽 표준 프로필을 읽고 상태를 직접 만들어 한 경로씩 확인한다. 헤드리스, 실패하면 종료 코드 1.

const SQ := {"liu": "RC-LIU-SQ-01", "zhuge": "RC-LIU-SQ-02", "jiang": "RC-LIU-SQ-03", "fc": "RC-LIU-FC-01",
	"zhou": "RC-SUN-SQ-01", "cao": "RC-CAO-SQ-01"}

func _initialize() -> void:
	call_deferred("_run")

func _sim(seed_id := 1, diff := "표준") -> BattleSim:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", diff)
	var s := BattleSim.new(seed_id, BattleRules.TICK_HZ, p)
	s.st.ai_timer = 1 << 40   # AI 끔
	return s

func _f(s: BattleSim, key: String) -> FleetState:
	for f in s.st.fleets:
		if f.sq_id == SQ.get(key, key):
			return f
	return null

# 한 초(10틱) 진행
func _sec(s: BattleSim, n := 1) -> void:
	for i in n * s.st.hz:
		s.step()
		s.drain_events()

# 전대를 코스트 비율만큼 잃은 상태로 만든다(이탈 척 수를 함종 순서대로 늘린다)
func _wreck(s: BattleSim, f: FleetState, share_bp: int) -> void:
	var dmg := f.max_hull * share_bp / BattleRules.BP
	s.salvo.apply_hull(null, f, float(dmg), "engagement", "front", s.st.new_event_id())

func _ended(s: BattleSim, win: bool, reason: String, msg: String) -> bool:
	return TestCheck.ok(self, s.st.over and s.st.win == win and s.st.end_reason == reason, "%s: over=%s win=%s reason=%s" % [msg, s.st.over, s.st.win, s.st.end_reason])

func _run() -> void:
	# --- CP 제거: salvo 규칙은 CP를 쓰지 않고 투영에도 없다 ---
	var s := _sim()
	if not TestCheck.ok(self, s.victory != null and s.morale != null, "morale·victory 켜짐"): return
	_sec(s, 5)
	if not TestCheck.ok(self, s.st.cp == 0 and s.st.ecp == 0 and not s.projection(0).has("cp_bp"), "CP 없음"): return
	var poc := BattleSim.new(1)
	if not TestCheck.ok(self, poc.victory == null and poc.projection(0).has("cp_bp"), "POC는 CP 유지"): return

	# --- 전대 사기 상태 임계: 6000 이상 안정, 3000~5999 동요, 1~2999 퇴각, 0 항복 ---
	s = _sim()
	var z := _f(s, "zhuge")
	var th := {10000: "stable", 6000: "stable", 5999: "shaken", 3000: "shaken", 2999: "retreat", 1: "retreat"}
	for bp in th:
		z.morale_bp = bp
		s.morale.step()
		if not TestCheck.ok(self, z.mstate == th[bp], "상태 %d -> %s (%s)" % [bp, th[bp], z.mstate]): return
	z.morale_bp = 0
	s.morale.step()
	if not TestCheck.ok(self, z.out == "surrender" and z.dead, "사기 0은 항복"): return

	# --- 명중 감소: max(300, ceil(피해×10000/(최대 선체×5))) × 거리대 × 방향 ---
	s = _sim()
	var j := _f(s, "jiang")
	j.morale_bp = 10000
	s.morale.hit(j, 1, "barrage", "front")    # 하한 300 × 1.2
	if not TestCheck.ok(self, j.morale_bp == 10000 - 360, "명중 하한 300×1.2: %d" % j.morale_bp): return
	j.morale_bp = 10000
	s.morale.hit(j, 1, "engagement", "rear")  # 300 × 2.0 × 1.5
	if not TestCheck.ok(self, j.morale_bp == 10000 - 900, "교전 후면: %d" % j.morale_bp): return
	j.morale_bp = 10000
	s.morale.hit(j, j.max_hull / 2, "assault", "flank")  # 선체 절반: 10000×0.5/5 = 1000 × 1.6 × 1.25 = 2000
	if not TestCheck.ok(self, j.morale_bp == 10000 - 2000, "큰 피해: %d" % j.morale_bp): return
	j.morale_bp = 10000
	s.morale.ship_departed(j)
	if not TestCheck.ok(self, j.morale_bp == 9800, "이탈 200"): return
	# 연환: 조조 밀집 진형 ×0.8
	var cs := _f(s, "cao")
	cs.morale_bp = 10000
	s.morale.hit(cs, 1, "engagement", "front")   # 300 × 2.0 × 0.8
	if not TestCheck.ok(self, cs.morale_bp == 10000 - 480, "연환 ×0.8: %d" % cs.morale_bp): return

	# --- 군 사기: 코스트 가중 평균, 퇴각은 현재 사기, 항복·탈출은 0, 사건 누적 ---
	s = _sim()
	for f in s.st.fleets:
		f.morale_bp = 10000 if f.side == 0 else 8000
	if not TestCheck.ok(self, s.morale.army_bp(0) == 10000 and s.morale.army_bp(1) == 8000, "군 사기 평균"): return
	z = _f(s, "zhuge")
	z.morale_bp = 2000   # 퇴각 상태: 현재 사기 그대로 센다
	s.morale.step()
	var a1: int = s.morale.army_bp(0)
	var cost_all := 0
	for f in s.st.fleets:
		if f.side == 0:
			cost_all += f.cost0
	var expect := (10000 * (cost_all - z.cost0) + 2000 * z.cost0) / cost_all - 500   # 퇴각 사건 −500
	if not TestCheck.ok(self, z.mstate == "retreat" and a1 == expect, "퇴각 전대는 현재 사기: %d != %d" % [a1, expect]): return
	if not TestCheck.ok(self, s.morale.army_bp(1) == 8000, "상대 회복은 누적 0 아래로 내려가지 않음"): return
	s.morale.step()
	if not TestCheck.ok(self, s.morale.army_bp(0) == a1, "퇴각 사건은 한 번만"): return
	z.morale_bp = 0
	s.morale.step()   # 항복: 0으로 센다
	var expect2 := (10000 * (cost_all - z.cost0)) / cost_all - 500
	if not TestCheck.ok(self, s.morale.army_bp(0) == expect2, "항복은 0: %d != %d" % [s.morale.army_bp(0), expect2]): return

	# --- 강제 퇴각 이동: 공격·명령 불가, 탈출 지점으로 이동, 도착하면 탈출 ---
	s = _sim()
	z = _f(s, "zhuge")
	z.morale_bp = 2500
	_sec(s, 2)
	var d0 := z.pos.distance_to(s.morale.exit_point(0))
	s.queue(BattleSim.command(0, [z.id], "attack", _f(s, "cao").id))
	s.step()
	var rej := false
	for e in s.drain_events():
		if e.kind == "rejected" and e.value == "retreating":
			rej = true
	if not TestCheck.ok(self, rej and z.target_id == -1, "퇴각 중 명령 거부"): return
	_sec(s, 60)   # 선회 9°/초라 먼저 돌아서는 데 20초가 든다(M5)
	if not TestCheck.ok(self, z.pos.distance_to(s.morale.exit_point(0)) < d0 - 20.0, "탈출 지점으로 이동"): return
	z.pos = s.morale.exit_point(0) + Vector2(30, 0)
	_sec(s, 1)
	if not TestCheck.ok(self, z.out == "escaped" and z.dead, "탈출 지점 반경 60에 닿으면 탈출"): return
	# 퇴각 중에는 사격하지 않는다
	s = _sim()
	z = _f(s, "zhuge")
	var c := _f(s, "cao")
	c.pos = z.pos + Vector2(120, 0)
	z.heading = 0.0
	z.morale_bp = 2500
	_sec(s, 5)
	var fired := false
	for e in s.drain_events():
		fired = fired or (e.kind == "salvo" and e.sq == z.id)
	if not TestCheck.ok(self, not fired and z.mstate == "retreat", "퇴각 전대는 쏘지 않음"): return

	# --- 후퇴 명령은 탈출 지점 이동이고 이동·공격 명령으로 취소된다 ---
	s = _sim()
	z = _f(s, "zhuge")
	s.queue(BattleSim.command(0, [z.id], "retreat"))
	s.step()
	if not TestCheck.ok(self, z.retreat_order and z.has_move and z.move_to == s.morale.exit_point(0), "후퇴 명령 = 탈출 지점 이동"): return
	s.queue(BattleSim.command(0, [z.id], "stop"))
	s.step()
	if not TestCheck.ok(self, not z.retreat_order, "정지 명령으로 취소"): return

	# --- 사건 회복과 결집 ---
	s = _sim()
	for f in s.st.fleets:
		f.morale_bp = 10000
	z = _f(s, "zhuge")
	var base0: int = s.morale.army_bp(0)
	c = _f(s, "cao")
	c.morale_bp = 2000
	s.morale.step()   # 조조 전대 퇴각: 연합 군 사기 +300(누적이 0이라 그대로), 조조군 −500
	if not TestCheck.ok(self, s.st.army_ev[1] == 500 and s.st.army_ev[0] == 0, "퇴각 사건"): return
	var lf := _f(s, "liu")
	z.morale_bp = 4000
	lf.morale_bp = 4000
	z.pos = lf.pos + Vector2(100, 0)
	var far := _f(s, "zhou")
	far.morale_bp = 4000
	far.pos = lf.pos + Vector2(600, -300)
	s.queue(BattleSim.command(0, [lf.id], "morale_rally", -1, Vector2.ZERO, {"id": "liu_bei_rally"}))
	s.step()
	if not TestCheck.ok(self, z.morale_bp >= 5200 and lf.morale_bp >= 5200 and far.morale_bp == 4000, "결집: 반경 200 안만 +1200 (%d %d %d)" % [z.morale_bp, lf.morale_bp, far.morale_bp]): return
	s.queue(BattleSim.command(0, [lf.id], "morale_rally", -1, Vector2.ZERO, {"id": "liu_bei_rally"}))
	s.step()
	rej = false
	for e in s.drain_events():
		rej = rej or (e.kind == "rejected" and e.value == "rally_used")
	if not TestCheck.ok(self, rej, "결집은 전투당 1회"): return
	# 결집 30초 동안 감소 ×0.5
	var before := lf.morale_bp
	s.morale.lose(lf, 1000)
	if not TestCheck.ok(self, lf.morale_bp == before - 500, "결집 중 감소 ×0.5"): return

	# --- 역병: 분산 진형 북방군만 10초마다 −40 ---
	s = _sim(1, "상급")
	var hu := _f(s, "RC-CAO-SQ-06")
	var m0 := hu.morale_bp
	s.st.tick = hu.wait   # 투입 뒤
	var ms: MoraleCore = s.morale
	ms._plague_tick()
	if not TestCheck.ok(self, hu.morale_bp == m0 - 40 and cs.morale_bp != 0, "역병 −40: %d" % (m0 - hu.morale_bp)): return
	var inn := _f(s, "RC-CAO-SQ-02")   # 어린진은 중립
	var n0 := inn.morale_bp
	ms._plague_tick()
	if not TestCheck.ok(self, inn.morale_bp == n0, "중립 진형은 역병 없음"): return

	# ===== §4.12 종료 경로 =====
	# 1. 유비 기함 선체 0 → 연합 패배
	print("sec 1")
	s = _sim()
	s.salvo.apply_hull(null, _f(s, "liu"), 1e9, "engagement", "front", 1)
	_sec(s, 1)
	if not _ended(s, false, "liu_flagship_lost", "유비 기함 격침"): return
	if not TestCheck.ok(self, s.st.result.commanders.alliance in ["severe", "captured", "killed"], "유비 운명 결산"): return
	# 2. 조조 기함 선체 0 → 연합 승리
	print("sec 2")
	s = _sim()
	s.salvo.apply_hull(null, _f(s, "cao"), 1e9, "engagement", "front", 1)
	_sec(s, 1)
	if not _ended(s, true, "cao_flagship_lost", "조조 기함 격침"): return
	# 2b. 기함 항복도 같다 (G8-04: 포로)
	print("sec 2b")
	s = _sim()
	_f(s, "cao").morale_bp = 0
	_sec(s, 1)
	if not _ended(s, true, "cao_flagship_lost", "조조 기함 항복") or not TestCheck.ok(self, s.st.result.commanders.foe == "captured", "조조 포로"): return
	# 3. 조조 기함이 탈출 지점 반경 60에 도달 → 연합 승리
	print("sec 3")
	s = _sim()
	_f(s, "cao").pos = Vector2(1600, 300) - Vector2(50, 0)
	_sec(s, 1)
	if not _ended(s, true, "cao_escaped", "조조 도주"): return
	s = _sim()
	_f(s, "cao").pos = Vector2(1600, 300) - Vector2(80, 0)
	_sec(s, 1)
	if not TestCheck.ok(self, not s.st.over, "반경 밖은 도달 아님"): return
	# 4. 유비 기함과 함대 전체가 연합 탈출 지점 → 제한적 승리 (함대 = RC-LIU-FLT-01: 유비·제갈량·고속정)
	print("sec 4")
	s = _sim()
	var ex := Vector2(0, 650)
	_f(s, "liu").pos = ex + Vector2(40, 0)
	_f(s, "zhuge").pos = ex + Vector2(40, 30)
	_sec(s, 1)
	if not TestCheck.ok(self, not s.st.over, "함대 일부만 도달하면 아님"): return
	_f(s, "fc").pos = ex + Vector2(30, -30)
	_sec(s, 1)
	if not _ended(s, true, "alliance_escaped", "제한적 승리") or not TestCheck.ok(self, s.st.result.limited, "limited 표시"): return
	# 4a. 같은 함대의 격침·항복 전대가 있으면 나머지가 모두 도달해도 제한적 승리가 아니다
	print("sec 4a")
	s = _sim()
	_f(s, "liu").pos = ex + Vector2(40, 0)
	_f(s, "fc").pos = ex + Vector2(30, -30)
	_wreck(s, _f(s, "zhuge"), 10000)
	_sec(s, 1)
	if not TestCheck.ok(self, not (s.st.over and s.st.end_reason == "alliance_escaped"), "격침 전대가 있으면 제한적 승리 아님"): return
	# 4b. 강하군(다른 함대)은 조건이 아니다
	print("sec 4b")
	# 5. 유비군 코스트 70% 손실 → 연합 패배
	print("sec 5")
	s = _sim()
	for k in ["zhuge", "jiang", "fc"]:
		_wreck(s, _f(s, k), 9500)
	_wreck(s, _f(s, "liu"), 6500)
	_sec(s, 1)
	var anchor: Dictionary = s.victory.cost_of("anchor")
	if not TestCheck.ok(self, anchor.loss_bp >= 7000 and s.st.over and not s.st.win and s.st.end_reason == "liu_cost_loss", "유비군 70%%: loss=%d reason=%s" % [anchor.loss_bp, s.st.end_reason]): return
	# 6. 연합 결합 코스트 70% (유비군 단독으로는 안 닿는다)
	print("sec 6")
	s = _sim()
	for k in ["zhuge", "jiang", "fc", "zhou"]:
		_wreck(s, _f(s, k), 9900)
	_wreck(s, _f(s, "RC-SUN-SQ-02"), 9900)
	_wreck(s, _f(s, "RC-SUN-SQ-03"), 9900)
	_wreck(s, _f(s, "liu"), 5000)
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and not s.st.win and s.st.end_reason in ["alliance_cost_loss", "liu_cost_loss"], "연합 결합 70%%: %s" % s.st.end_reason): return
	# 7. 조조군 코스트 70% 손실 → 연합 승리
	print("sec 7")
	s = _sim()
	for f in s.st.fleets:
		if f.side == 1 and not f.is_flag:
			_wreck(s, f, 9900)
	_wreck(s, _f(s, "cao"), 5000)
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and s.st.win and s.st.end_reason == "cao_cost_loss", "조조군 70%%: %s" % s.st.end_reason): return
	# 8. 전 전대 소멸(항복) — 유비군
	print("sec 8")
	s = _sim()
	for f in s.st.fleets:
		if f.side == 0 and f.faction == s.victory.anchor_faction:
			f.morale_bp = 0
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and not s.st.win and s.st.end_reason in ["liu_flagship_lost", "liu_eliminated"], "유비군 전 전대 항복: %s" % s.st.end_reason): return
	# 8b. 조조군 전 전대 항복 → 연합 승리
	print("sec 8b")
	s = _sim()
	for f in s.st.fleets:
		if f.side == 1:
			f.morale_bp = 0
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and s.st.win, "조조군 전 전대 항복"): return
	# 9. 군 사기 3000 미만 → 즉시 결산, 그 진영 패배 (손권군만 무너져도 연합이 버티면 계속)
	print("sec 9")
	s = _sim()
	for k in ["zhou", "RC-SUN-SQ-02", "RC-SUN-SQ-03"]:
		_f(s, k).morale_bp = 2500   # 퇴각 상태는 현재 사기로 센다(항복 0이 아니다)
	_sec(s, 1)
	if not TestCheck.ok(self, not s.st.over, "손권군만 무너져도 계속: army=%d" % s.morale.army_bp(0)): return
	s = _sim()
	for f in s.st.fleets:
		if f.side == 0:
			f.morale_bp = 2900 if f.is_flag else 2900
	s.morale.step()
	var cr: int = s.morale.army_bp(0)
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and not s.st.win and s.st.end_reason == "alliance_morale_collapse", "연합 군 사기 붕괴 (army=%d): %s" % [cr, s.st.end_reason]): return
	s = _sim()
	for f in s.st.fleets:
		if f.side == 1:
			f.morale_bp = 2900
	s.morale.step()
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and s.st.win and s.st.end_reason == "cao_morale_collapse", "조조군 군 사기 붕괴: %s" % s.st.end_reason): return
	# 10. 동시 성립 → 조조군 승리
	print("sec 10")
	s = _sim()
	s.salvo.apply_hull(null, _f(s, "liu"), 1e9, "engagement", "front", 1)
	s.salvo.apply_hull(null, _f(s, "cao"), 1e9, "engagement", "front", 2)
	_sec(s, 1)
	if not _ended(s, false, "simultaneous", "동시 성립은 조조군"): return
	# 11. 20분 시계: 잔존 코스트 비율이 높은 쪽
	print("sec 11")
	s = _sim()
	_wreck(s, _f(s, "cao"), 2000)
	var lim := int(s.salvo.C.victory.time_limit_s)
	s.st.clock_ms = (lim - 5) * BattleRules.MILLI
	s.st.tick = (lim - 5) * s.st.hz
	_sec(s, 4)
	if not TestCheck.ok(self, not s.st.over, "20분 전에는 계속"): return
	_sec(s, 2)
	if not _ended(s, true, "time_limit", "20분: 조조군 손실이 더 큼 → 연합 승리"): return
	s = _sim()
	_wreck(s, _f(s, "zhuge"), 3000)
	s.st.clock_ms = lim * BattleRules.MILLI
	s.st.tick = lim * s.st.hz
	_sec(s, 1)
	if not _ended(s, false, "time_limit", "20분: 연합 손실이 더 큼 → 조조군"): return
	s = _sim()
	s.st.clock_ms = lim * BattleRules.MILLI
	s.st.tick = lim * s.st.hz
	_sec(s, 1)
	if not _ended(s, false, "time_limit", "20분 동률은 조조군"): return
	# 12. 퇴각 실패(G8-04 6행): 승패 확정 때 강제 퇴각 중이고 탈출 지점 밖인 패배측 전대는 포로
	print("sec 12")
	s = _sim()
	z = _f(s, "zhuge")
	z.morale_bp = 2500
	s.morale.step()
	s.salvo.apply_hull(null, _f(s, "liu"), 1e9, "engagement", "front", 1)
	_sec(s, 1)
	if not TestCheck.ok(self, s.st.over and "RC-LIU-SQ-02" in s.st.result.captured_in_retreat, "퇴각 실패 포로: %s" % str(s.st.result.captured_in_retreat)): return
	# 13. 격침 시 지휘관 운명: 근처에 적만 있으면 포로, 가까운 아군이 더 가까우면 중상
	print("sec 13")
	s = _sim()
	var cf := _f(s, "cao")
	cf.pos = Vector2(900, 450)
	for f in s.st.fleets:
		if f != cf:
			f.pos = Vector2(100, 100)
	_f(s, "zhuge").pos = cf.pos + Vector2(60, 0)
	s.salvo.apply_hull(null, cf, 1e9, "engagement", "front", 1)
	if not TestCheck.ok(self, s.victory.commander_fate(cf) == "captured", "적만 근접: 포로 (%s)" % s.victory.commander_fate(cf)): return
	s = _sim()
	cf = _f(s, "cao")
	cf.pos = Vector2(900, 450)
	for f in s.st.fleets:
		if f != cf:
			f.pos = Vector2(100, 100)
	_f(s, "zhuge").pos = cf.pos + Vector2(60, 0)
	_f(s, "RC-CAO-SQ-02").pos = cf.pos + Vector2(30, 0)
	s.salvo.apply_hull(null, cf, 1e9, "engagement", "front", 1)
	if not TestCheck.ok(self, s.victory.commander_fate(cf) == "severe", "아군이 더 가까움: 중상 생환"): return
	s = _sim()
	cf = _f(s, "cao")
	cf.chain_sunk = true
	s.salvo.apply_hull(null, cf, 1e9, "engagement", "front", 1)
	if not TestCheck.ok(self, s.victory.commander_fate(cf) == "killed", "연쇄 폭발: 전사"): return

	# --- 결정론: 같은 시드는 같은 지문, 재생 일치 ---
	var fp1 := _fp(_sim(7), 1200)
	var fp2 := _fp(_sim(7), 1200)
	if not TestCheck.ok(self, fp1 == fp2, "결정론"): return
	print("VICTORY_RULES_PASS")
	quit(0)

func _fp(s: BattleSim, ticks: int) -> String:
	for i in ticks:
		s.step()
		s.drain_events()
	return s.fingerprint()
