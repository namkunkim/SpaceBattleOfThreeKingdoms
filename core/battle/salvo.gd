class_name SalvoCombat
extends RefCounted

# M3 사격과 피해(제안서 §4.3~§4.5, §4.8). 전대는 무기 범주마다 60초에 한 번 일제사격하고, 판정은 한 번이다.
# 규칙 수치는 모두 data/profiles/combat_m3.json의 `combat`(= rs.c)에서 온다. 이 파일에는 구조 값만 있다.
# BattleSim이 combat 사전을 가진 프로필일 때만 만든다(POC 프로필에는 없다).
#
# 한 틱의 순서: 자원 회복 → 전대마다 범주별 사격 계획(표적·플랫폼·자원) → 같은 틱의 피해를 피해 전 스냅숏으로 계산
# → 표적별로 적용(선체 → 손실 척 수 → 방향 배분 → 손상 단계).

const STAGE_N := 5        # 무손상, 경파, 중파, 대파, 격침
const STAGE_HEAVY := 3
const STAGE_SUNK := 4

var sim: BattleSim
var C: Dictionary

func _init(s: BattleSim, combat: Dictionary) -> void:
	sim = s
	C = combat

# ============================================================ 편성
# 전대 정의 d({composition, formation_id, command, start_morale_bp, ...})로 salvo 상태를 채운다.
func init_fleet(f: FleetState, d: Dictionary) -> void:
	f.formation_id = d.get("formation_id", C.default_formation)
	f.cmd_stat = int(d.get("command", 0))
	# 지휘관 능력치(거리대별 보정, §4.3). 데이터에 없는 능력치는 통솔로 대신한다
	f.stats = {"command": f.cmd_stat, "might": int(d.get("might", f.cmd_stat)), "intellect": int(d.get("intellect", f.cmd_stat))}
	f.morale_bp = int(d.get("start_morale_bp", 0))
	if f.morale_bp <= 0:
		f.morale_bp = BattleRules.BP
	var total := 0
	for c in d.composition:
		var n := int(c.count)
		var t: String = c.ship_type_id
		f.comp0[t] = f.comp0.get(t, 0) + n
		total += n
		if c.get("mission_equipment_id", "") != "":
			f.equip = c.mission_equipment_id
	for t in f.comp0:
		f.stages[t] = [f.comp0[t], 0, 0, 0, 0]
		f.max_hull += f.comp0[t] * int(C.ship_types[t].cost) * int(C.hull.points_per_cost)
		f.cost0 += f.comp0[t] * int(C.ship_types[t].cost)
	f.hull = f.max_hull
	f.ships = total * BattleRules.MILLI
	f.max_ships = f.ships
	f.shown = f.ships
	var res: Dictionary = C.resources
	f.energy_m = _energy_cap_m(f)
	f.sorties_m = _sorties_cap_m(f)
	var period := BattleRules.ticks(float(C.period_s), sim.st.hz)
	var i := 0
	for cat in C.categories:
		var w: Dictionary = C.weapons[cat]
		var n_plat := 0
		for t in w.platforms:
			n_plat += f.comp0.get(t, 0)
		for eq in w.equipment:
			if f.equip == eq:
				n_plat += f.comp0.get(C.fast_craft.ship_type_id, 0)
		var per: int = int(w.ammo_per_platform) if int(w.shot.ammo) > 0 else int(w.special_per_platform)
		f.ammo[cat] = n_plat * per
		f.next_fire[cat] = sim.rng.u32(0, f.id, i + 1) % maxi(1, period)
		f.supp[cat] = ""
		i += 1
	f.speed = _speed(f)
	refresh_range(f)

func finish_setup() -> void:
	# 초기 방향: 가장 가까운 적 전대를 향한다(§4.2)
	for f in sim.st.fleets:
		var n := sim.st.nearest_foe(f, 1e9)
		if n:
			f.heading = BattleRules.quant(atan2(n.pos.y - f.pos.y, n.pos.x - f.pos.x))

func _speed(f: FleetState) -> float:
	var slow := 1e9
	for t in f.comp0:
		if f.comp0[t] > 0:
			slow = minf(slow, float(C.ship_types[t].speed_per_turn))
	var form_bp: int = int(C.formations[_form_id(f)].mobility_bp)
	return slow / float(C.movement.turn_div) * float(BattleRules.BP + form_bp) / float(BattleRules.BP)

func _form_id(f: FleetState) -> String:
	return f.formation_id if C.formations.has(f.formation_id) else C.default_formation

# ============================================================ 질의
func total0(f: FleetState) -> int:
	var n := 0
	for t in f.comp0:
		n += f.comp0[t]
	return n

# 이탈하지 않은 척 수(무손상 + 경파 + 중파)
func present_of(f: FleetState, t: String) -> int:
	var s: Array = f.stages[t]
	return s[0] + s[1] + s[2]

func present_ships(f: FleetState) -> int:
	var n := 0
	for t in f.comp0:
		n += present_of(f, t)
	return n

# 단계 계수를 곱한 유효 함선 수(§4.5)
func effective_of(f: FleetState, t: String) -> float:
	var s: Array = f.stages[t]
	var p: Array = C.stage.power
	var e := 0.0
	for i in STAGE_N:
		e += float(s[i]) * float(p[i])
	return e

# 범주의 플랫폼 목록: [{type, n(유효 척 수), range, arc}] (함종 ID 순)
func platforms(f: FleetState, cat: String) -> Array:
	var out: Array = []
	var w: Dictionary = C.weapons[cat]
	var ids: Array = w.platforms.keys()
	ids.sort()
	for t in ids:
		if not f.stages.has(t):
			continue
		var n := effective_of(f, t)
		if n > 0.0:
			out.append({"type": t, "n": n, "range": float(w.platforms[t].range), "arc": float(w.platforms[t].arc_deg)})
	var eqs: Array = w.equipment.keys()
	eqs.sort()
	var fc: String = C.fast_craft.ship_type_id
	for eq in eqs:
		if f.equip == eq and f.stages.has(fc):
			var n := effective_of(f, fc)
			if n > 0.0:
				out.append({"type": fc, "n": n, "range": float(w.equipment[eq].range), "arc": float(w.equipment[eq].arc_deg)})
	return out

func refresh_range(f: FleetState) -> void:
	var r := 0.0
	for cat in C.categories:
		for p in platforms(f, cat):
			r = maxf(r, p.range)
	f.range_r = r if r > 0.0 else float(C.bands.assault_r)

func _max_range(f: FleetState, cat: String, fallback: float) -> float:
	var r := 0.0
	for p in platforms(f, cat):
		r = maxf(r, p.range)
	return r if r > 0.0 else fallback

# 거리대(§4.2): 강습 ≤ 80, 교전 = 전열 사거리 안, 포화 = 포격 사거리 안, 그 밖은 접적
func band(f: FleetState, dist: float) -> String:
	if dist <= float(C.bands.assault_r):
		return "assault"
	if dist <= _max_range(f, "line_fire", float(C.bands.line_fire_default_r)):
		return "engagement"
	if dist <= _max_range(f, "artillery", float(C.bands.artillery_default_r)):
		return "barrage"
	return "contact"

# 표적 기준 사격 방향 구간. 정면 ≤ 60°, 후면 ≥ 120°(경계 포함), 그 사이는 측면.
func sector(att_pos: Vector2, tgt: FleetState) -> String:
	var a := atan2(att_pos.y - tgt.pos.y, att_pos.x - tgt.pos.x)
	var d := rad_to_deg(absf(BattleRules.ang_diff(tgt.heading, a)))
	var eps := 0.001
	if d <= float(C.sector.front_deg) + eps:
		return "front"
	if d >= float(C.sector.rear_deg) - eps:
		return "rear"
	return "flank"

# 명중률(bp) [§4.3]: clamp(범주 기본값 + (사격측 화력 − 표적 방어) , 최소, 최대), 지휘 범위 밖이면 −10%p
func hit_bp(f: FleetState, tgt: FleetState, cat: String) -> int:
	var fire: int = int(C.formations[_form_id(f)].fire_bp)
	var defense: int = int(C.formations[_form_id(tgt)].defense_bp) + int(C.sector.defense_bp[sector(f.pos, tgt)])
	var h: Dictionary = C.hit
	var acc := clampi(int(C.weapons[cat].base_accuracy_bp) + fire - defense, int(h.min_bp), int(h.max_bp))
	if not f.in_cmd:
		acc = maxi(int(h.min_bp), acc - int(h.out_of_command_bp))
	return acc

func platform_mul(n: float) -> float:
	match str(C.damage_mode):
		"fixed":
			return 1.0
		"linear":
			return n
	return sqrt(n)

# 지휘관 보정(§4.3): 거리대마다 쓰는 능력치가 다르다. 둘 이상이면 평균
func commander_mul(f: FleetState, bd: String) -> float:
	var c: Dictionary = C.damage.commander
	var names: Array = c.stat_by_band[bd]
	var sum := 0.0
	for n in names:
		sum += float(f.stats[n])
	return 1.0 + float(c.span) * clampf((sum / names.size() - float(c.pivot)) / float(c.spread), -1.0, 1.0)

func morale_mul(f: FleetState) -> float:
	return float(C.damage.morale_base) + float(f.morale_bp) / float(C.damage.morale_div_bp)

func formation_mul(f: FleetState) -> float:
	return float(C.damage.formation_damage_mul.get(_form_id(f), 1.0))

# 피해 [§4.3]: 범주 기본 피해 × 플랫폼 배율 × 함종 거리대 계수 × 지휘관 × 사기 × 진형 × 지형 (× 돌격, 방어태세)
func damage_of(f: FleetState, cat: String, n_total: float, coef: float, bd: String) -> float:
	var d := float(C.weapons[cat].base_damage) * platform_mul(n_total) * coef
	d *= commander_mul(f, bd) * morale_mul(f) * formation_mul(f) * float(C.damage.terrain_mul)
	if f.charge > 0:
		d *= sim.R.charge_power_mul
	if f.defense:
		d *= sim.R.defense_power_mul
	return d

# ============================================================ 사격 계획
# 표적이 사거리와 사격각 안에 드는 플랫폼만 모은다. [{type, n, range, arc}]
func qualifying(f: FleetState, cat: String, tgt: FleetState) -> Array:
	var out: Array = []
	var dist := f.pos.distance_to(tgt.pos)
	var bearing := atan2(tgt.pos.y - f.pos.y, tgt.pos.x - f.pos.x)
	var off := rad_to_deg(absf(BattleRules.ang_diff(f.heading, bearing)))
	for p in platforms(f, cat):
		if dist <= p.range and off <= p.arc * 0.5 + 0.001:
			out.append(p)
	return out

func _pick_target(f: FleetState, cat: String) -> Dictionary:
	var best: FleetState = null
	var best_q: Array = []
	var cur := sim.st.live_target(f)
	if cur:
		var q := qualifying(f, cat, cur)
		if not q.is_empty():
			return {"tgt": cur, "q": q}
	var bd := 1e9
	for o in sim.st.fleets:
		if o.dead or o.side == f.side:
			continue
		var d := f.pos.distance_to(o.pos)
		if d >= bd:
			continue
		var q := qualifying(f, cat, o)
		if not q.is_empty():
			bd = d
			best = o
			best_q = q
	return {"tgt": best, "q": best_q}

# ============================================================ 자원
func _energy_cap_m(f: FleetState) -> int:
	var r: Dictionary = C.resources
	return (int(r.energy_base) + int(r.energy_per_ship) * total0(f)) * BattleRules.MILLI

func _heat_cap_m(f: FleetState) -> int:
	var r: Dictionary = C.resources
	return (int(r.heat_base) + int(r.heat_per_ship) * total0(f)) * BattleRules.MILLI

func _sorties_cap_m(f: FleetState) -> int:
	var cr: Dictionary = C.carrier
	return int(f.comp0.get(cr.ship_type_id, 0)) * int(cr.sorties_per_ship) * BattleRules.MILLI

# 틱마다 연속 회복(§4.8): 에너지와 함재기는 용량의 20%·25%, 열은 30 + 척 수 × 2를 recovery_period_s마다
func _recover(f: FleetState) -> void:
	var r: Dictionary = C.resources
	var pt := BattleRules.ticks(float(r.recovery_period_s), sim.st.hz)
	var cap_e := _energy_cap_m(f)
	f.energy_rem += cap_e * int(r.energy_recover_bp)
	f.energy_m = mini(cap_e, f.energy_m + f.energy_rem / (BattleRules.BP * pt))
	f.energy_rem %= BattleRules.BP * pt
	var cap_s := _sorties_cap_m(f)
	if cap_s > 0:
		f.sorties_rem += cap_s * int(r.carrier_recover_bp)
		f.sorties_m = mini(cap_s, f.sorties_m + f.sorties_rem / (BattleRules.BP * pt))
		f.sorties_rem %= BattleRules.BP * pt
	f.heat_rem += (int(r.heat_cool_base) + int(r.heat_cool_per_ship) * present_ships(f)) * BattleRules.MILLI
	f.heat_m = maxi(0, f.heat_m - f.heat_rem / pt)
	f.heat_rem %= pt

func heat_ratio_bp(f: FleetState) -> int:
	return f.heat_m * BattleRules.BP / maxi(1, _heat_cap_m(f))

# 사격 한 번의 자원 사유. 가능하면 "".
func _shortage(f: FleetState, cat: String, uses_sortie: bool) -> String:
	var w: Dictionary = C.weapons[cat]
	var shot: Dictionary = w.shot
	var unit: int = int(shot.ammo) if int(shot.ammo) > 0 else int(shot.special)
	if f.ammo[cat] < unit:
		return "ammo" if int(shot.ammo) > 0 else "special"
	if f.energy_m < int(shot.energy) * BattleRules.MILLI:
		return "energy"
	if f.heat_m + int(shot.heat) * BattleRules.MILLI > _heat_cap_m(f):
		return "overheat"
	if uses_sortie and f.sorties_m < int(C.carrier.sorties_per_shot) * BattleRules.MILLI:
		return "carrier_not_returned"
	return ""

func _consume(f: FleetState, cat: String, uses_sortie: bool) -> void:
	var shot: Dictionary = C.weapons[cat].shot
	f.ammo[cat] -= int(shot.ammo) if int(shot.ammo) > 0 else int(shot.special)
	f.energy_m -= int(shot.energy) * BattleRules.MILLI
	f.heat_m += int(shot.heat) * BattleRules.MILLI
	if uses_sortie:
		f.sorties_m -= int(C.carrier.sorties_per_shot) * BattleRules.MILLI

# 일제사격 지금: 모든 범주의 다음 주기를 현재 틱으로 당긴다
func pull(f: FleetState) -> void:
	for cat in C.categories:
		f.next_fire[cat] = mini(f.next_fire[cat], sim.st.tick)

# 돌격 조건(Q28·Q42): 사기 안정, 열 여유. 사유 코드 또는 "".
func charge_block(f: FleetState) -> String:
	var c: Dictionary = C.charge
	if f.morale_bp < int(c.min_morale_bp):
		return "charge_morale"
	var cost := _heat_cap_m(f) * int(c.heat_share_bp) / BattleRules.BP
	if f.heat_m + cost > _heat_cap_m(f):
		return "charge_heat"
	return ""

func charge_pay(f: FleetState) -> void:
	f.heat_m += _heat_cap_m(f) * int(C.charge.heat_share_bp) / BattleRules.BP

# ============================================================ 틱
func step() -> void:
	var st := sim.st
	var shots: Array[Dictionary] = []
	for f in st.fleets:
		if f.dead or f.max_hull == 0:
			continue
		_recover(f)
		if f.mstate == "retreat":
			continue   # 퇴각 중인 전대는 공격하지 못한다(§4.6)
		for cat in C.categories:
			if st.tick < f.next_fire[cat]:
				continue
			var pick := _pick_target(f, cat)
			if pick.tgt == null:
				_set_supp(f, cat, "")
				continue
			var q: Array = pick.q
			var uses_sortie := false
			var carrier: String = C.carrier.ship_type_id
			if cat == C.carrier.category and not q.is_empty():
				for p in q:
					if p.type == carrier:
						uses_sortie = true
				if uses_sortie and f.sorties_m < int(C.carrier.sorties_per_shot) * BattleRules.MILLI:
					# 함재기가 돌아오지 않았다: 강습모함을 빼고 쏜다. 남는 플랫폼이 없으면 보류
					q = q.filter(func(p): return p.type != carrier)
					uses_sortie = false
					if q.is_empty():
						_set_supp(f, cat, "carrier_not_returned")
						continue
			var why := _shortage(f, cat, uses_sortie)
			if why != "":
				_set_supp(f, cat, why)
				continue
			_set_supp(f, cat, "")
			_consume(f, cat, uses_sortie)
			f.next_fire[cat] = st.tick + BattleRules.ticks(float(C.period_s), st.hz) + _stagger(f, cat)
			shots.append(_plan_shot(f, cat, pick.tgt, q))
	# 같은 틱의 피해는 위에서 모두 피해 전 스냅숏으로 계산했다. 이제 표적별로 적용한다.
	for s in shots:
		_resolve(s)

# 첫 일제 뒤 다음 주기에 0~N초를 더해 같은 진영 전대들의 일제가 한 틱에 몰리지 않게 한다(M3 리뷰 후보, 0이면 끔)
func _stagger(f: FleetState, cat: String) -> int:
	var n := BattleRules.ticks(float(C.first_volley_stagger_s.value), sim.st.hz)
	if n <= 0 or f.fired.has(cat):
		return 0
	f.fired[cat] = true
	return sim.rng.u32(sim.st.tick, f.id, C.categories.find(cat)) % (n + 1)

func _set_supp(f: FleetState, cat: String, why: String) -> void:
	if f.supp[cat] != why:
		f.supp[cat] = why
		if why != "":
			sim.emit("suppressed", f.id, -1, f.pos, {"cat": cat, "reason": why})

func _plan_shot(f: FleetState, cat: String, tgt: FleetState, q: Array) -> Dictionary:
	var dist := f.pos.distance_to(tgt.pos)
	var bd := band(f, dist)
	# 퇴각 상태 전대가 관련된 사격은 결착 거리대다(§4.2). 손상 단계 비율(heavy_share)은 실제 거리대를 쓴다
	var wband := "resolution" if tgt.mstate == "retreat" else bd
	var n_total := 0.0
	var wsum := 0.0
	for p in q:
		n_total += p.n
		wsum += p.n * float(C.ship_types[p.type].phase[wband])
	var coef := wsum / n_total
	var eid := sim.st.new_event_id()
	var acc := hit_bp(f, tgt, cat)
	return {"src": f, "tgt": tgt, "cat": cat, "band": bd, "wband": wband, "sector": sector(f.pos, tgt), "acc": acc,
		"dmg": damage_of(f, cat, n_total, coef, wband), "n": n_total, "eid": eid,
		"hit": sim.rng.bp(sim.st.tick, eid, 1) < acc}

func _resolve(s: Dictionary) -> void:
	var f: FleetState = s.src
	var tgt: FleetState = s.tgt
	sim.emit("salvo", f.id, tgt.id, tgt.pos, {"cat": s.cat, "hit": s.hit, "dmg": roundi(s.dmg), "acc": s.acc, "band": s.band, "sector": s.sector, "n": s.n})
	if s.hit and not tgt.dead:
		var loss := apply_hull(f, tgt, s.dmg, s.band, s.sector, s.eid)
		if sim.morale:
			sim.morale.hit(tgt, loss, s.wband, s.sector)

# ============================================================ 피해 적용
# 선체 → 손실 척 수(누적 단조) → 맞은 방향 배분 → 손상 단계 → 표시 척 수
func apply_hull(src: FleetState, tgt: FleetState, dmg: float, bd: String, sec: String, eid: int) -> int:
	if tgt.dead:
		return 0
	if tgt.defense:
		dmg *= sim.R.defense_damage_taken_mul
	var loss := mini(roundi(dmg), tgt.hull)
	tgt.hull -= loss
	var cum := tgt.max_hull - tgt.hull
	var want := total0(tgt) * cum / tgt.max_hull
	var k := 0
	while tgt.lost_ships < want:
		_depart_one(tgt, bd, sec, eid, k)
		k += 1
	_wound(tgt)
	refresh_range(tgt)
	var new_ships := tgt.max_ships * tgt.hull / tgt.max_hull
	var a := maxi(0, tgt.ships - new_ships)
	if tgt.hull <= 0:
		a = tgt.ships
	tgt.ships -= a
	sim.book_loss(src, tgt, a)
	return loss

func _exposure(f: FleetState, sec: String) -> Array:
	var tab: Dictionary = C.loss.exposure
	return tab.get(_form_id(f), tab[C.default_formation])[sec]

func _pick_type(f: FleetState, group: Array) -> String:
	var best := ""
	var bn := 0
	var ids: Array = group.duplicate()
	ids.sort()
	for t in ids:
		if f.stages.has(t) and present_of(f, t) > bn:
			bn = present_of(f, t)
			best = t
	return best

# 이탈 한 척: 맞은 방향 노출 함종 60%, 나머지 40%. 각 묶음에서는 척 수가 가장 많은 함종부터(함종 ID 순 동률).
func _depart_one(f: FleetState, bd: String, sec: String, eid: int, k: int) -> void:
	var expo: Array = _exposure(f, sec)
	var rest: Array = []
	var all_ids: Array = f.comp0.keys()
	all_ids.sort()
	for t in all_ids:
		if not expo.has(t):
			rest.append(t)
	var share: int = int(C.loss.exposed_share_bp)
	var want_exposed := f.loss_exposed * BattleRules.BP < share * (f.loss_total + 1)
	var t := _pick_type(f, expo) if want_exposed else _pick_type(f, rest)
	var was_exposed := want_exposed
	if t == "":
		t = _pick_type(f, rest) if want_exposed else _pick_type(f, expo)
		was_exposed = not want_exposed
	if t == "":
		return
	var s: Array = f.stages[t]
	# 가장 손상된 함선이 먼저 이탈한다
	if s[2] > 0:
		s[2] -= 1
	elif s[1] > 0:
		s[1] -= 1
	else:
		s[0] -= 1
	var heavy_bp: int = int(C.stage.heavy_share_bp[bd])
	if sim.rng.bp(sim.st.tick, eid, 1 + k + 1) < heavy_bp:
		s[STAGE_HEAVY] += 1
	else:
		s[STAGE_SUNK] += 1
	f.lost_ships += 1
	if sim.morale:
		sim.morale.ship_departed(f)
	f.loss_total += 1
	if was_exposed:
		f.loss_exposed += 1

func _stage_sum(f: FleetState, i: int) -> int:
	var n := 0
	for t in f.stages:
		n += f.stages[t][i]
	return n

# 이탈하지 않은 선체 손실은 경파·중파로 쌓는다(§4.5). 신규 중파는 경파에서 먼저 나온다.
func _wound(f: FleetState) -> void:
	var survivors := present_ships(f)
	if survivors <= 0:
		return
	var ratio_bp := f.hull * BattleRules.BP / f.max_hull
	var mod_min := 0
	for fl in C.stage.hull_floor:
		if ratio_bp < int(fl.below_bp):
			mod_min = maxi(mod_min, survivors * int(fl.moderate_share_bp) / BattleRules.BP)
	var worn := (survivors * (BattleRules.BP - ratio_bp) + BattleRules.BP / 2) / BattleRules.BP
	var cur_mod := _stage_sum(f, 2)
	var mod_target := mini(survivors, maxi(cur_mod, mod_min))
	var wound_target := mini(survivors, maxi(maxi(_stage_sum(f, 1) + cur_mod, worn), mod_target))
	var ids: Array = f.comp0.keys()
	ids.sort()
	while _stage_sum(f, 1) + _stage_sum(f, 2) < wound_target:
		var t := _most_in_stage(f, ids, 0)
		if t == "":
			break
		f.stages[t][0] -= 1
		f.stages[t][1] += 1
	while _stage_sum(f, 2) < mod_target:
		var t := _most_in_stage(f, ids, 1)
		if t == "":
			t = _most_in_stage(f, ids, 0)
			if t == "":
				break
			f.stages[t][0] -= 1
			f.stages[t][1] += 1
		f.stages[t][1] -= 1
		f.stages[t][2] += 1

func _most_in_stage(f: FleetState, ids: Array, stage: int) -> String:
	var best := ""
	var bn := 0
	for t in ids:
		if f.stages[t][stage] > bn:
			bn = f.stages[t][stage]
			best = t
	return best

# 함종 × 손상 단계 카운터(투영용)
func counts_of(f: FleetState) -> Dictionary:
	var out := {}
	for t in f.stages:
		out[t] = (f.stages[t] as Array).duplicate()
	return out
