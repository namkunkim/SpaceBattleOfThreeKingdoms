extends SceneTree

# M1 9단계: 자동 해결 실행기. 화면 없이 BattleSim만 돌려 정책 3종 × N시드의 통계 JSON을 낸다.
# --baseline 경로를 주면 §9.2 통계 동등성(승률 |Δ| ≤ 5%p, 길이·손실 KS D < 0.136)을 검사하고 실패하면 종료 코드 1.
#
# 실행: godot --headless --path . -s tests/autoresolve.gd -- --runs 200 [--hz 10] [--out user://autoresolve.json]
#        [--baseline res://tests/fixtures/m1_baseline.json] [--policies none,attack5,charge30]

const MAX_S := 1800.0
const KS_MAX := 0.136
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
			out[k] = {"test": "ks", "value": snappedf(d, 0.0001), "max": KS_MAX}
			if d >= KS_MAX:
				out.pass = false
	return out
