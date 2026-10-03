extends SceneTree

# 터치 길게 누르기 툴팁 검증(헤드리스): 명령 버튼을 길게 누르면 툴팁이 뜨고 손을 떼도 명령이 실행되지 않는다.
# 짧게 탭하면 명령이 실행된다. 아이콘 버튼(배속)도 같은 방식으로 툴팁만 뜬다.

func _initialize() -> void:
	call_deferred("_run")

func _press(c: Control, down: bool) -> void:
	var p := c.get_global_rect().get_center()
	var m := InputEventMouseButton.new()
	m.device = InputEvent.DEVICE_ID_EMULATION
	m.button_index = MOUSE_BUTTON_LEFT
	m.position = p
	m.global_position = p
	m.pressed = down
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(m, true)

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	GameSettings.auto_fast = false
	deck.begin_battle()
	await _frames()
	battle.selected.clear()
	for f in battle.alive(0):
		battle.selected.append(f)
	battle.G.cp = 10.0
	var btn: Control = null
	for b in deck.cmd_buttons:
		if b.cmd.id == "charge":
			btn = b
	# 1. 길게 누르기: 툴팁이 뜨고, 떼도 명령이 실행되지 않는다
	_press(btn, true)
	await create_timer(0.7).timeout
	await _frames()
	if not TestCheck.ok(self, deck.hold_tip.showing(), "long press shows tooltip"): return
	var tip: Control = deck.hold_tip.get_child(0)
	var view: Vector2 = deck.get_viewport_rect().size
	if not TestCheck.ok(self, tip.get_global_rect().end.y <= btn.get_global_rect().position.y and tip.get_global_rect().position.x >= 0.0 and tip.get_global_rect().end.x <= view.x, "tooltip above the button, on screen"): return
	var cp0: float = battle.G.cp
	_press(btn, false)
	await _frames()
	if not TestCheck.ok(self, not deck.hold_tip.showing(), "release hides tooltip"): return
	if not TestCheck.ok(self, battle.G.cp >= cp0 and battle.flag(0).charge_t <= 0.0, "release after tooltip does not run the command"): return
	# 2. 짧은 탭: 명령 실행
	_press(btn, true)
	await _frames(2)
	_press(btn, false)
	await _frames()
	if not TestCheck.ok(self, not deck.hold_tip.showing() and battle.flag(0).charge_t > 0.0, "short tap runs the command"): return
	# 3. 배속 버튼 길게 누르기: 툴팁만 뜨고 배속은 그대로
	var sp: Control = deck.speed_btns[1]
	_press(sp, true)
	await create_timer(0.7).timeout
	await _frames()
	if not TestCheck.ok(self, deck.hold_tip.showing(), "icon button long press shows tooltip"): return
	_press(sp, false)
	await _frames()
	if not TestCheck.ok(self, battle.G.speed == 1, "speed unchanged after long press"): return
	print("TOUCH_HOLD_PASS")
	quit(0)
