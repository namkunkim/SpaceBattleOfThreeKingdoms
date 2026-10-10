class_name ScenarioProfile
extends RefCounted

# 시나리오 JSON(data/scenarios/)과 프로필 정의(data/profiles/)를 합쳐 BattleSim이 받는 프로필 사전을 만든다.
# 편성, 난이도 적용(difficulty_policy), 투입 시각(deploy_delay_s), realtime_rules는 모두 데이터에서 읽는다.
# 순수 변환이다. 파일은 ProfileLoader로만 읽는다.
#
# 만든 프로필: {profile_id, difficulty, rules, ally, foe, reinf, combat, scenario: {...}}
#  - combat: 사격·피해 규칙 사전(data/profiles/combat_m3.json). 프로필 정의에 combat_rules_path가 있을 때만 채워진다(M3)
#  - ai: 지휘관 AI 수치 사전(data/profiles/ai_m7.json, M7). 프로필 정의에 ai_rules_path가 있을 때만 채워진다
#  - rules: base 프로필의 규칙 수치에 rule_overrides와 전장 크기(battlefield_bounds)를 덮은 것
#  - ally/foe: 전대 정의 사전(PocSetup과 같은 키 + squadron_id, faction_id, commander_id, might, intellect, morale_group, start_morale_bp, formation_id, composition)
#  - scenario: {difficulty_policy, difficulty_profile, realtime_rules, escape_points, ...}. RuleSet이 읽는다

# 프로필 정의 경로에서 읽어 만든다.
static func load_profile(def_path: String, difficulty := "", dprof_override := {}) -> Dictionary:
	var def := ProfileLoader.read_json(def_path)
	if def.is_empty():
		return {}
	var scn := ProfileLoader.read_json(def.scenario_path)
	var base := ProfileLoader.read_json(def.base_profile)
	if scn.is_empty() or base.is_empty():
		return {}
	if not dprof_override.is_empty() and scn.difficulty_profiles.has(difficulty):
		scn.difficulty_profiles[difficulty].merge(dprof_override, true)   # 밸런스 측정용(autoresolve --cao-fleets 등). 게임 흐름에서는 쓰지 않는다
	var combat := {}
	if def.has("combat_rules_path"):
		combat = ProfileLoader.read_json(def.combat_rules_path).get("combat", {})
		if combat.is_empty():
			return {}
	var p := build(def, scn, base, difficulty if difficulty != "" else def.default_difficulty, combat)
	if def.has("ai_rules_path") and not p.is_empty():
		p.ai = ProfileLoader.read_json(def.ai_rules_path).get("ai", {})   # M7 지휘관 AI 수치. 없으면 POC AI
	return p

static func build(def: Dictionary, scn: Dictionary, base: Dictionary, difficulty: String, combat := {}) -> Dictionary:
	var order: Array = scn.difficulty_order
	var rank := order.find(difficulty)
	if rank < 0:
		push_error("알 수 없는 난이도: %s" % difficulty)
		return {}
	var dprof: Dictionary = scn.difficulty_profiles[difficulty]

	var side_of := {}
	var player_flag := ""
	for f in scn.factions:
		side_of[f.id] = int(def.side_by_control[f.control])
	for sq in scn.squadrons:
		if sq.get("flagship", false) and scn.factions.any(func(f): return f.id == sq.faction_id and f.control == "player"):
			player_flag = sq.id

	var rules: Dictionary = base.rules.duplicate(true)
	for k in def.rule_overrides:
		rules[k] = def.rule_overrides[k]
	var b: Array = scn.battlefield_bounds
	rules.world_w = float(b[2]) - float(b[0])
	rules.world_h = float(b[3]) - float(b[1])

	var ally := []
	var foe := []
	var cao_n := 0
	var cao_last: Dictionary = {}
	for sq in scn.squadrons:
		var side: int = side_of[sq.faction_id]
		var is_cao: bool = sq.has("morale_group")
		if is_cao:
			# Q82: 조조 함대는 앞에서부터 cao_fleets개
			cao_n += 1
			if cao_n > int(dprof.cao_fleets):
				continue
		var ships := 0
		var comp := []
		for c in sq.composition:
			var n: int = int(c.count)
			ships += n
			var entry := {"ship_type_id": c.ship_type_id, "count": n}
			if c.has("mission_equipment_id"):
				entry.mission_equipment_id = c.mission_equipment_id
			comp.append(entry)
		var d := {
			"name": sq.commander.name, "role": sq.name, "ships": ships, "lv": 1,
			"x": sq.initial_position[0], "y": sq.initial_position[1],
			"flag": (sq.id == player_flag) if side == 0 else bool(sq.get("flagship", false)),
			"wait": sq.get("deploy_delay_s", 0), "p": 0,
			"squadron_id": sq.id, "faction_id": sq.faction_id, "commander_id": sq.commander.id,
			"formation_id": sq.formation_id, "composition": comp, "command": int(sq.commander.get("command", 0)),
			"traits": sq.commander.get("traits", []),
			"might": int(sq.commander.get("might", 0)), "intellect": int(sq.commander.get("intellect", 0)),
			"level": int(sq.commander.get("level", 1)) if sq.commander.get("level") != null else 1,
			"vice_commander": sq.get("vice_commander") if sq.get("vice_commander") != null else {},
			"staff": sq.get("staff", []),
		}
		if is_cao:
			d.morale_group = sq.morale_group
			d.start_morale_bp = int(dprof.start_morale_bp[sq.morale_group])
			cao_last = d
		else:
			d.start_morale_bp = 10000
		(ally if side == 0 else foe).append(d)
	if not cao_last.is_empty():
		cao_last.fill_bp = int(dprof.cao_last_fill_bp)   # 자동 편성(Organization.auto_fill)이 이 함대만 한도 × fill_bp까지 채운다

	return {
		"schema_version": 1,
		"profile_id": def.profile_id,
		"difficulty": difficulty,
		"rules": rules,
		"ally": ally, "foe": foe, "reinf": [],
		"combat": combat,
		"scenario": {
			"scenario_id": scn.scenario_id,
			"difficulty": difficulty,
			"difficulty_policy": scn.difficulty_policy,
			"difficulty_order": order,
			"difficulty_profile": dprof,
			"escape_points": scn.get("escape_points", {}),
			"battlefield_class": scn.get("battlefield_class", ""),
			"factions": scn.factions.map(func(f): return {"id": f.id, "control": f.control}),
			"realtime_rules": scn.realtime_rules,
			"chain_explosion_override": scn.get("chain_explosion_override", {}),
		},
	}

# 전장을 big 크기로 키운다. 시나리오의 절대 좌표를 전장 비율대로 늘려(전대 초기 위치, 지형 구역, 보급 거점, 탈출 지점) 원래 배치 모양을 지킨다:
# 아군은 서쪽 끝, 적은 동쪽 끝에서 시작하고 탈출 지점도 전장 가장자리에 남는다. 거리가 늘어난 만큼 접적까지 오래 걸린다.
# 호스트와 재생(replay)이 같은 프로필을 만들도록 여기 둔다.
# 플레이용 이동·선회 배율. 제자리 회전은 기본 선회율의 4배(배율 전 값)로 따로 둔다(영상에서 너무 빨랐다).
static func tune_for_play(profile: Dictionary, move_mul: float, turn_mul: float) -> void:
	for t in profile.combat.ship_types.values():
		t.speed_per_turn *= move_mul
	var mv: Dictionary = profile.combat.movement
	mv.face_turn_deg_per_s = mv.turn_deg_per_s * 4
	mv.turn_deg_per_s *= turn_mul

static func enlarge_field(profile: Dictionary, big: Vector2) -> void:
	var k := Vector2(big.x / float(profile.rules.world_w), big.y / float(profile.rules.world_h))
	profile.rules.world_w = big.x
	profile.rules.world_h = big.y
	for d in profile.ally + profile.foe:
		d.x *= k.x
		d.y *= k.y
	for z in profile.combat.get("terrain", {}).get("zones", []):
		z.rect = [z.rect[0] * k.x, z.rect[1] * k.y, z.rect[2] * k.x, z.rect[3] * k.y]
	for b in profile.combat.get("supply", {}).get("bases", []):
		b.position = [b.position[0] * k.x, b.position[1] * k.y]
	for e in profile.scenario.get("escape_points", {}).values():
		e.position = [e.position[0] * k.x, e.position[1] * k.y]
