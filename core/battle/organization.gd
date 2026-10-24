class_name Organization
extends RefCounted

# 전투 전 편성(BATTLE_DECISIONS §T Q73~Q81, docs/ui/FLEET-ORGANIZATION-SCREEN.md §3·§4·§6). 순수 변환이다.
#
# 편성(org): {"fleets": [{squadron_id, faction_id, on, admiral, vice, staff: [{post, id}], composition: [{ship_type_id, count, mission_equipment_id?}], skill_slots?}]}
#   skill_slots(P8a, §U Q92): 기술 ID 배열(길이 = special_skills.slots, 빈칸 ""). 없으면 apply가 기본값(직책 순)을 넣는다.
#   장수는 ID만 둔다(능력치는 시나리오 factions[].available_officers). 참모 보직 post = assault(무력) | siege(지력) | supply(정치).
#   함대 목록 = 이 난이도에 배치된 함대(프로필 ally + foe). 조조 함대 수는 난이도별 cao_fleets(Q82, ScenarioProfile).
# 흐름: ScenarioProfile.load_profile → default_org → (편성 화면·auto_fill) → validate → apply → BattleSim.new.
#   기본 경로(편성 화면 없음, Q83)는 load_auto = load_profile → auto_all(세 세력 auto_fill → apply).
# apply는 편성 사본을 profile.organization에 남긴다(재생 헤더. 틱 명령이 아니다). 같은 편성·시드면 같은 결과.
# 지휘 한도는 상한이 아니라 불이익 기준(CommandCore.limit_tier)이고 제독 통솔(d.command)로 다시 계산된다.

const POSTS := {"assault": "might", "siege": "intellect", "supply": "politics"}
const POST_ORDER := ["assault", "siege", "supply"]
# Q79 기본 비율 전열4·포격2·요격2·보급1·강습모함1·전자전1(목업 autoFill 순환 순서). 남는 점수는 고속정
const MIX := ["SHP-04", "SHP-04", "SHP-03", "SHP-07", "SHP-04", "SHP-03", "SHP-07", "SHP-05", "SHP-01", "SHP-04", "SHP-06"]
const FILLER := "SHP-08"
const FILLER_EQUIP := "FAST-EQ-RECON"   # 고속정 장비: 함대의 기존 고속정 장비를 유지하고, 없으면 정찰(목업)

# 사유 코드
const DUP_OFFICER := "dup_officer"          # 한 장수가 두 칸 이상
const FOREIGN_OFFICER := "foreign_officer"  # 세력 가용 장수(available_officers) 밖
const FLAG_ADMIRAL := "flag_admiral"        # 기함 함대 제독을 바꿈
const FLAG_OFF := "flag_off"                # 기함 함대 출전 끔
const NO_FLEET := "no_fleet"                # 출전 함대 0개
const NO_ADMIRAL := "no_admiral"
const NO_SHIPS := "no_ships"
const BAD_STAFF := "bad_staff"              # 참모 4명 이상, 보직 중복·모름
const BAD_SHIP := "bad_ship"                # 모르는 함종, 음수 척 수
const UNKNOWN_FLEET := "unknown_fleet"      # 프로필에 없는 전대, 같은 전대 두 번
const MISSING_FLEET := "missing_fleet"      # 프로필에 있는데 편성에 없는 전대
const BAD_FLEET := "bad_fleet"              # 형식 오류(키 없음·타입 다름). 재생 헤더 같은 외부 입력 방어
const SKILL_DUPLICATE := "skill_duplicate"  # 한 함대 슬롯에 같은 기술 ID 두 번(Q92)
const SKILL_FOREIGN := "skill_foreign"      # 그 함대 장수(제독·부제독·참모)가 가진 기술이 아님
const SKILL_UNKNOWN := "skill_unknown"      # 모르는 기술 ID, 슬롯 수가 데이터와 다름

# 지금 프로필의 편성(시나리오 정사 편성, 조조군은 난이도의 함대 수만큼). apply(profile, default_org(profile))는 결과를 바꾸지 않는다.
static func default_org(profile: Dictionary) -> Dictionary:
	var fleets := []
	for d in profile.ally + profile.foe:
		var staff := []
		for p in d.staff:
			staff.append({"post": "", "id": str(p.id)})
		_default_posts(staff, d.staff)
		fleets.append({"squadron_id": d.squadron_id, "faction_id": d.faction_id, "on": true, "admiral": d.commander_id,
			"vice": str(d.vice_commander.get("id", "")), "staff": staff, "composition": d.composition.duplicate(true)})
		fleets[-1].skill_slots = default_slots(fleets[-1], profile)
	return {"fleets": fleets}

# ============================================================ 특기 슬롯(P8a, BATTLE_DECISIONS §U D4·Q92)
static func _skills(profile: Dictionary) -> Dictionary:
	return profile.get("scenario", {}).get("realtime_rules", {}).get("special_skills", {})

# 슬롯 기본값: 직책 순(slot_default = admiral, vice, staff_assault, 이어서 나머지 참모)으로 장수 기술을 넣고,
# 이미 넣은 기술 ID는 건너뛰어 다음 후보로 채운다. 모자라면 빈칸. 특기 데이터가 없으면 빈 배열
static func default_slots(fl: Dictionary, profile: Dictionary) -> Array:
	return refill_slots(fl, profile, [])

# 사용자가 고른 슬롯(keep)을 자리째 유지하고, 그 함대 장수에게 없는 기술·중복·빈칸만 기본값 후보 순으로 다시 채운다(P8b).
# keep이 비면 default_slots와 같다
static func refill_slots(fl: Dictionary, profile: Dictionary, keep: Array) -> Array:
	var sk := _skills(profile)
	if sk.is_empty():
		return []
	var own := fleet_skills(fl, profile)
	var out := []
	for i in int(sk.slots):
		var k := str(keep[i]) if i < keep.size() else ""
		out.append(k if k != "" and own.has(k) and not out.has(k) else "")
	var cands := []
	for key in sk.slot_default:
		if key == "admiral" or key == "vice":
			cands.append(fl[key])
		else:
			for s in fl.staff:
				if "staff_" + str(s.post) == key:
					cands.append(s.id)
	for s in fl.staff:
		cands.append(s.id)
	for id in cands:
		var k := str(sk.by_officer.get(id, {}).get("skill", ""))
		var at := out.find("")
		if k != "" and not out.has(k) and at >= 0:
			out[at] = k
	return out

# 함대 장수가 가진 기술 ID 집합
static func fleet_skills(fl: Dictionary, profile: Dictionary) -> Dictionary:
	var by: Dictionary = _skills(profile).get("by_officer", {})
	var out := {}
	for id in _people(fl):
		var k := str(by.get(id, {}).get("skill", ""))
		if k != "":
			out[k] = true
	return out

static func _slot_codes(fl: Dictionary, profile: Dictionary) -> Array:
	if not fl.has("skill_slots"):
		return []
	var sk := _skills(profile)
	var slots: Array = fl.skill_slots
	if sk.is_empty():
		return [] if slots.all(func(k): return k == "") else [SKILL_UNKNOWN]
	var known := {}
	for d in sk.skills:
		known[d.id] = true
	var own := fleet_skills(fl, profile)
	var out := []
	if slots.size() != int(sk.slots):
		out.append(SKILL_UNKNOWN)
	var seen := {}
	for k in slots:
		if k == "":
			continue
		if not known.has(k):
			out.append(SKILL_UNKNOWN)
		elif not own.has(k):
			out.append(SKILL_FOREIGN)
		if seen.has(k):
			out.append(SKILL_DUPLICATE)
		seen[k] = true
	return out

# 기존 데이터의 참모에는 보직이 없다: 순서대로 남은 보직 중 그 장수 능력치가 가장 높은 것(같으면 POST_ORDER 순).
# 적벽 데이터에서는 결과가 이미 강습 → 공성 → 보급 순이라 apply의 정렬이 승계 순서를 바꾸지 않는다(organization_rules 확인)
static func _default_posts(staff: Array, people: Array) -> void:
	var free := POST_ORDER.duplicate()
	for i in staff.size():
		var best := ""
		for post in free:
			if best == "" or int(people[i].get(POSTS[post], 0)) > int(people[i].get(POSTS[best], 0)):
				best = post
		staff[i].post = best
		free.erase(best)

# ============================================================ 검증
# [{squadron_id, faction_id, code}] — 빈 배열이면 확정 가능. 끈 함대는 보지 않는다(장수·함선은 대기 풀).
static func validate(org: Dictionary, scn: Dictionary, profile: Dictionary) -> Array:
	var out := []
	if typeof(org.get("fleets")) != TYPE_ARRAY:
		return [{"squadron_id": "", "faction_id": "", "code": BAD_FLEET}]
	var known := {}
	for d in profile.ally + profile.foe:
		known[d.squadron_id] = d.faction_id
	var flags := _flags(scn)
	var ship_types: Dictionary = profile.combat.ship_types
	var equips: Dictionary = profile.combat.get("detection", {}).get("equip_sensor", {})
	var used := {}
	var seen := {}
	var on_count := {}
	for f in scn.factions:
		if known.values().has(f.id):
			on_count[f.id] = 0
	for fl in org.fleets:
		if not _fleet_shape(fl):
			out.append({"squadron_id": "", "faction_id": "", "code": BAD_FLEET})
			continue
		var sq: String = fl.squadron_id
		var bad := func(code): out.append({"squadron_id": sq, "faction_id": fl.faction_id, "code": code})
		if not known.has(sq) or known[sq] != fl.faction_id or seen.has(sq):
			bad.call(UNKNOWN_FLEET)
			continue
		seen[sq] = true
		if not fl.on:
			if flags.has(sq):
				bad.call(FLAG_OFF)
			continue
		on_count[fl.faction_id] += 1
		var pool := _officers(scn, fl.faction_id)
		if fl.admiral == "":
			bad.call(NO_ADMIRAL)
		if flags.has(sq) and fl.admiral != flags[sq]:
			bad.call(FLAG_ADMIRAL)
		var posts := {}
		if fl.staff.size() > POST_ORDER.size():
			bad.call(BAD_STAFF)
		for s in fl.staff:
			if not POSTS.has(s.post) or posts.has(s.post) or s.id == "":
				bad.call(BAD_STAFF)
			posts[s.post] = true
		for id in _people(fl):
			if not pool.has(id):
				bad.call(FOREIGN_OFFICER)
			elif used.has(id):
				bad.call(DUP_OFFICER)
			used[id] = true
		var ships := 0
		var types := {}
		for c in fl.composition:
			if not ship_types.has(c.ship_type_id) or types.has(c.ship_type_id) or int(c.count) < 0 					or (c.has("mission_equipment_id") and c.mission_equipment_id != "" and not equips.has(c.mission_equipment_id)):
				bad.call(BAD_SHIP)
			types[c.ship_type_id] = true
			ships += maxi(0, int(c.count))
		if ships == 0:
			bad.call(NO_SHIPS)
		for code in _slot_codes(fl, profile):
			bad.call(code)
	for sq in known:
		if not seen.has(sq):
			out.append({"squadron_id": sq, "faction_id": known[sq], "code": MISSING_FLEET})
	for fid in on_count:
		if on_count[fid] == 0:
			out.append({"squadron_id": "", "faction_id": fid, "code": NO_FLEET})
	return out

static func _fleet_shape(fl: Variant) -> bool:
	if typeof(fl) != TYPE_DICTIONARY:
		return false
	for k in ["squadron_id", "faction_id", "admiral", "vice"]:
		if typeof(fl.get(k)) != TYPE_STRING:
			return false
	if typeof(fl.get("on")) != TYPE_BOOL or typeof(fl.get("staff")) != TYPE_ARRAY or typeof(fl.get("composition")) != TYPE_ARRAY:
		return false
	for s in fl.staff:
		if typeof(s) != TYPE_DICTIONARY or typeof(s.get("post")) != TYPE_STRING or typeof(s.get("id")) != TYPE_STRING:
			return false
	for c in fl.composition:
		if typeof(c) != TYPE_DICTIONARY or typeof(c.get("ship_type_id")) != TYPE_STRING or not _is_int(c.get("count")):
			return false
		if c.has("mission_equipment_id") and typeof(c.mission_equipment_id) != TYPE_STRING:
			return false
	if fl.has("skill_slots") and (typeof(fl.skill_slots) != TYPE_ARRAY or not fl.skill_slots.all(func(k): return typeof(k) == TYPE_STRING)):
		return false
	return true

# JSON으로 읽은 재생 헤더는 정수가 float로 온다. 소수부가 없으면 정수로 본다
static func _is_int(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and v == floorf(v))

# 함대 장수 ID(제독·부제독·참모 순, 빈칸 제외)
static func people(fl: Dictionary) -> Array:
	return _people(fl)

static func _people(fl: Dictionary) -> Array:
	var ids := [fl.admiral, fl.vice]
	for s in fl.staff:
		ids.append(s.id)
	return ids.filter(func(id): return id != "")

# 기함 전대 → 고정 제독 ID(시나리오 정사 편성)
static func _flags(scn: Dictionary) -> Dictionary:
	var out := {}
	for sq in scn.squadrons:
		if sq.get("flagship", false):
			out[sq.id] = str(sq.commander.id)
	return out

static func _officers(scn: Dictionary, faction_id: String) -> Dictionary:
	var out := {}
	for f in scn.factions:
		if f.id == faction_id:
			for o in f.get("available_officers", []):
				out[str(o.id)] = o
	return out

# ============================================================ 자동 편성(Q79·Q80·Q81)
# faction_id의 출전 함대를 꽉 채운 사본. 다른 세력·끈 함대는 그대로. 손권·조조 AI도 같은 함수(Q81).
# 장수: 제독(기함은 고정) → 부제독 → 함대마다 참모 강습·공성·보급, 각각 남은 장수 중 통솔·통솔·무력·지력·정치 최고(같으면 ID 순).
# 함선: 지휘 한도 (limit_base + limit_per_command × 제독 통솔)까지 MIX 순환 탐욕, 남는 점수는 고속정.
#   fill_bp로 정한 총예산은 유지하고, 시나리오 정책이 있으면 후군에 비례 분산한다.
#   시나리오 편성의 RECON 정찰 고속정(P10b·R5)은 먼저 예약하고 나머지를 채운다(한도를 넘지 않는 만큼).
# only(전대 ID 배열)가 있으면 그 함대만 채우고, 나머지 출전 함대의 장수는 쓰지 않는다(repair).
static func auto_fill(org: Dictionary, faction_id: String, scn: Dictionary, profile: Dictionary, only := []) -> Dictionary:
	var res := org.duplicate(true)
	var flags := _flags(scn)
	var pool := _officers(scn, faction_id)
	var on: Array = res.fleets.filter(func(fl): return fl.faction_id == faction_id and fl.on and (only.is_empty() or only.has(fl.squadron_id)))
	var used := {}
	if not only.is_empty():
		for fl in res.fleets:
			if fl.faction_id == faction_id and fl.on and not only.has(fl.squadron_id):
				for id in _people(fl):
					used[id] = true
	var equip := {}
	var scouts := {}   # 전대 ID → 시나리오 편성의 RECON 정찰 고속정 수(예약)
	for sq in scn.squadrons:
		for c in sq.composition:
			if c.ship_type_id == FILLER and c.get("mission_equipment_id", "") == "FAST-EQ-RECON":
				scouts[sq.id] = scouts.get(sq.id, 0) + int(c.count)
	for fl in on:
		for c in fl.composition:
			if c.ship_type_id == FILLER and c.has("mission_equipment_id"):
				equip[fl.squadron_id] = c.mission_equipment_id
		fl.admiral = flags.get(fl.squadron_id, "")
		fl.vice = ""
		fl.staff = []
		fl.composition = []
		used[fl.admiral] = true
	var pick := func(stat: String) -> String:
		var best := ""
		for id in pool:
			if used.has(id):
				continue
			if best == "" or int(pool[id][stat]) > int(pool[best][stat]) or (int(pool[id][stat]) == int(pool[best][stat]) and id < best):
				best = id
		if best != "":
			used[best] = true
		return best
	for fl in on:
		if fl.admiral == "":
			fl.admiral = pick.call("command")
	for fl in on:
		fl.vice = pick.call("command")
	for fl in on:
		for post in POST_ORDER:
			var id: String = pick.call(POSTS[post])
			if id != "":
				fl.staff.append({"post": post, "id": id})
	for fl in on:
		fl.skill_slots = default_slots(fl, profile)
	var costs := {}
	for t in profile.combat.ship_types:
		costs[t] = int(profile.combat.ship_types[t].cost)
	var caps := auto_caps(res, faction_id, scn, profile)
	for fl in on:
		if not pool.has(fl.admiral):
			continue   # 제독 없음·기함 제독이 가용 장수 밖: validate가 거부한다
		var cap: int = caps[fl.squadron_id]
		var mix := auto_mix(fl.squadron_id, scn)
		var n := {}
		var spent := 0
		var keep: int = mini(scouts.get(fl.squadron_id, 0), cap / costs[FILLER])
		if keep > 0:
			n[FILLER] = keep
			spent = keep * costs[FILLER]
		var i := 0
		var miss := 0
		while miss < mix.size():
			var t: String = mix[i % mix.size()]
			i += 1
			if spent + costs[t] <= cap:
				n[t] = n.get(t, 0) + 1
				spent += costs[t]
				miss = 0
			else:
				miss += 1
		var extra: int = (cap - spent) / costs[FILLER]
		if extra > 0:
			n[FILLER] = n.get(FILLER, 0) + extra
		var keys := n.keys()
		keys.sort()
		for t in keys:
			var c := {"ship_type_id": t, "count": n[t]}
			if t == FILLER:
				c.mission_equipment_id = equip.get(fl.squadron_id, FILLER_EQUIP)
			fl.composition.append(c)
	return res

# 함종 역할과 예산 분산은 적벽 시나리오의 명시적 정책이다. 다른 세력·시나리오는 기존 MIX를 쓴다.
static func auto_mix(squadron_id: String, scn: Dictionary) -> Array:
	var policy: Dictionary = scn.get("realtime_rules", {}).get("auto_organization", {})
	var role: String = str(policy.get("role_by_squadron", {}).get(squadron_id, ""))
	var mix: Array = policy.get("role_mixes", {}).get(role, [])
	return MIX if mix.is_empty() else mix

# 편성된 제독의 실제 지휘 한도를 기준으로 원래 fill_bp 예산 합을 보존한다.
# 누적 정수 배분으로 반올림 잔여도 후군에 포함한다. 출전하지 않는 함대는 예산을 받지 않는다.
static func auto_caps(org: Dictionary, faction_id: String, scn: Dictionary, profile: Dictionary) -> Dictionary:
	var fills := {}
	for d in profile.ally + profile.foe:
		fills[d.squadron_id] = int(d.get("fill_bp", BattleRules.BP))
	var policy: Dictionary = scn.get("realtime_rules", {}).get("auto_organization", {})
	var rear_ids: Array = policy.get("rear_squadron_ids", [])
	var caps := {}
	var rear := []
	var rear_budget := 0
	var rear_limit := 0
	for fl in org.fleets:
		if fl.faction_id != faction_id or not fl.on:
			continue
		var lim := limit_of(fl, scn, profile)
		var cap: int = lim * int(fills.get(fl.squadron_id, BattleRules.BP)) / BattleRules.BP
		caps[fl.squadron_id] = cap
		if rear_ids.has(fl.squadron_id):
			rear.append({"id": fl.squadron_id, "limit": lim})
			rear_budget += cap
			rear_limit += lim
	if rear_limit > 0:
		var cumulative := 0
		var assigned := 0
		for fl in rear:
			cumulative += int(fl.limit)
			var next: int = rear_budget * cumulative / rear_limit
			caps[fl.id] = next - assigned
			assigned = next
	return caps

# 함대 비용 합과 지휘 한도(편성 화면·테스트용)
static func cost_of(fl: Dictionary, profile: Dictionary) -> int:
	var s := 0
	for c in fl.composition:
		s += int(c.count) * int(profile.combat.ship_types[c.ship_type_id].cost)
	return s

static func limit_of(fl: Dictionary, scn: Dictionary, profile: Dictionary) -> int:
	var o: Dictionary = _officers(scn, fl.faction_id).get(fl.admiral, {})
	return 0 if o.is_empty() else int(profile.combat.command.limit_base) + int(profile.combat.command.limit_per_command) * int(o.command)

# 지휘 한도 초과 단계(CommandCore.limit_tier와 같은 식, 전투 전 편성 기준). 0 = 초과 없음 또는 제독 없음
static func tier_of(fl: Dictionary, scn: Dictionary, profile: Dictionary) -> int:
	var lim := limit_of(fl, scn, profile)
	var cost := cost_of(fl, profile)
	var K: Dictionary = profile.combat.command
	if lim <= 0 or cost <= lim:
		return 0
	return mini(int(K.max_tier), ceili(float(cost - lim) / (float(lim) * float(K.over_tier_ratio))))

# ============================================================ 세 세력 자동 편성(Q81·Q83)
# 기본 경로(편성 화면 없음)와 편성 화면의 "자동 편성으로 시작"이 같이 쓴다. 성공하면 프로필 사본, 실패하면 {"errors": [...]}.
static func auto_all(profile: Dictionary, scn: Dictionary) -> Dictionary:
	var org := default_org(profile)
	for f in scn.factions:
		org = auto_fill(org, f.id, scn, profile)
	return apply(profile, org, scn)

# 거부된 편성 고치기(REVIEW-O4b F-3, 사용자 결정 2026-10-11): 지금 프로필(난이도)의 함대 목록으로 맞추고,
# 플레이어 세력은 사유가 없는 함대(직책·함선·출전 여부)를 그대로 두고 빠지거나 사유가 난 함대만 자동 편성으로 채운다.
# AI 세력(손권·조조)은 Q81대로 언제나 전부 자동 편성. 고쳐도 검증을 못 넘으면(세력 단위 사유 등) 플레이어도 전부 자동 편성.
# {"org": 고친 편성, "changed": 다시 채운 함대 ID(모든 세력, 원래 없던 함대 포함)}
static func repair(org: Dictionary, profile: Dictionary, scn: Dictionary) -> Dictionary:
	var bad := {}
	for e in validate(org, scn, profile):
		bad[e.squadron_id] = true
	var old := {}
	if typeof(org.get("fleets")) == TYPE_ARRAY:
		for fl in org.fleets:
			if _fleet_shape(fl) and not old.has(fl.squadron_id):
				old[fl.squadron_id] = fl
	var player := {}
	for f in scn.factions:
		if f.control == "player":
			player[f.id] = true
	var res := default_org(profile)
	var changed := []
	for i in res.fleets.size():
		var sq: String = res.fleets[i].squadron_id
		if old.has(sq) and old[sq].faction_id == res.fleets[i].faction_id and not bad.has(sq):
			if player.has(res.fleets[i].faction_id):
				res.fleets[i] = old[sq].duplicate(true)
		else:
			changed.append(sq)
	var fixed := res
	for f in scn.factions:
		var only: Array = changed.filter(func(sq): return res.fleets.any(func(fl): return fl.squadron_id == sq and fl.faction_id == f.id))
		if not player.has(f.id):
			fixed = auto_fill(fixed, f.id, scn, profile)
		elif not only.is_empty():
			fixed = auto_fill(fixed, f.id, scn, profile, only)
	if not validate(fixed, scn, profile).is_empty():
		fixed = default_org(profile)
		changed = []
		for fl in fixed.fleets:
			changed.append(fl.squadron_id)
		for f in scn.factions:
			fixed = auto_fill(fixed, f.id, scn, profile)
	return {"org": fixed, "changed": changed}

# 프로필 정의 경로에서 읽어 세 세력 자동 편성까지. 읽기 실패는 빈 사전
static func load_auto(def_path: String, difficulty := "", dprof_override := {}) -> Dictionary:
	var p := ScenarioProfile.load_profile(def_path, difficulty, dprof_override)
	if p.is_empty():
		return p
	var res := auto_all(p, ProfileLoader.read_json(ProfileLoader.read_json(def_path).scenario_path))
	if res.has("errors"):
		push_error("자동 편성 실패: %s" % [res.errors])
		return {}
	return res

# ============================================================ 프로필 덮어쓰기
# 끈 함대는 빠지고, 출전 함대의 직책·composition이 바뀐 프로필 사본.
# validate를 먼저 돌려 사유가 있으면 적용하지 않고 {"errors": [...]}를 돌려준다(편성 화면·재생 헤더 입력 방어).
# 참모 배열 순서 = 승계 순서(CommandCore._substitute의 staff[0]) = 보직 순서 강습 → 공성 → 보급.
static func apply(profile: Dictionary, org: Dictionary, scn: Dictionary) -> Dictionary:
	var errs := validate(org, scn, profile)
	if not errs.is_empty():
		return {"errors": errs}
	var p := profile.duplicate(true)
	var by_sq := {}
	for fl in org.fleets:
		by_sq[fl.squadron_id] = fl
	for side in ["ally", "foe"]:
		var keep := []
		for d in p[side]:
			var fl: Dictionary = by_sq.get(d.squadron_id, {})
			if fl.is_empty():
				keep.append(d)
				continue
			if not fl.on:
				continue
			var pool := _officers(scn, fl.faction_id)
			var a: Dictionary = pool[fl.admiral]
			if fl.admiral != d.commander_id:
				d.level = 1
			d.name = a.name
			d.commander_id = fl.admiral
			d.command = int(a.get("command", 0))
			d.might = int(a.get("might", 0))
			d.intellect = int(a.get("intellect", 0))
			d.traits = a.get("traits", []).duplicate()
			d.vice_commander = pool[fl.vice].duplicate(true) if fl.vice != "" else {}
			d.staff = []
			var staff: Array = fl.staff.duplicate()
			staff.sort_custom(func(x, y): return POST_ORDER.find(x.post) < POST_ORDER.find(y.post))
			for s in staff:
				var o: Dictionary = pool[s.id].duplicate(true)
				o.post = s.post
				d.staff.append(o)
			d.composition = fl.composition.duplicate(true)
			d.skill_slots = (fl.skill_slots if fl.has("skill_slots") else default_slots(fl, profile)).duplicate()
			d.ships = 0
			for c in d.composition:
				c.count = int(c.count)
				d.ships += c.count
			keep.append(d)
		p[side] = keep
	p.organization = org.duplicate(true)
	return p
