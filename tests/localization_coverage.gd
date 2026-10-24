extends SceneTree

# Static inventory is checked by tools/audit-localization.py. This exercises the
# actual display boundary, including formatted and composed messages and tooltips.
var failures: Array[String] = []
var translated_count := 0
var locale := ""
var capture := false
var format_regex := RegEx.new()

func _initialize() -> void:
	call_deferred("_run")

func verify(source: String, location: String) -> void:
	if not GameLocale.CATALOG_SCRIPT._has_hangul(source):
		return
	var output := GameLocale.text(source)
	translated_count += 1
	if GameLocale.CATALOG_SCRIPT._has_hangul(output):
		var failure := "%s %s: %s => %s" % [locale, location, source, output]
		if failure not in failures:
			failures.append(failure)

func scan(node: Node) -> void:
	if node.auto_translate_mode == Node.AUTO_TRANSLATE_MODE_DISABLED:
		return
	if node is Control:
		verify(node.tooltip_text, str(node.get_path()) + "/tooltip")
	if node is Label or node is RichTextLabel or node is Button:
		verify(node.text, str(node.get_path()) + "/text")
	if node is LineEdit:
		verify(node.placeholder_text, str(node.get_path()) + "/placeholder")
	if node is OptionButton:
		for index in node.item_count:
			verify(node.get_item_text(index), str(node.get_path()) + "/item")
	for child in node.get_children():
		scan(child)

func sample(source: String) -> String:
	for token in ["{trait}", "{조조_상태}", "{손실_적}", "{시각}"]:
		source = source.replace(token, "유비")
	var matches := format_regex.search_all(source)
	for index in range(matches.size() - 1, -1, -1):
		var match_value: RegExMatch = matches[index]
		var value := "유비" if match_value.get_string().ends_with("s") else ("1.2" if match_value.get_string().ends_with("f") else "3")
		source = source.substr(0, match_value.get_start()) + value + source.substr(match_value.get_end())
	return source.replace("%%", "%")

func frame(deck: Control, name_value: String, screenshot := false) -> void:
	for index in 3:
		await process_frame
	scan(deck)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		if capture and screenshot:
			root.get_texture().get_image().save_png("res://artifacts/localization/%s-%s.png" % [locale, name_value])

func _run() -> void:
	format_regex.compile("%[-+0-9.]*[dsf]")
	capture = "--capture" in OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute("res://artifacts/localization")
	GameSettings.load_cfg()
	var original_language := GameSettings.language
	var original_scale := GameSettings.ui_scale
	GameSettings.ui_scale = 1.0
	root.size = Vector2i(1600, 900)
	root.content_scale_size = Vector2i(1600, 900)
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck: Control = battle.presentation.hud
	deck.guard.enabled = false
	for language in ["en", "zh_CN", "ja"]:
		locale = language
		GameSettings.language = language
		GameLocale.set_language(language)
		for catalog in GameLocale._catalogs:
			catalog.audit_enabled = true
			catalog.untranslated.clear()
		for key: String in GameLocale.CATALOG.data:
			verify(sample(key), "formatted catalog")
		# Compositions used by warnings, selected fleets and special skill tooltips.
		for composed in [
			"★ 돌격", "「강궁」", "“전 함대, 전투 배치. 조조의 선봉이 적벽에 들어섰다.”",
			"유비  수리 필요 12척", "선택 · 강습모함 · 8척\n중앙 후방 · 함재기·강습정",
			"확정할 수 없음 — 제독이 없습니다 · 함선이 0척입니다",
			"\n대상: 반경 안에서 가장 가까운 확인된 적 함대 (지금: 조조 함대)",
			"연합 · 강하에서", "조조군 · 장강 대항로 · 규모 추정",
		]:
			verify(composed, "composed caption")
		deck.show_screen("title")
		await frame(deck, "title", true)
		deck.open_prologue()
		for page in PrologueText.PAGES.size():
			deck.screens.prologue.open_at(page)
			await frame(deck, "prologue", page == 0)
		deck.show_screen("brief")
		await frame(deck, "brief", true)
		for full in [false, true]:
			for difficulty in ["입문", "표준", "상급", "극한"]:
				deck.screens.roster.open_roster(full, difficulty)
				await frame(deck, "roster")
		deck.screens.org.open_org()
		deck.screens.org.press(deck.screens.org.mine()[0], "vice")
		deck.screens.org.pick_skill_slot(0)
		for query in [GameLocale.text("왕평"), GameLocale.text("무당비군")]:
			deck.screens.org.search.text = query.to_upper()
			deck.screens.org._fill_pool()
			var found := false
			for child in deck.screens.org.pool_box.get_children():
				if child is Button and "왕평" in child.text:
					found = true
			if not found:
				failures.append(language + " localized officer/trait search: " + query)
		deck.screens.org.search.text = ""
		deck.screens.org._fill_pool()
		await frame(deck, "organization", true)
		for box in [deck.screens.org.fleets_box, deck.screens.org.detail, deck.screens.org.pool_box]:
			var panel: Control = box.get_parent().get_parent().get_parent().get_parent()
			if panel.get_global_rect().end.x > deck.screens.org.get_global_rect().end.x + 1:
				failures.append(language + " organization column exceeds viewport")
		var guide: Control = deck.screens.formation_guide
		guide.open_guide()
		for index in 7:
			guide.formation_picker.select(index)
			guide.formation_picker.item_selected.emit(index)
			await frame(deck, "formation", index == 0)
		for screen_name in ["pause", "settings", "settings_pause"]:
			deck.show_screen(screen_name)
			if screen_name.begins_with("settings"):
				for page in 3:
					deck.screens[screen_name]._show_page(page)
					await frame(deck, screen_name)
			else:
				await frame(deck, screen_name)
		deck.begin_battle()
		for index in 120:
			battle.update_sim(0.05)
		for fleet in battle.alive(0):
			battle.selected.assign([fleet])
			battle.refresh_panel()
			deck._set_info_open(true)
			for tab in 5:
				deck._set_tab(tab)
				deck._refresh_cmds()
				await frame(deck, "battle", tab == 2 and fleet == battle.alive(0)[0])
			for button in deck.cmd_buttons:
				if not button is Button or not button.cmd.has("desc"):
					continue
				var tooltip: Control = deck.make_cmd_tooltip(button.cmd)
				deck.add_child(tooltip)
				scan(tooltip)
				tooltip.queue_free()
		for win in [false, true]:
			battle.G.end_win = win
			battle.G.end_text = "조조군이 적벽에서 모두 사라졌습니다. 적벽의 궤도는 연합의 손에 남습니다."
			deck.show_screen("result")
			await frame(deck, "result", win)
		deck.hide()
		var world: Control = (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate()
		root.add_child(world)
		for level in ["z0", "z2", "z3"]:
			world.canvas.jump_to(level)
			await frame(world, "world-" + level, true)
		for system in world.world.systems:
			world._on_system(system.id)
			scan(world)
		for region in world.world.regions:
			world._on_region(region.id)
			scan(world)
		for ending: String in EpilogueText.ENDINGS:
			var outcome := BattleOutcome.new()
			outcome.kind = "alliance_win"
			outcome.win = true
			outcome.ending = ending
			outcome.line = "E1"
			outcome.cao_status = "killed"
			outcome.grade = "결정적 승리"
			outcome.t_s = 180
			outcome.loss_pct = {"alliance": 15, "foe": 75}
			world._show_result(outcome)
			await frame(world, "world-result", ending == "J-D2")
		world.queue_free()
		await process_frame
		deck.show()
		for catalog in GameLocale._catalogs:
			for source: String in catalog.untranslated:
				var failure: String = language + " rendered: " + source
				if failure not in failures:
					failures.append(failure)
			catalog.audit_enabled = false
	GameSettings.language = original_language
	GameSettings.ui_scale = original_scale
	GameLocale.set_language(original_language)
	var report := {"checked": translated_count, "failures": failures}
	var output := FileAccess.open("res://artifacts/localization/runtime-coverage.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	output.close()
	for failure in failures.slice(0, 30):
		push_error(failure)
	print("LOCALIZATION_RUNTIME: ", "PASS" if failures.is_empty() else "FAIL", " checked=", translated_count, " failures=", failures.size())
	battle.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
