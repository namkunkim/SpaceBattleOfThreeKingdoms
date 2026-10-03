class_name BattleSim
extends RefCounted

# 전투 코어: 상태, 고정 틱, 규칙, 승패, 명령 검증, 사건 발행. 유일한 권위다.
# Node·Input·전역 난수·Time·타이머·프레임 delta를 쓰지 않는다.
#
# 명령: {tick, side, ids: Array[int], kind, target_id, point: Vector2, args: Dictionary}
#   플레이어 명령은 queue()로 넣고 다음 step()의 첫머리에 적용·기록한다. AI 명령은 기록하지 않는다(상태에서 다시 나온다).
# 사건: {tick, kind, sq, other, pos, value} — drain_events()로 가져간다. 표현과 로그는 사건만 보고 그린다.

const PROFILE := "poc-red-cliffs-corridor"

var st: BattleState
var rng: BattleRng
var dt := BattleRules.TICK_S
var command_log: Array[Dictionary] = []
var _queue: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _ai := PocEnemyAi.new()
# 초 단위 규칙값의 틱 수(틱 폭에 따라)
var T := {}
var sub_ms := 50

func _init(seed_id: int = 0, hz: int = BattleRules.TICK_HZ) -> void:
	st = BattleState.new()
	st.hz = hz
	st.seed_id = seed_id
	dt = 1.0 / hz
	rng = BattleRng.new("%s|%d" % [PROFILE, seed_id])
	var secs := {
		"MISSILE_CD_S": BattleRules.MISSILE_CD_S, "FIGHTER_CD_S": BattleRules.FIGHTER_CD_S,
		"CHARGE_S": BattleRules.CHARGE_S, "FLANK_MSG_S": BattleRules.FLANK_MSG_S,
		
		
	}
	for k in secs:
		T[k] = BattleRules.ticks(secs[k], hz)
	T.CP_REGEN = BattleRules.ticks(BattleRules.CP_REGEN_S, hz)
	T.ECP_REGEN = BattleRules.ticks(BattleRules.ECP_REGEN_S, hz)
	for d in PocSetup.ALLY_DEF:
		_spawn(d, 0)
	for d in PocSetup.FOE_DEF:
		_spawn(d, 1)

# ============================================================ 공개 API
func queue(cmd: Dictionary) -> void:
	_queue.append(cmd)

func drain_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out

func projection(side: int) -> Dictionary:
	return BattleProjection.build(self, side)

func fingerprint() -> String:
	return BattleFingerprint.of(st)

# 즉시 적용 명령. 틱 사이에 상태는 변하지 않으므로 "다음 step() 첫머리에 적용"과 결과가 같고,
# 재생(replay)도 같은 틱 번호로 같은 결과를 낸다. 화면이 명령 직후 상태를 바로 읽을 수 있다.
func issue(cmd: Dictionary) -> void:
	var c := cmd.duplicate(true)
	c.tick = st.tick
	command_log.append(c)
	apply(c)

# 한 틱 진행. 대기 중인 명령을 먼저 적용한다.
func step() -> void:
	var cmds := _queue
	_queue = []
	for c in cmds:
		c = c.duplicate(true)
		c.tick = st.tick
		command_log.append(c)
		apply(c)
	_tick()

# 명령 기록으로 다시 돌린다(재생). until_tick까지.
static func replay(seed_id: int, hz: int, log: Array, until_tick: int) -> BattleSim:
	var sim := BattleSim.new(seed_id, hz)
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
	f.form_id = st.form_counter
	st.form_counter += 1
	f.form = BattleRules.formation_offsets(f.form_id % BattleRules.FORM_COUNT, 1.0 if f.form_id < BattleRules.FORM_COUNT else 1.35)
	st.fleets.append(f)
	emit("spawn", f.id)
	return f

func _spawn_reinf() -> void:
	st.reinf = true
	st.reinf_ms = st.clock_ms
	for d in PocSetup.REINF_DEF:
		_spawn(d, 1)
	emit("reinforcements")

# ============================================================ 피해
func _rand_ship(f: FleetState, eid: int, sub: int) -> Vector2:
	var i := rng.index(BattleRules.n_ships(f.ships, f.max_ships), st.tick, eid, sub)
	return BattleRules.ship_pos(f.pos, f.heading, f.form, i)

func apply_dmg(src: FleetState, tgt: FleetState, amt: float) -> void:
	if tgt.dead:
		return
	if tgt.defense:
		amt *= 0.6
	var a := mini(roundi(amt), tgt.ships)
	tgt.ships -= a
	if src and not src.dead:
		src.xp += a
		var need := BattleRules.xp_need_milli(src.lv)
		if src.xp >= need and src.lv < 20:
			src.xp -= need
			src.lv += 1
			emit("level_up", src.id, -1, src.pos)
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
	if tgt.ships <= BattleRules.MILLI / 2:
		_kill(tgt, src)

func _kill(f: FleetState, src: FleetState) -> void:
	if f.dead:
		return
	f.dead = true
	f.ships = 0
	for o in st.fleets:
		if o.target_id == f.id:
			o.target_id = -1
	emit("destroyed", f.id, src.id if src else -1, f.pos)

func _fire_missiles(f: FleetState, tgt: FleetState) -> void:
	var eid := st.new_event_id()
	for i in BattleRules.MISSILE_COUNT:
		var m := BattleState.Missile.new()
		m.id = st.new_event_id()
		m.pos = _rand_ship(f, eid, i * 3 + 1)
		m.target_id = tgt.id
		m.src_id = f.id
		m.dmg = roundi(f.ships * 0.03 * BattleRules.power(f.lv, f.charge > 0, f.in_cmd, f.defense) / (0.7 if f.defense else 1.0))
		m.v = 260.0 + rng.unit(st.tick, eid, i * 3 + 2) * 60.0
		m.wob = (rng.unit(st.tick, eid, i * 3 + 3) - 0.5) * 2.4
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
	s.life = BattleRules.SWARM_LIFE_MS
	s.dps = roundi(f.ships * 0.009 * BattleRules.level_mul(f.lv))
	for i in BattleRules.SWARM_POINTS:
		var k := i * 5
		s.pts.append({
			"pos": _rand_ship(f, eid, k + 1),
			"a": rng.unit(st.tick, eid, k + 2) * TAU,
			"r": 20.0 + rng.unit(st.tick, eid, k + 3) * 50.0,
			"w": (-1.0 if rng.bp(st.tick, eid, k + 4) < 5000 else 1.0) * (1.5 + rng.unit(st.tick, eid, k + 5) * 2.0),
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

func _reject(lead: FleetState, reason: String, side: int) -> void:
	emit("rejected", lead.id if lead else -1, side, Vector2.ZERO, reason)

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
	var s := _cmd_fleets(c)
	if s.is_empty():
		_reject(null, "no_selection", side)
		return
	var L := _lead(s)
	match kind:
		"stop":
			for f in s:
				f.target_id = -1
				f.has_move = false
			emit("say", L.id, -1, L.pos, "stop")
		"def":
			var on := false
			for f in s:
				if not f.defense:
					on = true
			for f in s:
				f.defense = on
			emit("say", L.id, -1, L.pos, "def_on" if on else "def_off")
		"def_on":
			for f in s:
				f.defense = true
			emit("say", L.id, -1, L.pos, "ai_def")
		"missile", "fighter":
			_cmd_weapon(c, s, L, kind == "missile")
		"charge":
			if _cp(side) < BattleRules.CHARGE_COST_BP:
				_reject(L, "cp_charge", side)
				return
			_spend(side, BattleRules.CHARGE_COST_BP)
			for f in s:
				f.charge = T.CHARGE_S
				f.defense = false
				if st.live_target(f) == null:
					var t := st.nearest_foe(f, 900.0)
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
				f.move_to = pf.pos + Vector2(cos(a), sin(a)) * 120.0
			emit("say", L.id, -1, L.pos, "rally")
		"retreat":
			var W := BattleRules.WORLD
			for f in s:
				var t := st.nearest_foe(f, 2000.0)
				f.target_id = -1
				var a := atan2(f.pos.y - t.pos.y, f.pos.x - t.pos.x) if t else PI
				f.has_move = true
				f.move_to = Vector2(clampf(f.pos.x + cos(a) * 420.0, 60.0, W.x - 60.0), clampf(f.pos.y + sin(a) * 420.0, 60.0, W.y - 60.0))
			emit("say", L.id, -1, L.pos, "retreat")
		"move":
			# 선택 전체가 현재 배치를 유지한 채 목표 지점으로 이동
			var W := BattleRules.WORLD
			var e := BattleRules.EDGE
			var w: Vector2 = c.point
			var cen := Vector2.ZERO
			for f in s:
				cen += f.pos
			cen /= s.size()
			for f in s:
				var o := f.pos - cen
				f.target_id = -1
				f.has_move = true
				f.move_to = BattleRules.quant_v(Vector2(clampf(w.x + o.x, e, W.x - e), clampf(w.y + o.y, e, W.y - e)))
			emit("say", L.id, -1, L.pos, "move_all" if s.size() > 1 else "move")
		"attack":
			var t := st.by_id(int(c.target_id))
			if t == null or t.dead or t.side == side:
				_reject(L, "bad_target", side)
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

func _cmd_weapon(c: Dictionary, s: Array[FleetState], L: FleetState, missile: bool) -> void:
	var side := int(c.side)
	var cost := BattleRules.MISSILE_COST_BP if missile else BattleRules.FIGHTER_COST_BP
	var reach := BattleRules.MISSILE_R if missile else BattleRules.FIGHTER_R
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
static func _regen(cur: int, rem: int, period: int) -> Array:
	# 1점(10000bp)을 period 틱에 나눠 채운다. 나머지를 넘겨 누적 오차가 없다.
	rem += BattleRules.BP
	cur = mini(BattleRules.CP_MAX_BP, cur + rem / period)
	rem %= period
	return [cur, rem]

func _turn(f: FleetState, a: float) -> void:
	var m := BattleRules.TURN_RATE * dt
	var dh := BattleRules.ang_diff(f.heading, a)
	f.heading += dh if absf(dh) < m else signf(dh) * m

func _tick() -> void:
	st.tick += 1
	var r := _regen(st.cp, st.cp_rem, T.CP_REGEN)
	st.cp = r[0]
	st.cp_rem = r[1]
	r = _regen(st.ecp, st.ecp_rem, T.ECP_REGEN)
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
	if not st.reinf and st.clock_ms > BattleRules.REINF_MS:
		_spawn_reinf()
	st.ai_timer -= sub_ms
	if st.ai_timer <= 0:
		st.ai_timer += BattleRules.AI_PERIOD_MS
		_ai.think(self)
	_fleet_phase(first)
	_separate()
	_move_missiles()
	_move_swarms()
	if st.flag(0) == null:
		_end(false, "flagship_lost")
	elif st.alive(1).is_empty():
		if not st.reinf:
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
		f.in_cmd = fl == null or fl == f or f.pos.distance_to(fl.pos) < BattleRules.CMD_R
		var tgt := st.live_target(f)
		if tgt == null:
			f.target_id = -1
		var has_dest := false
		var dest := Vector2.ZERO
		if tgt:
			if f.pos.distance_to(tgt.pos) > f.range_r * 0.8:
				has_dest = true
				dest = tgt.pos
		elif f.has_move:
			if f.pos.distance_to(f.move_to) < 10.0:
				f.has_move = false
			else:
				has_dest = true
				dest = f.move_to
		var spd := BattleRules.move_speed(f.spd, f.defense, f.charge > 0)
		if has_dest:
			var a := atan2(dest.y - f.pos.y, dest.x - f.pos.x)
			_turn(f, a)
			var dd := f.pos.distance_to(dest)
			if dd < spd * 0.7:
				f.pos += (dest - f.pos) * BattleRules.lerp_k(2.0 * BattleRules.REF_DT, dt)
			else:
				var k := maxf(0.3, cos(BattleRules.ang_diff(f.heading, a)))
				var stp := minf(spd * dt * k, dd)
				f.pos += Vector2(cos(f.heading), sin(f.heading)) * stp
		var ft: FleetState = tgt if (tgt and f.pos.distance_to(tgt.pos) <= f.range_r) else st.nearest_foe(f, f.range_r)
		f.fire_id = ft.id if ft else -1
		if ft:
			if not has_dest:
				_turn(f, atan2(ft.pos.y - f.pos.y, ft.pos.x - f.pos.x))
			var fm := BattleRules.flank_mul(f.pos, ft.pos, ft.heading)
			apply_dmg(f, ft, f.ships * 0.011 * BattleRules.power(f.lv, f.charge > 0, f.in_cmd, f.defense) * fm * dt)
			if fm > 1.0 and f.flank_msg <= 0:
				f.flank_msg = T.FLANK_MSG_S
				emit("flank", f.id, ft.id, ft.pos, fm)

func _separate() -> void:
	var k := BattleRules.lerp_k(4.0 * BattleRules.REF_DT, dt)
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
			var mn := BattleRules.ALLY_GAP if a.side == b.side else BattleRules.FOE_GAP
			if d < mn:
				var p := (mn - d) * 0.5 * k
				a.pos -= dv / d * p
				b.pos += dv / d * p
	var W := BattleRules.WORLD
	var e := BattleRules.EDGE
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
		var a := atan2(t.pos.y - m.pos.y, t.pos.x - m.pos.x) + m.wob * maxf(0.0, 0.6 - age_s)
		m.pos = BattleRules.quant_v(m.pos + Vector2(cos(a), sin(a)) * m.v * dt)
		m.v += 120.0 * dt
		# 명중 판정은 기준 POC와 같은 점 판정이다(이동 뒤 위치가 표적에서 22px 안). 하위 걸음이 0.05초 이하라
		# 한 걸음 이동(≤20px)이 판정 지름(44px)보다 작아 놓치지 않는다. 선분 판정(§3.3)은 걸음이 더 커질 때 쓴다.
		var hit := m.pos.distance_to(t.pos) < BattleRules.MISSILE_HIT_R
		if hit:
			m.dead = true
			apply_dmg(st.by_id(m.src_id), t, m.dmg)
			emit("missile_hit", t.id, m.src_id, m.pos)
	st.missiles = st.missiles.filter(func(m): return not m.dead)

func _move_swarms() -> void:
	var k_goal := BattleRules.lerp_k(2.2 * BattleRules.REF_DT, dt)
	var k_back := BattleRules.lerp_k(2.0 * BattleRules.REF_DT, dt)
	for s in st.swarms:
		s.life -= sub_ms
		var t := st.by_id(s.target_id)
		var src := st.by_id(s.src_id)
		if t.dead or src.dead:
			s.life = mini(s.life, BattleRules.SWARM_RETURN_MS)
		for p in s.pts:
			p.a += p.w * dt
			var goal: Vector2 = t.pos + Vector2(cos(p.a), sin(p.a)) * p.r
			if s.life < BattleRules.SWARM_RETURN_MS:
				p.pos = BattleRules.quant_v(p.pos + (src.pos - p.pos) * k_back)
			else:
				p.pos = BattleRules.quant_v(p.pos + (goal - p.pos) * k_goal)
		s.striking = not t.dead and s.life > BattleRules.SWARM_RETURN_MS and s.pts.size() > 0 and (s.pts[0].pos as Vector2).distance_to(t.pos) < BattleRules.SWARM_HIT_R
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
