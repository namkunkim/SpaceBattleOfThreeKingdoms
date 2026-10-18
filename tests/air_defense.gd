extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func arena() -> BattleSim:
	var F := SalvoFixture
	var s := F.sim([F.def("아군", 500, 450, [["SHP-01", 6], ["SHP-07", 12], ["SHP-04", 50]], true)], [F.def("적군", 650, 450, [["SHP-01", 6], ["SHP-07", 12], ["SHP-04", 50]], true)], 7)
	for f in s.st.fleets:
		for cat in s.salvo.C.categories:
			f.next_fire[cat] = 999999
	return s

func shot(s: BattleSim, a: FleetState, z: FleetState, counter := false) -> Dictionary:
	var q := s.salvo.qualifying(a, "fighter", z)
	var out := s.salvo._plan_shot(a, "fighter", z, q)
	out.hit = false # 빗나가도 대응. 피해로 인한 퇴각과 분리
	out.counter = counter
	return out

func _run() -> void:
	var s := arena()
	var sal := s.salvo
	var a: FleetState = s.st.fleets[0]
	var z: FleetState = s.st.fleets[1]
	var ad: Dictionary = sal.C.air_defense
	if not TestCheck.ok(self, ad.categories == ["fighter", "artillery"] and ad.status.begins_with("proposed"), "방공 데이터·범주"): return
	if not TestCheck.ok(self, not a.counter_launch and z.counter_launch, "아군 꺼짐·적 켜짐 기본값"): return
	var expected := int((12.0 * 4000 + 6 * 2000) / 68)
	if not TestCheck.ok(self, sal.air_defense_bp(z, "fighter") == expected, "편성 비율 계산"): return
	for cat in ["line_fire", "intercept", "torpedo"]:
		if not TestCheck.ok(self, sal.air_defense_bp(z, cat) == 0, "%s 방공 제외" % cat): return
	var normal := sal.hit_bp(a, z, "fighter")
	ad.max_bp = 0
	if not TestCheck.ok(self, sal.hit_bp(a, z, "fighter") - normal == expected, "명중률에서 방공 차감"): return
	ad.max_bp = 1500
	z.stages["SHP-04"] = [0, 0, 0, 0, 50]
	if not TestCheck.ok(self, sal.air_defense_bp(z, "artillery") == 1500, "전문 함대 상한"): return
	z.stages["SHP-07"] = [0, 0, 0, 12, 0]
	z.stages["SHP-01"] = [0, 0, 0, 6, 0]
	if not TestCheck.ok(self, sal.air_defense_bp(z, "fighter") == 0, "이탈 함선 방공 없음"): return
	var F := SalvoFixture
	for eq in ["FAST-EQ-RECON", "FAST-EQ-TORPEDO", "FAST-EQ-INTERCEPT"]:
		var craft := F.sim([F.def("고속정", 500, 450, [["SHP-08", 12, eq]], true)], [F.def("적", 650, 450, [["SHP-01", 6]], true)])
		var f: FleetState = craft.st.fleets[0]
		var value: int = craft.salvo.air_defense_bp(f, "fighter")
		if not TestCheck.ok(self, value == (1500 if eq == "FAST-EQ-INTERCEPT" else 0), "요격 장비만 방공 " + eq): return
		if eq == "FAST-EQ-INTERCEPT":
			f.stages["SHP-08"] = [0, 0, 12, 0, 0]
			var damaged := mini(1500, int(float(craft.salvo.C.stage.power[2]) * 3000))
			if not TestCheck.ok(self, craft.salvo.air_defense_bp(f, "fighter") == damaged, "손상 계수 적용"): return
	# 피격 뒤 다음 틱에 정확히 한 번, 실제 자원 소비·주기 갱신·연쇄 차단
	s = arena(); sal = s.salvo; a = s.st.fleets[0]; z = s.st.fleets[1]
	a.counter_launch = true
	sal._resolve(shot(s, a, z))
	sal._resolve(shot(s, a, z))
	if not TestCheck.ok(self, z.counter_pending and int(z.wch.fighter) == 3, "중복 피격은 대응 하나 예약"): return
	s.st.tick += 1
	sal.step()
	if not TestCheck.ok(self, int(z.wch.fighter) == 2 and not z.counter_pending and not a.counter_pending, "대응 1회 소비·연쇄 없음"): return
	sal._resolve(shot(s, a, z))
	if not TestCheck.ok(self, not z.counter_pending, "같은 틱 이미 발진하면 추가 대응 없음"): return
	s.st.tick += 1
	sal._resolve(shot(s, a, z, true))
	if not TestCheck.ok(self, not z.counter_pending, "대응 공격에는 재대응 없음"): return
	# 명령은 선택 함대에만 적용, 혼합이면 모두 켜기, 명시적 해제는 예약 취소
	s = arena(); sal = s.salvo; a = s.st.fleets[0]; z = s.st.fleets[1]
	var off_fp := s.fingerprint()
	s.apply(BattleSim.command(0, [a.id], "counter_launch"))
	if not TestCheck.ok(self, a.counter_launch and z.counter_launch and s.fingerprint() != off_fp, "선택 함대 설정·지문 반영"): return
	a.counter_pending = true
	s.apply(BattleSim.command(0, [a.id], "counter_launch", -1, Vector2.ZERO, {"on": false}))
	if not TestCheck.ok(self, not a.counter_launch and not a.counter_pending, "해제 시 예약 취소"): return
	sal._resolve(shot(s, z, a))
	if not TestCheck.ok(self, not a.counter_pending, "아군 설정 꺼짐이면 대응 없음"): return
	s.apply(BattleSim.command(0, [a.id], "counter_launch"))
	sal._resolve(shot(s, z, a))
	s.st.tick += 1
	sal.step()
	if not TestCheck.ok(self, int(a.wch.fighter) == 2 and not z.counter_pending, "아군 켜짐이면 실제 대응·적 재대응 없음"): return
	var mixed := F.sim([F.def("A", 400, 450, [["SHP-01", 2]], true), F.def("B", 450, 450, [["SHP-01", 2]])], [F.def("Z", 650, 450, [["SHP-01", 2]], true)])
	var ma: FleetState = mixed.st.fleets[0]
	var mb: FleetState = mixed.st.fleets[1]
	ma.counter_launch = true
	mixed.apply(BattleSim.command(0, [ma.id, mb.id], "counter_launch"))
	if not TestCheck.ok(self, ma.counter_launch and mb.counter_launch, "혼합 선택은 모두 켜짐"): return
	mixed.apply(BattleSim.command(0, [ma.id, mb.id], "counter_launch"))
	if not TestCheck.ok(self, not ma.counter_launch and not mb.counter_launch, "전체 켜짐 선택은 모두 꺼짐"): return
	mixed.apply(BattleSim.command(0, [mixed.st.fleets[2].id], "counter_launch", -1, Vector2.ZERO, {"on": false}))
	if not TestCheck.ok(self, mixed.st.fleets[2].counter_launch, "적 설정 변경 불가"): return
	# 자원·사거리·퇴각·격침 제한
	for reason in ["charges", "range", "retreat", "dead", "platform"]:
		s = arena(); sal = s.salvo; a = s.st.fleets[0]; z = s.st.fleets[1]
		var incoming := shot(s, a, z)
		match reason:
			"charges": z.wch.fighter = 0
			"range": a.pos = Vector2(1500, 450)
			"retreat": z.mstate = "retreat"
			"dead": z.dead = true
			"platform": z.stages["SHP-01"] = [0, 0, 0, 6, 0]
		sal._resolve(incoming)
		if not TestCheck.ok(self, not z.counter_pending, "대응 제한 " + reason): return
	# 예약 뒤 사거리 상실 → 나중 정상 사격까지 대응 표식이 남지 않는다
	s = arena(); sal = s.salvo; a = s.st.fleets[0]; z = s.st.fleets[1]
	sal._resolve(shot(s, a, z))
	a.pos = Vector2(1500, 450)
	s.st.tick += 1
	sal.step()
	if not TestCheck.ok(self, not z.counter_pending and int(z.wch.fighter) == 3, "실패한 예약 해제·자원 보존"): return
	var fp := []
	for i in 2:
		var replay := arena()
		replay.st.fleets[0].counter_launch = true
		replay.st.fleets[0].next_fire.fighter = 0
		F.run(replay, 65.0)
		fp.append(replay.fingerprint())
	if not TestCheck.ok(self, fp[0] == fp[1], "대응 포함 결정론"): return
	print("air_defense OK")
	quit(0)
