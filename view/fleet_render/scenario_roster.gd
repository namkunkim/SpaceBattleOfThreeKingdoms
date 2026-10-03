class_name ScenarioRoster
extends RefCounted

# 정본 편성 읽기(data/scenarios/*.json). 표시 전용이다. 전투 규칙 값은 코어가 같은 파일에서 읽는다.
# 함종 ID는 제안서 v0.2 §4.1·DATA-CROSSCHECK §1 순서(ID 오름차순)를 따른다.

const DEFAULT_PATH := "res://data/scenarios/red_cliffs_208_realtime.json"

# 함종: 이름, 짧은 이름, 표시 모델(fleet_renderer 함종). 고속정은 절차적 글리프(모델 없음).
const SHIP_TYPES := {
	"SHP-01": {"name": "강습모함", "short": "모함", "model": "항모"},
	"SHP-02": {"name": "공성함", "short": "공성", "model": "공성함"},
	"SHP-03": {"name": "포격함", "short": "포격", "model": "화력함"},
	"SHP-04": {"name": "전열함", "short": "전열", "model": "전열함"},
	"SHP-05": {"name": "보급함", "short": "보급", "model": "보급_수리함"},
	"SHP-06": {"name": "전자전함", "short": "전자", "model": "전자전함"},
	"SHP-07": {"name": "요격함", "short": "요격", "model": "호위함"},
	"SHP-08": {"name": "고속정", "short": "고속", "model": ""},
}

# 시나리오 세력 ID → 표시 세력 키(Factions)
const FACTION_KEY := {"liu_bei": "shu", "sun_quan": "wu", "cao_cao": "wei"}
const CONTROL_LABEL := {"player": "직접 지휘", "ai_delegate": "동맹 · 위임", "ai": "적"}

static var _cache := {}

static func load_scenario(path := DEFAULT_PATH) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	_cache[path] = d if d is Dictionary else {}
	return _cache[path]

static func squadrons_of(d: Dictionary, faction_id: String) -> Array:
	return d.get("squadrons", []).filter(func(s): return s.faction_id == faction_id)

static func groups_of(d: Dictionary, faction_id: String) -> Array:
	return d.get("fleet_groups", []).filter(func(g): return g.faction_id == faction_id)

static func squadron(d: Dictionary, id: String) -> Dictionary:
	for s in d.get("squadrons", []):
		if s.id == id:
			return s
	return {}

static func ship_count(s: Dictionary) -> int:
	var n := 0
	for c in s.get("composition", []):
		n += int(c.count)
	return n

# "전열 4 · 보급 1 · 요격 2"
static func composition_text(s: Dictionary, short := true) -> String:
	var parts := PackedStringArray()
	for c in s.get("composition", []):
		var t: Dictionary = SHIP_TYPES.get(c.ship_type_id, {"name": c.ship_type_id, "short": c.ship_type_id})
		parts.append("%s %d" % [t.short if short else t.name, int(c.count)])
	return " · ".join(parts)
