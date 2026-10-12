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
	var zr := _cmd(sim, a, "SK-U-ZHAOYUN", enemy.id)
	if not TestCheck.ok(self, zr == ["skill_no_target"] or zr == ["skill_requires_ally_within"], "대상 없음 %s" % [zr]): return
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
	print("SPECIAL_SKILLS_OK")
	quit(0)

func _q(view: Dictionary, id: int) -> Dictionary:
	for q in view.squadrons:
		if q.id == id:
			return q
	return {}
