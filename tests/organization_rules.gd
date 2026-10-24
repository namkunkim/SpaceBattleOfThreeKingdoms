extends SceneTree

# O1 코어 편성(Organization, BATTLE_DECISIONS §T Q73~Q81): 검증 사유 코드, 자동 편성(한도·직책 능력치 순·결정론),
# 프로필 덮어쓰기(기본 편성은 결과 그대로, 재생 헤더로 같은 결과).
# O1b(REVIEW-O1): apply가 잘못된 편성을 거부, 참모 순서 = 승계 순서 = 강습 → 공성 → 보급, 장수 부족, 동점 ID 순,
# 끈 함대 + 자동 편성으로 전투 종료까지, 재생 헤더(JSON 왕복) 지문 시드 3개·종료까지.

const DEF := "res://data/profiles/red_cliffs_rt.json"
const END_SEEDS := [1, 2, 3]
const END_MAX := 30000   # 3000초 상한(종료 확인용)
const TICKS := 3800   # 380초: 기본 편성 첫 명중(시드 7, 3440틱) 뒤까지

var scn: Dictionary
var prof: Dictionary

func _initialize() -> void:
	call_deferred("_run")

func _codes(org: Dictionary) -> Array:
	return Organization.validate(org, scn, prof).map(func(e): return e.code)

func _fleet(org: Dictionary, sq: String) -> Dictionary:
	for fl in org.fleets:
		if fl.squadron_id == sq:
			return fl
	return {}

func _run_fp(p: Dictionary, ticks := TICKS) -> String:
	var sim := BattleSim.new(7, BattleRules.TICK_HZ, p)
	for i in ticks:
		sim.step()
		sim.drain_events()
	return sim.fingerprint()

func _run() -> void:
	scn = ProfileLoader.read_json(ProfileLoader.read_json(DEF).scenario_path)
	prof = ScenarioProfile.load_profile(DEF, "표준")
	var base := Organization.default_org(prof)
	if not TestCheck.ok(self, base.fleets.size() == prof.ally.size() + prof.foe.size(), "default org fleets"): return
	if not TestCheck.ok(self, _codes(base).is_empty(), "default org valid %s" % [Organization.validate(base, scn, prof)]): return
	# 기존 데이터 참모의 추정 보직이 이미 강습 → 공성 → 보급 순이다(apply 정렬이 기본 승계 순서를 바꾸지 않는다)
	for fl in base.fleets:
		var idx: Array = fl.staff.map(func(x): return Organization.POST_ORDER.find(x.post))
		var sorted := idx.duplicate()
		sorted.sort()
		if not TestCheck.ok(self, idx == sorted, "default staff in post order " + fl.squadron_id): return

	# 검증 사유 코드별
	var cases := {
		Organization.DUP_OFFICER: func(o): _fleet(o, "RC-LIU-SQ-02").vice = "CHR-0130",
		Organization.FOREIGN_OFFICER: func(o): _fleet(o, "RC-LIU-SQ-02").vice = "CHR-0185",
		Organization.FLAG_ADMIRAL: func(o): _fleet(o, "RC-LIU-SQ-01").admiral = "CHR-0134",
		Organization.FLAG_OFF: func(o): _fleet(o, "RC-LIU-SQ-01").on = false,
		Organization.NO_ADMIRAL: func(o): _fleet(o, "RC-LIU-SQ-02").admiral = "",
		Organization.NO_SHIPS: func(o): _fleet(o, "RC-LIU-SQ-02").composition = [],
		Organization.BAD_STAFF: func(o): _fleet(o, "RC-LIU-SQ-02").staff = [{"post": "siege", "id": "CHR-0112"}, {"post": "siege", "id": "CHR-0113"}],
		Organization.BAD_SHIP: func(o): _fleet(o, "RC-LIU-SQ-02").composition = [{"ship_type_id": "SHP-99", "count": 1}],
		Organization.MISSING_FLEET: func(o): o.fleets.erase(_fleet(o, "RC-LIU-SQ-02")),
		Organization.BAD_FLEET: func(o): o.fleets.append({"squadron_id": "RC-LIU-SQ-02"}),
		"bad_fleet_count": func(o): _fleet(o, "RC-LIU-SQ-02").composition[0].count = 1.5,
		"bad_ship_equip": func(o): _fleet(o, "RC-LIU-SQ-01").composition[-1].mission_equipment_id = "FAST-EQ-NOPE",
		"bad_ship_dup": func(o): _fleet(o, "RC-LIU-SQ-02").composition.append(_fleet(o, "RC-LIU-SQ-02").composition[0].duplicate()),
		Organization.UNKNOWN_FLEET: func(o): o.fleets.append({"squadron_id": "RC-X", "faction_id": "liu_bei", "on": true, "admiral": "", "vice": "", "staff": [], "composition": []}),
	}
	for key in cases:
		var o := base.duplicate(true)
		cases[key].call(o)
		var code: String = key.trim_suffix("_count").trim_suffix("_equip").trim_suffix("_dup")
		if not TestCheck.ok(self, _codes(o).has(code), "code %s: %s" % [key, _codes(o)]): return
		# apply는 검증 실패 편성을 적용하지 않고 사유를 돌려준다(크래시 없음)
		var r := Organization.apply(prof, o, scn)
		if not TestCheck.ok(self, r.has("errors") and not r.has("ally"), "apply rejects " + key): return
	for junk in [{}, {"fleets": "x"}, {"fleets": ["x", 3]}]:
		if not TestCheck.ok(self, Organization.apply(prof, junk, scn).has("errors"), "apply rejects junk %s" % [junk]): return
	var none := base.duplicate(true)
	for fl in none.fleets:
		if fl.faction_id == "sun_quan":
			fl.on = false
	if not TestCheck.ok(self, _codes(none).has(Organization.FLAG_OFF) and _codes(none).has(Organization.NO_FLEET), "no fleet %s" % [_codes(none)]): return
	# 끈 함대는 검사하지 않는다(장수는 대기 풀로)
	var off := base.duplicate(true)
	_fleet(off, "RC-LIU-SQ-02").on = false
	_fleet(off, "RC-LIU-SQ-02").admiral = ""
	if not TestCheck.ok(self, _codes(off).is_empty(), "off fleet ignored"): return

	# 자동 편성: 세 세력(Q81), 같은 입력 같은 결과
	var auto := base
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		auto = Organization.auto_fill(auto, fid, scn, prof)
	var again := base
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		again = Organization.auto_fill(again, fid, scn, prof)
	if not TestCheck.ok(self, JSON.stringify(auto) == JSON.stringify(again), "auto_fill deterministic"): return
	if not TestCheck.ok(self, _codes(auto).is_empty(), "auto org valid %s" % [Organization.validate(auto, scn, prof)]): return
	# P10b: 자동 편성은 시나리오 정찰 고속정 수를 예약한다(유비 본대 정찰정 18척(문서 6 x 3배), 장비 유지). 조조 함대 수는 비용비 우선 결과(P10b, 입문 9 · 표준 10 · 상급/극한 14)
	var scout_n := 0
	for c in scn.squadrons.filter(func(x): return x.id == "RC-LIU-SQ-01")[0].composition:
		if c.ship_type_id == Organization.FILLER:
			scout_n += int(c.count)
	var got := 0
	var recon_ok := false
	for c in _fleet(auto, "RC-LIU-SQ-01").composition:
		if c.ship_type_id == Organization.FILLER:
			got += int(c.count)
			recon_ok = c.mission_equipment_id == "FAST-EQ-RECON"
	if not TestCheck.ok(self, scout_n == 18 and got >= scout_n and recon_ok, "auto scouts reserved %d/%d" % [got, scout_n]): return
	if not _scout_boundaries(base, auto): return
	var want_foes := {"입문": 9, "표준": 10, "상급": 14, "극한": 14}
	for dn in want_foes:
		var pd := Organization.load_auto(DEF, dn)
		if not TestCheck.ok(self, pd.has("organization") and pd.foe.size() == want_foes[dn], "%s cao fleets %d (want %d)" % [dn, pd.foe.size(), want_foes[dn]]): return
	var min_cost := 1 << 30
	for t in prof.combat.ship_types.values():
		min_cost = mini(min_cost, int(t.cost))
	var fill := {}
	for d in prof.ally + prof.foe:
		fill[d.squadron_id] = int(d.get("fill_bp", BattleRules.BP))
	if not TestCheck.ok(self, fill.values().filter(func(b): return b < BattleRules.BP).size() == 1, "fill_bp는 조조 마지막 함대 하나(Q82)"): return
	var caps := {}
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		caps.merge(Organization.auto_caps(auto, fid, scn, prof))
	for fl in auto.fleets:
		var lim: int = caps[fl.squadron_id]
		var c := Organization.cost_of(fl, prof)
		if not TestCheck.ok(self, c <= lim and c > lim - min_cost, "%s cost %d limit %d" % [fl.squadron_id, c, lim]): return
		if not TestCheck.ok(self, fl.vice != "" and fl.staff.map(func(s): return s.post) == Organization.POST_ORDER, "%s posts filled" % fl.squadron_id): return
	# 기함 제독 고정
	for sq in scn.squadrons:
		if sq.get("flagship", false):
			if not TestCheck.ok(self, _fleet(auto, sq.id).admiral == sq.commander.id, "flag admiral kept " + sq.id): return
	# 직책 능력치 순: 비기함 제독 통솔 ≥ 모든 부제독 통솔, 뽑힌 장수는 남은 장수보다 그 능력치가 낮지 않다
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		var pool := Organization._officers(scn, fid)
		var mine: Array = auto.fleets.filter(func(fl): return fl.faction_id == fid)
		var used := {}
		for fl in mine:
			for id in Organization._people(fl):
				used[id] = true
		var low := {"command": 1000, "might": 1000, "intellect": 1000, "politics": 1000}
		for fl in mine:
			low.command = mini(low.command, int(pool[fl.vice].command))
			for s in fl.staff:
				var st: String = Organization.POSTS[s.post]
				low[st] = mini(low[st], int(pool[s.id][st]))
		for id in pool:
			if used.has(id):
				continue
			for st in low:
				if not TestCheck.ok(self, int(pool[id][st]) <= low[st], "%s %s: free %s %d > picked %d" % [fid, st, id, pool[id][st], low[st]]): return
		var adm_low := 1000
		var vice_high := 0
		for fl in mine:
			if not _is_flag(fl.squadron_id):
				adm_low = mini(adm_low, int(pool[fl.admiral].command))
			vice_high = maxi(vice_high, int(pool[fl.vice].command))
		if not TestCheck.ok(self, adm_low >= vice_high, "%s admirals %d >= vices %d" % [fid, adm_low, vice_high]): return

	if not _shortage_and_ties(base): return
	if not _succession(auto): return

	# 덮어쓰기: 기본 편성은 결과를 바꾸지 않는다(P8a: 특기 슬롯을 비우면. 슬롯이 차 있으면 특기 발동이 결과를 바꾼다)
	var fp0 := _run_fp(ScenarioProfile.load_profile(DEF, "표준"))
	var bare := base.duplicate(true)
	for fl in bare.fleets:
		fl.skill_slots = ["", "", ""]
	var pd := Organization.apply(prof, bare, scn)
	if not TestCheck.ok(self, _run_fp(pd) == fp0, "default org keeps result"): return
	# 자동 편성: 한도 재계산, 끈 함대 빠짐, 재생 헤더로 같은 결과
	var auto_off := auto.duplicate(true)
	_fleet(auto_off, "RC-LIU-SQ-03").on = false
	var pa := Organization.apply(prof, auto_off, scn)
	var a1 := _fleet(auto_off, "RC-LIU-SQ-02")
	var d1: Dictionary = pa.ally.filter(func(d): return d.squadron_id == "RC-LIU-SQ-02")[0]
	if not TestCheck.ok(self, d1.commander_id == a1.admiral and d1.ships == a1.composition.reduce(func(s, c): return s + int(c.count), 0), "applied fleet"): return
	if not TestCheck.ok(self, not pa.ally.any(func(d): return d.squadron_id == "RC-LIU-SQ-03"), "off fleet dropped"): return
	var sim := BattleSim.new(7, BattleRules.TICK_HZ, pa)
	var f2: FleetState = sim.st.fleets.filter(func(f): return f.sq_id == "RC-LIU-SQ-02")[0]
	if not TestCheck.ok(self, sim.cmd and sim.cmd.limit_tier(f2) == 0 and f2.cmd_stat == int(Organization._officers(scn, "liu_bei")[a1.admiral].command), "limit with new admiral"): return
	var fpa := _run_fp(pa, 1000)
	var replayed := Organization.apply(ScenarioProfile.load_profile(DEF, "표준"), pa.organization, scn)
	if not TestCheck.ok(self, _run_fp(replayed, 1000) == fpa and fpa != fp0, "replay header same result"): return
	# P8b-b F-1: refill_slots 단위(결정론 근거: keep=[] = default_slots, 고른 칸은 자리째 유지, 중복·남의 기술·길이는 바로잡음)
	var rf := _fleet(base, "RC-LIU-SQ-01")
	var ds: Array = Organization.default_slots(rf, prof)
	var n_sl: int = ds.size()
	var own_sk := Organization.fleet_skills(rf, prof)
	var alien := ""
	for sd in prof.scenario.realtime_rules.special_skills.skills:
		if not own_sk.has(sd.id):
			alien = sd.id
			break
	if not TestCheck.ok(self, n_sl == 3 and ds[0] != "" and alien != "", "refill setup %s" % [ds]): return
	if not TestCheck.ok(self, Organization.refill_slots(rf, prof, []) == ds and Organization.refill_slots(rf, prof, ds) == ds, "refill: keep [] = default, keep default = default"): return
	if not TestCheck.ok(self, Organization.refill_slots(rf, prof, [ds[2], ds[0], ds[1]]) == [ds[2], ds[0], ds[1]], "refill: kept order stays in place"): return
	var part := Organization.refill_slots(rf, prof, [ds[0], alien, ""])
	if not TestCheck.ok(self, part[0] == ds[0] and not part.has(alien) and part.size() == n_sl and part.filter(func(k): return k != "").size() == part.filter(func(k): return k != "").reduce(func(a, k): return a if a.has(k) else a + [k], []).size(), "refill: partial keep, alien dropped, no dup %s" % [part]): return
	var dup := Organization.refill_slots(rf, prof, [ds[0], ds[0], ds[0]])
	if not TestCheck.ok(self, dup[0] == ds[0] and dup.count(ds[0]) == 1, "refill: duplicate in keep -> later ones refilled %s" % [dup]): return
	if not TestCheck.ok(self, Organization.refill_slots(rf, prof, [ds[0]]).size() == n_sl and Organization.refill_slots(rf, prof, [ds[0], ds[1], ds[2], ds[0], ds[1]]).size() == n_sl, "refill: length always = slots"): return
	var one := rf.duplicate(true)   # 특기 없는 장수만 남으면 칸은 빈칸
	one.admiral = ""
	one.vice = ""
	one.staff = []
	if not TestCheck.ok(self, Organization.refill_slots(one, prof, ds) == ["", "", ""], "refill: no officers -> all empty"): return
	if not _to_end(): return
	print("ORGANIZATION_RULES_OK")
	quit(0)

# 정찰 예약만 영향: 비정찰 고속정·다른 함대 불변, only/출전 끔 보존, 낮은 한도 절삭.
func _scout_boundaries(base: Dictionary, auto: Dictionary) -> bool:
	var without := scn.duplicate(true)
	for sq in without.squadrons:
		sq.composition = sq.composition.filter(func(c): return c.ship_type_id != Organization.FILLER)
	var reference := base
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		reference = Organization.auto_fill(reference, fid, without, prof)
	for fl in auto.fleets:
		if fl.squadron_id != "RC-LIU-SQ-01":
			if not TestCheck.ok(self, fl == _fleet(reference, fl.squadron_id), "non-recon fleet unchanged " + fl.squadron_id): return false
	var limited := Organization.auto_fill(base, "liu_bei", scn, prof, ["RC-LIU-SQ-01"])
	for fl in base.fleets:
		if fl.squadron_id != "RC-LIU-SQ-01":
			if not TestCheck.ok(self, fl == _fleet(limited, fl.squadron_id), "only preserves " + fl.squadron_id): return false
	var off := base.duplicate(true)
	_fleet(off, "RC-LIU-SQ-01").on = false
	var after_off := Organization.auto_fill(off, "liu_bei", scn, prof)
	if not TestCheck.ok(self, _fleet(off, "RC-LIU-SQ-01") == _fleet(after_off, "RC-LIU-SQ-01"), "off scout fleet preserved"): return false
	var small := prof.duplicate(true)
	for d in small.ally:
		if d.squadron_id == "RC-LIU-SQ-01":
			d.fill_bp = 100   # 한도 612의 1% = 6점: 2점 정찰정 3척만 가능
	var clipped := Organization.auto_fill(base, "liu_bei", scn, small, ["RC-LIU-SQ-01"])
	var fl := _fleet(clipped, "RC-LIU-SQ-01")
	return TestCheck.ok(self, fl.composition == [{"ship_type_id": Organization.FILLER, "count": 3, "mission_equipment_id": "FAST-EQ-RECON"}] and Organization.cost_of(fl, small) == 6, "scouts clipped at actual cap %s" % [fl.composition])

func _is_flag(sq: String) -> bool:
	return Organization._flags(scn).has(sq)

# 장수 부족: 남은 칸은 비고(부제독 → 참모 순으로 앞 함대부터), 제독이 모자라면 no_admiral. 동점은 ID가 작은 쪽
func _shortage_and_ties(base: Dictionary) -> bool:
	var liu: Dictionary = scn.factions.filter(func(f): return f.id == "liu_bei")[0]
	var full: Array = liu.available_officers
	for keep_n in [6, 2]:
		var s2 := scn.duplicate(true)
		var l2: Dictionary = s2.factions.filter(func(f): return f.id == "liu_bei")[0]
		l2.available_officers = full.filter(func(o): return o.id == "CHR-0128").duplicate(true)
		l2.available_officers.append_array(full.filter(func(o): return o.id != "CHR-0128").slice(0, keep_n - 1).duplicate(true))
		var o := Organization.auto_fill(base, "liu_bei", s2, prof)
		var mine: Array = o.fleets.filter(func(fl): return fl.faction_id == "liu_bei")
		var people := []
		for fl in mine:
			people.append_array(Organization._people(fl))
		var errs := Organization.validate(o, s2, prof).map(func(e): return e.code)
		if keep_n == 6:
			var vices := mine.filter(func(fl): return fl.vice != "").size()
			if not TestCheck.ok(self, people.size() == 6 and vices == 3 and mine.all(func(fl): return fl.staff.is_empty()) and errs.is_empty(), "shortage 6: %s %s" % [people, errs]): return false
		elif not TestCheck.ok(self, people.size() == 2 and errs.has(Organization.NO_ADMIRAL) and Organization.apply(prof, o, s2).has("errors"), "shortage 2: %s" % [errs]): return false
	var s3 := scn.duplicate(true)
	for o in s3.factions.filter(func(f): return f.id == "liu_bei")[0].available_officers:
		if o.id in ["CHR-0112", "CHR-0104"]:
			o.command = 200
	var t := Organization.auto_fill(base, "liu_bei", s3, prof)
	return TestCheck.ok(self, _fleet(t, "RC-LIU-SQ-02").admiral == "CHR-0104" and _fleet(t, "RC-LIU-SQ-03").admiral == "CHR-0112", "tie by id")

# apply 뒤 전대 안 승계: 부제독 → 첫 참모. 참모는 넣은 순서와 관계없이 강습 → 공성 → 보급
func _succession(auto: Dictionary) -> bool:
	var o := auto.duplicate(true)
	var f3 := _fleet(o, "RC-LIU-SQ-03")
	f3.vice = ""
	f3.staff.reverse()
	f3.skill_slots = Organization.default_slots(f3, prof)   # 장수가 빠지면 슬롯을 다시 채운다(P8a, 안 하면 skill_foreign)
	var p := Organization.apply(prof, o, scn)
	var sim := BattleSim.new(7, BattleRules.TICK_HZ, p)
	var by := func(sq): return sim.st.fleets.filter(func(f): return f.sq_id == sq)[0]
	var f2: FleetState = by.call("RC-LIU-SQ-02")
	var g3: FleetState = by.call("RC-LIU-SQ-03")
	var d3: Dictionary = p.ally.filter(func(d): return d.squadron_id == "RC-LIU-SQ-03")[0]
	if not TestCheck.ok(self, d3.staff.map(func(x): return x.post) == Organization.POST_ORDER, "staff sorted by post"): return false
	sim.cmd.force_state(f2, "severe")
	sim.cmd.force_state(g3, "severe")
	var assault: String = f3.staff.filter(func(x): return x.post == "assault")[0].id
	return TestCheck.ok(self, f2.cmdr_sub == _fleet(o, "RC-LIU-SQ-02").vice and g3.cmdr_sub == assault, "succession vice %s / staff %s" % [f2.cmdr_sub, g3.cmdr_sub])

# 끈 함대 + 세 세력 자동 편성으로 전투 종료까지(입문, 공격 정책), 재생 헤더(JSON 왕복)로 같은 지문
func _to_end() -> bool:
	var pi := ScenarioProfile.load_profile(DEF, "입문")
	var o := Organization.default_org(pi)
	for fid in ["liu_bei", "sun_quan", "cao_cao"]:
		o = Organization.auto_fill(o, fid, scn, pi)
	_fleet(o, "RC-LIU-SQ-03").on = false
	_fleet(o, "RC-SUN-SQ-02").on = false
	var pa := Organization.apply(pi, o, scn)
	for seed_id in END_SEEDS:
		var sim := BattleSim.new(seed_id, BattleRules.TICK_HZ, pa)
		var hz: int = sim.st.hz
		while not sim.st.over and sim.st.tick < END_MAX:
			if sim.st.tick % (5 * hz) == 0:
				for a in sim.st.alive(0):
					var n := sim.sight_foe(a, 1e9)
					if n:
						sim.queue(BattleSim.command(0, [a.id], "attack", n.id))
			sim.step()
			sim.drain_events()
		if not TestCheck.ok(self, sim.st.over, "seed %d battle ends (%s)" % [seed_id, sim.st.end_reason]): return false
		var header: Dictionary = JSON.parse_string(JSON.stringify(pa.organization))
		var rp := Organization.apply(ScenarioProfile.load_profile(DEF, "입문"), header, scn)
		var again := BattleSim.replay(seed_id, hz, sim.command_log, sim.st.tick, rp)
		if not TestCheck.ok(self, again.st.over and again.fingerprint() == sim.fingerprint(), "seed %d replay to end" % seed_id): return false
		print("seed %d: %s at %ds" % [seed_id, sim.st.end_reason, sim.st.tick / hz])
	return true
