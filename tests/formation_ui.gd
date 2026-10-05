extends SceneTree

# 진형 탭(docs/ui/FORMATION-TAB-SPEC.md): 탭이 보낸 명령이 코어까지 가서 formation_id가 바뀌고, 카드가 투영 값을 그대로 보여 주는가.
# 헤드리스. 실패하면 종료 코드 1.

# BattleCommands가 호스트에게 바라는 것만 가진 가짜 호스트(코어 sim에 그대로 명령을 넘긴다)
class Host extends Node:
	var G := {"state": "play"}
	var sim: BattleSim
	var sel: Array = []
	var toasts: Array = []
	func my_sel() -> Array:
		return sel
	func issue(cmd: Dictionary) -> void:
		sim.issue(BattleSim.command(0, cmd.ids, cmd.kind, cmd.get("target_id", -1), cmd.get("point", Vector2.ZERO), cmd.get("args", {})))
	func refresh_panel() -> void:
		pass
	func toast(t: String) -> void:
		toasts.append(t)

func _initialize() -> void:
	call_deferred("_run")

func _sec(s: BattleSim, n: float) -> void:
	for i in int(n * s.st.hz):
		s.step()
		s.drain_events()

func _card(opts: Array, fid: String) -> Dictionary:
	for o in opts:
		if o.id == fid:
			return o
	return {}

func _sel(s: BattleSim, side_fleets: Array) -> Array:
	var proj := BattleProjection.build(s, 0)
	var out := []
	for q in proj.squadrons:
		if side_fleets.has(q.id):
			out.append(q)
	return out

func _run() -> void:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준")
	var sim := BattleSim.new(1, BattleRules.TICK_HZ, p)
	var combat: Dictionary = sim.salvo.C
	var mine: Array = []
	for f in sim.st.fleets:
		if f.side == 0:
			mine.append(f)
	var a: FleetState = mine[0]
	var host := Host.new()
	host.sim = sim
	host.sel = [a]
	var cmds := BattleCommands.new(host)

	# --- 1. 카드: 7종, 정본 이름·순서, 현재 진형 표시 ---
	var opts := FormationTab.options(combat, _sel(sim, [a.id]))
	if not TestCheck.ok(self, opts.size() == 7, "진형 카드 7종: %d" % opts.size()): return
	var names := []
	for o in opts:
		names.append(o.name)
	if not TestCheck.ok(self, names == ["어린진", "학익진", "방원진", "안행진", "봉시진", "장사진", "팔진"], "정본 이름·순서: %s" % str(names)): return
	if not TestCheck.ok(self, _card(opts, a.formation_id).state == "current", "현재 진형 칸"): return
	# 상성 힌트(학익 → 어린 → 방원 → 봉시 → 안행 → 학익), 팔진 무효, 장사진 ×0.9
	if not TestCheck.ok(self, "어린진에 강함" in _card(opts, "FRM-02").foot and "안행진에 약함" in _card(opts, "FRM-02").foot, "학익 상성 힌트"): return
	if not TestCheck.ok(self, "상성 판정 무효" in _card(opts, "FRM-07").foot and "피해 ×0.9" in _card(opts, "FRM-06").foot, "팔진·장사 힌트"): return
	if not TestCheck.ok(self, _card(opts, "FRM-01").fx[0][1] == "+10%" and _card(opts, "FRM-01").fx[1][1] == "−5%", "어린진 화력 +10%% 방어 −5%%"): return

	# --- 2. 명령 → 코어: 다른 진형을 고르면 전환이 시작되고 남은 시간이 투영에 나온다 ---
	var target := "FRM-04" if a.formation_id != "FRM-04" else "FRM-02"
	var before: String = a.formation_id
	cmds.do_formation(target)
	sim.drain_events()
	if not TestCheck.ok(self, a.form_to == target and a.formation_id == before, "명령 직후 전환 시작(진형은 아직 이전)"): return
	opts = FormationTab.options(combat, _sel(sim, [a.id]))
	var c := _card(opts, target)
	if not TestCheck.ok(self, c.state == "to" and c.line.begins_with("전환 "), "전환 중 카드: %s" % c.line): return
	if not TestCheck.ok(self, _card(opts, before).cancel, "현재 진형 칸은 전환 취소"): return
	_sec(sim, 61.0)
	if not TestCheck.ok(self, a.formation_id == target and a.form_to == "", "전환 완료 후 formation_id 변경"): return
	if not TestCheck.ok(self, _card(FormationTab.options(combat, _sel(sim, [a.id])), target).state == "current", "완료 후 현재 칸"): return

	# --- 3. 현재 진형을 다시 고르면 전환 취소(코어 규칙) ---
	var other := "FRM-03" if target != "FRM-03" else "FRM-01"
	cmds.do_formation(other)
	sim.drain_events()
	cmds.do_formation(target)
	sim.drain_events()
	if not TestCheck.ok(self, a.form_to == "" and a.formation_id == target, "전환 취소"): return

	# --- 4. 선택 불가: 팔진은 조건 미달 전대에게 잠김이고, UI는 코어 사유를 그대로 보여 준다. 코어도 거부한다 ---
	var m := _card(FormationTab.options(combat, _sel(sim, [a.id])), "FRM-07")
	var master := sim.salvo.master_ok(a)
	if not master:
		if not TestCheck.ok(self, m.state == "locked" and "통솔 90" in m.reason and "신기묘산" in m.reason, "팔진 잠김 사유: %s" % m.reason): return
		cmds.do_formation("FRM-07")
		var rejected := ""
		for e in sim.drain_events():
			if e.kind == "rejected":
				rejected = str(e.value)
		if not TestCheck.ok(self, rejected == "formation_master" and a.form_to == "", "코어가 팔진 거부: " + rejected): return

	# --- 5. 여러 전대 선택: 같은 명령이 전원에게 간다(그룹 진형도 formation_to(ids) 하나로 보낸다) ---
	var b: FleetState = mine[1]
	host.sel = [a, b]
	var t2 := "FRM-05" if a.formation_id != "FRM-05" and b.formation_id != "FRM-05" else "FRM-01"
	cmds.do_formation(t2)
	sim.drain_events()
	if not TestCheck.ok(self, a.form_to == t2 and b.form_to == t2, "선택 전대 모두 전환 시작"): return

	# --- 6. POC 규칙(진형 정보 없음)이면 카드가 없다 ---
	if not TestCheck.ok(self, FormationTab.options({}, [{"formation_id": ""}]).is_empty(), "POC는 카드 없음"): return

	print("FORMATION_UI_PASS")
	quit(0)
