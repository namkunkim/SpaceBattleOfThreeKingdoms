extends SceneTree

# M2 데이터 정본화 검사: 코어에 규칙 수치가 없고(정적), 코어가 읽는 키가 프로필에 모두 있으며,
# 시나리오 JSON(난이도, 투입 시각, realtime_rules)이 데이터로 읽힌다. 헤드리스, 실패하면 종료 코드 1.

# 코어 소스에서 허용하는 숫자 리터럴: 구조 값(0·1·2, 반, 분모, 단위 환산, 양자화 격자, 무한대 대용, 난수 하위 번호).
const ALLOWED_NUMBERS := ["0", "1", "2", "3", "4", "5", "0.0", "1.0", "2.0", "0.5", "1e9", "1e-9", "1000", "1000.0", "10000", "0.001"]
# 숫자 검사에서 빼는 파일과 이유
const EXEMPT_FILES := {
	"battle_rng.gd": "해시 산술",
	"battle_fingerprint.gd": "지문 형식",
	"tick_clock.gd": "실시간 시계 정책(UI 감속 단계, 프레임당 틱 상한). 규칙 값이 아니다",
}
# 단위 환산 상수 정의 줄(이름으로 허용). FORM_SHAPE는 진형 7종 → 배치도 번호 대응표(기하, 규칙 값 아님)
const UNIT_CONSTS := ["FORM_COUNT", "FORM_SHAPE", "TICK_HZ", "TICK_S", "REF_DT", "MILLI", "BP", "PCT"]
# rules.gd에서 이 함수 안은 진형 슬롯 기하라 검사에서 뺀다(M3에서 본편 진형 7종으로 교체)
const EXEMPT_FUNCS := {"rules.gd": ["formation_offsets"]}

func _initialize() -> void:
	call_deferred("_run")

func _files(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_files(dir + "/" + d, out)

# 주석과 따옴표 안을 뺀 코드 줄
static func _code(line: String) -> String:
	var out := ""
	var q := ""
	for i in line.length():
		var ch := line[i]
		if q != "":
			if ch == q:
				q = ""
			continue
		if ch == "\"" or ch == "'":
			q = ch
			continue
		if ch == "#":
			break
		out += ch
	return out

func _scan_literals(path: String, hits: Array) -> void:
	var base := path.get_file()
	if EXEMPT_FILES.has(base):
		return
	var skip_funcs: Array = EXEMPT_FUNCS.get(base, [])
	var re := RegEx.create_from_string("(?<![\\w.])(\\d+\\.?\\d*(?:e-?\\d+)?)\\b")
	var in_skip := false
	var n := 0
	for raw in FileAccess.get_file_as_string(path).split("\n"):
		n += 1
		var line := _code(raw)
		if line.begins_with("static func ") or line.begins_with("func "):
			in_skip = false
			for fn in skip_funcs:
				if line.contains(" " + fn + "("):
					in_skip = true
		if in_skip:
			continue
		var is_unit := false
		for c in UNIT_CONSTS:
			if line.begins_with("const " + c + " "):
				is_unit = true
		if is_unit:
			continue
		for m in re.search_all(line):
			if not ALLOWED_NUMBERS.has(m.get_string(1)):
				hits.append("%s:%d  %s  <- %s" % [path, n, m.get_string(1), raw.strip_edges()])

func _used_keys(path: String, keys: Dictionary) -> void:
	var re := RegEx.create_from_string("(?:\\bR|\\.R|\\brs\\.v|\\bv)\\.([a-z][a-z0-9_]*)(?![\\w(])")
	for raw in FileAccess.get_file_as_string(path).split("\n"):
		for m in re.search_all(_code(raw)):
			keys[m.get_string(1)] = path

func _run() -> void:
	var core: Array = []
	_files("res://core", core)
	# --- 1. 정적: 규칙 수치 리터럴 0건 ---
	var hits: Array = []
	for f in core:
		_scan_literals(f, hits)
	if not TestCheck.ok(self, hits.is_empty(), "core에 규칙 수치 리터럴:\n" + "\n".join(hits)): return
	# --- 2. 코어가 읽는 키가 프로필에 있고, 프로필에 안 쓰는 키가 없다 ---
	var used := {}
	for f in core:
		_used_keys(f, used)
	var poc := PocSetup.profile()
	var scn_prof := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json")
	if not TestCheck.ok(self, not scn_prof.is_empty(), "scenario profile load"): return
	for entry in [["poc", poc], ["red_cliffs", scn_prof]]:
		var rules: Dictionary = entry[1].rules
		for k in used:
			if not TestCheck.ok(self, rules.has(k), "%s 프로필에 규칙 키 없음: %s (%s)" % [entry[0], k, used[k]]): return
		for k in rules:
			if not TestCheck.ok(self, used.has(k) or k in ["world_w", "world_h"], "%s 프로필의 안 쓰는 규칙 키: %s" % [entry[0], k]): return
	# --- 3. POC 프로필: 편성이 데이터에서 온다 ---
	if not TestCheck.ok(self, poc.ally.size() == 6 and poc.foe.size() == 7 and poc.reinf.size() == 2, "poc fleets"): return
	var sim0 := BattleSim.new(1)
	if not TestCheck.ok(self, sim0.profile_id == "poc-red-cliffs-corridor" and sim0.rs.world == Vector2(3400, 2300), "poc profile"): return
	# --- 4. 적벽 시나리오: 난이도별 편성 ---
	var foes := {}
	for diff in ["입문", "표준", "상급", "극한"]:
		var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", diff)
		if not TestCheck.ok(self, not p.is_empty() and p.difficulty == diff, "profile " + diff): return
		foes[diff] = p
	# Q82: 조조 함대 수 = 난이도의 cao_fleets(입문 9 · 표준 10 · 상급/극한 14), 척 수 배율 없음, 마지막 함대만 fill_bp
	if not TestCheck.ok(self, foes["입문"].foe.size() == 9 and foes["표준"].foe.size() == 10 and foes["상급"].foe.size() == 14 and foes["극한"].foe.size() == 14, "cao fleet count by difficulty"): return
	for diff in foes:
		if not TestCheck.ok(self, foes[diff].ally.size() == 6, "alliance fixed %s" % diff): return
		var fills: Array = foes[diff].foe.filter(func(d): return d.has("fill_bp"))
		if not TestCheck.ok(self, fills.size() == 1 and fills[0] == foes[diff].foe[-1] and int(fills[0].fill_bp) == int(foes[diff].scenario.difficulty_profile.cao_last_fill_bp), "fill_bp는 마지막 조조 함대만 %s" % diff): return
	if not TestCheck.ok(self, _def(foes["입문"].foe, "RC-CAO-SQ-01").ships == 78 and _def(foes["입문"].foe, "RC-CAO-SQ-10").is_empty() and not _def(foes["표준"].foe, "RC-CAO-SQ-10").is_empty(), "배율 없음, 앞에서부터 배치"): return
	# Q82·Q83 비율: 게임 기본 경로(Organization.load_auto = 세 세력 자동 편성) 프로필에서 조조 비용 합 / 연합 비용 합이 난이도 목표 ±0.05
	for diff in foes:
		var p := Organization.load_auto("res://data/profiles/red_cliffs_rt.json", diff)
		if not TestCheck.ok(self, not p.is_empty() and p.has("organization"), "load_auto %s" % diff): return
		var sum := {"ally": 0, "foe": 0}
		for side in sum:
			for d in p[side]:
				for c in d.composition:
					sum[side] += int(c.count) * int(p.combat.ship_types[c.ship_type_id].cost)
		var ratio := float(sum.foe) / float(sum.ally)
		var want := float(p.scenario.difficulty_profile.target_cost_ratio)
		if not TestCheck.ok(self, absf(ratio - want) <= 0.05, "Q82 %s 비율 %.3f (목표 %.2f, 조조 %d / 연합 %d)" % [diff, ratio, want, sum.foe, sum.ally]): return
		print("Q82 %s 함대 %d 비율 %.3f" % [diff, p.foe.size(), ratio])
	var by_delay := {"RC-CAO-SQ-02": 0, "RC-CAO-SQ-04": 0, "RC-CAO-SQ-01": 180, "RC-CAO-SQ-03": 180, "RC-CAO-SQ-05": 180, "RC-CAO-SQ-06": 360, "RC-CAO-SQ-07": 360, "RC-CAO-SQ-14": 360}
	for id in by_delay:
		var d := _def(foes["극한"].foe, id)
		if not TestCheck.ok(self, int(d.wait) == by_delay[id], "deploy_delay_s %s = %s" % [id, str(d.get("wait"))]): return
	# 사기 시작값은 난이도 프로필에서 온다
	if not TestCheck.ok(self, _def(foes["표준"].foe, "RC-CAO-SQ-04").start_morale_bp == 6500 and _def(foes["극한"].foe, "RC-CAO-SQ-02").start_morale_bp == 10000, "start morale"): return
	# 플레이어 기함은 유비 본대 하나, 손권 기함은 기함이 아니다
	var flags := 0
	for d in foes["표준"].ally:
		if d.flag:
			flags += 1
			if not TestCheck.ok(self, d.squadron_id == "RC-LIU-SQ-01", "player flagship"): return
	if not TestCheck.ok(self, flags == 1, "one player flag"): return
	# --- 5. realtime_rules 데이터 ---
	var rs := RuleSet.from_profile(foes["표준"])
	if not TestCheck.ok(self, rs.world == Vector2(1600, 900), "world from battlefield_bounds"): return
	if not TestCheck.ok(self, rs.rt("linked_ships_and_plague.plague_interval_s") == 10.0 and rs.rt("morale_events.crisis_threshold_bp") == 4500.0, "rt lookup"): return
	if not TestCheck.ok(self, rs.rt("chain_operation.power_by_range.1.1") == 0.4 and rs.rt("no.such.path", "x") == "x", "rt array path / fallback"): return
	var prop := rs.proposed_paths()
	for must in ["linked_ships_and_plague", "morale_events", "chain_operation", "seed_variation", "cao_dispositions", "morale_events.rally.1"]:
		if not TestCheck.ok(self, prop.has(must), "proposed 경로 없음: %s (%s)" % [must, str(prop)]): return
	if not TestCheck.ok(self, rs.difficulty_ai().think_depth == 2 and rs.scenario.difficulty_policy.has("cao_scale_rule"), "difficulty policy data"): return
	if not _special_skills(rs.rt("special_skills", {}), ProfileLoader.read_json(ProfileLoader.read_json("res://data/profiles/red_cliffs_rt.json").scenario_path)): return
	# --- 6. 적벽 시나리오를 코어가 돌린다 ---
	var sim := BattleSim.new(5, 10, foes["표준"])
	if not TestCheck.ok(self, sim.st.alive(0).size() == 6 and sim.st.alive(1).size() == 10 and sim.rs.world == Vector2(1600, 900), "scenario spawn"): return
	var cao3 := _fleet(sim, "RC-CAO-SQ-03")
	var start := cao3.pos
	if not TestCheck.ok(self, cao3.wait == 1800 and cao3.start_morale_bp == 8000, "wait ticks / morale %d %d" % [cao3.wait, cao3.start_morale_bp]): return
	var a := BattleSim.new(5, 10, foes["표준"])
	var b := BattleSim.new(5, 10, foes["표준"])
	var first_move := -1
	while a.st.tick < 2400 and not a.st.over:
		a.step()
		a.drain_events()
		b.step()
		b.drain_events()
		var f := _fleet(a, "RC-CAO-SQ-03")
		if first_move < 0 and not f.dead and f.pos.distance_to(start) > 1.0:
			first_move = a.st.tick
	if not TestCheck.ok(self, a.fingerprint() == b.fingerprint(), "scenario determinism"): return
	if not TestCheck.ok(self, first_move < 0 or first_move >= 1700, "투입 전에 움직임: tick %d" % first_move): return
	var other := BattleSim.new(5, 10, foes["상급"])
	if not TestCheck.ok(self, other.fingerprint() != BattleSim.new(5, 10, foes["표준"]).fingerprint(), "difficulty changes state"): return
	print("DATA_RULES_PASS keys=%d core=%d proposed=%d first_move=%d" % [used.size(), core.size(), prop.size(), first_move])
	quit(0)

# P8a 특기 스키마(REVIEW-P8-0 F-12): 필수 키, 기술 ID 참조, 술어·requires·효과 키 허용 목록, 슬롯 기본값 직책명.
# 코어(skills.gd)가 해석하는 키만 허용한다. 슬롯 수·사용 횟수는 데이터에만 있다(코어 리터럴 검사는 1번이 한다)
const SK_TOP := ["uses_per_battle", "slots", "slot_default", "use_scope", "no_duplicate_skill_in_fleet", "stacking", "skills", "by_officer", "definitions"]
const SK_KEYS := ["id", "kind", "name", "target", "duration_s", "effects", "ai_when", "status"]
const SK_TARGETS := ["self", "ally_fleet", "enemy_fleet", "allies_in_radius", "side"]
const SK_PREDS := ["enemy_in_band", "enemy_within", "enemy_beyond_base_range_within_mul", "estimated_within", "enemy_flagship_within", "enemy_carrier_within",
	"self_hull_below_bp", "self_morale_below_bp", "self_retreating", "self_charges_zero", "ally_hull_below_bp_within", "ally_flagship_within",
	"ally_flagship_hull_below_bp", "wind_window_open", "chain_host_ai"]
const SK_REQS := ["has_ship_type", "enemy_within", "ally_within", "ally_flagship_within", "self_not_flagship", "charges_below_base", "chain_host"]
const SK_EFFECTS := ["damage_mul_bp", "damage_taken_mul_bp", "speed_mul_bp", "transition_mul_bp", "morale_bp", "morale_loss_mul_bp", "hit_bp",
	"sensor_mul_bp", "reveal_radius", "reveal_orders", "range_mul_bp", "categories", "charges_add", "assault_bp", "assault_cd_reset", "assault_block",
	"chain_power_mul_bp", "damage_redirect_bp", "affinity_ignore", "rescue_equipped", "in_terrain", "only_while", "alias_command", "note"]
const SK_STACK := ["damage_taken_reduction", "damage_taken_increase", "speed_mul", "transition_mul", "other"]

func _special_skills(sk: Dictionary, scn: Dictionary) -> bool:
	for k in SK_TOP:
		if not TestCheck.ok(self, sk.has(k), "special_skills 키 없음: " + k): return false
	if not TestCheck.ok(self, sk.use_scope == "fleet_skill_pair" and sk.no_duplicate_skill_in_fleet and int(sk.slots) == (sk.slot_default as Array).size(), "Q92 범위·슬롯 수"): return false
	for p in sk.slot_default:
		if not TestCheck.ok(self, p in ["admiral", "vice"] or (str(p).begins_with("staff_") and Organization.POSTS.has(str(p).trim_prefix("staff_"))), "slot_default 직책명 %s (F-9)" % p): return false
	for k in SK_STACK:
		if not TestCheck.ok(self, ["min_only", "max_only", "multiply"].has(str(sk.stacking.get(k, ""))), "stacking %s" % k): return false
	var ids := {}
	for d in sk.skills:
		for k in SK_KEYS:
			if not TestCheck.ok(self, d.has(k), "%s 키 없음: %s" % [d.get("id", "?"), k]): return false
		if not TestCheck.ok(self, not ids.has(d.id) and SK_TARGETS.has(d.target), "%s 중복·대상 %s" % [d.id, d.target]): return false
		ids[d.id] = true
		for k in d.effects:
			if not TestCheck.ok(self, SK_EFFECTS.has(k), "%s 효과 키 %s" % [d.id, k]): return false
		for k in d.get("requires", {}):
			if not TestCheck.ok(self, SK_REQS.has(k), "%s requires %s" % [d.id, k]): return false
		var w: Dictionary = d.ai_when
		if not TestCheck.ok(self, w.size() == 1 and (w.has("all") or w.has("any")), "%s ai_when 형식" % d.id): return false
		for p in w.values()[0]:
			if not TestCheck.ok(self, p.size() == 1 and SK_PREDS.has(p.keys()[0]), "%s 술어 %s" % [d.id, p]): return false
			if p.keys()[0] == "enemy_in_band":
				if not TestCheck.ok(self, SkillCore.BAND_RANK.has(p.values()[0]), "%s 거리대 %s" % [d.id, p]): return false
		if d.target in ["ally_fleet", "enemy_fleet", "allies_in_radius"]:
			if not TestCheck.ok(self, float(d.get("radius", 0)) > 0.0, "%s 반경" % d.id): return false
	var avail := {}
	for f in scn.factions:
		for o in f.get("available_officers", []):
			avail[str(o.id)] = o
	for oid in sk.by_officer:
		if not TestCheck.ok(self, ids.has(sk.by_officer[oid].skill) and avail.has(oid), "by_officer %s → %s" % [oid, sk.by_officer[oid].skill]): return false
	for oid in avail:
		if not TestCheck.ok(self, (avail[oid].get("traits", []) as Array).is_empty() != sk.by_officer.has(oid), "특성 보유 장수 = 기술 보유 %s" % oid): return false
	print("special_skills %d by_officer %d" % [ids.size(), sk.by_officer.size()])
	return true

func _def(defs: Array, sq_id: String) -> Dictionary:
	for d in defs:
		if d.squadron_id == sq_id:
			return d
	return {}

func _fleet(sim: BattleSim, sq_id: String) -> FleetState:
	for f in sim.st.fleets:
		if f.sq_id == sq_id:
			return f
	return null
