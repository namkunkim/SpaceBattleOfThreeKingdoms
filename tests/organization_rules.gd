extends SceneTree

# O1 코어 편성(Organization, BATTLE_DECISIONS §T Q73~Q81): 검증 사유 코드, 자동 편성(한도·직책 능력치 순·결정론),
# 프로필 덮어쓰기(기본 편성은 결과 그대로, 재생 헤더로 같은 결과).

const DEF := "res://data/profiles/red_cliffs_rt.json"
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
		Organization.UNKNOWN_FLEET: func(o): o.fleets.append({"squadron_id": "RC-X", "faction_id": "liu_bei", "on": true, "admiral": "", "vice": "", "staff": [], "composition": []}),
	}
	for code in cases:
		var o := base.duplicate(true)
		cases[code].call(o)
		if not TestCheck.ok(self, _codes(o).has(code), "code %s: %s" % [code, _codes(o)]): return
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
	var min_cost := 1 << 30
	for t in prof.combat.ship_types.values():
		min_cost = mini(min_cost, int(t.cost))
	for fl in auto.fleets:
		var lim := Organization.limit_of(fl, scn, prof)
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

	# 덮어쓰기: 기본 편성은 결과를 바꾸지 않는다
	var fp0 := _run_fp(ScenarioProfile.load_profile(DEF, "표준"))
	var pd := Organization.apply(prof, base, scn)
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
	print("ORGANIZATION_RULES_OK")
	quit(0)

func _is_flag(sq: String) -> bool:
	return Organization._flags(scn).has(sq)
