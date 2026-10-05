extends SceneTree

# 전대 띠 검증(헤드리스, 리뷰 U4): 탭 선택, 다시 탭하면 화면 이동, 길게 눌러 추가, 끌어서 이동·공격, 띠로 되돌리면 취소.
# 터치(마우스 흉내)로 누른다.

func _initialize() -> void:
	call_deferred("_run")

func _mouse(p: Vector2, down: bool) -> void:
	var m := InputEventMouseButton.new()
	m.device = InputEvent.DEVICE_ID_EMULATION
	m.button_index = MOUSE_BUTTON_LEFT
	m.position = p
	m.global_position = p
	m.pressed = down
	m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	root.push_input(m, true)

func _move(a: Vector2, b: Vector2, steps := 8) -> void:
	for i in steps:
		var p := a.lerp(b, float(i + 1) / steps)
		var m := InputEventMouseMotion.new()
		m.device = InputEvent.DEVICE_ID_EMULATION
		m.position = p
		m.global_position = p
		m.relative = (b - a) / steps
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
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
	GameSettings.slow_mode = GameSettings.SLOW_OFF
	deck.begin_battle()
	battle.cam_z = 1.0
	battle.cam_pos = Vector2(900.0, 1150.0)
	await _frames()
	var strip: Control = deck.strip
	var c1: Vector2 = strip.get_global_transform() * strip.cell_rect(1).get_center()
	var c2: Vector2 = strip.get_global_transform() * strip.cell_rect(2).get_center()
	var f1 = strip.fleets()[1]
	var f2 = strip.fleets()[2]
	# 탭 선택
	battle.selected.clear()
	_mouse(c1, true)
	_mouse(c1, false)
	await _frames()
	if not TestCheck.ok(self, battle.selected.size() == 1 and battle.selected[0] == f1, "tap selects"): return
	# 다시 탭: 화면 이동
	battle.cam_pos = Vector2(200, 200)
	battle.cam_z = 2.0
	_mouse(c1, true)
	_mouse(c1, false)
	await _frames()
	if not TestCheck.ok(self, battle.cam_pos.distance_to(f1.pos) < 5.0, "tap again centers camera"): return
	# 길게 눌러 추가
	_mouse(c2, true)
	await create_timer(0.7).timeout
	_mouse(c2, false)
	await _frames()
	if not TestCheck.ok(self, battle.selected.size() == 2 and battle.selected.has(f2), "long press adds"): return
	# 끌어서 이동(빈 곳)
	battle.selected.clear()
	TestPoke.fleet(battle, f1, {"has_move": false})
	var dst := Vector2(700, 300)
	_mouse(c1, true)
	_move(c1, dst)
	await _frames()
	if not TestCheck.ok(self, not deck.overlay.touch.order.is_empty(), "drag shows order preview"): return
	_mouse(dst, false)
	await _frames()
	if not TestCheck.ok(self, f1.has_move and f1.move_to.distance_to(battle.s2w(dst)) < 40.0, "drag to field = move"): return
	# 끌어서 공격(적 위)
	var foe = battle.alive(1)[0]
	var fp: Vector2 = battle.w2s(foe.pos)
	_mouse(c1, true)
	_move(c1, fp)
	_mouse(fp, false)
	await _frames()
	if not TestCheck.ok(self, f1.target == foe, "drag to enemy = attack"): return
	# 띠로 되돌리면 취소
	TestPoke.fleet(battle, f1, {"has_move": false, "target_id": -1})
	_mouse(c1, true)
	_move(c1, dst)
	_move(dst, c1 + Vector2(0, -2))
	_mouse(c1 + Vector2(0, -2), false)
	await _frames()
	if not TestCheck.ok(self, not f1.has_move and f1.target == null, "drag back to strip cancels"): return
	print("SQUADRON_STRIP_PASS")
	quit(0)
