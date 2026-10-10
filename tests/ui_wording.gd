extends SceneTree

# 화면 문구에 "전대"가 없는지 검사한다(Q73: 조종 단위는 모두 "함대", O5).
# hud·view·input·scripts·core의 GDScript 문자열 리터럴(주석 제외)과, 화면에 나오는 데이터 필드(이름·역할)를 본다.
# 내부 식별자(squadrons, squadron_strip 등)와 주석·규칙 메모(note)는 대상이 아니다.

const WORD := "전대"
const DIRS := ["res://hud", "res://view", "res://input", "res://scripts", "res://core"]
const DATA := ["res://data/scenarios/red_cliffs_208_realtime.json", "res://data/profiles/poc_corridor.json",
	"res://data/profiles/red_cliffs_rt.json"]
const SHOWN_KEYS := ["name", "role", "label", "title", "text"]

func _initialize() -> void:
	call_deferred("_run")

func _gd_files(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_gd_files(dir.path_join(d), out)

# 한 줄의 문자열 리터럴들. 문자열 밖의 #부터는 주석이라 버린다.
static func literals(line: String) -> Array:
	var out := []
	var q := ""
	var cur := ""
	var i := 0
	while i < line.length():
		var ch := line[i]
		if q == "":
			if ch == "#":
				break
			if ch == "\"" or ch == "'":
				q = ch
				cur = ""
		elif ch == "\\":
			i += 1
		elif ch == q:
			out.append(cur)
			q = ""
		else:
			cur += ch
		i += 1
	return out

func _shown(v, path: String, bad: Array) -> void:
	if v is Dictionary:
		for k in v:
			if k in SHOWN_KEYS and v[k] is String and WORD in v[k]:
				bad.append("%s.%s = %s" % [path, k, v[k]])
			else:
				_shown(v[k], path + "." + str(k), bad)
	elif v is Array:
		for i in v.size():
			_shown(v[i], "%s[%d]" % [path, i], bad)

func _run() -> void:
	# 판정기 자체: 주석 속 단어는 무시, 문자열 속 단어는 잡는다
	if not TestCheck.ok(self, literals("x(\"a 전대\") # \"전대\"") == ["a 전대"] and literals("# \"전대\"").is_empty(), "literals"): return
	var bad := []
	var files := []
	for d in DIRS:
		_gd_files(d, files)
	if not TestCheck.ok(self, files.size() > 20, "gd files %d" % files.size()): return
	for f in files:
		var lines := FileAccess.get_file_as_string(f).split("\n")
		for n in lines.size():
			for s in literals(lines[n]):
				if WORD in s:
					bad.append("%s:%d %s" % [f, n + 1, s])
	for f in DATA:
		_shown(JSON.parse_string(FileAccess.get_file_as_string(f)), f.get_file(), bad)
	if not TestCheck.ok(self, bad.is_empty(), "화면 문구에 \"전대\":\n" + "\n".join(bad)): return
	print("UI_WORDING_PASS")
	quit(0)
