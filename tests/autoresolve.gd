extends SceneTree

# M1 9단계: 자동 해결 실행기. 화면 없이 BattleSim만 돌려 정책 3종 × N시드의 통계 JSON을 낸다.
# --baseline 경로를 주면 §9.2 통계 동등성(승률 |Δ| ≤ 5%p, 길이·손실 KS D < 0.136)을 검사하고 실패하면 종료 코드 1.
#
# 실행: godot --headless --path . -s tests/autoresolve.gd -- --runs 200 [--hz 10] [--out user://autoresolve.json]
#        [--baseline res://tests/fixtures/m1_baseline.json] [--policies none,attack5,charge30]
# M4 적벽 기준선: --profile red_cliffs [--difficulty 표준] [--policies none,attack] [--period 15] [--dmg-scale 0.25] [--stagger 15] [--org auto]
#   BALANCE-PLAN-M4 §3의 측정값(길이, 승률, 종료 경로, 첫 일제 동기화, 파도, 사기 곡선)을 판마다 한 줄로 낸다. 정책 attack은 5초마다 가까운 적 공격(일제사격 명령 없음)

const MAX_S := 1800.0
# KS 통계량 D의 한계는 제안서 §9.2의 0.136(효과 크기 기준)이다. 200 대 200에서 0.136은 5% 유의수준 임계값과 같아
# 완전히 같은 구현도 지표 12개 중 하나쯤 우연히 넘을 수 있다(M1 측정: 200시드 charge30 길이 D 0.16, 1000시드 0.036).
# 그래서 판정은 1000시드(--runs 1000)로 하고, 표본 크기에 맞춘 5% 유의 임계값은 참고로만 남긴다.
const KS_MAX := 0.136
const KS_C := 1.36
const WIN_MAX := 0.05
const KS_KEYS := ["t", "lost", "killed", "reinf_t"]
# 기준선의 변동계수가 이보다 작은(거의 상수인) 변수는 KS 대신 평균의 상대 차이로 본다(컨셉 세션 조정, §9.2).
const NEAR_CONST_CV := 0.01
const MEAN_REL_MAX := 0.01
const REASON_MAX := 0.05

func _initialize() -> void:
	call_deferred("_run")

func _arg(name: String, def: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else def

func _run() -> void:
	var runs := int(_arg("--runs", "200"))
	var hz := int(_arg("--hz", str(BattleRules.TICK_HZ)))
	var out_path := _arg("--out", "user://autoresolve.json")
	var base_path := _arg("--baseline", "")
	var pols := _arg("--policies", "none,attack5,charge30").split(",")
	if _arg("--profile", "") == "red_cliffs":
		_run_rc(runs, out_path, _arg("--policies", "none,attack").split(","))
		return
	var result := {"meta": {"hz": hz, "runs": runs, "max_s": MAX_S}, "policies": {}}
	var ok := true
	var base := {}
	if base_path != "":
		base = JSON.parse_string(FileAccess.get_file_as_string(base_path))
	for pol in pols:
		var rows := []
		var t0 := Time.get_ticks_msec()
		for i in runs:
			rows.append(play(i, hz, pol))
		var summ := summarize(rows)
		result.policies[pol] = {"runs": rows, "summary": summ}
		print("%s: %s (%.1fs)" % [pol, JSON.stringify(summ), (Time.get_ticks_msec() - t0) / 1000.0])
		if not base.is_empty() and base.policies.has(pol):
			var cmp := compare(base.policies[pol].runs, rows)
			result.policies[pol]["compare"] = cmp
			print("  vs baseline: %s" % JSON.stringify(cmp))
			if not cmp.pass:
				ok = false
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "\t"))
		f.close()
	if not ok:
		push_error("TEST_FAIL autoresolve: 통계 동등성 실패")
		quit(1)
		return
	print("AUTORESOLVE_PASS")
	quit(0)

# 정책은 공개 투영만 읽고 명령만 낸다(플레이어 입력과 같은 경로).
static func policy_commands(pol: String, p: Dictionary) -> Array:
	var out := []
	var tick: int = p.tick
	var hz: int = p.hz
	var allies := []
	var foes := []
	for s in p.squadrons:
		if s.dead:
			continue
		(allies if s.side == 0 else foes).append(s)
	if allies.is_empty():
		return out
	var ids := []
	for a in allies:
		ids.append(a.id)
	if pol == "attack5" and tick % (5 * hz) == 0:
		for a in allies:
			var best = null
			var bd := 1e9
			for o in foes:
				var d: float = (a.pos as Vector2).distance_to(o.pos)
				if d < bd:
					bd = d
					best = o
			if best:
				out.append(BattleSim.command(0, [a.id], "attack", best.id))
		out.append(BattleSim.command(0, ids, "missile"))
		out.append(BattleSim.command(0, ids, "fighter"))
	elif pol == "charge30" and tick == 30 * hz:
		out.append(BattleSim.command(0, ids, "charge"))
	return out

static func play(seed_id: int, hz: int, pol: String) -> Dictionary:
	var sim := BattleSim.new(seed_id, hz)
	var max_tick := int(MAX_S * hz)
	while not sim.st.over and sim.st.tick < max_tick:
		if pol != "none":
			for c in policy_commands(pol, sim.projection(0)):
				sim.queue(c)
		sim.step()
		sim.drain_events()
	var st := sim.st
	return {"win": st.over and st.win, "reason": st.end_reason if st.over else "timeout",
		"t": st.end_ms / 1000.0 if st.over else st.clock_s(), "lost": st.lost / 1000.0, "killed": st.killed / 1000.0,
		"reinf_t": (st.reinf_ms / 1000.0) if st.reinf else -1.0,
		"ally_alive": st.alive(0).size(), "foe_alive": st.alive(1).size(),
		"fp": sim.fingerprint(), "commands": sim.command_log.size()}

static func summarize(rows: Array) -> Dictionary:
	var wins := 0
	var reasons := {}
	var keys := ["t", "lost", "killed", "reinf_t"]
	var sums := {}
	for k in keys:
		sums[k] = 0.0
	for r in rows:
		if r.win:
			wins += 1
		reasons[r.reason] = reasons.get(r.reason, 0) + 1
		for k in keys:
			sums[k] += float(r[k])
	var s := {"n": rows.size(), "win_rate": float(wins) / maxf(1.0, rows.size()), "reasons": reasons}
	for k in keys:
		s["mean_" + k] = snappedf(sums[k] / maxf(1.0, rows.size()), 0.01)
	return s

static func ks(a: Array, b: Array) -> float:
	var x := a.duplicate()
	var y := b.duplicate()
	x.sort()
	y.sort()
	var i := 0
	var j := 0
	var d := 0.0
	while i < x.size() and j < y.size():
		var v: float = minf(x[i], y[j])
		while i < x.size() and x[i] <= v:
			i += 1
		while j < y.size() and y[j] <= v:
			j += 1
		d = maxf(d, absf(float(i) / x.size() - float(j) / y.size()))
	return d

static func compare(base_rows: Array, rows: Array) -> Dictionary:
	var out := {"pass": true}
	var ks_max := KS_MAX
	out.ks_crit_5pct = snappedf(KS_C * sqrt(1.0 / base_rows.size() + 1.0 / rows.size()), 0.0001)
	var wb := 0.0
	var wn := 0.0
	for r in base_rows:
		wb += 1.0 if r.win else 0.0
	for r in rows:
		wn += 1.0 if r.win else 0.0
	out.win_delta = snappedf(wn / rows.size() - wb / base_rows.size(), 0.0001)
	if absf(out.win_delta) > WIN_MAX:
		out.pass = false
	# 종료 경로 분포: 경로마다 비율 차이 ≤ 5%p
	var reasons := {}
	for r in base_rows:
		reasons[r.reason] = true
	for r in rows:
		reasons[r.reason] = true
	out.reason_delta = {}
	for k in reasons:
		var a := 0.0
		var b := 0.0
		for r in base_rows:
			a += 1.0 if r.reason == k else 0.0
		for r in rows:
			b += 1.0 if r.reason == k else 0.0
		var dd := b / rows.size() - a / base_rows.size()
		out.reason_delta[k] = snappedf(dd, 0.0001)
		if absf(dd) > REASON_MAX:
			out.pass = false
	for k in KS_KEYS:
		var xa := []
		var xb := []
		for r in base_rows:
			xa.append(float(r[k]))
		for r in rows:
			xb.append(float(r[k]))
		var m := 0.0
		for v in xa:
			m += v
		m /= xa.size()
		var var_ := 0.0
		for v in xa:
			var_ += (v - m) * (v - m)
		var sd := sqrt(var_ / xa.size())
		if absf(m) > 1e-9 and sd / absf(m) < NEAR_CONST_CV:
			var mb := 0.0
			for v in xb:
				mb += v
			mb /= xb.size()
			var rel := absf(mb - m) / absf(m)
			out[k] = {"test": "mean_rel", "value": snappedf(rel, 0.0001), "max": MEAN_REL_MAX}
			if rel > MEAN_REL_MAX:
				out.pass = false
		else:
			var d := ks(xa, xb)
			out[k] = {"test": "ks", "value": snappedf(d, 0.0001), "max": snappedf(ks_max, 0.0001)}
			if d >= ks_max:
				out.pass = false
	return out


# ============================================================ M4 적벽 기준선
func _tune(cb: Dictionary) -> void:
	var period := _arg("--period", "")
	if period != "":
		cb.period_s = float(period)
	var scale := float(_arg("--dmg-scale", "1.0"))
	if scale != 1.0:
		for cat in cb.weapons:
			cb.weapons[cat].base_damage = float(cb.weapons[cat].base_damage) * scale
	var stag := _arg("--stagger", "")
	if stag != "":
		cb.first_volley_stagger_s.value = float(stag)
	# M6 탐지 재조정 레버(수치는 데이터 그대로가 기본). --fog 0이면 안개를 끈다(완전 정보, M5 기준선과 비교용)
	if _arg("--fog", "1") == "0":
		cb.erase("detection")
	elif cb.has("detection"):
		if _arg("--confirmed", "") != "":
			cb.detection.confirmed = int(_arg("--confirmed", ""))
		if _arg("--estimated", "") != "":
			cb.detection.estimated = int(_arg("--estimated", ""))
	if _arg("--terrain", "1") == "0":
		cb.erase("terrain")

func _run_rc(runs: int, out_path: String, pols: Array) -> void:
	var diff := _arg("--difficulty", "표준")
	var result := {"meta": {"runs": runs, "difficulty": diff, "period": _arg("--period", ""), "dmg_scale": _arg("--dmg-scale", "1.0"),
		"stagger": _arg("--stagger", ""), "org": _arg("--org", "")}, "policies": {}}
	var from := int(_arg("--from", "0"))
	for pol in pols:
		var rows := []
		var t0 := Time.get_ticks_msec()
		for i in runs:
			rows.append(play_rc(from + i, pol, diff))
		var summ := summarize_rc(rows)
		result.policies[pol] = {"runs": rows if _arg("--rows", "0") == "1" else [], "summary": summ}
		print("%s %s: %s (%.1fs)" % [diff, pol, JSON.stringify(summ), (Time.get_ticks_msec() - t0) / 1000.0])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(result, "	"))
		f.close()
	print("AUTORESOLVE_RC_DONE")
	quit(0)

func play_rc(seed_id: int, pol: String, diff: String) -> Dictionary:
	var ov := {}
	if _arg("--cao-fleets", "") != "":
		ov.cao_fleets = int(_arg("--cao-fleets", ""))   # 레버 측정(Q82): 난이도의 조조 함대 수
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", diff, ov)
	if _arg("--org", "") == "auto":   # O1·Q81: 세 세력 자동 편성(O3 기준선)
		var scn := ProfileLoader.read_json(ProfileLoader.read_json("res://data/profiles/red_cliffs_rt.json").scenario_path)
		var org := Organization.default_org(p)
		for fid in ["liu_bei", "sun_quan", "cao_cao"]:
			org = Organization.auto_fill(org, fid, scn, p)
		p = Organization.apply(p, org, scn)
		if p.has("errors"):   # REVIEW-O1b #1: 검증 실패면 사본 대신 errors가 온다
			push_error("org auto rejected: %s" % [p.errors])
			quit(1)
			return {}
	_tune(p.combat)
	# M9 비교: --no-chain 1(화공 끔), --no-m9 1(화공·승계·강습 모두 끔 = M8 코드와 같은 판), --wind "540,600"(기류 창 시작 범위)
	if _arg("--no-chain", "0") == "1" or _arg("--no-m9", "0") == "1":
		p.scenario.realtime_rules.erase("chain_operation")
	if _arg("--no-m9", "0") == "1":
		for k in ["command", "stratagem", "assault"]:
			p.combat.erase(k)
	if _arg("--wind", "") != "":
		var w := _arg("--wind", "").split(",")
		p.scenario.realtime_rules.wind_window.start_after_first_hit_s = [int(w[0]), int(w[1])]
	var sim := BattleSim.new(seed_id, BattleRules.TICK_HZ, p)
	var hz: int = sim.st.hz
	var max_tick := int(MAX_S * hz)
	var first_fire := {}      # 전대 id → 첫 일제 틱
	var first_hit := -1
	var retreats := []
	var curve := []
	var conf_t := [-1, -1]       # 진영별 첫 확인 접촉 틱(M6)
	var conf_n := [0, 0]         # 진영별 확인 접촉이 하나라도 있던 표본 수
	var samples := 0
	var sup := [[0, 0, 0, 0], [0, 0, 0, 0]]   # M8 진영별 [보급 주기, 탄약 보충, 수리, 경파 회복 척 수]
	while not sim.st.over and sim.st.tick < max_tick:
		if pol == "attack" and sim.st.tick % (5 * hz) == 0:
			for a in sim.st.alive(0):
				var n := sim.sight_foe(a, 1e9)   # 플레이어도 접촉이 있는 적만 지정할 수 있다(M6)
				if n:
					sim.queue(BattleSim.command(0, [a.id], "attack", n.id))
		elif pol == "charge30" and sim.st.tick == 30 * hz:
			var ids := []
			for a in sim.st.alive(0):
				ids.append(a.id)
			sim.queue(BattleSim.command(0, ids, "charge"))
		sim.step()
		if sim.detect and sim.st.tick % hz == 0:
			samples += 1
			for sd in 2:
				var any := false
				for k in sim.detect.contacts[sd]:
					if sim.detect.contacts[sd][k].state == "confirmed":
						any = true
				if any:
					conf_n[sd] += 1
					if conf_t[sd] < 0:
						conf_t[sd] = sim.st.tick
		for e in sim.drain_events():
			if e.kind == "salvo":
				if not first_fire.has(e.sq):
					first_fire[e.sq] = e.tick
				if first_hit < 0 and e.value.hit:
					first_hit = e.tick
			elif e.kind == "supply":
				var sd: int = sim.st.by_id(e.sq).side
				sup[sd][0] += 1
				sup[sd][1] += int(e.value.ammo > 0)
				sup[sd][2] += int(e.value.repair)
			elif e.kind == "light_recovered":
				sup[sim.st.by_id(e.sq).side][3] += int(e.value)
			elif e.kind == "morale_state" and e.value.to == "retreat":
				retreats.append([snappedf(e.tick / float(hz), 0.1), sim.st.by_id(e.sq).sq_id])
		if sim.st.tick % (30 * hz) == 0:
			curve.append([sim.morale.army_bp(0), sim.morale.army_bp(1)])
	var st := sim.st
	var r := st.result
	# 첫 일제 동기화: 같은 진영에서 첫 일제가 같은 초에 겹치는 전대의 비율(전대가 둘 이상일 때)
	var sync := [0, 0]
	var by_sec := {}
	for id in first_fire:
		var f := st.by_id(id)
		var k := "%d:%d" % [f.side, first_fire[id] / hz]
		by_sec[k] = by_sec.get(k, 0) + 1
	var fired := [0, 0]
	for id in first_fire:
		var f := st.by_id(id)
		fired[f.side] += 1
		if by_sec["%d:%d" % [f.side, first_fire[id] / hz]] > 1:
			sync[f.side] += 1
	var join := {}
	for id in first_fire:
		var f := st.by_id(id)
		if f.side == 1:
			join[f.sq_id] = snappedf(first_fire[id] / float(hz), 0.1)
	var res := r if st.over else {}
	return {"seed": seed_id, "win": st.over and st.win, "reason": st.end_reason if st.over else "timeout", "limited": bool(r.get("limited", false)),
		"t": st.end_ms / 1000.0 if st.over else st.clock_s(),
		"ally_cost_loss_bp": int(res.cost.alliance.loss_bp) if st.over else -1, "foe_cost_loss_bp": int(res.cost.foe.loss_bp) if st.over else -1,
		"first_hit_t": snappedf(first_hit / float(hz), 0.1) if first_hit >= 0 else -1.0,
		"sync_ally": float(sync[0]) / maxf(1.0, fired[0]), "sync_foe": float(sync[1]) / maxf(1.0, fired[1]),
		"fired_ally": fired[0], "fired_foe": fired[1],
		"join": join, "retreats": retreats, "curve": curve,
		"army_end": [sim.morale.army_bp(0), sim.morale.army_bp(1)], "plague_bp": sim.morale.plague_bp_total,
		"conf_t": [snappedf(conf_t[0] / float(hz), 0.1) if conf_t[0] >= 0 else -1.0, snappedf(conf_t[1] / float(hz), 0.1) if conf_t[1] >= 0 else -1.0],
		"conf_share": [float(conf_n[0]) / maxf(1.0, samples), float(conf_n[1]) / maxf(1.0, samples)],
		"supply": sup,
		"m9": _m9_row(sim),
		"fp": sim.fingerprint()}

# M9 통계: 화공 경과(서신·발동·간파·번짐·차단·창 시각), 승계, 강습 [시도, 성공]
static func _m9_row(sim: BattleSim) -> Dictionary:
	var out := {}
	if sim.chain:
		var c := sim.chain
		out.chain = c.stats.duplicate(true)
		out.chain.mode = c.mode
		out.chain.win_start_s = c.win_start / float(sim.st.hz) if c.win_start >= 0 else -1.0
	if sim.cmd:
		out.cmd = sim.cmd.stats.duplicate()
	if sim.assault:
		out.assault = sim.assault.stats.duplicate(true)
	return out

static func summarize_rc(rows: Array) -> Dictionary:
	var n := float(rows.size())
	var wins := 0
	var reasons := {}
	var ts := []
	var sums := {"sync_ally": 0.0, "sync_foe": 0.0, "first_hit_t": 0.0, "ally_loss": 0.0, "foe_loss": 0.0, "plague": 0.0, "retreats": 0.0}
	var limited := 0
	var wave_n := {}
	var conf_ever := [0, 0]      # 한 번이라도 확인 접촉을 얻은 판 수(M6)
	var conf_first := [0.0, 0.0]
	var conf_share := [0.0, 0.0]
	for r in rows:
		wins += 1 if r.win else 0
		limited += 1 if r.limited else 0
		reasons[r.reason] = reasons.get(r.reason, 0) + 1
		ts.append(r.t)
		sums.sync_ally += r.sync_ally
		sums.sync_foe += r.sync_foe
		sums.first_hit_t += r.first_hit_t
		sums.ally_loss += maxf(0, r.ally_cost_loss_bp)
		sums.foe_loss += maxf(0, r.foe_cost_loss_bp)
		sums.plague += r.plague_bp
		sums.retreats += r.retreats.size()
		for sd in 2:
			if r.conf_t[sd] >= 0.0:
				conf_ever[sd] += 1
				conf_first[sd] += r.conf_t[sd]
			conf_share[sd] += r.conf_share[sd]
		for k in r.join:
			wave_n[k] = wave_n.get(k, 0.0) + r.join[k]
	ts.sort()
	var q := func(p: float) -> float: return ts[mini(ts.size() - 1, int(p * ts.size()))] if not ts.is_empty() else 0.0
	var wave := {}
	for k in wave_n:
		wave[k] = snappedf(wave_n[k] / n, 0.1)
	var se := sqrt(float(wins) / n * (1.0 - float(wins) / n) / n)
	return {"n": rows.size(), "win_rate": snappedf(wins / n, 0.001), "win_se": snappedf(se, 0.001), "limited": limited,
		"reasons": reasons, "t_mean": snappedf(float(ts.reduce(func(a, b): return a + b, 0.0)) / n, 0.1),
		"t_p10": q.call(0.1), "t_median": q.call(0.5), "t_p90": q.call(0.9),
		"first_hit_t": snappedf(sums.first_hit_t / n, 0.1), "sync_ally": snappedf(sums.sync_ally / n, 0.001), "sync_foe": snappedf(sums.sync_foe / n, 0.001),
		"ally_cost_loss_bp": snappedf(sums.ally_loss / n, 1.0), "foe_cost_loss_bp": snappedf(sums.foe_loss / n, 1.0),
		"plague_bp": snappedf(sums.plague / n, 1.0), "retreats": snappedf(sums.retreats / n, 0.01), "join_mean_s": wave,
		"confirm_ally": snappedf(conf_ever[0] / n, 0.001), "confirm_foe": snappedf(conf_ever[1] / n, 0.001),
		"confirm_first_ally_s": snappedf(conf_first[0] / maxf(1.0, conf_ever[0]), 0.1), "confirm_first_foe_s": snappedf(conf_first[1] / maxf(1.0, conf_ever[1]), 0.1),
		"confirm_share_ally": snappedf(conf_share[0] / n, 0.001), "confirm_share_foe": snappedf(conf_share[1] / n, 0.001)}
