class_name SkillCore
extends RefCounted

# P8a 장수 특기(BATTLE_DECISIONS §U Q88~Q95, docs/battle-core/SPECIAL-SKILLS.md). 수치·조건은 모두 시나리오
# realtime_rules.special_skills에서 온다. 시나리오 프로필에 special_skills가 있을 때만 켜진다.
#
# 슬롯: FleetState.skill_slots(편성 apply가 넣는다, 전투 중 바뀌지 않는다). 사용 = (함대, 기술 ID) 쌍당 uses_per_battle회(Q92).
# 발동: 명령 "skill"(args.slot 또는 args.skill_id, target_id) → use(). 거부 사유 skill_no_slot · skill_used · commander_down ·
#   skill_requires_<키> · skill_no_target(그 밖에 고육계는 화공 서신 사유를 그대로).
# 효과: 즉시 키(morale_bp·charges_add·assault_cd_reset·alias_command)는 발동 때 한 번, 나머지는 대상 함대 fx에
#   until 틱까지 둔다(대상 side = 진영 전체는 side_fx). 계산 쪽(salvo·morale·탐지·이동·강습·화공)이 mul()/add()/flag()로 읽는다.
# 겹침(Q95, 데이터 stacking): 받는 피해 감소는 가장 낮은 값 하나, 증가는 가장 큰 값 하나, 둘을 곱한다.
#   speed 가장 큰 값, transition 가장 낮은 값, 그 밖은 곱.
# AI(Q91): 지휘관 AI 생각 틱마다 함대 ID 순 → 슬롯 순으로 ai_when + requires를 보고 함대당 하나만 발동한다(ai_eval). 난수 없음.
#   적 조건은 진영 접촉표의 확인 접촉으로만 판정한다(estimated_within만 추정 포함). 적 기함·강습모함 여부는
#   공개 투영의 확인 접촉 키(flagship·carrier, Q96)만 읽는다.
# 정보 경계: 발동·해제 사건은 시전 진영에만 간다(sq = 시전 함대). 적이 건 효과는 받은 함대의 투영에 기술 ID·이름만(Q97).

const BAND_RANK := {"contact": 0, "barrage": 1, "engagement": 2, "assault": 3}

var sim: BattleSim
var K: Dictionary
var defs := {}                  # 기술 ID → 정의
var side_fx: Array = [[], []]   # 진영 전체 효과(미주랑)
var used_n := 0                 # 전투 전체 발동 수(지문·통계)
var stats := {}                 # 기술 ID → 발동 수
var _views: Array = [{}, {}]    # ai_eval 중 진영별 공개 투영(Q96 술어 입력)

func _view(side: int) -> Dictionary:
	if _views[side].is_empty():
		_views[side] = sim.projection(side)
	return _views[side]

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	K = cfg
	for d in K.skills:
		defs[d.id] = d

# ============================================================ 효과 읽기(계산 쪽이 부른다)
func _fx_of(f: FleetState) -> Array:
	return f.fx + side_fx[f.side] if not side_fx[f.side].is_empty() else f.fx

# 효과 값. only_while holding이면 멈춰 있을 때만, in_terrain이 있으면 지형 구역 안에서는 그 값
func _val(f: FleetState, e: Dictionary, key: String, cat: String) -> Variant:
	if e.get("only_while", "") == "holding" and not holding(f):
		return null
	if cat != "" and e.has("categories") and not (e.categories as Array).has(cat):
		return null
	if e.has("in_terrain") and (e.in_terrain as Dictionary).has(key) and _in_terrain(f):
		return e.in_terrain[key]
	return e.get(key)

# 배율 키(bp) 합성. 효과가 없으면 BP
func mul(f: FleetState, key: String, cat := "") -> int:
	if f.fx.is_empty() and side_fx[f.side].is_empty():
		return BattleRules.BP
	var lo: Array = []
	var hi: Array = []
	for x in _fx_of(f):
		var v: Variant = _val(f, x.e, key, cat)
		if v == null:
			continue
		if int(v) < BattleRules.BP:
			lo.append(int(v))
		else:
			hi.append(int(v))
	var S: Dictionary = K.stacking
	match key:
		"damage_taken_mul_bp":
			return _combine(lo, str(S.damage_taken_reduction)) * _combine(hi, str(S.damage_taken_increase)) / BattleRules.BP
		"speed_mul_bp":
			return _combine(lo + hi, str(S.speed_mul))
		"transition_mul_bp":
			return _combine(lo + hi, str(S.transition_mul))
	return _combine(lo + hi, str(S.other))

static func _combine(vs: Array, rule: String) -> int:
	if vs.is_empty():
		return BattleRules.BP
	match rule:
		"min_only":
			return vs.min()
		"max_only":
			return vs.max()
	var m := BattleRules.BP
	for v in vs:
		m = m * int(v) / BattleRules.BP
	return m

func mulf(f: FleetState, key: String, cat := "") -> float:
	return float(mul(f, key, cat)) / float(BattleRules.BP)

# 가산 키 합(hit_bp)
func add(f: FleetState, key: String) -> int:
	var n := 0
	for x in _fx_of(f):
		var v: Variant = _val(f, x.e, key, "")
		if v != null:
			n += int(v)
	return n

# 참·거짓 키(assault_block · affinity_ignore · rescue_equipped)
func flag(f: FleetState, key: String) -> bool:
	for x in _fx_of(f):
		var v: Variant = _val(f, x.e, key, "")
		if v != null and bool(v):
			return true
	return false

# 악래: 기함 t가 받는 피해를 대신 받는 함대(반경 안, 함대 ID 순 첫째). 없으면 null
func guard_of(t: FleetState) -> FleetState:
	if not t.is_flag:
		return null
	for o in sim.st.fleets:
		if o == t or o.side != t.side or o.out != "":
			continue
		for x in o.fx:
			if x.e.has("damage_redirect_bp") and o.pos.distance_to(t.pos) <= float(x.r) + 0.001:
				return o
	return null

func redirect_bp(g: FleetState) -> int:
	for x in g.fx:
		if x.e.has("damage_redirect_bp"):
			return int(x.e.damage_redirect_bp)
	return 0

# 귀모·간파: side 진영의 함대 중 reveal_radius 안에 t가 있다(탐지가 확인 접촉으로 올린다). orders면 reveal_orders 효과만
func reveals(side: int, t: FleetState, orders := false) -> bool:
	for o in sim.st.fleets:
		if o.side != side or o.out != "":
			continue
		for x in o.fx:
			if x.e.has("reveal_radius") and (not orders or bool(x.e.get("reveal_orders", false))) and o.pos.distance_to(t.pos) <= float(x.e.reveal_radius) + 0.001:
				return true
	return false

# ============================================================ 상태 판정
# definitions.holding: 이동 명령·경유점이 없고 후퇴·돌격 접근 중이 아님(진형 전환 중은 holding)
func holding(f: FleetState) -> bool:
	return not f.has_move and f.route.is_empty() and f.charge <= 0 and not (sim.morale and sim.morale.fleeing(f))

func _in_terrain(f: FleetState) -> bool:
	if sim.terrain == null:
		return false
	for z in sim.terrain.zones:
		if str(z.get("type", "")) != "chain_hazard" and BattleTerrain._has(z, f.pos):
			return true
	return false

# 남은 척 수 비율(bp)
func hull_bp(f: FleetState) -> int:
	return sim.salvo.present_ships(f) * BattleRules.BP / maxi(1, sim.salvo.total0(f))

# 진영이 확인한 살아 있는 적(함대 ID 순). 안개가 없으면 모두
func _confirmed(f: FleetState) -> Array[FleetState]:
	var out: Array[FleetState] = []
	for o in sim.st.fleets:
		if o.side != f.side and not o.dead and (sim.detect == null or sim.detect.state(f.side, o.id) == "confirmed"):
			out.append(o)
	return out

func _nearest(f: FleetState, list: Array[FleetState]) -> FleetState:
	var best: FleetState = null
	for o in list:
		if best == null or f.pos.distance_to(o.pos) < f.pos.distance_to(best.pos):
			best = o
	return best

func _within(f: FleetState, list: Array[FleetState], r: float) -> Array[FleetState]:
	var out: Array[FleetState] = []
	for o in list:
		if f.pos.distance_to(o.pos) <= r + 0.001:
			out.append(o)
	return out

func _allies(f: FleetState, r: float, include_self: bool) -> Array[FleetState]:
	var out: Array[FleetState] = []
	for o in sim.st.fleets:
		if o.side == f.side and o.out == "" and (o != f or include_self) and f.pos.distance_to(o.pos) <= r + 0.001:
			out.append(o)
	return out

func _ally_flag(f: FleetState) -> FleetState:
	var fl := sim.st.flag(f.side)
	return fl if fl != f else null

# 기본(효과 없는) 사거리
func _base_range(f: FleetState, cat: String) -> float:
	return sim.salvo._max_range(f, cat, 0.0) / sim.salvo.range_mul(f, cat)

func _req(f: FleetState, k: String, v: Variant) -> bool:
	match k:
		"has_ship_type":
			return f.stages.has(str(v)) and sim.salvo.present_of(f, str(v)) > 0
		"enemy_within":
			return not _within(f, _confirmed(f), float(v)).is_empty()
		"ally_within":
			return not _allies(f, float(v), false).is_empty()
		"ally_flagship_within":
			var fl := _ally_flag(f)
			return fl != null and f.pos.distance_to(fl.pos) <= float(v) + 0.001
		"self_not_flagship":
			return not f.is_flag
		"charges_below_base":
			return int(f.wmax.get(str(v), 0)) > 0 and int(f.wch.get(str(v), 0)) < int(f.wmax[str(v)])
		"chain_host":
			return sim.chain != null and f.sq_id == sim.chain.host_sq
	return false

# ai_when 술어(SPECIAL-SKILLS §4)
func _pred(f: FleetState, k: String, v: Variant) -> bool:
	match k:
		"enemy_in_band":
			var n := _nearest(f, _confirmed(f))
			return n != null and int(BAND_RANK[sim.salvo.band(f, f.pos.distance_to(n.pos))]) >= int(BAND_RANK[str(v)])
		"enemy_within":
			return _req(f, k, v)
		"enemy_beyond_base_range_within_mul":
			var n := _nearest(f, _confirmed(f))
			var r := _base_range(f, str(v[0]))
			var d := f.pos.distance_to(n.pos) if n else 0.0
			return n != null and r > 0.0 and d > r and d <= r * float(v[1]) / float(BattleRules.BP)
		"estimated_within":
			if sim.detect == null:
				return _req(f, "enemy_within", v)
			for id in sim.detect.contacts[f.side]:
				var c: Dictionary = sim.detect.contacts[f.side][id]
				if c.state in ["confirmed", "estimated"] and f.pos.distance_to(c.pos) <= float(v) + 0.001:
					return true
			return false
		"enemy_flagship_within", "enemy_carrier_within":
			# Q96: 공개 투영의 확인 접촉에 있는 기함·강습모함 여부만 읽는다(사람도 같은 정보를 본다)
			var key := "flagship" if k == "enemy_flagship_within" else "carrier"
			for q in _view(f.side).squadrons:
				if q.side != f.side and not q.get("dead", false) and q.get("contact", "confirmed") == "confirmed" and bool(q.get(key, false)) 						and f.pos.distance_to(q.pos) <= float(v) + 0.001:
					return true
			return false
		"self_hull_below_bp":
			return hull_bp(f) < int(v)
		"self_morale_below_bp":
			return f.morale_bp < int(v)
		"self_retreating":
			return sim.morale != null and sim.morale.fleeing(f) == bool(v)
		"self_charges_zero":
			return int(f.wmax.get(str(v), 0)) > 0 and int(f.wch.get(str(v), 0)) == 0
		"ally_hull_below_bp_within":
			return _allies(f, float(v[1]), true).any(func(o): return hull_bp(o) < int(v[0]))
		"ally_flagship_within":
			return _req(f, k, v)
		"ally_flagship_hull_below_bp":
			var fl := _ally_flag(f)
			return fl != null and hull_bp(fl) < int(v)
		"wind_window_open":
			return sim.chain != null and sim.chain.window_open() == bool(v)
	return false   # chain_host_ai는 화공 AI(ChainOp.host_think)가 직접 판단한다

func _when(f: FleetState, w: Dictionary) -> bool:
	if w.has("all"):
		return (w.all as Array).all(func(p): return _pred(f, p.keys()[0], p.values()[0]))
	if w.has("any"):
		return (w.any as Array).any(func(p): return _pred(f, p.keys()[0], p.values()[0]))
	return false

# ============================================================ 발동
func uses_left(f: FleetState, id: String) -> int:
	return maxi(0, int(K.uses_per_battle) - int(f.skill_used.get(id, 0)))

func block(f: FleetState, id: String) -> String:
	if id == "" or not f.skill_slots.has(id) or not defs.has(id):
		return "skill_no_slot"
	if uses_left(f, id) <= 0:
		return "skill_used"
	if sim.cmd and sim.cmd.incapacitated(f) and f.cmdr_sub == "":
		return "commander_down"
	var req: Dictionary = defs[id].get("requires", {})
	for k in req:
		if not _req(f, k, req[k]):
			return "skill_requires_" + k
	return ""

# 대상 함대. target_id < 0이면 target_pick(결정론, 동률 ID 순). 빈 배열 = 대상 없음
func targets(f: FleetState, d: Dictionary, target_id := -1) -> Array[FleetState]:
	var r := float(d.get("radius", 0))
	var cands: Array[FleetState] = []
	match str(d.target):
		"self", "side":
			cands.append(f)
			return cands
		"allies_in_radius":
			return _allies(f, r, bool(d.get("include_self", true)))
		"ally_fleet":
			cands = _allies(f, r, bool(d.get("target_pick", {}).get("include_self", true)))
		"enemy_fleet":
			cands = _within(f, _confirmed(f), r)
	var out: Array[FleetState] = []
	var best: FleetState = null
	for o in cands:
		if target_id >= 0:
			if o.id == target_id:
				best = o
		elif best == null or _score(f, o, d) < _score(f, best, d) or (_score(f, o, d) == _score(f, best, d) and o.id < best.id):
			best = o   # 동률은 함대 ID 오름차순(target_pick.tie)
	if best:
		out.append(best)
	return out

func _score(f: FleetState, o: FleetState, d: Dictionary) -> float:
	return float(hull_bp(o)) if str(d.get("target_pick", {}).get("by", "")) == "lowest_hull_ratio" else f.pos.distance_to(o.pos)

# 명령 처리. 사유 코드 또는 ""
func use(f: FleetState, id: String, target_id := -1) -> String:
	var why := block(f, id)
	if why != "":
		return why
	var d: Dictionary = defs[id]
	var tg := targets(f, d, target_id)
	if tg.is_empty():
		return "skill_no_target"
	var e: Dictionary = d.effects
	if e.has("alias_command"):
		why = sim.chain.letter(f)   # 고육계: 기존 서신(letter_uses 공유). 새 효과 없음
		if why != "":
			return why
	f.skill_used[id] = int(f.skill_used.get(id, 0)) + 1
	used_n += 1
	stats[id] = int(stats.get(id, 0)) + 1
	var st := sim.st
	var dur := BattleRules.ticks(float(d.duration_s), st.hz)
	var ids := []
	for t in tg:
		ids.append(t.id)
		if e.has("morale_bp"):
			var v := int(e.morale_bp)
			if v >= 0:
				t.morale_bp = mini(BattleRules.BP, t.morale_bp + v)
			elif sim.morale:
				sim.morale.lose(t, -v)
		if e.has("charges_add"):
			for cat in e.charges_add:
				if t.wch.has(cat):
					t.wch[cat] = mini(int(t.wmax[cat]), int(t.wch[cat]) + int(e.charges_add[cat]))
		if e.has("assault_cd_reset"):
			t.assault_cd = st.tick
		if dur > 0:
			var x := {"id": id, "src": f.id, "until": st.tick + dur, "e": e, "r": float(d.get("radius", 0))}
			if str(d.target) == "side":
				side_fx[f.side].append(x)
			else:
				t.fx.append(x)
			_changed(t, e)
	sim.emit("skill", f.id, tg[0].id if tg[0] != f else -1, f.pos, {"id": id, "targets": ids})
	return ""

# 사거리·진형 전환이 바뀌는 효과는 걸릴 때·풀릴 때 상태를 다시 맞춘다
func _changed(t: FleetState, e: Dictionary) -> void:
	if e.has("range_mul_bp"):
		sim.salvo.refresh_range(t)
	if e.has("transition_mul_bp") and t.form_left > 0 and mul(t, "transition_mul_bp") <= 0:
		sim.salvo.force_formation(t, t.form_to)   # 신기묘산: 진행 중인 전환을 바로 끝낸다

# AI·위임 발동(Q91): 슬롯 순으로 처음 조건이 맞는 기술 하나
# view: 지휘관 AI가 이번 생각에 읽은 공개 투영(없으면 새로 만든다)
func ai_eval(f: FleetState, view := {}) -> void:
	if f.skill_slots.is_empty() or (sim.morale and sim.morale.forced(f)):
		return
	_views[f.side] = view
	var pick := -1
	for i in f.skill_slots.size():
		var id: String = f.skill_slots[i]
		if block(f, id) == "" and _when(f, defs[id].get("ai_when", {})) and not targets(f, defs[id]).is_empty():
			pick = i
			break
	_views[f.side] = {}
	if pick >= 0:
		sim.apply(BattleSim.command(f.side, [f.id], "skill", -1, Vector2.ZERO, {"slot": pick}))

# 고육계 슬롯이 남아 있으면 그 슬롯(화공 AI가 서신을 이 경로로 보낸다). 없으면 -1
func alias_slot(f: FleetState, cmd: String) -> int:
	for i in f.skill_slots.size():
		var id: String = f.skill_slots[i]
		if defs.has(id) and str(defs[id].effects.get("alias_command", "")) == cmd and block(f, id) == "":
			return i
	return -1

# ============================================================ 틱: 만료
func step() -> void:
	var now := sim.st.tick
	for f in sim.st.fleets:
		if f.fx.is_empty():
			continue
		var gone: Array = f.fx.filter(func(x): return now >= int(x.until))
		if gone.is_empty():
			continue
		f.fx = f.fx.filter(func(x): return now < int(x.until))
		for x in gone:
			_changed(f, x.e)
			sim.emit("skill_end", int(x.src), f.id, f.pos, x.id)   # sq = 시전 함대(시전 진영에만 간다), other = 효과를 가졌던 함대
	for side in 2:
		side_fx[side] = side_fx[side].filter(func(x): return now < int(x.until))

# ============================================================ 투영·지문
# 아군 전용: 슬롯·남은 횟수·걸린 효과 남은 초(진영 효과 포함)
func view(f: FleetState) -> Dictionary:
	var hz := float(sim.st.hz)
	var slots := []
	for id in f.skill_slots:
		var d: Dictionary = defs.get(id, {})
		slots.append({"id": id, "name": str(d.get("name", "")), "target": str(d.get("target", "")),
			"uses_left": uses_left(f, id) if id != "" else 0, "block": block(f, id) if id != "" else "skill_no_slot"})
	var fx := []
	for x in _fx_of(f):
		var e := {"id": x.id, "name": str(defs.get(x.id, {}).get("name", "")), "left_s": maxf(0.0, float(int(x.until) - sim.st.tick) / hz)}
		var src := sim.st.by_id(int(x.src))
		if src and src.side == f.side:
			e.src = x.src   # Q97: 적이 건 효과는 시전 함대를 숨긴다
		else:
			e.foe = true
		fx.append(e)
	return {"slots": slots, "fx": fx}

func fingerprint() -> String:
	if used_n == 0:
		return ""   # 발동이 없으면 P8a 이전 지문과 같다
	var parts := PackedStringArray()
	for f in sim.st.fleets:
		var ks: Array = f.skill_used.keys()
		ks.sort()
		parts.append("%d.%s.%s" % [f.id, "+".join(PackedStringArray(ks)), "+".join(PackedStringArray(f.fx.map(func(x): return "%s@%d" % [x.id, x.until])))])
	var sides := PackedStringArray()
	for side in 2:
		sides.append("+".join(PackedStringArray(side_fx[side].map(func(x): return "%s@%d" % [x.id, x.until]))))
	return "|sk%d.%s|%s" % [used_n, ".".join(sides), ",".join(parts)]
