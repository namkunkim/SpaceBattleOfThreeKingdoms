extends SceneTree

# 일시정지/재개 고정 버튼: 터치로 누를 때마다 G.hold가 바뀌고, 전장 선택은 건드리지 않는다.

func _initialize() -> void:
	call_deferred("_run")

func _touch(p: Vector2, down: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = p
	e.pressed = down
	root.push_input(e, true)

func _settle() -> void:
	Input.flush_buffered_events()
	await process_frame
	await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	battle.presentation.hud.begin_battle()
	await _settle()
	var b: Button = battle.presentation.touch._resume
	var c := b.get_global_rect().get_center()
	if not TestCheck.ok(self, b.is_visible_in_tree(), "button visible"): return
	var h0: bool = battle.G.hold
	var sel0: int = battle.selected.size()
	for i in 2:
		var before: bool = battle.G.hold
		_touch(c, true)
		await _settle()
		_touch(c, false)
		await _settle()
		if not TestCheck.ok(self, battle.G.hold != before, "tap %d toggles hold (rect %s)" % [i, b.get_global_rect()]): return
	if not TestCheck.ok(self, battle.G.hold == h0 and battle.selected.size() == sel0, "selection untouched"): return
	# 다른 손가락(0번)이 전장을 누르는 동안 1번 손가락으로 눌러도 바뀐다
	var f0: bool = battle.G.hold
	_touch(Vector2(900, 500), true)
	var e := InputEventScreenTouch.new()
	e.index = 1
	e.position = c
	e.pressed = true
	root.push_input(e, true)
	e.pressed = false
	root.push_input(e, true)
	await _settle()
	if not TestCheck.ok(self, battle.G.hold != f0, "second finger toggles"): return
	print("PAUSE_BUTTON_PASS")
	quit()
