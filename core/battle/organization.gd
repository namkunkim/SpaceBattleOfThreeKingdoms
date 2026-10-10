class_name Organization
extends RefCounted

# 전투 전 편성(BATTLE_DECISIONS §T Q73~Q81, docs/ui/FLEET-ORGANIZATION-SCREEN.md §3·§4·§6). 순수 변환이다.
#
# 편성(org): {"fleets": [{squadron_id, faction_id, on, admiral, vice, staff: [{post, id}], composition: [{ship_type_id, count, mission_equipment_id?}]}]}
#   장수는 ID만 둔다(능력치는 시나리오 factions[].available_officers). 참모 보직 post = assault(무력) | siege(지력) | supply(정치).
#   함대 목록 = 이 난이도에 배치된 전대(프로필 ally + foe). 배치되지 않은 조조 함대 추가는 O2(Q82).
# 흐름: ScenarioProfile.load_profile → default_org → (편성 화면·auto_fill) → validate → apply → BattleSim.new.
# apply는 편성 사본을 profile.organization에 남긴다(재생 헤더. 틱 명령이 아니다). 같은 편성·시드면 같은 결과.
# 지휘 한도는 상한이 아니라 불이익 기준(CommandCore.limit_tier)이고 제독 통솔(d.command)로 다시 계산된다.

const POSTS := {"assault": "might", "siege": "intellect", "supply": "politics"}
const POST_ORDER := ["assault", "siege", "supply"]
# Q79 기본 비율 전열4·포격2·요격2·보급1·강습모함1·전자전1(목업 autoFill 순환 순서). 남는 점수는 고속정
const MIX := ["SHP-04", "SHP-04", "SHP-03", "SHP-07", "SHP-04", "SHP-03", "SHP-07", "SHP-05", "SHP-01", "SHP-04", "SHP-06"]
const FILLER := "SHP-08"
const FILLER_EQUIP := "FAST-EQ-RECON"   # ponytail: 고속정 장비는 정찰 고정(목업). 장비 선택은 열린 항목(T-1)

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

# 지금 프로필의 편성(시나리오 정사 편성, 조조군은 count_factor 적용 뒤). apply(profile, default_org(profile))는 결과를 바꾸지 않는다.
static func default_org(profile: Dictionary) -> Dictionary:
	var fleets := []
	for d in profile.ally + profile.foe:
		var staff := []
		for p in d.staff:
			staff.append({"post": "", "id": str(p.id)})
		_default_posts(staff, d.staff)
		fleets.append({"squadron_id": d.squadron_id, "faction_id": d.faction_id, "on": true, "admiral": d.commander_id,
			"vice": str(d.vice_commander.get("id", "")), "staff": staff, "composition": d.composition.duplicate(true)})
	return {"fleets": fleets}

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
			if not ship_types.has(c.ship_type_id) or types.has(c.ship_type_id) or int(c.count) < 0 					or (c.has("mission_equipment_id") and not equips.has(c.mission_equipment_id)):
				bad.call(BAD_SHIP)
			types[c.ship_type_id] = true
			ships += maxi(0, int(c.count))
		if ships == 0:
			bad.call(NO_SHIPS)
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
	return true

# JSON으로 읽은 재생 헤더는 정수가 float로 온다. 소수부가 없으면 정수로 본다
static func _is_int(v: Variant) -> bool:
	return typeof(v) == TYPE_INT or (typeof(v) == TYPE_FLOAT and v == floorf(v))

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
static func auto_fill(org: Dictionary, faction_id: String, scn: Dictionary, profile: Dictionary) -> Dictionary:
	var res := org.duplicate(true)
	var flags := _flags(scn)
	var pool := _officers(scn, faction_id)
	var on: Array = res.fleets.filter(func(fl): return fl.faction_id == faction_id and fl.on)
	var used := {}
	for fl in on:
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
	var K: Dictionary = profile.combat.command
	var costs := {}
	for t in profile.combat.ship_types:
		costs[t] = int(profile.combat.ship_types[t].cost)
	for fl in on:
		if not pool.has(fl.admiral):
			continue   # 제독 없음·기함 제독이 가용 장수 밖: validate가 거부한다
		var cap := int(K.limit_base) + int(K.limit_per_command) * int(pool[fl.admiral].command)
		var n := {}
		var spent := 0
		var i := 0
		var miss := 0
		while miss < MIX.size():
			var t: String = MIX[i % MIX.size()]
			i += 1
			if spent + costs[t] <= cap:
				n[t] = n.get(t, 0) + 1
				spent += costs[t]
				miss = 0
			else:
				miss += 1
		var extra: int = (cap - spent) / costs[FILLER]
		if extra > 0:
			n[FILLER] = extra
		var keys := n.keys()
		keys.sort()
		for t in keys:
			var c := {"ship_type_id": t, "count": n[t]}
			if t == FILLER:
				c.mission_equipment_id = FILLER_EQUIP
			fl.composition.append(c)
	return res

# 함대 비용 합과 지휘 한도(편성 화면·테스트용)
static func cost_of(fl: Dictionary, profile: Dictionary) -> int:
	var s := 0
	for c in fl.composition:
		s += int(c.count) * int(profile.combat.ship_types[c.ship_type_id].cost)
	return s

static func limit_of(fl: Dictionary, scn: Dictionary, profile: Dictionary) -> int:
	var o: Dictionary = _officers(scn, fl.faction_id).get(fl.admiral, {})
	return 0 if o.is_empty() else int(profile.combat.command.limit_base) + int(profile.combat.command.limit_per_command) * int(o.command)

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
			d.ships = 0
			for c in d.composition:
				c.count = int(c.count)
				d.ships += c.count
			keep.append(d)
		p[side] = keep
	p.organization = org.duplicate(true)
	return p
