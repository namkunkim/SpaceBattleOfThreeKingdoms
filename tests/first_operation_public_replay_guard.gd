extends SceneTree

const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const Viewer := preload("res://scripts/first_operation_replay_viewer.gd")
const Slot := preload("res://scripts/first_operation_save_store.gd")
const Host := preload("res://scripts/first_operation_host.gd")
const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const ENTRY := "res://scenes/entry/EntryBoot.tscn"
const PRIMARY := Host.PRODUCT_SLOT_PATH
const PREVIOUS := PRIMARY + ".previous"
const ORIGINAL := "user://approved-original.pcopreplay"
const MUTANT := "user://unknown-rules.pcopreplay"

var _checks := 0
var _failures := 0
var _viewers: Array[WeakRef] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String) -> bool:
	_checks += 1
	_failures += 0 if condition else 1
	print("P02_REPLAY_GUARD_CHECK ", condition, " ", label)
	return condition


func _watch() -> Button:
	var map := current_scene as WorldMapScreen
	if map == null or map.state != "browse" or not map._atlas.is_visible_in_tree():
		return null
	var watch := map._cta.find_child("WatchReplay", true, false) as Button
	return watch if watch != null and watch.is_visible_in_tree() and not watch.disabled else null


func _wait_watch() -> bool:
	for attempt in 300:
		if _watch() != null:
			return true
		await process_frame
	return false


func _record_viewer(node: Node) -> void:
	if node.get_script() == Viewer:
		_viewers.append(weakref(node))


func _snapshot(map: WorldMapScreen, link: Node) -> Array:
	return [map.state, map.canvas.input_lock, map.hud.visible, map._atlas.visible, map._card.visible,
		link.brief, link.outcome, link.last_difficulty, link.last_mode, link._prepared_restore]


func _hashes() -> Array[String]:
	var output: Array[String] = []
	for path: String in [ORIGINAL, MUTANT, PRIMARY, PREVIOUS]:
		output.append(FileAccess.get_sha256(path))
	return output


func _storage_files() -> PackedStringArray:
	var paths := PackedStringArray()
	for filename in DirAccess.get_files_at("user://"):
		if filename.begins_with(PRIMARY.get_file()) or filename.begins_with(Ledger.PRODUCT_SLOT_PATH.get_file()):
			paths.append(filename)
	paths.sort()
	return paths


func _select(map: WorldMapScreen, watch: Button, path: String) -> bool:
	watch.grab_focus()
	watch.pressed.emit()
	if not _check(map._replay_dialog != null and map._replay_dialog.file_mode == FileDialog.FILE_MODE_OPEN_FILE,
			"public Atlas opens replay picker for " + path.get_file()):
		return false
	map._replay_dialog.file_selected.emit(ProjectSettings.globalize_path(path))
	return true


func _exercise() -> void:
	if not _check(await _wait_watch(), "EntryBoot routes real saved profile to public Atlas replay action"):
		return
	var map := current_scene as WorldMapScreen
	var link := root.get_node("WorldLink")
	var watch := _watch()
	var state := _snapshot(map, link)
	var hashes := _hashes()
	var storage := _storage_files()
	if not _check(Slot.read(PRIMARY).ok and Slot.read(PREVIOUS).ok and not hashes.has("") \
			and storage == PackedStringArray([PRIMARY.get_file(), PREVIOUS.get_file()]),
			"real replay and two saved generations have hashes and no settlement ledger"):
		return
	var good := Codec.read(ProjectSettings.globalize_path(ORIGINAL))
	var bad := Codec.read(ProjectSettings.globalize_path(MUTANT))
	if not _check(good.ok and good.bundle.max_ticks == 5487 and not bad.ok \
			and bad.error == "replay_rules_mismatch" and bad.path == "file.rules_digest",
			"codec rejects only the unknown authority fingerprint of the valid original"):
		return
	node_added.connect(_record_viewer)
	if not _select(map, watch, MUTANT) or not _check(_viewers.size() == 1, "selection constructs a single transient viewer"):
		return
	var rejected: Node = _viewers[0].get_ref()
	if not _check(is_instance_valid(rejected) and rejected._adapter == null and rejected._verification == null \
			and rejected._replay == null and rejected._frame.is_empty() and not rejected.is_processing(),
			"rejected viewer creates no adapter, verification session, playback or frame"):
		return
	await process_frame
	if not _check(_viewers[0].get_ref() == null and current_scene == map and _watch() == watch and watch.has_focus() \
			and map._replay_dialog == null and map._replay_overlay == null and _snapshot(map, link) == state \
			and map._chip.visible and map._chip_label.text == "replay_rules_mismatch / file.rules_digest",
			"rejection frees viewer and restores same Atlas, focus and exact public error"):
		return
	if not _check(_hashes() == hashes and _storage_files() == storage,
			"rejection preserves both replay files and saved-generation inventory"):
		return
	if not _select(map, watch, ORIGINAL) or not _check(_viewers.size() == 2 and map._replay_overlay != null \
			and map.canvas.input_lock and not map.hud.visible, "same action admits exact original to isolated verifier"):
		return
	var accepted: Node = _viewers[1].get_ref()
	if not _check(is_instance_valid(accepted), "retry has a new live viewer"):
		return
	accepted.set_process(false)
	var verification: RefCounted = accepted._verification
	if not _check(verification != null and verification._owner != null and verification._tick == 0 \
			and verification._cursor == 0 and accepted._verified_bundle == good.bundle \
			and accepted._replay == null and accepted._frame.is_empty(),
			"original starts private verification at tick zero with no published playback"):
		return
	var close: Array = accepted.find_children("*", "Button", true, false).filter(
		func(button: Button) -> bool: return button.text == "Close replay")
	if not _check(close.size() == 1 and close[0].is_visible_in_tree() and not close[0].disabled,
			"public close action is available while verification is pending"):
		return
	close[0].pressed.emit()
	await process_frame
	_check(_viewers[1].get_ref() == null and verification._owner == null and verification._tick == 0 \
		and current_scene == map and _watch() == watch and watch.has_focus() and map._replay_dialog == null \
		and map._replay_overlay == null and _snapshot(map, link) == state,
		"cancel closes private owner without stepping and restores same Atlas and focus")
	_check(_hashes() == hashes and _storage_files() == storage, "retry and cancel preserve replay and storage bytes")


func _run() -> void:
	var profile := OS.get_environment("SBTK_P02_REPLAY_GUARD_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _check(OS.has_feature("windows") and OS.get_cmdline_user_args().is_empty() and not profile.is_empty() \
			and actual == expected and ProjectSettings.get_setting("application/run/main_scene") == ENTRY,
			"isolated Windows profile and default EntryBoot without development flags"):
		if _check(change_scene_to_file(ENTRY) == OK, "load product EntryBoot"):
			await _exercise()
	print("P02_REPLAY_GUARD_RESULT checks=%d failures=%d pid=%d" % [_checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
