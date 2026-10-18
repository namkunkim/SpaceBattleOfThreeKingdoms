extends SceneTree

# 게임 내 진형 배치도: 진입 버튼·7종 보기·실제 아군 편성·정보 경계·상태 복원.
func _initialize() -> void:
	call_deferred("_run")

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
	var previous: Array = []
	for i in 7:
		guide.formation_picker.select(i)
		guide.formation_picker.item_selected.emit(i)
		if not TestCheck.ok(self, guide.chart_points.size() == 56 and guide.chart_points != previous, "진형 %d 배치 갱신" % i): return
		previous = guide.chart_points.duplicate()
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
	for i in guide.fleet_picker.item_count:
		var id: int = guide.fleet_picker.get_item_metadata(i)
		if not TestCheck.ok(self, id < 0 or deck.src.squadron(id).side == 0, "적 편성 비공개"): return
	if not TestCheck.ok(self, battle.sim.st.by_id(ally.id).formation_id == original, "열람은 진형 명령을 보내지 않음"): return
	if not args.is_empty():
		guide.fleet_picker.select(0)
		guide.formation_picker.select(1)
		guide._sync()
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
