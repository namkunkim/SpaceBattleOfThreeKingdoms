extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var format_regex := RegEx.new()
	format_regex.compile("%[-+0-9.]*[dsf]")
	for key: String in GameLocale.CATALOG.data:
		var translations: Array = GameLocale.CATALOG.data[key]
		check(translations.size() == 3, "three translations: " + key)
		var original_formats := format_regex.search_all(key)
		for translated: String in translations:
			check(not translated.is_empty(), "translation nonempty: " + key)
			var translated_formats := format_regex.search_all(translated)
			check(original_formats.size() == translated_formats.size(), "format count: " + key)
			for index in mini(original_formats.size(), translated_formats.size()):
				check(original_formats[index].get_string().right(1) == translated_formats[index].get_string().right(1), "format type: " + key)
	var existed := FileAccess.file_exists(GameSettings.PATH)
	var original := FileAccess.get_file_as_bytes(GameSettings.PATH) if existed else PackedByteArray()
	GameSettings.load_cfg()
	var saved_language := GameSettings.language
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var deck: Control = battle.presentation.hud
	var settings: Control = deck.screens.settings
	var pause_settings: Control = deck.screens.settings_pause
	var label := Label.new()
	label.text = "설정"
	label.visible = false
	root.add_child(label)
	for i in GameLocale.CODES.size():
		deck.show_screen("settings")
		settings.language_picker.select(i)
		settings._save()
		await process_frame
		var code: String = GameLocale.CODES[i]
		check(GameLocale.current == code, "language applies immediately: " + code)
		check(GameLocale.text("설정") == ["설정", "Settings", "设置", "設定"][i], "translated text: " + code)
		check(label.tr("설정") == ["설정", "Settings", "设置", "設定"][i], "native control translation: " + code)
		check(GameLocale.text("123척") == ["123척", "123 ships", "123艘", "123隻"][i], "formatted ship count: " + code)
		check(GameLocale.text("교전 01:23") == ["교전 01:23", "Battle 01:23", "交战 01:23", "交戦 01:23"][i], "formatted timer: " + code)
		check(GameLocale.text("untranslated sentinel") == "untranslated sentinel", "unknown text preserved")
		check(GameLocale.text("유비 함대") == ["유비 함대", "Liu Bei's fleet", "刘备舰队", "劉備艦隊"][i], "nested name translation: " + code)
		check(GameLocale.text("아군 3개 함대 · 123척") == ["아군 3개 함대 · 123척", "Allies: 3 fleets · 123 ships", "友军3支舰队 · 123艘", "味方3個艦隊 · 123隻"][i], "specific template wins: " + code)
		if "--capture" in OS.get_cmdline_user_args():
			for page in 3:
				deck.show_screen("settings")
				settings._show_page(page)
				for frame in 4:
					await process_frame
				await RenderingServer.frame_post_draw
				DirAccess.make_dir_recursive_absolute("res://artifacts/localization")
				root.get_texture().get_image().save_png("res://artifacts/localization/%s-settings-%d.png" % [code, page])
		GameSettings._loaded = false
		GameSettings.language = "invalid"
		GameSettings.load_cfg()
		check(GameSettings.language == code, "saved language reload: " + code)
		pause_settings.on_show()
		check(pause_settings.language_picker.selected == i, "pause settings reflect language: " + code)
		for glyph in "设置语言日本語":
			check(UiTheme.font("regular").has_char(glyph.unicode_at(0)), "CJK font: " + glyph)
	deck.show_screen("settings")
	var before := GameSettings.language
	settings.language_picker.select((settings.language_picker.selected + 1) % 4)
	settings._cancel()
	check(GameSettings.language == before and GameLocale.current == before, "cancel preserves language")
	check(GameLocale.normalize("unsupported") == "ko", "invalid locale falls back to Korean")
	GameSettings.language = saved_language
	GameLocale.set_language(saved_language)
	if existed:
		var file := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(GameSettings.PATH)
	label.queue_free()
	battle.queue_free()
	await process_frame
	print("LOCALIZATION: ", "PASS" if failures == 0 else "FAIL (%d)" % failures)
	if failures > 0:
		quit(1)
	else:
		quit(0)
