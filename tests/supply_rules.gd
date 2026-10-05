extends SceneTree

# M8 완료 기준(제안서 §4.13, §9): 보급 영역에 60초 정지하면 탄약 전량 보충, 중간에 벗어나면 완료 안 됨,
# 처리량(보급함 1척당 1개 전대, 선체 구간 100/50/25%), 처리 순서, 재고(전량 보충만·물자 1·이탈 시 손실),
# 기지(반경 180·동시 4·연합 보급·같은 세력 재적재), 적은 받지 않음, 수리(중파 → 경파, 경파 120초 무피격 → 무손상),
# 공개 투영(자기 진영 공급원만), 결정론(지문에 보급 상태). 헤드리스, 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _sec(s: BattleSim, n: float) -> void:
	for i in roundi(n * s.st.hz):
		s.step()

func _ticks(s: BattleSim, n: int) -> void:
	for i in n:
		s.step()

# 보급을 켠 소규모 전장(규칙은 실제 데이터). AI·안개·지형은 꺼져 있다. 적 한 전대는 사거리 밖 멀리 둔다.
func _sim(ally: Array, foe: Array = []) -> BattleSim:
	var full := SalvoFixture.combat()
	if foe.is_empty():
		foe = [_d("Z", 1500, 850, [["SHP-04", 1]], "cao_cao")]
	return SalvoFixture.sim(ally, foe, 1, "", func(cb): cb.supply = full.supply)

func _d(name: String, x: float, y: float, comp: Array, faction := "liu_bei", flag := false) -> Dictionary:
	var d := SalvoFixture.def(name, x, y, comp, flag)
	d.faction_id = faction
	return d

func _empty(f: FleetState) -> void:
	for cat in f.ammo:
		f.ammo[cat] = 0

func _full(sup: SupplyCore, f: FleetState) -> bool:
	return sup.deficit(f) == 0

func _count(evs: Array, kind: String, sq := -1) -> int:
	return evs.filter(func(e): return e.kind == kind and (sq < 0 or e.sq == sq)).size()

func _run() -> void:
	var full := SalvoFixture.combat()
	var S: Dictionary = full.supply
	if not TestCheck.ok(self, str(S.status).begins_with("proposed") and int(S.ship_radius) == 140 and int(S.base_radius) == 180 and int(S.stationary_s) == 60, "데이터: 반경 140·180, 60초, 제안값 표시"): return

	# --- 1. 완료 기준: 보급 영역(반경 140) 안에 60초 정지하면 탄약 전량 보충. 재고에서 탄약 단위와 물자 1을 쓴다 ---
	var s := _sim([_d("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], "liu_bei", true), _d("A", 925, 450, [["SHP-03", 2]])])
	var sup := s.supply
	var sf: FleetState = s.st.fleets[0]
	var a: FleetState = s.st.fleets[1]
	if not TestCheck.ok(self, sup != null and sf.sup_ammo == 24 and sf.sup_mat == 8, "보급함 2척 재고 탄약 24·물자 4×2: %d/%d" % [sf.sup_ammo, sf.sup_mat]): return
	_empty(a)
	var need := sup.deficit(a)
	if not TestCheck.ok(self, need == 12, "포격함 2척 탄약 상한 12: %d" % need): return
	_ticks(s, 599)
	if not TestCheck.ok(self, sup.deficit(a) == need and a.sup_src == "f%d" % sf.id, "59.9초: 아직 보충 전, 배정은 보급함 전대(%s)" % a.sup_src): return
	s.drain_events()
	_ticks(s, 1)
	var evs := s.drain_events()
	if not TestCheck.ok(self, _full(sup, a), "60초: 탄약 전량 보충"): return
	if not TestCheck.ok(self, sf.sup_ammo == 24 - need and sf.sup_mat == 7, "재고 차감: 탄약 %d 물자 %d" % [sf.sup_ammo, sf.sup_mat]): return
	var se: Array = evs.filter(func(e): return e.kind == "supply" and e.sq == a.id)
	if not TestCheck.ok(self, se.size() == 1 and se[0].other == sf.id and int(se[0].value.ammo) == need, "supply 사건 1건"): return
	_ticks(s, 5)
	if not TestCheck.ok(self, a.sup_src == "", "받을 것이 없으면 배정이 풀린다"): return

	# --- 2. 중간에 벗어나면 완료되지 않는다(진행 0) ---
	s = _sim([_d("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], "liu_bei", true), _d("A", 925, 450, [["SHP-03", 2]])])
	a = s.st.fleets[1]
	_empty(a)
	_sec(s, 30)
	if not TestCheck.ok(self, a.sup_prog > 0, "30초: 진행 중"): return
	s.issue(BattleSim.command(0, [a.id], "move", -1, Vector2(1200, 450)))
	_sec(s, 31)
	if not TestCheck.ok(self, a.sup_prog == 0 and a.sup_src == "" and s.supply.deficit(a) == 12, "움직이면 진행 0, 보충 안 됨"): return
	# 영역 밖에 정지해 있으면 받지 않는다
	_sec(s, 60)
	if not TestCheck.ok(self, s.supply.deficit(a) == 12 and a.pos.distance_to(s.st.fleets[0].pos) > 140.0, "반경 밖 정지: 보충 안 됨"): return

	# --- 3. 처리량: 보급함 1척 = 동시 1개 전대. 순서는 남은 탄약 비율이 낮은 전대부터 ---
	s = _sim([_d("S", 800, 450, [["SHP-05", 1], ["SHP-04", 2]], "liu_bei", true), _d("B", 925, 450, [["SHP-03", 2]]), _d("C", 800, 575, [["SHP-03", 2]])])
	sup = s.supply
	sf = s.st.fleets[0]
	var b: FleetState = s.st.fleets[1]
	var c: FleetState = s.st.fleets[2]
	b.ammo.artillery = 9    # 75%
	c.ammo.artillery = 6    # 50% → 먼저
	_ticks(s, 600)
	if not TestCheck.ok(self, _full(sup, c) and not _full(sup, b), "60초: 비율이 낮은 C만 끝남"): return
	_ticks(s, 600)
	if not TestCheck.ok(self, _full(sup, b), "120초: 다음 차례 B"): return
	if not TestCheck.ok(self, sf.sup_ammo == 12 - 6 - 3 and sf.sup_mat == 2, "재고 탄약 3·물자 2: %d/%d" % [sf.sup_ammo, sf.sup_mat]): return
	# 재고가 모자라면 시작하지 않는다(전량 보충만, 원자적)
	_empty(b)
	_sec(s, 70)
	if not TestCheck.ok(self, sup.deficit(b) == 12 and b.sup_src == "" and sf.sup_ammo == 3, "재고 3 < 12: 보충 안 함"): return

	# --- 4. 보급함 전대의 선체 구간이 처리량을 줄인다: 50% → 120초 ---
	s = _sim([_d("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], "liu_bei", true), _d("A", 925, 450, [["SHP-03", 2]])])
	sup = s.supply
	sf = s.st.fleets[0]
	a = s.st.fleets[1]
	sf.hull = sf.max_hull * 6000 / 10000
	if not TestCheck.ok(self, sup.rate_of(sf) == 5000, "선체 60%: 처리량 50%"): return
	sf.hull = sf.max_hull * 3000 / 10000
	if not TestCheck.ok(self, sup.rate_of(sf) == 2500, "선체 30%: 처리량 25%"): return
	sf.hull = sf.max_hull * 6000 / 10000
	_empty(a)
	_ticks(s, 1199)
	if not TestCheck.ok(self, not _full(sup, a), "119.9초: 아직"): return
	_ticks(s, 1)
	if not TestCheck.ok(self, _full(sup, a), "120초: 보충"): return

	# --- 5. 보급함 이탈: 재고 floor(재고 × (N − d) / N). 0척이면 공급원이 사라진다 ---
	s = _sim([_d("S", 800, 450, [["SHP-05", 3], ["SHP-04", 2]], "liu_bei", true)])
	sup = s.supply
	sf = s.st.fleets[0]
	sf.sup_ammo = 20
	sf.sup_mat = 7
	sf.stages["SHP-05"][0] -= 1
	sf.stages["SHP-05"][4] += 1
	_ticks(s, 1)
	if not TestCheck.ok(self, sf.sup_ammo == 13 and sf.sup_mat == 4 and sf.sup_n == 2, "3척 중 1척 이탈: 20→13, 7→4 (%d/%d)" % [sf.sup_ammo, sf.sup_mat]): return
	sf.stages["SHP-05"][0] -= 2
	sf.stages["SHP-05"][3] += 2
	_ticks(s, 1)
	if not TestCheck.ok(self, sf.sup_ammo == 0 and not sup.sources().any(func(x): return x.key == "f%d" % sf.id), "보급함 0척: 재고 0, 공급원 없음"): return

	# --- 6. 기지: 반경 180, 동시 4개 전대, 연합(유비·손권) 보급, 적(조조)은 받지 않음, 재고 무한 ---
	var sun_base := Vector2(300, 440)
	var defs := []
	for i in 5:
		var ang := TAU * i / 5.0
		defs.append(_d("L%d" % i, sun_base.x + 150.0 * cos(ang), sun_base.y + 150.0 * sin(ang), [["SHP-03", 2]], "liu_bei", i == 0))
	s = _sim(defs, [_d("Y", 60, 850, [["SHP-03", 2]], "cao_cao")])
	sup = s.supply
	for f in s.st.fleets:
		_empty(f)
	_ticks(s, 600)
	var done := 0
	for i in 5:
		if _full(sup, s.st.fleets[i]):
			done += 1
	if not TestCheck.ok(self, done == 4, "손권 기지가 유비 전대 4개를 60초에 보충: %d" % done): return
	_ticks(s, 600)
	done = 0
	for i in 5:
		if _full(sup, s.st.fleets[i]):
			done += 1
	var y: FleetState = s.st.fleets[5]
	if not TestCheck.ok(self, done == 5, "다섯째는 120초에"): return
	if not TestCheck.ok(self, sup.deficit(y) == 12 and y.pos.distance_to(Vector2(120, 780)) < 180.0, "유비 기지 반경 안의 조조 전대는 받지 않는다"): return

	# 같은 세력 기지에서만 보급함 재고를 다시 채운다
	s = _sim([_d("Sx", 170, 780, [["SHP-05", 1]], "liu_bei", true), _d("Sy", 120, 655, [["SHP-05", 1]], "sun_quan")])
	var sx: FleetState = s.st.fleets[0]
	var sy: FleetState = s.st.fleets[1]
	sx.sup_ammo = 0
	sy.sup_ammo = 0
	_sec(s, 61)
	if not TestCheck.ok(self, sx.sup_ammo == 12 and sx.sup_mat == 4 and sy.sup_ammo == 0, "유비 기지: 유비 보급함 재적재, 손권 보급함은 아님(%d, %d)" % [sx.sup_ammo, sy.sup_ammo]): return

	# --- 7. 적 보급함은 보급하지 않는다 ---
	s = _sim([_d("A", 800, 450, [["SHP-03", 2]], "liu_bei", true)], [_d("Q", 1300, 450, [["SHP-05", 2]], "cao_cao"), _d("P", 1300, 575, [["SHP-03", 2]], "cao_cao")])
	a = s.st.fleets[0]
	var p: FleetState = s.st.fleets[2]
	_empty(a)
	_empty(p)
	_sec(s, 61)
	if not TestCheck.ok(self, s.supply.deficit(a) == 12 and _full(s.supply, p), "조조 보급함은 조조 전대만"): return

	# --- 8. 수리: 주기마다 물자 1로 중파 1척 → 경파. 경파는 마지막 피격 뒤 120초면 무손상 ---
	s = _sim([_d("S", 800, 450, [["SHP-05", 1], ["SHP-04", 2]], "liu_bei", true), _d("R", 925, 450, [["SHP-04", 4]])])
	sup = s.supply
	sf = s.st.fleets[0]
	var r: FleetState = s.st.fleets[1]
	r.stages["SHP-04"] = [2, 0, 2, 0, 0]
	r.hit_tick = 1 << 30   # 경파 회복은 따로 본다
	_ticks(s, 600)
	if not TestCheck.ok(self, r.stages["SHP-04"] == [2, 1, 1, 0, 0] and sf.sup_mat == 3, "60초: 중파 1척 → 경파, 물자 1 (%s, %d)" % [str(r.stages["SHP-04"]), sf.sup_mat]): return
	_ticks(s, 600)
	if not TestCheck.ok(self, r.stages["SHP-04"] == [2, 2, 0, 0, 0] and sf.sup_mat == 2, "120초: 둘째 중파"): return
	_ticks(s, 5)
	if not TestCheck.ok(self, r.sup_src == "", "중파가 없으면 배정이 풀린다"): return
	# 대파·격침은 고치지 않는다
	r.stages["SHP-04"] = [2, 0, 0, 1, 1]
	_sec(s, 61)
	if not TestCheck.ok(self, r.stages["SHP-04"] == [2, 0, 0, 1, 1], "대파·격침 수리 없음"): return
	# 경파 회복: 피격 뒤 120초. 중간 피격이 시계를 다시 건다
	r.stages["SHP-04"] = [1, 3, 0, 0, 0]
	r.hit_tick = s.st.tick
	_sec(s, 60)
	r.hit_tick = s.st.tick   # 60초에 다시 맞음
	_ticks(s, 1199)
	if not TestCheck.ok(self, r.stages["SHP-04"] == [1, 3, 0, 0, 0], "다시 맞은 뒤 119.9초: 경파 그대로"): return
	s.drain_events()
	_ticks(s, 1)
	if not TestCheck.ok(self, r.stages["SHP-04"] == [4, 0, 0, 0, 0] and _count(s.drain_events(), "light_recovered", r.id) == 1, "120초 무피격: 경파 3척 → 무손상"): return

	# 회복·수리는 다음 작은 피격에 사라지지 않는다(REVIEW-M8 F-1). 선체는 그대로, 되찾은 척 수만 목표에서 뺀다. 선체 50%: 하한 문턱(75·40%)에서 멀다
	s = _sim([_d("S", 800, 450, [["SHP-05", 1], ["SHP-04", 2]], "liu_bei", true), _d("R", 925, 450, [["SHP-04", 20]])])
	r = s.st.fleets[1]
	s.salvo.apply_hull(null, r, r.max_hull * 0.5, "engagement", "front", s.st.new_event_id())
	r.hit_tick = s.st.tick
	var hull0 := r.hull
	var mod0 := s.salvo._stage_sum(r, 2)
	_sec(s, 121)
	var intact := s.salvo._stage_sum(r, 0)
	var mod1 := s.salvo._stage_sum(r, 2)
	if not TestCheck.ok(self, r.hull == hull0 and s.salvo._stage_sum(r, 1) == 0 and mod1 < mod0 and r.healed_wound > 0 and r.healed_mod > 0, "회복·수리: 선체 그대로, 경파 0, 중파 %d → %d" % [mod0, mod1]): return
	s.salvo.apply_hull(null, r, maxf(1.0, r.max_hull * 0.009), "engagement", "front", s.st.new_event_id())
	var intact2 := s.salvo._stage_sum(r, 0)
	if not TestCheck.ok(self, intact2 >= intact - 1 and s.salvo._stage_sum(r, 2) <= mod1 + 1, "선체 1%% 미만 피해: 무손상 %d → %d, 중파 %d → %d" % [intact, intact2, mod1, s.salvo._stage_sum(r, 2)]): return

	# 실제 명중이 hit_tick을 남긴다
	s = SalvoFixture.sim([_d("A", 600, 450, [["SHP-03", 6]], "liu_bei", true)], [_d("B", 800, 450, [["SHP-04", 6]], "cao_cao")], 1, "", func(cb): cb.supply = full.supply)
	var last_hit := -1
	var tb: FleetState = s.st.fleets[1]
	for i in 3000:
		s.step()
		for e in s.drain_events():
			if e.kind == "salvo" and e.other == tb.id and e.value.hit:
				last_hit = e.tick
	if not TestCheck.ok(self, last_hit >= 0 and tb.hit_tick == last_hit, "명중 틱 기록: %d == %d" % [tb.hit_tick, last_hit]): return

	# --- 9. 적벽 프로필: 보급이 켜지고, 공개 투영은 자기 진영 공급원만 준다(정보 경계) ---
	var prof := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	var rc := BattleSim.new(5, BattleRules.TICK_HZ, prof)
	if not TestCheck.ok(self, rc.supply != null and rc.supply.bases.size() == 3, "적벽: 보급 켜짐, 기지 3"): return
	var cao_base: Dictionary = rc.supply.bases.filter(func(x): return x.faction == "cao_cao")[0]
	if not TestCheck.ok(self, cao_base.side == 1, "조조 기지는 진영 1"): return
	for i in 200 * rc.st.hz:
		rc.step()
		rc.drain_events()
		if i % 50 != 0:
			continue
		for sd in 2:
			var pr := rc.projection(sd)
			for src in pr.supply_sources:
				var fac := str(src.faction_id)
				if not TestCheck.ok(self, (fac == "cao_cao") == (sd == 1), "진영 %d 투영에 남의 공급원(%s)" % [sd, src.key]): return
			for q in pr.squadrons:
				if not TestCheck.ok(self, (q.side == sd) == q.has("supply"), "보급 상태는 자기 전대에만"): return
	# --- 10. 결정론: 같은 시드 지문 일치, 지문에 보급 상태 포함 ---
	var r2 := BattleSim.new(5, BattleRules.TICK_HZ, prof)
	for i in 200 * r2.st.hz:
		r2.step()
		r2.drain_events()
	if not TestCheck.ok(self, rc.fingerprint() == r2.fingerprint(), "같은 시드 지문 일치"): return
	var fp := rc.fingerprint()
	rc.st.fleets[0].sup_prog += 1
	if not TestCheck.ok(self, rc.fingerprint() != fp, "지문이 보급 상태를 포함"): return
	# --- 11. 정지 판정은 초당 값(still_eps_px_s 0.5)이다: 10Hz·20Hz에서 같은 초당 이동이 같은 판정 (REVIEW-M8 F-4) ---
	for hz in [10, 20]:
		for v in [0.4, 0.6]:
			var hs := _sim([_d("H", 800, 450, [["SHP-04", 1]])])
			hs.st.hz = hz
			var hsup := SupplyCore.new(hs, S)
			var hf: FleetState = hs.st.fleets[0]
			hf.pos.x += v / hz
			hsup.step()
			if not TestCheck.ok(self, hf.sup_still == (v < float(S.still_eps_px_s)), "%dHz 초당 %.1fpx: 정지 %s" % [hz, v, hf.sup_still]): return
	print("SUPPLY_RULES_PASS")
	quit(0)
