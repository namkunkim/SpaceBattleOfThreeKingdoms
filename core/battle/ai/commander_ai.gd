class_name CommanderAi
extends RefCounted

# M7 지휘관 AI(제안서 §5). 적(조조군)과 위임한 아군 전대가 같은 규칙을 쓴다. 결정은 모두 명령으로 내고
# 코어가 사람의 명령과 같은 해석기로 적용한다. 수치는 data/profiles/ai_m7.json(ai).
#
# 정보 경계(M6·M7 테스트): 적에 대해서는 BattleProjection.build(sim, side)가 주는 접촉 항목만 읽는다.
# 미탐지 적은 입력에 없다. 자기 편 상태(sim.st의 아군, 열·사기)는 자기 정보라 직접 읽는다.
#
# 전대 하나의 판단: 방침(전대 지정 > 지휘관 성향 > 진영 기본) → 성향 가중 a(방침 bias + 전황 반응 + 결정 카드)
#   → 표적 선택 → 목표 거리(포화 → 교전 → 강습 일정, a가 높으면 빨리 좁힌다) → 이동·표적·돌격·진형·퇴각.

var A: Dictionary
var last_view := [{}, {}]      # 진영별로 마지막에 읽은 공개 투영(테스트가 입력을 검사한다)
var last_known := [[], []]     # 같은 순간 그 진영의 접촉표 ID(안개가 있을 때). 투영의 적은 이 안에만 있어야 한다
var stats := {"charge": 0, "retreat": 0, "formation": 0}

func _init(cfg: Dictionary) -> void:
	A = cfg

# ============================================================ 방침
func posture_of(f: FleetState) -> String:
	var p := f.posture
	if p == "" or p == "delegated":
		var c: Dictionary = A.commanders.get(f.commander_id, {})
		if c.has("posture"):
			return str(c.posture)
		p = str(A.dispositions.get(str(c.get("disposition", "")), "balanced"))
	return p

func _bias(sim: BattleSim, f: FleetState, P: Dictionary, view: Dictionary, weak: bool) -> float:
	var a := float(P.bias)
	if f.bias_until > sim.st.tick:
		a += f.bias_mod
	if view.get("morale_crisis", false):
		a += float(A.reaction.crisis_bias)
	if weak:
		a += float(A.reaction.foe_weak_bias)
	return a

# ============================================================ 입력: 공개 투영에서 적 접촉만
func _foes(view: Dictionary, side: int, dense_ids: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in view.squadrons:
		if s.side == side or s.get("dead", false):
			continue
		var state: String = s.get("contact", "confirmed")   # 안개가 없는 프로필은 접촉 키가 없고 모두 확인이다
		if state == "lost":
			continue
		var band: int = int(s.get("strength_band", 0))
		if band == 0 and s.has("ships_milli"):
			band = clampi(ceili(4 * float(s.ships_milli) / float(s.max_ships_milli)), 1, 4)
		out.append({"id": s.id, "pos": s.pos, "state": state, "conf_bp": int(s.get("conf_bp", 10000)), "band": band if band > 0 else 4,
			"dense": bool(s.get("dense", dense_ids.has(s.get("formation_id", ""))))})
	return out

# ============================================================ 한 번 생각
func think(sim: BattleSim) -> void:
	for side in 2:
		_think_side(sim, side)

func _think_side(sim: BattleSim, side: int) -> void:
	var st := sim.st
	var mine: Array[FleetState] = []
	for f in st.alive(side):
		if side == 1 or f.control == "delegate":
			mine.append(f)
	if mine.is_empty():
		return
	var view := sim.projection(side)
	last_view[side] = view
	last_known[side] = sim.detect.contacts[side].keys() if sim.detect else []
	var foes := _foes(view, side, sim.chain.X.dense if sim.chain else [])
	if sim.chain and side == 1:
		foes.assign(foes.filter(func(c): return not sim.chain.truce_id(int(c.id))))   # 투항 중인 황개는 표적이 아니다(공개된 사실)
	var lvl: Dictionary = sim.rs.difficulty_ai() if side == 1 else A.delegate_level
	var allies: Array[Vector2] = []
	for s in view.squadrons:
		if s.side == side and not s.get("dead", false):
			allies.append(s.pos)
	for f in mine:
		_think_fleet(sim, f, side, foes, view, lvl, allies)

func _think_fleet(sim: BattleSim, f: FleetState, side: int, foes: Array[Dictionary], view: Dictionary, lvl: Dictionary, allies: Array[Vector2]) -> void:
	var st := sim.st
	if sim.morale and sim.morale.fleeing(f):
		return   # 퇴각 중(강제·명령)이다. 탈출 지점까지 간다
	if sim.chain and side == 0 and sim.chain.host_think(f, foes):
		return   # 황개 화공대: 화공 일정(M9 chain_host_ai)
	var F: Dictionary = A.factions.get(f.faction, A.factions.cao_cao)
	var P: Dictionary = A.postures[posture_of(f)]
	var min_conf := int(F.estimated_min_conf_bp)
	var tg: Array[Dictionary] = []     # 표적이 될 수 있는 접촉(확인, 또는 신뢰도 충분한 추정)
	for c in foes:
		if c.state == "confirmed" or (c.state == "estimated" and c.conf_bp >= min_conf):
			tg.append(c)
	# 접촉이 처음 생긴 때부터 반응 지연(난이도)을 센다
	if foes.is_empty():
		f.ai_seen = -1
	elif f.ai_seen < 0:
		f.ai_seen = st.tick
	var react := BattleRules.ticks(float(lvl.reaction_s), st.hz)
	var nd := 1e9
	for c in tg:
		nd = minf(nd, f.pos.distance_to(c.pos))
	if st.tick < f.wait and nd >= sim.R.ai_engage_r:
		_hold(sim, f)   # 투입 대기(deploy_delay_s)
		return
	_defend(sim, f, P)
	if tg.is_empty() or (f.ai_seen >= 0 and st.tick < f.ai_seen + react):
		_no_contact(sim, f, side, F)
		return
	if F.engage_trigger_r > 0.0 and f.pursue_until <= st.tick:
		var near := false
		for c in tg:
			for ap in allies:
				if ap.distance_to(c.pos) <= float(F.engage_trigger_r):
					near = true
		if not near:
			_hold(sim, f)
			return
	var best := _pick(sim, f, tg, lvl)
	var weak: bool = best.band <= int(A.reaction.foe_weak_band)
	var a := _bias(sim, f, P, view, weak)
	_retreat(sim, f, P)
	if f.retreat_order:
		return
	if f.pursue_until > st.tick and f.pursue_id >= 0:
		for c in tg:
			if c.id == f.pursue_id:
				best = c
	var d := f.pos.distance_to(best.pos)
	if f.is_flag:
		# 기함은 가까워질 때까지 제 자리를 지킨다(POC 규칙). 사거리 안에서만 표적을 잡는다
		if nd < sim.R.ai_flag_engage_r:
			_do(sim, f, "ai_target", best.id)
		else:
			_do(sim, f, "ai_target", -1)
			if f.pos.distance_to(f.home) > sim.R.ai_flag_home_r:
				_do(sim, f, "ai_move", -1, f.home)
		return
	var D := _desired(sim, f, F, P, a)
	var slack := float(A.slack)
	var chase_r: float = f.range_r * sim.R.chase_range_share
	if f.charge > 0:
		chase_r = float(sim.salvo.C.bands.assault_r)
	var dir: Vector2 = (best.pos - f.pos) / maxf(d, 0.001)
	var aim: Vector2 = _linked(sim, f, best.pos - dir * D)
	if f.pursue_until > st.tick and f.pursue_id == best.id:
		_do(sim, f, "ai_target", best.id)   # 추격: 붙을 때까지 쫓는다
	elif d > D + slack:
		_do(sim, f, "ai_target", best.id if D <= chase_r + 1.0 else -1)
		_do(sim, f, "ai_move", -1, aim)
	elif d < D - slack and bool(P.kite):
		_do(sim, f, "ai_target", -1)
		_do(sim, f, "ai_move", -1, aim)   # 너무 가깝다: 물러나 거리를 유지한다
	else:
		_do(sim, f, "ai_target", best.id if D <= chase_r + 1.0 and d <= f.range_r else -1)
		if f.has_move:
			_do(sim, f, "ai_move", -1, f.pos)
	_charge(sim, f, P, a, d)
	if sim.assault:
		sim.assault.ai_try(f, best)   # 강습 거리에서 진형이 열렸으면 강습(M9)

# 현재 목표 거리: 첫 명중 뒤 포화 → 교전 → 강습 일정(realtime_rules.range_band_hold). a가 높으면 단계를 짧게 쓴다.
func _desired(sim: BattleSim, f: FleetState, F: Dictionary, P: Dictionary, a: float) -> float:
	var h: Dictionary = sim.rs.rt("range_band_hold", {})
	var d := float(h.barrage_distance)
	if sim.first_hit_tick >= 0:
		var mul := float(P.hold_mul) * clampf(1.0 - 0.5 * (a - float(P.bias)), float(A.hold_clamp[0]), float(A.hold_clamp[1]))
		var t := float(sim.st.tick - sim.first_hit_tick) / sim.st.hz
		var b := float(h.barrage_hold_s_after_first_hit) * mul
		var e := float(h.engagement_hold_s) * mul
		if t >= b + e:
			d = float(h.assault_distance)
		elif t >= b:
			d = float(h.engagement_distance)
	return maxf(d, maxf(float(P.min_dist), float(F.standoff)))

# 표적 고르기. 사고 깊이 1은 가장 가까운 것, 2는 거리 × (남은 전력 가중), 3은 추정 접촉에 벌점. 실수율만큼은 아무거나 고른다.
func _pick(sim: BattleSim, f: FleetState, tg: Array[Dictionary], lvl: Dictionary) -> Dictionary:
	var depth := int(lvl.think_depth)
	var sc: Dictionary = A.score
	var best: Dictionary = tg[0]
	var bs := 1e9
	for c in tg:
		var s := f.pos.distance_to(c.pos)
		if depth >= 2:
			s *= float(sc.base) + float(c.band) / 4 * float(sc.span)
		if depth >= 3 and c.state != "confirmed":
			s *= float(sc.estimated_mul)
		if s < bs:
			bs = s
			best = c
	var eid := sim.st.new_event_id()
	if tg.size() > 1 and sim.rng.bp(sim.st.tick, eid, 1) < int(lvl.mistake_bp):
		best = tg[sim.rng.index(tg.size(), sim.st.tick, eid, 2)]
	return best

func _no_contact(sim: BattleSim, f: FleetState, side: int, F: Dictionary) -> void:
	_do(sim, f, "ai_target", -1)
	if str(F.no_contact) == "advance" and sim.morale:
		# 정찰 전진을 방침으로 바꿨다: 접촉이 없으면 적 진영의 탈출 지점(공개 시나리오 데이터) 쪽으로 간다
		var goal := sim.morale.exit_point(1 - side)
		_do(sim, f, "ai_move", -1, f.pos + (goal - f.pos).normalized() * float(F.pursuit_step))
	else:
		_hold(sim, f)

func _hold(sim: BattleSim, f: FleetState) -> void:
	_do(sim, f, "ai_target", -1)
	if f.has_move:
		_do(sim, f, "ai_move", -1, f.pos)

func _defend(sim: BattleSim, f: FleetState, P: Dictionary) -> void:
	var def_id: String = sim.salvo.C.formation_rules.defense_id
	if float(f.ships) < float(f.max_ships) * float(P.defend_share) and f.formation_id != def_id and f.form_to != def_id:
		sim.apply(BattleSim.command(f.side, [f.id], "formation", -1, Vector2.ZERO, {"id": def_id}))   # 방어진형 대신 방원진(§9)
		stats.formation += 1

func _retreat(sim: BattleSim, f: FleetState, P: Dictionary) -> void:
	if sim.morale == null or f.retreat_order:
		return
	var rm := int(P.retreat_morale_bp)
	# 성향별 손실 임계(실무)는 방침 위에 얹는다: 둘 중 높은 남은 선체 비율에서 퇴각(§5.2·§5.3)
	var disp := str(A.commanders.get(f.commander_id, {}).get("disposition", ""))
	var share := maxf(float(P.retreat_ship_share), float(A.get("disposition_retreat_ship_share", {}).get(disp, 0.0)))
	if (rm > 0 and f.morale_bp < rm) or (share > 0.0 and float(f.ships) < float(f.max_ships) * share):
		sim.apply(BattleSim.command(f.side, [f.id], "retreat"))   # 질서 퇴각: 탈출 지점으로(§5.3)
		stats.retreat += 1

func _charge(sim: BattleSim, f: FleetState, P: Dictionary, a: float, d: float) -> void:
	if not bool(P.charge) or f.charge > 0 or a < float(A.reaction.charge_bias) or f.mstate != "stable":
		return
	if d > float(sim.rs.rt("range_band_hold.engagement_distance")) * float(A.reaction.charge_dist_share):
		return
	if sim.salvo.charge_block(f) != "":
		return
	sim.apply(BattleSim.command(f.side, [f.id], "charge"))
	stats.charge += 1

# 연환 대형 유지(§4.11, 제안값): 조조의 밀집 전대는 가장 가까운 밀집 아군과 120~180 간격을 유지하려 한다.
# 간격이 벌어지면 이동 목표를 그 아군 쪽 150 지점으로 cohesion만큼 끌어당긴다(가까워지는 쪽은 전대 간격 규칙이 막는다)
func _linked(sim: BattleSim, f: FleetState, aim: Vector2) -> Vector2:
	if sim.chain == null or f.side != 1 or not sim.chain.dense(f):
		return aim
	var sp: Array = sim.rs.rt("chain_operation.linked_formation_ai.spacing")
	var near: FleetState = null
	for o in sim.st.alive(1):
		if o != f and sim.chain.dense(o) and sim.st.tick >= o.wait and (near == null or f.pos.distance_to(o.pos) < f.pos.distance_to(near.pos)):
			near = o
	if near == null or f.pos.distance_to(near.pos) <= float(sp[1]):
		return aim
	var keep := near.pos + (f.pos - near.pos).normalized() * (float(sp[0]) + float(sp[1])) / 2.0
	return aim.lerp(keep, float(sim.chain.X.linked.cohesion))

func _do(sim: BattleSim, f: FleetState, kind: String, target_id := -1, point := Vector2.ZERO) -> void:
	sim.apply(BattleSim.command(f.side, [f.id], kind, target_id, point))
