extends SceneTree

# M5 완료 기준(제안서 §9): 진형 % 보정, 상성 순환, 전환(5초·전환 중 ×0.8), 지형 제한, 노출표 전체,
# 선회·평행 이동·경유점·도착 방향, 방향 배분 60/40 장기 비율, 지휘 한도 초과 없음, 방어진형 삭제. 헤드리스, 실패하면 종료 코드 1.

const FRM := ["FRM-01", "FRM-02", "FRM-03", "FRM-04", "FRM-05", "FRM-06", "FRM-07"]

func _initialize() -> void:
	call_deferred("_run")

func _sec(s: BattleSim, n: float) -> void:
	for i in int(n * s.st.hz):
		s.step()
		s.drain_events()

func _pair(form_a := "FRM-01", form_b := "FRM-01", cmd := 70, dist := 150.0) -> BattleSim:
	var F := SalvoFixture
	return F.sim([F.def("A", 400, 450, [["SHP-04", 8], ["SHP-07", 4]], true, form_a, cmd)], [F.def("B", 400 + dist, 450, [["SHP-04", 8], ["SHP-07", 4]], false, form_b, cmd)])

func _cmd(s: BattleSim, f: FleetState, kind: String, args := {}, point := Vector2.ZERO) -> Array:
	s.issue(BattleSim.command(f.side, [f.id], kind, -1, point, args))
	var out := []
	for e in s.drain_events():
		if e.kind == "rejected":
			out.append(e.value)
	return out

func _run() -> void:
	var F := SalvoFixture
	var cb := F.combat()
	var fr: Dictionary = cb.formation_rules
	# --- 1. 진형 % 보정은 정본 데이터 그대로(명중률 식), 기동%는 속도에 곱한다 ---
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/scenarios/base/red-cliffs-formation-rules.json")).formations
	for id in FRM:
		var r: Dictionary = rules[id]
		var m: Dictionary = cb.formations[id]
		if not TestCheck.ok(self, m.fire_bp == r.fire_percent * 100 and m.defense_bp == r.defense_percent * 100 and m.detection_bp == r.detection_percent * 100 and m.mobility_bp == r.mobility_percent * 100, "진형 % " + id): return
	var s := _pair()
	var a: FleetState = s.st.fleets[0]
	var b: FleetState = s.st.fleets[1]
	var base_speed := a.speed
	_cmd(s, a, "formation", {"id": "FRM-06"})
	_sec(s, 31.0)
	if not TestCheck.ok(self, a.formation_id == "FRM-06" and is_equal_approx(a.speed, base_speed / 1.05 * 1.15), "장사진 기동 +15%%: %f" % a.speed): return

	# --- 2. 상성 순환: 학익 → 어린 → 방원 → 봉시 → 안행 → 학익, 교전 거리대 ×1.2, 반대 방향은 1.0 ---
	var cyc := ["FRM-02", "FRM-01", "FRM-03", "FRM-05", "FRM-04"]
	for i in cyc.size():
		var win: String = cyc[i]
		var lose: String = cyc[(i + 1) % cyc.size()]
		s = _pair(win, lose)
		a = s.st.fleets[0]
		b = s.st.fleets[1]
		if not TestCheck.ok(self, is_equal_approx(s.salvo.formation_mul(a, b, "engagement"), 1.2), "%s이 %s에 우위 ×1.2" % [win, lose]): return
		if not TestCheck.ok(self, is_equal_approx(s.salvo.formation_mul(b, a, "engagement"), 1.0), "%s은 %s에 우위 없음" % [lose, win]): return
		if not TestCheck.ok(self, is_equal_approx(s.salvo.formation_mul(a, b, "barrage"), 1.0), "교전 밖에서는 상성 없음"): return
		# 건너뛴 쌍(순환 밖)은 우위가 없다
		var skip: String = cyc[(i + 2) % cyc.size()]
		if not TestCheck.ok(self, not s.salvo.affinity_wins(win, skip), "%s은 %s에 우위 아님" % [win, skip]): return
	# 장사진 ×0.9, 팔진은 상성 무효(양쪽)
	s = _pair("FRM-06", "FRM-01")
	if not TestCheck.ok(self, is_equal_approx(s.salvo.formation_mul(s.st.fleets[0], s.st.fleets[1], "engagement"), 0.9), "장사진 ×0.9"): return
	for id in FRM:
		if id == "FRM-07":
			continue
		if not TestCheck.ok(self, not s.salvo.affinity_wins("FRM-07", id) and not s.salvo.affinity_wins(id, "FRM-07"), "팔진 상성 무효 " + id): return

	# --- 3. 전환: 5초, 전환 중 피해 ×0.8, 방어%·노출은 이전 진형, 완료하면 바뀐다 ---
	s = _pair("FRM-01", "FRM-01")
	a = s.st.fleets[0]
	b = s.st.fleets[1]
	var dmg0 := s.salvo.formation_mul(a, b, "engagement")
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-03"}).is_empty() and a.form_to == "FRM-03" and a.form_left == 50, "전환 시작 5초: %d" % a.form_left): return
	if not TestCheck.ok(self, is_equal_approx(s.salvo.formation_mul(a, b, "engagement"), dmg0 * 0.8), "전환 중 피해 ×0.8"): return
	if not TestCheck.ok(self, a.formation_id == "FRM-01" and s.salvo._form_id(a) == "FRM-01", "전환 중 진형·방어%는 이전 값"): return
	# 같은 사격이 전환 중에는 이전 진형(어린진 방어 −5%)으로 명중률을 낸다
	var hit_old := s.salvo.hit_bp(b, a, "line_fire")
	var shape_old := a.shape
	_sec(s, 4.0)
	if not TestCheck.ok(self, a.formation_id == "FRM-01" and a.form_left > 0, "4초에는 아직 전환 중"): return
	_sec(s, 1.5)
	if not TestCheck.ok(self, a.formation_id == "FRM-03" and a.form_to == "" and a.form_left == 0, "5초 뒤 완료"): return
	if not TestCheck.ok(self, s.salvo.hit_bp(b, a, "line_fire") < hit_old and a.shape != shape_old, "완료 뒤 방원진 방어 +15%·배치도 변경"): return
	if not TestCheck.ok(self, is_equal_approx(s.salvo.formation_mul(a, b, "engagement"), 1.0), "완료 뒤 전환 감소 없음(방원 대 어린은 상성 열세라 1.0)"): return
	# 현재 진형으로 되돌리면 취소
	_cmd(s, a, "formation", {"id": "FRM-05"})
	_sec(s, 2.0)
	_cmd(s, a, "formation", {"id": "FRM-03"})
	if not TestCheck.ok(self, a.form_left == 0 and a.form_to == "", "현재 진형 지정은 전환 취소"): return
	# 통솔이 요구치에 못 미쳐도 5초: 학익진(75)에 통솔 70
	s = _pair("FRM-01", "FRM-01", 70)
	a = s.st.fleets[0]
	_cmd(s, a, "formation", {"id": "FRM-02"})
	if not TestCheck.ok(self, a.form_left == 50, "통솔 미달도 5초: %d" % a.form_left): return
	s = _pair("FRM-01", "FRM-01", 80)
	a = s.st.fleets[0]
	_cmd(s, a, "formation", {"id": "FRM-02"})
	if not TestCheck.ok(self, a.form_left == 50, "통솔 충족 5초: %d" % a.form_left): return
	# 팔진: 통솔 90 + 신기묘산만. 조건 충족자는 전환 절반(2.5초)
	s = _pair("FRM-01", "FRM-01", 95)
	a = s.st.fleets[0]
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-07"}) == ["formation_master"], "특성 없는 통솔 95는 팔진 불가"): return
	a.traits = ["신기묘산"]
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-07"}).is_empty() and a.form_left == 25, "팔진 조건 충족자 전환 2.5초: %d" % a.form_left): return
	s = _pair("FRM-01", "FRM-01", 80)
	a = s.st.fleets[0]
	a.traits = ["신기묘산"]
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-07"}) == ["formation_master"], "통솔 80은 팔진 불가"): return
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-99"}) == ["unknown_formation"], "없는 진형"): return
	# 방어진형 삭제: def는 거부, 방원진이 대신한다
	if not TestCheck.ok(self, _cmd(s, a, "def") == ["unknown_command"] and not a.defense, "방어진형 명령 삭제"): return
	if not TestCheck.ok(self, fr.defense_id == "FRM-03", "방어진형 대체 = 방원진"): return

	# --- 4. 지형 제한: 기저 항로는 학익·안행 불가, 중회랑은 방원·봉시·장사만, 대회랑은 장사진 강제 ---
	s = _pair("FRM-01", "FRM-01", 99)
	a = s.st.fleets[0]
	s.salvo.terrain_class = "base_route"
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-02"}) == ["formation_terrain"] and _cmd(s, a, "formation", {"id": "FRM-04"}) == ["formation_terrain"], "기저 항로 학익·안행 불가"): return
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-05"}).is_empty(), "기저 항로 봉시 가능"): return
	s.salvo.terrain_class = "mid_corridor"
	for id in FRM:
		var want: bool = id in ["FRM-03", "FRM-05", "FRM-06"]
		if not TestCheck.ok(self, s.salvo.terrain_allowed(id) == want, "중회랑 허용 " + id): return
	s.salvo.terrain_class = "great_corridor"
	a.form_to = ""
	a.form_left = 0
	if not TestCheck.ok(self, _cmd(s, a, "formation", {"id": "FRM-03"}) == ["formation_terrain"], "대회랑 변경 불가"): return
	s.salvo.finish_setup()   # 시작 진형이 지형에 어긋나면 즉시 강제 진형으로 바뀐다
	if not TestCheck.ok(self, a.formation_id == "FRM-06" and s.st.fleets[1].formation_id == "FRM-06", "대회랑 장사진 강제"): return
	s = _pair("FRM-02", "FRM-05")
	s.salvo.terrain_class = "mid_corridor"
	s.salvo.finish_setup()
	if not TestCheck.ok(self, s.st.fleets[0].formation_id == "FRM-03" and s.st.fleets[1].formation_id == "FRM-05", "중회랑 시작 진형 보정(학익 → 허용되는 첫 진형 방원)"): return

	# --- 5. 노출표 전체: 진형 7종 × 방향 3, 함종이 데이터에 있고 어린진은 제안서 표와 같다 ---
	var ex: Dictionary = cb.loss.exposure
	for id in FRM:
		if not TestCheck.ok(self, ex.has(id), "노출표 " + id): return
		for sec in ["front", "flank", "rear"]:
			var list: Array = ex[id][sec]
			if not TestCheck.ok(self, not list.is_empty(), "노출 비어 있음 %s %s" % [id, sec]): return
			for t in list:
				if not TestCheck.ok(self, cb.ship_types.has(t), "노출 함종 " + t): return
	if not TestCheck.ok(self, ex["FRM-03"].front == ["SHP-04"] and ex["FRM-06"].flank == ["SHP-03", "SHP-05", "SHP-01"] and ex["FRM-04"].rear == ["SHP-05", "SHP-02"], "노출표 값(§4.4)"): return
	# 방향별 이탈 함종이 표를 따른다: 후면에서 맞은 방원진은 전열·요격만 잃는다
	s = F.sim([F.def("방원", 400, 450, [["SHP-04", 8], ["SHP-07", 4], ["SHP-03", 4], ["SHP-05", 4]], true, "FRM-03")], [F.def("B", 1400, 450, [["SHP-04", 4]])])
	a = s.st.fleets[0]
	var hits := 0
	while a.lost_ships < 6 and hits < 200:
		s.salvo.apply_hull(null, a, a.max_hull / 60.0, "engagement", "rear", s.st.new_event_id())
		hits += 1
	var lost_non_expo := 0
	for t in ["SHP-03", "SHP-05"]:
		lost_non_expo += (a.comp0[t] - s.salvo.present_of(a, t))
	if not TestCheck.ok(self, a.lost_ships >= 6 and lost_non_expo <= 2, "후면 피격: 노출 함종(전열·요격)이 먼저, 포격·보급 손실 %d/%d" % [lost_non_expo, a.lost_ships]): return

	# --- 6. 방향 배분 장기 비율(M3 리뷰 후속 ②): 이탈 20척 이상에서 노출 함종 몫 60 ± 5% ---
	s = F.sim([F.def("어린", 400, 450, [["SHP-04", 16], ["SHP-07", 4], ["SHP-03", 4], ["SHP-05", 2], ["SHP-01", 2]], true, "FRM-01")], [F.def("B", 1400, 450, [["SHP-04", 4]])])
	a = s.st.fleets[0]
	hits = 0
	while a.loss_total < 24 and hits < 400:
		s.salvo.apply_hull(null, a, a.max_hull / 90.0, "engagement", "front", s.st.new_event_id())
		hits += 1
	var share := a.loss_exposed * 100 / maxi(1, a.loss_total)
	if not TestCheck.ok(self, a.loss_total >= 20 and absi(share - 60) <= 5, "노출 함종 몫 %d%% (이탈 %d척, 타격 %d회)" % [share, a.loss_total, hits]): return

	# --- 7. 선회 9°/초, 평행 이동 60%, 경유점, 도착 방향 ---
	s = F.sim([F.def("A", 400, 450, [["SHP-04", 8]], true)], [F.def("B", 1500, 850, [["SHP-04", 4]])])
	a = s.st.fleets[0]
	a.heading = 0.0
	var p0 := a.pos
	_cmd(s, a, "move", {"facing_deg": 180}, p0 + Vector2(2, 0))   # 도착 반경 안: 제자리에서 돌아선다
	_sec(s, 10.0)
	var h10 := absf(a.heading)
	if not TestCheck.ok(self, absf(rad_to_deg(h10) - 90.0) < 3.0, "선회 9°/초: 10초에 %f°" % rad_to_deg(h10)): return
	_sec(s, 11.0)
	if not TestCheck.ok(self, absf(absf(a.heading) - PI) < deg_to_rad(2.0) and not a.face_set, "180° 선회 20초, 맞으면 해제"): return
	# 경유점: 지나는 순서대로, 도착 방향
	s = F.sim([F.def("A", 200, 450, [["SHP-04", 8]], true)], [F.def("B", 1500, 850, [["SHP-04", 4]])])
	a = s.st.fleets[0]
	var via := [Vector2(260, 450), Vector2(260, 520)]
	_cmd(s, a, "move", {"via": via, "facing_deg": 90}, Vector2(320, 520))
	if not TestCheck.ok(self, a.route.size() == 2 and a.move_to.is_equal_approx(Vector2(260, 450)), "경유점 3개 중 첫 점으로 출발"): return
	var seen := [false, false]
	for i in 3000:
		s.step()
		s.drain_events()
		if a.move_to.is_equal_approx(Vector2(260, 520)):
			seen[0] = true
		if a.move_to.is_equal_approx(Vector2(320, 520)):
			seen[1] = true
		if not a.has_move and not a.face_set:
			break
	if not TestCheck.ok(self, seen[0] and seen[1] and a.pos.distance_to(Vector2(320, 520)) < 10.0, "경유점을 순서대로 지난다: %s" % a.pos): return
	if not TestCheck.ok(self, absf(a.heading - PI / 2.0) < deg_to_rad(2.0), "도착 방향 90°: %f" % rad_to_deg(a.heading)): return
	var tooMany := [Vector2(1, 1), Vector2(2, 2), Vector2(3, 3), Vector2(4, 4), Vector2(5, 5)]
	if not TestCheck.ok(self, _cmd(s, a, "move", {"via": tooMany}, Vector2(9, 9)) == ["too_many_waypoints"], "경유 + 목적지는 5점까지"): return
	# 평행 이동: 방향 유지, 속도는 전진의 60%
	s = F.sim([F.def("A", 200, 450, [["SHP-04", 8]], true)], [F.def("B", 1500, 850, [["SHP-04", 4]])])
	a = s.st.fleets[0]
	a.heading = 0.0
	var v := a.speed
	_cmd(s, a, "move", {"strafe": true}, Vector2(200, 650))   # 헤딩과 수직인 옆 이동
	_sec(s, 20.0)
	if not TestCheck.ok(self, absf(a.heading) < 0.01 and absf(a.pos.x - 200.0) < 0.5, "평행 이동은 방향을 바꾸지 않는다"): return
	if not TestCheck.ok(self, absf((a.pos.y - 450.0) - v * 0.6 * 20.0) < 1.0, "평행 이동 속도 60%%: %f / %f" % [a.pos.y - 450.0, v * 0.6 * 20.0]): return
	# 정지 명령은 경유점·평행·도착 방향을 지운다
	_cmd(s, a, "stop")
	if not TestCheck.ok(self, a.route.is_empty() and not a.strafe and not a.face_set and not a.has_move, "정지가 이동 부속 상태를 지운다"): return

	# 투영: 화면이 읽는 진형·전환·경로 값. 배치도 번호는 정본 7종 → 재사용 모양
	var pj: Dictionary = s.projection(0).squadrons[0]
	if not TestCheck.ok(self, pj.formation_id == "FRM-01" and pj.formation == BattleRules.FORM_SHAPE[0] and pj.form_to == "" and pj.has("route") and pj.has("strafe"), "투영 진형 키"): return
	s = _pair("FRM-01", "FRM-01", 80)
	_cmd(s, s.st.fleets[0], "formation", {"id": "FRM-02"})
	pj = s.projection(0).squadrons[0]
	if not TestCheck.ok(self, pj.form_to == "FRM-02" and is_equal_approx(pj.form_left_s, 5.0), "투영 전환 남은 시간"): return

	# --- 8. 결정론: 진형·경유점·평행 명령을 섞은 같은 입력은 같은 지문 ---
	var fps := []
	for k in 2:
		s = _pair("FRM-01", "FRM-04", 80, 200.0)
		a = s.st.fleets[0]
		s.queue(BattleSim.command(0, [a.id], "formation", -1, Vector2.ZERO, {"id": "FRM-02"}))
		s.queue(BattleSim.command(0, [a.id], "move", -1, Vector2(500, 500), {"via": [Vector2(450, 400)], "strafe": true, "facing_deg": 45}))
		_sec(s, 60.0)
		fps.append(s.fingerprint())
	if not TestCheck.ok(self, fps[0] == fps[1], "같은 입력 같은 지문"): return

	# --- 9. 지휘 한도 초과(M3 후속): 적벽 모든 난이도에서 초과 전대가 없다. 생기면 기동·명중·전환 페널티 구현이 필요하다 ---
	for diff in ["입문", "표준", "상급", "극한"]:
		var sim := BattleSim.new(1, BattleRules.TICK_HZ, ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", diff))
		for f in sim.st.fleets:
			var limit: int = 40 + f.cmd_stat * 2
			if not TestCheck.ok(self, f.cost0 <= limit, "지휘 한도 초과 %s %s: %d > %d" % [diff, f.sq_id, f.cost0, limit]): return

	print("FORMATION_RULES_PASS")
	quit(0)
