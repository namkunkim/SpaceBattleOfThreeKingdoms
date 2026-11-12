extends "res://tests/first_operation_public_cursor.gd"

const PRODUCT_LEDGER := "user://pc-first-operation-product-v1-settlements.save"
const FIXTURE_ORIGINAL := "user://p03-version-original"
const VERSION_CASES := [
	["envelope-version", "unsupported_version / " + PRIMARY, "unsupported_version", ""],
	["checkpoint-format", "unsupported_checkpoint_format / packet.format", "", "format"],
	["rules-digest", "checkpoint_rules_mismatch / packet.rules_digest", "", "rules_digest"],
]


func _slot_files() -> PackedStringArray:
	var files := DirAccess.get_files_at("user://")
	var slot_names := PackedStringArray()
	for file in files:
		if file.begins_with(PRIMARY.get_file()) or file.begins_with(PRODUCT_LEDGER.get_file()):
			slot_names.append(file)
	slot_names.sort()
	return slot_names


func _copy_primary(source: String, expected_sha: String) -> bool:
	return _expect(DirAccess.copy_absolute(source, PRIMARY) == OK \
		and FileAccess.get_sha256(PRIMARY) == expected_sha, "stage exact private fixture " + source.get_file())


func _reject(map: WorldMapScreen, resume: Button, case: Array, original: Dictionary,
		previous_sha: String, slot_names: PackedStringArray) -> bool:
	var id: String = case[0]
	var source := "user://p03-version-" + id
	var digest := FileAccess.get_sha256(source)
	if not _expect(not digest.is_empty() and digest != FileAccess.get_sha256(FIXTURE_ORIGINAL),
			"id-specific fixture is present and differs: " + id) or not _copy_primary(source, digest):
		return false
	var decoded := Slot.read(PRIMARY)
	if case[2] != "":
		if not _expect(not decoded.ok and decoded.error == case[2], "outer envelope fails before payload: " + id):
			return false
	else:
		var changed := original.duplicate(true)
		var key: String = case[3]
		changed[key] = "pc-first-operation-internal-replay/2" if key == "format" else "f".repeat(64)
		if not _expect(decoded.ok and decoded.payload == changed, "checksum-valid payload has exactly one changed field: " + id):
			return false
	var link := root.get_node("WorldLink")
	var before := [map.canvas.input_lock, map.hud.visible, link.brief, link.outcome, link._prepared_restore]
	resume.pressed.emit()
	var stayed := true
	for index in 4:
		await process_frame
		stayed = stayed and current_scene == map and _host() == null
	var state_preserved := stayed and map.state == "browse" and _atlas_resume() == resume \
		and map._restore_job == null and map._restore_overlay == null \
		and before == [map.canvas.input_lock, map.hud.visible, link.brief, link.outcome, link._prepared_restore]
	return _expect(state_preserved, "no host, restore job or route published: " + id) \
		and _expect(map._chip.visible and map._chip_label.text == case[1], "public Atlas error " + str(case[1])) \
		and _expect(FileAccess.get_sha256(PRIMARY) == digest and FileAccess.get_sha256(PREVIOUS) == previous_sha \
			and _slot_files() == slot_names, "reject preserves primary, valid previous and save/ledger inventory: " + id)


func _version_boundaries() -> void:
	if not _expect(await _wait_until(func(): return _atlas_resume() != null), "public Atlas offers first-operation resume"):
		return
	var map := current_scene as WorldMapScreen
	var resume := _atlas_resume()
	var original := Slot.read(PRIMARY)
	var previous := Slot.read(PREVIOUS)
	var oracle := _read_oracle(ORACLE_B)
	var slot_names := _slot_files()
	if oracle.is_empty() or not _expect(original.ok and previous.ok and original.payload == _slot_value(oracle.saved) \
		and FileAccess.get_sha256(PRIMARY) == oracle.primary_sha \
		and FileAccess.get_sha256(FIXTURE_ORIGINAL) == oracle.primary_sha \
		and FileAccess.get_sha256(PREVIOUS) == oracle.previous_sha \
		and slot_names == PackedStringArray([PRIMARY.get_file(), PREVIOUS.get_file()]),
		"authentic copied generations with a valid retained slot and no ledger"):
		return
	for case: Array in VERSION_CASES:
		if not await _reject(map, resume, case, original.payload, oracle.previous_sha, slot_names):
			return
	if not _copy_primary(FIXTURE_ORIGINAL, oracle.primary_sha) \
		or not _expect(current_scene == map and _atlas_resume() == resume, "retry uses the same public Atlas and button") \
		or not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == oracle.saved,
			"restored compatible checkpoint resumes exact state with its pending commands"):
		return
	_start(host)
	_expect(host.step_operation() and _capture(host) == oracle.advanced \
		and JSON.stringify(host.frame) == oracle.advanced_frame, "one manual tick consumes pending batch exactly as before")
	_expect(FileAccess.get_sha256(PRIMARY) == oracle.primary_sha and FileAccess.get_sha256(PREVIOUS) == oracle.previous_sha \
		and _slot_files() == slot_names, "successful retry and one tick do not publish a save or ledger")


func _run() -> void:
	var profile := OS.get_environment("SBTK_P03_CURSOR_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(OS.get_cmdline_user_args() == PackedStringArray(["version-boundaries"]) and not profile.is_empty() \
			and actual == expected and ProjectSettings.get_setting("application/run/main_scene") == ENTRY,
			"isolated profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			await _version_boundaries()
	print("P03_PUBLIC_CURSOR_RESULT phase=version-boundaries checks=%d failures=%d pid=%d" % [_checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
