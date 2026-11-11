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

# Packaged checkpoint engine ID and SHA-256 source digest shape.
const HASH_FORMAT_PATH := "res://core/battle/operation_private_state.gd"
const HASH_FORMAT_PATTERNS := {
	"engine hash prefix width": r'''(?mx)
		^[ \t]+ var \s+ engine \s* := \s*
		(?<quote>["']) %d\.%d\.%d\.%s\.%s \k<quote> \s* % \s* \[ \s*
		version \s* \. \s* major \s* , \s* version \s* \. \s* minor \s* , \s*
		version \s* \. \s* patch \s* , \s* version \s* \. \s* status \s* , \s*
		str \s* \( \s* version \s* \. \s* hash \s* \) \s* \. \s* left \s* \( \s*
		(?<width>9) \s* \) \s* ,? \s* \] [ \t]* \r?$''',
	"source SHA-256 digest width": r'''(?mx)
		^[ \t]+ if \s+ not \s+ digest \s+ is \s+ String \s+ or \s+
		digest \s* \. \s* length \s* \( \s* \) \s* != \s* (?<width>64) \s+ or \s+
		not \s+ digest \s* \. \s* is_valid_hex_number \s* \( \s* \) \s* or \s+
		digest \s* \. \s* begins_with \s* \( \s* (?: "\+" | '\+' ) \s* \) \s* or \s+
		digest \s* \. \s* begins_with \s* \( \s* (?: "-" | '-' ) \s* \) \s* or \s+
		digest \s* != \s* digest \s* \. \s* to_lower \s* \( \s* \) \s* : [ \t]* \r?$''',
}

# Approved checkpoint, replay, and adapter format literals. An empty function
# name selects top-level declarations. Named captures identify only the literals
# belonging to each role. A missing or duplicate statement is a separate error.
const STRUCTURE_PATTERNS := {
	"res://core/battle/first_operation_checkpoint.gd": {
		"": {
			"checkpoint tick limit": 'const \\s+ MAX_TICKS \\s* := \\s* (?<value>12000)',
			"checkpoint counter limit": 'const \\s+ MAX_COUNT \\s* := \\s* (?<value>2147483647)',
			"checkpoint command batch limit": 'const \\s+ MAX_BATCH \\s* := \\s* (?<value>256)',
		},
		"prepare_restore": {
			"initial restore step budget": 'var \\s+ result \\s* := \\s* job \\s* \\. \\s* step \\s* \\( \\s* (?<value>100000) \\s* \\)',
			"repeated restore step budget": 'result \\s* = \\s* job \\s* \\. \\s* step \\s* \\( \\s* (?<value>100000) \\s* \\)',
		},
		"_normalize": {
			"checkpoint digest width": 'if \\s+ not \\s+ _hex \\s* \\( \\s* packet \\s* \\[ \\s* key \\s* \\] \\s* , \\s* (?<value>64) \\s* \\) \\s* :',
			"operation ID suffix width": r'''if \s+ not \s+ operation_id \s+ is \s+ String \s+ or \s+ not \s+ operation_id \s* \. \s* begins_with \s* \( \s* prefix \s* \) \s+ or \s+ not \s+ _hex \s* \( \s* operation_id \s* \. \s* trim_prefix \s* \( \s* prefix \s* \) \s* , \s* (?<value>32) \s* \) \s* :''',
			"checkpoint request uint32 limit": 'if \\s+ not \\s+ _uint \\s* \\( \\s* field \\s* , \\s* (?<value>4294967295) \\s* \\) \\s* :',
			"checkpoint request string limit": 'if \\s+ not \\s+ field \\s+ is \\s+ String \\s+ or \\s+ field \\s* \\. \\s* length \\s* \\( \\s* \\) \\s* > \\s* (?<value>128) \\s* :',
			"checkpoint tick to clock conversion": r'''if \s+ not \s+ _uint \s* \( \s* packet \s* \. \s* tick \s* , \s* MAX_TICKS \s* \) \s+ or \s+ not \s+ _uint \s* \( \s* packet \s* \. \s* clock_ms \s* , \s* MAX_TICKS \s* \* \s* (?<limit>100) \s* \) \s+ or \s+ int \s* \( \s* packet \s* \. \s* clock_ms \s* \) \s* != \s* int \s* \( \s* packet \s* \. \s* tick \s* \) \s* \* \s* (?<match>100) \s* :''',
		},
	},
	"res://core/battle/first_operation_dev.gd": {
		"_build_runtime": {
			"operation ID random byte count": r'''operation_id \s* = \s* DEFINITION_ID \s* \+ \s* (?: "/" | '/' ) \s* \+ \s* Crypto \s* \. \s* new \s* \( \s* \) \s* \. \s* generate_random_bytes \s* \( \s* (?<value>16) \s* \) \s* \. \s* hex_encode \s* \( \s* \)''',
		},
	},
	"res://core/battle/first_operation_preparer.gd": {
		"_validate_request": {
			"preparer seed uint32 limit": r'''if \s+ typeof \s* \( \s* request \s* \. \s* seed \s* \) \s* != \s* TYPE_INT \s+ or \s+ request \s* \. \s* seed \s* < \s* 0 \s+ or \s+ request \s* \. \s* seed \s* > \s* (?<value>4294967295) \s* :''',
		},
		"_initial_clock_matches": {
			"initial projection clock frequency": r'''
				return \s* \( \s* typeof \s* \( \s* summary \s* \. \s* get \s* \( \s* "tick" \s* \) \s* \) \s* == \s* TYPE_INT \s+ and \s+ summary \s* \. \s* tick \s* == \s* 0
				\s+ and \s+ typeof \s* \( \s* summary \s* \. \s* get \s* \( \s* "clock_ms" \s* \) \s* \) \s* == \s* TYPE_INT \s+ and \s+ summary \s* \. \s* clock_ms \s* == \s* 0
				\s+ and \s+ typeof \s* \( \s* summary \s* \. \s* get \s* \( \s* "over" \s* \) \s* \) \s* == \s* TYPE_BOOL \s+ and \s+ not \s+ summary \s* \. \s* over
				\s+ and \s+ typeof \s* \( \s* projection \s* \. \s* get \s* \( \s* "tick" \s* \) \s* \) \s* == \s* TYPE_INT \s+ and \s+ projection \s* \. \s* tick \s* == \s* summary \s* \. \s* tick
				\s+ and \s+ typeof \s* \( \s* projection \s* \. \s* get \s* \( \s* "side" \s* \) \s* \) \s* == \s* TYPE_INT \s+ and \s+ projection \s* \. \s* side \s* == \s* 0
				\s+ and \s+ typeof \s* \( \s* projection \s* \. \s* get \s* \( \s* "hz" \s* \) \s* \) \s* == \s* TYPE_INT \s+ and \s+ projection \s* \. \s* hz \s* == \s* (?<value>10)
				\s+ and \s+ projection \s* \. \s* get \s* \( \s* "clock_s" \s* \) \s* == \s* 0\.0
				\s+ and \s+ projection \s* \. \s* get \s* \( \s* "squadrons" \s* \) \s+ is \s+ Array \s* \)''',
		},
	},
	"res://core/battle/operation_replay.gd": {
		"": {
			"replay byte limit": 'const \\s+ MAX_BYTES \\s* := \\s* (?<mib>16) \\s* \\* \\s* (?<kib>1024) \\s* \\* \\s* (?<bytes>1024)',
			"replay tick limit": 'const \\s+ MAX_TICKS \\s* := \\s* (?<value>18000)',
			"replay command limit": 'const \\s+ MAX_COMMANDS \\s* := \\s* (?<value>18000)',
			"replay ID limit": 'const \\s+ MAX_ID \\s* := \\s* (?<value>2147483647)',
		},
	},
	"res://core/battle/operation_runtime_adapter.gd": {
		"": {
			"adapter integer limit": 'const \\s+ LIMIT \\s* := \\s* (?<value>2147483647)',
		},
		"normalize": {
			"adapter seed uint32 limit": r'''var \s+ maximum \s* := \s* (?<value>4294967295) \s+ if \s+ key \s* == \s* "seed" \s+ else \s+ LIMIT''',
			"adapter supported clock frequency": r'''if \s+ value \s* \. \s* hz \s* != \s* (?<value>10) \s* : \s* return \s+ fail \s* \( \s* "unsupported_hz" \s* , \s* "hz" \s* \)''',
		},
	},
}

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


# Keep quoted tokens and physical line numbers for the two statement matches.
func _hash_format_lines(source: String, remaining: Dictionary) -> Dictionary:
	var trivia := RegEx.create_from_string("(?m)(\"\"\"[\\s\\S]*?\"\"\"|'''[\\s\\S]*?''')|(\"(?:\\\\[^\\r\\n]|[^\"\\\\\\r\\n])*\"|'(?:\\\\[^\\r\\n]|[^'\\\\\\r\\n])*')|#[^\\r\\n]*|\\\\(?=[ \\t]*\\r?$)")
	var code := ""
	var offset := 0
	for token in trivia.search_all(source):
		code += source.substr(offset, token.get_start() - offset)
		if token.get_string(1) != "":
			code += "~" + "\n~".repeat(token.get_string(1).count("\n"))
		else:
			code += token.get_string(2)
		offset = token.get_end()
	code += source.substr(offset)
	var header := RegEx.create_from_string("(?m)^static[ \\t]+func[ \\t]+_packaged_code[ \\t]*\\([ \\t]*\\)[ \\t]*->[ \\t]*Dictionary[ \\t]*:[ \\t]*\\r?$").search(code)
	var lines := {}
	if header == null:
		return lines
	var start := header.get_end()
	var next_top_level := RegEx.create_from_string("(?m)^(?:(?:static[ \\t]+)?func|class|class_name|extends|const|var|enum|signal)\\b|^@").search(code, start)
	var end := code.length() if next_top_level == null else next_top_level.get_start()
	for name in HASH_FORMAT_PATTERNS:
		var occurrence := RegEx.create_from_string(HASH_FORMAT_PATTERNS[name]).search(code, start, end)
		if occurrence != null:
			var line := code.count("\n", 0, occurrence.get_start("width")) + 1
			lines[line] = occurrence.get_string("width")
			remaining.erase(name)
	return lines

# Preserve offsets while treating explicit continuations as part of the same
# logical statement. Quoted tokens are kept for matching; multiline strings are opaque.
func _structure_source(source: String) -> String:
	var trivia := RegEx.create_from_string(r'''(?x)
		(?<multiline> (?<delimiter> "{3} | '{3} )
			(?: \\ [\s\S] | (?! \k<delimiter> | \\ ) [\s\S] )* \k<delimiter> )
		| (?<quoted> "(?: \\ [^\r\n] | [^"\\\r\n] )*" | '(?: \\ [^\r\n] | [^'\\\r\n] )*' )
		| \# [^\r\n]*
		| \\ [ \t]* \r?\n
	''')
	var code := ""
	var offset := 0
	for token in trivia.search_all(source):
		code += source.substr(offset, token.get_start() - offset)
		if token.get_string("multiline") != "":
			for ch in token.get_string():
				code += ch if ch == "\n" or ch == "\r" else "~"
		elif token.get_string("quoted") != "":
			code += token.get_string("quoted")
		else:
			code += " ".repeat(token.get_end() - token.get_start())
		offset = token.get_end()
	return code + source.substr(offset)


func _structure_occurrences(path: String, source: String, code: String, findings: Array, errors: Array) -> Dictionary:
	var lines := {}
	var declarations := RegEx.create_from_string(
		r'(?m)^(?:(?:static[ \t]+)?func[ \t]+([A-Za-z_][A-Za-z_0-9]*)|class\b|class_name\b|extends\b|const\b|var\b|enum\b|signal\b|@)'
	).search_all(code)
	var scopes: Dictionary = STRUCTURE_PATTERNS[path]
	for scope in scopes:
		var ranges: Array[Vector2i] = []
		var indent := "[ \t]+"
		if scope == "":
			ranges.append(Vector2i(0, code.length()))
			indent = ""
		else:
			for i in declarations.size():
				if declarations[i].get_string(1) == scope:
					var end: int = declarations[i + 1].get_start() if i + 1 < declarations.size() else code.length()
					ranges.append(Vector2i(declarations[i].get_end(), end))
		for role in scopes[scope]:
			var pattern := RegEx.create_from_string("(?mx)^" + indent + scopes[scope][role] + "[ \t]*\\r?$")
			var matches: Array[RegExMatch] = []
			for span in ranges:
				matches.append_array(pattern.search_all(code, span.x, span.y))
			if matches.size() != 1:
				errors.append("%s  missing, changed or duplicate structure  <- %s (%d matches)" % [path, role, matches.size()])
				continue
			var occurrence := matches[0]
			for name in occurrence.get_names():
				var offset := occurrence.get_start(name)
				var line := source.count("\n", 0, offset) + 1
				var column := offset - source.rfind("\n", offset) - 1
				var literal := occurrence.get_string(name)
				if not lines.has(line):
					lines[line] = []
				lines[line].append(Vector2i(column, literal.length()))
				findings.append("%s:%d  %s  <- %s" % [path, line, literal, role])
	return lines

func _scan_literals(path: String, hits: Array, remaining_hash_format: Dictionary, structure: Array, structure_errors: Array) -> void:
	var base := path.get_file()
	if EXEMPT_FILES.has(base):
		return
	var skip_funcs: Array = EXEMPT_FUNCS.get(base, [])
	var re := RegEx.create_from_string("(?<![\\w.])(\\d+\\.?\\d*(?:e-?\\d+)?)\\b")
	var in_skip := false
	var source := FileAccess.get_file_as_string(path)
	var syntax := source
	var structure_lines := {}
	if STRUCTURE_PATTERNS.has(path):
		syntax = _structure_source(source)
		structure_lines = _structure_occurrences(path, source, syntax, structure, structure_errors)
	var format_lines := {}
	if path == HASH_FORMAT_PATH:
		format_lines = _hash_format_lines(source, remaining_hash_format)
	var n := 0
	var offset := 0
	for raw in source.split("\n"):
		n += 1
		var masked := syntax.substr(offset, raw.length())
		offset += raw.length() + 1
		for span in structure_lines.get(n, []):
			masked = masked.substr(0, span.x) + " ".repeat(span.y) + masked.substr(span.x + span.y)
		var line := _code(masked)
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
			var literal := m.get_string(1)
			if not ALLOWED_NUMBERS.has(literal) and format_lines.get(n) != literal:
				hits.append("%s:%d  %s  <- %s" % [path, n, literal, raw.strip_edges()])

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
	var remaining_hash_format := HASH_FORMAT_PATTERNS.duplicate()
	var structure: Array = []
	var structure_errors: Array = []
	for f in core:
		_scan_literals(f, hits, remaining_hash_format, structure, structure_errors)
	if not structure.is_empty():
		print("data_rules structure literals (%d):\n%s" % [structure.size(), "\n".join(structure)])
	var errors := PackedStringArray()
	if not hits.is_empty():
		errors.append("core에 규칙 수치 리터럴:\n" + "\n".join(hits))
	for name in remaining_hash_format:
		errors.append("%s  missing or changed hash format  <- %s" % [HASH_FORMAT_PATH, name])
	if not structure_errors.is_empty():
		errors.append("data_rules structure errors:\n" + "\n".join(structure_errors))
	if not TestCheck.ok(self, errors.is_empty(), "\n".join(errors)): return
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
	if not _chase_fallback(): return
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

# 시나리오 교전 거리 우선, 누락 시 POC 정본의 추격 기본값 170 유지.
# 실제 이동 분기를 한 번 실행한다. fallback을 지우면 169에서도 추격하므로 실패한다.
func _chase_fallback() -> bool:
	if not TestCheck.ok(self, PocSetup.profile().rules.chase_engagement_fallback_r == 170, "chase fallback data = 170"): return false
	var missing := [
		{},
		{"scenario_id": "no-realtime"},
		{"realtime_rules": {}},
		{"realtime_rules": {"range_band_hold": {}}},
	]
	var cases := []
	for i in missing.size():
		cases.append({"label": "missing-%d-inside" % i, "scenario": missing[i], "distance": 169.0, "moves": false})
		cases.append({"label": "missing-%d-outside" % i, "scenario": missing[i], "distance": 171.0, "moves": true})
	cases.append({"label": "override-150", "scenario": {"realtime_rules": {"range_band_hold": {"engagement_distance": 150}}}, "distance": 160.0, "moves": true})
	cases.append({"label": "override-200", "scenario": {"realtime_rules": {"range_band_hold": {"engagement_distance": 200}}}, "distance": 180.0, "moves": false})
	for c in cases:
		var s := SalvoFixture.sim(
			[SalvoFixture.def("chaser", 400, 450, [["SHP-04", 1]], true)],
			[SalvoFixture.def("target", 400 + float(c.distance), 450, [["SHP-04", 1]], true)])
		s.rs.scenario = c.scenario.duplicate(true)
		s.assault = AssaultCore.new(s, s.salvo.C.assault)
		# 별도 위치 차단은 hold_distance.gd가 검사한다. 누락 데이터에서도 추격 임계만 고립한다.
		s._hold_d2 = 0.0
		var f: FleetState = s.st.fleets[0]
		var target: FleetState = s.st.fleets[1]
		f.target_id = target.id
		f.heading = 0.0
		if not TestCheck.ok(self, s.salvo != null and s.assault != null and f.charge == 0 and s.sight_target(f) == target and f.range_r * s.R.chase_range_share < float(c.distance), "chase branch setup " + c.label): return false
		var start := f.pos
		s._fleet_phase(false)
		var moved := f.pos.x > start.x and is_equal_approx(f.pos.y, start.y)
		if not TestCheck.ok(self, moved == c.moves and f.moving == c.moves and (bool(c.moves) or f.pos == start), "chase fallback/override " + c.label): return false
	return true

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
