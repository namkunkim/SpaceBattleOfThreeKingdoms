extends SceneTree

# 전투 시간 진행 검증(헤드리스): Q52 조용한 구간 자동 ×4·건너뛰기, Q53 포커스를 잃으면 즉시 일시정지,
# Q31·Q55 선택 감속(×0.2)과 5초 유휴 해제, 명령 확정 시 해제.

func _initialize() -> void:
	call_deferred("_run")

func _frames(n := 6) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	var pacing = deck.pacing
	var src: BattleSource = battle.presentation.src
	GameSettings.auto_fast = true
	GameSettings.slow_mode = GameSettings.SLOW_OFF
	deck.begin_battle()
	await _frames(2)
	if not TestCheck.ok(self, battle.G.state == "play" and battle.G.speed == 1, "battle starts at x1"): return
	if not TestCheck.ok(self, src.quiet(), "opening is quiet (fleets out of engagement range)"): return
	# 조용한 상태가 1초 이어지면 자동 ×4
	await create_timer(1.3).timeout
	await _frames(2)
	if not TestCheck.ok(self, pacing.mode == pacing.Mode.AUTO and battle.G.speed == 4, "quiet -> auto x4 (speed %d)" % battle.G.speed): return
	# 배속 버튼을 누르면 이번 구간 동안은 자동 ×4를 쓰지 않는다
	pacing.set_user_speed(2)
	await create_timer(1.3).timeout
	if not TestCheck.ok(self, battle.G.speed == 2 and pacing.mode == pacing.Mode.USER, "manual speed overrides auto in this quiet span"): return
	pacing.set_user_speed(1)
	# 건너뛰기: 조용한 구간에서 ×8, 전장을 누르면 멈춘다
	if not TestCheck.ok(self, pacing.can_skip(), "skip available while quiet"): return
	pacing.skip()
	await _frames(2)
	if not TestCheck.ok(self, battle.G.speed == 8, "skip -> x8"): return
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_LEFT
	m.pressed = true
	m.position = Vector2(5, 5)
	root.push_input(m, true)
	m = m.duplicate()
	m.pressed = false
	root.push_input(m, true)
	await _frames(2)
	if not TestCheck.ok(self, pacing.mode == pacing.Mode.USER and battle.G.speed == 1, "touching the field cancels skip"): return
	# 다시 건너뛰면 교전이 시작될 때 원래 배속으로 돌아온다
	pacing.skip()
	var waited := 0.0
	while src.quiet() and waited < 30.0 and battle.G.state == "play":
		await process_frame
		waited += 1.0 / 60.0
	await _frames(2)
	if not TestCheck.ok(self, not src.quiet(), "skip reaches engagement (game clock %.0fs)" % battle.G.t): return
	if not TestCheck.ok(self, pacing.mode == pacing.Mode.USER and battle.G.speed == 1, "engagement returns to x1"): return
	if not TestCheck.ok(self, not pacing.can_skip(), "skip unavailable during engagement"): return
	# Q31·Q55: 선택하면 ×0.2, 5초(실제 시간) 입력이 없으면 해제, 다시 만지면 감속
	GameSettings.slow_mode = GameSettings.SLOW_ON_SELECT
	battle.selected.clear()
	battle.selected.append(battle.fleets[1])
	var k := InputEventKey.new()
	k.keycode = KEY_SHIFT
	k.pressed = true
	root.push_input(k, true)
	await _frames(3)
	if not TestCheck.ok(self, pacing.slow and is_equal_approx(Engine.time_scale, 0.2), "select -> x0.2"): return
	await create_timer(5.4, true, false, true).timeout
	await _frames(2)
	if not TestCheck.ok(self, not pacing.slow and is_equal_approx(Engine.time_scale, 1.0) and battle.selected.size() == 1, "idle 5s -> x1, selection kept"): return
	root.push_input(k, true)
	await _frames(3)
	if not TestCheck.ok(self, pacing.slow, "touch again -> slow again"): return
	# 명령 확정(정지 명령)이면 해제
	battle.fleets[1].has_move = true
	battle.fleets[1].move_to = battle.fleets[1].pos + Vector2(200, 0)
	await _frames(3)
	if not TestCheck.ok(self, not pacing.slow and is_equal_approx(Engine.time_scale, 1.0), "order confirmed -> x1"): return
	# W-7: 조작 중에만 감속 / 끔
	GameSettings.slow_mode = GameSettings.SLOW_WHILE_HANDLING
	battle.selected.clear()
	battle.selected.append(battle.fleets[1])
	await _frames(3)
	if not TestCheck.ok(self, not pacing.slow, "while-handling: no slow when idle"): return
	var hm := InputEventMouseButton.new()
	hm.button_index = MOUSE_BUTTON_LEFT
	hm.pressed = true
	hm.position = Vector2(5, 5)
	root.push_input(hm, true)
	await _frames(3)
	if not TestCheck.ok(self, pacing.slow, "while-handling: slow while pressed"): return
	hm = hm.duplicate()
	hm.pressed = false
	root.push_input(hm, true)
	await _frames(3)
	if not TestCheck.ok(self, not pacing.slow, "while-handling: release -> x1"): return
	GameSettings.slow_mode = GameSettings.SLOW_OFF
	battle.selected.clear()
	await _frames(2)
	# Q53: 포커스를 잃으면 즉시 일시정지
	deck.guard.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	await _frames(2)
	if not TestCheck.ok(self, battle.G.state == "pause" and deck.screen == "pause" and deck.guard.auto_paused, "focus out -> pause"): return
	var t0: float = battle.G.t
	await _frames(10)
	if not TestCheck.ok(self, battle.G.t == t0, "clock frozen while paused"): return
	deck.resume()
	await _frames(2)
	if not TestCheck.ok(self, battle.G.state == "play" and not deck.guard.auto_paused, "resume clears auto-pause notice"): return
	deck.guard.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await _frames(2)
	if not TestCheck.ok(self, battle.G.state == "pause", "app background -> pause"): return
	print("PACING_PASS")
	quit(0)
