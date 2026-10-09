extends SceneTree

# 결정 분기 자리 검증(헤드리스, 리뷰 V-3·V-4·V-7·C-2). POC에는 분기가 없어 견본 데이터로 부른다.
# - V-4 곧 분기: 자동 ×4·건너뛰기가 멈추고 상단 문구가 "결정 임박", 예고 소리
# - V-3 결정 카드: 남은 시간이 게임 시계로 줄고(일시정지 중에는 멈춤), 다 되면 추천안으로 위임 처리
# - V-7 빠른 선택 알림: 2초 안에 고르지 않으면 그대로 닫히고 자동 적용하지 않는다. 고르면 그 선택을 낸다
# - C-2 강조 포화: 교전 중인 전대에서 부르면 포화·흔들림·"salvo" 소리

func _initialize() -> void:
	call_deferred("_run")

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	var src: BattleSource = battle.presentation.src
	var pacing = deck.pacing
	GameSettings.auto_fast = true
	GameSettings.slow_mode = GameSettings.SLOW_OFF
	deck.begin_battle()
	for f in battle.sim.st.fleets:
		if f.side == 1:
			f.wait = 1 << 30   # 적 AI 투입 대기: 적이 전속으로 오면 2초 안에 교전 거리라 시작 조용한 구간(자동 ×4)을 볼 수 없다
	deck.battle.G.hold = false   # 전투는 일시정지로 시작하므로 시간을 흘린다
	await create_timer(1.3).timeout
	await _frames()
	if not TestCheck.ok(self, pacing.mode == pacing.Mode.AUTO, "auto x4 before incoming"): return
	# V-4
	UiSound.history.clear()
	src.incoming_override = {"secs": 3.0, "pos": battle.fleets[1].pos}
	await _frames()
	if not TestCheck.ok(self, pacing.mode == pacing.Mode.USER and battle.G.speed == 1 and not pacing.can_skip(), "incoming stops auto/skip"): return
	if not TestCheck.ok(self, pacing.status_tag().begins_with("결 정") and UiSound.history.has("warn_branch"), "incoming tag + sound"): return
	src.incoming_override = {}
	# V-3
	var got := [-1]
	deck.decision_card.delegated.connect(func(i): got[0] = i)
	deck.decision_card.open_card({"speaker_id": "CHR-0186", "line": "견본", "time": 3.0,
		"options": [{"label": "가", "rec": ""}, {"label": "나", "rec": "노숙"}]})
	await _frames()
	if not TestCheck.ok(self, not deck.info.visible, "card replaces info panel"): return
	deck.open_pause()
	var tl: float = deck.decision_card.time_left
	await create_timer(0.5).timeout
	if not TestCheck.ok(self, is_equal_approx(deck.decision_card.time_left, tl), "card timer frozen while paused"): return
	deck.resume()
	var waited := 0.0
	while deck.decision_card.visible and waited < 6.0:
		await create_timer(0.1).timeout
		waited += 0.1
	if not TestCheck.ok(self, got[0] == 1 and not deck.decision_card.visible and deck.info.visible, "expiry delegates to recommended (%d)" % got[0]): return
	# V-7
	var picked := [-1]
	var exp := [false]
	deck.quick_alert.chosen.connect(func(i): picked[0] = i)
	deck.quick_alert.expired.connect(func(): exp[0] = true)
	deck.quick_alert.open_alert({"text": "정욱의 의심이 커지고 있습니다", "options": [{"label": "황개를 늦춘다", "rec": true}, {"label": "그대로"}], "time": 0.6})
	await create_timer(0.9).timeout
	await _frames()
	if not TestCheck.ok(self, exp[0] and picked[0] == -1 and not deck.quick_alert.visible, "quick alert expires without auto-apply"): return
	# W-5: 알림이 떠 있는 동안 ×0.2, 열 때 소리. 소리 간격(1초)은 실제 시간이라 앞 알림에서 충분히 기다린다(감속이 엔진 시간이 아니므로 타이머가 늘어나지 않는다)
	await create_timer(1.1).timeout
	UiSound.history.clear()
	deck.quick_alert.open_alert({"text": "견본", "options": [{"label": "가", "rec": true}, {"label": "나"}], "time": 5.0})
	await _frames()
	if not TestCheck.ok(self, not pacing.slow and is_equal_approx(battle.G.slow, 1.0) and UiSound.history.has("warn_branch"), "quick alert does not slow time + sound"): return
	deck.quick_alert.close_alert()
	await _frames()
	if not TestCheck.ok(self, not pacing.slow and is_equal_approx(battle.G.slow, 1.0), "closing alert restores speed"): return
	# W-6: 추천 없는 카드는 위임하지 않고 경고
	got[0] = 99
	deck.decision_card.open_card({"speaker_id": "CHR-0207", "line": "견본", "time": 0.5, "options": [{"label": "가"}, {"label": "나"}]})
	waited = 0.0
	while deck.decision_card.visible and waited < 3.0:
		await create_timer(0.1).timeout
		waited += 0.1
	if not TestCheck.ok(self, got[0] == -1, "no recommendation -> no delegation (%d)" % got[0]): return
	deck.quick_alert.open_alert({"text": "견본", "options": [{"label": "가", "rec": true}, {"label": "나"}], "time": 2.0})
	await _frames()
	deck.quick_alert._btns[0].pressed.emit()   # _btns는 뒤에서부터 만든다: [0] = 마지막 선택지
	if not TestCheck.ok(self, picked[0] == 1, "quick alert choice"): return
	# C-2
	var shooter = null
	for f in battle.sim.st.fleets:
		f.wait = 0   # 적 AI 투입
	TestPoke.foe_beside(battle, battle.flag(0))   # 안개 시작이라 적을 곁으로 옮겨 교전을 만든다
	for i in 600:
		for f in battle.alive(0):
			if f.fire_t and not f.fire_t.dead:
				shooter = f
		if shooter:
			break
		battle.update_sim(0.05)
		if i % 20 == 0:
			await process_frame
	await _frames()
	if not TestCheck.ok(self, shooter != null, "found a firing squadron"): return
	UiSound.history.clear()
	if not TestCheck.ok(self, deck.renderer.emphasis_volley(shooter.id) and deck.renderer.shake > 0.0 and UiSound.history.has("salvo"), "emphasis volley"): return
	print("DECISION_FLOW_PASS")
	quit(0)
