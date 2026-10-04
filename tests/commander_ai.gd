extends SceneTree

# M7 완료 기준(제안서 §5, §9): 플레이어 명령 0건으로 정상 종료, 방침별 행동 차이, AI 입력에 미탐지 정보 0건,
# 직접/위임 전환, 결정 카드(time_left·예고·응답·위임 처리), 놓친 추정 접촉은 마지막 위치로 조준, 같은 시드 지문 일치.
# 헤드리스, 실패하면 종료 코드 1.

const RC := "res://data/profiles/red_cliffs_rt.json"

func _initialize() -> void:
	call_deferred("_run")

func _sec(s: BattleSim, n: float) -> void:
	for i in int(n * s.st.hz):
		s.step()
		s.drain_events()

# 적벽 프로필. fog false면 안개를 끈다(완전 정보: AI 규칙 단위 테스트). 전대는 sq_id로 찾는다.
func _rc(seed_id := 1, fog := true, diff := "표준", live := false) -> BattleSim:
	var p := ScenarioProfile.load_profile(RC, diff)
	if not fog:
		p.combat.erase("detection")
	var s := BattleSim.new(seed_id, BattleRules.TICK_HZ, p)
	if not live:
		s.st.ai_timer = 1 << 40   # 단위 테스트는 think()를 직접 부른다
	return s

func _f(s: BattleSim, sq_id: String) -> FleetState:
	for f in s.st.fleets:
		if f.sq_id == sq_id:
			return f
	return null

func _park(s: BattleSim, keep: Array) -> void:
	# keep 말고는 먼 구석으로 보낸다(서로 탐지·사격에 얽히지 않게)
	var i := 0
	for f in s.st.fleets:
		if not (f.sq_id in keep):
			f.pos = Vector2(40.0 + 30.0 * i if f.side == 0 else 1560.0 - 30.0 * i, 880.0)   # 진영별 반대쪽 구석
			f.home = f.pos
			i += 1
			f.wait = 0

func _run() -> void:
	# --- 1. 플레이어 명령 0건으로 정상 종료 + AI 입력 경계(미탐지 정보 0건) ---
	var s := _rc(3, true, "표준", true)
	var bad := ""
	var allowed := ["id", "side", "contact", "pos", "err_r", "conf_bp", "faction", "name", "role", "portrait", "commander_id", "faction_id", "heading", "strength_band", "max_strength_band"]
	var thinks := 0
	var cards := 0
	while not s.st.over and s.st.tick < 1800 * s.st.hz:
		s.step()
		s.drain_events()
		if s.st.tick % 5 == 0:
			for side in 2:
				var v: Dictionary = s.cai.last_view[side]
				if v.is_empty():
					continue
				thinks += 1
				for q in v.squadrons:
					if q.side == side:
						continue
					if not (q.id in s.cai.last_known[side]) or not q.has("contact"):
						bad = "미탐지 적이 AI 입력에 있다 id %d" % q.id
					for k in q.keys():
						if not (k in allowed):
							bad = "AI 입력의 적 항목에 공개하지 않는 키 %s" % k
		for f in s.st.alive(1):
			if f.target_id >= 0 and not s.detect.contacts[1].has(f.target_id):
				bad = "적 AI가 접촉 없는 표적을 골랐다"
		if bad != "":
			break
	if not TestCheck.ok(self, bad == "", bad): return
	if not TestCheck.ok(self, thinks > 100, "AI 입력 표본 %d" % thinks): return
	if not TestCheck.ok(self, s.st.over, "자동 해결이 20분 안에 끝나야 한다(종료 경로 %s, 시계 %.0f초)" % [s.st.end_reason, s.st.clock_s()]): return
	if not TestCheck.ok(self, s.command_log.size() == 0, "플레이어 명령 0건: %d" % s.command_log.size()): return
	var fp_a := s.fingerprint()
	var done_a := s.decisions.done.size()
	print("자동 해결: %s %.0f초, 결정 카드 %d, AI 돌격 %d 퇴각 %d 진형 %d" % [s.st.end_reason, s.st.end_ms / 1000.0, done_a, s.cai.stats.charge, s.cai.stats.retreat, s.cai.stats.formation])

	# --- 2. 같은 시드는 같은 지문 ---
	var s2 := _rc(3, true, "표준", true)
	while not s2.st.over and s2.st.tick < 1800 * s2.st.hz:
		s2.step()
		s2.drain_events()
	if not TestCheck.ok(self, s2.fingerprint() == fp_a, "같은 시드 지문 일치"): return

	# --- 3. 미탐지 아군의 위치는 적 AI에 영향이 없다(불간섭). 탐지되면 달라진다(양성 대조) ---
	var res := []
	for variant in 3:
		var t := _rc(5, true, "표준", true)
		var hidden := _f(t, "RC-LIU-SQ-03")   # (230, 700): 조조 선봉(1250~1330)에서 1000 넘게 멀다
		hidden.pos = [Vector2(230, 700), Vector2(60, 880), Vector2(1250, 160)][variant]   # 셋째는 조조 문빙에 바짝 붙인다
		_sec(t, 75.0)
		var sig := []
		for f in t.st.alive(1):
			sig.append([f.id, f.target_id, f.has_move, f.move_to])
		res.append(sig)
		if variant < 2 and not TestCheck.ok(self, t.detect.state(1, hidden.id) == "", "변형 %d: 아군이 미탐지여야 한다" % variant): return
	if not TestCheck.ok(self, res[0] == res[1], "미탐지 아군 위치가 달라도 적 AI 명령이 같다"): return
	if not TestCheck.ok(self, res[0] != res[2], "탐지되면 적 AI가 반응한다(대조)"): return

	# --- 4. 방침별 행동 차이(완전 정보, 한 번 생각) ---
	var base_s := _rc(1, false)
	var A: Dictionary = base_s.cai.A
	if not TestCheck.ok(self, A.postures.size() == 5, "방침 5종"): return
	# 4a. 목표 거리: 첫 명중 900초 뒤. 적극 100(강습), 균형 170(교전), 신중·계략 240(포화 유지)
	var want := {"aggressive": 100.0, "balanced": 170.0, "cautious": 240.0, "scheming": 240.0}
	var ally := _f(base_s, "RC-LIU-SQ-02")
	base_s.first_hit_tick = 0
	base_s.st.tick = 900 * base_s.st.hz
	for pid in want:
		var P: Dictionary = A.postures[pid]
		var D: float = base_s.cai._desired(base_s, ally, A.factions.liu_bei, P, float(P.bias))
		if not TestCheck.ok(self, is_equal_approx(maxf(D, 0.0), maxf(want[pid], 150.0)), "%s 목표 거리 %.0f(기대 %.0f, 진영 하한 150)" % [pid, D, want[pid]]): return
	# 4b~d. 같은 상황에서 방침만 바꿔 한 번 생각시킨다
	var out := {}
	for pid in want:
		var t := _rc(1, false)
		_park(t, ["RC-LIU-SQ-02", "RC-CAO-SQ-02"])
		var a := _f(t, "RC-LIU-SQ-02")
		var c := _f(t, "RC-CAO-SQ-02")
		a.pos = Vector2(800, 450)
		c.pos = Vector2(930, 450)   # 거리 130
		t.first_hit_tick = 0
		t.st.tick = 900 * t.st.hz
		t.apply(BattleSim.command(0, [a.id], "posture", -1, Vector2.ZERO, {"id": pid}))
		t.cai.think(t)
		var kite_to := a.move_to if a.has_move else a.pos
		# 퇴각: 사기 3500
		var u := _rc(1, false)
		_park(u, ["RC-LIU-SQ-02", "RC-CAO-SQ-02"])
		var a2 := _f(u, "RC-LIU-SQ-02")
		a2.pos = Vector2(800, 450)
		_f(u, "RC-CAO-SQ-02").pos = Vector2(1000, 450)
		a2.morale_bp = 3500
		u.apply(BattleSim.command(0, [a2.id], "posture", -1, Vector2.ZERO, {"id": pid}))
		u.cai.think(u)
		out[pid] = {"charge": a.charge > 0, "kite": kite_to.distance_to(c.pos), "retreat": a2.retreat_order}
	if not TestCheck.ok(self, out.aggressive.charge and not out.balanced.charge and not out.cautious.charge and not out.scheming.charge, "돌격은 적극만: %s" % str(out)): return
	if not TestCheck.ok(self, out.cautious.kite >= 239.0 and out.scheming.kite >= 239.0 and out.balanced.kite < 131.0, "거리 130에서 신중·계략은 240까지 물러나고 균형·적극은 유지: %s" % str(out)): return
	if not TestCheck.ok(self, out.cautious.retreat and out.scheming.retreat and not out.aggressive.retreat and not out.balanced.retreat, "사기 3500: 신중·계략만 질서 퇴각: %s" % str(out)): return
	# 4e. 인물 위임(기본값): 지휘관 성향으로 방침이 정해진다. 장비(무뢰)는 적극, 관우(절의)는 신중, 황개는 계략 중시
	var cai: CommanderAi = base_s.cai
	if not TestCheck.ok(self, cai.posture_of(_f(base_s, "RC-LIU-SQ-02")) == "cautious" and cai.posture_of(_f(base_s, "RC-CAO-SQ-02")) == "aggressive" and cai.posture_of(_f(base_s, "RC-SUN-SQ-03")) == "scheming" and cai.posture_of(_f(base_s, "RC-LIU-SQ-01")) == "balanced", "성향 → 방침"): return
	# 4f. 손권군은 아군 300 안에 적이 없으면 접근하지 않는다
	var h := _rc(1, false)
	_park(h, ["RC-SUN-SQ-02", "RC-CAO-SQ-02"])
	var sa := _f(h, "RC-SUN-SQ-02")
	sa.pos = Vector2(600, 450)
	_f(h, "RC-CAO-SQ-02").pos = Vector2(1100, 450)
	h.cai.think(h)
	if not TestCheck.ok(self, not sa.has_move, "손권군은 적이 300 밖이면 제자리"): return
	_f(h, "RC-CAO-SQ-02").pos = Vector2(880, 450)
	h.cai.think(h)
	if not TestCheck.ok(self, sa.has_move, "아군 전대에서 300 안으로 들어오면 접근"): return

	# --- 5. 직접/위임 ---
	var d := _rc(1, false)
	_park(d, ["RC-LIU-SQ-02", "RC-CAO-SQ-02"])
	var da := _f(d, "RC-LIU-SQ-02")
	da.pos = Vector2(800, 450)
	_f(d, "RC-CAO-SQ-02").pos = Vector2(1000, 450)
	d.first_hit_tick = 0
	d.st.tick = 900 * d.st.hz
	if not TestCheck.ok(self, da.control == "delegate", "기본은 위임"): return
	d.issue(BattleSim.command(0, [da.id], "move", -1, Vector2(100, 100)))
	if not TestCheck.ok(self, da.control == "direct", "명령하면 직접 지휘"): return
	var mv := da.move_to
	d.cai.think(d)
	if not TestCheck.ok(self, da.move_to == mv and da.target_id == -1, "직접 지휘 전대는 AI가 이동·표적을 바꾸지 않는다"): return
	d.issue(BattleSim.command(0, [da.id], "delegate"))
	d.cai.think(d)
	if not TestCheck.ok(self, da.control == "delegate" and da.move_to != mv, "위임으로 돌리면 AI가 다시 정한다"): return
	d.set_manual_all(true)
	if not TestCheck.ok(self, d.st.alive(0).all(func(f): return f.control == "direct"), "전 전대 수동"): return
	d.set_manual_all(false)
	d.issue(BattleSim.command(0, [da.id], "posture", -1, Vector2.ZERO, {"id": "bogus"}))
	var why := ""
	for e in d.drain_events():
		if e.kind == "rejected":
			why = str(e.value)
	if not TestCheck.ok(self, why == "unknown_command", "알 수 없는 방침 거부: '%s'" % why): return
	var pr: Dictionary = d.projection(0)
	var pq := {}
	for q in pr.squadrons:
		pq[q.id] = q
	if not TestCheck.ok(self, pq[da.id].control == "delegate" and pq[da.id].posture == "delegated", "투영 control·posture"): return

	# --- 6. 결정 카드: 예고 → 열림(time_left) → 응답, 시간 초과는 추천안으로 위임 처리 ---
	var k := _rc(1, false)
	var dc: Dictionary = k.decisions.cfg
	k.st.army_ev[0] = 9000   # 연합 군 사기를 위기 아래로
	k.step()
	var pj: Dictionary = k.projection(0)
	if not TestCheck.ok(self, pj.pending_decisions.is_empty() and pj.upcoming_decisions.size() == 1 and pj.upcoming_decisions[0].kind == "morale_crisis", "위기 진입 → 예고 중: %s" % str(pj.upcoming_decisions)): return
	if not TestCheck.ok(self, absf(float(pj.upcoming_decisions[0].eta_s) - float(dc.precursor_s)) < 0.2, "예고 약 %ss 전: %.1f" % [str(dc.precursor_s), pj.upcoming_decisions[0].eta_s]): return
	if not TestCheck.ok(self, k.projection(1).pending_decisions.is_empty(), "적 진영 투영에는 카드가 없다"): return
	_sec(k, float(dc.precursor_s) + 0.2)
	pj = k.projection(0)
	if not TestCheck.ok(self, pj.pending_decisions.size() == 1 and pj.upcoming_decisions.is_empty(), "예고 뒤 카드가 열린다"): return
	var card: Dictionary = pj.pending_decisions[0]
	if not TestCheck.ok(self, card.rec == "defend" and card.time_left > float(dc.time_game_s) - 1.0 and card.time_left <= float(dc.time_game_s), "time_left %.1f, 추천 %s" % [card.time_left, card.rec]): return
	_sec(k, 10.0)
	if not TestCheck.ok(self, absf(k.projection(0).pending_decisions[0].time_left - (card.time_left - 10.0)) < 0.15, "time_left는 게임 초로 줄어든다"): return
	# 플레이어 응답: counter → 위임 전대 가중 +
	k.issue(BattleSim.command(0, [], "decide", -1, Vector2.ZERO, {"id": card.id, "option": "counter"}))
	if not TestCheck.ok(self, k.projection(0).pending_decisions.is_empty() and k.decisions.done.size() == 1 and k.decisions.done[0].by == "player", "응답하면 카드가 닫힌다"): return
	var lf := _f(k, "RC-LIU-SQ-02")
	if not TestCheck.ok(self, lf.bias_mod > 0.0 and lf.bias_until > k.st.tick, "공세 응답: 위임 전대 가중 +"): return
	k.issue(BattleSim.command(0, [], "decide", -1, Vector2.ZERO, {"id": 999, "option": "x"}))
	why = ""
	for e in k.drain_events():
		if e.kind == "rejected":
			why = str(e.value)
	if not TestCheck.ok(self, why == "no_decision", "없는 카드 응답 거부: '%s'" % why): return
	# 응답이 없으면 time_game_s 뒤 추천안(방어)을 위임 처리. 직접 지휘 전대는 가중을 받지 않는다
	var m := _rc(1, false)
	m.st.army_ev[0] = 6000   # 위기(4500) 아래, 붕괴(3000) 위
	_f(m, "RC-LIU-SQ-01").control = "direct"
	_sec(m, float(dc.precursor_s) + float(dc.time_game_s) + 1.0)
	if not TestCheck.ok(self, m.decisions.done.size() == 1 and m.decisions.done[0].by == "delegate" and m.decisions.done[0].option == "defend", "시간 초과 → 추천안 위임 처리: %s" % str(m.decisions.done)): return
	if not TestCheck.ok(self, _f(m, "RC-LIU-SQ-02").bias_mod < 0.0 and _f(m, "RC-LIU-SQ-01").bias_mod == 0.0, "방어 위임: 위임 전대만 가중 −"): return
	# 추격 카드: 확인한 적 전대가 퇴각 상태가 되면 열린다
	var q := _rc(1, false)
	_f(q, "RC-CAO-SQ-02").morale_bp = 2000   # 퇴각 구간(3000 미만). 상태는 사기에서 정해진다
	_sec(q, float(dc.precursor_s) + 0.3)
	var pc: Array = q.projection(0).pending_decisions
	if not TestCheck.ok(self, pc.size() == 1 and pc[0].kind == "pursuit" and pc[0].ref == _f(q, "RC-CAO-SQ-02").id, "추격 카드: %s" % str(pc)): return

	# --- 7. 놓친 추정 접촉은 마지막 위치로 조준한다 ---
	var F := SalvoFixture
	var full := F.combat()
	var g := SalvoFixture.sim([F.def("A", 400, 450, [["SHP-03", 8]], true)], [F.def("B", 600, 450, [["SHP-04", 4]], true)], 1, "", func(cb): cb.detection = full.detection)
	var ga: FleetState = g.st.fleets[0]
	var gb: FleetState = g.st.fleets[1]
	_sec(g, 1.0)
	var rec := {"seen": g.st.tick, "pos": Vector2(900, 450), "state": "estimated", "conf_bp": 7500, "err_r": 55.0}
	g.detect.contacts[0][gb.id] = rec   # 접촉은 (900, 450)에 있다고 안다. 실제는 (600, 450)
	if not TestCheck.ok(self, g.salvo.qualifying(ga, "artillery", gb).is_empty() and g.salvo.aim_ok(ga, gb) == false, "조준점(900,450)은 사거리 밖이라 쏘지 못한다(실제 거리 200은 사거리 안)"): return
	rec.pos = Vector2(560, 450)   # 마지막 위치가 사거리 안이지만 실제와 40 어긋남(오차 55 안)
	if not TestCheck.ok(self, not g.salvo.qualifying(ga, "artillery", gb).is_empty() and g.salvo.aim_ok(ga, gb), "마지막 위치가 사거리 안이고 오차 반경 안이면 사격 가능·명중 가능"): return
	rec.pos = Vector2(520, 450)   # 80 어긋남: 사거리는 되지만 오차 반경(55) 밖
	if not TestCheck.ok(self, not g.salvo.qualifying(ga, "artillery", gb).is_empty() and not g.salvo.aim_ok(ga, gb), "오차 반경 밖이면 쏘되 빗나간다"): return
	rec.state = "confirmed"
	if not TestCheck.ok(self, g.salvo.aim_ok(ga, gb) and g.detect.aim_pos(0, gb) == gb.pos, "확인 접촉은 실제 위치"): return

	# --- 8. 명령이 섞인 안개 판의 재생 지문 일치(M6 리뷰 F-2) ---
	var live := _rc(7, true, "표준", true)
	var ids := []
	for f in live.st.alive(0):
		ids.append(f.id)
	var until := 150 * live.st.hz
	while live.st.tick < until:
		if live.st.tick == 20 * live.st.hz:
			live.queue(BattleSim.command(0, [ids[1]], "move", -1, Vector2(500, 300)))
		if live.st.tick == 60 * live.st.hz:
			live.queue(BattleSim.command(0, [ids[1]], "delegate"))
			live.queue(BattleSim.command(0, [ids[0]], "posture", -1, Vector2.ZERO, {"id": "aggressive"}))
		live.step()
		live.drain_events()
	var rp := ScenarioProfile.load_profile(RC, "표준")
	var again := BattleSim.replay(7, live.st.hz, live.command_log, until, rp)
	if not TestCheck.ok(self, live.command_log.size() == 3 and again.fingerprint() == live.fingerprint(), "명령이 섞인 안개 판 재생 지문 일치(명령 %d건)" % live.command_log.size()): return

	print("COMMANDER_AI_PASS")
	quit(0)
