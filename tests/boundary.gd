extends SceneTree

# 계층 경계 정적 검사(제안서 §3.5, M1 §9.2 5).
# - core/: Node·Input·전역 난수·Time·타이머·프레임 delta 0건
# - view/·hud/·input/: 코어 클래스(BattleSim·BattleState·FleetState·BattleRules·BattleRng·BattleProjection·TickClock 등) 참조 0건
#   (화면은 투영과 화면 모델만 읽고, 입력은 명령 사전만 만든다)
# 주석 줄과 문자열 안은 보지 않는다.

const CORE_FORBIDDEN := [
	"\\bNode\\b", "\\bNode[23]D\\b", "\\bControl\\b", "\\bInput\\b", "\\bInputEvent\\w*",
	"\\brandf\\b", "\\brandi\\b", "\\brandomize\\b", "\\brand_range\\b", "\\brandf_range\\b", "\\brandi_range\\b", "\\bRandomNumberGenerator\\b",
	"\\bcreate_timer\\b", "\\bTime\\.", "\\bOS\\.", "\\bget_tree\\b", "\\b_process\\b", "\\b_physics_process\\b", "\\bdelta\\b", "\\bEngine\\.", "\\bawait\\b",
]
const CORE_CLASSES := [
	"BattleSim", "BattleState", "FleetState", "BattleRules", "BattleRng", "BattleProjection", "BattleFingerprint",
	"TickClock", "PocSetup", "PocEnemyAi",
]
const SCREEN_DIRS := ["res://view", "res://hud", "res://input"]

func _initialize() -> void:
	call_deferred("_run")

func _files(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		_files(dir + "/" + d, out)

static func _strip(line: String) -> String:
	# 주석 제거(문자열 안의 #은 드물어 단순 처리), 따옴표 안 내용 제거
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

func _scan(path: String, patterns: Array, hits: Array) -> void:
	var text := FileAccess.get_file_as_string(path)
	var n := 0
	for raw in text.split("\n"):
		n += 1
		var line := _strip(raw)
		if line.strip_edges() == "":
			continue
		for p in patterns:
			var re := RegEx.create_from_string(p)
			if re.search(line):
				hits.append("%s:%d  %s  <- %s" % [path, n, p, raw.strip_edges()])

func _run() -> void:
	var core: Array = []
	_files("res://core", core)
	if not TestCheck.ok(self, core.size() >= 8, "core files found %d" % core.size()): return
	var hits: Array = []
	for f in core:
		_scan(f, CORE_FORBIDDEN, hits)
	if not TestCheck.ok(self, hits.is_empty(), "core boundary:\n" + "\n".join(hits)): return
	var screens: Array = []
	for d in SCREEN_DIRS:
		_files(d, screens)
	if not TestCheck.ok(self, screens.size() >= 20, "screen files found %d" % screens.size()): return
	var pats: Array = []
	for c in CORE_CLASSES:
		pats.append("\\b" + c + "\\b")
	hits.clear()
	for f in screens:
		_scan(f, pats, hits)
	if not TestCheck.ok(self, hits.is_empty(), "screen layer touches core classes:\n" + "\n".join(hits)): return
	print("BOUNDARY_PASS core=%d screen=%d" % [core.size(), screens.size()])
	quit(0)
