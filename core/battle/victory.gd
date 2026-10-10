class_name Victory
extends RefCounted

# M4 승패(제안서 §4.12). 매 초(check_period_s) 한 번 판정하고, 확정하면 결산(st.result)을 만들어 전투를 끝낸다.
# 진영 0은 연합(유비 + 손권, 하나의 군 사기), 진영 1은 조조군이다. 수치는 combat.victory와 시나리오 데이터에서 온다.
#
# 연합 패배: 유비 기함 선체 0·항복 / 유비군 코스트 손실 70% / 연합 결합 코스트 손실 70% / 유비군 전 전대 소멸 / 연합 군 사기 붕괴
# 연합 승리: 조조 기함 선체 0·항복 / 조조 기함이 조조군 탈출 지점 도달 / 조조군 코스트 손실 70% / 전 전대 소멸 / 조조군 군 사기 붕괴
# 제한적 승리: 유비 기함과 함대 전체가 연합 탈출 지점에 도달
# 20분 시계: 시간 안에 승패가 안 나면 연합 패배(코스트 비교 없음). 같은 시점에 양쪽이 성립하면 조조군.

const REASONS := ["liu_flagship_lost", "cao_flagship_lost", "cao_escaped", "alliance_escaped", "liu_cost_loss", "alliance_cost_loss",
	"cao_cost_loss", "liu_eliminated", "cao_eliminated", "alliance_morale_collapse", "cao_morale_collapse", "time_limit", "simultaneous"]

var sim: BattleSim
var V: Dictionary
var period := 0
var anchor_faction := ""    # 플레이어(유비) 세력

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	V = cfg
	period = BattleRules.ticks(float(V.check_period_s), sim.st.hz)
	var f := flag_fleet(0)
	if f:
		anchor_faction = f.faction

# 기함 전대(전투에서 빠졌어도 찾는다)
func flag_fleet(side: int) -> FleetState:
	for f in sim.st.fleets:
		if f.is_flag and f.side == side:
			return f
	return null

# ============================================================ 코스트
func cost_present(f: FleetState) -> int:
	var n := 0
	for t in f.stages:
		n += sim.salvo.present_of(f, t) * int(sim.salvo.C.ship_types[t].cost)
	return n

# 잔존 코스트: 이탈하지 않은 척의 함종 비용 합(임무장비 제외). 항복·탈출은 cost_policy에 따른다.
func cost_remaining(f: FleetState) -> int:
	if f.out == "sunk":
		return 0
	if f.out != "" and str(V.cost_policy[f.out]) == "lost":
		return 0
	return cost_present(f)

# {original, remaining, loss_bp}. who: "alliance" | "foe" | "anchor"
func cost_of(who: String) -> Dictionary:
	var o := 0
	var r := 0
	for f in sim.st.fleets:
		var hit := false
		match who:
			"alliance":
				hit = f.side == 0
			"foe":
				hit = f.side == 1
			"anchor":
				hit = f.side == 0 and f.faction == anchor_faction
		if hit:
			o += f.cost0
			r += cost_remaining(f)
	return {"original": o, "remaining": r, "loss_bp": ((o - r) * BattleRules.BP / o) if o > 0 else 0}

func _eliminated(side: int, faction := "") -> bool:
	var any := false
	for f in sim.st.fleets:
		if f.side == side and (faction == "" or f.faction == faction):
			any = true
			if f.out == "":
				return false
	return any

# ============================================================ 판정
# 반환: {alliance: [사유], foe: [사유], limited: bool}
func conditions() -> Dictionary:
	var a: Array[String] = []
	var c: Array[String] = []
	var lf := flag_fleet(0)
	var cf := flag_fleet(1)
	var lim := int(V.loss_bp)
	if lf and (lf.out == "sunk" or lf.out == "surrender"):
		a.append("liu_flagship_lost")
	if cost_of("anchor").loss_bp >= lim:
		a.append("liu_cost_loss")
	if cost_of("alliance").loss_bp >= lim:
		a.append("alliance_cost_loss")
	if _eliminated(0, anchor_faction):
		a.append("liu_eliminated")
	if sim.morale.army_bp(0) < sim.morale.collapse_bp():
		a.append("alliance_morale_collapse")
	if cf and (cf.out == "sunk" or cf.out == "surrender"):
		c.append("cao_flagship_lost")
	if cf and cf.out == "" and sim.morale.at_exit(cf):
		c.append("cao_escaped")
	if cost_of("foe").loss_bp >= lim:
		c.append("cao_cost_loss")
	if _eliminated(1):
		c.append("cao_eliminated")
	if sim.morale.army_bp(1) < sim.morale.collapse_bp():
		c.append("cao_morale_collapse")
	return {"alliance": a, "foe": c, "limited": _alliance_escaped()}

# 유비 기함 함대가 탈출 지점에 닿았다(편제 한 단계, Q73: 다른 함대는 조건이 아니다)
func _alliance_escaped() -> bool:
	var lf := flag_fleet(0)
	return lf != null and lf.out == "" and lf.arrived

func check() -> void:
	var st := sim.st
	if st.over or (st.tick % period) != 0:
		return
	var cond := conditions()
	var a_def: Array = cond.alliance
	var c_def: Array = cond.foe
	if not a_def.is_empty() and not c_def.is_empty():
		_finish(false, "simultaneous", false, cond)
	elif not a_def.is_empty():
		_finish(false, a_def[0], false, cond)
	elif not c_def.is_empty():
		_finish(true, c_def[0], false, cond)
	elif cond.limited:
		_finish(true, "alliance_escaped", true, cond)
	elif st.clock_ms >= int(V.time_limit_s) * BattleRules.MILLI:
		_finish(false, "time_limit", false, cond)   # 시간 초과는 코스트와 무관하게 패배

# ============================================================ 결산
func _finish(win: bool, reason: String, limited: bool, cond: Dictionary) -> void:
	sim.st.result = settle(win, reason, limited, cond)
	sim._end(win, reason)

func settle(win: bool, reason: String, limited: bool, cond: Dictionary) -> Dictionary:
	var st := sim.st
	var fleets: Array = []
	var failed: Array = []
	var loser := 1 if win else 0
	for f in st.fleets:
		var row := {"sq": f.sq_id, "side": f.side, "out": f.out, "mstate": f.mstate, "morale_bp": f.morale_bp,
			"ships_left": sim.salvo.present_ships(f), "cost_left": cost_remaining(f), "cost0": f.cost0}
		# G8-04 6행: 승패가 확정될 때 강제 퇴각 중이고 자기 탈출 지점 밖인 패배측 전대는 포로(퇴각 실패)
		if f.side == loser and f.out == "" and sim.morale.fleeing(f) and not sim.morale.at_exit(f):
			failed.append(f.sq_id)
		fleets.append(row)
	return {
		"win": win, "winner_side": 0 if win else 1, "reason": reason, "limited": limited,
		"t_s": st.clock_s(), "tick": st.tick,
		"cost": {"alliance": cost_of("alliance"), "anchor": cost_of("anchor"), "foe": cost_of("foe")},
		"army_morale_bp": [sim.morale.army_bp(0), sim.morale.army_bp(1)],
		"conditions": {"alliance": cond.alliance.duplicate(), "foe": cond.foe.duplicate()},
		"commanders": {"alliance": commander_fate(flag_fleet(0)), "foe": commander_fate(flag_fleet(1))},
		"captured_in_retreat": failed,
		"casualties": _casualties(failed),
		"fleets": fleets,
	}

# 기함 지휘관의 운명(G8-04 1~3행). 값: unhurt | captured | killed | severe(중상 생환).
# 격침이면 ① 같은 틱 연쇄 폭발 → 전사 ② 반경 안 아군 구조 장비 전대 → 중상 ③ 반경 안 적 작전 가능 전대 없음 → 중상
# ④ 가장 가까운 아군이 가장 가까운 적 이하 거리(동거리면 아군) → 중상 ⑤ 그 외 포로. 항복은 포로.
func commander_fate(f: FleetState) -> String:
	if f == null:
		return "unhurt"
	if f.out == "surrender":
		return "captured"
	if f.out != "sunk":
		return "unhurt"
	if f.chain_sunk:
		return "killed"
	var rad: float = float(sim.rs.rt("commander_casualties.rescue_radius", 0))
	var near_f := 1e9
	var near_e := 1e9
	for o in sim.st.fleets:
		if o == f or o.out != "" or sim.morale.forced(o):
			continue
		var d := f.died_pos.distance_to(o.pos)
		if o.side == f.side:
			near_f = minf(near_f, d)
			if d <= rad and o.equip == str(V.commander.rescue_equipment):
				return "severe"
		else:
			near_e = minf(near_e, d)
	if near_e > rad:
		return "severe"
	return "severe" if near_f <= near_e else "captured"

# M9 장수 사상 전체(G8-04): 상태가 바뀐 전대 지휘관과 이은 사람. 퇴각 실패(6행)는 포로로 적는다
func _casualties(failed: Array) -> Array:
	var out := []
	if sim.cmd == null:
		return out
	for f in sim.st.fleets:
		var s := "captured" if failed.has(f.sq_id) else f.cmdr_state
		if s != "unhurt" or f.cmdr_sub != "":
			out.append({"sq": f.sq_id, "person": f.commander_id, "state": s, "sub": f.cmdr_sub})
	return out
