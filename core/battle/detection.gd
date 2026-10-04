class_name Detection
extends RefCounted

# M6 탐지와 전쟁 안개(제안서 §4.9). 진영 단위 접촉표: 같은 진영의 모든 전대가 센서를 합친다(Q46).
# 점수 = round_half_up(함종 센서 합 × (100 + 진형 탐지% + 지형 센서%) / 100) + 지력 구간 − 표적 전자전 − floor(거리 / 25) − 표적 은폐
# 확인 ≥ 37, 추정 ≥ 15, 그 아래 미탐지. 수치는 combat.detection, 신뢰도 시작값은 시나리오 realtime_rules.fog_override.
#
# 접촉 상태: confirmed(점수 확인) · estimated(점수 추정, 또는 놓친 뒤 기억 시간 안) · lost(기억이 끝난 뒤 한 번 더, 사격 불가) · 없음.
# 접촉 기록: {seen(마지막으로 점수를 받은 틱), pos(그때의 위치), state, conf_bp, err_r}.
# 평가는 eval_period_s마다 한 번 한다(첫 평가는 1틱). 전대 데이터는 센서·전자전·진형·위치만 읽는다.

var sim: BattleSim
var D: Dictionary
var terr: BattleTerrain
var contacts: Array = [{}, {}]     # 진영 → {표적 ID: 접촉 기록}
var _period := 1
var _conf0 := 0

func _init(s: BattleSim, cfg: Dictionary, t: BattleTerrain) -> void:
	sim = s
	D = cfg
	terr = t
	_period = maxi(1, BattleRules.ticks(float(D.eval_period_s), s.st.hz))
	_conf0 = int(s.rs.rt("fog_override.estimated_confidence_basis_points", D.confidence_bp))

# ============================================================ 질의
func rec(side: int, id: int) -> Dictionary:
	return contacts[side].get(id, {})

func state(side: int, id: int) -> String:
	return str(rec(side, id).get("state", ""))

# 쏘거나 표적으로 삼을 수 있는 접촉(확인 · 추정)
func can_target(side: int, id: int) -> bool:
	var s := state(side, id)
	return s == "confirmed" or s == "estimated"

# 사격 조준점(M7). 확인 접촉은 실제 위치, 추정 접촉은 마지막으로 안 위치. 접촉이 없으면 실제 위치(호출 쪽이 막는다)
func aim_pos(side: int, t: FleetState) -> Vector2:
	var r := rec(side, t.id)
	return t.pos if r.is_empty() or r.state == "confirmed" else r.pos

# 조준점이 실제 위치와 이만큼 어긋나도 맞는다(접촉 오차 반경). 확인 접촉은 오차가 0이라 제한이 없다
func aim_tol(side: int, id: int) -> float:
	var r := rec(side, id)
	return 1e9 if r.is_empty() or r.state == "confirmed" else float(r.err_r)

# 추정 사격의 명중 배율(bp). 확인은 1.0
func hit_mul_bp(side: int, id: int) -> int:
	var r := rec(side, id)
	return BattleRules.BP if r.get("state", "") == "confirmed" else int(r.get("conf_bp", 0))

# 진영이 아는 적 목록(확인 · 추정 · 상실), ID 순. {id, state, pos, conf_bp, err_r, ships_milli, max_ships_milli}
# ships는 확인 접촉만 준다(정확한 값이 아니라 호출 쪽이 구간으로 줄인다).
func foes(side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var ids: Array = contacts[side].keys()
	ids.sort()
	for id in ids:
		var r: Dictionary = contacts[side][id]
		var t := sim.st.by_id(id)
		if t.dead:
			continue
		out.append({"id": id, "state": r.state, "pos": r.pos, "conf_bp": r.conf_bp, "err_r": r.err_r,
			"ships_milli": t.ships if r.state == "confirmed" else -1, "max_ships_milli": t.max_ships if r.state == "confirmed" else -1})
	return out

# 확인 접촉에 공개하는 전력 구간(1~strength_bands): 남은 척 수 비율을 올림한다. 정확한 척 수는 공개하지 않는다(§4.9).
func strength_band(t: FleetState) -> int:
	return clampi(ceili(float(D.strength_bands) * float(t.ships) / float(t.max_ships)), 1, int(D.strength_bands))

# ============================================================ 점수
func _count(f: FleetState, t: String) -> int:
	return sim.salvo.present_of(f, t) if f.stages.has(t) else 0

func _sum(f: FleetState, ship_pts: Dictionary, equip_pts: Dictionary) -> int:
	var n := 0
	for t in f.comp0:
		n += _count(f, t) * int(ship_pts.get(t, 0))
	if f.equip != "":
		n += _count(f, sim.salvo.C.fast_craft.ship_type_id) * int(equip_pts.get(f.equip, 0))
	return n

func sensor_of(f: FleetState) -> int:
	var bp: int = int(sim.salvo.C.formations[sim.salvo._form_id(f)].detection_bp)
	var lim: Array = D.sensor_bp_clamp
	bp += terr.sensor_bp(f.pos, int(lim[0]), int(lim[1]))
	var ship := _sum(f, D.ship_sensor, D.equip_sensor)
	var s := (ship * (BattleRules.BP + bp) + BattleRules.BP / 2) / BattleRules.BP
	var iq := int(f.stats.get("intellect", 0))
	for b in D.intellect_bands:
		if iq >= int(b.min) and iq <= int(b.max):
			s += int(b.sensor_points)
	return s

func ew_of(f: FleetState) -> int:
	return _sum(f, D.ship_ew, D.equip_ew)

func score(sensor: int, obs: FleetState, tgt: FleetState) -> int:
	return sensor - ew_of(tgt) - floori(obs.pos.distance_to(tgt.pos) / float(D.distance_units_per_point)) - terr.conceal(tgt.pos)

# 0 미탐지 · 1 추정 · 2 확인
func level_of(sc: int) -> int:
	if sc >= int(D.confirmed):
		return 2
	if sc >= int(D.estimated):
		return 1
	return 0

# ============================================================ 한 틱
func step() -> void:
	var st := sim.st
	if (st.tick - 1) % _period != 0:
		return
	for side in 2:
		_eval(side)

func _eval(side: int) -> void:
	var st := sim.st
	var obs: Array[FleetState] = []
	var sens: Array[int] = []
	for o in st.fleets:
		if o.side == side and not o.dead and o.max_hull > 0:
			obs.append(o)
			sens.append(sensor_of(o))
	var book: Dictionary = contacts[side]
	for t in st.fleets:
		if t.side == side or t.max_hull == 0:
			continue
		if t.dead:
			_store(side, t, book, {})
			continue
		var best := 0
		for i in obs.size():
			best = maxi(best, level_of(score(sens[i], obs[i], t)))
		var r: Dictionary = book.get(t.id, {})
		if best > 0:
			r = {"seen": st.tick, "pos": t.pos}
		if r.is_empty():
			continue
		var age := st.tick - int(r.seen)
		var turn := BattleRules.ticks(float(D.turn_s), st.hz)
		var mem := BattleRules.ticks(float(D.memory_s), st.hz)
		var lost := mem + BattleRules.ticks(float(D.lost_s), st.hz)
		var n := age / turn
		var nr := {"seen": r.seen, "pos": r.pos, "state": "", "conf_bp": 0, "err_r": float(D.error_radius) + float(D.error_radius_per_turn) * n}
		if best == 2:
			nr.state = "confirmed"
			nr.conf_bp = BattleRules.BP
			nr.err_r = 0.0
		elif best == 1 or age <= mem:
			nr.state = "estimated"
			nr.conf_bp = maxi(int(D.confidence_min_bp), _conf0 - int(D.confidence_loss_bp_per_turn) * n)
		elif age <= lost:
			nr.state = "lost"
		else:
			nr = {}
		_store(side, t, book, nr)

func _store(side: int, t: FleetState, book: Dictionary, nr: Dictionary) -> void:
	var was := str(book.get(t.id, {}).get("state", ""))
	if nr.is_empty():
		book.erase(t.id)
	else:
		book[t.id] = nr
	var now := str(nr.get("state", ""))
	if side == 0 and now != was:
		sim.emit("contact", t.id, -1, nr.get("pos", t.pos), {"state": now if now != "" else "none", "was": was if was != "" else "none"})
