extends SceneTree

# P8a 장수 특기(BATTLE_DECISIONS §U Q88~Q95, SPECIAL-SKILLS.md): 슬롯 기본값(직책 순, 중복 건너뜀), 검증 사유,
# 발동 1회 제한((함대, 기술 ID) 쌍), 거부 사유, 겹침(Q95), 진형 즉시 전환·사거리, 투영 비공개,
# 결정론 지문(같은 시드 두 번, AI 발동 포함), 슬롯을 비우면 특기 없는 코어와 같은 지문.

const DEF := "res://data/profiles/red_cliffs_rt.json"
const RUN_TICKS := 6000   # 600초: 접적·교전까지

var scn: Dictionary
var prof: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _fleet_org(org: Dictionary, sq: String) -> Dictionary:
	for fl in org.fleets:
		if fl.squadron_id == sq:
			return fl
	return {}

func _sq(sim: BattleSim, sq: String) -> FleetState:
	for f in sim.st.fleets:
		if f.sq_id == sq:
			return f
	return null

func _codes(org: Dictionary) -> Array:
	return Organization.validate(org, scn, prof).map(func(e): return e.code)

func _rejects(sim: BattleSim) -> Array:
	return sim.drain_events().filter(func(e): return e.kind == "rejected").map(func(e): return e.value)

func _cmd(sim: BattleSim, f: FleetState, id: String, target := -1) -> Array:
	sim.drain_events()
	sim.apply(BattleSim.command(f.side, [f.id], "skill", target, Vector2.ZERO, {"skill_id": id}))
	return _rejects(sim)

func _run_fp(p: Dictionary, seed_id: int, ticks := RUN_TICKS) -> BattleSim:
	var sim := BattleSim.new(seed_id, BattleRules.TICK_HZ, p)
	for i in ticks:
		sim.step()
		sim.drain_events()
	return sim

func _run() -> void:
	scn = ProfileLoader.read_json(ProfileLoader.read_json(DEF).scenario_path)
	prof = ScenarioProfile.load_profile(DEF, "표준")
	var K: Dictionary = prof.scenario.realtime_rules.special_skills
	var n_slots := int(K.slots)

	# --- 1. 슬롯 기본값: 직책 순, 같은 기술 ID는 다음 후보, 모자라면 빈칸 ---
	var base := Organization.default_org(prof)
	if not TestCheck.ok(self, _fleet_org(base, "RC-LIU-SQ-01").skill_slots == ["SK-T-MORALE", "SK-T-DISRUPT", "SK-U-ZHUGE"], "유비 본대 %s" % [_fleet_org(base, "RC-LIU-SQ-01").skill_slots]): return
	if not TestCheck.ok(self, _fleet_org(base, "RC-LIU-SQ-02").skill_slots == ["SK-U-GUANYU", "", ""], "관우 함대"): return
	if not TestCheck.ok(self, _fleet_org(base, "RC-SUN-SQ-02").skill_slots == ["SK-T-GUARD", "SK-T-MOVE", ""], "중복 견수 → 다음 후보 %s" % [_fleet_org(base, "RC-SUN-SQ-02").skill_slots]): return
	if not TestCheck.ok(self, _codes(base).is_empty(), "기본 편성 유효 %s" % [_codes(base)]): return
	var auto := base
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		auto = Organization.auto_fill(auto, fid, scn, prof)
	for fl in auto.fleets:
		if not TestCheck.ok(self, fl.skill_slots == Organization.default_slots(fl, prof) and fl.skill_slots.size() == n_slots, "auto_fill 슬롯 %s" % fl.squadron_id): return
	if not TestCheck.ok(self, _codes(auto).is_empty(), "자동 편성 유효"): return

	# --- 2. 검증 사유 ---
	var cases := {
		Organization.SKILL_DUPLICATE: ["SK-T-MORALE", "SK-T-MORALE", ""],
		Organization.SKILL_FOREIGN: ["SK-U-GUANYU", "", ""],
		Organization.SKILL_UNKNOWN: ["SK-NOPE", "", ""],
		"skill_unknown_len": ["SK-T-MORALE"],
	}
	for key in cases:
		var o := base.duplicate(true)
		_fleet_org(o, "RC-LIU-SQ-01").skill_slots = cases[key]
		var code: String = key.trim_suffix("_len")
		if not TestCheck.ok(self, _codes(o).has(code) and Organization.apply(prof, o, scn).has("errors"), "사유 %s: %s" % [key, _codes(o)]): return
	var junk := base.duplicate(true)
	_fleet_org(junk, "RC-LIU-SQ-01").skill_slots = [1, 2, 3]
	if not TestCheck.ok(self, _codes(junk).has(Organization.BAD_FLEET), "슬롯 형식 오류 = bad_fleet"): return
	# 슬롯 키가 없는 편성(P8a 이전 재생 헤더)은 기본값으로 apply
	var old := base.duplicate(true)
	for fl in old.fleets:
		fl.erase("skill_slots")
	var po := Organization.apply(prof, old, scn)
	if not TestCheck.ok(self, not po.has("errors") and po.ally[0].skill_slots.size() == n_slots, "슬롯 없는 편성 → 기본값"): return
	# 재생 헤더(JSON 왕복)
	var pa := Organization.apply(prof, auto, scn)
	var header: Dictionary = JSON.parse_string(JSON.stringify(pa.organization))
	var rp := Organization.apply(ScenarioProfile.load_profile(DEF, "표준"), header, scn)
	if not TestCheck.ok(self, not rp.has("errors") and JSON.stringify(rp.ally.map(func(d): return d.skill_slots)) == JSON.stringify(pa.ally.map(func(d): return d.skill_slots)), "재생 헤더 슬롯"): return

	# --- 3. 발동·1회 제한·거부 사유 ---
	var sim := BattleSim.new(1, BattleRules.TICK_HZ, Organization.apply(prof, base, scn))   # 정사 편성: 유비군 SHP-01 0척
	if not TestCheck.ok(self, sim.skills != null, "SkillCore 켜짐"): return
	sim.set_manual_all(true)   # 아군 AI 발동이 끼어들지 않게
	var a := _sq(sim, "RC-LIU-SQ-02")
	var b := _sq(sim, "RC-LIU-SQ-03")
	a.skill_slots = ["SK-T-FIRE", "SK-U-GUANYU", "SK-U-ZHAOYUN"]
	b.skill_slots = ["SK-T-FIRE", "", ""]
	if not TestCheck.ok(self, _cmd(sim, a, "SK-T-FIRE").is_empty() and sim.skills.mul(a, "damage_mul_bp") == 11500, "맹공 발동"): return
	if not TestCheck.ok(self, _cmd(sim, a, "SK-T-FIRE") == ["skill_used"], "두 번째 = skill_used"): return
	if not TestCheck.ok(self, _cmd(sim, b, "SK-T-FIRE").is_empty(), "다른 함대는 같은 기술 ID를 쓴다(Q92)"): return
	if not TestCheck.ok(self, _cmd(sim, b, "SK-T-GUARD") == ["skill_no_slot"], "슬롯 밖 = skill_no_slot"): return
	if not TestCheck.ok(self, _cmd(sim, a, "SK-U-GUANYU") == ["skill_requires_has_ship_type"], "관우 SHP-01 0척 거부(Q68)"): return
	var enemy := sim.st.alive(1)[0]
	b.pos = a.pos + Vector2(50, 0)   # 반경 안 아군이 있어 requires는 통과, 적 지정은 대상 아님
	if not TestCheck.ok(self, _cmd(sim, a, "SK-U-ZHAOYUN", enemy.id) == ["skill_no_target"], "적 지정 = skill_no_target"): return
	sim.apply(BattleSim.command(0, [a.id], "skill", -1, Vector2.ZERO, {"slot": n_slots + 4}))
	if not TestCheck.ok(self, _rejects(sim) == ["skill_no_slot"], "없는 슬롯 번호"): return
	b.vice = {}
	b.staff = []
	b.skill_slots = ["SK-T-GUARD", "", ""]
	sim.cmd.force_state(b, "severe")
	if not TestCheck.ok(self, _cmd(sim, b, "SK-T-GUARD") == ["commander_down"], "지휘 불능"): return
	# 만료: 120초 뒤 효과가 풀린다
	var until := int(a.fx[0].until)
	while sim.st.tick < until:
		sim.step()
	sim.drain_events()
	if not TestCheck.ok(self, a.fx.is_empty() and sim.skills.mul(a, "damage_mul_bp") == BattleRules.BP, "효과 만료"): return

	# --- 4. 겹침(Q95)·진형 즉시 전환·사거리 ---
	var c := _sq(sim, "RC-LIU-SQ-01")
	var fx := func(id: String) -> Dictionary: return {"id": id, "src": c.id, "until": sim.st.tick + 100, "e": sim.skills.defs[id].effects, "r": 0.0}
	c.has_move = false
	c.route.clear()
	c.fx = [fx.call("SK-T-GUARD"), fx.call("SK-U-CAOREN"), fx.call("SK-U-XIAHOUYUAN"), fx.call("SK-T-MOVE")]
	var taken := sim.skills.mul(c, "damage_taken_mul_bp")
	if not TestCheck.ok(self, taken == 6667 * 11500 / BattleRules.BP, "감소 최소 하나 × 증가 최대 하나 %d" % taken): return
	if not TestCheck.ok(self, sim.skills.mul(c, "speed_mul_bp") == 14000 and sim.skills.mul(c, "transition_mul_bp") == 5000, "speed max · transition min"): return
	c.has_move = true
	if not TestCheck.ok(self, sim.skills.mul(c, "damage_taken_mul_bp") == 8000 * 11500 / BattleRules.BP, "철벽은 멈춰 있을 때만"): return
	c.has_move = false
	c.fx.append(fx.call("SK-U-ZHAOYUN"))
	if not TestCheck.ok(self, sim.skills.mul(c, "damage_taken_mul_bp") == 0, "일신시담 0이 이긴다"): return
	c.fx = [fx.call("SK-U-ZHUGE")]
	var to: String = sim.salvo.formation_ids().filter(func(id): return id != c.formation_id and sim.salvo.form_block(c, id) == "")[0]
	sim.apply(BattleSim.command(0, [c.id], "formation", -1, Vector2.ZERO, {"id": to}))
	if not TestCheck.ok(self, c.formation_id == to and c.form_left == 0, "신기묘산 즉시 전환"): return
	var art: FleetState = sim.st.fleets.filter(func(o): return o.ranges.has("artillery"))[0]
	var r0 := float(art.ranges.artillery)
	art.fx = [fx.call("SK-U-HUANGZHONG")]
	sim.salvo.refresh_range(art)
	if not TestCheck.ok(self, absf(float(art.ranges.artillery) - r0 * 1.3) < 0.01, "강궁 사거리 %f → %f" % [r0, art.ranges.artillery]): return
	art.fx = []
	sim.salvo.refresh_range(art)
	c.fx = []

	# --- 5. 투영: 아군만 ---
	var v0 := sim.projection(0)
	var v1 := sim.projection(1)
	var own: Array = v0.squadrons.filter(func(q): return q.side == 0)
	if not TestCheck.ok(self, own.all(func(q): return q.has("skills") and q.skills.slots.size() == n_slots), "아군 슬롯 투영"): return
	if not TestCheck.ok(self, v1.squadrons.filter(func(q): return q.side == 0).all(func(q): return not q.has("skills")), "적 진영 투영에 슬롯 없음"): return
	if not TestCheck.ok(self, _q(v0, a.id).skills.slots[0].uses_left == 0 and _q(v0, a.id).skills.slots[0].block == "skill_used", "남은 횟수"): return
	sim.drain_events()
	sim.apply(BattleSim.command(0, [_sq(sim, "RC-LIU-SQ-01").id], "skill", -1, Vector2.ZERO, {"slot": 0}))
	if not TestCheck.ok(self, not sim.drain_events_for(1).any(func(e): return str(e.kind).begins_with("skill")), "적에게 발동 사건 숨김"): return

	# --- 6. AI 조건 발동(위임 아군·조조군), 결정론 ---
	var p := Organization.load_auto(DEF, "표준")
	var s1 := _run_fp(p, 3)
	var s2 := _run_fp(p, 3)
	if not TestCheck.ok(self, s1.fingerprint() == s2.fingerprint(), "같은 시드 같은 지문"): return
	if not TestCheck.ok(self, s1.skills.used_n > 0, "AI 발동 0회"): return
	print("AI 발동 %d: %s" % [s1.skills.used_n, s1.skills.stats])
	var m := _sq(s1, "RC-LIU-SQ-03")
	if m and not m.dead:
		m.skill_slots = ["SK-T-MORALE", "", ""]
		m.skill_used = {}
		m.morale_bp = 100
		m.mstate = "stable"
		s1.skills.ai_eval(m)
		if not TestCheck.ok(self, m.skill_used.has("SK-T-MORALE"), "격려 AI 조건 발동"): return

	# --- 7. 슬롯을 비우면 특기 없는 코어(special_skills 없음)와 같은 지문 ---
	var empty := p.duplicate(true)
	for side in ["ally", "foe"]:
		for d in empty[side]:
			d.skill_slots = []
	var none := p.duplicate(true)
	none.scenario.realtime_rules.erase("special_skills")
	var e1 := _run_fp(empty, 3)
	var e0 := _run_fp(none, 3)
	if not TestCheck.ok(self, e0.skills == null and e1.skills.used_n == 0 and e1.fingerprint() == e0.fingerprint(), "빈 슬롯 = 기존 지문"): return
	if not TestCheck.ok(self, s1.fingerprint() != e1.fingerprint(), "특기가 결과를 바꾼다"): return
	if not _effects(Organization.apply(prof, base, scn)): return
	if not _replay(Organization.apply(prof, base, scn)): return
	print("SPECIAL_SKILLS_OK")
	quit(0)

func _q(view: Dictionary, id: int) -> Dictionary:
	for q in view.squadrons:
		if q.id == id:
			return q
	return {}

func _fresh(p: Dictionary) -> BattleSim:
	var sim := BattleSim.new(1, BattleRules.TICK_HZ, p)
	sim.set_manual_all(true)
	return sim

func _see(sim: BattleSim, side: int, t: FleetState) -> void:
	sim.detect.contacts[side][t.id] = {"seen": sim.st.tick, "pos": t.pos, "state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}

func _shot(sim: BattleSim, src: FleetState, tgt: FleetState, dmg: float) -> void:
	sim.salvo._resolve({"src": src, "tgt": tgt, "cat": "line_fire", "band": "engagement", "wband": "engagement", "sector": "front",
		"acc": BattleRules.BP, "dmg": dmg, "n": 1.0, "eid": sim.st.new_event_id(), "hit": true})

func _carrier_fleet(sim: BattleSim, side: int) -> FleetState:
	var ct := str(sim.assault.A.carrier)
	for f in sim.st.alive(side):
		if f.stages.has(ct) and sim.salvo.present_of(f, ct) > 0:
			return f
	return null

func _fx(sim: BattleSim, f: FleetState, id: String) -> Dictionary:
	return {"id": id, "src": f.id, "until": sim.st.tick + 100, "e": sim.skills.defs[id].effects, "r": 0.0}

# REVIEW-P8A F-5: 효과별 단언(F-1 사건·F-2 투영·F-6 분담·F-9 동률 포함)
func _effects(p: Dictionary) -> bool:
	var sim := _fresh(p)
	var sk := sim.skills
	var BP := BattleRules.BP
	var foe_flag := sim.st.flag(1)
	var cao: Array = sim.st.alive(1).filter(func(o): return o != foe_flag)
	var ally := sim.st.alive(0)
	# 악래: 기함이 받는 사격 피해의 절반을 대신 받는다(합계 보존), 기함 받는 피해 배율이 먼저(F-6), 자기가 기함이면 거부
	var g: FleetState = cao[0]
	g.pos = foe_flag.pos + Vector2(20, 0)
	g.skill_slots = ["SK-U-DIANWEI", "", ""]
	foe_flag.skill_slots = ["SK-U-DIANWEI", "", ""]
	# 기함 자신은 거부. requires를 데이터 순서로 보므로 ally_flagship_within(자기 제외)에서 먼저 걸린다
	if not TestCheck.ok(self, _cmd(sim, foe_flag, "SK-U-DIANWEI") == ["skill_requires_ally_flagship_within"], "악래 기함 자신 거부"): return false
	if not TestCheck.ok(self, _cmd(sim, g, "SK-U-DIANWEI").is_empty() and sk.guard_of(foe_flag) == g, "악래 발동"): return false
	var h0 := [foe_flag.hull, g.hull]
	_shot(sim, ally[0], foe_flag, 1000.0)
	if not TestCheck.ok(self, h0[0] - foe_flag.hull == 500 and h0[1] - g.hull == 500, "악래 분담 %d / %d" % [h0[0] - foe_flag.hull, h0[1] - g.hull]): return false
	foe_flag.fx.append(_fx(sim, foe_flag, "SK-U-ZHAOYUN"))
	h0 = [foe_flag.hull, g.hull]
	_shot(sim, ally[0], foe_flag, 1000.0)
	if not TestCheck.ok(self, foe_flag.hull == h0[0] and g.hull == h0[1], "일신시담 기함 = 분담 몫도 0(F-6)"): return false
	foe_flag.fx = []
	# 호치: 반경 안 아군(자기 포함)은 강습을 받지 않는다
	var x: FleetState = cao[1]
	var y: FleetState = cao[2]
	y.pos = x.pos + Vector2(100, 0)
	x.skill_slots = ["SK-U-XUCHU", "", ""]
	if not TestCheck.ok(self, _cmd(sim, x, "SK-U-XUCHU").is_empty() and sk.flag(x, "assault_block") and sk.flag(y, "assault_block"), "호치 발동"): return false
	var src := _carrier_fleet(sim, 0)
	if not TestCheck.ok(self, src != null, "강습모함 보유 아군 함대"): return false
	src.pos = y.pos + Vector2(10, 0)
	_see(sim, 0, y)
	if not TestCheck.ok(self, sim.assault.block(src, y, "unit") == "assault_blocked", "호치 = assault_blocked: %s" % sim.assault.block(src, y, "unit")): return false
	# 만인지적: 강습 성공률 +3000(escort 뒤 clamp, forced_div 앞), 재사용 대기 초기화
	var A: Dictionary = sim.assault.A
	var c0 := sim.assault.chance_bp(src, y, "unit")
	var forced := not sim.assault.is_open(src, foe_flag)
	var div := int(A.forced_div)
	A.forced_div = 1   # forced_div 앞 값(escort 반영)을 얻는다
	var cf0 := sim.assault.chance_bp(src, foe_flag, "flagship")
	A.forced_div = div
	src.skill_slots = ["SK-U-GUANYU", "", ""]
	src.assault_cd = sim.st.tick + 600
	if not TestCheck.ok(self, _cmd(sim, src, "SK-U-GUANYU").is_empty() and src.assault_cd == sim.st.tick, "만인지적 발동·대기 초기화"): return false
	if not TestCheck.ok(self, sim.assault.chance_bp(src, y, "unit") == clampi(c0 + 3000, int(A.min_bp), int(A.max_bp)), "만인지적 성공률 %d → %d" % [c0, sim.assault.chance_bp(src, y, "unit")]): return false
	var cf := clampi(cf0 + 3000, int(A.min_bp), int(A.max_bp)) / (div if forced else 1)
	if not TestCheck.ok(self, sim.assault.chance_bp(src, foe_flag, "flagship") == cf, "만인지적 forced_div 순서 %d" % cf): return false
	# 미주랑: 연합 진영 전체 화공 위력 ×1.3(Q93), 조조군에는 없음
	var z: FleetState = ally[1]
	z.skill_slots = ["SK-U-ZHOUYU", "", ""]
	if not TestCheck.ok(self, _cmd(sim, z, "SK-U-ZHOUYU").is_empty() and ally.all(func(o): return sk.mul(o, "chain_power_mul_bp") == 13000) and sk.mul(g, "chain_power_mul_bp") == BP, "미주랑 진영 효과"): return false
	# 진창: 지형 구역 안이면 in_terrain 값
	var hz: FleetState = cao[3]
	hz.fx = [_fx(sim, hz, "SK-U-HAOZHAO")]
	var zone: Dictionary = sim.terrain.zones.filter(func(q): return str(q.get("type", "")) != "chain_hazard")[0]
	hz.pos = Vector2(-1000, -1000)
	var out_v := [sk.mul(hz, "damage_taken_mul_bp"), sk.mul(hz, "morale_loss_mul_bp")]
	hz.pos = Vector2(float(zone.rect[0]) + float(zone.rect[2]) / 2, float(zone.rect[1]) + float(zone.rect[3]) / 2)
	if not TestCheck.ok(self, out_v == [8000, 7000] and sk.mul(hz, "damage_taken_mul_bp") == 6000 and sk.mul(hz, "morale_loss_mul_bp") == 5000, "진창 지형 %s" % [out_v]): return false
	hz.fx = []
	# 교란: 확인된 적 함대 사기 −800·명중 −800, 사건은 시전 진영에만(F-1), 받은 함대 투영에 시전 함대 없음(Q97)
	var d: FleetState = ally[2]
	var e: FleetState = cao[4]
	e.pos = d.pos + Vector2(150, 0)
	e.loss_mul_until = -1
	e.fx = []   # 앞 단계 호치 범위에 들었을 수 있다
	_see(sim, 0, e)
	_see(sim, 1, d)   # 교란 대상의 명중을 재려면 상대 진영도 d를 봐야 한다
	d.skill_slots = ["SK-T-DISRUPT", "", ""]
	var m0 := e.morale_bp
	var hit0 := sim.salvo.hit_bp(e, d, "line_fire")
	sim.drain_events()
	sim.apply(BattleSim.command(0, [d.id], "skill", -1, Vector2.ZERO, {"slot": 0}))
	if not TestCheck.ok(self, sim.drain_events_for(1).all(func(ev): return not str(ev.kind).begins_with("skill")), "교란 발동 사건 적에게 숨김"): return false
	if not TestCheck.ok(self, e.morale_bp == maxi(0, m0 - 800) and sk.add(e, "hit_bp") == -800 and sim.salvo.hit_bp(e, d, "line_fire") < hit0, "교란 사기·명중 %d→%d add %d hit %d→%d" % [m0, e.morale_bp, sk.add(e, "hit_bp"), hit0, sim.salvo.hit_bp(e, d, "line_fire")]): return false
	var qe := _q(sim.projection(1), e.id)
	if not TestCheck.ok(self, qe.skills.fx.size() == 1 and qe.skills.fx[0].get("foe", false) and not qe.skills.fx[0].has("src") and qe.skills.fx[0].name == "교란", "Q97 받은 함대 투영 %s" % [qe.skills.fx]): return false
	for viewer in [1, 0]:
		var keep: Array = e.fx.duplicate(true)
		var t0 := sim.st.tick
		sim.st.tick = int(e.fx[0].until)
		sk.step()
		sim.st.tick = t0
		var evs := sim.drain_events_for(viewer).filter(func(ev): return ev.kind == "skill_end")
		if not TestCheck.ok(self, evs.is_empty() if viewer == 1 else (evs.size() == 1 and int(evs[0].sq) == d.id), "skill_end 시전 진영만(F-1) viewer %d" % viewer): return false
		e.fx = keep
	e.fx = []
	# 조달: 미사일 횟수 +1(상한 base), 가득 차면 거부
	var arts: Array = sim.st.fleets.filter(func(o): return int(o.wmax.get("artillery", 0)) > 0)
	var sup: FleetState = arts[0]
	var sup2: FleetState = arts[1]
	sup.skill_slots = ["SK-T-SUPPLY", "", ""]
	sup2.skill_slots = ["SK-T-SUPPLY", "", ""]
	sup.wch.artillery = int(sup.wmax.artillery) - 1
	if not TestCheck.ok(self, _cmd(sim, sup, "SK-T-SUPPLY").is_empty() and int(sup.wch.artillery) == int(sup.wmax.artillery), "조달 +1"): return false
	if not TestCheck.ok(self, _cmd(sim, sup2, "SK-T-SUPPLY") == ["skill_requires_charges_below_base"], "조달 가득 거부"): return false
	# 고육계: 화공 서신과 같은 경로(letter_uses 공유), 운용 함대만
	var host: FleetState = sim.st.fleets.filter(func(o): return o.sq_id == sim.chain.host_sq)[0]
	host.skill_slots = ["", "SK-U-HUANGGAI", ""]
	var lt0 := sim.chain.letters
	if not TestCheck.ok(self, sk.alias_slot(host, "letter") == 1, "고육계 슬롯"): return false
	sim.apply(BattleSim.command(0, [host.id], "skill", -1, Vector2.ZERO, {"slot": 1}))
	if not TestCheck.ok(self, sim.chain.letters == lt0 - 1 and sim.chain.mode == "feign" and host.skill_used.has("SK-U-HUANGGAI") and sk.alias_slot(host, "letter") == -1, "고육계 = 서신"): return false
	var other: FleetState = ally.filter(func(o): return o != host)[0]
	other.skill_slots = ["SK-U-HUANGGAI", "", ""]
	if not TestCheck.ok(self, _cmd(sim, other, "SK-U-HUANGGAI") == ["skill_requires_chain_host"], "고육계 운용 함대만"): return false
	# 승계 중 발동: 부제독이 이으면 쓸 수 있다
	var sc: FleetState = sim.st.alive(0).filter(func(o): return not o.vice.is_empty() and o.skill_used.is_empty())[0]
	sim.cmd.force_state(sc, "severe")
	sc.skill_slots = ["SK-T-FIRE", "", ""]
	if not TestCheck.ok(self, sc.cmdr_sub != "" and _cmd(sim, sc, "SK-T-FIRE").is_empty(), "승계 중 발동"): return false
	# F-9: 일신시담 동률(선체 비율 같음) = 함대 ID 오름차순
	var t1 := _fresh(p)
	var zs := t1.st.alive(0)
	for i in zs.size():
		zs[i].pos = zs[0].pos + Vector2(i * 5, 0)
	var pick := t1.skills.targets(zs[zs.size() - 1], t1.skills.defs["SK-U-ZHAOYUN"])
	if not TestCheck.ok(self, pick.size() == 1 and pick[0].id == zs.map(func(o): return o.id).min(), "동률 ID 순"): return false
	return true

# REVIEW-P8A F-4: 사람의 skill 명령이 명령 로그로 재생돼 같은 지문, 위임 함대는 직접 지휘로, 재생 헤더(JSON 왕복)
func _replay(p: Dictionary) -> bool:
	var sim := BattleSim.new(2, BattleRules.TICK_HZ, p)
	var f := sim.st.alive(0)[0]
	for i in 30:
		sim.step()
	sim.queue(BattleSim.command(0, [f.id], "skill", -1, Vector2.ZERO, {"slot": 0}))
	for i in 300:
		sim.step()
		sim.drain_events()
	if not TestCheck.ok(self, f.skill_used.has(str(f.skill_slots[0])) and f.control == "direct", "사람 발동 기록·직접 지휘 %s %s" % [f.skill_used, f.control]): return false
	var header: Dictionary = JSON.parse_string(JSON.stringify(p.organization))
	var rp := Organization.apply(ScenarioProfile.load_profile(DEF, "표준"), header, scn)
	var again := BattleSim.replay(2, BattleRules.TICK_HZ, sim.command_log, sim.st.tick, rp)
	return TestCheck.ok(self, again.fingerprint() == sim.fingerprint() and again.skills.used_n == sim.skills.used_n, "skill 명령 재생 지문")
