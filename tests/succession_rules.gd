extends SceneTree

# M9 완료 기준(제안서 §4.14, 본편 V-74 / G8-04): 전대 지휘관 상태(항복 포로, 격침 운명, 남은 척 < 40% 중상, < 75% 경상, 악화만),
# 중상이면 같은 함대의 부제독 → 첫 참모가 능력치를 잇고 그 함대만 60초 혼선(2단계: 기동 −10%, 명중 −8%, 진형 변경 −16%, Q73·Q74),
# 이을 사람이 없으면 끝까지 혼선,
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

func _run() -> void:
	var s := _sim()
	if not TestCheck.ok(self, s.cmd != null and str(s.rs.rt("commander_succession.status")) == "proposed" and int(s.cmd.K.limit_base) == 120, "데이터: 승계 제안값, 지휘 한도 120 + 통솔 × 6(척 수 3배)"): return

	# --- 선체 구간(척 수 비율): < 75% 경상(지휘 유지), < 40% 중상(지휘 불능 → 부지휘관이 잇는다). 악화만 ---
	var cheng := _f(s, "cheng")
	_wreck(s, cheng, 6500)
	var evs := _ticks(s, 1)
	if not TestCheck.ok(self, _ratio(s, cheng) < 7500 and _ratio(s, cheng) >= 4000 and cheng.cmdr_state == "light" and cheng.cmd_stat == 84, "경상: 지휘 유지 (%d bp)" % _ratio(s, cheng)): return
	_wreck(s, cheng, 4500)
	evs = _ticks(s, 1)
	var sub: Array = evs.filter(func(e): return e.kind == "commander_sub" and e.sq == cheng.id)
	if not TestCheck.ok(self, _ratio(s, cheng) < 4000 and cheng.cmdr_state == "severe" and cheng.cmdr_sub == "CHR-0212" and cheng.cmd_stat == 78 and int(cheng.stats.might) == 90 and sub.size() == 1, "중상: 부지휘관 주태가 잇는다"): return
	if not TestCheck.ok(self, s.cmd.confused(cheng) and s.cmd.stats.succession == 1 and not s.cmd.confused(_f(s, "zhou")), "승계하면 그 함대만 60초 혼선"): return

	# --- 유비 중상 → 부제독 장비가 잇는다(Q74). 승패 기함은 그대로, 그 함대만 60초 혼선, 전투 계속 ---
	s = _sim()
	var liu := _f(s, "liu")
	var t := _f(s, "wen")
	liu.pos = t.pos + Vector2(-150, 0)
	liu.heading = 0.0
	_wreck(s, liu, 1500)
	evs = _ticks(s, 1)
	if not TestCheck.ok(self, liu.cmdr_state == "severe" and liu.cmdr_sub == "CHR-0130" and liu.cmd_stat == 88 and liu.is_flag and not s.st.over, "유비 중상 → 장비 승계, 기함 유지"): return
	if not TestCheck.ok(self, s.cmd.confused(liu) and not s.cmd.confused(_f(s, "guan")) and not s.cmd.confused(_f(s, "zhou")), "혼선: 그 함대만"): return
	if not TestCheck.ok(self, s.cmd.stages(liu) == 2 and absf(s.cmd.penalty(liu, "move_pct") + 0.10) < 1e-9, "2단계: 기동 −10%"): return
	s.detect.contacts[0][t.id] = {"seen": 0, "pos": t.pos, "state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}
	var cu := liu.confuse_until
	liu.confuse_until = -1
	var hit0 := s.salvo.hit_bp(liu, t, "line_fire")   # 같은 순간의 혼선 없는 값
	var tr0 := s.salvo.transition_ticks(liu, "FRM-02")
	liu.confuse_until = cu
	if not TestCheck.ok(self, hit0 > 0 and s.salvo.hit_bp(liu, t, "line_fire") == roundi(hit0 * 0.92), "명중 −8%%: %d → %d" % [hit0, s.salvo.hit_bp(liu, t, "line_fire")]): return
	if not TestCheck.ok(self, s.salvo.transition_ticks(liu, "FRM-02") == BattleRules.ticks(float(tr0) / 10.0 / 0.84, 10), "진형 변경 속도 −16%%: %d → %d틱" % [tr0, s.salvo.transition_ticks(liu, "FRM-02")]): return
	var q: Array = s.projection(0).squadrons.filter(func(x): return x.id == liu.id)
	if not TestCheck.ok(self, q[0].penalty_stages == 2 and q[0].confusion_s > 59.0 and q[0].commander_state == "severe", "투영: 자기 함대 혼선·불이익 단계"): return
	liu.pos = Vector2(200, 800)   # 교전에서 떼어 둔다
	_ticks(s, 600)
	if not TestCheck.ok(self, not s.cmd.confused(liu) and s.cmd.stages(liu) == 0, "60초 뒤 혼선 끝"): return
	if not TestCheck.ok(self, s.morale.rally(0, "liu_bei_rally") == "", "유비 중상이어도 이은 사람(장비)이 결집한다"): return

	# --- 조조 중상 → 부제독 허저. 부제독이 없으면 첫 참모. 다른 함대는 혼선 없음 ---
	s = _sim()
	var cao := _f(s, "cao")
	_wreck(s, cao, 3500)
	cao.morale_bp = BattleRules.BP   # 사기 붕괴 항복(포로)이 아니라 중상만 본다
	_ticks(s, 1)
	if not TestCheck.ok(self, cao.cmdr_sub == "CHR-0047" and cao.is_flag and s.cmd.confused(cao) and not s.cmd.confused(_f(s, "ren")) and not s.st.over, "조조 중상 → 허저 승계, 기함 유지 %s %s %s %s %s %s %s" % [cao.out, cao.morale_bp, cao.cmdr_state, cao.cmdr_sub, cao.is_flag, s.cmd.confused(cao), s.cmd.confused(_f(s, "ren"))]): return
	s = _sim()
	cao = _f(s, "cao")
	cao.vice = {}
	_wreck(s, cao, 3500)
	cao.morale_bp = BattleRules.BP
	_ticks(s, 1)
	if not TestCheck.ok(self, cao.cmdr_sub == str(cao.staff[0].id) and s.cmd.confused(cao), "부제독 없음 → 첫 참모 %s" % cao.cmdr_sub): return

	# --- 지휘 공백: 유기 혼자(부제독·참모 없음) → 끝까지 혼선 ---
	s = _sim()
	var liuqi := _f(s, "liuqi")
	_wreck(s, liuqi, 1500)
	_ticks(s, 1)
	q = s.projection(0).squadrons.filter(func(x): return x.id == liuqi.id)
	if not TestCheck.ok(self, s.cmd.stats.leaderless == 1 and s.cmd.confused(liuqi) and q[0].confusion_s == -1.0, "지휘 공백: 끝까지 혼선"): return
	_ticks(s, 1000)
	if not TestCheck.ok(self, s.cmd.confused(liuqi), "100초 뒤에도 혼선"): return
	if not TestCheck.ok(self, not s.projection(0).has("fleet_groups"), "상위 묶음 투영 없음(Q73)"): return
	var foe_q: Array = s.projection(0).squadrons.filter(func(x): return x.side == 1)
	if not TestCheck.ok(self, foe_q.all(func(x): return not x.has("commander_state")), "적 접촉에는 지휘관 상태가 없다"): return

	# --- 지휘 한도 초과 단계: 비용 > 120 + 통솔 × 6(척 수 3배)이면 한도의 25%마다 1단계, 상한 4 ---
	s = _sim()
	cao = _f(s, "cao")
	var cost := 0
	for ty in cao.stages:
		cost += s.salvo.present_of(cao, ty) * int(s.salvo.C.ship_types[ty].cost)
	if not TestCheck.ok(self, s.cmd.limit_tier(cao) == 0, "조조 통솔 96: 한도 696 안 (비용 %d)" % cost): return
	cao.cmd_stat = 70
	var want := 0 if cost <= 540 else mini(4, ceili(float(cost - 540) / 135.0))
	if not TestCheck.ok(self, want > 0 and s.cmd.limit_tier(cao) == want and s.cmd.stages(cao) == want, "통솔 70(허저): 한도 540, 비용 %d → %d단계" % [cost, want]): return
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
