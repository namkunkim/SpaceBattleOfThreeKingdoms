extends SceneTree

# 선택 집합·그룹 검증(헤드리스). 순수 로직(SelectionSet)과 전투 화면 입력: 추가 탭, 범위 선택(마우스·터치 다중 모드),
# 그룹 저장·호출(혼합 포함), 소속 소멸 시 그룹에서 빠짐, 그룹 명령이 선택 전대마다 같은 코어 명령으로 가는지.

class Fake:
	var id := 0
	var dead := false
	var pos := Vector2.ZERO
	func _init(i: int, p := Vector2.ZERO) -> void:
		id = i
		pos = p

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
		e.position = a.lerp(b, float(i + 1) / steps)
		e.relative = (b - a) / steps
		root.push_input(e, true)
		Input.flush_buffered_events()

func _settle() -> void:
	Input.flush_buffered_events()
	await process_frame
	await process_frame

func _run() -> void:
	# ---- 순수 로직 ----
	var a := Fake.new(1, Vector2(10, 10))
	var b := Fake.new(2, Vector2(50, 50))
	var c := Fake.new(3, Vector2(300, 300))
	var sel := []
	SelectionSet.toggle(sel, a)
	SelectionSet.toggle(sel, b)
	if not TestCheck.ok(self, sel.size() == 2, "toggle add"): return
	SelectionSet.toggle(sel, a)
	if not TestCheck.ok(self, sel == [b], "toggle remove"): return
	SelectionSet.add_all(sel, [a, b])
	if not TestCheck.ok(self, sel.size() == 2, "add_all no duplicates"): return
	c.dead = true
	var hit := SelectionSet.in_rect([a, b, c], Rect2(0, 0, 100, 100), func(p): return p)
	if not TestCheck.ok(self, hit == [a, b], "in_rect skips outside/dead"): return
	var groups := {1: [1, 2], 2: [3], 3: [2, 3]}
	var by := {1: a, 2: b, 3: c}
	SelectionSet.prune(groups, func(id): return by.get(id))
	if not TestCheck.ok(self, groups == {1: [1, 2], 3: [2]} and not groups.has(2), "prune drops dead members and empty groups: %s" % [groups]): return
	b.dead = true
	SelectionSet.prune(groups, func(id): return by.get(id))
	if not TestCheck.ok(self, groups == {1: [1]}, "prune after second loss: %s" % [groups]): return
	if not TestCheck.ok(self, SelectionSet.same([a], [a]) and not SelectionSet.same([a], [a, c]), "same"): return

	# ---- 전투 화면 ----
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	deck.begin_battle()
	battle.cam_z = 1.0
	battle.cam_pos = Vector2(900.0, 1150.0)
	await _settle()
	var allies: Array = battle.alive(0)
	var f1 = allies[1]
	var f2 = allies[2]
	# 1. 다중 모드 탭 = 추가/해제
	battle.selected.assign([f1])
	battle.multi = true
	var p2: Vector2 = battle.w2s(f2.pos)
	_touch(0, p2, true)
	_touch(0, p2, false)
	await _settle()
	if not TestCheck.ok(self, battle.selected.size() == 2 and battle.selected.has(f1) and battle.selected.has(f2), "multi tap adds"): return
	_touch(0, p2, true)
	_touch(0, p2, false)
	await _settle()
	if not TestCheck.ok(self, battle.selected == [f1], "multi tap again removes"): return
	# 2. 다중 모드 빈 곳 끌기 = 범위 선택(카메라 그대로, 기존 선택에 추가)
	var cam0: Vector2 = battle.cam_pos
	var p1: Vector2 = battle.w2s(f1.pos)
	var box_a := Vector2(minf(p1.x, p2.x) - 60.0, minf(p1.y, p2.y) - 60.0)
	var box_b := Vector2(maxf(p1.x, p2.x) + 60.0, maxf(p1.y, p2.y) + 60.0)
	if battle._hit_fleet(box_a) != null:
		print("skip box test: start point on a fleet")
	else:
		battle.selected.clear()
		_touch(0, box_a, true)
		_move(0, box_a, box_b)
		if not TestCheck.ok(self, battle.drag.get("mode", "") == "box", "box preview while dragging"): return
		_touch(0, box_b, false)
		await _settle()
		if not TestCheck.ok(self, battle.selected.has(f1) and battle.selected.has(f2), "box selects inside"): return
		if not TestCheck.ok(self, battle.cam_pos.is_equal_approx(cam0) and battle.drag.is_empty(), "box does not pan"): return
	# 2b. 다중 모드에서 선택된 전대 위에서 시작한 끌기도 범위 선택(명령 아님)
	battle.selected.assign([f1])
	TestPoke.fleet(battle, f1, {"has_move": false})
	_touch(0, p1, true)
	_move(0, p1, p1 + Vector2(220, 160))
	_touch(0, p1 + Vector2(220, 160), false)
	await _settle()
	if not TestCheck.ok(self, not f1.has_move and battle.presentation.touch.order.is_empty(), "multi drag from selected fleet is not an order"): return
	# 3. 선택이 없을 때 빈 곳 끌기 = 범위 선택(팬 아님)
	battle.multi = false
	battle.selected.clear()
	_touch(0, box_a, true)
	_move(0, box_a, box_b)
	_touch(0, box_b, false)
	await _settle()
	if not TestCheck.ok(self, battle.cam_pos.is_equal_approx(cam0) and battle.selected.has(f1) and battle.selected.has(f2), "no selection: empty drag box-selects, no pan"): return
	# 3a. 선택이 있을 때 빈 곳 끌기 = 선택 전체 이동(범위 선택 아님, 팬 아님)
	TestPoke.fleet(battle, f1, {"has_move": false})
	TestPoke.fleet(battle, f2, {"has_move": false})
	var to_p := box_a + Vector2(-150, 0)
	_touch(0, box_a, true)
	_move(0, box_a, to_p)
	if not TestCheck.ok(self, not battle.presentation.touch.order.is_empty() and battle.drag.is_empty(), "selection: empty drag previews an order"): return
	_touch(0, to_p, false)
	await _settle()
	if not TestCheck.ok(self, f1.has_move and f2.has_move and battle.selected.size() == 2 and battle.cam_pos.is_equal_approx(cam0), "selection: empty drag moves all selected"): return
	# 3b. 시작 지점으로 되돌려 놓으면 취소
	TestPoke.fleet(battle, f1, {"has_move": false})
	TestPoke.fleet(battle, f2, {"has_move": false})
	_touch(0, box_a, true)
	_move(0, box_a, to_p)
	_move(0, to_p, box_a + Vector2(6, 0))
	_touch(0, box_a + Vector2(6, 0), false)
	await _settle()
	if not TestCheck.ok(self, not f1.has_move and not f2.has_move, "drag back to start cancels"): return
	# 3c. 선택이 있을 때 적 탭 = 공격 지정
	var foe = battle.alive(1)[0]
	TestPoke.fleet(battle, foe, {"pos": f1.pos + Vector2(380.0, -40.0)})
	await _settle()
	var fp: Vector2 = battle.w2s(foe.pos)
	_touch(0, fp, true)
	_touch(0, fp, false)
	await _settle()
	if not TestCheck.ok(self, f1.target == foe and f2.target == foe, "selection: tap enemy attacks"): return
	# 3d. 선택이 있을 때 빈 곳 탭 = 선택 해제(적 탭은 선택 유지)
	_touch(0, box_a, true)
	_touch(0, box_a, false)
	await _settle()
	if not TestCheck.ok(self, battle.selected.is_empty(), "tap empty clears selection"): return
	# 3e. 선택이 없을 때 적 탭 = 정보 보기(명령 아님)
	var tgt0 = f1.target
	_touch(0, fp, true)
	_touch(0, fp, false)
	await _settle()
	if not TestCheck.ok(self, battle.inspect == foe and f1.target == tgt0, "no selection: tap enemy inspects"): return
	# 4. 그룹 저장·호출: 전대 여럿
	battle.selected.assign([f1, f2])
	battle.assign_group(1)
	battle.selected.clear()
	battle.select_group(1)
	if not TestCheck.ok(self, battle.selected.size() == 2 and battle.selected.has(f1) and battle.selected.has(f2), "group recall"): return
	# 5. 길게 눌러 저장(HUD 번호 버튼)
	battle.selected.assign([f1])
	deck.grp_btns[1].button_down.emit()
	await create_timer(0.7).timeout
	deck.grp_btns[1].button_up.emit()
	if not TestCheck.ok(self, battle.groups.get(2, []) == [f1.id], "hold saves group 2: %s" % [battle.groups.get(2)]): return
	battle.selected.clear()
	deck.grp_btns[1].button_down.emit()
	deck.grp_btns[1].button_up.emit()
	if not TestCheck.ok(self, battle.selected == [f1], "tap recalls group 2"): return
	# 6. 그룹 명령: 선택 전대마다 같은 코어 명령(이동)
	battle.selected.assign([f1, f2])
	var dst: Vector2 = f1.pos + Vector2(200.0, 0.0)
	battle.order_move(dst)
	battle.update_sim(0.3)
	if not TestCheck.ok(self, f1.has_move and f2.has_move and ((f1.move_to + f2.move_to) * 0.5).distance_to(dst) < 80.0, "group move keeps layout around dst"): return
	# 7. 소속 소멸: 전대 하나가 사라지면 그룹에서 빠진다
	f2.dead = true
	var g: Array = battle.group_fleets(1)
	if not TestCheck.ok(self, g == [f1] and battle.groups[1] == [f1.id], "dead member leaves group: %s" % [battle.groups[1]]): return
	print("SELECTION_GROUPS_PASS")
	quit(0)
