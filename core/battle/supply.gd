class_name SupplyCore
extends RefCounted

# M8 보급과 수리(제안서 §4.13, 세션 Q25·Q48). 수치는 combat.supply(data/profiles/combat_m3.json)에서 온다.
# 본편 고속정 보급 계약(턴제)을 일반 전대·실시간으로 넓혔다. 턴 → 초 환산과 처리량 표현은 제안값이다.
#
# 공급원: 보급함(SHP-05)이 남은 전대(반경 140, 보급함 1척당 동시 1개 전대, 재고 있음)와 아군 기지(반경 180, 동시 4개, 재고 무한).
# 손님: 같은 진영이고 같은 세력 또는 연합(mutual)인 전대가 공급원 반경 안에 정지해 있고, 받을 것이 있을 때.
# 진행: 배정된 손님은 틱마다 공급원 처리량(bp)만큼 쌓고 need_s × 10000이 차면 한 주기가 끝난다(손상된 보급함 전대는 느리다).
#   중간에 움직이거나 반경을 벗어나면 진행이 0으로 돌아간다. 배정은 끝날 때까지 유지된다(빈자리만 우선순위로 채운다).
# 한 주기: 탄약 전량 보충(공급원 재고가 모자라면 시작하지 않는다) + 물자 1로 중파 1척 → 경파 + 같은 세력 기지면 보급함 재고 재적재.
# 경파는 마지막 피격 뒤 light_recover_s가 지나면 어디서든 무손상으로 돌아간다(P16).
#
# 한 틱의 순서(첫 하위 걸음, 사기 다음): 재고 손실 → 정지 판정 → 경파 회복 → 배정 → 진행·완료.

var sim: BattleSim
var S: Dictionary
var ship := ""
var need := 0             # 한 주기의 bp·틱
var light_ticks := 0
var still_eps := 0.0     # 틱당 정지 판정 px = still_eps_px_s / hz
var bases: Array = []     # {key, faction, side, pos}

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	S = cfg
	ship = str(S.ship_type_id)
	need = BattleRules.ticks(float(S.stationary_s), sim.st.hz) * BattleRules.BP
	light_ticks = BattleRules.ticks(float(S.repair.light_recover_s), sim.st.hz)
	still_eps = float(S.still_eps_px_s) / sim.st.hz
	for b in S.bases:
		var side := -1
		for f in sim.st.fleets:
			if allied(f.faction, str(b.faction_id)):   # 연합 기지는 그 연합의 진영
				side = f.side
		bases.append({"key": str(b.id), "faction": str(b.faction_id), "side": side, "pos": Vector2(float(b.position[0]), float(b.position[1]))})
	for f in sim.st.fleets:
		f.sup_n = ships_of(f)
		f.sup_ammo = f.sup_n * int(S.per_ship.ammo)
		f.sup_mat = f.sup_n * int(S.per_ship.materials)
		f.sup_pos = f.pos

# ============================================================ 질의
# 이탈하지 않은 보급함 수(무손상 + 경파 + 중파)
func ships_of(f: FleetState) -> int:
	return sim.salvo.present_of(f, ship) if f.stages.has(ship) else 0

func allied(a: String, b: String) -> bool:
	if a == b:
		return true
	for g in S.mutual:
		if g.has(a) and g.has(b):
			return true
	return false

# 범주의 탄약 상한: 남은 플랫폼 수 × 플랫폼당 탄약(편성 때와 같은 식)
func ammo_cap(f: FleetState, cat: String) -> int:
	var w: Dictionary = sim.salvo.C.weapons[cat]
	var n := 0
	for t in w.platforms:
		if f.stages.has(t):
			n += sim.salvo.present_of(f, t)
	var fc: String = sim.salvo.C.fast_craft.ship_type_id
	for eq in w.equipment:
		if f.equip == eq and f.stages.has(fc):
			n += sim.salvo.present_of(f, fc)
	return n * (int(w.ammo_per_platform) if int(w.shot.ammo) > 0 else int(w.special_per_platform))

func deficit(f: FleetState) -> int:
	var d := 0
	for cat in f.ammo:
		d += maxi(0, ammo_cap(f, cat) - int(f.ammo[cat]))
	return d

func ammo_ratio_bp(f: FleetState) -> int:
	var cap := 0
	var cur := 0
	for cat in f.ammo:
		var c := ammo_cap(f, cat)
		cap += c
		cur += mini(c, int(f.ammo[cat]))
	return cur * BattleRules.BP / cap if cap > 0 else BattleRules.BP

# Q69: 미사일·함재기 사용 횟수 부족분
func charge_deficit(f: FleetState) -> int:
	var d := 0
	for cat in f.wch:
		d += maxi(0, sim.salvo.charge_cap(f, cat) - int(f.wch[cat]))
	return d

func moderate_of(f: FleetState) -> int:
	var n := 0
	for t in f.stages:
		n += f.stages[t][2]
	return n

# 보급함 전대의 처리량(bp): 선체 구간 100% / 50% / 25%
func rate_of(f: FleetState) -> int:
	var hb: Dictionary = sim.salvo.C.hull.bands_bp
	var r := f.hull * BattleRules.BP / maxi(1, f.max_hull)
	var tb: Dictionary = S.throughput_bp
	if r >= int(hb.operational_min):
		return int(tb.operational)
	if r >= int(hb.moderate_damage_min):
		return int(tb.moderate_damage)
	return int(tb.heavy_damage)

# 지금 쓸 수 있는 공급원 목록: {key, side, faction, pos, r, cap, rate, fleet(null이면 기지)}. 기지 → 전대 ID 순
func sources() -> Array:
	var out := []
	for b in bases:
		out.append({"key": b.key, "side": b.side, "faction": b.faction, "pos": b.pos, "r": float(S.base_radius), "cap": int(S.base_capacity), "rate": BattleRules.BP, "fleet": null})
	for f in sim.st.fleets:
		if f.dead or f.max_hull == 0:
			continue
		var n := ships_of(f)
		if n > 0:
			out.append({"key": "f%d" % f.id, "side": f.side, "faction": f.faction, "pos": f.pos, "r": float(S.ship_radius), "cap": n * int(S.capacity_per_ship), "rate": rate_of(f), "fleet": f})
	return out

func source_by_key(key: String) -> Dictionary:
	for s in sources():
		if s.key == key:
			return s
	return {}

func _reloadable(f: FleetState, src: Dictionary) -> bool:
	return src.fleet == null and src.faction == f.faction and f.sup_n > 0 \
		and (f.sup_ammo < f.sup_n * int(S.per_ship.ammo) or f.sup_mat < f.sup_n * int(S.per_ship.materials))

# 이 공급원에서 받을 것이 있는가(재고가 모자라면 받지 않는다: 전량 보충만, 원자적)
func serviceable(f: FleetState, src: Dictionary) -> bool:
	if f.dead or f.max_hull == 0 or not f.sup_still:
		return false
	if src.side != f.side or not allied(src.faction, f.faction) or f.pos.distance_to(src.pos) > src.r:
		return false
	var g: FleetState = src.fleet
	var d := deficit(f)
	if d > 0 and (g == null or (g.sup_ammo >= d and g.sup_mat >= int(S.materials_per_refill))):
		return true
	if charge_deficit(f) > 0:
		return true   # 횟수 보충은 재고를 쓰지 않는다
	if moderate_of(f) > 0 and (g == null or g.sup_mat >= int(S.repair.materials)):
		return true
	return _reloadable(f, src)

# ============================================================ 틱
func step() -> void:
	var st := sim.st
	for f in st.fleets:
		if f.dead:
			continue
		# 보급함이 이탈하면 남은 비율만큼 재고를 잃는다: floor(재고 × (N − d) / N)
		var n := ships_of(f)
		if n < f.sup_n:
			f.sup_ammo = f.sup_ammo * n / f.sup_n
			f.sup_mat = f.sup_mat * n / f.sup_n
			f.sup_n = n
		var still := f.pos.distance_to(f.sup_pos) <= still_eps
		f.sup_pos = f.pos
		if not still:
			f.sup_since = -1
		elif not f.sup_still or f.sup_since < 0:
			f.sup_since = st.tick
		f.sup_still = still
		_light_recover(f)
	var srcs := sources()
	var used := {}
	for s in srcs:
		used[s.key] = 0
	# 진행 중인 손님은 자리를 지킨다
	for f in st.fleets:
		if f.sup_src == "":
			continue
		var s := _find(srcs, f.sup_src)
		if s.is_empty() or used[s.key] >= s.cap or not serviceable(f, s):
			f.sup_src = ""
			f.sup_prog = 0
		else:
			used[s.key] += 1
	# 빈자리: 남은 탄약 비율 → 먼저 정지한 순 → 전대 ID 순. 공급원은 가까운 곳(동률이면 목록 순)
	var cand: Array[FleetState] = []
	for f in st.fleets:
		if f.sup_src == "" and not f.dead and f.max_hull > 0 and f.sup_still:
			cand.append(f)
	cand.sort_custom(func(a, b):
		var ra := ammo_ratio_bp(a)
		var rb := ammo_ratio_bp(b)
		if ra != rb:
			return ra < rb
		if a.sup_since != b.sup_since:
			return a.sup_since < b.sup_since
		return a.id < b.id)
	for f in cand:
		var best: Dictionary = {}
		var bd := INF
		for s in srcs:
			if used[s.key] < s.cap and serviceable(f, s):
				var d := f.pos.distance_to(s.pos)
				if d < bd:
					bd = d
					best = s
		if not best.is_empty():
			used[best.key] += 1
			f.sup_src = best.key
			f.sup_prog = 0
	for f in st.fleets:
		if f.sup_src == "":
			continue
		var s := _find(srcs, f.sup_src)
		f.sup_prog += int(s.rate)
		if f.sup_prog >= need:
			_complete(f, s)
			f.sup_prog = 0

func _find(srcs: Array, key: String) -> Dictionary:
	for s in srcs:
		if s.key == key:
			return s
	return {}

func _complete(f: FleetState, src: Dictionary) -> void:
	var g: FleetState = src.fleet
	var got := 0
	var fixed := 0
	var reload := false
	var d := deficit(f)
	if d > 0 and (g == null or (g.sup_ammo >= d and g.sup_mat >= int(S.materials_per_refill))):
		for cat in f.ammo:
			f.ammo[cat] = maxi(int(f.ammo[cat]), ammo_cap(f, cat))
		if g:
			g.sup_ammo -= d
			g.sup_mat -= int(S.materials_per_refill)
		got = d
	var charges := 0
	if charge_deficit(f) > 0:
		var add: int = sim.salvo.charge_refill(int(src.rate))   # 보급 레벨 = 공급원 처리량(100/50/25% → 3/2/1회, 기지 3회)
		for cat in f.wch:
			var room: int = sim.salvo.charge_cap(f, cat) - int(f.wch[cat])
			if room > 0:
				f.wch[cat] += mini(room, add)
				charges += mini(room, add)
	if moderate_of(f) > 0 and (g == null or g.sup_mat >= int(S.repair.materials)):
		var ids: Array = f.stages.keys()
		ids.sort()
		var best := ""
		for t in ids:
			if f.stages[t][2] > 0 and (best == "" or f.stages[t][2] > f.stages[best][2]):
				best = t
		f.stages[best][2] -= 1
		f.stages[best][1] += 1
		if g:
			g.sup_mat -= int(S.repair.materials)
		fixed = 1
		f.healed_mod += 1
	if _reloadable(f, src):
		f.sup_ammo = f.sup_n * int(S.per_ship.ammo)
		f.sup_mat = f.sup_n * int(S.per_ship.materials)
		reload = true
	f.supplied += 1
	sim.emit("supply", f.id, g.id if g else -1, f.pos, {"src": src.key, "ammo": got, "charges": charges, "repair": fixed, "reload": reload})

# 경파 → 무손상: 마지막 피격 뒤 light_recover_s 동안 피격이 없으면 모두(P16). 보급 영역은 필요 없다
func _light_recover(f: FleetState) -> void:
	if f.max_hull == 0 or f.hit_tick < 0 or sim.st.tick - f.hit_tick < light_ticks:
		return
	var n := 0
	for t in f.stages:
		var s: Array = f.stages[t]
		n += s[1]
		s[0] += s[1]
		s[1] = 0
	f.healed_wound += n
	if n > 0:
		sim.emit("light_recovered", f.id, -1, f.pos, n)

# ============================================================ 투영
# 진영이 쓸 수 있는 공급원(자기 진영 것만. 적 보급함·적 기지는 넣지 않는다)
func public_sources(side: int) -> Array:
	var out := []
	for s in sources():
		if s.side != side:
			continue
		var e := {"key": s.key, "pos": s.pos, "radius": s.r, "capacity": s.cap, "rate_bp": s.rate, "base": s.fleet == null, "faction_id": s.faction}
		if s.fleet:
			e.squadron = s.fleet.id
			e.ammo = s.fleet.sup_ammo
			e.materials = s.fleet.sup_mat
		out.append(e)
	return out

func squadron_state(f: FleetState) -> Dictionary:
	return {"src": f.sup_src, "progress_s": float(f.sup_prog) / BattleRules.BP / sim.st.hz, "need_s": float(S.stationary_s),
		"still": f.sup_still, "ammo_ratio_bp": ammo_ratio_bp(f), "stock_ammo": f.sup_ammo, "stock_materials": f.sup_mat}

func fingerprint() -> String:
	var parts := PackedStringArray()
	for f in sim.st.fleets:
		parts.append("%d.%d.%d.%d.%s.%d.%d.%d.%d.%d.%d.%d" % [f.id, f.hit_tick, f.healed_wound, f.healed_mod, f.sup_src, f.sup_prog, f.sup_since, int(f.sup_still), f.sup_ammo, f.sup_mat, f.sup_n, f.supplied])
	return "sup|" + ",".join(parts)
