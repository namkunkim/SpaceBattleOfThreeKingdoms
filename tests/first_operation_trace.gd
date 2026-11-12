extends "res://tests/first_operation_public_cursor.gd"

const Trace := preload("res://scripts/first_operation_trace.gd")
const Settlements := preload("res://scripts/first_operation_settlement_store.gd")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := str(args[0]) if not args.is_empty() else ""
	var profile := OS.get_environment("SBTK_OPERATION_TRACE_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(not profile.is_empty() and actual == expected and mode in ["enabled", "disabled", "blocked"]
			and args.has(Trace.ARG) == (mode != "disabled")
			and ProjectSettings.get_setting("application/run/main_scene") == ENTRY, "isolated profile and exact product entry"):
		await _exercise(mode)
	print("FIRST_OPERATION_TRACE_RESULT mode=%s checks=%d failures=%d pid=%d" % [mode, _checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)


func _exercise(mode: String) -> void:
	if not _expect(not FileAccess.file_exists(PRIMARY) and not FileAccess.file_exists(PREVIOUS)
			and not FileAccess.file_exists(Settlements.PRODUCT_SLOT_PATH)
			and not DirAccess.dir_exists_absolute(Trace.DIRECTORY)
			and not FileAccess.file_exists(Trace.DIRECTORY), "fresh isolated profile"):
		return
	if mode == "blocked":
		var blocker := FileAccess.open(Trace.DIRECTORY, FileAccess.WRITE)
		if not _expect(blocker != null, "stage diagnostic directory collision"):
			return
		blocker.store_string("collision")
		blocker.close()
	if not _expect(change_scene_to_file(ENTRY) == OK, "load product main scene"):
		return
	for label in ["적벽대전 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			return
	if not _expect(await _wait_host(), "public sortie publishes product host"):
		return
	var host := _host()
	var events: Array = _event_kinds(host.frame)
	_start(host)
	# Exercise the actual queue rejection path with an invalid request.
	host._issue("invalid_trace_test")
	if not _queue(host, "Withdraw") or not _expect(host.step_operation(), "withdraw advances normally"):
		return
	events.append_array(_event_kinds(host.frame))
	if not _queue(host, "Finalize withdrawal"):
		return
	var pending := _capture(host)
	if not _expect(pending.get("tick") == 1 and pending.get("pending", []).size() == 1, "diagnostics leave the queued checkpoint intact") \
			or not _save(host, pending):
		return
	var checkpoint_hash := FileAccess.get_sha256(PRIMARY)
	var owner_id: int = host.operation_owner.get_instance_id()
	host._load.pressed.emit()
	if not _expect(await _wait_until(func(): return host.operation_owner.get_instance_id() != owner_id),
			"public Load replaces the live owner"):
		return
	_expect(not host.started and _capture(host) == pending, "restored trace starts with the exact paused checkpoint")
	_start(host)
	host.step_operation()
	if not _expect(host.settlement != null and host.frame.tick == 2 and host.frame.clock_ms == 200
			and host.settlement.reason == "facility_never_secured" and host.failure.is_empty(), "settlement and clock unaffected"):
		return
	var terminal_events := _event_kinds(host.frame)
	var settlement: Variant = JSON.parse_string(JSON.stringify(host.frame.projection.operation.settlement))
	host._return.pressed.emit()
	_expect(await _wait_until(func(): return current_scene is WorldMapScreen and current_scene.state == "result"),
		"public return reaches the result")
	var ledger := Slot.read(Settlements.PRODUCT_SLOT_PATH)
	_expect(FileAccess.get_sha256(PRIMARY) == checkpoint_hash and not FileAccess.file_exists(PREVIOUS)
		and ledger.ok and ledger.payload.consumed.size() == 1, "exact save bytes and a single ledger settlement")
	if mode == "enabled":
		_verify_logs(events, terminal_events, settlement)
	else:
		_expect(not DirAccess.dir_exists_absolute(Trace.DIRECTORY), "no operation trace directory")
		if mode == "blocked":
			_expect(FileAccess.get_file_as_string(Trace.DIRECTORY) == "collision", "collision file remains intact")


func _event_kinds(frame: Dictionary) -> Array:
	return frame.events.map(func(event: Dictionary): return event.kind)


func _verify_logs(fresh_events: Array, resumed_events: Array, settlement: Dictionary) -> void:
	var files := DirAccess.get_files_at(Trace.DIRECTORY)
	if not _expect(files.size() == 2, "one fresh segment and one resumed segment"):
		return
	var segments := {}
	for filename in files:
		var rows := _read_rows(Trace.DIRECTORY.path_join(filename))
		if not _expect(not rows.is_empty() and rows[0].kind == "session_start" and rows[-1].kind == "session_closed",
				"complete segment boundaries"):
			return
		segments[rows[0].data.restored] = rows
	if not _expect(segments.has(false) and segments.has(true), "segments identify fresh and restored starts"):
		return
	var fresh: Array = segments[false]
	var resumed: Array = segments[true]
	_expect(fresh[0].tick == 0 and fresh[-1].data.reason == "replaced"
		and resumed[0].tick == 1 and resumed[-1].data.reason == "settled", "replacement and resume preserve their clocks")
	_expect(_rows_of_kind(fresh, "operation_event").map(func(row: Dictionary): return row.data.event.kind) == fresh_events
		and _rows_of_kind(resumed, "operation_event").map(func(row: Dictionary): return row.data.event.kind) == resumed_events,
		"events match published host frames without another drain")
	var requests := _rows_of_kind(fresh, "command_request")
	var queued := _rows_of_kind(fresh, "command_queued")
	var rejected := _rows_of_kind(fresh, "command_rejected")
	_expect(requests.size() == 3 and requests[1].data.command.point == [0.0, 0.0]
		and queued.size() == 2 and rejected.size() == 1 and rejected[0].data.error == "unsupported_dev_command",
		"requests preserve JSON coordinates and queue decisions")
	var ends := _rows_of_kind(resumed, "operation_end")
	_expect(ends.size() == 1 and ends[0].tick == 2 and ends[0].sim_ms == 200
		and ends[0].data.settlement == settlement, "terminal record matches the actual operation settlement")
	for segment: Array in [fresh, resumed]:
		var snapshots := _rows_of_kind(segment, "snapshot")
		_expect(snapshots.size() == 1 and not snapshots[0].data.allies.is_empty()
			and snapshots[0].data.allies.all(func(row: Dictionary): return row.side == 0),
			"initial snapshot contains allied state only")


func _rows_of_kind(rows: Array, kind: String) -> Array:
	return rows.filter(func(row: Dictionary): return row.kind == kind)


func _read_rows(path: String) -> Array:
	var rows: Array = []
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		var row: Variant = JSON.parse_string(line)
		if not _expect(row is Dictionary and row.v == 1 and row.seq == rows.size() + 1
				and (rows.is_empty() or (rows[-1].tick <= row.tick and rows[-1].sim_ms <= row.sim_ms)),
				"valid versioned sequential row"):
			return []
		rows.append(row)
	return rows
