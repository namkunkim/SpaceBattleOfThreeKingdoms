class_name AssaultCore
extends RefCounted

# M9 강습(제안서 §4.11 강습, 정본 combat.md §6). 수치는 combat.assault(모두 제안값). 판정은 시드 난수 한 번이다.
# 전제: 아군 강습모함(SHP-01) 보유, 표적까지 강습 거리대(80) 이내, 표적은 쏠 수 있는 접촉.
# 진형 붕괴(열림): 표적이 퇴각 상태, 진형 전환 중, 또는 직전 30초 안에 측면·후면 명중 3회 이상
#   (침입 전대에 강습형(무력 85 이상)이 있으면 2회, 특급 무력(관우·장비)이 있으면 1회).
# 부대 강습(unit): 열리지 않아도 된다(제한 강습). 성공하면 함선 1척 나포, 표적 사기 −1500.
# 기함 진입(flagship): 표적이 함대 기함 전대여야 한다. 열리지 않았으면 강행 돌입(성공률 1/3, 실패 시 강습모함 1척 상실·자기 사기 −3000).
#   호위 「호치」(허저)가 있으면 성공률 ×0.5. 성공하면 표적 사기 −4000, 지휘관 보정 소멸, 표적 지휘관 중상(승계), 자기 군 사기 +1000.
# 성공률 = clamp(5000 + (침입측 최고 무력 − 방어측 최고 무력) × 100, 1000, 9000)bp. 쿨다운 60초. 일기토는 후속.

var sim: BattleSim
var A: Dictionary
var stats := {"unit": [0, 0], "flagship": [0, 0], "forced": [0, 0]}   # [시도, 성공]

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	A = cfg

func _people(f: FleetState) -> Array:
	var out: Array = [{"id": f.commander_id, "might": int(f.stats.get("might", 0)), "traits": f.traits}]
	if not f.vice.is_empty():
		out.append(f.vice)
	out.append_array(f.staff)
	return out

func best_might(f: FleetState) -> int:
	var m := 0
	for p in _people(f):
		m = maxi(m, int(p.get("might", 0)))
	return m

func _need_hits(f: FleetState) -> int:
	var n := int(A.open_hits)
	for p in _people(f):
		if A.elite_ids.has(str(p.get("id", ""))):
			return int(A.elite_hits)
		if int(p.get("might", 0)) >= int(A.assault_type_might):
			n = mini(n, int(A.assault_type_hits))
	return n

func is_open(src: FleetState, t: FleetState) -> bool:
	if t.mstate == "retreat" or t.form_left > 0:
		return true
	var since := sim.st.tick - BattleRules.ticks(float(A.open_window_s), sim.st.hz)
	return t.fr_hits.filter(func(k): return k > since).size() >= _need_hits(src)

func fleet_flag(t: FleetState) -> bool:
	if sim.cmd:
		for g in sim.cmd.groups:
			if g.flag_sq == t.sq_id:
				return true
	return t.is_flag

func block(src: FleetState, t: FleetState, kind: String) -> String:
	if not (kind in ["unit", "flagship"]):
		return "unknown_command"
	if not src.stages.has(str(A.carrier)) or sim.salvo.present_of(src, str(A.carrier)) <= 0:
		return "assault_no_carrier"
	if t == null or t.dead or t.side == src.side:
		return "bad_target"
	if not sim.sees(src, t) or (sim.chain and sim.chain.truce(src, t)):
		return "no_contact"
	if src.pos.distance_to(sim.known_pos(src, t)) > float(sim.salvo.C.bands.assault_r) + 0.001:
		return "assault_range"
	if sim.st.tick < src.assault_cd:
		return "assault_cooldown"
	if kind == "flagship" and not fleet_flag(t):
		return "assault_not_flagship"
	return ""

func chance_bp(src: FleetState, t: FleetState, kind: String) -> int:
	var bp := clampi(int(A.base_bp) + (best_might(src) - best_might(t)) * int(A.might_bp), int(A.min_bp), int(A.max_bp))
	if kind == "flagship":
		for p in _people(t):
			if (p.get("traits", []) as Array).has(str(A.flagship.escort_trait)):
				bp = bp * int(A.flagship.escort_trait_mul_bp) / BattleRules.BP
				break
		if not is_open(src, t):
			bp /= int(A.forced_div)
	return bp

# 명령 처리. 사유 코드 또는 ""
func attempt(src: FleetState, t: FleetState, kind: String) -> String:
	var why := block(src, t, kind)
	if why != "":
		return why
	var st := sim.st
	var open := is_open(src, t)
	var forced := kind == "flagship" and not open
	var bp := chance_bp(src, t, kind)
	var eid := st.new_event_id()
	var ok := sim.rng.bp(st.tick, eid, 1) < bp
	src.assault_cd = st.tick + BattleRules.ticks(float(A.cooldown_s), st.hz)
	var key := "forced" if forced else kind
	stats[key][0] += 1
	if ok:
		stats[key][1] += 1
		if kind == "unit":
			var per := float(t.max_hull) / float(maxi(1, sim.salvo.total0(t)))
			sim.salvo.apply_hull(src, t, ceilf(per * float(A.unit.capture_ships)), "assault", sim.salvo.sector(src.pos, t), eid, 0)   # 나포: 이탈 처리(대파 0). 척당 선체가 정수로 안 나뉘면 버림 때문에 0척이 되므로 올림
			if sim.morale:
				sim.morale.lose(t, int(A.unit.target_morale_bp))
		else:
			if sim.morale:
				sim.morale.lose(t, int(A.flagship.target_morale_bp))
				st.army_ev[src.side] = maxi(0, int(st.army_ev[src.side]) - int(sim.rs.rt("morale_events.army_recovery_bp.flagship_boarding_success", 0)))
			t.boarded = true
			if sim.cmd:
				sim.cmd.force_state(t, "severe")
	elif forced:
		_lose_carrier(src)
		if sim.morale:
			sim.morale.lose(src, int(A.forced_fail.own_morale_bp))
	sim.emit("assault", src.id, t.id, t.pos, {"type": kind, "ok": ok, "open": open, "forced": forced, "bp": bp})
	return ""

# 강행 돌입 실패: 강습모함을 잃는다(가장 손상된 것부터)
func _lose_carrier(f: FleetState) -> void:
	var t := str(A.carrier)
	for i in int(A.forced_fail.carrier_loss):
		var s: Array = f.stages[t]
		var k := 2 if s[2] > 0 else (1 if s[1] > 0 else 0)
		if s[k] <= 0:
			return
		s[k] -= 1
		s[SalvoCombat.STAGE_SUNK] += 1
		f.lost_ships += 1
		var pts := int(sim.salvo.C.ship_types[t].cost) * int(sim.salvo.C.hull.points_per_cost)
		f.hull = maxi(0, f.hull - pts)
		var a := maxi(0, f.ships - f.max_ships * f.hull / f.max_hull)
		f.ships -= a
		sim.book_loss(null, f, a)
		sim.salvo.refresh_range(f)

# 지휘관 AI(위임 아군·조조군): 확인 접촉이 강습 거리 안이고 진형이 열렸을 때만 쓴다(기함이면 기함 진입)
func ai_try(f: FleetState, c: Dictionary) -> void:
	if c.get("state", "") != "confirmed":
		return
	var t := sim.st.by_id(int(c.id))
	var kind := "flagship" if t and fleet_flag(t) else "unit"
	if t == null or block(f, t, kind) != "" or not is_open(f, t):
		return
	attempt(f, t, kind)
