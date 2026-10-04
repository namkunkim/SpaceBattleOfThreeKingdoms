class_name BattleSim
extends RefCounted

# 전투 코어: 상태, 고정 틱, 규칙, 승패, 명령 검증, 사건 발행. 유일한 권위다.
# Node·Input·전역 난수·Time·타이머·프레임 delta를 쓰지 않는다.
#
# 명령: {tick, side, ids: Array[int], kind, target_id, point: Vector2, args: Dictionary}
#   플레이어 명령은 queue()로 넣고 다음 step()의 첫머리에 적용·기록한다. AI 명령은 기록하지 않는다(상태에서 다시 나온다).
# 사건: {tick, kind, sq, other, pos, value} — drain_events()로 가져간다. 표현과 로그는 사건만 보고 그린다.

var profile_id := ""
var rs: RuleSet
var R: Dictionary          # rs.v (규칙 수치, 프로필 JSON)
var st: BattleState
var rng: BattleRng
var dt := BattleRules.TICK_S
var command_log: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _ai := PocEnemyAi.new()
# 초 단위 규칙값의 틱 수(틱 폭에 따라)
var T := {}
var sub_ms := 0              # 틱마다 정해진다(_tick)
var _reinf_def: Array = []
var morale: MoraleCore = null   # M4 사기. 시나리오 프로필(salvo + realtime_rules)에서만 켜진다
var victory: Victory = null     # M4 승패(§4.12). 없으면 POC 종료 조건(기함 상실·섬멸)
var salvo: SalvoCombat = null   # M3 사격·피해 규칙. combat 사전이 있는 프로필에서만 켜진다(없으면 POC 규칙)
var terrain: BattleTerrain = null   # M6 지형. combat.terrain이 있을 때
var cai: CommanderAi = null     # M7 지휘관 AI. 프로필에 ai 수치가 있을 때(적벽)만. 없으면 POC AI
var decisions: DecisionBoard = null   # M7 결정 카드(시나리오 realtime_rules.decision_cards가 있을 때)
var first_hit_tick := -1        # 첫 명중 틱(양측이 아는 공개 사실). AI의 거리대 일정이 이 시각에서 센다
var detect: Detection = null    # M6 탐지·전쟁 안개. combat.detection이 있을 때만 켜진다(없으면 완전 정보)
var supply: SupplyCore = null   # M8 보급과 수리. combat.supply가 있을 때만 켜진다

# profile: 프로필 사전({profile_id, rules, ally, foe, reinf}). 비우면 POC 프로필(기준선 동등).
func _init(seed_id: int = 0, hz: int = BattleRules.TICK_HZ, profile: Dictionary = {}) -> void:
	if profile.is_empty():
		profile = PocSetup.profile()
	profile_id = profile.profile_id
	rs = RuleSet.from_profile(profile)
	R = rs.v
	st = BattleState.new()
	st.hz = hz
	st.seed_id = seed_id
	st.cp = R.cp_start_bp
	st.ecp = R.cp_start_bp
	dt = 1.0 / hz
	rng = BattleRng.new("%s|%d" % [profile_id, seed_id])
	T.MISSILE_CD_S = BattleRules.ticks(R.missile_cd_s, hz)
	T.FIGHTER_CD_S = BattleRules.ticks(R.fighter_cd_s, hz)
	T.CHARGE_S = BattleRules.ticks(R.charge_s, hz)
	T.FLANK_MSG_S = BattleRules.ticks(R.flank_msg_s, hz)
	T.CP_REGEN = BattleRules.ticks(R.cp_regen_s, hz)
	T.ECP_REGEN = BattleRules.ticks(R.ecp_regen_s, hz)
	_reinf_def = profile.get("reinf", [])
	if not profile.get("combat", {}).is_empty():
		salvo = SalvoCombat.new(self, profile.combat)
	for d in profile.ally:
		_spawn(d, 0)
	for d in profile.foe:
		_spawn(d, 1)
	if salvo:
		salvo.terrain_class = str(rs.scenario.get("battlefield_class", ""))
		salvo.finish_setup()
		st.cp = 0   # CP는 salvo 규칙에서 쓰지 않는다(M4). 자원은 탄약·에너지·열·함재기다
		st.ecp = 0
		var cb: Dictionary = profile.combat
		if cb.has("terrain"):
			terrain = BattleTerrain.new(cb.terrain)
			salvo.terr = terrain
		if cb.has("detection"):
			detect = Detection.new(self, cb.detection, terrain if terrain else BattleTerrain.new({}))
		if cb.has("supply"):
			supply = SupplyCore.new(self, cb.supply)
		if cb.has("morale") and not rs.scenario.is_empty():
			morale = MoraleCore.new(self, cb.morale)
			if cb.has("victory"):
				victory = Victory.new(self, cb.victory)
	if not profile.get("ai", {}).is_empty() and salvo and morale:
		enable_commander_ai(profile.ai)

# ============================================================ 공개 API
func queue(cmd: Dictionary) -> void:
	_queue.append(cmd)

func drain_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out

# 지휘관 AI와 결정 카드를 켠다(프로필 ai 수치가 있을 때 _init이 부른다. 규칙 단위 테스트도 쓴다)
func enable_commander_ai(cfg: Dictionary) -> void:
	cai = CommanderAi.new(cfg)
	var dc: Dictionary = rs.rt("decision_cards", {})
	if not dc.is_empty() and morale:
		decisions = DecisionBoard.new(self, dc, cfg.decisions)

# "전 전대 수동" 설정(§5.4): 켜면 모든 아군 전대가 직접 지휘가 된다. 끄면 모두 위임으로 돌아간다
func set_manual_all(on: bool) -> void:
	for f in st.fleets:
		if f.side == 0:
			f.control = "direct" if on else "delegate"

func projection(side: int) -> Dictionary:
	return BattleProjection.build(self, side)

func fingerprint() -> String:
	var extra := ""
	if cai:
		var parts := PackedStringArray()
		for f in st.fleets:
			parts.append("%d.%s.%s.%d.%d.%d.%d" % [f.id, f.control, f.posture, f.bias_until, roundi(f.bias_mod * 1000.0), f.pursue_id, f.ai_seen])
		extra = "ai%d|%s|%s" % [first_hit_tick, ",".join(parts), decisions.fingerprint() if decisions else ""]
	if supply:
		extra += supply.fingerprint()   # M8. 보급이 없으면 M7 지문과 같다
	return BattleFingerprint.of(st, detect, extra)

# 즉시 적용 명령. 틱 사이에 상태는 변하지 않으므로 "다음 step() 첫머리에 적용"과 결과가 같고,
# 재생(replay)도 같은 틱 번호로 같은 결과를 낸다. 화면이 명령 직후 상태를 바로 읽을 수 있다.
func issue(cmd: Dictionary) -> void:
	var c := cmd.duplicate(true)
	c.tick = st.tick
	command_log.append(c)
	_mark_direct(c)
	apply(c)

# 플레이어가 명령한 전대는 직접 지휘가 된다(§5.4). AI 명령은 apply()를 바로 불러 여기를 거치지 않는다.
const DIRECT_KINDS := ["stop", "move", "attack", "charge", "retreat", "rally", "formation", "restore", "def", "missile", "fighter", "volley"]

func _mark_direct(c: Dictionary) -> void:
	if int(c.side) != 0 or not (str(c.kind) in DIRECT_KINDS):
		return
	for f in _cmd_fleets(c):
		f.control = "direct"

# 한 틱 진행. 대기 중인 명령을 먼저 적용한다.
func step() -> void:
	var cmds := _queue
	_queue = []
	for c in cmds:
		c = c.duplicate(true)
		c.tick = st.tick
		command_log.append(c)
		_mark_direct(c)
		apply(c)
	_tick()

# 명령 기록으로 다시 돌린다(재생). until_tick까지.
static func replay(seed_id: int, hz: int, log: Array, until_tick: int, profile := {}) -> BattleSim:
	var sim := BattleSim.new(seed_id, hz, profile)   # 시나리오 판(안개·AI)은 같은 프로필로 다시 만든다(M6 리뷰 F-2)
	var i := 0
	while sim.st.tick < until_tick:
		while i < log.size() and int(log[i].tick) == sim.st.tick:
			sim.queue(log[i])
			i += 1
		sim.step()
		sim.drain_events()
	return sim

static func command(side: int, ids: Array, kind: String, target_id := -1, point := Vector2.ZERO, args := {}) -> Dictionary:
	return {"tick": -1, "side": side, "ids": ids.duplicate(), "kind": kind, "target_id": target_id, "point": point, "args": args}

# 테스트·도구용 훅(규칙 단위 테스트가 상태를 직접 만든다). 게임 흐름에서는 쓰지 않는다.
func debug_damage(src_id: int, tgt_id: int, amt: float) -> void:
	apply_dmg(st.by_id(src_id), st.by_id(tgt_id), amt)

func debug_fire_missiles(src_id: int, tgt_id: int) -> void:
	_fire_missiles(st.by_id(src_id), st.by_id(tgt_id))

func debug_launch_fighters(src_id: int, tgt_id: int) -> void:
	_launch_fighters(st.by_id(src_id), st.by_id(tgt_id))

func debug_spawn_reinf() -> void:
	_spawn_reinf()

func debug_end(win: bool, reason: String) -> void:
	_end(win, reason)

# ============================================================ 사건
func emit(kind: String, sq := -1, other := -1, pos := Vector2.ZERO, value: Variant = null) -> void:
	_events.append({"tick": st.tick, "kind": kind, "sq": sq, "other": other, "pos": pos, "value": value})

# ============================================================ 편성
func _spawn(d: Dictionary, side: int) -> FleetState:
	var f := FleetState.new()
	f.id = st.next_id
	st.next_id += 1
	f.side = side
	f.name = d.name
	f.role = d.role
	f.ships = int(d.ships) * BattleRules.MILLI
	f.max_ships = f.ships
	f.shown = f.ships
	f.lv = d.lv
	f.pos = Vector2(d.x, d.y)
	f.heading = PI if side == 1 else 0.0
	f.is_flag = d.get("flag", false)
	f.spd = d.get("spd", 1.0)
	f.wait = BattleRules.ticks(float(d.get("wait", 0)), st.hz)
	f.portrait = d.p
	f.home = f.pos
	f.sq_id = d.get("squadron_id", "")
	f.morale_group = d.get("morale_group", "")
	f.faction = d.get("faction_id", "")
	f.group_id = d.get("group_id", "")
	f.commander_id = d.get("commander_id", "")
	f.start_morale_bp = int(d.get("start_morale_bp", 0))
	f.range_r = R.range_r
	f.form_id = st.form_counter
	st.form_counter += 1
	f.form = BattleRules.formation_offsets(f.form_id % BattleRules.FORM_COUNT, R.ship_gap * (1.0 if f.form_id < BattleRules.FORM_COUNT else R.formation_loose_mul))
	st.fleets.append(f)
	if salvo:
		salvo.init_fleet(f, d)
	emit("spawn", f.id)
	return f

func _spawn_reinf() -> void:
	st.reinf = true
	st.reinf_ms = st.clock_ms
	for d in _reinf_def:
		_spawn(d, 1)
	emit("reinforcements")

# ============================================================ 피해
func _rand_ship(f: FleetState, eid: int, sub: int) -> Vector2:
	var i := rng.index(rs.n_ships(f.ships, f.max_ships), st.tick, eid, sub)
	return BattleRules.ship_pos(f.pos, f.heading, f.form, i)

func apply_dmg(src: FleetState, tgt: FleetState, amt: float) -> void:
	if tgt.dead:
		return
	if tgt.defense:
		amt *= R.defense_damage_taken_mul
	var a := mini(roundi(amt), tgt.ships)
	tgt.ships -= a
	if src and not src.dead:
		src.xp += a
		var need := rs.xp_need_milli(src.lv)
		if src.xp >= need and src.lv < R.level_max_n:
			src.xp -= need
			src.lv += 1
			emit("level_up", src.id, -1, src.pos)
	book_loss(src, tgt, a)

# 척 수(1/1000척)가 a만큼 줄어든 것을 기록한다: 누계, 표시 척 수, 손실 사건, 격침. POC 피해와 salvo 피해가 함께 쓴다.
func book_loss(src: FleetState, tgt: FleetState, a: int) -> void:
	if tgt.side == 1:
		st.killed += a
	else:
		st.lost += a
	var n := 0
	while tgt.shown - tgt.ships >= BattleRules.MILLI:
		tgt.shown -= BattleRules.MILLI
		n += 1
	if n > 0:
		emit("ship_lost", tgt.id, src.id if src else -1, tgt.pos, n)
	if tgt.ships <= R.kill_below_milli_n:
		_kill(tgt, src)

func _kill(f: FleetState, src: FleetState) -> void:
	if f.dead:
		return
	f.dead = true
	f.out = "sunk"
	f.died_pos = f.pos
	f.ships = 0
	for o in st.fleets:
		if o.target_id == f.id:
			o.target_id = -1
	emit("destroyed", f.id, src.id if src else -1, f.pos)

# 항복·탈출로 전투에서 빠진다(M4). 격침(_kill)과 달리 척 수는 그대로다.
func remove_fleet(f: FleetState, why: String) -> void:
	if f.dead:
		return
	f.dead = true
	f.out = why
	f.died_pos = f.pos
	f.has_move = false
	for o in st.fleets:
		if o.target_id == f.id:
			o.target_id = -1
	emit("surrender" if why == "surrender" else "escape", f.id, -1, f.pos)

func _fire_missiles(f: FleetState, tgt: FleetState) -> void:
	var eid := st.new_event_id()
	for i: int in R.missile_count_n:
		var m := BattleState.Missile.new()
		m.id = st.new_event_id()
		m.pos = _rand_ship(f, eid, i * 3 + 1)
		m.target_id = tgt.id
		m.src_id = f.id
		m.dmg = roundi(f.ships * R.missile_dmg_share * rs.power(f.lv, f.charge > 0, f.in_cmd, f.defense) / (R.defense_power_mul if f.defense else 1.0))
		m.v = R.missile_v0 + rng.unit(st.tick, eid, i * 3 + 2) * R.missile_v_rand
		m.wob = (rng.unit(st.tick, eid, i * 3 + 3) - 0.5) * R.missile_wob
		m.side = f.side
		st.missiles.append(m)
	f.missile_cd = T.MISSILE_CD_S
	emit("missile_launch", f.id, tgt.id, f.pos)

func _launch_fighters(f: FleetState, tgt: FleetState) -> void:
	var eid := st.new_event_id()
	var s := BattleState.Swarm.new()
	s.id = eid
	s.src_id = f.id
	s.target_id = tgt.id
	s.side = f.side
	s.life = R.swarm_life_ms
	s.dps = roundi(f.ships * R.fighter_dps_share * rs.level_mul(f.lv))
	for i: int in R.swarm_points_n:
		var k := i * 5
		s.pts.append({
			"pos": _rand_ship(f, eid, k + 1),
			"a": rng.unit(st.tick, eid, k + 2) * TAU,
			"r": R.swarm_r0 + rng.unit(st.tick, eid, k + 3) * R.swarm_r_rand,
			"w": (-1.0 if rng.bp(st.tick, eid, k + 4) < BattleRules.BP / 2 else 1.0) * (R.swarm_w0 + rng.unit(st.tick, eid, k + 5) * R.swarm_w_rand),
		})
	st.swarms.append(s)
	f.fighter_cd = T.FIGHTER_CD_S
	emit("fighter_launch", f.id, tgt.id, f.pos)

# ============================================================ 명령
func _cmd_fleets(c: Dictionary) -> Array[FleetState]:
	var out: Array[FleetState] = []
	for id in c.get("ids", []):
		var f := st.by_id(int(id))
		if f and not f.dead and f.side == int(c.side) and not out.has(f):
			out.append(f)
	return out

func _lead(s: Array[FleetState]) -> FleetState:
	for f in s:
		if f.is_flag:
			return f
	return s[0] if s.size() > 0 else null

# 이동 명령의 부속 상태(경유점, 평행 이동, 도착 방향)를 지운다
func _clear_path(f: FleetState) -> void:
	f.route.clear()
	f.strafe = false
	f.face_set = false

func _reject(lead: FleetState, reason: String, side: int) -> void:
	emit("rejected", lead.id if lead else -1, side, Vector2.ZERO, reason)

# ============================================================ 시야(M6)
# 전대가 쏘거나 따라갈 수 있는 적인가: 진영 접촉표의 확인·추정 접촉. 안개가 없으면(POC·테스트) 살아 있으면 된다.
func sees(f: FleetState, t: FleetState) -> bool:
	return t != null and not t.dead and (detect == null or detect.can_target(f.side, t.id))

# 지정 표적(살아 있고 보이는 것만)
func sight_target(f: FleetState) -> FleetState:
	var t := st.live_target(f)
	return t if sees(f, t) else null

# 진영이 아는 표적 위치. 접촉이 없거나 안개가 없으면 실제 위치
func known_pos(f: FleetState, t: FleetState) -> Vector2:
	if detect == null:
		return t.pos
	return detect.rec(f.side, t.id).get("pos", t.pos)

func sight_foe(f: FleetState, max_r: float) -> FleetState:
	if detect == null:
		return st.nearest_foe(f, max_r)
	var best: FleetState = null
	var bd := max_r
	for o in st.fleets:
		if o.side == f.side or not sees(f, o):
			continue
		var d := f.pos.distance_to(known_pos(f, o))
		if d < bd:
			bd = d
			best = o
	return best

# 화면용 사건. 보이지 않는 적이 낸 사건은 빼거나 가린다(안개 경계). 안개가 없으면 그대로.
# 보이지 않는 적의 일제사격은 사격 사실만 남긴다(맞은 쪽은 아군이라 알 수 있다) — 조용한 구간을 끝내는 신호(리뷰 V-2).
func drain_events_for(side: int) -> Array[Dictionary]:
	var evs := drain_events()
	if detect == null:
		return evs
	var out: Array[Dictionary] = []
	for e in evs:
		var e2 := e
		if e.kind == "contact":
			if side != 0:
				continue
		else:
			var a := st.by_id(int(e.sq))
			if a and a.side != side and not detect.contacts[side].has(a.id):
				if e.kind != "salvo":
					continue
				e2 = e.duplicate()
				e2.sq = -1
			var b := st.by_id(int(e.other))
			if b and b.side != side and not detect.contacts[side].has(b.id):
				e2 = e2.duplicate()
				e2.other = -1
		out.append(e2)
	return out

func _cp(side: int) -> int:
	return st.cp if side == 0 else st.ecp

func _spend(side: int, amt: int) -> void:
	if side == 0:
		st.cp -= amt
	else:
		st.ecp -= amt

# 명령 적용. 검증에 실패하면 "rejected" 사건(사유 코드)을 내고 상태를 바꾸지 않는다.
func apply(c: Dictionary) -> void:
	var side := int(c.side)
	var kind: String = c.kind
	if kind == "decide":
		# 결정 카드 응답(M7). args {id, option}. 전대 선택이 없다
		var why: String = decisions.resolve(int(c.args.get("id", -1)), str(c.args.get("option", "")), "player") if decisions and side == 0 else "unknown_command"
		if why != "":
			_reject(null, why, side)
		return
	var s := _cmd_fleets(c)
	if s.is_empty():
		_reject(null, "no_selection", side)
		return
	if morale:
		# 강제 퇴각 중인 전대는 명령을 받지 않는다(§4.6)
		s = s.filter(func(f): return not morale.forced(f))
		if s.is_empty():
			if not (kind.begins_with("ai_") or kind == "def_on" or kind == "delegate" or kind == "posture"):
				_reject(null, "retreating", side)
			return
	var L := _lead(s)
	if morale and kind in ["stop", "move", "attack", "charge"]:
		for f in s:
			f.retreat_order = false
	if kind in ["stop", "attack", "charge", "retreat", "rally", "ai_move", "restore"]:
		for f in s:
			_clear_path(f)
	match kind:
		"delegate":
			# 위임으로 돌리기(§5.4): 지휘관 AI가 다시 이동·표적을 정한다. 퇴각 명령은 그대로 둔다
			if side != 0:
				return
			for f in s:
				f.control = "delegate"
			emit("say", L.id, -1, L.pos, "delegate")
		"posture":
			# 전투 방침 지정(§5.2). args.id = aggressive | balanced | cautious | scheming | delegated(인물 위임)
			var pid := str(c.get("args", {}).get("id", ""))
			if cai == null or not cai.A.postures.has(pid):
				_reject(L, "unknown_command", side)
				return
			for f in s:
				f.posture = pid
			emit("say", L.id, -1, L.pos, "posture")
		"stop":
			for f in s:
				f.target_id = -1
				f.has_move = false
			emit("say", L.id, -1, L.pos, "stop")
		"formation":
			# 진형 전환(§4.7). args.id = 진형 ID. 전환 시간 동안 피해 ×0.8, 방어%·노출 배치는 이전 진형
			if salvo == null:
				_reject(L, "unknown_command", side)
				return
			var ok := 0
			var why := ""
			for f in s:
				var w := salvo.start_transition(f, str(c.get("args", {}).get("id", "")))
				if w == "":
					ok += 1
				else:
					why = w
			if ok == 0:
				_reject(L, why, side)
				return
			emit("say", L.id, -1, L.pos, "formation")
		"def":
			if salvo:
				_reject(L, "unknown_command", side)   # 방어진형은 삭제됐다. 방원진이 대신한다(§9)
				return
			var on := false
			for f in s:
				if not f.defense:
					on = true
			for f in s:
				f.defense = on
			emit("say", L.id, -1, L.pos, "def_on" if on else "def_off")
		"def_on":
			if salvo:
				return
			for f in s:
				f.defense = true
			emit("say", L.id, -1, L.pos, "ai_def")
		"missile", "fighter", "volley":
			if salvo:
				for f in s:
					salvo.pull(f)   # 일제사격 지금: 다음 주기를 당긴다(§4.3). 비용은 자원 규칙이 받는다
				emit("say", L.id, -1, L.pos, "missile" if side == 0 else "ai_missile")
			elif kind == "volley":
				_reject(L, "unknown_command", side)
			else:
				_cmd_weapon(c, s, L, kind == "missile")
		"charge":
			if salvo:
				_cmd_charge_salvo(s, L, side)
				return
			if _cp(side) < R.charge_cost_bp:
				_reject(L, "cp_charge", side)
				return
			_spend(side, R.charge_cost_bp)
			for f in s:
				f.charge = T.CHARGE_S
				f.defense = false
				if sight_target(f) == null:
					var t := sight_foe(f, R.charge_seek_r)
					if t:
						f.target_id = t.id
			emit("say", L.id, -1, L.pos, "charge")
			emit("charge", L.id)
		"rally":
			var pf := st.flag(side)
			if pf == null:
				_reject(L, "no_flagship", side)
				return
			var i := 0
			for f in s:
				if f == pf:
					continue
				var a := i * TAU / maxf(1.0, s.size() - 1.0) + PI / 2.0
				i += 1
				f.target_id = -1
				f.has_move = true
				f.move_to = pf.pos + Vector2(cos(a), sin(a)) * R.rally_radius
			emit("say", L.id, -1, L.pos, "rally")
		"morale_rally":
			var why := morale.rally(side, str(c.get("args", {}).get("id", ""))) if morale else "unknown_command"
			if why != "":
				_reject(L, why, side)
		"retreat":
			if morale:
				# 후퇴는 버튼이 아니라 탈출 지점까지의 이동이다(§4.12)
				for f in s:
					f.target_id = -1
					f.defense = false
					f.retreat_order = true
					f.has_move = true
					f.move_to = morale.exit_point(f.side)
				emit("say", L.id, -1, L.pos, "retreat")
				return
			var W := rs.world
			for f in s:
				var t := sight_foe(f, R.retreat_seek_r)
				f.target_id = -1
				# 표적이 없으면 바라보는 방향의 반대로 물러난다(M1 목록: 고정 방향(서쪽)이라 적 쪽으로 갈 수 있었다)
				var a := atan2(f.pos.y - t.pos.y, f.pos.x - t.pos.x) if t else f.heading + PI
				f.has_move = true
				f.move_to = Vector2(clampf(f.pos.x + cos(a) * R.retreat_dist, R.retreat_margin, W.x - R.retreat_margin), clampf(f.pos.y + sin(a) * R.retreat_dist, R.retreat_margin, W.y - R.retreat_margin))
			emit("say", L.id, -1, L.pos, "retreat")
		"move":
			# 선택 전체가 현재 배치를 유지한 채 목표 지점으로 이동. salvo 규칙에서는 args로
			# via(경유점 목록, 경유 + 목적지가 max_waypoints 이하), strafe(평행 이동), facing_deg(도착 방향)를 받는다(§4.2)
			var W := rs.world
			var e: float = R.edge
			var args: Dictionary = c.get("args", {}) if salvo else {}
			var pts: Array = (args.get("via", []) as Array).duplicate()
			pts.append(c.point)
			if salvo and pts.size() > int(salvo.C.movement.max_waypoints):
				_reject(L, "too_many_waypoints", side)
				return
			var cen := Vector2.ZERO
			for f in s:
				cen += f.pos
			cen /= s.size()
			for f in s:
				var o := f.pos - cen
				f.target_id = -1
				f.has_move = true
				_clear_path(f)
				for i in pts.size():
					var w: Vector2 = pts[i]
					var p := BattleRules.quant_v(Vector2(clampf(w.x + o.x, e, W.x - e), clampf(w.y + o.y, e, W.y - e)))
					if i == 0:
						f.move_to = p
					else:
						f.route.append(p)
				f.strafe = bool(args.get("strafe", false))
				if args.has("facing_deg"):
					f.face_set = true
					f.face_to = BattleRules.quant(deg_to_rad(float(args.facing_deg)))
			emit("say", L.id, -1, L.pos, "move_all" if s.size() > 1 else "move")
		"attack":
			var t := st.by_id(int(c.target_id))
			if t == null or t.dead or t.side == side:
				_reject(L, "bad_target", side)
				return
			if detect and not detect.can_target(side, t.id):
				_reject(L, "no_contact", side)   # 접촉이 없는 적은 지정할 수 없다(M6)
				return
			for f in s:
				f.target_id = t.id
				f.has_move = false
			emit("say", L.id, t.id, L.pos, "attack")
		"ai_target":
			for f in s:
				f.target_id = int(c.target_id)
		"ai_move":
			for f in s:
				f.has_move = true
				f.move_to = c.point
		"restore":
			# 명령 되돌리기(U2): 직전 명령 상태로 돌아가는 새 명령. args.orders = {id: [has_move, move_to, target_id, defense]}
			var orders: Dictionary = c.args.get("orders", {})
			for f in s:
				var o = orders.get(f.id, orders.get(str(f.id)))
				if o == null:
					continue
				f.has_move = bool(o[0])
				f.move_to = o[1]
				var t := st.by_id(int(o[2]))
				f.target_id = t.id if (t and not t.dead) else -1
				f.defense = bool(o[3])
		_:
			_reject(L, "unknown_command", side)

# 돌격(Q28·Q42): 열 40%와 사기 안정 조건. CP는 쓰지 않는다. 조건을 채우지 못한 전대는 빠지고, 모두 못 채우면 거부한다.
func _cmd_charge_salvo(s: Array[FleetState], L: FleetState, side: int) -> void:
	var ok: Array[FleetState] = []
	var why := ""
	for f in s:
		var w := salvo.charge_block(f)
		if w == "":
			ok.append(f)
		else:
			why = w
	if ok.is_empty():
		_reject(L, why, side)
		return
	for f in ok:
		salvo.charge_pay(f)
		f.charge = T.CHARGE_S
		f.defense = false
		if sight_target(f) == null:
			var t := sight_foe(f, R.charge_seek_r)
			if t:
				f.target_id = t.id
	emit("say", L.id, -1, L.pos, "charge")
	emit("charge", L.id)

func _cmd_weapon(c: Dictionary, s: Array[FleetState], L: FleetState, missile: bool) -> void:
	var side := int(c.side)
	var cost: int = R.missile_cost_bp if missile else R.fighter_cost_bp
	var reach: float = R.missile_r if missile else R.fighter_r
	if _cp(side) < cost:
		_reject(L, "cp_missile" if missile else "cp_fighter", side)
		return
	var fixed := st.by_id(int(c.get("target_id", -1)))
	var n := 0
	for f in s:
		if (f.missile_cd if missile else f.fighter_cd) > 0:
			continue
		var t: FleetState = null
		if fixed:
			t = fixed if not fixed.dead else null
		else:
			var ft := st.live_target(f)
			t = ft if (ft and f.pos.distance_to(ft.pos) <= reach) else st.nearest_foe(f, reach)
		if t:
			if missile:
				_fire_missiles(f, t)
			else:
				_launch_fighters(f, t)
			n += 1
	if n == 0:
		var ready := false
		for f in s:
			if (f.missile_cd if missile else f.fighter_cd) <= 0:
				ready = true
		if missile:
			_reject(L, "missile_no_target" if ready else "missile_reload", side)
		else:
			_reject(L, "fighter_no_target" if ready else "fighter_reload", side)
		return
	_spend(side, cost)
	if side == 1:
		emit("say", L.id, -1, L.pos, "ai_missile" if missile else "ai_fighter")
	else:
		emit("say", L.id, -1, L.pos, "missile" if missile else "fighter")
		if missile:
			emit("volley", L.id, -1, L.pos, n)

# ============================================================ 틱
static func _regen(cur: int, rem: int, period: int, cap: int) -> Array:
	# 1점(10000bp)을 period 틱에 나눠 채운다. 나머지를 넘겨 누적 오차가 없다.
	rem += BattleRules.BP
	cur = mini(cap, cur + rem / period)
	rem %= period
	return [cur, rem]

func _turn(f: FleetState, a: float) -> void:
	# salvo 규칙의 선회는 데이터(제자리 180°에 20초, §4.2). POC 규칙은 turn_rate
	var m: float = (deg_to_rad(float(salvo.C.movement.turn_deg_per_s)) if salvo else float(R.turn_rate)) * dt
	var dh := BattleRules.ang_diff(f.heading, a)
	f.heading += dh if absf(dh) < m else signf(dh) * m

func _tick() -> void:
	st.tick += 1
	if not salvo:
		var r := _regen(st.cp, st.cp_rem, T.CP_REGEN, R.cp_max_bp)
		st.cp = r[0]
		st.cp_rem = r[1]
		r = _regen(st.ecp, st.ecp_rem, T.ECP_REGEN, R.cp_max_bp)
		st.ecp = r[0]
		st.ecp_rem = r[1]
	# 틱 안의 하위 걸음: 한 걸음이 0.05초(기준 POC의 프레임 폭)를 넘지 않게 나눈다. 한 걸음의 순서는 기준과 같다
	# (증원 → AI → 함대 이동·사격 → 간격 → 미사일 → 함재기 → 승패). 0.1초 한 걸음으로 돌리면 추격·사격 순서의
	# 이산화로 통계가 어긋난다(charge30에서 killed +15%, KS D 0.83). 틱·명령·기록·난수·사건은 10Hz 그대로이고
	# 나눠 도는 것도 결정론이다.
	var n := maxi(1, ceili(dt / BattleRules.REF_DT - 1e-9))
	var save := dt
	dt = save / n
	sub_ms = roundi(dt * 1000.0)
	for i in n:
		if st.over:
			break
		_substep(i == 0)
	dt = save
	for f in st.fleets:
		f.pos = BattleRules.quant_v(f.pos)
		f.heading = BattleRules.quant(f.heading)

func _substep(first: bool) -> void:
	st.clock_ms += sub_ms
	if not st.reinf and not _reinf_def.is_empty() and st.clock_ms > R.reinf_ms:
		_spawn_reinf()
	st.ai_timer -= sub_ms
	if st.ai_timer <= 0:
		st.ai_timer += R.ai_period_ms
		if cai:
			cai.think(self)
		else:
			_ai.think(self)
	_fleet_phase(first)
	if salvo and first:
		if detect:
			detect.step()
		salvo.step()
		if morale:
			morale.step()
		if supply:
			supply.step()
		if decisions:
			decisions.step()
	_separate()
	_move_missiles()
	_move_swarms()
	if victory:
		if first:
			victory.check()
	elif st.flag(0) == null:
		_end(false, "flagship_lost")
	elif st.alive(1).is_empty():
		if not st.reinf and not _reinf_def.is_empty():
			_spawn_reinf()
		else:
			_end(true, "annihilation")

func _fleet_phase(timers: bool) -> void:
	var flags := [st.flag(0), st.flag(1)]
	for f in st.fleets:
		if f.dead:
			continue
		if timers:
			f.missile_cd = maxi(0, f.missile_cd - 1)
			f.fighter_cd = maxi(0, f.fighter_cd - 1)
			if f.charge > 0:
				f.charge -= 1
			if f.flank_msg > 0:
				f.flank_msg -= 1
		var fl: FleetState = flags[f.side]
		f.in_cmd = fl == null or fl == f or f.pos.distance_to(fl.pos) < R.cmd_r
		if morale and morale.forced(f):
			f.target_id = -1
			f.has_move = true
			f.move_to = morale.exit_point(f.side)
			_clear_path(f)
		var tgt := sight_target(f)
		if tgt == null:
			f.target_id = -1
		var has_dest := false
		var dest := Vector2.ZERO
		var chase_r: float = f.range_r * R.chase_range_share
		if salvo and f.charge > 0:
			chase_r = float(salvo.C.bands.assault_r)   # 돌격은 강습 거리까지 붙는다
		if tgt:
			var tp := known_pos(f, tgt)
			if f.pos.distance_to(tp) > chase_r:
				has_dest = true
				dest = tp
		elif f.has_move:
			if f.pos.distance_to(f.move_to) < R.arrive_r:
				if f.route.is_empty():
					f.has_move = false
					f.strafe = false
				else:
					f.move_to = f.route.pop_front()   # 다음 경유점
			if f.has_move:
				has_dest = true
				dest = f.move_to
		var spd := rs.move_speed(f.spd, f.defense, f.charge > 0)
		if salvo:
			spd = f.speed * (R.charge_speed_mul if f.charge > 0 else 1.0)
			if terrain:
				spd *= float(BattleRules.BP) / float(terrain.move_cost_bp(f.pos))   # 성운·잔해·그림자는 느리다(§4.10)
		if has_dest and f.strafe and tgt == null:
			# 평행 이동: 방향을 유지한 채 전진 속도의 일부로 목적지를 향해 옆으로 간다(§4.2)
			var dd := f.pos.distance_to(dest)
			f.pos += (dest - f.pos) / maxf(dd, 0.001) * minf(spd * float(salvo.C.movement.strafe_speed_bp) / float(BattleRules.BP) * dt, dd)
		elif has_dest:
			var a := atan2(dest.y - f.pos.y, dest.x - f.pos.x)
			_turn(f, a)
			var dd := f.pos.distance_to(dest)
			if dd < spd * R.settle_speed_share:
				f.pos += (dest - f.pos) * BattleRules.lerp_k(R.arrive_k_ref * BattleRules.REF_DT, dt)
			else:
				var k: float = maxf(R.min_turn_cos, cos(BattleRules.ang_diff(f.heading, a)))
				var stp := minf(spd * dt * k, dd)
				f.pos += Vector2(cos(f.heading), sin(f.heading)) * stp
		if not has_dest and f.face_set:
			# 도착 방향: 도착한 뒤 지정한 방향으로 돌아선다(§4.2). 맞출 때까지는 자동 조준보다 우선한다
			_turn(f, f.face_to)
			if absf(BattleRules.ang_diff(f.heading, f.face_to)) < deg_to_rad(float(salvo.C.movement.face_tolerance_deg)):
				f.face_set = false
		var ft: FleetState = tgt if (tgt and f.pos.distance_to(known_pos(f, tgt)) <= f.range_r) else sight_foe(f, f.range_r)
		f.fire_id = ft.id if ft else -1
		if ft:
			if not has_dest and not f.face_set:
				var fp := known_pos(f, ft)
				_turn(f, atan2(fp.y - f.pos.y, fp.x - f.pos.x))
			if salvo:
				continue   # 사격은 salvo.step()이 범주별 주기로 한다
			var fm := rs.flank_mul(f.pos, ft.pos, ft.heading)
			apply_dmg(f, ft, f.ships * R.fire_share * rs.power(f.lv, f.charge > 0, f.in_cmd, f.defense) * fm * dt)
			if fm > 1.0 and f.flank_msg <= 0:
				f.flank_msg = T.FLANK_MSG_S
				emit("flank", f.id, ft.id, ft.pos, fm)

func _separate() -> void:
	var k := BattleRules.lerp_k(R.separate_k_ref * BattleRules.REF_DT, dt)
	var fl := st.fleets
	for i in fl.size():
		var a: FleetState = fl[i]
		if a.dead:
			continue
		for j in range(i + 1, fl.size()):
			var b: FleetState = fl[j]
			if b.dead:
				continue
			var dv := b.pos - a.pos
			var d := maxf(dv.length(), 0.001)
			var mn: float = R.ally_gap if a.side == b.side else R.foe_gap
			if d < mn:
				var p := (mn - d) * 0.5 * k
				a.pos -= dv / d * p
				b.pos += dv / d * p
	var W := rs.world
	var e: float = R.edge
	for f in fl:
		f.pos.x = clampf(f.pos.x, e, W.x - e)
		f.pos.y = clampf(f.pos.y, e, W.y - e)

func _move_missiles() -> void:
	for m in st.missiles:
		m.age += sub_ms
		var t := st.by_id(m.target_id)
		if t == null or t.dead:
			m.dead = true
			continue
		var age_s := m.age / 1000.0
		var a: float = atan2(t.pos.y - m.pos.y, t.pos.x - m.pos.x) + m.wob * maxf(0.0, R.missile_wob_decay_s - age_s)
		m.pos = BattleRules.quant_v(m.pos + Vector2(cos(a), sin(a)) * m.v * dt)
		m.v += R.missile_accel * dt
		# 명중 판정은 기준 POC와 같은 점 판정이다(이동 뒤 위치가 표적에서 22px 안). 하위 걸음이 0.05초 이하라
		# 한 걸음 이동(≤20px)이 판정 지름(44px)보다 작아 놓치지 않는다. 선분 판정(§3.3)은 걸음이 더 커질 때 쓴다.
		var hit: bool = m.pos.distance_to(t.pos) < R.missile_hit_r
		if hit:
			m.dead = true
			apply_dmg(st.by_id(m.src_id), t, m.dmg)
			emit("missile_hit", t.id, m.src_id, m.pos)
	st.missiles = st.missiles.filter(func(m): return not m.dead)

func _move_swarms() -> void:
	var k_goal := BattleRules.lerp_k(R.swarm_goal_k_ref * BattleRules.REF_DT, dt)
	var k_back := BattleRules.lerp_k(R.swarm_back_k_ref * BattleRules.REF_DT, dt)
	for s in st.swarms:
		s.life -= sub_ms
		var t := st.by_id(s.target_id)
		var src := st.by_id(s.src_id)
		if t.dead or src.dead:
			s.life = mini(s.life, R.swarm_return_ms)
		for p in s.pts:
			p.a += p.w * dt
			var goal: Vector2 = t.pos + Vector2(cos(p.a), sin(p.a)) * p.r
			if s.life < R.swarm_return_ms:
				p.pos = BattleRules.quant_v(p.pos + (src.pos - p.pos) * k_back)
			else:
				p.pos = BattleRules.quant_v(p.pos + (goal - p.pos) * k_goal)
		s.striking = not t.dead and s.life > R.swarm_return_ms and s.pts.size() > 0 and (s.pts[0].pos as Vector2).distance_to(t.pos) < R.swarm_hit_r
		if s.striking:
			apply_dmg(src, t, s.dps * dt)
	st.swarms = st.swarms.filter(func(s): return s.life > 0)

func _end(win: bool, reason: String) -> void:
	st.over = true
	st.win = win
	st.end_reason = reason
	st.end_tick = st.tick
	st.end_ms = st.clock_ms
	emit("battle_end", -1, -1, Vector2.ZERO, reason)
