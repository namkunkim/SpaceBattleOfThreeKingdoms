extends "res://tests/first_operation_public_cursor.gd"

const Settlements := preload("res://scripts/first_operation_settlement_store.gd")
const SAVED_MASTER := 0.35
const SAVED_SFX := 0.45


func _slot_is_unchanged(expected_sha: String) -> bool:
	return FileAccess.get_sha256(PRIMARY) == expected_sha and not FileAccess.file_exists(PREVIOUS) \
		and not FileAccess.file_exists(PRIMARY + ".pending") \
		and not FileAccess.file_exists(Settlements.PRODUCT_SLOT_PATH)


func _preferences(screen: Node) -> Control:
	var open: Button = _button(screen, "설정")
	if not _expect(open != null, "public SELECT offers settings"):
		return null
	open.pressed.emit()
	var overlay: Node = screen.get_node_or_null("EntrySettings")
	if not _expect(overlay != null and _button(overlay, "화면·진행·소리 설정") != null,
			"public settings menu offers device preferences"):
		return null
	_button(overlay, "화면·진행·소리 설정").pressed.emit()
	var page := overlay.find_child("GamePreferences", true, false) as Control
	if not _expect(page != null and page.is_visible_in_tree(), "device preferences open"):
		return null
	page.tabs[2].pressed.emit()
	if not _expect(page.vol_sliders.master.is_visible_in_tree() and page.vol_sliders.sfx.is_visible_in_tree(),
			"public sound tab exposes volume sliders"):
		return null
	return page


func _save_and_cancel(fixture: String, expected_sha: String) -> void:
	if not _expect(not FileAccess.file_exists(PRIMARY) and not FileAccess.file_exists(GameSettings.PATH),
			"begin with a fresh isolated profile"):
		return
	var is_select := func() -> bool:
		return is_instance_valid(current_scene) and current_scene.scene_file_path == ENTRY and is_instance_valid(current_scene.screen)
	if not _expect(await _wait_until(is_select),
			"product EntryBoot reaches fresh SELECT"):
		return
	var screen: Node = current_scene.screen
	# EntryBoot normally sends profiles with a slot straight to Atlas. Seed the
	# genuine copy after SELECT so the settings writes can be checked against it.
	if not _expect(FileAccess.get_sha256(fixture) == expected_sha
			and DirAccess.copy_absolute(fixture, ProjectSettings.globalize_path(PRIMARY)) == OK
			and _slot_is_unchanged(expected_sha), "stage only the verified copy after reaching SELECT"):
		return
	var page := _preferences(screen)
	if page == null:
		return
	page.vol_sliders.master.value = SAVED_MASTER
	page.vol_sliders.sfx.value = SAVED_SFX
	var save := _button(page, "저장")
	if not _expect(save != null, "device preferences expose Save"):
		return
	save.pressed.emit()
	var config := ConfigFile.new()
	var cfg_sha := FileAccess.get_sha256(GameSettings.PATH)
	if not _expect(config.load(GameSettings.PATH) == OK and not cfg_sha.is_empty()
			and is_equal_approx(float(config.get_value("audio", "master", -1.0)), SAVED_MASTER)
			and is_equal_approx(float(config.get_value("audio", "sfx", -1.0)), SAVED_SFX)
			and _slot_is_unchanged(expected_sha), "Save writes audio settings without changing the product slot"):
		return
	var overlay: Node = screen.get_node_or_null("EntrySettings")
	_button(overlay, "화면·진행·소리 설정").pressed.emit()
	page.tabs[2].pressed.emit()
	page.vol_sliders.master.value = 0.65
	page.vol_sliders.sfx.value = 0.75
	if not _expect(is_equal_approx(GameSettings.vol_master, 0.65)
			and is_equal_approx(GameSettings.vol_sfx, 0.75), "slider preview changes live volume"):
		return
	_button(page, "취소").pressed.emit()
	if not _expect(is_equal_approx(GameSettings.vol_master, SAVED_MASTER)
			and is_equal_approx(GameSettings.vol_sfx, SAVED_SFX)
			and FileAccess.get_sha256(GameSettings.PATH) == cfg_sha
			and _slot_is_unchanged(expected_sha), "Cancel restores saved volume and preserves both files"):
		return
	_button(overlay, "시작 화면으로 돌아가기").pressed.emit()
	if not _expect(_button(screen, "적벽대전 시작") != null, "leaving settings returns to public Start"):
		return
	_button(screen, "적벽대전 시작").pressed.emit()
	_expect(await _wait_until(func(): return _button(screen, "서사 건너뛰기") != null)
		and _slot_is_unchanged(expected_sha), "Start still enters the prologue without changing the slot")


func _reopen_settings_and_slot(expected_sha: String) -> void:
	var cfg_sha := FileAccess.get_sha256(GameSettings.PATH)
	if not _expect(not cfg_sha.is_empty() and _slot_is_unchanged(expected_sha),
			"fresh process receives both exact isolated files"):
		return
	if not await _resume():
		return
	var host := _host()
	var packet := _capture(host)
	if not _expect(is_equal_approx(GameSettings.vol_master, SAVED_MASTER)
			and is_equal_approx(GameSettings.vol_sfx, SAVED_SFX),
			"startup loaded the saved settings in a different process"):
		return
	if not _expect(not host.started and not host.is_processing() and packet.get("tick") == 1
			and packet.get("pending", []).size() == 1 and packet.pending[0].kind == "finalize_withdrawal"
			and host._start.is_visible_in_tree() and not host._start.disabled,
			"public Continue restores the slot but still requires explicit host Start"):
		return
	_start(host)
	_expect(host.started and _capture(host) == packet
		and FileAccess.get_sha256(GameSettings.PATH) == cfg_sha and _slot_is_unchanged(expected_sha),
		"explicit Start remains usable and neither on-disk file changes")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase: String = args[0] if args.size() == 3 else ""
	var profile := OS.get_environment("SBTK_ENTRY_SETTINGS_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(phase in ["save", "reopen"] and not profile.is_empty() and actual == expected
			and ProjectSettings.get_setting("application/run/main_scene") == ENTRY, "isolated profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			if phase == "save":
				await _save_and_cancel(args[1], args[2])
			else:
				await _reopen_settings_and_slot(args[2])
	print("ENTRY_SETTINGS_RESULT phase=%s checks=%d failures=%d pid=%d" % [phase, _checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
