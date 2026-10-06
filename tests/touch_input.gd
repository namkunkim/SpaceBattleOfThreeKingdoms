extends SceneTree

# 터치·마우스 입력 검증(헤드리스). 터치: 탭 선택, 끌어서 이동/공격, 되돌려 취소, 빈 곳 끌기 화면 이동,
# 두 손가락 확대, 길게 눌러 추가 선택. 마우스: 기존 클릭 선택이 그대로 동작하는지.
# 헤드리스 창은 작아서 좌표 변환이 생기므로 push_input(local)로 화면 좌표를 그대로 넣는다.

func _initialize() -> void:
	call_deferred("_run")

func _touch(idx: int, p: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = idx
	e.position = p
	e.pressed = down
	root.push_input(e, true)

func _move(idx: int, a: Vector2, b: Vector2, steps := 8) -> void:
	for i in steps:
		var e := InputEventScreenDrag.new()
		e.index = idx
		var p := a.lerp(b, float(i + 1) / steps)
		e.position = p
		e.relative = (b - a) / steps
		root.push_input(e, true)
		Input.flush_buffered_events()

func _settle() -> void:
	Input.flush_buffered_events()
	await process_frame
	await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	if not TestCheck.ok(self, deck != null and battle.presentation.touch != null, "presentation"): return
	deck.begin_battle()
	battle.cam_z = 1.0
	battle.cam_pos = Vector2(900.0, 1150.0)
	await _settle()
	var f = battle.fleets[1]
	var g = battle.fleets[2]
	var sp: Vector2 = battle.w2s(f.pos)
	# 1. 탭 선택
	battle.selected.clear()
	_touch(0, sp, true)
	_touch(0, sp, false)
	await _settle()
	if not TestCheck.ok(self, battle.selected.size() == 1 and battle.selected[0] == f, "tap select"): return
	if not TestCheck.ok(self, battle.drag.is_empty(), "no mouse box drag from touch"): return
	# 2. 끌어서 이동
	TestPoke.fleet(battle, f, {"has_move": false})
	var dst := Vector2(800.0, 330.0)
	_touch(0, sp, true)
	_move(0, sp, dst)
	await _settle()
	if not TestCheck.ok(self, not battle.presentation.touch.order.is_empty(), "order preview"): return
	_touch(0, dst, false)
	await _settle()
	if not TestCheck.ok(self, f.has_move and f.move_to.distance_to(battle.s2w(dst)) < 60.0, "drag move %s" % f.move_to): return
	# 3. 되돌려 취소
	TestPoke.fleet(battle, f, {"has_move": false})
	sp = battle.w2s(f.pos)
	_touch(0, sp, true)
	_move(0, sp, sp + Vector2(160, 0))
	_move(0, sp + Vector2(160, 0), sp + Vector2(6, 0))
	_touch(0, sp + Vector2(6, 0), false)
	await _settle()
	if not TestCheck.ok(self, not f.has_move, "drag cancel"): return
	# 4. 적 위에 놓아 공격
	TestPoke.foe_beside(battle, f, Vector2(380.0, -40.0))   # 안개 시작이라 적을 곁으로 옮겨 접촉을 만든다
	battle.update_sim(0.3)
	await _settle()
	var foe = battle.alive(1)[0]
	sp = battle.w2s(f.pos)
	var fp: Vector2 = battle.w2s(foe.pos)
	_touch(0, sp, true)
	_move(0, sp, fp)
	_touch(0, fp, false)
	await _settle()
	if not TestCheck.ok(self, f.target == foe, "drag attack"): return
	# 5. 빈 곳 끌기 = 범위 선택(화면은 그대로)
	var cam0: Vector2 = battle.cam_pos
	var empty := Vector2.ZERO
	for cand in [Vector2(800, 560), Vector2(1000, 520), Vector2(600, 600), Vector2(1100, 400), Vector2(500, 420)]:
		if battle._hit_fleet(cand) == null:
			empty = cand
			break
	if not TestCheck.ok(self, empty != Vector2.ZERO, "no empty spot for pan"): return
	if true:
		_touch(0, empty, true)
		_move(0, empty, empty + Vector2(-200, 0))
		_touch(0, empty + Vector2(-200, 0), false)
		await _settle()
		if not TestCheck.ok(self, battle.cam_pos.is_equal_approx(cam0) and battle.drag.is_empty(), "empty drag does not pan %s -> %s" % [cam0, battle.cam_pos]): return
	# 6. 두 손가락 확대
	var z0: float = battle.cam_z
	_touch(0, Vector2(700, 450), true)
	_touch(1, Vector2(900, 450), true)
	await _settle()
	_move(1, Vector2(900, 450), Vector2(1100, 450))
	await _settle()
	_touch(1, Vector2(1100, 450), false)
	_touch(0, Vector2(700, 450), false)
	await _settle()
	if not TestCheck.ok(self, battle.cam_z > z0 * 1.2, "pinch zoom %f -> %f" % [z0, battle.cam_z]): return
	# 7. 길게 눌러 추가 선택
	battle.selected.clear()
	battle.selected.append(f)
	var gp: Vector2 = battle.w2s(g.pos)
	_touch(0, gp, true)
	await _settle()
	await create_timer(0.7).timeout
	_touch(0, gp, false)
	await _settle()
	if not TestCheck.ok(self, battle.selected.has(f) and battle.selected.has(g), "long press add"): return
	# 8. 마우스 클릭 선택은 그대로
	battle.selected.clear()
	var mp: Vector2 = battle.w2s(g.pos)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	mb.position = mp
	mb.pressed = true
	root.push_input(mb, true)
	var mr := mb.duplicate()
	mr.pressed = false
	root.push_input(mr, true)
	await _settle()
	if not TestCheck.ok(self, battle.selected.size() == 1 and battle.selected[0] == g, "mouse click select"): return
	print("TOUCH_INPUT_PASS")
	quit(0)
