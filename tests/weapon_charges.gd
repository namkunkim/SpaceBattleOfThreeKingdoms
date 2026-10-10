extends SceneTree

# Q69 무장 자원화: 미사일(포격 범주)·함재기(강습모함 플랫폼)는 탄약 대신 기본 3회로 센다.
#  1. 초기 3/3, 함재기는 강습모함이 있는 함대만 / 2. 자동 사격이 횟수를 쓰고 0이면 멈춘다(탄약·에너지·열은 안 쓴다)
#  3. 버튼 매핑: 함재기 = 함재기 범주만, 미사일 = 포격 범주만(전열·요격·뇌격은 당기지 않는다)
#  4. 거부 사유 사건(횟수 0, 함재기 없음, 사거리 밖) / 5. 보급 레벨별 보충 3/2/1회 / 6. 결정론

func _initialize() -> void:
	call_deferred("_run")

func _rejects(s: BattleSim) -> Array:
	var out := []
	for e in s.drain_events():
		if e.kind == "rejected":
			out.append(e.value)
	return out

func _cmd(s: BattleSim, f: FleetState, kind: String) -> Array:
	s.issue(BattleSim.command(f.side, [f.id], kind))
	return _rejects(s)

func _sup_sim(a_comp: Array) -> BattleSim:
	var full := SalvoFixture.combat()
	var d := SalvoFixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], true)
	d.faction_id = "liu_bei"
	var a := SalvoFixture.def("A", 925, 450, a_comp)
	a.faction_id = "liu_bei"
	var z := SalvoFixture.def("Z", 1500, 850, [["SHP-04", 1]])
	z.faction_id = "cao_cao"
	return SalvoFixture.sim([d, a], [z], 1, "", func(cb): cb.supply = full.supply)

func _run() -> void:
	var F := SalvoFixture
	var cb := F.combat()
	if not TestCheck.ok(self, cb.charges.base == 3 and cb.charges.commands == {"missile": "artillery", "fighter": "fighter"}, "데이터: 기본 3회, 버튼 매핑"): return
	if not TestCheck.ok(self, cb.weapons.fighter.platforms.keys() == ["SHP-01"] and not cb.weapons.line_fire.platforms.has("SHP-01"), "함재기 = SHP-01 플랫폼만, 전열에서 분리"): return

	# --- 1. 초기 횟수 ---
	var s := F.sim([F.def("본대", 400, 450, [["SHP-03", 2], ["SHP-04", 2], ["SHP-01", 1]], true), F.def("무모함", 400, 600, [["SHP-03", 2], ["SHP-04", 2]])], [F.def("적", 1500, 850, [["SHP-04", 1]])], 1)
	var a: FleetState = s.st.fleets[0]
	var b: FleetState = s.st.fleets[1]
	if not TestCheck.ok(self, a.wch == {"artillery": 3, "fighter": 3} and a.wmax == {"artillery": 3, "fighter": 3}, "강습모함 있음: 3/3, 3/3 %s" % str(a.wch)): return
	if not TestCheck.ok(self, b.wch == {"artillery": 3, "fighter": 0} and b.wmax.fighter == 0, "강습모함 없음: 함재기 0/0 %s" % str(b.wch)): return
	if not TestCheck.ok(self, a.ammo.artillery == 0 and a.ammo.fighter == 0, "횟수가 탄약을 대체: 탄약 0"): return
	if not TestCheck.ok(self, _cmd(s, b, "fighter") == ["fighter_none"], "함재기 없는 함대의 함재기 명령은 fighter_none"): return

	# --- 2. 자동 사격이 횟수를 쓰고 0이면 멈춘다. 탄약·에너지·열은 쓰지 않는다 ---
	var t := F.sim([F.def("포격", 400, 450, [["SHP-03", 4]], true)], [F.def("표적", 640, 450, [["SHP-04", 40]])], 5)
	var pf: FleetState = t.st.fleets[0]
	var e0 := pf.energy_m
	var shots := 0
	var supp := ""
	for i in 4000:
		t.step()
		for e in t.drain_events():
			if e.kind == "salvo" and e.sq == pf.id and e.value.cat == "artillery":
				shots += 1
			elif e.kind == "suppressed" and e.sq == pf.id:
				supp = e.value.reason
	if not TestCheck.ok(self, shots == 3 and pf.wch.artillery == 0 and supp == "charges", "미사일 자동 사격 3회 뒤 멈춤: %d회 '%s'" % [shots, supp]): return
	if not TestCheck.ok(self, pf.heat_m == 0 and pf.energy_m == e0, "열·에너지 소모 없음"): return
	var c := F.sim([F.def("모함", 400, 450, [["SHP-01", 2]], true)], [F.def("표적", 540, 450, [["SHP-05", 40]])], 5)
	var cf: FleetState = c.st.fleets[0]
	shots = 0
	for i in 4000:
		c.step()
		for e in c.drain_events():
			if e.kind == "salvo" and e.sq == cf.id and e.value.cat == "fighter":
				shots += 1
	if not TestCheck.ok(self, shots == 3 and cf.wch.fighter == 0, "함재기 자동 사격 3회 뒤 멈춤: %d" % shots): return

	# --- 3. 버튼 매핑: 표적이 모든 사거리 안(거리 150)에 있어도 눌린 범주만 당긴다 ---
	var m := F.sim([F.def("혼성", 400, 450, [["SHP-03", 2], ["SHP-04", 2], ["SHP-01", 1], ["SHP-07", 2]], true)], [F.def("표적", 550, 450, [["SHP-04", 40]])], 5)
	var mf: FleetState = m.st.fleets[0]
	var far := m.st.tick + 100000
	for k in ["fighter", "missile"]:
		for cat in mf.next_fire:
			mf.next_fire[cat] = far
		if not TestCheck.ok(self, _cmd(m, mf, k).is_empty(), "%s 명령 수락" % k): return
		var pulled := []
		for cat in mf.next_fire:
			if mf.next_fire[cat] < far:
				pulled.append(cat)
		var want := ["fighter"] if k == "fighter" else ["artillery"]
		if not TestCheck.ok(self, pulled == want, "%s 버튼이 당긴 범주 %s" % [k, str(pulled)]): return

	# --- 4. 거부 사유: 횟수 0, 사거리·사격각 밖 ---
	mf.wch.artillery = 0
	if not TestCheck.ok(self, _cmd(m, mf, "missile") == ["missile_charges"], "횟수 0: missile_charges"): return
	var o := F.sim([F.def("포격", 400, 450, [["SHP-03", 2]], true)], [F.def("먼 표적", 900, 450, [["SHP-04", 4]])], 5)
	if not TestCheck.ok(self, _cmd(o, o.st.fleets[0], "missile") == ["missile_no_target"], "사거리 밖: missile_no_target"): return

	# --- 5. 보급 레벨별 보충: 처리량 100/50/25% -> 3/2/1회(데이터 환산), 정지 60/120/240초 ---
	var sal := F.sim([F.def("x", 0, 0, [["SHP-04", 1]])], [F.def("y", 900, 900, [["SHP-04", 1]])]).salvo
	if not TestCheck.ok(self, [sal.charge_refill(10000), sal.charge_refill(5000), sal.charge_refill(2500)] == [3, 2, 1], "환산 3/2/1"): return
	for lv in [[10000, 600, 3], [5500, 1200, 2], [2000, 2400, 1]]:   # [보급함 선체 비율 bp, 걸리는 틱, 보충 횟수]
		var r := _sup_sim([["SHP-03", 2]])
		var sf: FleetState = r.st.fleets[0]
		var af: FleetState = r.st.fleets[1]
		sf.hull = sf.max_hull * int(lv[0]) / 10000
		af.wch.artillery = 0
		for i in int(lv[1]) - 1:
			r.step()
		if not TestCheck.ok(self, af.wch.artillery == 0, "보충 전(%d틱)" % int(lv[1])): return
		r.step()
		if not TestCheck.ok(self, af.wch.artillery == int(lv[2]), "선체 %d bp: %d회 보충(%d)" % [int(lv[0]), int(lv[2]), af.wch.artillery]): return
	# 움직이면 보충되지 않는다
	var mv := _sup_sim([["SHP-03", 2]])
	var mfl: FleetState = mv.st.fleets[1]
	mfl.wch.artillery = 0
	mv.issue(BattleSim.command(0, [mfl.id], "move", -1, Vector2(1200, 450)))
	for i in 1300:
		mv.step()
	if not TestCheck.ok(self, mfl.wch.artillery == 0, "정지하지 않으면 보충 없음"): return
	# 재고 소모: 3회 보충 = 탄약 2×3 + 물자 1(보급함 2척 재고 탄약 24·물자 8)
	var st := _sup_sim([["SHP-03", 2]])
	var ssf: FleetState = st.st.fleets[0]
	var saf: FleetState = st.st.fleets[1]
	saf.wch.artillery = 0
	for i in 600:
		st.step()
	if not TestCheck.ok(self, saf.wch.artillery == 3 and ssf.sup_ammo == 24 - 6 and ssf.sup_mat == 7, "보충이 재고를 쓴다: 탄약 %d 물자 %d" % [ssf.sup_ammo, ssf.sup_mat]): return
	# 재고 0이면 보충 불가
	var ze := _sup_sim([["SHP-03", 2]])
	ze.st.fleets[0].sup_ammo = 0
	ze.st.fleets[1].wch.artillery = 0
	for i in 800:
		ze.step()
	if not TestCheck.ok(self, ze.st.fleets[1].wch.artillery == 0, "재고 0: 보충 안 됨"): return
	# 재고가 모자라면 댈 수 있는 만큼만(탄약 4 = 2회)
	var lo := _sup_sim([["SHP-03", 2]])
	lo.st.fleets[0].sup_ammo = 4
	lo.st.fleets[1].wch.artillery = 0
	for i in 600:
		lo.step()
	if not TestCheck.ok(self, lo.st.fleets[1].wch.artillery == 2 and lo.st.fleets[0].sup_ammo == 0, "재고 4: 2회만 보충"): return
	# 자기 자신 보급 금지: 보급함이 있는 함대도 자기 횟수를 못 채운다
	var me := SalvoFixture.sim([SalvoFixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-03", 2]], true)], [SalvoFixture.def("Z", 1500, 850, [["SHP-04", 1]])], 1, "", func(cb): cb.supply = SalvoFixture.combat().supply)
	me.st.fleets[0].wch.artillery = 0
	for i in 800:
		me.step()
	if not TestCheck.ok(self, me.st.fleets[0].wch.artillery == 0 and me.st.fleets[0].sup_src == "", "자기 보급 금지"): return
	# 강습모함이 없는 함대는 보급을 받아도 함재기 횟수 0 유지, 미사일만 찬다
	var nc := _sup_sim([["SHP-03", 2]])
	var nf: FleetState = nc.st.fleets[1]
	nf.wch.artillery = 0
	for i in 700:
		nc.step()
	if not TestCheck.ok(self, nf.wch.fighter == 0 and nf.wch.artillery == 3, "함재기 없음 유지, 미사일 보충: %s" % str(nf.wch)): return
	# 강습모함이 전멸하면 최대·남은 함재기 횟수도 0(버튼 0/0)
	a.stages["SHP-01"] = [0, 0, 0, 0, 1]
	s.salvo.refresh_range(a)
	if not TestCheck.ok(self, a.wmax.fighter == 0 and a.wch.fighter == 0 and a.wmax.artillery == 3, "모함 전멸: 함재기 0/0 %s" % str(a.wmax)): return

	# --- 6. 결정론: 같은 시드의 지문이 같다 ---
	var fp := []
	for k in 2:
		var d := F.sim([F.def("혼성", 400, 450, [["SHP-03", 2], ["SHP-01", 1]], true)], [F.def("표적", 540, 450, [["SHP-04", 40]])], 9)
		for i in 2000:
			d.step()
		fp.append(d.fingerprint())
	if not TestCheck.ok(self, fp[0] == fp[1], "같은 시드 같은 지문"): return
	print("weapon_charges OK")
	quit(0)
