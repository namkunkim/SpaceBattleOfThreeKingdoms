extends SceneTree

# PC 지형 설명 토글·교체·바깥 클릭/Esc와 기존 터치 길게 누르기 보존.
func _initialize() -> void:
	call_deferred("_run")

func _mouse(pos: Vector2, emulated := false, down := true) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.device = InputEvent.DEVICE_ID_EMULATION if emulated else 0
	e.button_index = MOUSE_BUTTON_LEFT
	e.position = pos
	e.pressed = down
	return e

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var deck = battle.presentation.hud
	deck.guard.enabled = false
	deck.begin_battle()
	battle.set_process(false)
	var h: HoldTip = deck.hold_tip
	var b: Button = deck.terrain_info
	for i in TouchMetrics.TOUCH_DEVICES:
		var d: Array = TouchMetrics.DEVICES[i]
		if not TestCheck.ok(self, minf(b.size.x, b.size.y) * TouchMetrics.dp_per_unit(d[1], d[2], 1.0) >= TouchMetrics.MIN_DP, "지형 버튼 태블릿 48dp " + d[0]): return
	if not TestCheck.ok(self, not b.get_rect().intersects(deck.radar.get_rect()) and b.get_rect().end.x < 320.0, "작은 HUD 왼쪽 미니맵 위 영역 유지"): return
	b.pressed.emit()
	if not TestCheck.ok(self, h.showing() and h.get_child_count() == 1, "PC 클릭 팝업 1개"): return
	b.pressed.emit()
	if not TestCheck.ok(self, not h.showing() and h.get_child_count() == 0, "PC 재클릭 닫힘"): return
	b.pressed.emit()
	h._open(b)
	h._open(b)
	if not TestCheck.ok(self, h.showing() and h.get_child_count() == 1, "교체 호출 기존 자식 제거"): return
	h.hide_tip()
	b.pressed.emit()
	var tip_rect := h._tip.get_global_rect()
	h._input(_mouse(tip_rect.get_center()))
	if not TestCheck.ok(self, h.showing(), "설명 안 클릭 유지"): return
	h._input(_mouse(Vector2(1550, 10)))
	if not TestCheck.ok(self, not h.showing(), "PC 바깥 클릭 닫힘"): return
	b.pressed.emit()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	h._input(escape)
	if not TestCheck.ok(self, not h.showing(), "Esc 닫힘"): return
	# emulation press → 기존 타이머 → release 흐름(팝업이 생기면 버튼 누름 취소).
	h._input(_mouse(b.get_global_rect().get_center(), true))
	h._process(HoldTip.LONG_PRESS + 0.1)
	if not TestCheck.ok(self, h.showing() and not h._pinned and h.get_child_count() == 1, "터치 길게 누르기 기존 팝업"): return
	h._input(_mouse(b.get_global_rect().get_center(), true, false))
	if not TestCheck.ok(self, not h.showing() and h.get_child_count() == 0, "터치 해제 기존 닫기"): return
	print("TERRAIN_POPUP_PASS")
	quit(0)
