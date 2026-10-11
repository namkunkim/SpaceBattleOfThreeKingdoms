extends SceneTree

# P7 수리·보급 메뉴: 자동 보급 위의 수동 층(우선 대상 지정, 보급 중지/재개).
#  1. 수동 명령 미사용 시 지문이 변경 전(기준값)과 같다 / 2. 메뉴 읽기값(레벨·재고·도크·대상)은 보급함 아군에만, 적 접촉에 새 키 없음
#  3. 우선 지정이 보급 순서를 바꾼다 / 4. 중지·재개 / 5. 거부 사유 / 6. 명령이 command_log에 남고 재생하면 같은 지문
#  7. 화면: 보급함 선택 시 보급·수리 탭, 보급함 없는 함대·적에는 없다 / 8. 안개: 적 보급함 정보 없음
const BASE_FP := "b74837b8b13a48d5b49533d8a035f567"   # P7 이전 코드로 잰 같은 장면의 지문(md5)

func _initialize() -> void:
	call_deferred("_run")

func _d(name: String, x: float, y: float, comp: Array, faction := "liu_bei", flag := false) -> Dictionary:
	var d := SalvoFixture.def(name, x, y, comp, flag)
	d.faction_id = faction
	return d

# 보급함 S(SHP-05 2척) 곁에 탄약·횟수가 빈 손님 A·B·C
func _mk() -> BattleSim:
	var full := SalvoFixture.combat()
	var s := SalvoFixture.sim([_d("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], "liu_bei", true), _d("A", 900, 450, [["SHP-04", 2]]), _d("B", 800, 540, [["SHP-04", 2]]), _d("C", 700, 450, [["SHP-04", 2], ["SHP-03", 2]])],
		[_d("Z", 1500, 850, [["SHP-04", 1]], "cao_cao")], 1, "", func(cb): cb.supply = full.supply)
	for i in range(1, 4):
		var f: FleetState = s.st.fleets[i]
		for cat in f.ammo:
			f.ammo[cat] = 0
		for cat in f.wch:
			f.wch[cat] = 0
	return s

func _ticks(s: BattleSim, n: int) -> void:
	for i in n:
		s.step()

# n틱 동안 보급이 끝난 손님 ID들(사건 순서)
func _served(s: BattleSim, n: int) -> Array:
	var out := []
	for i in n:
		s.step()
		for e in s.drain_events():
			if e.kind == "supply":
				out.append(e.sq)
	return out

func _rej(s: BattleSim) -> Array:
	var out := []
	for e in s.drain_events():
		if e.kind == "rejected":
			out.append(e.value)
	return out

func _run() -> void:
	# --- 1. 수동 명령 미사용: 지문 불변 ---
	var s := _mk()
	_ticks(s, 4000)
	var fp := s.fingerprint()
	if not TestCheck.ok(self, fp.md5_text() == BASE_FP and not s.supply.fingerprint().contains("|man"), "수동 명령 없음: 지문이 P7 이전과 같다 %s" % fp.md5_text()): return

	# --- 2. 메뉴 읽기값 ---
	s = _mk()
	var S: FleetState = s.st.fleets[0]
	var A: FleetState = s.st.fleets[1]
	var B: FleetState = s.st.fleets[2]
	var C: FleetState = s.st.fleets[3]
	_ticks(s, 5)
	var pj := s.projection(0)
	var sq: Dictionary = pj.squadrons.filter(func(q): return q.id == S.id)[0]
	var m: Dictionary = sq.supply.menu
	if not TestCheck.ok(self, m.rate_bp == 10000 and m.level == 3 and m.level_max == 3 and m.docks == 2 and m.docks_used == 2 and m.stock_ammo == 24 and not m.hold and m.first == -1, "메뉴: 레벨 3/3·도크 2/2·재고 %s" % str(m)): return
	if not TestCheck.ok(self, m.targets.size() == 3 and m.targets[0].id == B.id and m.targets[0].dist == 90.0 and m.targets[0].ammo == 20 and m.targets.filter(func(t): return t.id == C.id)[0].charges > 0, "대상 3개, 가까운 순, 결손 표시 %s" % str(m.targets[0])): return
	var served_t: Array = m.targets.filter(func(t): return t.serving)
	if not TestCheck.ok(self, served_t.size() == 2 and served_t[0].left_s > 0.0 and served_t[0].left_s <= 60.0, "진행 중 2개와 남은 초 %s" % str(served_t)): return
	var guest: Dictionary = pj.squadrons.filter(func(q): return q.id == A.id)[0]
	if not TestCheck.ok(self, not guest.supply.has("menu"), "보급함 없는 함대에는 menu 없음"): return
	var foe_sq: Dictionary = pj.squadrons.filter(func(q): return q.side == 1)[0]
	if not TestCheck.ok(self, not foe_sq.has("supply") and not foe_sq.has("menu"), "적 항목에 supply 키 없음"): return
	S.hull = S.max_hull * 60 / 100
	_ticks(s, 1)
	if not TestCheck.ok(self, s.supply.menu(S).level == 2, "선체 60: 처리량 50 단계, 레벨 2"): return
	S.hull = S.max_hull * 30 / 100
	_ticks(s, 1)
	var m2: Dictionary = s.supply.menu(S)
	if not TestCheck.ok(self, m2.rate_bp == 2500 and m2.level == 1, "선체 30: 처리량 25 단계, 레벨 1 %s" % str(m2.rate_bp)): return

	# --- 3. 우선 지정이 보급 순서를 바꾼다(도크 2) ---
	s = _mk()
	var first_default := _served(s, 601)
	s = _mk()
	A = s.st.fleets[1]
	B = s.st.fleets[2]
	C = s.st.fleets[3]
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_first", s.st.fleets[3].id))
	var first_c := _served(s, 601)
	if not TestCheck.ok(self, first_default.size() == 2 and first_default.has(A.id) and first_default.has(B.id) and not first_default.has(C.id), "기본: A·B 먼저 %s" % str(first_default)): return
	if not TestCheck.ok(self, first_c.size() == 2 and first_c.has(C.id) and first_c.has(A.id) and not first_c.has(B.id), "C 먼저 지정: C·A %s" % str(first_c)): return
	if not TestCheck.ok(self, s.st.fleets[0].sup_first == -1, "끝나면 지정이 풀린다"): return

	# --- 4. 중지/재개 ---
	s = _mk()
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_hold", -1, Vector2.ZERO, {"on": true}))
	var held := _served(s, 1500)
	var mh: Dictionary = s.supply.menu(s.st.fleets[0])
	if not TestCheck.ok(self, held.is_empty() and mh.hold and mh.docks_used == 0, "중지: 150초 동안 보급 없음, 도크 0"): return
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_hold", -1, Vector2.ZERO, {"on": false}))
	var resumed := _served(s, 620)
	if not TestCheck.ok(self, resumed.size() == 2, "재개: 60초 뒤 보급 재개 %s" % str(resumed)): return

	# --- 5. 거부 사유 ---
	s = _mk()
	s.drain_events()
	s.issue(BattleSim.command(0, [s.st.fleets[1].id], "supply_hold", -1, Vector2.ZERO, {"on": true}))
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_first", s.st.fleets[0].id))
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_first", s.st.fleets[4].id))
	if not TestCheck.ok(self, _rej(s) == ["supply_none", "supply_target", "supply_target"] and not s.st.fleets[1].sup_hold, "보급함 없음/자기 자신/적 지정은 거부"): return

	# --- 6. replay: 명령이 기록되고, 같은 장면에 되돌려 넣으면 같은 지문 ---
	s = _mk()
	_ticks(s, 100)
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_first", s.st.fleets[3].id))
	_ticks(s, 400)
	s.issue(BattleSim.command(0, [s.st.fleets[0].id], "supply_hold", -1, Vector2.ZERO, {"on": true}))
	_ticks(s, 400)
	var lg: Array = s.command_log
	if not TestCheck.ok(self, lg.size() == 2 and lg[0].kind == "supply_first" and lg[0].tick == 100 and lg[1].kind == "supply_hold" and lg[1].tick == 500, "명령 기록 %s" % str(lg.size())): return
	var r := _mk()
	var i := 0
	while r.st.tick < s.st.tick:
		while i < lg.size() and int(lg[i].tick) == r.st.tick:
			r.queue(lg[i])
			i += 1
		r.step()
	if not TestCheck.ok(self, r.fingerprint() == s.fingerprint() and s.supply.fingerprint().contains("|man"), "재생 지문 일치, 지문에 수동 상태 반영"): return
	if not TestCheck.ok(self, _mk().fingerprint() != s.fingerprint(), "명령이 지문에 영향"): return

	await _ui()

# --- 7·8. 화면과 안개(실제 시나리오 장면) ---
func _ui() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var src: BattleSource = battle.presentation.src
	var deck = battle.presentation.hud
	deck.begin_battle()
	await process_frame
	var core: BattleSim = battle.sim
	var sup_f: FleetState = null
	var plain: FleetState = null
	for f in core.st.fleets:
		if f.side == 0 and not f.dead:
			if sup_f == null:
				sup_f = f
			elif plain == null:
				plain = f
				f.stages["SHP-05"] = [0, 0, 0, 0, 0]   # 적벽 자동 편성은 모든 함대에 보급함이 있다. 한 함대의 보급함만 뺀다
	if not TestCheck.ok(self, sup_f != null and plain != null, "시나리오에 보급함 함대와 아닌 함대"): return
	battle._sync()
	# 아무것도 선택하지 않으면 탭 없음
	battle.selected.clear()
	await process_frame
	deck._refresh_cmds()
	if not TestCheck.ok(self, not deck.cmd_tabs[3].visible and not deck.cmd_tabs[4].visible and not deck.supply_menu.visible, "선택 없음: 보급·수리 탭 없음"): return
	# 보급함이 없는 아군: 탭 없음
	battle.selected.clear()
	battle.selected.append(battle.by_id(plain.id))
	deck._refresh_cmds()
	if not TestCheck.ok(self, src.supply_view().is_empty() and not deck.cmd_tabs[3].visible, "보급함 없는 함대: 메뉴 없음"): return
	# 보급함 함대: 손님 하나를 곁에 두고 선택
	TestPoke.fleet(battle, battle.by_id(plain.id), {"pos": sup_f.pos + Vector2(60, 0)})
	battle.selected.clear()
	battle.selected.append(battle.by_id(sup_f.id))
	for i in 3:
		await process_frame
	deck._refresh_cmds()
	if not TestCheck.ok(self, deck.cmd_tabs[3].visible and deck.cmd_tabs[4].visible, "보급함 함대: 보급·수리 탭"): return
	deck._set_tab(3)
	await process_frame
	deck._refresh_cmds()
	var v: Dictionary = src.supply_view()
	if not TestCheck.ok(self, deck.supply_menu.visible and v.id == sup_f.id and v.menu.targets.any(func(t): return t.id == plain.id), "보급 탭: 패널 표시, 반경 안 손님 목록 %s" % str(v.menu.targets.size())): return
	var names := ""
	for c in deck.supply_menu._box.get_children():
		names += _text(c) + "
"
	if not TestCheck.ok(self, names.contains("보급 레벨") and names.contains("재고 탄약") and names.contains("먼저") and not names.contains("전대"), "보급 패널 문구(함대 표기)
" + names): return
	# 우선 지정 버튼 → 코어 명령 기록
	var n0: int = core.command_log.size()
	var btn: Button = _find_btn(deck.supply_menu._box, plain.id)
	if not TestCheck.ok(self, btn != null and btn.custom_minimum_size.y >= 48.0 and btn.custom_minimum_size.x >= 48.0, "먼저 버튼 48 이상"): return
	btn.pressed.emit()
	if not TestCheck.ok(self, core.command_log.size() == n0 + 1 and core.command_log[n0].kind == "supply_first" and sup_f.sup_first == plain.id, "먼저 버튼: supply_first 기록"): return
	# 중지/재개 버튼
	deck._refresh_cmds()
	await process_frame
	var hb: Button = deck.cmd_buttons[0]
	hb.pressed.emit()
	if not TestCheck.ok(self, sup_f.sup_hold and core.command_log.back().kind == "supply_hold", "중지 버튼"): return
	deck._refresh_cmds()
	if not TestCheck.ok(self, hb.cmd.label == "보급 재개", "중지 중에는 재개 표기"): return
	hb.pressed.emit()
	if not TestCheck.ok(self, not sup_f.sup_hold, "재개"): return
	deck._set_tab(4)
	deck._refresh_cmds()
	if not TestCheck.ok(self, deck.supply_menu.mode == "repair" and deck.supply_menu.visible, "수리 탭"): return
	var cap := ""
	for c in deck.supply_menu._box.get_children():
		cap += _text(c) + "
"
	if not TestCheck.ok(self, cap.contains("수리 도크"), "수리 탭: 도크 문구
" + cap): return
	# 선택을 보급함 없는 함대로 바꾸면 탭이 사라지고 태세 탭으로 돌아간다
	battle.selected.clear()
	battle.selected.append(battle.by_id(plain.id))
	deck._refresh_cmds()
	if not TestCheck.ok(self, not deck.cmd_tabs[3].visible and deck.tab_index == 0 and not deck.supply_menu.visible, "선택이 바뀌면 메뉴 닫힘"): return
	# 적: 안개 판의 투영에 적 보급 정보가 없다
	var foe_sup := false
	for f in core.st.fleets:
		if f.side == 1 and core.supply.ships_of(f) > 0:
			foe_sup = true
	var pj := core.projection(0)
	var leaked := false
	for q in pj.squadrons:
		if q.side == 1 and (q.has("supply") or q.has("menu")):
			leaked = true
	var mine := {}
	for q in pj.squadrons:
		if q.side == 0:
			mine["f%d" % q.id] = true
	for e in pj.supply_sources:
		if not (e.get("base", false) or mine.has(e.key)):
			leaked = true
	if not TestCheck.ok(self, not leaked and core.detect != null, "안개 켜짐: 적 접촉·공급원 목록에 적 보급 정보 없음(적 보급함 있음=%s)" % str(foe_sup)): return
	# 적을 골라도 탭이 안 뜬다
	TestPoke.foe_beside(battle, battle.by_id(plain.id))
	for i in 30:
		battle.update_sim(0.1)
	var foe = null
	for f in battle.fleets:
		if f.side == 1:
			foe = f
	battle.selected.clear()
	if foe:
		battle.selected.append(foe)
	deck._refresh_cmds()
	if not TestCheck.ok(self, src.supply_view().is_empty() and not deck.cmd_tabs[3].visible, "적 선택: 메뉴 없음"): return
	print("OK supply_menu")
	quit(0)

func _text(c: Node) -> String:
	var t := ""
	if c is Label:
		t += c.text
	if c is Button:
		t += c.text
	for k in c.get_children():
		t += " " + _text(k)
	return t

func _find_btn(n: Node, target_id: int) -> Button:
	if n is Button and n.has_meta("target_id") and int(n.get_meta("target_id")) == target_id:
		return n
	for k in n.get_children():
		var r := _find_btn(k, target_id)
		if r:
			return r
	return null
