extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _sim() -> BattleSim:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	p.combat.erase("detection")
	var s := BattleSim.new(17, BattleRules.TICK_HZ, p)
	s.st.ai_timer = 1 << 40
	for f in s.st.fleets:
		f.pos = Vector2(40, 40) if f.side == 0 else Vector2(1600, 40)
		f.home = f.pos
	return s

func _run() -> void:
	var s := _sim()
	var a: FleetState = s.st.fleets[1]
	var e: FleetState = s.st.alive(1)[1]
	a.pos = Vector2(600, 600)
	e.pos = Vector2(800, 600)
	a.control = "direct"
	var pos := a.pos
	s.cai.think(s)
	if not TestCheck.ok(self, a.pos == pos and not a.has_move and a.target_id == -1 and a.charge == 0, "direct fleet never receives AI pursuit"): return
	# 사격 표적이 있어도 AI가 내린 거리 유지 이동을 실제로 수행한다.
	s.apply(BattleSim.command(0, [a.id], "ai_target", e.id))
	s.apply(BattleSim.command(0, [a.id], "ai_move", -1, Vector2(400, 600)))
	for i in 30:
		s._fleet_phase(false)
	if not TestCheck.ok(self, a.pos.distance_to(e.pos) > pos.distance_to(e.pos), "standoff movement takes priority over target pursuit"): return
	# 강습모함 보유도 평시에는 적 중심으로 겹치지 않는다(양 진영).
	for side in 2:
		var w := _sim()
		var f: FleetState = w.st.alive(side)[1]
		var foe: FleetState = w.st.alive(1 - side)[1]
		f.stages["SHP-01"] = [1, 0, 0]
		f.pos = Vector2(600, 600)
		foe.pos = Vector2(800, 600)
		w.apply(BattleSim.command(side, [f.id], "ai_target", foe.id))
		w.apply(BattleSim.command(side, [f.id], "ai_move", -1, foe.pos))
		var minimum := 200.0
		for i in 700:
			w._fleet_phase(false)
			minimum = minf(minimum, f.pos.distance_to(foe.pos))
		if not TestCheck.ok(self, minimum >= 169.99, "carrier without charge keeps distance on side %d: %s" % [side, minimum]): return
	# 공개 정보와 아군 상태로만 판단하는 마무리 돌격 조건.
	for mode in ["strong", "early", "low_morale", "damaged", "estimated", "far", "no_carrier", "opportunity"]:
		var w := _sim()
		var f: FleetState = w.st.alive(1)[1]
		f.stages["SHP-01"] = [1, 0, 0]
		f.heat_m = 0
		w.first_hit_tick = 0
		w.st.tick = 30 * w.st.hz
		var best := {"id": w.st.alive(0)[1].id, "state": "confirmed", "band": 2}
		var d := 185.0
		match mode:
			"strong": best.band = 4
			"early": w.st.tick = 10 * w.st.hz
			"low_morale": f.morale_bp = 7000
			"damaged": f.ships = f.max_ships / 2
			"estimated": best.state = "estimated"
			"far": d = 300.0
			"no_carrier": f.stages.erase("SHP-01")
		w.cai._charge(w, f, w.cai.A.postures.balanced, 0.0, d, best)
		if not TestCheck.ok(self, (f.charge > 0) == (mode == "opportunity"), "charge opportunity gate: " + mode): return
	print("STANDOFF_CONTROL_PASS")
	quit(0)
