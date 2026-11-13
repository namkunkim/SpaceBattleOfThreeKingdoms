extends "res://tests/first_operation_public_cursor.gd"

const Codec := preload("res://scripts/first_operation_external_save.gd")
const Ledger := preload("res://scripts/first_operation_settlement_store.gd")


func _run() -> void:
	var profile := OS.get_environment("SBTK_P04_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(OS.has_feature("windows") and not profile.is_empty() and actual == expected, "isolated Windows profile"):
		await _exercise(profile, OS.get_cmdline_user_args().has("state-digest"))
	print("P04_PUBLIC_EXTERNAL_SAVE checks=%d failures=%d" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _exercise(profile: String, focused: bool) -> void:
	if not _expect(_protected_files() == ["", "", "", ""], "fresh isolated slots"):
		return
	change_scene_to_file(ENTRY)
	for label in ["적벽대전 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			print("entry state=", current_scene.screen.flow.state, " error=", current_scene.screen.flow.error)
			return
	if not _expect(await _wait_host(), "public entry publishes product host"):
		return
	var host := _host()
	_start(host)
	if not _queue(host, "Move to waypoint 1"):
		return
	for tick in 1252:
		if not _expect_advance(host, tick):
			return
	if not _queue(host, "Stop"):
		return
	var saved := _capture(host)
	if not _expect(saved.get("event_cursor", 0) > 0 and saved.commands.size() == 1 and saved.pending.size() == 1,
			"fixture has a consumed event cursor and applied and pending commands"):
		return
	if not _save(host, saved) or not _save(host, saved):
		return
	var settled_id: String = saved.operation_id.get_slice("/", 0) + "/" + "f".repeat(32)
	if not _expect(_consume(settled_id) and _consume(saved.operation_id.get_slice("/", 0) + "/" + "e".repeat(32)),
			"seed both settlement generations"):
		return
	var protected := _protected_files()
	_expect(protected.all(func(hash): return not hash.is_empty()), "all four protected files exist")
	if focused:
		await _state_digest_rejection(host, profile, saved, protected)
		return
	var external := profile.path_join("valid.pcopsave")
	var blocked_directory := profile.path_join("missing")
	var retry := blocked_directory.path_join("retry.pcopsave")
	var original: RefCounted = host.operation_owner
	var frame: Dictionary = host.frame.duplicate(true)
	if not _picker(host, true):
		return
	host._file_dialog.canceled.emit()
	_expect(_stable(host, original, frame, saved), "cancel restores live checkpoint and controls")
	if not _select(host, true, retry):
		return
	_expect(host._save_status.text == "external_write_failed / file" and _stable(host, original, frame, saved),
		"write failure preserves current operation")
	_expect(_protected_files() == protected, "failed export preserves all four files")
	_expect(DirAccess.make_dir_absolute(blocked_directory) == OK, "remove isolated write failure")
	if not _select(host, true, retry) or not _select(host, true, external):
		return
	_expect(DirAccess.get_files_at(blocked_directory) == PackedStringArray(["retry.pcopsave"]),
		"retry publishes one file and no temporary")
	var exported_hash := FileAccess.get_sha256(external)
	if not _select(host, true, external):
		return
	_expect(host._save_status.text == "external_path_exists / path" and FileAccess.get_sha256(external) == exported_hash,
		"duplicate export preserves the existing external file")
	_expect(_protected_files() == protected, "successful and duplicate exports preserve all four files")
	var decoded := Codec.read(external, true)
	if not _expect(decoded.ok and decoded.payload == saved and Codec.read(external).get("error") == "external_unsupported_request",
			"public export round trips and developer codec rejects it"):
		return
	var bad := profile.path_join("bad-authority.pcopsave")
	_write_wire(bad, saved, "effective_digest", "0".repeat(64))
	var dev := profile.path_join("developer.pcopsave")
	var dev_packet := saved.duplicate(true)
	dev_packet.request.capability = BattleBrief.FIRST_OPERATION_DEV_REQUEST.capability
	_expect(Codec.write(dev_packet, dev).ok, "canonical developer request fixture")
	var settled_path := profile.path_join("settled.pcopsave")
	_write_wire(settled_path, saved, "operation_id", settled_id)
	if not _expect(host.step_operation(), "uninterrupted tick consumes pending Stop"):
		return
	var continued := _capture(host)
	var continued_frame: Dictionary = host.frame.duplicate(true)

	frame = host.frame.duplicate(true)
	for rejection in [[dev, "external_unsupported_request"], [bad, "checkpoint_source_mismatch"],
			[settled_path, "checkpoint_already_settled"]]:
		if not _select(host, false, rejection[0]):
			return
		_expect(host._save_status.text.begins_with(rejection[1] + " / ") and _stable(host, original, frame, continued)
			and _protected_files() == protected, "reject %s without publication" % rejection[1])
	if not _select(host, false, external):
		return
	_expect(host._restore_job != null and host.operation_owner == original, "valid import remains private during replay")
	host._cancel_restore.pressed.emit()
	_expect(host._save_status.text == "Restore cancelled" and _stable(host, original, frame, continued)
		and _protected_files() == protected, "cancel candidate then preserve all four files")
	if not _select(host, false, external):
		return
	var lock := ProjectSettings.globalize_path(Ledger.PRODUCT_SLOT_PATH + ".lock")
	if not _expect(DirAccess.make_dir_absolute(lock) == OK, "simulate concurrent settlement writer during replay"):
		return
	_expect(await _wait_restore(host), "busy candidate finishes")
	_expect(host._save_status.text.begins_with("settlement_slot_busy / ") and _stable(host, original, frame, continued)
		and _protected_files() == protected, "busy publication keeps old owner and all four files")
	_expect(DirAccess.remove_absolute(lock) == OK, "release isolated ledger lock")

	if not await _reject_state_digest(host, profile, saved, continued, protected):
		return
	if not _select(host, false, external):
		return
	if not _expect(await _wait_restore(host), "retry finishes"):
		return
	_expect(host.operation_owner != original and not host.started and _capture(host) == saved and host.frame.events.is_empty(),
		"one resumed candidate preserves exact checkpoint with no republished events")
	_start(host)
	_expect(host.step_operation() and _capture(host) == continued
		and JSON.stringify(host.frame) == JSON.stringify(continued_frame), "one pending Stop reproduces uninterrupted state")
	_expect(_protected_files() == protected, "both operations preserve the two slot and two ledger files")


func _state_digest_rejection(host: Node, profile: String, saved: Dictionary, protected: Array) -> void:
	var valid := profile.path_join("valid.pcopsave")
	if not _select(host, true, valid):
		return
	if not _expect(host.step_operation(), "uninterrupted tick consumes pending Stop"):
		return
	var continued := _capture(host)
	var frame: Dictionary = host.frame.duplicate(true)
	var owner: RefCounted = host.operation_owner
	if not _expect(Codec.read(valid, true).get("payload") == saved, "valid public export matches checkpoint"):
		return
	if not await _reject_state_digest(host, profile, saved, continued, protected):
		return
	if not _select(host, false, valid) or not _expect(await _wait_restore(host), "same-host retry finishes"):
		return
	_expect(host.operation_owner != owner and not host.started and _capture(host) == saved and host.frame.events.is_empty(),
		"retry publishes exact checkpoint without republishing consumed events")
	_start(host)
	_expect(host.step_operation() and _capture(host) == continued and JSON.stringify(host.frame) == JSON.stringify(frame),
		"pending Stop applies once and reproduces uninterrupted state")
	_expect(_protected_files() == protected and _no_pending_files(profile), "retry preserves all four files without staging")


func _reject_state_digest(host: Node, profile: String, saved: Dictionary, continued: Dictionary, protected: Array) -> bool:
	var invalid := profile.path_join("bad-state.pcopsave")
	_write_wire(invalid, saved, "state_digest", "0".repeat(64))
	var expected := saved.duplicate(true)
	expected.state_digest = "0".repeat(64)
	var decoded := Codec.read(invalid, true)
	if not _expect(decoded.get("payload") == expected
			and expected.state_digest != saved.state_digest, "canonical packet differs only in state digest"):
		return false
	var frame: Dictionary = host.frame.duplicate(true)
	var owner: RefCounted = host.operation_owner
	var brief: BattleBrief = host.brief
	var brief_data := brief.to_dict().duplicate(true)
	if not _select(host, false, invalid):
		return false
	if not _expect(host._restore_job != null and host.operation_owner == owner
			and host._import.disabled and host._export.disabled, "tampered candidate enters private replay"):
		return false
	if not _expect(await _wait_restore(host), "tampered replay finishes"):
		return false
	_expect(host._save_status.text == "checkpoint_state_mismatch / packet.state_digest"
		and _stable(host, owner, frame, continued) and host.brief == brief
		and host.link.brief == brief and host.brief.to_dict() == brief_data,
		"late failure preserves live owner, brief, checkpoint and controls")
	_expect(_protected_files() == protected and _no_pending_files(profile), "late failure preserves all four files without staging")
	return true


func _no_pending_files(profile: String) -> bool:
	for directory in [profile, "user://"]:
		for name in DirAccess.get_files_at(directory):
			if ".pending-" in name:
				return false
	return true


func _wait_restore(host: Node) -> bool:
	var deadline := Time.get_ticks_msec() + 15000
	while host._restore_job != null and Time.get_ticks_msec() < deadline:
		await process_frame
	return host._restore_job == null


func _expect_advance(host: Node, tick: int) -> bool:
	if host.step_operation():
		return true
	return _expect(false, "advance fixture to tick %d" % (tick + 1))


func _protected_files() -> Array:
	return [FileAccess.get_sha256(PRIMARY), FileAccess.get_sha256(PREVIOUS),
		FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH), FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH + ".previous")]


func _picker(host: Node, exporting: bool) -> bool:
	var button: Button = host._export if exporting else host._import
	if not _expect(button.is_visible_in_tree() and not button.disabled, "public external button enabled"):
		return false
	button.pressed.emit()
	var dialog: FileDialog = host._file_dialog
	return _expect(dialog != null and dialog.file_mode == (FileDialog.FILE_MODE_SAVE_FILE if exporting
		else FileDialog.FILE_MODE_OPEN_FILE) and dialog.filters[0].begins_with("*.pcopsave") and not host.is_processing(),
		"public picker has expected mode and filter")


func _select(host: Node, exporting: bool, path: String) -> bool:
	if not _picker(host, exporting):
		return false
	host._file_dialog.file_selected.emit(path)
	return true


func _stable(host: Node, owner: RefCounted, frame: Dictionary, packet: Dictionary) -> bool:
	return host.operation_owner == owner and host.frame == frame and host.started and not host.is_processing() \
		and host._file_dialog == null and host._restore_job == null and not host._import.disabled \
		and not host._export.disabled and _capture(host) == packet


func _write_wire(path: String, packet: Dictionary, key: String, value: String) -> void:
	var public := packet.duplicate(true)
	public.erase("format")
	public[key] = value
	var body := JSON.stringify(public, "", true, true)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"format": Codec.FORMAT, "version": Codec.VERSION, "sha256": body.sha256_text(), "body": body},
		"", true, true))
	file.close()


func _consume(operation_id: String) -> bool:
	var outcome := BattleOutcome.new()
	outcome.settlement_id = operation_id + "/settlement"
	outcome.kind = "failure"
	outcome.reason = "facility_never_secured"
	outcome.t_s = 0.2
	outcome.seed = 208
	outcome.mode = "direct"
	outcome.difficulty = "standard"
	return Ledger.consume(outcome, Ledger.PRODUCT_SLOT_PATH).ok
