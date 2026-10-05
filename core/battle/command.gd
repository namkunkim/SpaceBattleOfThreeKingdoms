class_name CommandCore
extends RefCounted

# M9 장수 사상과 지휘 승계(제안서 §4.14, 본편 V-74 / G8-04). 시나리오 프로필에 combat.command가 있을 때만 켜진다.
# 수치: combat.command(지휘 한도·선체 구간), realtime_rules.commander_succession(혼선), commander_casualties(판정표).
#
# 전대 지휘관 상태(cmdr_state)는 사건이 일어난 틱에 위에서부터 처음 맞는 줄로 정하고, 악화 방향으로만 바뀐다.
#   항복 → 포로 · 격침 → Victory.commander_fate(연쇄 폭발 전사 / 중상 생환 / 포로) · 남은 척 < 40% 중상 · < 75% 경상
#   2행(표류 고속정 나포)은 고속정 표류가 없어 없다(후속). 6행(퇴각 실패)은 결산이 다룬다.
# 지휘 불능(중상·전사·포로):
#   전대: 부지휘관 → 첫 참모가 능력치를 잇는다. 아무도 없으면 그 전대는 전투 끝까지 혼선이다.
#   함대: 제독이 지휘 불능이면 부함장 → 소속 전대 지휘관(레벨 → 통솔 → 전대 ID). 승계하면 함대 전대들이 60초 혼선,
#         후보가 없으면 끝까지 혼선(지휘 공백). 부함장이 아닌 사람이 이으면 그 사람의 전대가 함대 기함이 된다.
#         승패의 기함(is_flag, 유비·조조가 탄 전대)과 지휘 범위(in_cmd)는 그대로다.
# 불이익 단계 = 혼선 2단계 + 지휘 한도 초과 단계(남은 척의 함종 비용 합이 40 + 통솔 × 2를 넘으면 한도의 25%마다 1단계), 상한 4.
#   단계마다 기동 −5%, 명중 −4%, 진형 변경 속도 −8%.

const RANK := {"unhurt": 0, "light": 1, "severe": 2, "killed": 3, "captured": 3}
const FOREVER := int(1e9)   # 틱(전투 끝까지)

var sim: BattleSim
var K: Dictionary            # combat.command
var S: Dictionary            # realtime_rules.commander_succession
var groups: Array[Dictionary] = []   # {id, side, members: [sq_id], vice, leader, flag_sq, leaderless, done_vice}
var stats := {"succession": 0, "leaderless": 0, "severe": 0, "light": 0}

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	K = cfg
	S = sim.rs.rt("commander_succession", {})
	for g in sim.rs.scenario.get("fleet_groups", []):
		var flag := _by_sq(str(g.flagship_squadron_id))
		if flag == null:
			continue   # 이 난이도에 배치되지 않은 함대
		groups.append({"id": g.id, "side": flag.side, "members": g.squadron_ids, "vice": str(g.vice_admiral) if g.vice_admiral != null else "",
			"leader": str(g.admiral), "flag_sq": flag.sq_id, "aboard": false, "leaderless": false})

func _by_sq(sq: String) -> FleetState:
	for f in sim.st.fleets:
		if f.sq_id == sq:
			return f
	return null

func incapacitated(f: FleetState) -> bool:
	return int(RANK[f.cmdr_state]) >= 2

# ============================================================ 불이익
func confused(f: FleetState) -> bool:
	return sim.st.tick < f.confuse_until

func limit_tier(f: FleetState) -> int:
	var lim := int(K.limit_base) + int(K.limit_per_command) * f.cmd_stat
	var cost := 0
	for t in f.stages:
		cost += sim.salvo.present_of(f, t) * int(sim.salvo.C.ship_types[t].cost)
	if cost <= lim or lim <= 0:
		return 0
	return mini(int(K.max_tier), ceili(float(cost - lim) / (float(lim) * float(K.over_tier_ratio))))

func stages(f: FleetState) -> int:
	var c: Dictionary = S.confusion
	return mini(int(c.max_stage), (int(c.penalty_stage_equivalent) if confused(f) else 0) + limit_tier(f))

# 단계 효과(비율, 음수). key: move_pct | hit_pct | formation_change_pct
func penalty(f: FleetState, key: String) -> float:
	var n := stages(f)
	return 0.0 if n == 0 else float(n) * float(S.confusion.effect_per_stage[key]) / BattleRules.PCT

# ============================================================ 한 틱
func step() -> void:
	for f in sim.st.fleets:
		if f.max_hull == 0 or int(RANK[f.cmdr_state]) >= 3:
			continue
		var ns := f.cmdr_state
		if f.out == "surrender":
			ns = "captured"
		elif f.out == "sunk":
			ns = sim.victory.commander_fate(f) if sim.victory else "captured"
		elif f.out == "":
			var r := sim.salvo.present_ships(f) * BattleRules.BP / maxi(1, sim.salvo.total0(f))
			if r < int(K.injury_bp.severe_below):
				ns = "severe"
			elif r < int(K.injury_bp.light_below):
				ns = "light"
		_worsen(f, ns)
	for g in groups:
		_check_group(g)

# 규칙 밖에서 상태를 정한다(기함 진입 성공 → 중상). 악화 방향만
func force_state(f: FleetState, ns: String) -> void:
	_worsen(f, ns)

func _worsen(f: FleetState, ns: String) -> void:
	if int(RANK[ns]) <= int(RANK[f.cmdr_state]):
		return
	f.cmdr_state = ns
	if stats.has(ns):
		stats[ns] += 1
	sim.emit("commander_status", f.id, -1, f.pos, {"person": f.commander_id, "state": ns})
	if int(RANK[ns]) >= 2 and f.out == "":
		_substitute(f)

# 전대 지휘관이 지휘 불능: 부지휘관 → 첫 참모가 능력치를 잇는다. 지휘 한도는 이 통솔로 다시 계산된다
func _substitute(f: FleetState) -> void:
	var sub: Dictionary = f.vice if not f.vice.is_empty() else (f.staff[0] if not f.staff.is_empty() else {})
	if sub.is_empty():
		f.confuse_until = FOREVER
		sim.emit("confusion", f.id, -1, f.pos, {"s": -1})
		return
	f.cmdr_sub = str(sub.id)
	f.cmd_stat = int(sub.get("command", f.cmd_stat))
	f.stats = {"command": f.cmd_stat, "might": int(sub.get("might", f.cmd_stat)), "intellect": int(sub.get("intellect", f.cmd_stat))}
	f.traits = sub.get("traits", [])
	sim.emit("commander_sub", f.id, -1, f.pos, {"person": f.cmdr_sub})

# ============================================================ 함대 승계
func _check_group(g: Dictionary) -> void:
	if g.leaderless:
		return
	var L := _by_sq(g.flag_sq)
	if L == null:
		return
	var down: bool = L.out == "sunk" or L.out == "surrender"
	if not g.aboard and L.commander_id == g.leader:
		down = down or incapacitated(L)
	if not down:
		return
	var pick := _successor(g, L)
	var st := sim.st
	var until := st.tick + BattleRules.ticks(float(S.confusion.duration_s), st.hz)
	if pick.is_empty():
		g.leaderless = true
		until = FOREVER
		stats.leaderless += 1
	else:
		g.leader = pick.person
		g.flag_sq = pick.sq
		g.aboard = pick.aboard
		stats.succession += 1
	for sq in g.members:
		var f := _by_sq(sq)
		if f and f.out == "":
			f.confuse_until = maxi(f.confuse_until, until)
	sim.emit("succession", L.id, -1, L.pos, {"group": g.id, "to": pick.get("person", ""), "flag_sq": g.flag_sq, "leaderless": g.leaderless})

# {person, sq, aboard} 또는 빈 사전
func _successor(g: Dictionary, L: FleetState) -> Dictionary:
	var v: String = g.vice
	if v != "" and v != g.leader:
		g.vice = ""   # 부함장은 한 번만 잇는다
		var on_flag := str(L.vice.get("id", "")) == v or L.staff.any(func(p): return str(p.id) == v)
		if on_flag and L.out == "":
			return {"person": v, "sq": L.sq_id, "aboard": true}   # 기함에 동승: 기함은 그대로
		for sq in g.members:
			var f := _by_sq(sq)
			if f and f.commander_id == v and _able(f):
				return {"person": v, "sq": f.sq_id, "aboard": false}
	var best: FleetState = null
	for sq in g.members:
		var f := _by_sq(sq)
		if f == null or f == L or not _able(f):
			continue
		if best == null or f.level > best.level or (f.level == best.level and (f.cmd_stat > best.cmd_stat or (f.cmd_stat == best.cmd_stat and f.sq_id < best.sq_id))):
			best = f
	return {} if best == null else {"person": best.commander_id, "sq": best.sq_id, "aboard": false}

func _able(f: FleetState) -> bool:
	return f.out == "" and not incapacitated(f) and not (sim.morale and sim.morale.forced(f))

# ============================================================ 투영·지문
func group_view(side: int) -> Array:
	var out := []
	for g in groups:
		if g.side == side:
			out.append({"id": g.id, "leader": g.leader, "flag_sq": g.flag_sq, "leaderless": g.leaderless})
	return out

func fingerprint() -> String:
	var parts := PackedStringArray()
	for f in sim.st.fleets:
		parts.append("%d.%s.%s.%d" % [f.id, f.cmdr_state, f.cmdr_sub, f.confuse_until])
	for g in groups:
		parts.append("%s.%s.%s" % [g.id, g.leader, g.flag_sq])
	return "|cmd" + ",".join(parts)
