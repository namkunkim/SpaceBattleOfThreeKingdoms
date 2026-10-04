extends SceneTree

# M3 사격·피해 규칙 테스트(제안서 §9 M3 완료 기준). 헤드리스, 실패하면 종료 코드 1.
#  1. 포격함 전대는 멀리서 이기고 가까이서 진다(거리대, 사거리, 함종 카운터)
#  2. 후면 피격 명중률이 정면보다 +25%p(방향 구간, 경계값)
#  3. 사격 주기·자원·손상 단계·손실 배분·결정론·재생

func _initialize() -> void:
	call_deferred("_run")

func _winner_side0(s: BattleSim) -> bool:
	return s.st.over and s.st.win

func _run() -> void:
	var F := SalvoFixture
	# --- 0. 데이터: combat_m3.json이 본편 스냅숏(data/scenarios/base/)과 같은 값이다 ---
	var cb := F.combat()
	var ships: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/base/ship-types.json"))
	for st in ships:
		var ph: Dictionary = st.phase_coefficients
		var mine: Dictionary = cb.ship_types[st.id].phase
		for k in ph:
			if not TestCheck.ok(self, is_equal_approx(float(ph[k]) if ph[k] != null else 0.0, float(mine[k])), "거리대 계수 %s.%s" % [st.id, k]): return
	var frms: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/base/formations.json"))
	for fr in frms:
		if not TestCheck.ok(self, is_equal_approx(float(fr.coefficients.engagement), float(cb.formations[fr.id].phase.engagement)), "진형 계수 %s" % fr.id): return
	if not TestCheck.ok(self, cb.weapons.artillery.platforms["SHP-03"].range == 260.0 and cb.weapons.line_fire.platforms["SHP-04"].range == 180.0 and cb.weapons.torpedo.equipment["FAST-EQ-TORPEDO"].arc_deg == 70.0, "사거리·사격각"): return
	# 적벽 프로필이 salvo 규칙으로 돈다: 모든 편성 함종·진형이 데이터에 있다
	var rp := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "상급")
	for d in rp.ally + rp.foe:
		if not TestCheck.ok(self, cb.formations.has(d.formation_id), "진형 없음 " + d.formation_id): return
		for c in d.composition:
			if not TestCheck.ok(self, cb.ship_types.has(c.ship_type_id), "함종 없음"): return
	var rs0 := BattleSim.new(1, BattleRules.TICK_HZ, rp)
	if not TestCheck.ok(self, rs0.salvo != null and rs0.st.fleets[0].max_hull > 0, "적벽 프로필은 salvo 규칙"): return
	# 조조 중군: 척 수·선체(비용 × 10, 고속정 장비 제외)
	var cao: FleetState = null
	for f in rs0.st.fleets:
		if f.sq_id == "RC-CAO-SQ-01":
			cao = f
	if not TestCheck.ok(self, cao != null and cao.ships == 26 * 1000 and cao.max_hull == (2 * 18 + 4 * 12 + 8 * 10 + 2 * 8 + 2 * 9 + 2 * 7 + 6 * 2) * 10 and cao.equip == "FAST-EQ-INTERCEPT", "조조 중군 선체 %d" % cao.max_hull): return
	if not TestCheck.ok(self, is_equal_approx(cao.speed, 70.0 / 60.0 * 1.0) , "조조 중군 속도(보급함 70/턴, 안행진 0%%) %f" % cao.speed): return
	var pr := rs0.projection(0)
	if not TestCheck.ok(self, pr.squadrons[0].counts.size() > 0 and pr.squadrons[0].hull == pr.squadrons[0].max_hull, "투영 counts·hull"): return
	# --- 1. 거리에 따른 승패 ---
	var far_wins := 0
	var near_wins := 0
	var runs := 30
	for sd in runs:
		var far := F.sim([F.def("포격", 400, 450, [["SHP-03", 8]], true)], [F.def("전열", 630, 450, [["SHP-04", 8]])], sd)
		F.run(far, 900.0)
		if _winner_side0(far):
			far_wins += 1
		var near := F.sim([F.def("포격", 400, 450, [["SHP-03", 8]], true)], [F.def("전열", 500, 450, [["SHP-04", 8]])], sd)
		F.run(near, 900.0)
		if _winner_side0(near):
			near_wins += 1
	if not TestCheck.ok(self, far_wins == runs, "포격함이 멀리서(230)는 항상 이긴다: %d/%d" % [far_wins, runs]): return
	if not TestCheck.ok(self, near_wins <= runs / 3, "포격함이 가까이서(100)는 대부분 진다: 포격 승 %d/%d" % [near_wins, runs]): return
	# 멀리서는 사거리 밖인 전열함이 한 발도 쏘지 못한다
	var fs := F.sim([F.def("포격", 400, 450, [["SHP-03", 8]], true)], [F.def("전열", 630, 450, [["SHP-04", 8]])], 3)
	var foe_shots := 0
	var own_shots := 0
	while not fs.st.over and fs.st.tick < 9000:
		fs.step()
		for e in fs.drain_events():
			if e.kind == "salvo":
				if e.sq == fs.st.fleets[1].id:
					foe_shots += 1
				else:
					own_shots += 1
	if not TestCheck.ok(self, foe_shots == 0 and own_shots > 0, "사거리 밖 전열함은 쏘지 못한다: 전열 %d, 포격 %d" % [foe_shots, own_shots]): return

	# --- 2. 방향 구간과 명중률 ---
	var h := F.sim([F.def("사수", 0, 0, [["SHP-04", 4]], true)], [F.def("표적", 100, 0, [["SHP-04", 4]])], 1)
	var shooter: FleetState = h.st.fleets[0]
	var tgt: FleetState = h.st.fleets[1]
	tgt.heading = 0.0
	var sal := h.salvo
	var at := func(deg: float) -> Vector2:
		return tgt.pos + Vector2.from_angle(deg_to_rad(deg)) * 100.0
	if not TestCheck.ok(self, sal.sector(at.call(0.0), tgt) == "front" and sal.sector(at.call(60.0), tgt) == "front", "정면 경계 60° 포함"): return
	if not TestCheck.ok(self, sal.sector(at.call(60.5), tgt) == "flank" and sal.sector(at.call(90.0), tgt) == "flank" and sal.sector(at.call(119.5), tgt) == "flank", "측면"): return
	if not TestCheck.ok(self, sal.sector(at.call(120.0), tgt) == "rear" and sal.sector(at.call(180.0), tgt) == "rear", "후면 경계 120° 포함"): return
	shooter.pos = at.call(0.0)
	var front_bp: int = sal.hit_bp(shooter, tgt, "artillery")
	shooter.pos = at.call(90.0)
	var flank_bp: int = sal.hit_bp(shooter, tgt, "artillery")
	shooter.pos = at.call(180.0)
	var rear_bp: int = sal.hit_bp(shooter, tgt, "artillery")
	if not TestCheck.ok(self, rear_bp - front_bp == 2500, "후면 명중률 +25%%p: 정면 %d 후면 %d" % [front_bp, rear_bp]): return
	if not TestCheck.ok(self, flank_bp - front_bp == 1000, "측면 +10%%p: 정면 %d 측면 %d" % [front_bp, flank_bp]): return
	# 방어가 높은 진형(방원진 +15%)을 상대로도 같은 +25%p가 나온다(상한 9500에 걸리지 않는 조건)
	tgt.formation_id = "FRM-03"
	shooter.formation_id = "FRM-06"   # 화력 −5%
	shooter.pos = at.call(0.0)
	var f2: int = sal.hit_bp(shooter, tgt, "line_fire")
	shooter.pos = at.call(180.0)
	var r2: int = sal.hit_bp(shooter, tgt, "line_fire")
	if not TestCheck.ok(self, r2 - f2 == 2500, "방원진 상대 후면 +25%%p: %d %d" % [f2, r2]): return
	# 지휘 범위 밖은 −10%p
	shooter.in_cmd = false
	if not TestCheck.ok(self, sal.hit_bp(shooter, tgt, "line_fire") == r2 - 1000, "지휘 범위 밖 −10%p"): return

	# --- 3. 사격 주기와 자원 ---
	var pc := F.sim([F.def("포격", 400, 450, [["SHP-03", 4]], true)], [F.def("표적", 640, 450, [["SHP-04", 40]])], 5)
	var vol := []
	for i in 3600:
		pc.step()
		for e in pc.drain_events():
			if e.kind == "salvo" and e.sq == pc.st.fleets[0].id:
				vol.append(e.tick)
	if not TestCheck.ok(self, vol.size() >= 3, "일제사격이 반복된다: %s" % str(vol)): return
	for i in range(1, vol.size()):
		if not TestCheck.ok(self, vol[i] - vol[i - 1] == 600, "주기 60초(600틱): %s" % str(vol)): return
	var pf: FleetState = pc.st.fleets[0]
	# 포격 4척: 탄약 24, 1회 탄 1·에너지 5·열 25
	if not TestCheck.ok(self, pf.ammo["artillery"] == 24 - vol.size(), "탄약 소모 %d" % pf.ammo["artillery"]): return
	# 열이 모자라면 보류하고 사유를 낸다
	var hs := F.sim([F.def("포격", 400, 450, [["SHP-03", 4]], true)], [F.def("표적", 640, 450, [["SHP-04", 40]])], 5)
	hs.st.fleets[0].heat_m = 1 << 30
	var supp := ""
	for i in 1500:
		hs.step()
		for e in hs.drain_events():
			if e.kind == "suppressed" and e.sq == hs.st.fleets[0].id:
				supp = e.value.reason
	if not TestCheck.ok(self, supp == "overheat", "과열 보류 사유: '%s'" % supp): return
	# 강습모함의 함재기 출격
	var cr := F.sim([F.def("모함", 400, 450, [["SHP-01", 1]], true)], [F.def("표적", 550, 450, [["SHP-05", 10]])], 5)
	var cf: FleetState = cr.st.fleets[0]
	if not TestCheck.ok(self, cf.sorties_m == 4000, "강습모함 1척 = 출격 4회"): return
	cf.sorties_m = 0
	var sup2 := ""
	for i in 300:
		cr.step()
		for e in cr.drain_events():
			if e.kind == "suppressed" and e.sq == cf.id:
				sup2 = e.value.reason
	if not TestCheck.ok(self, sup2 == "carrier_not_returned", "함재기 미복귀 사유: '%s'" % sup2): return

	# --- 4. 손실 배분과 손상 단계 ---
	var ds := F.sim([F.def("표적", 400, 450, [["SHP-04", 6], ["SHP-07", 4], ["SHP-03", 4], ["SHP-05", 3], ["SHP-01", 2]], true)], [F.def("적", 560, 450, [["SHP-04", 10]])], 1)
	var vt: FleetState = ds.st.fleets[0]
	var before := ds.salvo.total0(vt)
	ds.salvo.apply_hull(ds.st.fleets[1], vt, 600.0, "engagement", "front", 7)
	var gone := 0
	for t in vt.stages:
		gone += vt.stages[t][3] + vt.stages[t][4]
	if not TestCheck.ok(self, gone == vt.lost_ships and gone == before * 600 / vt.max_hull, "손실 척 수 = floor(원래 × 누적 / 최대): %d" % gone): return
	# 정면 피격은 노출 함종(전열함)에서 먼저 나간다(어린진: 정면 전열)
	if not TestCheck.ok(self, vt.stages["SHP-04"][3] + vt.stages["SHP-04"][4] >= gone * 1 / 2, "정면 손실은 전열함 중심: %s" % str(vt.stages)): return
	# 단조: 같은 피해를 더 받아도 손실 척 수가 줄지 않는다
	var lost0 := vt.lost_ships
	ds.salvo.apply_hull(ds.st.fleets[1], vt, 100.0, "engagement", "front", 8)
	if not TestCheck.ok(self, vt.lost_ships >= lost0, "손실 단조"): return
	# 7500bp 아래면 남은 함선의 25%가 중파 이상이다
	var ratio := vt.hull * 10000 / vt.max_hull
	var surv := ds.salvo.present_ships(vt)
	var mod := 0
	for t in vt.stages:
		mod += vt.stages[t][2]
	if ratio < 7500:
		if not TestCheck.ok(self, mod >= surv * 25 / 100, "선체 %dbp: 중파 %d / 생존 %d" % [ratio, mod, surv]): return
	# 선체와 척 수가 서로 맞는다
	if not TestCheck.ok(self, vt.ships == vt.max_ships * vt.hull / vt.max_hull, "척 수는 선체 비례"): return

	# --- 5. 결정론과 재생 ---
	var a := F.sim([F.def("포격", 400, 450, [["SHP-03", 5], ["SHP-04", 6], ["SHP-07", 2]], true)], [F.def("전열", 560, 450, [["SHP-04", 10], ["SHP-03", 3]])], 9)
	var b := F.sim([F.def("포격", 400, 450, [["SHP-03", 5], ["SHP-04", 6], ["SHP-07", 2]], true)], [F.def("전열", 560, 450, [["SHP-04", 10], ["SHP-03", 3]])], 9)
	F.run(a, 400.0)
	F.run(b, 400.0)
	if not TestCheck.ok(self, a.fingerprint() == b.fingerprint() and a.st.tick == b.st.tick, "같은 시드 같은 지문"): return
	var c := F.sim([F.def("포격", 400, 450, [["SHP-03", 5], ["SHP-04", 6], ["SHP-07", 2]], true)], [F.def("전열", 560, 450, [["SHP-04", 10], ["SHP-03", 3]])], 10)
	F.run(c, 400.0)
	if not TestCheck.ok(self, a.fingerprint() != c.fingerprint(), "다른 시드는 다른 지문"): return
	print("SALVO_RULES_PASS far=%d/%d near=%d/%d rear+%d" % [far_wins, runs, near_wins, runs, rear_bp - front_bp])
	quit(0)
