extends SceneTree

# M1 §9.2 6: 화면 수동 점검표를 API로 구동한다.
# 선택, 그룹, 명령 8개, 토스트, 로그, 속도(×1·×2·정지), 종료 화면, 재시작, 명령 기록.

var events: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _kinds(k: String) -> int:
	var n := 0
	for e in events:
		if e[0] == k:
			n += 1
	return n

func _run() -> void:
	var scene := load("res://scenes/FleetBattle3D.tscn") as PackedScene
	var battle := scene.instantiate()
	root.add_child(battle)
	await process_frame
	battle.battle_event.connect(func(kind, text, id): events.append([kind, text, id]))
	seed(77)
	battle._restart()
	if not TestCheck.ok(self, battle.G.state == "play", "start -> play"): return
	# --- 선택 ---
	if not TestCheck.ok(self, battle.my_sel().size() == 1 and battle.my_sel()[0].is_flag, "initial selection = flagship"): return
	battle.do_cmd("all")
	if not TestCheck.ok(self, battle.my_sel().size() == 6, "select all"): return
	battle.selected.clear()
	battle.do_cmd("stop")
	if not TestCheck.ok(self, _kinds("toast") == 1, "toast: no selection"): return
	# --- 그룹: 저장 후 선택 ---
	battle.selected.assign([battle.fleets[1], battle.fleets[2]])
	battle.assign_group(1)
	battle.selected.clear()
	battle.select_group(1)
	if not TestCheck.ok(self, battle.my_sel().size() == 2 and battle.my_sel()[0] == battle.fleets[1], "group assign/select"): return
	# --- 명령 8개 ---
	var f = battle.fleets[3]
	battle.selected.assign([f])
	var n_cmds0: int = battle.sim.command_log.size()
	battle.order_move(f.pos + Vector2(400, 0))
	if not TestCheck.ok(self, f.has_move and f.move_to.x > f.pos.x + 300.0, "move order"): return
	battle.do_cmd("stop")
	if not TestCheck.ok(self, not f.has_move and f.target == null, "stop"): return
	battle.do_cmd("def")
	if not TestCheck.ok(self, f.defense, "defense on"): return
	battle.do_cmd("def")
	if not TestCheck.ok(self, not f.defense, "defense toggle off"): return
	battle.do_cmd("rally")
	if not TestCheck.ok(self, f.has_move, "rally"): return
	battle.do_cmd("retreat")
	if not TestCheck.ok(self, f.has_move and f.move_to.x < 3400.0, "retreat"): return
	var cp0: float = battle.G.cp
	battle.do_cmd("charge")
	if not TestCheck.ok(self, f.charge_t > 9.0 and battle.G.cp == cp0 - 3.0, "charge costs CP 3 (%f -> %f)" % [cp0, battle.G.cp]): return
	battle.do_cmd("charge")
	if not TestCheck.ok(self, battle.G.cp < 3.0 or _kinds("toast") >= 2, "second charge rejected for CP"): return
	var toasts0 := _kinds("toast")
	battle.do_cmd("missile")
	if not TestCheck.ok(self, _kinds("toast") == toasts0 + 1, "missile with no target / low CP -> toast"): return
	# 미사일·함재기: 적 앞으로 보내서 실제로 발사
	var foe = battle.fleets[7]
	TestPoke.fleet(battle, foe, {"pos": f.pos + Vector2(300, 0)})
	battle.G.cp = 10.0
	battle.sim.st.cp = 100000
	battle._sync()
	battle.selected.assign([f])
	battle.do_cmd("missile")
	if not TestCheck.ok(self, battle.missiles.size() == 6 and battle.sim.st.cp == 80000, "missile volley: %d cp=%d" % [battle.missiles.size(), battle.sim.st.cp]): return
	if not TestCheck.ok(self, _kinds("") >= 1, "log lines emitted"): return
	battle.do_cmd("fighter")
	if not TestCheck.ok(self, battle.swarms.size() == 1 and battle.sim.st.cp == 50000, "fighters launched"): return
	if not TestCheck.ok(self, battle.sim.command_log.size() > n_cmds0, "commands recorded"): return
	# --- 속도: ×1 = 초당 10틱, ×2 = 20틱, 정지(메뉴) = 0 ---
	battle.selected.clear()
	var t0: int = battle.sim.st.tick
	for i in 10:
		battle._process(0.1)
	var d1: int = battle.sim.st.tick - t0
	if not TestCheck.ok(self, d1 >= 9 and d1 <= 11, "x1 -> ~10 ticks per second (%d)" % d1): return
	battle._toggle_speed()
	if not TestCheck.ok(self, battle.G.speed == 2, "toggle speed"): return
	t0 = battle.sim.st.tick
	for i in 10:
		battle._process(0.05)
	var d2: int = battle.sim.st.tick - t0
	if not TestCheck.ok(self, d2 >= 9 and d2 <= 11, "x2 -> ~20 ticks per second (%d)" % d2): return
	battle._toggle_speed()
	battle._toggle_menu()
	if not TestCheck.ok(self, battle.G.state == "pause", "pause"): return
	t0 = battle.sim.st.tick
	for i in 10:
		battle._process(0.1)
	if not TestCheck.ok(self, battle.sim.st.tick == t0, "paused -> no ticks"): return
	battle._close_menu()
	if not TestCheck.ok(self, battle.G.state == "play", "resume"): return
	# 틱 폭주 상한: 큰 delta를 한 번 줘도 한 프레임 8틱
	t0 = battle.sim.st.tick
	battle._process(5.0)
	if not TestCheck.ok(self, battle.sim.st.tick - t0 == 8, "frame tick cap %d" % (battle.sim.st.tick - t0)): return
	# --- 종료 화면과 재시작 ---
	battle.sim.debug_end(false, "flagship_lost")
	battle._pump()
	if not TestCheck.ok(self, battle.G.over and not battle.G.end_win, "end event -> G.over"): return
	for i in 40:
		battle._process(0.05)
	if not TestCheck.ok(self, battle.G.state == "end" and battle.hud.end_ov.visible, "end screen shown"): return
	var seed0: int = battle.battle_seed
	battle._restart()
	if not TestCheck.ok(self, battle.G.state == "play" and not battle.G.over and battle.sim.st.tick == 0 and battle.fleets.size() == 13, "restart resets"): return
	if not TestCheck.ok(self, battle.battle_seed != seed0 and not battle.hud.end_ov.visible, "restart new seed / overlay hidden"): return
	# --- 실제 한 판: 아군에 공격 명령 → 명령 기록으로 재생해도 같은 결과 ---
	battle.do_cmd("all")
	for a in battle.alive(0):
		var t = battle.nearest_foe(a, 1e9)
		battle.selected.assign([a])
		battle.order_attack(t)
	for i in 6000:
		battle.update_sim(0.05)
		if battle.sim.st.over:
			break
	var log: Array = battle.sim.command_log
	var rp := BattleSim.replay(battle.battle_seed, 10, log, battle.sim.st.tick)
	if not TestCheck.ok(self, rp.fingerprint() == battle.sim.fingerprint(), "live game replays to the same fingerprint"): return
	battle.queue_free()
	await process_frame
	print("BATTLE_FLOW_PASS")
	quit(0)
