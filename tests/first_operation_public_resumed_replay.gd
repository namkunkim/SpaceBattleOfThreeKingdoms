extends "res://tests/first_operation_public_cursor.gd"

const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const Viewer := preload("res://scripts/first_operation_replay_viewer.gd")
const ORACLE := "user://resumed-replay-oracle"
const UNINTERRUPTED := "user://uninterrupted.pcopreplay"
const RESUMED := "user://resumed.pcopreplay"
const EXPECTED := [{"tick": 0, "kind": "withdraw"}, {"tick": 1, "kind": "finalize_withdrawal"}]


func _export_terminal(host: Node, path: String) -> Dictionary:
	if not _expect(host.settlement != null and host.frame.tick == 2 and host.frame.clock_ms == 200
			and host._export_replay.is_visible_in_tree() and not host._export_replay.disabled,
			"two-tick terminal host exposes public replay export"):
		return {}
	host._export_replay.pressed.emit()
	if not _expect(host._file_dialog != null and host._file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE,
			"public export opens the save picker"):
		return {}
	var absolute := ProjectSettings.globalize_path(path)
	host._file_dialog.file_selected.emit(absolute)
	var replay := Codec.read(absolute)
	var expected_settlement := {}
	for field: String in Adapter.SETTLEMENT_FIELDS:
		expected_settlement[field] = host.frame.projection.operation.settlement[field]
	if not _expect(host._save_status.text == "Replay exported" and replay.ok
			and replay.bundle.commands == EXPECTED and replay.bundle.max_ticks == 2
			and replay.bundle.expected_settlement.reason == "facility_never_secured"
			and replay.bundle.expected_settlement == expected_settlement,
			"exported replay records each command once at its original tick and the exact settlement"):
		return {}
	return replay.bundle


func _make_checkpoint() -> void:
	if not _expect(not FileAccess.file_exists(PRIMARY) and not FileAccess.file_exists(UNINTERRUPTED),
			"start with an empty isolated profile"):
		return
	for label in ["적벽대전 선택 · 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			return
	if not _expect(await _wait_host(), "public EntryBoot sortie mounts the product host"):
		return
	var host := _host()
	_start(host)
	if not _queue(host, "Withdraw") or not _expect(host.step_operation() and host.frame.tick == 1,
			"apply Withdraw and reach checkpoint tick one") or not _queue(host, "Finalize withdrawal"):
		return
	var saved := _capture(host)
	if not _expect(not saved.is_empty() and saved.tick == 1 and saved.commands.size() == 1
			and saved.commands[0].tick == 0 and saved.commands[0].batch.size() == 1
			and saved.commands[0].batch[0].kind == "withdraw" and saved.pending.size() == 1
			and saved.pending[0].kind == "finalize_withdrawal",
			"checkpoint holds the applied prefix and a distinct pending terminal command"):
		return
	if not _save(host, saved):
		return
	var saved_sha := FileAccess.get_sha256(PRIMARY)
	host.step_operation()
	var bundle := _export_terminal(host, UNINTERRUPTED)
	if bundle.is_empty():
		return
	_write_oracle(ORACLE, {"pid": OS.get_process_id(), "saved": saved, "slot_sha": saved_sha,
		"events": host.frame.events, "projection": host.frame.projection,
		"bundle_sha": FileAccess.get_sha256(UNINTERRUPTED)})


func _export_restored() -> void:
	var oracle := _read_oracle(ORACLE)
	if oracle.is_empty() or not _expect(FileAccess.get_sha256(PRIMARY) == oracle.slot_sha
			and FileAccess.get_sha256(UNINTERRUPTED) == oracle.bundle_sha and not FileAccess.file_exists(RESUMED),
			"original checkpoint and uninterrupted export are unchanged before resume"):
		return
	if not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == oracle.saved,
			"public Atlas restores the exact tick-one checkpoint without starting it"):
		return
	_start(host)
	host.step_operation()
	var bundle := _export_terminal(host, RESUMED)
	if bundle.is_empty():
		return
	_expect(host.frame.events == oracle.events and host.frame.projection == oracle.projection,
		"resumed terminal events and projection equal the uninterrupted oracle")
	_expect(FileAccess.get_sha256(RESUMED) == oracle.bundle_sha
		and FileAccess.get_sha256(UNINTERRUPTED) == oracle.bundle_sha
		and FileAccess.get_sha256(PRIMARY) == oracle.slot_sha and not FileAccess.file_exists(PREVIOUS),
		"resumed export is byte-identical and neither save generation is changed")


func _watch() -> Button:
	if not current_scene is WorldMapScreen or current_scene.state != "browse":
		return null
	var button := current_scene._cta.find_child("WatchReplay", true, false) as Button
	return button if button != null and button.is_visible_in_tree() and not button.disabled else null


func _verify_export() -> void:
	var oracle := _read_oracle(ORACLE)
	if oracle.is_empty() or not _expect(FileAccess.get_sha256(RESUMED) == oracle.bundle_sha,
			"replay phase starts with the exact resumed export"):
		return
	if not _expect(await _wait_until(func(): return _watch() != null), "public Atlas offers Watch Replay"):
		return
	var map := current_scene as WorldMapScreen
	var watch := _watch()
	var viewers: Array[WeakRef] = []
	node_added.connect(func(node: Node) -> void:
		if node.get_script() == Viewer:
			viewers.append(weakref(node)))
	watch.grab_focus()
	watch.pressed.emit()
	if not _expect(map._replay_dialog != null, "public Atlas opens replay picker"):
		return
	map._replay_dialog.file_selected.emit(ProjectSettings.globalize_path(RESUMED))
	if not _expect(viewers.size() == 1 and viewers[0].get_ref() != null,
			"public replay loads resumed export"):
		return
	var viewer: Node = viewers[0].get_ref()
	if not _expect(await _wait_until(func(): return viewer._replay != null) and viewer._frame.tick == 0,
			"asynchronous verification admits resumed export and begins playback from tick zero"):
		return
	var step := _button(viewer, "Step one tick")
	if not _expect(step != null, "verified replay exposes the step action"):
		return
	step.pressed.emit()
	if not _expect(viewer._frame.tick == 1 and not viewer._finished, "replay advances through the applied prefix"):
		return
	step.pressed.emit()
	var terminal: Dictionary = viewer._frame.projection.operation.settlement
	var expected: Dictionary = oracle.projection.operation.settlement
	if not _expect(viewer._frame.tick == 2 and viewer._frame.clock_ms == 200 and viewer._finished
			and terminal == expected and viewer._frame.events == oracle.events
			and viewer._frame.projection == oracle.projection,
			"public replay reproduces the exact ordered terminal events, projection and settlement"):
		return
	var close := _button(viewer, "Close replay")
	if not _expect(close != null, "terminal replay can be closed"):
		return
	close.pressed.emit()
	await process_frame
	_expect(viewers[0].get_ref() == null and current_scene == map and watch.has_focus()
		and FileAccess.get_sha256(RESUMED) == oracle.bundle_sha and FileAccess.get_sha256(PRIMARY) == oracle.slot_sha,
		"closing replay restores the same Atlas and preserves resumed replay and checkpoint bytes")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase: String = args[0] if args.size() == 1 else ""
	var profile := OS.get_environment("SBTK_P02_P03_REPLAY_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(OS.has_feature("windows") and phase in ["checkpoint", "resume", "replay"] and not profile.is_empty()
			and actual == expected and ProjectSettings.get_setting("application/run/main_scene") == ENTRY,
			"isolated Windows profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			match phase:
				"checkpoint": await _make_checkpoint()
				"resume": await _export_restored()
				"replay": await _verify_export()
	print("P02_P03_RESUMED_REPLAY_RESULT phase=%s checks=%d failures=%d pid=%d" % [phase, _checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
