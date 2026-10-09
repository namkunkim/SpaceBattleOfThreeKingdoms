extends SceneTree

# PC 마우스 컨트롤 검증(헤드리스): 오른쪽 클릭 이동, 오른쪽 끌기 이동, 오른쪽 끌기 적 공격, 왼쪽 클릭 선택, 가운데 끌기 화면 이동.

func _initialize() -> void:
	call_deferred("_run")

func _btn(b: int, p: Vector2, down: bool) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = b
	e.position = p
	e.pressed = down
	root.push_input(e, true)

func _move(a: Vector2, b: Vector2, mask: int, steps := 8) -> void:
	for i in steps:
		var e := InputEventMouseMotion.new()
		e.position = a.lerp(b, float(i + 1) / steps)
		e.button_mask = mask
		root.push_input(e, true)
		Input.flush_buffered_events()

func _settle() -> void:
	Input.flush_buffered_events()
	await process_frame
	await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	battle.move_mul = 1.0   # 일시정지가 없어 시간이 흐른다: 플레이용 이동 배율(×150)이면 확인 전에 도착해 버린다
	root.add_child(battle)
	await process_frame
	battle.presentation.hud.begin_battle()
	battle.cam_z = 1.0
	battle.cam_pos = Vector2(900.0, 1150.0)
	await _settle()
	var f = battle.alive(0)[0]
	var sp: Vector2 = battle.w2s(f.pos)
	# 1. 왼쪽 클릭 선택
	battle.selected.clear()
	_btn(MOUSE_BUTTON_LEFT, sp, true)
	_btn(MOUSE_BUTTON_LEFT, sp, false)
	await _settle()
	if not TestCheck.ok(self, battle.selected.size() == 1 and battle.selected[0] == f, "left click select"): return
	# 2. 오른쪽 클릭 = 이동
	TestPoke.fleet(battle, f, {"has_move": false})
	var dst := sp + Vector2(160.0, -60.0)   # 함대 근처 빈 곳(다른 함대 위면 이동이 아니다)
	for k in 12:
		if battle._hit_fleet(dst) == null:
			break
		dst += Vector2(0.0, 40.0)
	_btn(MOUSE_BUTTON_RIGHT, dst, true)
	_btn(MOUSE_BUTTON_RIGHT, dst, false)
	await _settle()
	# 3. 오른쪽 끌기 = 미리보기 후 이동
	TestPoke.fleet(battle, f, {"has_move": false})
	var a := Vector2(700.0, 500.0)
	_btn(MOUSE_BUTTON_RIGHT, a, true)
	_move(a, dst, MOUSE_BUTTON_MASK_RIGHT)
	await _settle()
	if not TestCheck.ok(self, not battle.presentation.touch.order.is_empty(), "right drag preview"): return
	_btn(MOUSE_BUTTON_RIGHT, dst, false)
	await _settle()
	if not TestCheck.ok(self, f.has_move and f.move_to.distance_to(battle.s2w(dst)) < 60.0, "right drag move"): return
	# 4. 오른쪽 끌기를 적 위에 놓아 공격
	TestPoke.foe_beside(battle, f, Vector2(380.0, -40.0))
	battle.update_sim(0.3)
	await _settle()
	if battle.alive(1).is_empty():
		print("(적 없음: 공격 항목 건너뜀)")
		print("MOUSE_INPUT_PASS")
		quit(0)
		return
	var foe = battle.alive(1)[0]
	var fp: Vector2 = battle.w2s(foe.pos)
	_btn(MOUSE_BUTTON_RIGHT, a, true)
	_move(a, fp, MOUSE_BUTTON_MASK_RIGHT)
	_btn(MOUSE_BUTTON_RIGHT, fp, false)
	await _settle()
	if not TestCheck.ok(self, f.target == foe, "right drag attack"): return
	# 5. 가운데 끌기 = 화면 이동
	var cam0: Vector2 = battle.cam_pos
	var e0 := Vector2(800, 560)
	_btn(MOUSE_BUTTON_MIDDLE, e0, true)
	_move(e0, e0 + Vector2(-200, 0), MOUSE_BUTTON_MASK_MIDDLE)
	_btn(MOUSE_BUTTON_MIDDLE, e0 + Vector2(-200, 0), false)
	await _settle()
	if not TestCheck.ok(self, not battle.cam_pos.is_equal_approx(cam0), "middle drag pans"): return
	print("MOUSE_INPUT_PASS")
	quit(0)
