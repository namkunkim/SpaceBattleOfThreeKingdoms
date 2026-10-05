class_name MoraleCore
extends RefCounted

# M4 전대·군 사기(제안서 §4.6). 시나리오 프로필(salvo + realtime_rules)일 때만 BattleSim이 만든다.
# 수치는 combat.morale(data/profiles/combat_m3.json)과 시나리오 realtime_rules(morale_events, linked_ships_and_plague)에서 온다.
#
# 전대 사기(bp)는 명중·함선 이탈·역병으로 줄고 사건(결집)으로만 늘어난다. 상태는 사기에서 정해진다:
#   stable(6000+) / shaken(3000~5999) / retreat(1~2999, 공격 불가, 탈출 지점으로 강제 이동) / 0이면 항복(전투에서 빠짐).
# 군 사기 = Σ(전대 사기 × 코스트) / Σ 코스트 − 사건 누적. 퇴각 상태는 현재 사기 그대로, 항복·격침·탈출은 0으로 센다.

var sim: BattleSim
var M: Dictionary
var plague_ticks := 0
var crisis_sent := [false, false]
var rally_uses: Dictionary = {}     # 결집 ID → 남은 횟수
var plague_bp_total := 0            # 통계(역병으로 잃은 사기 합)
var recoveries := 0                 # 통계(사건 회복 횟수)
var _cost_total := [0, 0]
var _dispersed: Array = []
var _plague: Dictionary = {}

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	M = cfg
	_plague = sim.rs.rt("linked_ships_and_plague", {})
	_dispersed = sim.rs.rt("formation_classes.dispersed", [])
	plague_ticks = BattleRules.ticks(float(_plague.get("plague_interval_s", 0)), sim.st.hz)
	for r in sim.rs.rt("morale_events.rally", []):
		rally_uses[r.id] = int(r.get("uses", 1))
	for f in sim.st.fleets:
		_cost_total[f.side] += f.cost0

# ============================================================ 질의
func collapse_bp() -> int:
	return int(sim.rs.rt("morale_events.collapse_threshold_bp", 0))

func crisis_bp() -> int:
	return int(sim.rs.rt("morale_events.crisis_threshold_bp", 0))

# 군 사기(bp). 진영 단위이고 연합은 하나다.
func army_bp(side: int) -> int:
	if _cost_total[side] <= 0:
		return 0
	var num := 0
	for f in sim.st.fleets:
		if f.side == side and f.out == "":
			num += f.morale_bp * f.cost0
	return clampi(num / _cost_total[side] - int(sim.st.army_ev[side]), 0, BattleRules.BP)

func exit_point(side: int) -> Vector2:
	var p: Dictionary = sim.rs.scenario.get("escape_points", {}).get(sim.salvo.C.victory.exit_key_by_side[side], {})
	var a: Array = p.get("position", [0, 0])
	return Vector2(float(a[0]), float(a[1]))

func exit_radius(side: int) -> float:
	return float(sim.rs.scenario.get("escape_points", {}).get(sim.salvo.C.victory.exit_key_by_side[side], {}).get("arrival_radius", 0))

func at_exit(f: FleetState) -> bool:
	return f.pos.distance_to(exit_point(f.side)) <= exit_radius(f.side)

# 강제 퇴각 중이다(사기 상태). 플레이어의 후퇴 명령(retreat_order)은 따로다.
func forced(f: FleetState) -> bool:
	return f.mstate == "retreat" and f.out == ""

func fleeing(f: FleetState) -> bool:
	return forced(f) or f.retreat_order

# ============================================================ 사기 감소
# 명중 1회(§4.6): max(300, ceil(피해 × 10000 / (최대 선체 × 5))) × 거리대 가중 × 방향 가중 × (연환 ×0.8) × (보급함 ×0.6, 결착)
func hit(tgt: FleetState, loss: int, wband: String, sector: String) -> void:
	if loss <= 0 or tgt.out != "":
		return
	var h: Dictionary = M.hit
	var denom: int = tgt.max_hull * int(h.hull_div)
	var base := maxi(int(h.min_bp), (loss * BattleRules.BP + denom - 1) / denom)
	var bp := base * int(h.band_weight_bp[wband]) / BattleRules.BP * int(h.sector_weight_bp[sector]) / BattleRules.BP
	if _linked(tgt):
		bp = bp * _linked_mul_bp() / BattleRules.BP
	var rel: Dictionary = M.supply_relief
	if wband == rel.band and _supply_share_bp(tgt) >= int(rel.min_share_bp):
		bp = bp * int(rel.loss_mul_bp) / BattleRules.BP
	lose(tgt, bp)

func ship_departed(f: FleetState) -> void:
	lose(f, int(M.ship_departure_bp))

# 감소를 적용한다. 결집 효과 중이면 배율을 곱한다.
func lose(f: FleetState, bp: int) -> void:
	if sim.st.tick < f.loss_mul_until:
		bp = bp * f.loss_mul_bp / BattleRules.BP
	f.morale_bp = maxi(0, f.morale_bp - bp)

func _linked(f: FleetState) -> bool:
	return f.morale_group != "" and sim.rs.rt("formation_classes.dense", []).has(f.formation_id)

func _linked_mul_bp() -> int:
	return roundi(float(_plague.get("dense_cao_morale_loss_mul", 1.0)) * BattleRules.BP)

func _supply_share_bp(f: FleetState) -> int:
	var n := sim.salvo.present_ships(f)
	if n <= 0:
		return 0
	var t: String = M.supply_relief.ship_type_id
	return sim.salvo.present_of(f, t) * BattleRules.BP / n if f.stages.has(t) else 0

# ============================================================ 결집 (전투당 1회, 반경 안 아군 전대)
# 결집 크기는 지휘관 매력에 비례한다(+1200 × 매력 / 99). 데이터에 매력이 없으면 99(만점)로 본다.
func rally(side: int, rally_id: String) -> String:
	var def := {}
	for r in sim.rs.rt("morale_events.rally", []):
		if r.id == rally_id:
			def = r
	if def.is_empty():
		return "unknown_rally"
	if int(rally_uses.get(rally_id, 0)) <= 0:
		return "rally_used"
	var src: FleetState = null
	for f in sim.st.fleets:
		if f.sq_id == def.squadron_id and f.side == side and f.out == "":
			src = f
	if src == null or (sim.cmd and sim.cmd.incapacitated(src) and src.cmdr_sub == ""):
		return "rally_no_source"   # 결집하는 지휘관이 지휘 불능이고 이은 사람도 없으면 못 한다(M9)
	rally_uses[rally_id] -= 1
	var e: Dictionary = sim.rs.rt("morale_events.rally_effect", {})
	var gain := int(e.morale_bp_at_charm_99) * int(def.get("charm", M.rally_charm_max)) / int(M.rally_charm_max)
	for f in sim.st.fleets:
		if f.side == side and f.out == "" and f.pos.distance_to(src.pos) <= float(e.radius):
			f.morale_bp = mini(BattleRules.BP, f.morale_bp + gain)
			f.loss_mul_until = sim.st.tick + BattleRules.ticks(float(e.loss_mul_s), sim.st.hz)
			f.loss_mul_bp = roundi(float(e.loss_mul) * BattleRules.BP)
	recoveries += 1
	sim.emit("rally", src.id, -1, src.pos, {"id": rally_id, "gain": gain})
	return ""

# ============================================================ 틱
func step() -> void:
	var st := sim.st
	if plague_ticks > 0 and st.tick % plague_ticks == 0:
		_plague_tick()
	for f in st.fleets:
		if f.out != "":
			continue
		_update_state(f)
	for side in 2:
		if not crisis_sent[side] and army_bp(side) < crisis_bp():
			crisis_sent[side] = true
			sim.emit("morale_crisis", -1, side, Vector2.ZERO, army_bp(side))

# 역병: 분산 진형 북방군은 10초마다 사기 −40bp(§4.7). 투입 전 전대는 받지 않는다.
func _plague_tick() -> void:
	var grp: String = _plague.get("plague_group", "")
	for f in sim.st.fleets:
		if f.out != "" or f.morale_group != grp or not _dispersed.has(f.formation_id) or sim.st.tick < f.wait:
			continue
		var before := f.morale_bp
		lose(f, int(_plague.plague_loss_bp))
		plague_bp_total += before - f.morale_bp

func _update_state(f: FleetState) -> void:
	var prev := f.mstate
	if f.morale_bp <= 0:
		_count_exit(f)
		sim.remove_fleet(f, "surrender")
		return
	var s: Dictionary = M.state_bp
	var ns := "stable"
	if f.morale_bp < int(s.retreat_below):
		ns = "retreat"
	elif f.morale_bp < int(s.stable_min):
		ns = "shaken"
	if ns != prev:
		f.mstate = ns
		sim.emit("morale_state", f.id, -1, f.pos, {"from": prev, "to": ns})
	if ns == "retreat":
		_count_exit(f)
	if at_exit(f):
		f.arrived = true
	# 탈출: 퇴각 중(강제 또는 명령)인 전대가 자기 탈출 지점에 닿으면 전투에서 빠진다. 기함은 남는다(승패 판정이 다룬다).
	if fleeing(f) and not f.is_flag and at_exit(f):
		sim.remove_fleet(f, "escaped")

# 전대의 퇴각·항복은 군 사기 사건이다(한 번): 자기 진영 −500, 상대 진영 회복 +300
func _count_exit(f: FleetState) -> void:
	if f.retreat_counted:
		return
	f.retreat_counted = true
	var ev: Dictionary = sim.rs.rt("morale_events", {})
	var st := sim.st
	st.army_ev[f.side] += int(ev.army_loss_bp.own_squadron_retreat_or_surrender)
	var o := 1 - f.side
	st.army_ev[o] = maxi(0, int(st.army_ev[o]) - int(ev.army_recovery_bp.enemy_squadron_retreat_or_surrender))
	recoveries += 1
