extends SceneTree

# P9 후속: 그룹 진형 일부 거부 표시(FormationTab who)와 초기 배치(place 명령: 반경, 틱 0 전용, replay 일치).
# 헤드리스. 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	var sim := BattleSim.new(1, BattleRules.TICK_HZ, p)
	var mine: Array = []
	for f in sim.st.fleets:
		if f.side == 0:
			mine.append(f)

	# --- 1. 그룹 진형: 팔진을 못 받는 함대가 이름·사유와 함께 who에 든다 ---
	var rows: Array = []
	for q in BattleProjection.build(sim, 0).squadrons:
		if q.side == 0:
			var r: Dictionary = q.duplicate()
			r.name = "F%d" % q.id
			rows.append(r)
	var no_master := rows.filter(func(r): return not sim.salvo.master_ok(sim.st.by_id(r.id)))
	var card := {}
	for o in FormationTab.options(sim.salvo.C, rows):
		if o.id == "FRM-07":
			card = o
	if not TestCheck.ok(self, card.who.size() == no_master.size(), "팔진 제외 함대 수 %d/%d" % [card.who.size(), no_master.size()]): return
	if no_master.size() > 0 and not TestCheck.ok(self, ("F%d" % no_master[0].id) in card.foot, "그룹 사유에 함대 이름: " + card.foot): return

	# --- 2. 배치: 반경 안으로 잘리고, 반경 안은 그대로 간다 ---
	var a: FleetState = mine[0]
	var s0 := a.spawn
	sim.issue(BattleSim.command(0, [a.id], "place", -1, s0 + Vector2(5000, 0)))
	if not TestCheck.ok(self, absf(a.pos.distance_to(s0) - sim.place_radius()) < 1.0, "반경 밖 요청은 반경 끝: %.1f" % a.pos.distance_to(s0)): return
	sim.issue(BattleSim.command(0, [a.id], "place", -1, s0 + Vector2(0, 30)))
	if not TestCheck.ok(self, a.pos.distance_to(s0 + Vector2(0, 30)) < 1.0 and a.home == a.pos, "반경 안 요청은 그 자리"): return
	# 그룹: 대형째 같은 만큼 옮긴다(둘 다 반경 안일 때)
	var b: FleetState = mine[1]
	var gap := b.pos - a.pos
	sim.issue(BattleSim.command(0, [a.id, b.id], "place", -1, (a.pos + b.pos) * 0.5 + Vector2(20, 0)))
	if not TestCheck.ok(self, (b.pos - a.pos).distance_to(gap) < 2.0, "그룹 배치는 간격 유지"): return

	# 그룹이 경계·반경에 걸려도 대형이 그대로다(이동량을 일괄로 줄인다)
	var g0 := b.pos - a.pos
	sim.issue(BattleSim.command(0, [a.id, b.id], "place", -1, (a.pos + b.pos) * 0.5 + Vector2(-9000, -9000)))
	if not TestCheck.ok(self, (b.pos - a.pos).distance_to(g0) < 2.0, "경계 근처 그룹 배치도 간격 유지"): return
	for f in [a, b]:
		if not TestCheck.ok(self, f.pos.distance_to(f.spawn) <= sim.place_radius() + 1.0 and f.pos.x >= sim.R.edge - 1.0 and f.pos.y >= sim.R.edge - 1.0, "반경·경계 안"): return
	# 방향: 배치 뒤 가장 가까운 적을 다시 향하고, facing_deg가 있으면 그 방향이 이긴다
	var nf := sim.st.nearest_foe(a, 1e9)
	if not TestCheck.ok(self, absf(angle_difference(atan2(nf.pos.y - a.pos.y, nf.pos.x - a.pos.x), a.heading)) < 0.02, "배치 뒤 초기 방향 재계산"): return
	sim.issue(BattleSim.command(0, [a.id], "place", -1, a.pos, {"facing_deg": 90.0}))
	if not TestCheck.ok(self, absf(angle_difference(PI * 0.5, a.heading)) < 0.02, "facing_deg 즉시 방향: %.3f" % a.heading): return
	if not TestCheck.ok(self, absf(sim.place_radius() - minf(sim.rs.world.x, sim.rs.world.y) * sim.R.place_radius_ratio) < 0.01, "반경 = 짧은 변 비율"): return

	# --- 3. replay: 같은 기록 = 같은 결과 ---
	var ticks := 120
	for i in ticks:
		sim.step()
	var rp := BattleSim.replay(1, BattleRules.TICK_HZ, sim.command_log, ticks, p)
	if not TestCheck.ok(self, rp.fingerprint() == sim.fingerprint(), "replay 지문 일치"): return

	# --- 4. 틱 0이 지나면 거부 ---
	sim.drain_events()
	sim.issue(BattleSim.command(0, [a.id], "place", -1, a.pos + Vector2(10, 0)))
	var why := ""
	for e in sim.drain_events():
		if e.kind == "rejected":
			why = str(e.value)
	if not TestCheck.ok(self, why == "place_late", "틱 0 이후 배치 거부: " + why): return

	print("PLACEMENT_PASS")
	quit(0)
