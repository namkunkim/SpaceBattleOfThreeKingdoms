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

# 인물 ID(CHR-xxxx) → {id, name, faction(세력 키)}. 전대의 지휘관·부지휘관·참모와 불참 인물에서 찾는다.
static func person(d: Dictionary, id: String) -> Dictionary:
	for s in d.get("squadrons", []):
		var ppl: Array = [s.get("commander", {}), s.get("vice_commander", {})]
		ppl.append_array(s.get("staff", []))
		for p in ppl:
			if p is Dictionary and p.get("id", "") == id:
				return {"id": id, "name": p.name, "faction": FACTION_KEY.get(s.faction_id, "shu")}
	for f in d.get("factions", []):
		for p in f.get("not_deployed", []):
			if p.get("id", "") == id:
				return {"id": id, "name": p.name, "faction": FACTION_KEY.get(f.id, "shu")}
	return {}

# ---------------------------------------------------------------- 난이도(리뷰 W-2)
# cao_scale_rule: 조조군 전대마다 함종별 척 수 × count_factor를 half-up 반올림, 원래 1척 이상이면 최소 1척.
# 난이도가 deploy_min_difficulty보다 낮으면 그 전대는 배치하지 않는다. 연합 편성은 모든 난이도에서 같다.
static func deployed(d: Dictionary, faction_id: String, difficulty: String) -> Array:
	var order: Array = d.get("difficulty_order", [])
	var lv := order.find(difficulty)
	var factor: float = float(d.get("difficulty_profiles", {}).get(difficulty, {}).get("count_factor", 1.0))
	var out := []
	for s in squadrons_of(d, faction_id):
		var need := order.find(s.get("deploy_min_difficulty", order[0] if not order.is_empty() else ""))
		if faction_id == "cao_cao" and need > lv:
			continue
		if faction_id != "cao_cao":
			out.append(s)
			continue
		var t: Dictionary = s.duplicate(true)
		for c in t.composition:
			var n := int(c.count)
			# half-up을 정수로 센다(부동소수 오차로 3.5가 3.4999…가 되지 않게)
			var milli := roundi(factor * 1000.0)
			c.count = maxi(1 if n >= 1 else 0, (n * milli + 500) / 1000)
		out.append(t)
	return out

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
