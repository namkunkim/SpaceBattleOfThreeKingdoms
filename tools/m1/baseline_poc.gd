extends SceneTree

# M1 0단계: 현행 POC(FleetBattle3D.gd, M1 이전 커밋)의 자동 해결 기준선을 잡는다.
# seed(i), dt 0.05(20Hz)로 정책 3종 × N회를 헤드리스로 돌려 tests/fixtures/m1_baseline.json에 쓴다.
# 그리기(_draw_fx)가 전역 난수를 쓰므로 프레임을 돌리지 않고 update_sim만 직접 부른다.
# 이 스크립트는 M1 이전 POC API에 기대므로 기준선 커밋에서만 돈다. 이후 비교는 tests/autoresolve.gd가 한다.
#
# 실행: godot --headless --path . -s tools/m1/baseline_poc.gd -- --runs 200 [--out path]

const DT := 0.05
const MAX_T := 1800.0
const POLICIES := ["none", "attack5", "charge30"]

func _initialize() -> void:
	call_deferred("_run")

func _arg(name: String, def: String) -> String:
	var a := OS.get_cmdline_user_args()
	var i := a.find(name)
	return a[i + 1] if i >= 0 and i + 1 < a.size() else def

func _run() -> void:
	var runs := int(_arg("--runs", "200"))
	var out_path := _arg("--out", "res://tests/fixtures/m1_baseline.json")
	var scene := load("res://scenes/FleetBattle3D.tscn") as PackedScene
	var battle := scene.instantiate()
	root.add_child(battle)
	await process_frame
	var result := {"meta": {
		"source": "scripts/FleetBattle3D.gd (M1 이전 POC)", "dt": DT, "max_t": MAX_T, "runs": runs,
		"seeding": "seed(i) after _restart(), i = 0..runs-1",
		"policies": {
			"none": "명령 없음",
			"attack5": "5초마다(0,5,10..) 아군 전대마다 최근접 적 공격 명령, 이어서 전 함대 선택 후 미사일·함재기 명령",
			"charge30": "30초에 전 함대 선택 후 돌격 1회",
		},
	}, "policies": {}}
	for pol in _arg("--policies", ",".join(POLICIES)).split(","):
		var rows := []
		var t0 := Time.get_ticks_msec()
		for i in range(int(_arg("--from", "0")), int(_arg("--from", "0")) + runs):
			battle.G.state = "end"
			await process_frame
			battle._restart()
			seed(i)
			rows.append(_play(battle, pol))
		result.policies[pol] = {"runs": rows, "summary": summarize(rows)}
		print("%s: %s (%.1fs)" % [pol, JSON.stringify(result.policies[pol].summary), (Time.get_ticks_msec() - t0) / 1000.0])
	var f := FileAccess.open(out_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, "\t"))
	f.close()
	battle.queue_free()
	await process_frame
	print("M1_BASELINE_DONE")
	quit(0)

func _play(b, pol: String) -> Dictionary:
	var step := 0
	var reinf_t := -1.0
	var charged := false
	while not b.G.over and b.G.t < MAX_T:
		if pol == "attack5" and step % 100 == 0:
			for f in b.alive(0):
				var t = b.nearest_foe(f, 1e9)
				if t:
					b.selected.assign([f])
					b.order_attack(t)
			b.selected = b.alive(0)
			b.do_cmd("missile")
			b.do_cmd("fighter")
		elif pol == "charge30" and not charged and b.G.t >= 30.0 - 1e-6:
			charged = true
			b.selected = b.alive(0)
			b.do_cmd("charge")
		b.update_sim(DT)
		step += 1
		if reinf_t < 0.0 and b.G.reinf:
			reinf_t = b.G.t
	var reason := "timeout"
	if b.G.over:
		reason = "annihilation" if b.G.end_win else "flagship_lost"
	return {"win": b.G.over and b.G.end_win, "reason": reason, "t": snappedf(b.G.t, 0.001),
		"lost": snappedf(b.G.lost, 0.001), "killed": snappedf(b.G.killed, 0.001), "reinf_t": snappedf(reinf_t, 0.001),
		"ally_alive": b.alive(0).size(), "foe_alive": b.alive(1).size()}

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
