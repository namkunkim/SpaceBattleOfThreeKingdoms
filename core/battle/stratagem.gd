class_name ChainOp
extends RefCounted

# M9 연쇄 폭발 작전(화공)과 위장 항복(제안서 §4.11). 시나리오에 realtime_rules.chain_operation이 있고
# combat.stratagem이 있을 때만 켜진다. 정본의 "조건이 모두 맞으면 확률 없이 확정 발동"을 지킨다.
#
# 흐름: 첫 명중 → 기류 창 예보(시작 = 첫 명중 + 시드 540~600초, 180초) → 서신(letter) → 투항 중(의심 < 100이면 황개와
#   조조군이 서로 쏘지 않는다) → 발동(ignite: 창 안, 거리 ≤ 240, 표적 밀집 진형, 표적 확인 접촉, 흐름 +X ±60°)
#   → 위력(거리 240 25% · 120 40% · 60 50%, 선형) → 번짐(20초마다 반경 150 밀집 전대, 최대 2회, 매번 절반)
#   → 결과 등급(번짐 0·1·2회). 의심 100이면 간파: 표적 분산, 황개 집중 사격, 연합 군 사기 −1500, 폭발정 1회 소모.
# 상태 mode: idle(서신 전) · feign(투항 중) · open(위장 없음: 간파·서신 철회·1회 발동 뒤) · done(더 쓸 수 없음)
# 조조 차단(난이도, 한 화공에 한 번): ㉡ 요격망(위장 없는 돌입 위력 ×0.5) · ㉠ 긴급 분산(발동 때 반경 150 밀집 전대 30초 분산)
#   · ㉢ 끊어 내기(첫 번짐 직후 불붙은 전대 퇴각, 번짐 멈춤, 조조 군 사기 −1000).

var sim: BattleSim
var O: Dictionary     # realtime_rules.chain_operation
var X: Dictionary     # combat.stratagem
var host_sq := ""
var charges := 0
var letters := 0
var mode := "idle"
var susp_m := 0       # 의심 × 1000. 음수는 고육계 여유(화면에는 0)
var warned := {}
var win_off := 0      # 첫 명중 뒤 창 시작까지 틱(시드)
var win_start := -1
var win_end := -1
var _win_state := ""
var fires: Array[Dictionary] = []   # {host, next, last, power, n, burned, counter}
var _revert: Array = []             # [틱, 전대 ID, 진형 ID] 긴급 분산 복귀
var _hazards: Array = []            # [만료 틱, 구역 ID]
var _zone_seq := 0
var sensor_until := -1              # 조조 진영 센서 장애 끝 틱
var card_id := -1
var stats := {"letter_t": -1.0, "ignite_t": -1.0, "ignite_power": 0.0, "feigned": false, "susp_at_ignite": 0.0, "detected": 0,
	"spreads": -1, "counters": [], "fires": 0}

func _init(s: BattleSim, cfg: Dictionary) -> void:
	sim = s
	X = cfg
	O = sim.rs.rt("chain_operation", {})
	host_sq = str(sim.rs.scenario.get("chain_explosion_override", {}).get("host_squadron_id", ""))
	charges = int(O.charges)
	letters = int(O.feigned_surrender.letter_uses)
	var w: Dictionary = sim.rs.rt("wind_window", {})
	var lo := int(w.start_after_first_hit_s[0])
	var hi := int(w.start_after_first_hit_s[1])
	win_off = BattleRules.ticks(float(lo + int(sim.rng.u32(0, 0xC4A1, 1) % (hi - lo + 1))), sim.st.hz)

# ============================================================ 질의
func host() -> FleetState:
	for f in sim.st.fleets:
		if f.sq_id == host_sq and f.side == 0:
			return f
	return null

func suspicion() -> float:
	return maxf(0.0, susp_m / 1000.0)

func window_open() -> bool:
	return win_start >= 0 and sim.st.tick >= win_start and sim.st.tick < win_end

func window_over() -> bool:
	return win_end >= 0 and sim.st.tick >= win_end

func dense(f: FleetState) -> bool:
	return X.dense.has(f.formation_id)

func _rank() -> int:
	var order: Array = sim.rs.scenario.get("difficulty_order", [])
	return order.find(str(sim.rs.scenario.get("difficulty", "")))

func _counter_ok(id: String) -> bool:
	var order: Array = sim.rs.scenario.get("difficulty_order", [])
	for c in O.cao_counters:
		if c.id == id:
			return _rank() >= order.find(str(c.min_difficulty))
	return false

func _counter(id: String) -> Dictionary:
	for c in O.cao_counters:
		if c.id == id:
			return c
	return {}

# 투항 중: 황개와 조조군은 서로 쏘지 않는다
func truce(a: FleetState, b: FleetState) -> bool:
	if mode != "feign" or susp_m >= _cap():
		return false
	return (a.sq_id == host_sq and b.side == 1) or (b.sq_id == host_sq and a.side == 1)

func truce_id(id: int) -> bool:
	var h := host()
	return h != null and h.id == id and mode == "feign" and susp_m < _cap()

# 간파 의심(× 1000). 이 값 미만인 동안 투항 중이다
func _cap() -> int:
	return int(O.feigned_surrender.ceasefire_while_suspicion_below) * BattleRules.MILLI

# 조조 진영 센서 장애(bp, 탐지 점수의 진형 탐지%에 더한다)
func sensor_bp(side: int) -> int:
	return int(X.sensor_bp) if side == 1 and sim.st.tick < sensor_until else 0

func burning() -> Array:
	var out := []
	for fi in fires:
		if int(fi.next) >= 0:
			out.append(fi.last)
	return out

# ============================================================ 명령
func letter(h: FleetState) -> String:
	if h == null or h.sq_id != host_sq:
		return "chain_host"
	if letters <= 0 or mode != "idle":
		return "chain_letter_used"
	if charges <= 0 or window_over():
		return "chain_spent"
	letters -= 1
	mode = "feign"
	susp_m = 0
	var fm: Dictionary = O.feigned_surrender.modifiers
	if float(h.max_hull - h.hull) >= float(h.max_hull) * float(fm.self_inflicted_hull_damage_min):
		susp_m = int(fm.self_inflicted_start_suspicion) * 1000   # 고육계: 미리 맞았으면 시작 의심 −30
	warned = {}
	stats.letter_t = sim.st.clock_s()
	sim.emit("chain_letter", h.id, -1, h.pos, {"suspicion": suspicion()})
	return ""

func withdraw(h: FleetState) -> String:
	if mode != "feign":
		return "chain_not_feigning"
	mode = "open"
	sim.emit("chain_withdraw", h.id if h else -1, -1, h.pos if h else Vector2.ZERO)
	return ""

# 발동 조건 5개 + 자산. 가능하면 ""
func ignite_block(h: FleetState, t: FleetState) -> String:
	if mode == "done" or charges <= 0:
		return "chain_spent"
	if h == null or h.sq_id != host_sq or h.out != "" or h.mstate == "retreat":
		return "chain_host"
	if not window_open():
		return "chain_window"
	if t == null or t.dead or t.side != 1:
		return "bad_target"
	if not dense(t):
		return "chain_not_dense"
	if sim.detect and sim.detect.state(0, t.id) != "confirmed":
		return "chain_no_contact"
	if h.pos.distance_to(t.pos) > float(O.trigger_range) + 0.001:
		return "chain_range"
	var wd := Vector2(float(X.wind_dir[0]), float(X.wind_dir[1]))
	if rad_to_deg(absf(wd.angle_to(t.pos - h.pos))) > float(O.wind_cone_deg) + 0.001:
		return "chain_wind"
	return ""

func power_at(d: float) -> float:
	var tab: Array = O.power_by_range   # [[240, .25], [120, .4], [60, .5]] 거리 내림차순
	if d >= float(tab[0][0]):
		return float(tab[0][1])
	for i in range(1, tab.size()):
		var a: Array = tab[i - 1]
		var b: Array = tab[i]
		if d >= float(b[0]):
			return lerpf(float(b[1]), float(a[1]), (d - float(b[0])) / (float(a[0]) - float(b[0])))
	return float(tab[tab.size() - 1][1])

func ignite(h: FleetState, t: FleetState) -> String:
	var why := ignite_block(h, t)
	if why != "":
		return why
	var st := sim.st
	var feigned := mode == "feign"
	var p := power_at(h.pos.distance_to(t.pos))
	var fi := {"host": h.id, "next": st.tick + BattleRules.ticks(float(O.spread.interval_s), st.hz), "last": t.id, "power": p, "n": 0,
		"burned": {t.id: true}, "counter": ""}
	var net := _counter("interception_net")
	if not feigned and _counter_ok("interception_net") and _interceptors(t) >= int(net.min_interceptor_platforms):
		p *= float(net.second_run_power_mul)
		fi.power = p
		_use_counter(fi, "interception_net", t)
	stats.ignite_t = st.clock_s()
	stats.ignite_power = p
	stats.feigned = feigned
	stats.susp_at_ignite = suspicion()
	stats.fires += 1
	charges -= 1
	mode = "done" if charges <= 0 else "open"
	sim.emit("chain_explosion", t.id, h.id, t.pos, {"power": p, "feigned": feigned, "suspicion": suspicion()})
	if fires.all(func(x): return int(x.next) < 0):
		sim.emit("fire_loop", t.id, -1, t.pos, {"on": true})
	_burn(h, t, p)
	fires.append(fi)
	# ㉠ 긴급 분산: 불붙은 전대 반경 150 안의 밀집 전대가 30초 분산(번짐 표적에서 빠진다)
	var ed := _counter("emergency_disperse")
	if fi.counter == "" and _counter_ok("emergency_disperse"):
		var near := _spread_cands(t, fi)
		if not near.is_empty():
			var back := st.tick + BattleRules.ticks(float(ed.duration_s), st.hz)
			for o in near:
				_revert.append([back, o.id, o.formation_id])
				sim.salvo.force_formation(o, str(X.disperse_to))
			_use_counter(fi, "emergency_disperse", t)
	return ""

func _use_counter(fi: Dictionary, id: String, t: FleetState) -> void:
	fi.counter = id
	stats.counters.append(id)
	sim.emit("chain_counter", t.id, -1, t.pos, id)

# 표적 반경 200 안의 조조 요격 플랫폼(요격함·요격 고속정) 수
func _interceptors(t: FleetState) -> int:
	var n := 0
	var ic: Dictionary = X.interceptor
	var r := float(_counter("interception_net").radius)
	for o in sim.st.fleets:
		if o.side != 1 or o.out != "" or o.pos.distance_to(t.pos) > r:
			continue
		for ty in ic.ship_types:
			if o.stages.has(ty):
				n += sim.salvo.present_of(o, ty)
		if ic.equipment.has(o.equip):
			n += sim.salvo.present_of(o, sim.salvo.C.fast_craft.ship_type_id)
	return n

# 한 전대에 불: 선체 손실(최대 선체 × 위력, 이탈 중 대파 0.25), 사기 충격, 위험 지대, 센서 장애
func _burn(src: FleetState, t: FleetState, p: float) -> void:
	var st := sim.st
	sim.salvo.apply_hull(src, t, float(t.max_hull) * p, "assault", sim.salvo.sector(src.pos, t), st.new_event_id(), roundi(float(O.breakaway_heavy_damage_share) * BattleRules.BP))
	t.hit_tick = st.tick
	if t.out == "sunk":
		t.chain_sunk = true   # 같은 틱 연쇄 폭발 격침 → 지휘관 전사(G8-04 3행 ①)
	var k := p / float(X.shock_ref_power)
	var sc: Dictionary = sim.rs.rt("chain_morale_shock_scale", {})
	if sim.morale:
		sim.morale.lose(t, roundi(float(sim.salvo.C.morale.chain_hit_bp) * k * float(sc.target_squadron)))
		st.army_ev[1] += roundi(float(sim.rs.rt("morale_events.army_loss_bp.chain_fire_hit", 0)) * k * float(sc.army))
	sensor_until = st.tick + BattleRules.ticks(float(X.sensor_s), st.hz)
	if sim.terrain:
		var hz: Dictionary = X.hazard
		_zone_seq += 1
		var id := "TRN-ZFIRE-%03d" % _zone_seq
		sim.terrain.zones.append({"id": id, "type": "chain_hazard", "name": "반응로 연쇄 유폭 지대",
			"rect": [t.pos.x - float(hz.size[0]) / 2, t.pos.y - float(hz.size[1]) / 2, float(hz.size[0]), float(hz.size[1])],
			"move_cost_bp": int(hz.move_cost_bp), "sensor_bp": int(hz.sensor_bp), "conceal": int(hz.conceal), "range_bp": int(hz.range_bp), "arc_deg": int(hz.arc_deg)})
		sim.terrain.zones.sort_custom(func(a, b): return str(a.id) < str(b.id))
		_hazards.append([st.tick + BattleRules.ticks(float(hz.duration_s), st.hz), id])
	sim.emit("fire_ignite", t.id, src.id if src else -1, t.pos, {"power": p})

func _spread_cands(from: FleetState, fi: Dictionary) -> Array[FleetState]:
	var out: Array[FleetState] = []
	var at := from.pos if from.out == "" else from.died_pos
	for o in sim.st.fleets:
		if o.side == 1 and o.out == "" and dense(o) and not fi.burned.has(o.id) and o.pos.distance_to(at) <= float(O.spread.radius):
			out.append(o)
	return out

# ============================================================ AI 입력 보조
# 의심 80 결정 카드의 추천: 지금 발동할 수 있는 표적이 있으면 놓는다, 없으면 물러난다(2회차 보존)
func best_target(h: FleetState) -> FleetState:
	var best: FleetState = null
	for o in sim.st.fleets:
		if ignite_block(h, o) == "" and (best == null or h.pos.distance_to(o.pos) < h.pos.distance_to(best.pos)):
			best = o
	return best

func card_resolve(option: String) -> void:
	var h := host()
	card_id = -1
	if option == "ignite":
		var t := best_target(h)
		if t:
			ignite(h, t)
	elif option == "withdraw":
		withdraw(h)

# ============================================================ 한 틱
func step() -> void:
	var st := sim.st
	if win_start < 0 and sim.first_hit_tick >= 0:
		win_start = sim.first_hit_tick + win_off
		win_end = win_start + BattleRules.ticks(float(sim.rs.rt("wind_window.duration_s")), st.hz)
		sim.emit("chain_window", -1, -1, Vector2.ZERO, {"state": "forecast", "start_s": win_start / float(st.hz), "end_s": win_end / float(st.hz)})
	var ws := "open" if window_open() else ("closed" if window_over() else "")
	if ws != _win_state and ws != "":
		_win_state = ws
		sim.emit("chain_window", -1, -1, Vector2.ZERO, {"state": ws})
	var h := host()
	if mode != "done" and (h == null or h.out != "" or window_over() or charges <= 0):
		mode = "done"
	if mode == "feign":
		_suspicion(h)
	for fi in fires:
		if int(fi.next) >= 0 and st.tick >= int(fi.next):
			_spread(fi)
	for r in _revert.duplicate():
		if st.tick >= int(r[0]):
			_revert.erase(r)
			var f := st.by_id(int(r[1]))
			if f and f.out == "":
				sim.salvo.force_formation(f, str(r[2]))   # 긴급 분산 끝: 다시 묶는다
	for z in _hazards.duplicate():
		if st.tick >= int(z[0]):
			_hazards.erase(z)
			sim.terrain.zones = sim.terrain.zones.filter(func(q): return q.id != z[1])

func _suspicion(h: FleetState) -> void:
	var st := sim.st
	var fm: Dictionary = O.feigned_surrender.modifiers
	var mul := 1.0
	if h.charge > 0:
		mul *= float(fm.fast_approach_rate_mul)   # 빠른 접근(돌격)
	if sim.terrain:
		for z in sim.terrain.zones:
			if z.type == "nebula" and BattleTerrain._has(z, h.pos):
				mul *= float(fm.in_nebula_rate_mul)
				break
	if _cheng_yu_absent():
		mul *= float(fm.cheng_yu_absent_rate_mul)
	var rate := float(sim.rs.difficulty_ai().get("suspicion_per_s", 0.0)) * mul
	for o in sim.st.fleets:
		if o.side == 0 and o != h and o.out == "" and o.pos.distance_to(h.pos) <= float(fm.escort_radius):
			rate += float(fm.escort_per_squadron_per_s)   # 호위 동반
	susp_m += roundi(rate * 1000.0 / st.hz)
	_warn()

func on_hit(src: FleetState, tgt: FleetState) -> void:
	if mode != "feign" or src.side != 0 or tgt.side != 1 or src.sq_id == host_sq:
		return
	var h := host()
	var fm: Dictionary = O.feigned_surrender.modifiers
	if h and src.pos.distance_to(h.pos) <= float(fm.alliance_hit_radius):
		susp_m += int(fm.alliance_hit_near_host) * 1000   # 투항 중 연합의 공격
		_warn()

func _cheng_yu_absent() -> bool:
	for f in sim.st.fleets:
		if f.side == 1 and f.staff.any(func(p): return str(p.id) == str(X.cheng_yu_id)):
			return f.out != "" or (sim.morale and sim.morale.forced(f))
	return true

func _warn() -> void:
	var h := host()
	for w in O.feigned_surrender.warnings:
		if susp_m >= int(w) * 1000 and not warned.has(w):
			warned[w] = true
			sim.emit("suspicion", h.id, -1, h.pos, {"level": int(w)})
			if w == O.feigned_surrender.warnings.back() and sim.decisions:
				# 마지막 경고(80)는 결정 카드: 간파까지 남은 게임 초 − 2초, 최대 time_game_s(realtime_rules.decision_cards.suspicion_80)
				var full := float(sim.decisions.cfg.time_game_s)
				var rate := float(sim.rs.difficulty_ai().get("suspicion_per_s", 0.0))
				var left := float(_cap() - susp_m) / BattleRules.MILLI / rate if rate > 0.0 else full
				var rec := "ignite" if best_target(h) else "withdraw"
				card_id = sim.decisions.open_card("suspicion_80", h.id, [{"id": "ignite"}, {"id": "withdraw"}], rec, maxf(1.0, minf(full, left - 2.0)), 0.0)
	if susp_m >= _cap() and mode == "feign":
		_detected(h)

# 간파: 표적(황개에 가장 가까운 밀집 전대)은 분산, 반경 안 조조 전대가 황개를 쫓는다, 연합 군 사기 −1500, 폭발정 1회 소모
func _detected(h: FleetState) -> void:
	var st := sim.st
	var od: Dictionary = O.feigned_surrender.on_detected
	charges -= 1
	mode = "open" if charges > 0 else "done"
	stats.detected += 1
	var tg: FleetState = null
	for o in st.fleets:
		if o.side == 1 and o.out == "" and dense(o) and (tg == null or o.pos.distance_to(h.pos) < tg.pos.distance_to(h.pos)):
			tg = o
	if tg and bool(od.target_to_dispersed):
		sim.salvo.force_formation(tg, str(X.disperse_to))
	st.army_ev[0] += int(od.alliance_army_loss_bp)
	if bool(od.focus_fire_on_host):
		var fc: Dictionary = X.detected_focus
		for o in st.fleets:
			if o.side == 1 and o.out == "" and o.pos.distance_to(h.pos) <= float(fc.radius):
				o.pursue_id = h.id
				o.pursue_until = st.tick + BattleRules.ticks(float(fc.duration_s), st.hz)
	if card_id >= 0 and sim.decisions:
		sim.decisions.drop(card_id)   # 늦었다: 의심 80 카드는 닫는다
		card_id = -1
	sim.emit("chain_detected", h.id, tg.id if tg else -1, h.pos, {"charges": charges})

func _spread(fi: Dictionary) -> void:
	var st := sim.st
	var last := st.by_id(int(fi.last))
	var cands := _spread_cands(last, fi)
	if int(fi.n) >= int(O.spread.max) or cands.is_empty():
		_end_fire(fi)
		return
	var at := last.pos if last.out == "" else last.died_pos
	var t: FleetState = cands[0]
	for o in cands:
		if o.pos.distance_to(at) < t.pos.distance_to(at):
			t = o
	fi.power = float(fi.power) * float(O.spread.power_mul_each)
	fi.n = int(fi.n) + 1
	fi.burned[t.id] = true
	_burn(st.by_id(int(fi.host)), t, float(fi.power))
	fi.last = t.id
	fi.next = st.tick + BattleRules.ticks(float(O.spread.interval_s), st.hz)
	sim.emit("chain_spread", t.id, last.id, t.pos, {"n": fi.n, "power": fi.power})
	# ㉢ 끊어 내기: 번짐이 시작된 직후 불붙은 전대를 퇴각시켜 다음 번짐을 멈춘다
	if fi.counter == "" and _counter_ok("cut_off") and int(fi.n) < int(O.spread.max) and t.out == "":
		_use_counter(fi, "cut_off", t)
		st.army_ev[1] += int(_counter("cut_off").cao_army_loss_bp)
		sim.apply(BattleSim.command(1, [t.id], "retreat"))
		_end_fire(fi)

func _end_fire(fi: Dictionary) -> void:
	fi.next = -1
	stats.spreads = maxi(int(stats.spreads), int(fi.n))
	var g: Array = O.result_grades
	var t := sim.st.by_id(int(fi.last))
	sim.emit("chain_result", t.id, -1, t.pos, {"n": fi.n, "grade": g[mini(int(fi.n), g.size() - 1)], "counter": fi.counter})
	if fires.all(func(x): return int(x.next) < 0):
		sim.emit("fire_loop", t.id, -1, t.pos, {"on": false})

# ============================================================ 황개 AI (위임 중일 때, realtime_rules.chain_host_ai)
# 창 전에는 모든 적에게서 280 밖에 대기하고, 창 시작에 맞춰 서신을 보내 가장 가까운 밀집 전대에 120까지 붙어 발동한다.
# 입력은 공개 투영의 접촉(확인·밀집 여부)과 공개된 기류 창 시각뿐이다. 처리했으면 true(지휘관 AI는 이 전대를 건너뛴다).
func host_think(f: FleetState, foes: Array[Dictionary]) -> bool:
	if mode == "done" or charges <= 0 or f.sq_id != host_sq or int(stats.fires) > 0:
		return false   # AI는 한 번 발동하면 끝낸다. 남은 폭발정은 플레이어 몫
	var H: Dictionary = X.host_ai
	var st := sim.st
	var near_d := 1e9
	var near_p := Vector2.ZERO
	var tg: Dictionary = {}
	for c in foes:
		if c.state == "lost":
			continue
		var d := f.pos.distance_to(c.pos)
		if d < near_d:
			near_d = d
			near_p = c.pos
		if c.state == "confirmed" and c.get("dense", false) and (tg.is_empty() or d < f.pos.distance_to(tg.pos)):
			tg = c
	var td := f.pos.distance_to(tg.pos) if not tg.is_empty() else 1e9
	if mode == "idle" or (mode == "open" and not window_open()):
		if mode == "idle" and letters > 0 and not tg.is_empty() and win_start >= 0:
			var travel := maxf(0.0, td - float(H.approach)) / maxf(1.0, f.speed)
			if float(win_start - st.tick) / st.hz <= travel + float(H.letter_margin_s):
				sim.apply(BattleSim.command(0, [f.id], "letter"))
				return true
		_aim(f, -1)
		var sl := float(H.slack)
		if near_d < float(H.standoff) - sl:
			_go(f, f.pos + (f.pos - near_p).normalized() * float(H.back_step))
		elif not tg.is_empty() and win_start >= 0 and td > float(H.stage) + sl and near_d > float(H.standoff) + sl:
			_go(f, tg.pos + (f.pos - tg.pos) / td * float(H.stage))
		elif f.has_move:
			_go(f, f.pos)
		return true
	# 투항 중이거나 위장 없이 창 안: 붙어서 발동한다. 밀집 표적이 없으면 기다린다(방해 뒤 재시도)
	if tg.is_empty():
		_aim(f, -1)
		if f.has_move:
			_go(f, f.pos)
		return true
	var t := st.by_id(int(tg.id))
	if window_open() and ignite_block(f, t) == "":
		var late := st.tick >= win_start + BattleRules.ticks(float(H.late_fire_s), st.hz)
		if td <= float(H.approach) + float(H.fire_tol) or late:
			sim.apply(BattleSim.command(0, [f.id], "ignite", t.id))
			return true
	# 흐름(+X) ±(콘 − 10°) 안에서 접근
	var cone := deg_to_rad(float(O.wind_cone_deg) - float(H.cone_margin_deg))
	var a := clampf((tg.pos - f.pos).angle(), -cone, cone)
	_aim(f, -1)
	_go(f, tg.pos - Vector2(cos(a), sin(a)) * float(H.approach))
	return true

func _go(f: FleetState, p: Vector2) -> void:
	sim.apply(BattleSim.command(0, [f.id], "ai_move", -1, p))

func _aim(f: FleetState, id: int) -> void:
	sim.apply(BattleSim.command(0, [f.id], "ai_target", id))

# ============================================================ 투영·지문
func view(side: int) -> Dictionary:
	var st := sim.st
	var h := host()
	var d := {"mode": mode, "suspicion": suspicion(), "window": {}}
	if win_start >= 0:
		d.window = {"start_s": win_start / float(st.hz), "end_s": win_end / float(st.hz), "open": window_open()}
	if side == 0:
		d.host_id = h.id if h else -1
		d.charges = charges
		d.letters = letters
		d.burning = burning()
	return d

func fingerprint() -> String:
	return "|chain%s.%d.%d.%d.%d.%d.%d" % [mode, charges, letters, susp_m, win_start, sensor_until, fires.size()]
