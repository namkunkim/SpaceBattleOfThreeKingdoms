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
	if not TestCheck.ok(self, foes["입문"].foe.size() == 4 and foes["표준"].foe.size() == 5 and foes["상급"].foe.size() == 7 and foes["극한"].foe.size() == 7, "cao squadron count by difficulty"): return
	for diff in foes:
		if not TestCheck.ok(self, foes[diff].ally.size() == 7, "alliance fixed %s" % diff): return
	var cao1_easy := _def(foes["입문"].foe, "RC-CAO-SQ-01")
	var cao1_hard := _def(foes["상급"].foe, "RC-CAO-SQ-01")
	# 중군 2,4,8,2,2,2,6척 × 0.7 half-up(최소 1) = 1,3,6,1,1,1,4 = 17 / 상급은 원래대로 26
	if not TestCheck.ok(self, cao1_easy.ships == 17 and cao1_hard.ships == 26, "count_factor: %d %d" % [cao1_easy.ships, cao1_hard.ships]): return
	if not TestCheck.ok(self, _def(foes["입문"].foe, "RC-CAO-SQ-05").is_empty() and not _def(foes["표준"].foe, "RC-CAO-SQ-05").is_empty(), "deploy_min_difficulty"): return
	var by_delay := {"RC-CAO-SQ-02": 0, "RC-CAO-SQ-04": 0, "RC-CAO-SQ-01": 180, "RC-CAO-SQ-03": 180, "RC-CAO-SQ-05": 180, "RC-CAO-SQ-06": 360, "RC-CAO-SQ-07": 360}
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
	# --- 6. 적벽 시나리오를 코어가 돌린다 ---
	var sim := BattleSim.new(5, 10, foes["표준"])
	if not TestCheck.ok(self, sim.st.alive(0).size() == 7 and sim.st.alive(1).size() == 5 and sim.rs.world == Vector2(1600, 900), "scenario spawn"): return
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
