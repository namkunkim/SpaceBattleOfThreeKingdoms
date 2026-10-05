extends SceneTree

# 진형 탭 캡처(호스트가 아직 POC 규칙이라 코어 투영으로 만든 카드를 명령 패널 자리에 그린다).
# godot --path . --resolution 2560x1600 --script tests/capture_formation.gd -- [출력 png] [UI 크기]
# 상태: 첫 칸 현재, 하나는 전환 중, 팔진은 잠김(조건 미달), 느린 전환은 노랑.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var outp := args[0] if args.size() > 0 else "res://out/ui-formation.png"
	if args.size() > 1:
		GameSettings.ui_scale = float(args[1])
		GameSettings.apply(root.get_window())
	var sim := BattleSim.new(1, BattleRules.TICK_HZ, ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json", "표준"))
	var a: FleetState = null
	for f in sim.st.fleets:
		if f.side == 0:
			a = f
			break
	sim.issue(BattleSim.command(0, [a.id], "formation", -1, Vector2.ZERO, {"id": "FRM-04" if a.formation_id != "FRM-04" else "FRM-02"}))
	for i in 130:
		sim.step()
	sim.drain_events()
	var sel := []
	for q in BattleProjection.build(sim, 0).squadrons:
		if q.id == a.id:
			sel.append(q)
	var opts := FormationTab.options(sim.salvo.C, sel)
	var theme_ := UiTheme.build()
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var panel := DeckWidgets.DrawPanel.new(Callable(), UiTheme.ornate())
	panel.theme = theme_
	bg.add_child(panel)
	panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	panel.custom_minimum_size = Vector2(364, 250)
	panel.size = Vector2(364, 250)
	panel.offset_left = -364 - 16
	panel.offset_top = -250 - 14
	panel.offset_right = -16
	panel.offset_bottom = -14
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	grid.position = Vector2(12, 66)
	panel.add_child(grid)
	var tabs := HBoxContainer.new()
	tabs.position = Vector2(8, 6)
	tabs.size = Vector2(348, 52)
	for i in 3:
		var tb := DeckWidgets.TabButton.new(["태세", "진형", "무장"][i])
		tb.on = i == 1
		tabs.add_child(tb)
	panel.add_child(tabs)
	for o in opts:
		var b := FormationTab.FormButton.new(o, null)
		grid.add_child(b)
	for i in 10:
		await process_frame
	var path := ProjectSettings.globalize_path(outp) if outp.begins_with("res://") else outp
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	root.get_viewport().get_texture().get_image().save_png(path)
	print("FORMATION_CAPTURE_PASS ", path, " ", root.get_visible_rect().size, " cards ", opts.size())
	quit(0)
