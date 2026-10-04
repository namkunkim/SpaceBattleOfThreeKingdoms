class_name RuleSet
extends RefCounted

# 규칙 수치 묶음. 값은 코드가 아니라 프로필 JSON의 "rules"에서 온다(M2 데이터 정본화).
# 키 이름 규칙: `_bp`·`_ms`·`_n`으로 끝나는 키는 정수, 나머지는 실수로 읽는다.
# 코어는 `rs.v.<키>`로 읽는다. 키가 JSON에 있는지는 tests/data_rules.gd가 소스 전체를 훑어 확인한다.

var v := {}
var world := Vector2.ZERO
# 시나리오 데이터(시나리오 프로필일 때만 채워진다): 난이도 프로필, difficulty_policy, realtime_rules 등.
# realtime_rules의 status "proposed" 값도 그대로 들어 있다. 규칙 동작은 M3 이후 단계가 이 값을 읽는다.
var scenario := {}
# 사격·피해 규칙(M3, data/profiles/combat_m3.json). 비어 있으면 POC 규칙이다. 코어는 BattleSim.salvo.C로 읽는다.
var c := {}

static func from_profile(profile: Dictionary) -> RuleSet:
	var rs := from_dict(profile.rules)
	rs.scenario = profile.get("scenario", {})
	rs.c = profile.get("combat", {})
	return rs

# realtime_rules 안의 값을 "a.b.c" 경로로 읽는다. 없으면 fallback.
func rt(path: String, fallback: Variant = null) -> Variant:
	var cur: Variant = scenario.get("realtime_rules", {})
	for key in path.split("."):
		if typeof(cur) == TYPE_DICTIONARY and cur.has(key):
			cur = cur[key]
		elif typeof(cur) == TYPE_ARRAY and key.is_valid_int() and int(key) < cur.size():
			cur = cur[int(key)]
		else:
			return fallback
	return cur

# status가 "proposed"인 realtime_rules 노드의 경로 목록(잠정값 추적용).
func proposed_paths() -> Array[String]:
	var out: Array[String] = []
	_walk_proposed(scenario.get("realtime_rules", {}), "", out)
	return out

static func _walk_proposed(node: Variant, path: String, out: Array[String]) -> void:
	if typeof(node) == TYPE_DICTIONARY:
		if node.get("status", "") == "proposed":
			out.append(path if path != "" else "realtime_rules")
		for k in node:
			_walk_proposed(node[k], k if path == "" else path + "." + k, out)
	elif typeof(node) == TYPE_ARRAY:
		for i in node.size():
			_walk_proposed(node[i], "%s.%d" % [path, i], out)

# 난이도 프로필의 AI 값(ai-design §9). 시나리오 프로필이 아니면 빈 사전.
func difficulty_ai() -> Dictionary:
	return scenario.get("difficulty_profile", {}).get("ai", {})

static func from_dict(rules: Dictionary) -> RuleSet:
	var rs := RuleSet.new()
	for k in rules:
		var x = rules[k]
		if typeof(x) == TYPE_ARRAY or typeof(x) == TYPE_DICTIONARY or typeof(x) == TYPE_STRING or typeof(x) == TYPE_BOOL:
			rs.v[k] = x
		elif k.ends_with("_bp") or k.ends_with("_ms") or k.ends_with("_n"):
			rs.v[k] = int(x)
		else:
			rs.v[k] = float(x)
	rs.world = Vector2(rs.v.get("world_w", 0.0), rs.v.get("world_h", 0.0))
	return rs

# 맞는 방향 피해 배율: 정면, 측면, 후면 (경계 처리는 M3에서 Q33으로)
func flank_mul(att_pos: Vector2, tgt_pos: Vector2, tgt_heading: float) -> float:
	var a := atan2(att_pos.y - tgt_pos.y, att_pos.x - tgt_pos.x)
	var d := absf(BattleRules.ang_diff(tgt_heading, a))
	if d < deg_to_rad(v.flank_front_deg):
		return 1.0
	if d < deg_to_rad(v.flank_side_deg):
		return v.flank_side_mul
	return v.flank_rear_mul

func level_mul(lv: int) -> float:
	return 1.0 + v.level_step * (lv - 1)

# 화력 배율: 레벨, 돌격, 지휘 범위 밖, 방어진형
func power(lv: int, charging: bool, in_cmd: bool, defense: bool) -> float:
	return level_mul(lv) * (v.charge_power_mul if charging else 1.0) * (1.0 if in_cmd else v.out_cmd_power_mul) * (v.defense_power_mul if defense else 1.0)

func xp_need_milli(lv: int) -> int:
	return (v.xp_base_n + lv * v.xp_per_lv_n) * BattleRules.MILLI

func move_speed(spd: float, defense: bool, charging: bool) -> float:
	return v.base_speed * spd * (v.defense_speed_mul if defense else 1.0) * (v.charge_speed_mul if charging else 1.0)

# 표시 척 수(진형 슬롯 수). 함재기·미사일 발사 위치가 이 값으로 정해진다(M3에서 정리할 결함).
func n_ships(ships_milli: int, max_milli: int) -> int:
	var cap: int = v.max_visible_n
	return maxi(1, mini(cap, ceili(float(cap) * ships_milli / maxf(1.0, max_milli))))
