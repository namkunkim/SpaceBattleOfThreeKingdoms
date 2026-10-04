extends SceneTree

# M6 완료 기준(제안서 §4.9·§4.10, §9): 탐지 점수 식과 임계, 접촉 4상태와 기억·신뢰도 감쇠, 추정 사격(명중 × 신뢰도),
# 접촉 없는 적 지정 거부, 지형 3구역 효과, 공개 투영·사건에 미탐지 적 0건, 적 AI가 접촉만 보는지, 지문에 접촉 포함.
# 헤드리스, 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _sec(s: BattleSim, n: float) -> void:
	for i in int(n * s.st.hz):
		s.step()
		s.drain_events()

# 탐지·지형을 켠 소규모 전장(규칙은 실제 데이터). AI는 꺼져 있다.
func _sim(ally: Array, foe: Array, terrain := true) -> BattleSim:
	var full := SalvoFixture.combat()
	return SalvoFixture.sim(ally, foe, 1, "", func(cb):
		cb.detection = full.detection
		if terrain:
			cb.terrain = full.terrain)

func _run() -> void:
	var F := SalvoFixture
	var full := F.combat()
	var D: Dictionary = full.detection

	# --- 1. 점수 식과 임계: 10 × 호위함(센서 3) = 30, 통솔 70 → 지력 구간 +12, 어린진 탐지 0% → 42 − floor(거리 / 25) ---
	var s := _sim([F.def("A", 400, 450, [["SHP-01", 10]], true)], [F.def("B", 540, 450, [["SHP-02", 4]], true)])
	var a: FleetState = s.st.fleets[0]
	var b: FleetState = s.st.fleets[1]
	var det: Detection = s.detect
	if not TestCheck.ok(self, det.sensor_of(a) == 42, "센서 합 30 + 지력 12: %d" % det.sensor_of(a)): return
	var cases := [[100.0, 38, 2], [124.9, 38, 2], [125.0, 37, 2], [149.9, 37, 2], [150.0, 36, 2], [300.0, 30, 2], [325.0, 29, 1], [420.0, 26, 1], [525.0, 21, 1], [650.0, 16, 1], [675.0, 15, 1], [700.0, 14, 0]]
	for c in cases:
		b.pos = Vector2(400.0 + c[0], 450.0)
		var sc := det.score(det.sensor_of(a), a, b)
		if not TestCheck.ok(self, sc == c[1] and det.level_of(sc) == (2 if sc >= int(D.confirmed) else (1 if sc >= int(D.estimated) else 0)), "거리 %.1f 점수 %d(기대 %d) 등급 %d" % [c[0], sc, c[1], det.level_of(sc)]): return
	# 진형 탐지%: FRM-04(탐지 +5%)는 센서 합에 곱한다(half-up). 30 × 1.05 = 31.5 → 32
	var frm_bp := -1
	var frm_id := ""
	for fid in full.formations:
		if int(full.formations[fid].detection_bp) == 500:
			frm_bp = 500
			frm_id = fid
	if not TestCheck.ok(self, frm_bp == 500, "탐지 +5% 진형이 데이터에 있다"): return
	var s2 := _sim([F.def("A", 400, 450, [["SHP-01", 10]], true, frm_id)], [F.def("B", 800, 450, [["SHP-02", 4]], true)])
	if not TestCheck.ok(self, s2.detect.sensor_of(s2.st.fleets[0]) == 32 + 12, "진형 탐지 +5%%: %d" % s2.detect.sensor_of(s2.st.fleets[0])): return
	# 전자전: 표적의 전자전 점수를 뺀다. 호위함 1척당 −1
	var s3 := _sim([F.def("A", 400, 450, [["SHP-01", 10]], true)], [F.def("B", 500, 450, [["SHP-01", 5]], true)])
	var sc3 := s3.detect.score(s3.detect.sensor_of(s3.st.fleets[0]), s3.st.fleets[0], s3.st.fleets[1])
	if not TestCheck.ok(self, s3.detect.ew_of(s3.st.fleets[1]) == 5 and sc3 == 42 - 5 - 4, "표적 전자전 5: 점수 %d" % sc3): return

	# --- 2. 접촉 4상태: 확인 → (놓침) 추정, 신뢰도 감쇠, 상실, 기억 끝 ---
	s = _sim([F.def("A", 400, 450, [["SHP-01", 10]], true)], [F.def("B", 500, 450, [["SHP-02", 4]], true)])
	a = s.st.fleets[0]
	b = s.st.fleets[1]
	_sec(s, 2.0)
	if not TestCheck.ok(self, s.detect.state(0, b.id) == "confirmed" and s.detect.hit_mul_bp(0, b.id) == BattleRules.BP, "가까우면 확인"): return
	b.pos = Vector2(1500, 450)
	var conf0: int = s.detect._conf0
	var t0 := s.st.tick
	var marks := [[30.0, "estimated", 0], [70.0, "estimated", 1], [170.0, "estimated", 2], [190.0, "lost", -1], [250.0, "", -1]]
	for m in marks:
		while s.st.tick < t0 + int(float(m[0]) * s.st.hz):
			s.step()
			s.drain_events()
		var r := s.detect.rec(0, b.id)
		var got := str(r.get("state", ""))
		if not TestCheck.ok(self, got == m[1], "%.0f초 뒤 상태 '%s'(기대 '%s')" % [m[0], got, m[1]]): return
		if m[2] >= 0:
			if not TestCheck.ok(self, int(r.conf_bp) == maxi(int(D.confidence_min_bp), conf0 - int(D.confidence_loss_bp_per_turn) * int(m[2])) and is_equal_approx(float(r.err_r), float(D.error_radius) + float(D.error_radius_per_turn) * int(m[2])), "%.0f초 뒤 신뢰도 %d 오차 %f" % [m[0], r.conf_bp, r.err_r]): return
	if not TestCheck.ok(self, not s.detect.can_target(0, b.id), "기억이 끝나면 접촉 없음"): return

	# --- 3. 접촉 사건: 진영 0만 낸다. 확인 → 추정 → 상실 → 없음 ---
	var kinds := []
	s = _sim([F.def("A", 400, 450, [["SHP-01", 10]], true)], [F.def("B", 500, 450, [["SHP-02", 4]], true)])
	b = s.st.fleets[1]
	for i in 2 * s.st.hz:
		s.step()
	b.pos = Vector2(1500, 450)
	for i in 260 * s.st.hz:
		s.step()
	for e in s.drain_events():
		if e.kind == "contact":
			kinds.append(e.value.state)
	if not TestCheck.ok(self, kinds == ["confirmed", "estimated", "lost", "none"], "접촉 사건 순서 %s" % str(kinds)): return

	# --- 4. 사격: 접촉 없는 적은 쏘지 못하고, 추정 접촉은 명중률에 신뢰도를 곱한다 ---
	s = _sim([F.def("A", 400, 450, [["SHP-03", 8]], true)], [F.def("B", 600, 450, [["SHP-04", 4]], true)])
	a = s.st.fleets[0]
	b = s.st.fleets[1]
	var shots := 0
	for i in 130 * s.st.hz:
		s.step()
		for e in s.drain_events():
			if e.kind == "salvo" and e.sq == a.id:
				shots += 1
	if not TestCheck.ok(self, shots == 0 and s.detect.state(0, b.id) == "", "거리 200: 점수 12로 미탐지라 포격 없음 (사격 %d)" % shots): return
	b.pos = Vector2(500, 450)   # 거리 100: 20 − 4 = 16 → 추정
	var acc := -1
	var base := -1
	for i in 130 * s.st.hz:
		s.step()
		for e in s.drain_events():
			if e.kind == "salvo" and e.sq == a.id and acc < 0:
				acc = int(e.value.acc)
				var keep := s.detect
				s.detect = null
				base = s.salvo.hit_bp(a, b, str(e.value.cat))
				s.detect = keep
		if acc >= 0:
			break
	if not TestCheck.ok(self, acc > 0 and acc == base * s.detect._conf0 / BattleRules.BP and acc < base, "추정 사격 명중 %d = 기본 %d × 신뢰도 %d" % [acc, base, s.detect._conf0]): return
	# 접촉 없는 적 지정 거부
	b.pos = Vector2(1500, 450)
	_sec(s, 300.0)
	s.issue(BattleSim.command(0, [a.id], "attack", b.id))
	var why := ""
	for e in s.drain_events():
		if e.kind == "rejected":
			why = str(e.value)
	if not TestCheck.ok(self, why == "no_contact", "미탐지 적 지정은 거부: '%s'" % why): return

	# --- 5. 지형: 이동 비용·센서·은폐·사거리·사격각 ---
	var T := BattleTerrain.new(full.terrain)
	var open_pt := Vector2(300, 600)
	if not TestCheck.ok(self, T.move_cost_bp(open_pt) == BattleRules.BP and T.move_cost_bp(Vector2(650, 100)) == 13333 and T.move_cost_bp(Vector2(700, 150)) == 15385, "이동 비용: 개활 · 성운 · 성운∩잔해 최댓값"): return
	if not TestCheck.ok(self, T.sensor_bp(Vector2(650, 100), -6000, 3000) == -2000 and T.sensor_bp(Vector2(700, 150), -6000, 3000) == -2500 and T.sensor_bp(Vector2(1300, 400), -6000, 3000) == -1500, "센서: 성운 −20%, 겹치면 합 −25%, 그림자 −15%"): return
	if not TestCheck.ok(self, T.sensor_bp(Vector2(700, 150), -2000, 3000) == -2000, "센서 합은 하한으로 자른다"): return
	if not TestCheck.ok(self, T.conceal(Vector2(700, 150)) == 11 and T.conceal(Vector2(1300, 400)) == 12 and T.conceal(open_pt) == 0, "은폐: 합산"): return
	var seg_a := Vector2(500, 160)
	var seg_b := Vector2(900, 160)   # 성운(y 50~170)과 잔해(y 100~220)를 지난다
	if not TestCheck.ok(self, is_equal_approx(T.range_mul(seg_a, seg_b), 0.85 * 0.90) and is_equal_approx(T.arc_delta(seg_a, seg_b), -15.0), "사거리 ×0.85×0.90, 사격각 −15°"): return
	if not TestCheck.ok(self, T.range_mul(Vector2(0, 0), Vector2(100, 0)) == 1.0 and T.arc_delta(Vector2(0, 0), Vector2(100, 0)) == 0.0, "구역 밖 사격선은 영향 없음"): return
	# 관측자가 성운 안: 센서 합 30 × 0.8 = 24, 표적이 성운 안이면 은폐 −8
	s = _sim([F.def("A", 650, 100, [["SHP-01", 10]], true)], [F.def("B", 700, 60, [["SHP-02", 4]], true)])
	a = s.st.fleets[0]
	b = s.st.fleets[1]
	if not TestCheck.ok(self, s.detect.sensor_of(a) == 24 + 12, "성운 안 관측자 센서: %d" % s.detect.sensor_of(a)): return
	if not TestCheck.ok(self, s.detect.score(s.detect.sensor_of(a), a, b) == 36 - floori(a.pos.distance_to(b.pos) / 25.0) - 8, "성운 안 표적 은폐 −8"): return
	# 이동: 성운 안은 ×0.75
	s = _sim([F.def("A1", 610, 100, [["SHP-04", 6]], true), F.def("A2", 300, 600, [["SHP-04", 6]])], [F.def("F1", 1500, 100, [["SHP-04", 2]], true), F.def("F2", 1500, 600, [["SHP-04", 2]])])
	var p1: Vector2 = s.st.fleets[0].pos
	var p2: Vector2 = s.st.fleets[1].pos
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "move", -1, Vector2(700, 100)))
	s.issue(BattleSim.command(0, [s.st.fleets[1].id], "move", -1, Vector2(390, 600)))
	_sec(s, 8.0)
	var d1: float = s.st.fleets[0].pos.distance_to(p1)
	var d2: float = s.st.fleets[1].pos.distance_to(p2)
	if not TestCheck.ok(self, d2 > 1.0 and absf(d1 / d2 - 0.75) < 0.02, "성운 안 이동 속도 ×0.75: %f / %f" % [d1, d2]): return
	# 사거리: 포격 260이 성운+잔해를 지나면 199로 줄어 240에서 닿지 못한다
	var lo := F.def("A", 500, 160, [["SHP-03", 6]], true)
	var hi := F.def("B", 740, 160, [["SHP-04", 4]], true)
	var with_t := _sim([lo], [hi], true)
	var without_t := _sim([lo], [hi], false)
	var q_with: Array = with_t.salvo.qualifying(with_t.st.fleets[0], "artillery", with_t.st.fleets[1])
	var q_without: Array = without_t.salvo.qualifying(without_t.st.fleets[0], "artillery", without_t.st.fleets[1])
	if not TestCheck.ok(self, q_without.size() == 1 and q_with.is_empty(), "지형이 사거리를 줄인다 (%d / %d)" % [q_with.size(), q_without.size()]): return

	# --- 6. 적 AI는 접촉만 본다: 접촉이 없으면 표적이 없고, 안개를 끄면 같은 배치에서 표적을 잡는다 ---
	var ai_t := []
	for fog in [true, false]:
		var sa := F.def("A", 200, 450, [["SHP-04", 4]], true)
		var sb := F.def("B", 1500, 100, [["SHP-04", 4]], true)
		var sc := F.def("C", 1200, 450, [["SHP-04", 4]])
		var ss: BattleSim = _sim([sa], [sb, sc]) if fog else F.sim([sa], [sb, sc])
		ss.st.ai_timer = 0
		var c0: Vector2 = ss.st.fleets[2].pos
		for i in 6 * ss.st.hz:
			ss.step()
			ss.drain_events()
		ai_t.append(ss.st.fleets[2].target_id)
		if fog:
			ai_t.append(ss.st.fleets[2].pos.x < c0.x and ss.st.fleets[2].pos.y > c0.y)   # 접촉이 없으면 정찰 전진(-x, +y)
	if not TestCheck.ok(self, ai_t[0] == -1 and ai_t[1] and ai_t[2] >= 0, "AI 표적: 안개 %d(기대 -1) 전진 %s, 완전 정보 %d(기대 0 이상)" % [ai_t[0], str(ai_t[1]), ai_t[2]]): return

	# --- 7. 사건 경계: 미탐지 적의 명령 사건은 화면용 사건에서 빠진다 ---
	s = _sim([F.def("A", 200, 450, [["SHP-04", 4]], true)], [F.def("B", 1200, 450, [["SHP-04", 4]], true)])
	var foe_id: int = s.st.fleets[1].id
	s.issue(BattleSim.command(1, [foe_id], "stop"))
	var raw := s.drain_events()
	if not TestCheck.ok(self, raw.any(func(e): return e.kind == "say" and e.sq == foe_id), "원 사건에는 적의 명령이 있다"): return
	s.issue(BattleSim.command(1, [foe_id], "stop"))
	var pub := s.drain_events_for(0)
	if not TestCheck.ok(self, not pub.any(func(e): return e.sq == foe_id or e.other == foe_id), "화면용 사건에 미탐지 적 없음"): return

	# --- 8. 공개 투영: 적벽 표준 한 판에서 적 항목은 접촉만, 줄인 형태 ---
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	var sim := BattleSim.new(7, BattleRules.TICK_HZ, p)
	var seen_hidden := 0
	var seen_conf := 0
	var seen_est := 0
	var checked := 0
	for i in 600 * sim.st.hz:
		if i % (10 * sim.st.hz) == 0:
			for side in 2:
				var pr := sim.projection(side)
				var foes_alive := sim.st.alive(1 - side).size()
				var n_foe := 0
				for q in pr.squadrons:
					if q.side == side:
						continue
					n_foe += 1
					var known: Dictionary = sim.detect.contacts[side].get(q.id, {})
					if not TestCheck.ok(self, not known.is_empty() and q.contact == known.state, "투영의 적은 접촉표에 있다: %d" % q.id): return
					for k in ["ships_milli", "hull", "morale_bp", "counts", "target_id", "formation_id", "ammo", "heat_milli", "energy_milli", "max_ships_milli", "dead"]:
						if not TestCheck.ok(self, not q.has(k), "적 접촉 항목에 %s 없음" % k): return
					if q.contact != "confirmed":
						if not TestCheck.ok(self, not q.has("name") and not q.has("strength_band"), "추정·상실 접촉은 이름·전력 구간 없음"): return
						seen_est += 1
					else:
						seen_conf += 1
				if foes_alive > n_foe:
					seen_hidden += 1
				checked += 1
		sim.step()
		sim.drain_events()
	if not TestCheck.ok(self, checked > 0 and seen_hidden > 0 and seen_conf > 0 and seen_est > 0, "투영 검사가 의미 있게 돌았다(가려진 판 %d, 확인 %d, 추정 %d)" % [seen_hidden, seen_conf, seen_est]): return
	var pr0 := BattleSim.new(7, BattleRules.TICK_HZ, p).projection(0)
	if not TestCheck.ok(self, pr0.squadrons.all(func(q): return q.side == 0), "첫 틱 전: 적 항목 0건"): return

	# --- 9. 지문: 같은 시드는 접촉까지 같고, 접촉이 지문에 들어 있다 ---
	var s_a := BattleSim.new(3, BattleRules.TICK_HZ, p)
	var s_b := BattleSim.new(3, BattleRules.TICK_HZ, p)
	for i in 300 * s_a.st.hz:
		s_a.step()
		s_b.step()
	s_a.drain_events()
	s_b.drain_events()
	if not TestCheck.ok(self, s_a.fingerprint() == s_b.fingerprint(), "같은 시드 지문 일치"): return
	var fp := s_a.fingerprint()
	var any_side := -1
	for sd in 2:
		if not s_a.detect.contacts[sd].is_empty():
			any_side = sd
	if not TestCheck.ok(self, any_side >= 0, "300초에는 접촉이 있다"): return
	var key: Variant = s_a.detect.contacts[any_side].keys()[0]
	s_a.detect.contacts[any_side].erase(key)
	if not TestCheck.ok(self, s_a.fingerprint() != fp, "지문이 접촉을 포함"): return
	print("DETECTION_RULES_PASS")
	quit(0)
