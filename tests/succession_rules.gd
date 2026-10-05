extends SceneTree

# M9 완료 기준(제안서 §4.14, 본편 V-74 / G8-04): 전대 지휘관 상태(항복 포로, 격침 운명, 남은 척 < 40% 중상, < 75% 경상, 악화만),
# 중상이면 부지휘관 → 첫 참모가 능력치를 잇는다, 함대 제독이 지휘 불능이면 부함장(동승 → 기함 유지, 자기 전대 → 그 전대가 기함)
# → 소속 전대 지휘관(레벨 → 통솔 → ID), 60초 혼선(2단계: 기동 −10%, 명중 −8%, 진형 변경 −16%), 지휘 공백은 끝까지,
# 지휘 한도 초과 단계, 결집 제한, 결산 사상 목록, 투영(자기 진영만). 헤드리스, 실패하면 종료 코드 1.

const SQ := {"liu": "RC-LIU-SQ-01", "guan": "RC-LIU-SQ-02", "liuqi": "RC-LIU-SQ-03", "zhao": "RC-LIU-FC-01",
	"zhou": "RC-SUN-SQ-01", "cheng": "RC-SUN-SQ-02", "cao": "RC-CAO-SQ-01", "ren": "RC-CAO-SQ-02", "xu": "RC-CAO-SQ-03",
	"wen": "RC-CAO-SQ-04", "hong": "RC-CAO-SQ-07"}

func _initialize() -> void:
	call_deferred("_run")

func _sim(diff := "표준") -> BattleSim:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", diff)
	var s := BattleSim.new(1, BattleRules.TICK_HZ, p)
	s.st.ai_timer = 1 << 40   # AI 끔
	return s

func _f(s: BattleSim, key: String) -> FleetState:
	for f in s.st.fleets:
		if f.sq_id == SQ.get(key, key):
			return f
	return null

func _ticks(s: BattleSim, n: int) -> Array:
	var evs := []
	for i in n:
		s.step()
		evs.append_array(s.drain_events())
	return evs

# 남은 척 비율이 keep_bp 근처가 되게 선체를 깎는다
func _wreck(s: BattleSim, f: FleetState, keep_bp: int) -> void:
	s.salvo.apply_hull(null, f, float(f.max_hull * (BattleRules.BP - keep_bp) / BattleRules.BP), "engagement", "front", s.st.new_event_id())

func _ratio(s: BattleSim, f: FleetState) -> int:
	return s.salvo.present_ships(f) * BattleRules.BP / s.salvo.total0(f)

func _group(s: BattleSim, id: String) -> Dictionary:
	return s.cmd.groups.filter(func(g): return g.id == id)[0]

func _run() -> void:
	var s := _sim()
	if not TestCheck.ok(self, s.cmd != null and str(s.rs.rt("commander_succession.status")) == "proposed" and int(s.cmd.K.limit_base) == 40, "데이터: 승계 제안값, 지휘 한도 40 + 통솔 × 2"): return

	# --- 선체 구간(척 수 비율): < 75% 경상(지휘 유지), < 40% 중상(지휘 불능 → 부지휘관이 잇는다). 악화만 ---
	var cheng := _f(s, "cheng")
	_wreck(s, cheng, 6500)
	var evs := _ticks(s, 1)
	if not TestCheck.ok(self, _ratio(s, cheng) < 7500 and _ratio(s, cheng) >= 4000 and cheng.cmdr_state == "light" and cheng.cmd_stat == 84, "경상: 지휘 유지 (%d bp)" % _ratio(s, cheng)): return
	_wreck(s, cheng, 4500)
	evs = _ticks(s, 1)
	var sub: Array = evs.filter(func(e): return e.kind == "commander_sub" and e.sq == cheng.id)
	if not TestCheck.ok(self, _ratio(s, cheng) < 4000 and cheng.cmdr_state == "severe" and cheng.cmdr_sub == "CHR-0212" and cheng.cmd_stat == 78 and int(cheng.stats.might) == 90 and sub.size() == 1, "중상: 부지휘관 주태가 잇는다"): return
	var g_sun := _group(s, "RC-SUN-FLT-01")
	if not TestCheck.ok(self, g_sun.leader == "CHR-0211" and g_sun.vice == "CHR-0207", "정보는 제독이 아니라 주유 수군 승계는 없다"): return

	# --- 유비 중상 → 부함장 제갈량(기함 동승): 기함 유지, 함대 60초 혼선, 전투 계속 ---
	s = _sim()
	var liu := _f(s, "liu")
	var guan := _f(s, "guan")
	var t := _f(s, "wen")
	guan.pos = t.pos + Vector2(-150, 0)
	guan.heading = 0.0
	s.detect.contacts[0][t.id] = {"seen": 0, "pos": t.pos, "state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}
	var hit0 := s.salvo.hit_bp(guan, t, "line_fire")
	var tr0 := s.salvo.transition_ticks(guan, "FRM-03")
	var sp0 := 1.0 + s.cmd.penalty(guan, "move_pct")
	_wreck(s, liu, 1500)
	evs = _ticks(s, 1)
	var g := _group(s, "RC-LIU-FLT-01")
	var su: Array = evs.filter(func(e): return e.kind == "succession")
	if not TestCheck.ok(self, liu.cmdr_state == "severe" and su.size() == 1 and g.leader == "CHR-0134" and g.flag_sq == SQ.liu and g.aboard and liu.is_flag and not s.st.over, "유비 중상 → 제갈량 승계, 기함 유지 %s" % [g]): return
	if not TestCheck.ok(self, liu.cmdr_sub == "CHR-0130" and liu.cmd_stat == 88, "유비 전대는 장비가 잇는다"): return
	if not TestCheck.ok(self, s.cmd.confused(guan) and s.cmd.confused(_f(s, "zhao")) and not s.cmd.confused(_f(s, "liuqi")) and not s.cmd.confused(_f(s, "zhou")), "혼선: 같은 함대만"): return
	if not TestCheck.ok(self, s.cmd.stages(guan) == 2 and sp0 == 1.0 and absf(s.cmd.penalty(guan, "move_pct") + 0.10) < 1e-9, "2단계: 기동 −10%"): return
	s.detect.contacts[0][t.id] = {"seen": 0, "pos": t.pos, "state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}
	var cu := guan.confuse_until
	guan.confuse_until = -1
	hit0 = s.salvo.hit_bp(guan, t, "line_fire")   # 같은 순간의 혼선 없는 값
	guan.confuse_until = cu
	if not TestCheck.ok(self, hit0 > 0 and s.salvo.hit_bp(guan, t, "line_fire") == roundi(hit0 * 0.92), "명중 −8%%: %d → %d" % [hit0, s.salvo.hit_bp(guan, t, "line_fire")]): return
	if not TestCheck.ok(self, s.salvo.transition_ticks(guan, "FRM-03") == BattleRules.ticks(float(tr0) / 10.0 / 0.84, 10), "진형 변경 속도 −16%%: %d → %d틱" % [tr0, s.salvo.transition_ticks(guan, "FRM-03")]): return
	var q: Array = s.projection(0).squadrons.filter(func(x): return x.id == guan.id)
	if not TestCheck.ok(self, q[0].penalty_stages == 2 and q[0].confusion_s > 59.0 and q[0].commander_state == "unhurt", "투영: 자기 전대 혼선·불이익 단계"): return
	guan.pos = Vector2(200, 800)   # 교전에서 떼어 둔다(다치면 관우는 이을 사람이 없어 끝까지 혼선)
	_ticks(s, 600)
	if not TestCheck.ok(self, guan.cmdr_state == "unhurt" and not s.cmd.confused(guan) and s.cmd.stages(guan) == 0, "60초 뒤 혼선 끝"): return
	if not TestCheck.ok(self, s.morale.rally(0, "liu_bei_rally") == "", "유비 중상이어도 이은 사람(장비)이 결집한다"): return

	# --- 조조 중상 → 부함장 조인(자기 전대): 조인 전대가 함대 기함, 승패 기함은 그대로 ---
	s = _sim()
	var cao := _f(s, "cao")
	_wreck(s, cao, 3500)
	_ticks(s, 1)
	g = _group(s, "RC-CAO-FLT-01")
	if not TestCheck.ok(self, g.leader == "CHR-0033" and g.flag_sq == SQ.ren and not g.aboard and cao.is_flag and s.cmd.confused(_f(s, "xu")) and not s.cmd.confused(_f(s, "wen")), "조조 중상 → 조인 승계, 조인 전대가 함대 기함 %s" % [g]): return
	# 이은 사람도 지휘 불능 → 다음 후보(레벨 → 통솔 → ID). 부함장은 한 번만
	_wreck(s, _f(s, "ren"), 3500)
	_ticks(s, 1)
	g = _group(s, "RC-CAO-FLT-01")
	if not TestCheck.ok(self, g.leader == "CHR-0017" and g.flag_sq == SQ.xu, "조인도 중상 → 서황 %s" % [g]): return
	# 상급: 레벨이 높은 사람이 먼저
	s = _sim("상급")
	s.remove_fleet(_f(s, "ren"), "surrender")
	_f(s, "hong").level = 2
	_wreck(s, _f(s, "cao"), 3500)
	_ticks(s, 1)
	g = _group(s, "RC-CAO-FLT-01")
	if not TestCheck.ok(self, g.leader == "CHR-0036" and g.flag_sq == SQ.hong, "부함장 없음(항복) → 레벨 2 조홍이 통솔 90 서황보다 먼저 %s" % [g]): return

	# --- 지휘 공백: 강하군(유기 혼자, 부함장·참모 없음) → 끝까지 혼선 ---
	s = _sim()
	var liuqi := _f(s, "liuqi")
	_wreck(s, liuqi, 1500)
	_ticks(s, 1)
	g = _group(s, "RC-LIU-FLT-02")
	q = s.projection(0).squadrons.filter(func(x): return x.id == liuqi.id)
	if not TestCheck.ok(self, g.leaderless and s.cmd.confused(liuqi) and q[0].confusion_s == -1.0, "지휘 공백: 끝까지 혼선"): return
	_ticks(s, 1000)
	if not TestCheck.ok(self, s.cmd.confused(liuqi), "100초 뒤에도 혼선"): return
	var fg: Array = s.projection(0).fleet_groups
	if not TestCheck.ok(self, fg.all(func(x): return str(x.id).begins_with("RC-LIU") or str(x.id).begins_with("RC-SUN")) and fg.any(func(x): return x.leaderless), "fleet_groups: 자기 진영만"): return
	var foe_q: Array = s.projection(0).squadrons.filter(func(x): return x.side == 1)
	if not TestCheck.ok(self, foe_q.all(func(x): return not x.has("commander_state")), "적 접촉에는 지휘관 상태가 없다"): return

	# --- 지휘 한도 초과 단계: 비용 > 40 + 통솔 × 2면 한도의 25%마다 1단계, 상한 4 ---
	s = _sim()
	cao = _f(s, "cao")
	var cost := 0
	for ty in cao.stages:
		cost += s.salvo.present_of(cao, ty) * int(s.salvo.C.ship_types[ty].cost)
	if not TestCheck.ok(self, s.cmd.limit_tier(cao) == 0, "조조 통솔 96: 한도 232 안 (비용 %d)" % cost): return
	cao.cmd_stat = 70
	var want := 0 if cost <= 180 else mini(4, ceili(float(cost - 180) / 45.0))
	if not TestCheck.ok(self, want > 0 and s.cmd.limit_tier(cao) == want and s.cmd.stages(cao) == want, "통솔 70(허저): 한도 180, 비용 %d → %d단계" % [cost, want]): return
	cao.cmd_stat = 10
	if not TestCheck.ok(self, s.cmd.limit_tier(cao) == 4, "상한 4단계"): return

	# --- 항복 → 포로, 격침 → 운명, 결집 제한, 결산 사상 목록 ---
	s = _sim()
	var wen := _f(s, "wen")
	wen.morale_bp = 0
	_ticks(s, 1)
	if not TestCheck.ok(self, wen.out == "surrender" and wen.cmdr_state == "captured", "항복 → 포로"): return
	var zhou := _f(s, "zhou")
	zhou.vice = {}
	zhou.staff = []
	_wreck(s, zhou, 3500)
	_ticks(s, 1)
	if not TestCheck.ok(self, zhou.cmdr_state == "severe" and zhou.cmdr_sub == "" and s.cmd.confused(zhou) and s.morale.rally(0, "zhou_yu_rally") == "rally_no_source", "주유 중상·이을 사람 없음: 결집 불가, 전대 혼선"): return
	var xu := _f(s, "xu")
	s.salvo.apply_hull(null, xu, float(xu.max_hull), "engagement", "front", s.st.new_event_id())
	_ticks(s, 1)
	if not TestCheck.ok(self, xu.out == "sunk" and xu.cmdr_state in ["severe", "captured"] and xu.cmdr_state == s.victory.commander_fate(xu), "격침 → G8-04 3행 운명 (%s)" % xu.cmdr_state): return
	var res := s.victory.settle(true, "test", false, s.victory.conditions())
	var cas: Array = res.casualties
	if not TestCheck.ok(self, cas.any(func(c): return c.sq == SQ.wen and c.state == "captured") and cas.any(func(c): return c.sq == SQ.zhou and c.state == "severe"), "결산 사상 목록 %s" % [cas]): return

	print("SUCCESSION_RULES_PASS")
	quit(0)
