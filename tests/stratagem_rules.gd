extends SceneTree

# M9 완료 기준(제안서 §4.11, §9): 조건 5개(기류 창·거리 240·밀집·확인 접촉·흐름 ±60°)가 모두 맞으면 확률 없이 확정 발동,
# 하나라도 빠지면 거부, 방해(분산) 뒤 다시 밀집하면 재시도 성공. 위력·번짐·결과 등급, 조조 차단 3종(난이도), 서신·의심 가감·경고·
# 의심 80 결정 카드·간파, 투항 중 상호 불사격, 센서 장애·위험 지대, 연쇄 폭발 격침 = 전사, 효과음 사건, 황개 AI, 투영, 지문.
# 강습: 전제(강습모함·거리 80·쿨다운), 진형 붕괴(퇴각·전환·측후면 명중, 무력형), 성공률, 부대 강습·기함 진입·강행 돌입 결과.
# 적벽 프로필을 읽고 상태를 직접 만든다(AI 끔). 헤드리스, 실패하면 종료 코드 1.

const SQ := {"host": "RC-SUN-SQ-03", "guan": "RC-LIU-SQ-02", "liuqi": "RC-LIU-SQ-03", "zhou": "RC-SUN-SQ-01",
	"cao": "RC-CAO-SQ-01", "cao2": "RC-CAO-SQ-02", "cao3": "RC-CAO-SQ-03", "wen": "RC-CAO-SQ-04", "cai": "RC-CAO-SQ-05", "chun": "RC-CAO-SQ-06"}

func _initialize() -> void:
	call_deferred("_run")

func _sim(diff := "표준", seed_id := 1) -> BattleSim:
	var p := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", diff)
	var s := BattleSim.new(seed_id, BattleRules.TICK_HZ, p)
	s.st.ai_timer = 1 << 40   # AI 끔
	return s

func _f(s: BattleSim, key: String) -> FleetState:
	for f in s.st.fleets:
		if f.sq_id == SQ.get(key, key):
			return f
	return null

func _ticks(s: BattleSim, n: int) -> Array:
	var evs := []
	for i in n:
		s.step()
		evs.append_array(s.drain_events())
	return evs

func _kinds(evs: Array, kind: String) -> Array:
	return evs.filter(func(e): return e.kind == kind)

func _confirm(s: BattleSim, t: FleetState) -> void:
	s.detect.contacts[0][t.id] = {"seen": s.st.tick, "pos": t.pos, "state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}

# 화공 판: 황개 (700,450), 표적 문빙(밀집 FRM-04) (900,450) = 거리 200 정동. 채모(밀집) 110 아래, 서황(밀집) 그 너머.
# 나머지 조조 전대는 멀리 둔다. 기류 창은 지금 연다.
func _stage(diff := "표준", seed_id := 1) -> BattleSim:
	var s := _sim(diff, seed_id)
	var far := 0
	for f in s.st.fleets:
		f.pos = Vector2(100 + far * 90, 860) if f.side == 0 else Vector2(1500, 80 + far * 60)
		far += 1
	_f(s, "host").pos = Vector2(700, 450)
	_f(s, "wen").pos = Vector2(900, 450)
	_n1(s).pos = Vector2(900, 560)
	_f(s, "cao3").pos = Vector2(1000, 650)
	s.first_hit_tick = 0
	s.chain.win_start = 0
	s.chain.win_end = 1 << 30
	_confirm(s, _f(s, "wen"))
	return s

# 첫 번짐 상대: 채모(표준 이상). 입문에는 채모가 없어 조조 본대(밀집)를 쓴다
func _n1(s: BattleSim) -> FleetState:
	return _f(s, "cai") if _f(s, "cai") else _f(s, "cao")

func _ignite(s: BattleSim, key := "wen") -> Array:
	s.issue(BattleSim.command(0, [_f(s, "host").id], "ignite", _f(s, key).id))
	return s.drain_events()

func _rejected(evs: Array) -> String:
	var r := _kinds(evs, "rejected")
	return str(r[0].value) if not r.is_empty() else ""

func _run() -> void:
	var s := _sim()
	var C := s.chain
	if not TestCheck.ok(self, C != null and C.host_sq == SQ.host and C.charges == 2 and C.letters == 1 and str(C.O.status) == "proposed", "데이터: 황개 화공대, 폭발정 2, 서신 1, 제안값"): return
	if not TestCheck.ok(self, C.win_off >= 5400 and C.win_off <= 6000, "기류 창 시작 = 첫 명중 + 540~600초(시드): %d틱" % C.win_off): return
	if not TestCheck.ok(self, s.cmd != null and s.assault != null, "지휘·강습 켜짐"): return
	if not TestCheck.ok(self, SalvoFixture.sim([SalvoFixture.def("A", 100, 100, [["SHP-04", 1]])], [SalvoFixture.def("B", 900, 100, [["SHP-04", 1]])]).chain == null, "시나리오 없는 판은 화공 없음"): return

	# --- 기류 창: 첫 명중 뒤 예보, 열림, 닫힘 ---
	s.first_hit_tick = s.st.tick
	var fh := s.st.tick
	var evs := _ticks(s, 1)
	var cw := _kinds(evs, "chain_window")
	if not TestCheck.ok(self, C.win_start == fh + C.win_off and C.win_end == C.win_start + 1800 and cw.size() == 1 and cw[0].value.state == "forecast", "예보: 시작 %d, 길이 180초" % C.win_start): return
	C.win_start = s.st.tick + 3
	C.win_end = C.win_start + 1800
	evs = _ticks(s, 4)
	if not TestCheck.ok(self, C.window_open() and _kinds(evs, "chain_window").any(func(e): return e.value.state == "open"), "창 열림"): return
	C.win_end = s.st.tick + 1
	evs = _ticks(s, 2)
	if not TestCheck.ok(self, not C.window_open() and C.mode == "done" and _kinds(evs, "chain_window").any(func(e): return e.value.state == "closed"), "창이 끝나면 더 쓸 수 없다"): return

	# --- 완료 기준 1: 조건 5개 충족 시 확정 발동(확률 없음: 시드가 달라도 같은 결과) ---
	var loss := -1
	for seed_id in [1, 2, 3, 4, 5]:
		s = _stage("표준", seed_id)
		var t := _f(s, "wen")
		var h0 := t.hull
		evs = _ignite(s)
		var ce := _kinds(evs, "chain_explosion")
		if not TestCheck.ok(self, _rejected(evs) == "" and ce.size() == 1, "시드 %d: 발동 (%s)" % [seed_id, _rejected(evs)]): return
		if not TestCheck.ok(self, absf(float(ce[0].value.power) - 0.3) < 1e-6 and h0 - t.hull == roundi(t.max_hull * 0.3), "거리 200 위력 30%%: 선체 %d → %d" % [h0, t.hull]): return
		if loss >= 0 and not TestCheck.ok(self, h0 - t.hull == loss, "시드와 무관한 같은 결과"): return
		loss = h0 - t.hull
		if not TestCheck.ok(self, s.chain.charges == 1 and s.chain.mode == "open", "폭발정 1회 소모"): return

	# --- 조건 하나씩 빠지면 거부 ---
	var cases := {
		"chain_window": func(q: BattleSim): q.chain.win_start = q.st.tick + 100,
		"chain_range": func(q: BattleSim): _f(q, "host").pos = Vector2(650, 450),
		"chain_not_dense": func(q: BattleSim): q.salvo.force_formation(_f(q, "wen"), "FRM-05"),
		"chain_no_contact": func(q: BattleSim): q.detect.contacts[0][_f(q, "wen").id].state = "estimated",
		"chain_wind": func(q: BattleSim): _f(q, "host").pos = Vector2(1100, 450),
	}
	for why in cases:
		s = _stage()
		cases[why].call(s)
		evs = _ignite(s)
		if not TestCheck.ok(self, _rejected(evs) == why and _kinds(evs, "chain_explosion").is_empty() and s.chain.charges == 2, "조건 빠짐 → %s (%s)" % [why, _rejected(evs)]): return
	# 흐름 경계: +X에서 60°는 되고 61°는 안 된다
	for deg in [60.0, 61.0]:
		s = _stage()
		var hp := Vector2(900, 450) - Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * 200.0
		_f(s, "host").pos = hp
		evs = _ignite(s)
		if not TestCheck.ok(self, (_rejected(evs) == "") == (deg <= 60.0), "흐름 %d°: %s" % [deg, _rejected(evs)]): return

	# --- 완료 기준 2: 방해(분산) 뒤 재시도 ---
	s = _stage()
	var wen := _f(s, "wen")
	s.salvo.force_formation(wen, "FRM-05")
	evs = _ignite(s)
	if not TestCheck.ok(self, _rejected(evs) == "chain_not_dense" and s.chain.charges == 2, "분산 방해: 거부, 폭발정 유지"): return
	_ticks(s, 30)
	s.salvo.force_formation(wen, "FRM-04")
	_confirm(s, wen)
	evs = _ignite(s)
	if not TestCheck.ok(self, _rejected(evs) == "" and _kinds(evs, "chain_explosion").size() == 1, "다시 밀집하면 재시도 성공"): return

	# --- 위력 표(선형) ---
	var P := {300.0: 0.25, 240.0: 0.25, 180.0: 0.325, 120.0: 0.4, 90.0: 0.45, 60.0: 0.5, 20.0: 0.5}
	for d in P:
		if not TestCheck.ok(self, absf(s.chain.power_at(d) - P[d]) < 1e-6, "위력 %d → %.3f (%.3f)" % [d, P[d], s.chain.power_at(d)]): return

	# --- 번짐·결과 등급(입문: 차단 없음 → 2회 "연환 대화재"), 효과음 사건, 센서 장애·위험 지대 ---
	s = _stage("입문")
	evs = _ignite(s)
	if not TestCheck.ok(self, _kinds(evs, "fire_ignite").size() == 1 and _kinds(evs, "fire_loop").size() == 1 and bool(_kinds(evs, "fire_loop")[0].value.on), "발동 사건: chain_explosion, fire_ignite, fire_loop 켬"): return
	if not TestCheck.ok(self, s.chain.sensor_bp(1) == -4000 and s.chain.sensor_bp(0) == 0 and s.terrain.zones.any(func(z): return z.type == "chain_hazard"), "조조 센서 −40%, 위험 지대"): return
	var cai := _n1(s)
	var c0 := cai.hull
	evs = _ticks(s, 200)
	var sp := _kinds(evs, "chain_spread")
	if not TestCheck.ok(self, sp.size() == 1 and sp[0].sq == cai.id and absf(float(sp[0].value.power) - 0.15) < 1e-6 and c0 - cai.hull == roundi(cai.max_hull * 0.15), "20초: 채모로 번짐, 위력 절반"): return
	evs = _ticks(s, 200)
	sp = _kinds(evs, "chain_spread")
	if not TestCheck.ok(self, sp.size() == 1 and sp[0].sq == _f(s, "cao3").id, "40초: 서황으로 번짐"): return
	evs = _ticks(s, 200)
	var res := _kinds(evs, "chain_result")
	if not TestCheck.ok(self, res.size() == 1 and int(res[0].value.n) == 2 and res[0].value.grade == "연환 대화재" and _kinds(evs, "fire_loop").any(func(e): return not e.value.on), "최대 2회 → 연환 대화재, fire_loop 끔"): return
	_ticks(s, 1600 - 600 - 2)
	if not TestCheck.ok(self, s.chain.sensor_bp(1) == -4000 and s.terrain.zones.filter(func(z): return z.type == "chain_hazard").size() == 1, "불마다 120초: 마지막 번짐(40초)의 지대만 남음"): return
	_ticks(s, 3)
	if not TestCheck.ok(self, s.chain.sensor_bp(1) == 0 and not s.terrain.zones.any(func(z): return z.type == "chain_hazard"), "마지막 불 120초 뒤 센서 장애·위험 지대 끝"): return

	# --- 조조 차단: 표준 ㉢ 끊어 내기(첫 번짐 직후), 상급 ㉠ 긴급 분산(발동 때), ㉡ 요격망(위장 없는 돌입) ---
	s = _stage("표준")
	_ignite(s)
	var ev0: int = s.st.army_ev[1]
	evs = _ticks(s, 200)
	cai = _f(s, "cai")
	res = _kinds(evs, "chain_result")
	if not TestCheck.ok(self, s.chain.stats.counters == ["cut_off"] and cai.retreat_order and res.size() == 1 and res[0].value.grade == "큰 타격", "표준 ㉢: 번짐 1회에서 멈춤, 불붙은 전대 퇴각 (%s)" % [s.chain.stats.counters]): return
	if not TestCheck.ok(self, s.st.army_ev[1] - ev0 >= 1000, "㉢ 조조 군 사기 −1000"): return
	s = _stage("상급")
	evs = _ignite(s)
	cai = _f(s, "cai")
	if not TestCheck.ok(self, s.chain.stats.counters == ["emergency_disperse"] and cai.formation_id == "FRM-05", "상급 ㉠: 반경 150 밀집 전대 분산"): return
	evs = _ticks(s, 200)
	res = _kinds(evs, "chain_result")
	if not TestCheck.ok(self, res.size() == 1 and int(res[0].value.n) == 0 and res[0].value.grade == "흔들림", "㉠ 뒤 번질 곳 없음 → 흔들림"): return
	_ticks(s, 101)
	if not TestCheck.ok(self, cai.formation_id == "FRM-03", "30초 뒤 다시 묶는다"): return
	s = _stage("상급")
	s.chain.mode = "open"   # 위장 없는 돌입(2회차)
	_f(s, "chun").pos = Vector2(950, 380)
	evs = _ignite(s)
	if not TestCheck.ok(self, s.chain.stats.counters == ["interception_net"] and absf(float(_kinds(evs, "chain_explosion")[0].value.power) - 0.15) < 1e-6, "㉡ 요격 플랫폼 8척 이상: 위력 ×0.5"): return
	s = _stage("상급")
	_f(s, "chun").pos = Vector2(950, 380)
	s.chain.mode = "feign"
	evs = _ignite(s)
	if not TestCheck.ok(self, not s.chain.stats.counters.has("interception_net") and absf(float(_kinds(evs, "chain_explosion")[0].value.power) - 0.3) < 1e-6, "㉡은 투항 중(1회차)에는 효과 없음"): return
	s = _stage("입문")
	_ignite(s)
	if not TestCheck.ok(self, s.chain.stats.counters.is_empty(), "입문 조조는 차단하지 않는다"): return

	# --- 연쇄 폭발 격침 = 지휘관 전사(G8-04 3행 ①) ---
	s = _stage()
	wen = _f(s, "wen")
	wen.hull = 1
	_ignite(s)
	_ticks(s, 1)
	if not TestCheck.ok(self, wen.out == "sunk" and wen.chain_sunk and wen.cmdr_state == "killed", "화공 격침 → 전사 (%s)" % wen.cmdr_state): return

	# --- 서신과 의심 ---
	s = _stage()
	var host := _f(s, "host")
	s.issue(BattleSim.command(0, [host.id], "letter"))
	evs = s.drain_events()
	if not TestCheck.ok(self, s.chain.mode == "feign" and s.chain.letters == 0 and _kinds(evs, "chain_letter").size() == 1, "서신: 투항 중"): return
	s.issue(BattleSim.command(0, [host.id], "letter"))
	if not TestCheck.ok(self, _rejected(s.drain_events()) == "chain_letter_used", "서신은 한 번"): return
	wen = _f(s, "wen")
	if not TestCheck.ok(self, s.chain.truce(host, wen) and s.chain.truce(wen, host) and not s.chain.truce(_f(s, "guan"), wen), "투항 중: 황개 ↔ 조조 불사격"): return
	evs = _ticks(s, 100)
	if not TestCheck.ok(self, absf(s.chain.suspicion() - 8.0) < 1e-6, "표준 0.8/초 × 10초 = 8 (%.3f)" % s.chain.suspicion()): return
	if not TestCheck.ok(self, not _kinds(evs, "salvo").any(func(e): return (e.sq == host.id and s.st.by_id(e.other).side == 1) or (e.other == host.id)), "투항 중 서로 쏘지 않았다"): return
	# 가감 요인
	var rates := {}
	for k in ["escort", "charge", "nebula", "cheng_yu", "base"]:
		s = _stage()
		host = _f(s, "host")
		s.issue(BattleSim.command(0, [host.id], "letter"))
		match k:
			"escort":
				_f(s, "guan").pos = host.pos + Vector2(0, 80)
			"charge":
				host.charge = 1 << 20
			"nebula":
				host.pos = Vector2(650, 100)
			"cheng_yu":
				s.remove_fleet(_f(s, "cao"), "escaped")
		var a0 := s.chain.susp_m
		_ticks(s, 1)   # 한 틱(전대 간격 110이 호위 반경 100보다 커서 서 있으면 곧 밀려난다)
		rates[k] = float(s.chain.susp_m - a0) * 10 / 1000.0
	if not TestCheck.ok(self, absf(rates.base - 0.8) < 1e-6 and absf(rates.escort - 1.1) < 1e-6 and absf(rates.charge - 1.2) < 1e-6 and absf(rates.nebula - 0.4) < 1e-6 and absf(rates.cheng_yu - 0.4) < 1e-6, "가감: 기본 0.8, 호위 +0.3, 빠른 접근 ×1.5, 성운 ×0.5, 정욱 부재 ×0.5 %s" % [rates]): return
	s = _stage()
	host = _f(s, "host")
	s.issue(BattleSim.command(0, [host.id], "letter"))
	var g := _f(s, "guan")
	g.pos = host.pos + Vector2(0, 250)
	var b0 := s.chain.susp_m
	s.chain.on_hit(g, _f(s, "wen"))
	s.chain.on_hit(_f(s, "liuqi"), _f(s, "wen"))   # 반경 300 밖 전대의 명중은 세지 않는다
	if not TestCheck.ok(self, s.chain.susp_m - b0 == 10000, "투항 중 연합의 명중(반경 300) +10"): return
	s = _stage()
	host = _f(s, "host")
	s.salvo.apply_hull(null, host, host.max_hull * 0.1, "engagement", "front", 1)
	s.issue(BattleSim.command(0, [host.id], "letter"))
	_ticks(s, 100)
	if not TestCheck.ok(self, s.chain.susp_m == -30000 + 8000 and s.chain.suspicion() == 0.0, "고육계: 선체 10% 피해 뒤 서신 → 시작 −30 (%d)" % s.chain.susp_m): return
	# 경고 50·80, 의심 80 결정 카드, 간파 100
	s = _stage()
	host = _f(s, "host")
	s.issue(BattleSim.command(0, [host.id], "letter"))
	s.chain.susp_m = 49950
	evs = _ticks(s, 1)
	if not TestCheck.ok(self, _kinds(evs, "suspicion").size() == 1 and int(_kinds(evs, "suspicion")[0].value.level) == 50, "의심 50 경고"): return
	s.chain.susp_m = 79950
	evs = _ticks(s, 1)
	var pend: Array = s.projection(0).pending_decisions.filter(func(c): return c.kind == "suspicion_80")
	if not TestCheck.ok(self, pend.size() == 1 and pend[0].rec == "ignite" and absf(float(pend[0].time_total) - minf(30.0, (100.0 - 80.03) / 0.8 - 2.0)) < 0.05, "의심 80 결정 카드: 사거리 안이면 발동 추천, 시간 = 간파까지 − 2초 %s" % [pend]): return
	s.issue(BattleSim.command(0, [], "decide", -1, Vector2.ZERO, {"id": pend[0].id, "option": "withdraw"}))
	if not TestCheck.ok(self, s.chain.mode == "open" and s.chain.charges == 2 and not s.chain.truce(host, _f(s, "wen")), "물러난다: 위장 해제, 폭발정 보존"): return
	s = _stage()
	host = _f(s, "host")
	s.issue(BattleSim.command(0, [host.id], "letter"))
	s.chain.susp_m = 79950
	_ticks(s, 1)
	pend = s.projection(0).pending_decisions
	s.issue(BattleSim.command(0, [], "decide", -1, Vector2.ZERO, {"id": pend[0].id, "option": "ignite"}))
	if not TestCheck.ok(self, s.chain.stats.fires == 1 and s.chain.stats.feigned, "의심 80 카드 → 지금 놓는다"): return
	s = _stage()
	host = _f(s, "host")
	s.issue(BattleSim.command(0, [host.id], "letter"))
	var aev: int = s.st.army_ev[0]
	s.chain.susp_m = 99950
	evs = _ticks(s, 1)
	wen = _f(s, "wen")
	if not TestCheck.ok(self, _kinds(evs, "chain_detected").size() == 1 and s.chain.mode == "open" and s.chain.charges == 1 and wen.formation_id == "FRM-05", "간파: 표적 분산, 폭발정 1회 소모"): return
	if not TestCheck.ok(self, s.st.army_ev[0] - aev == 1500 and wen.pursue_id == host.id and not s.chain.truce(host, wen), "간파: 연합 군 사기 −1500, 황개 집중 사격"): return
	_f(s, "cai").pos = Vector2(880, 470)
	_confirm(s, _f(s, "cai"))
	evs = _ignite(s, "cai")
	if not TestCheck.ok(self, _rejected(evs) == "" and not s.chain.stats.feigned, "2회차: 위장 없이 돌입"): return

	# --- 황개 AI(위임): 창 전 280 밖 대기, 창에 맞춘 서신, 120에서 발동 ---
	s = _stage()
	host = _f(s, "host")
	var foes: Array[Dictionary] = [{"id": _f(s, "wen").id, "pos": Vector2(900, 450), "state": "confirmed", "dense": true}]
	s.chain.win_start = s.st.tick + 6000
	s.chain.host_think(host, foes)
	if not TestCheck.ok(self, s.chain.mode == "idle" and host.has_move and host.move_to.x < 700, "창 전: 대기 거리 밖으로 물러난다"): return
	var travel := (200.0 - 120.0) / host.speed
	s.chain.win_start = s.st.tick + BattleRules.ticks(travel + 5.0, 10)
	s.chain.host_think(host, foes)
	if not TestCheck.ok(self, s.chain.mode == "feign", "창 시작 ≈ 접근 시간이면 서신"): return
	s.chain.host_think(host, foes)
	if not TestCheck.ok(self, host.move_to.distance_to(Vector2(780, 450)) < 1.0, "표적 120 앞(흐름 쪽)으로 접근: %s" % host.move_to): return
	s.chain.win_start = s.st.tick
	host.pos = Vector2(780, 450)
	foes[0].pos = _f(s, "wen").pos
	s.chain.host_think(host, foes)
	if not TestCheck.ok(self, s.chain.stats.fires == 1, "창 안 120: 발동"): return
	if not TestCheck.ok(self, not s.chain.host_think(host, foes), "한 번 발동한 뒤 AI는 화공을 놓는다"): return

	# --- 투영·지문 ---
	s = _stage()
	var v0 := s.projection(0)
	var v1 := s.projection(1)
	if not TestCheck.ok(self, v0.chain_op.has("host_id") and v0.chain_op.has("charges") and not v1.chain_op.has("host_id") and v1.chain_op.has("suspicion") and v0.chain_op.window.open, "chain_op: 운용 진영만 자산 정보, 의심·창은 공개"): return
	var wc: Array = v0.squadrons.filter(func(q): return q.id == _f(s, "wen").id)
	if not TestCheck.ok(self, wc.size() == 1 and wc[0].contact == "confirmed" and wc[0].dense and not wc[0].has("formation_id"), "확인 접촉에 밀집 여부만"): return
	var fps := []
	for i in 2:
		s = _stage()
		host = _f(s, "host")
		s.issue(BattleSim.command(0, [host.id], "letter"))
		_ticks(s, 50)
		_ignite(s)
		_ticks(s, 300)
		fps.append(s.fingerprint())
	var fp0 := s.fingerprint()
	s.chain.susp_m += 1
	var fp1 := s.fingerprint()
	_f(s, "cao2").cmdr_state = "light"
	if not TestCheck.ok(self, fps[0] == fps[1] and fp0 != fp1 and fp1 != s.fingerprint(), "같은 입력 같은 지문, 지문에 화공·지휘 상태 포함"): return

	# --- 강습 ---
	s = _stage()
	var zhou := _f(s, "zhou")
	var cao := _f(s, "cao")
	zhou.pos = Vector2(800, 300)
	cao.pos = Vector2(870, 300)
	_confirm(s, cao)
	var A := s.assault
	if not TestCheck.ok(self, A.block(_f(s, "guan"), cao, "unit") == "assault_no_carrier", "강습모함 없으면 불가"): return
	zhou.pos = Vector2(780, 300)
	if not TestCheck.ok(self, A.block(zhou, cao, "unit") == "assault_range", "거리 80 밖 불가"): return
	zhou.pos = Vector2(800, 300)
	if not TestCheck.ok(self, A.block(zhou, cao, "unit") == "" and A.fleet_flag(cao) and not A.fleet_flag(_f(s, "wen")), "거리 80 안 가능, 기함 진입 표적은 승패 기함(조조)뿐(Q73)"): return
	if not TestCheck.ok(self, A._need_hits(_f(s, "guan")) == 1 and A._need_hits(zhou) == 2 and A._need_hits(_f(s, "liuqi")) == 3, "붕괴 요건: 특급 1, 강습형 2, 그 밖 3"): return
	if not TestCheck.ok(self, not A.is_open(zhou, cao), "열리지 않음"): return
	cao.fr_hits.assign([s.st.tick - 10, s.st.tick - 5])
	if not TestCheck.ok(self, A.is_open(zhou, cao) and not A.is_open(_f(s, "liuqi"), cao), "30초 안 측후면 2회: 강습형은 열림"): return
	cao.fr_hits.assign([s.st.tick - 400, s.st.tick - 5])
	if not TestCheck.ok(self, not A.is_open(zhou, cao), "30초 지난 명중은 세지 않는다"): return
	cao.form_left = 10
	if not TestCheck.ok(self, A.is_open(zhou, cao), "진형 전환 중이면 열림"): return
	cao.form_left = 0
	var bp_u := A.chance_bp(zhou, cao, "unit")
	var bp_f := A.chance_bp(zhou, cao, "flagship")
	var exp := clampi(5000 + (A.best_might(zhou) - A.best_might(cao)) * 100, 1000, 9000)
	if not TestCheck.ok(self, bp_u == exp and bp_f == exp / 2 / 3, "성공률: 부대 %d, 기함 강행(호치 ×0.5, 1/3) %d" % [bp_u, bp_f]): return
	# 결과(성공률을 고정해 두 갈래를 본다)
	A.A.min_bp = 10000
	A.A.max_bp = 10000
	var wen2 := _f(s, "wen")
	wen2.pos = Vector2(860, 330)
	_confirm(s, wen2)
	var n0 := s.salvo.present_ships(wen2)
	var m0 := wen2.morale_bp
	s.issue(BattleSim.command(0, [zhou.id], "assault", wen2.id, Vector2.ZERO, {"type": "unit"}))
	evs = s.drain_events()
	if not TestCheck.ok(self, _kinds(evs, "assault").size() == 1 and bool(_kinds(evs, "assault")[0].value.ok) and s.salvo.present_ships(wen2) == n0 - 1 and m0 - wen2.morale_bp >= 1500, "부대 강습 성공: 1척 나포, 사기 −1500"): return
	s.issue(BattleSim.command(0, [zhou.id], "assault", wen2.id, Vector2.ZERO, {"type": "unit"}))
	if not TestCheck.ok(self, _rejected(s.drain_events()) == "assault_cooldown", "쿨다운 60초"): return
	zhou.assault_cd = 0
	cao.fr_hits.assign([s.st.tick - 3, s.st.tick - 2])   # 열림(강습형 2회)
	m0 = cao.morale_bp
	s.issue(BattleSim.command(0, [zhou.id], "assault", cao.id, Vector2.ZERO, {"type": "flagship"}))
	_ticks(s, 1)
	if not TestCheck.ok(self, cao.boarded and m0 - cao.morale_bp >= 4000 and cao.cmdr_state == "severe" and s.salvo.commander_mul(cao, "assault") == 1.0, "기함 진입 성공: 사기 −4000, 지휘관 중상, 보정 소멸"): return
	if not TestCheck.ok(self, cao.cmdr_sub == "CHR-0047" and not s.st.over, "조조 중상 → 허저(부제독) 승계, 전투 계속"): return
	A.A.min_bp = 0
	A.A.max_bp = 0
	zhou.assault_cd = 0
	var c1 := s.salvo.present_of(zhou, "SHP-01")
	m0 = zhou.morale_bp
	cao.fr_hits.clear()
	cao.mstate = "stable"   # 열리지 않은 기함
	zhou.pos = Vector2(800, 300)   # 한 틱 사이 적 간격(90)에 밀렸다
	cao.pos = Vector2(870, 300)
	_confirm(s, cao)
	s.issue(BattleSim.command(0, [zhou.id], "assault", cao.id, Vector2.ZERO, {"type": "flagship"}))
	evs = s.drain_events()
	if not TestCheck.ok(self, _kinds(evs, "assault").size() == 1 and _kinds(evs, "assault")[0].value.forced and s.salvo.present_of(zhou, "SHP-01") == c1 - 1 and m0 - zhou.morale_bp == 3000, "강행 돌입 실패: 강습모함 1척 상실, 자기 사기 −3000"): return

	print("STRATAGEM_RULES_PASS")
	quit(0)
