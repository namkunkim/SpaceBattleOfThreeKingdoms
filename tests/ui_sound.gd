extends SceneTree

# 효과음 훅 검증(헤드리스): 버튼·경보·격파·아군 손실·명령·되돌리기·포화가 사건을 내는지, 음량이 버스에 반영되는지.
# 소리 장치가 없어도 사건 기록(UiSound.history)으로 확인한다.

func _initialize() -> void:
	call_deferred("_run")

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _click(c: Control) -> void:
	var p := c.get_global_rect().get_center()
	for down in [true, false]:
		var m := InputEventMouseButton.new()
		m.button_index = MOUSE_BUTTON_LEFT
		m.position = p
		m.global_position = p
		m.pressed = down
		m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(m, true)

func _has(ev: String) -> bool:
	return UiSound.history.has(ev)

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	GameSettings.auto_fast = false
	GameSettings.slow_mode = GameSettings.SLOW_OFF
	deck.begin_battle()
	await _frames()
	UiSound.history.clear()
	_click(deck.speed_btns[1])
	await _frames()
	if not TestCheck.ok(self, _has("button"), "button sound"): return
	battle.spawn_reinf()
	await _frames()
	if not TestCheck.ok(self, _has("alert"), "reinforcement alert"): return
	battle.add_log("%s 함대 격파!" % battle.alive(1)[0].fname, "", battle.fleets[1])
	battle.add_log("%s 함대가 궤멸되었습니다" % battle.fleets[2].fname, "foe", battle.fleets[2])
	await _frames()
	if not TestCheck.ok(self, _has("fleet_destroyed") and _has("fleet_lost"), "kill / loss sounds %s" % [UiSound.history]): return
	battle.selected.clear()
	battle.selected.append(battle.fleets[1])
	battle.order_move(battle.fleets[1].pos + Vector2(200, 50))
	await _frames()
	if not TestCheck.ok(self, _has("confirm"), "order confirm sound"): return
	deck.undo_bar.undo()
	if not TestCheck.ok(self, _has("undo"), "undo sound"): return
	deck.renderer.fx_event.emit("volley")
	if not TestCheck.ok(self, _has("volley"), "renderer volley hook"): return
	# 같은 사건은 최소 간격 안에서 한 번만
	var n := UiSound.history.count("ship_kill")
	for i in 5:
		deck.sound.play("ship_kill")
	if not TestCheck.ok(self, UiSound.history.count("ship_kill") == n + 1, "rate limit"): return
	# 음량: 0이면 끔, 값은 dB로
	GameSettings.vol_sfx = 0.0
	GameSettings.vol_ui = 0.5
	UiSound.apply_volume()
	var sfx := AudioServer.get_bus_index("Sfx")
	var ui := AudioServer.get_bus_index("Ui")
	if not TestCheck.ok(self, AudioServer.is_bus_mute(sfx) and absf(AudioServer.get_bus_volume_db(ui) - linear_to_db(0.5)) < 0.01, "volume to buses"): return
	# 합성 임시음은 길이가 있는 소리여야 한다
	var w := UiSound._synth(UiSound.EVENTS.alert.synth)
	if not TestCheck.ok(self, w.get_length() > 0.4, "synth stream"): return
	print("UI_SOUND_PASS")
	quit(0)
