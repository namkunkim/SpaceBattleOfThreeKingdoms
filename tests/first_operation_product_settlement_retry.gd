extends "res://tests/first_operation_public_cursor.gd"

const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const PRODUCT_LEDGER := Ledger.PRODUCT_SLOT_PATH


func _ledger_absent() -> bool:
	return not FileAccess.file_exists(PRODUCT_LEDGER) \
		and not FileAccess.file_exists(PRODUCT_LEDGER + ".previous")


func _run() -> void:
	var allowed_profile := OS.get_environment("SBTK_P07_RETRY_PROFILE").replace("\\", "/")
	if not _expect(not allowed_profile.is_empty() and ProjectSettings.globalize_path("user://") \
			.replace("\\", "/").begins_with(allowed_profile + "/"), "run only in the isolated profile"):
		_finish()
		return
	if not _expect(_ledger_absent(), "fresh profile has no product settlement ledger"):
		_finish()
		return

	change_scene_to_file(ENTRY)
	for label in ["적벽대전 선택 · 시작", "서사 건너뛰기", "적벽", "출격 · 실제 전장 준비"]:
		if not await _entry_action(label):
			_finish()
			return
	if not _expect(await _wait_host(), "public entry mounts the direct product host"):
		_finish()
		return
	var host := _host()
	_start(host)
	if not _queue(host, "Withdraw") or not _expect(host.step_operation(), "Withdraw advances the first tick") \
			or not _queue(host, "Finalize withdrawal"):
		_finish()
		return
	host.step_operation()
	if not _expect(host.settlement != null and host.frame.tick == 2 and host.frame.clock_ms == 200 \
			and host.settlement.kind == "failure" and host.settlement.reason == "facility_never_secured" \
			and host.failure.is_empty(), "approved early withdrawal produces the expected terminal result"):
		_finish()
		return
	var terminal: Dictionary = host.frame.duplicate(true)
	var outcome := host.settlement as BattleOutcome
	var owner_id: int = host.operation_owner.get_instance_id()
	var return_button: Button = host._return
	var lock_path := ProjectSettings.globalize_path(PRODUCT_LEDGER + ".lock")
	if not _expect(return_button.is_visible_in_tree() and not return_button.disabled \
			and DirAccess.make_dir_absolute(lock_path) == OK, "hold only the isolated product ledger lock"):
		_finish()
		return
	for attempt in 2:
		return_button.pressed.emit()
		await process_frame
		_expect(is_instance_valid(host) and _host() == host and host.operation_owner.get_instance_id() == owner_id \
			and host.frame == terminal and host.settlement == outcome and not host._returning \
			and not host._product_settlement_committed, "busy return %d keeps the same terminal host" % (attempt + 1))
		_expect(return_button.text == "Retry map return" and not return_button.disabled \
			and host._save_status.text == "settlement_slot_busy / " + PRODUCT_LEDGER \
			and _ledger_absent() and DirAccess.dir_exists_absolute(lock_path), \
			"busy return %d displays the exact error and writes no generation" % (attempt + 1))
	if not _expect(DirAccess.remove_absolute(lock_path) == OK, "release the isolated lock"):
		_finish()
		return

	return_button.pressed.emit()
	var first: Dictionary = Slot.read(PRODUCT_LEDGER)
	var first_hash := FileAccess.get_sha256(PRODUCT_LEDGER)
	_expect(first.ok and first.payload.latest == outcome.settlement_id \
		and first.payload.consumed.size() == 1 and not FileAccess.file_exists(PRODUCT_LEDGER + ".previous"), \
		"retry publishes a single ledger record before the scene transition")
	return_button.pressed.emit()
	_expect(FileAccess.get_sha256(PRODUCT_LEDGER) == first_hash \
		and not FileAccess.file_exists(PRODUCT_LEDGER + ".previous"), \
		"duplicate return signal in the same dispatch does not rotate the ledger")
	if _expect(await _wait_until(func(): return current_scene is WorldMapScreen and current_scene.state == "result"), \
			"retry reaches the public map result"):
		var map := current_scene as WorldMapScreen
		var last: Dictionary = Slot.read(PRODUCT_LEDGER)
		_expect(map.outcome != null and map.outcome.settlement_id == outcome.settlement_id \
			and map.outcome.kind == outcome.kind and map.outcome.reason == outcome.reason \
			and roundi(map.outcome.t_s * 1000.0) == 200 and not is_instance_valid(host), \
			"map displays the original result and terminal host is freed")
		_expect(last == first and FileAccess.get_sha256(PRODUCT_LEDGER) == first_hash \
			and not FileAccess.file_exists(PRODUCT_LEDGER + ".previous") and not DirAccess.dir_exists_absolute(lock_path), \
			"one exact ledger generation remains without a lock")
		print("P07_PRODUCT_SETTLEMENT_OBSERVATION ", JSON.stringify({"ledger_sha256":first_hash, \
			"settlement_id":outcome.settlement_id,"kind":outcome.kind,"reason":outcome.reason, "clock_ms":200}))
	_finish()


func _finish() -> void:
	print("P07_PRODUCT_SETTLEMENT_RETRY checks=%d failures=%d pid=%d" % [_checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
