extends SceneTree

# 게임 내 진형 배치도: 진입 버튼·7종 보기·실제 아군 편성·정보 경계·상태 복원.
func _initialize() -> void:
	call_deferred("_run")

func _click(button: Button) -> void:
	var point := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for down in [true, false]:
		var click := InputEventMouseButton.new()
		click.position = point
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		root.push_input(click, true)

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 8:
		await process_frame
	var args := OS.get_cmdline_user_args()
	if args.size() > 1 and args[1] == "portrait":
		root.content_scale_size = Vector2i(800, 1280)
		root.size = Vector2i(800, 1280)
		for i in 4:
			await process_frame
	var deck: Control = battle.presentation.hud
	var guide: Control = deck.screens.formation_guide
	var entry: Button = null
	for b in deck.screens.title.find_children("*", "Button", true, false):
		if b.text == "진형 배치도":
			entry = b
	if not TestCheck.ok(self, entry != null, "타이틀에 진형 배치도 버튼"): return
	var state: String = battle.G.state
	entry.pressed.emit()
	for i in 3:
		await process_frame
	if not TestCheck.ok(self, guide.visible and deck.screen == "formation_guide" and battle.G.state == "formation_guide", "배치도 열기"): return
	if not TestCheck.ok(self, guide.chart_ids.size() == 56 and guide.formation_picker.item_count == 7 and guide.textures.size() == 8, "예시 56척·7종 진형·함종 이미지"): return
	var initial_points: Array = guide.chart_points.duplicate()
	for type in 8:
		_click(guide.legend_buttons[type])
		await process_frame
		if not TestCheck.ok(self, guide.selected_type == type and guide.legend_buttons[type].button_pressed and "강조" in guide.summary.text, "범례 클릭으로 함종 %d 강조" % type): return
		for other in 8:
			if not TestCheck.ok(self, is_equal_approx(guide.ship_alpha(other), 1.0 if other == type else 0.18), "선택 함종만 강조"): return
	if not TestCheck.ok(self, guide.chart_points == initial_points, "강조는 함선 위치를 바꾸지 않음"): return
	var previous: Array = []
	for i in 7:
		guide.formation_picker.select(i)
		guide.formation_picker.item_selected.emit(i)
		if not TestCheck.ok(self, guide.chart_points.size() == 56 and guide.chart_points != previous, "진형 %d 배치 갱신" % i): return
		previous = guide.chart_points.duplicate()
		if not TestCheck.ok(self, guide.selected_type == 7, "진형 변경에도 선택한 고속정 강조 유지"): return
	_click(guide.legend_buttons[7])
	await process_frame
	if not TestCheck.ok(self, guide.selected_type == -1 and guide.ship_alpha(0) == 1.0 and guide.clear_button.disabled, "동일 범례 다시 클릭으로 해제"): return
	_click(guide.legend_buttons[0])
	await process_frame
	_click(guide.clear_button)
	await process_frame
	if not TestCheck.ok(self, guide.selected_type == -1, "전체 표시로 강조 해제"): return
	guide.close_guide()
	if not TestCheck.ok(self, deck.screen == "title" and battle.G.state == state, "타이틀 상태 복원"): return
	var ally = battle.vm.alive(0)[0]
	battle.selected.assign([ally])
	battle.G.state = "play"
	deck.show_screen("")
	deck._set_tab(1)
	for i in 3:
		await process_frame
	if not TestCheck.ok(self, is_instance_valid(deck.formation_guide_button) and deck.cmd_buttons.size() == 7, "진형 탭 7개 명령과 배치도 보기 버튼"): return
	var original: String = battle.sim.st.by_id(ally.id).formation_id
	deck.formation_guide_button.pressed.emit()
	for i in 3:
		await process_frame
	var tick: int = battle.sim.st.tick
	for i in 5:
		await process_frame
	if not TestCheck.ok(self, tick == battle.sim.st.tick, "열람 중 전투 틱 정지"): return
	var sq: Dictionary = deck.src.squadron(ally.id)
	if not TestCheck.ok(self, guide.fleet_picker.get_selected_metadata() == ally.id and guide.chart_ids == deck.renderer._real_ship_ids(sq.counts), "선택 아군 실제 편성 표시"): return
	if not guide.chart_ids.has("SHP-02"):
		guide.legend_buttons[1].pressed.emit()
		if not TestCheck.ok(self, "편성에 없음" in guide.summary.text, "보유하지 않은 함종 안내"): return
	for i in guide.fleet_picker.item_count:
		var id: int = guide.fleet_picker.get_item_metadata(i)
		if not TestCheck.ok(self, id < 0 or deck.src.squadron(id).side == 0, "적 편성 비공개"): return
	if not TestCheck.ok(self, battle.sim.st.by_id(ally.id).formation_id == original, "열람은 진형 명령을 보내지 않음"): return
	if not args.is_empty():
		guide.fleet_picker.select(0)
		guide.formation_picker.select(1)
		guide._sync()
		if "highlight" in args:
			guide._select_type(6)
		for i in 6:
			await process_frame
		await create_timer(0.35).timeout
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		image.save_png(args[0])
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	if not TestCheck.ok(self, not guide.visible and deck.screen == "" and battle.G.state == "play", "Esc로 전투 복귀"): return
	deck._set_tab(0)
	await process_frame
	if not TestCheck.ok(self, not is_instance_valid(deck.formation_guide_button), "다른 탭에서 보기 버튼 정리"): return
	battle.G.state = "pause"
	deck.show_screen("pause")
	guide.open_guide()
	guide.close_guide()
	if not TestCheck.ok(self, battle.G.state == "pause" and deck.screen == "pause", "일시정지 상태 유지"): return
	print("FORMATION_GUIDE_UI_PASS")
	quit(0)
