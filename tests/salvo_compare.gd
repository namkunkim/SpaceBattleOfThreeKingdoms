extends SceneTree

# M3 피해 방식 3종(고정 / √ / 정비례) 통계 비교(제안서 §4.3 K1, §9 M3). 판정이 아니라 표를 만드는 도구다.
# 조건 A: 통제된 소 대 대 교전(함종 구성이 같은 12척 대 32척). 조건 B: 적벽 시나리오(표준 난이도), 플레이어 전대가 5초마다 가까운 적을 공격.
#
# 실행: godot --headless --path . -s tests/salvo_compare.gd -- --runs 100 [--scen A,B] [--out user://salvo_compare.json]
#        [--period 15] [--dmg-scale 0.25]   주기(초)와 기본 피해 배율. M4에서 (a) 주기만 줄임 (b) 주기와 피해를 같은 비율로 줄임을 잴 때 쓴다(P12)

const MAX_S := 1800.0
const MODES := ["fixed", "sqrt", "linear"]

func _initialize() -> void:
	call_deferred("_run")

func _arg(name: String, def: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else def

# 주기·피해 변형(기본은 JSON 그대로)
func _tune(cb: Dictionary) -> void:
	var period := _arg("--period", "")
	if period != "":
		cb.period_s = float(period)
	var scale := float(_arg("--dmg-scale", "1.0"))
	if scale != 1.0:
		for cat in cb.weapons:
			cb.weapons[cat].base_damage = float(cb.weapons[cat].base_damage) * scale

func _mix(n: int) -> Array:
	# 포격 25%, 전열 50%, 요격 17%, 보급 8% 정도의 비율
	var art := maxi(1, n / 4)
	var line := maxi(1, n / 2)
	var icp := maxi(1, n / 6)
	return [["SHP-03", art], ["SHP-04", line], ["SHP-07", icp], ["SHP-05", maxi(1, n - art - line - icp)]]

func _play_a(seed_id: int, mode: String) -> Dictionary:
	var F := SalvoFixture
	var s := F.sim([F.def("소", 300, 450, _mix(12), true)], [F.def("대", 1300, 450, _mix(32))], seed_id, mode, _tune)
	var f0: FleetState = s.st.fleets[0]
	var f1: FleetState = s.st.fleets[1]
	f0.target_id = f1.id
	f1.target_id = f0.id
	F.run(s, MAX_S)
	return _row(s)

func _play_b(seed_id: int, mode: String) -> Dictionary:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	p.combat.damage_mode = mode
	_tune(p.combat)
	var s := BattleSim.new(seed_id, BattleRules.TICK_HZ, p)
	var max_tick := int(MAX_S * s.st.hz)
	while not s.st.over and s.st.tick < max_tick:
		if s.st.tick % (5 * s.st.hz) == 0:
			for a in s.st.alive(0):
				var n := s.st.nearest_foe(a, 1e9)
				if n:
					s.queue(BattleSim.command(0, [a.id], "attack", n.id))
		s.step()
		s.drain_events()
	return _row(s)

func _row(s: BattleSim) -> Dictionary:
	var st := s.st
	return {"win": st.over and st.win, "reason": st.end_reason if st.over else "timeout",
		"t": st.end_ms / 1000.0 if st.over else st.clock_s(), "lost": st.lost / 1000.0, "killed": st.killed / 1000.0,
		"ally_alive": st.alive(0).size(), "foe_alive": st.alive(1).size()}

func _run() -> void:
	var runs := int(_arg("--runs", "100"))
	var scens := _arg("--scen", "A,B").split(",")
	var out := {}
	for sc in scens:
		out[sc] = {}
		for mode in MODES:
			var rows := []
			var t0 := Time.get_ticks_msec()
			for i in runs:
				rows.append(_play_a(i, mode) if sc == "A" else _play_b(i, mode))
			var wins := 0
			var mt := 0.0
			var ml := 0.0
			var mk := 0.0
			var reasons := {}
			for r in rows:
				wins += 1 if r.win else 0
				mt += r.t
				ml += r.lost
				mk += r.killed
				reasons[r.reason] = reasons.get(r.reason, 0) + 1
			var n := float(rows.size())
			out[sc][mode] = {"n": rows.size(), "win_rate": snappedf(wins / n, 0.001), "mean_t": snappedf(mt / n, 0.1),
				"mean_lost": snappedf(ml / n, 0.1), "mean_killed": snappedf(mk / n, 0.1), "reasons": reasons}
			print("%s %s: %s (%.1fs)" % [sc, mode, JSON.stringify(out[sc][mode]), (Time.get_ticks_msec() - t0) / 1000.0])
	var f := FileAccess.open(_arg("--out", "user://salvo_compare.json"), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(out, "\t"))
		f.close()
	print("SALVO_COMPARE_DONE")
	quit(0)
