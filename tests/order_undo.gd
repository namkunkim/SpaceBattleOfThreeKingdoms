extends SceneTree

# 명령 되돌리기 검증(헤드리스, 리뷰 U2): 이동 명령 뒤 4초 동안 알림이 뜨고, 되돌리면 직전 상태로 돌아간다.
# 도착처럼 저절로 풀린 것은 명령으로 보지 않는다. 4초가 지나면 알림이 닫힌다.

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
	GameSettings.auto_fast = false
	GameSettings.slow_mode = GameSettings.SLOW_OFF
	deck.begin_battle()
	await _frames()
	var bar = deck.undo_bar
	var f = battle.fleets[1]
	var before: Vector2 = f.move_to
	var had: bool = f.has_move
	battle.selected.clear()
	battle.selected.append(f)
	battle.order_move(f.pos + Vector2(300, 120))
	await _frames()
	if not TestCheck.ok(self, bar.visible and bar._what.contains("이동"), "move order shows undo (%s)" % bar._what): return
	bar._btn.pressed.emit()
	await _frames()
	if not TestCheck.ok(self, f.has_move == had and f.move_to == before and not bar.visible, "undo restores previous order"): return
	# 저절로 풀린 것(도착)은 명령이 아니다
	f.has_move = true
	f.move_to = f.pos + Vector2(400, 0)
	await _frames()
	bar._close()
	f.has_move = false
	await _frames()
	if not TestCheck.ok(self, not bar.visible, "arrival is not an order"): return
	# 4초 뒤 닫힘
	battle.order_move(f.pos + Vector2(-200, 80))
	await _frames()
	if not TestCheck.ok(self, bar.visible, "second order shows undo"): return
	await create_timer(4.4).timeout
	await _frames()
	if not TestCheck.ok(self, not bar.visible, "undo closes after 4s"): return
	print("ORDER_UNDO_PASS")
	quit(0)
