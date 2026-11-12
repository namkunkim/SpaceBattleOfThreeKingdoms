extends "res://tests/first_operation_public_cursor.gd"
## Use isolated Windows profiles. The launcher supplies real generation B and its oracle,
## then moves the newly rotated C to an unpublished pending name before the recover phase.

const PENDING := PRIMARY + ".pending-fallback-test"
const ROTATION := "user://p03-public-cursor-rotation"
const REPAIRED := "user://p03-public-cursor-repaired"


func _retain() -> void:
	var earlier := _read_oracle(ORACLE_B)
	if earlier.is_empty() or not _expect(FileAccess.get_sha256(PRIMARY) == earlier.primary_sha \
			and FileAccess.get_sha256(PREVIOUS) == earlier.previous_sha and not FileAccess.file_exists(PENDING), \
			"start from the real two committed generations"):
		return
	if not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == earlier.saved, \
			"public host starts from exact generation B"):
		return
	_start(host)
	if not _expect(host.step_operation() and _capture(host) == earlier.advanced, "advance through generation B pending batch"):
		return
	if not _queue(host, "Stop"):
		return
	var newer := _capture(host)
	if not _expect(not newer.is_empty() and newer.tick == 4 and newer.commands == earlier.advanced.commands \
			and newer.pending.size() == 1 and newer.pending[0].kind == "stop", "distinct generation C carries its own pending Stop"):
		return
	if not _save(host, newer):
		return
	var retained := Slot.read(PREVIOUS)
	var new_sha := FileAccess.get_sha256(PRIMARY)
	if not _expect(not new_sha.is_empty() and new_sha != earlier.primary_sha \
			and FileAccess.get_sha256(PREVIOUS) == earlier.primary_sha and retained.ok \
			and retained.payload == _slot_value(earlier.saved), "real rotation replaces previous with byte-identical generation B"):
		return
	_write_oracle(ROTATION, {"pid": OS.get_process_id(), "c": newer, "c_sha": new_sha, "b_sha": earlier.primary_sha})


func _retained_bytes(rotation: Dictionary) -> bool:
	return FileAccess.get_sha256(PREVIOUS) == rotation.b_sha and FileAccess.get_sha256(PENDING) == rotation.c_sha


func _recover() -> void:
	var earlier := _read_oracle(ORACLE_B)
	var rotation := _read_oracle(ROTATION)
	if earlier.is_empty() or rotation.is_empty():
		return
	var pending := Slot.read(PENDING)
	if not _expect(not FileAccess.file_exists(PRIMARY) and _retained_bytes(rotation) and pending.ok \
			and pending.payload == _slot_value(rotation.c), "missing primary has real previous and unpublished newer bytes"):
		return
	if not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == earlier.saved, \
			"explicit public resume chooses exact retained B over unpublished C"):
		return
	_start(host)
	if not _expect(host.step_operation() and _capture(host) == earlier.advanced \
			and JSON.stringify(host.frame) == earlier.advanced_frame, "retained ordered batch applies once with exact uninterrupted frame"):
		return
	if not _expect(host.step_operation() and _capture(host) == earlier.empty \
			and JSON.stringify(host.frame) == earlier.empty_frame, "empty tick neither repeats the batch nor applies the unpublished Stop"):
		return
	if not _expect(not FileAccess.file_exists(PRIMARY) and _retained_bytes(rotation), \
			"resume and advance leave primary absent and preserve previous and pending bytes"):
		return
	if not _save(host, earlier.empty):
		return
	var repaired_sha := FileAccess.get_sha256(PRIMARY)
	if not _expect(not repaired_sha.is_empty() and repaired_sha not in [rotation.b_sha, rotation.c_sha] \
			and _retained_bytes(rotation), "explicit save repairs primary and preserves both retained and unpublished bytes"):
		return
	if not _expect(host.step_operation(), "advance uninterrupted after repair"):
		return
	var next := _capture(host)
	if not _expect(not next.is_empty() and next.tick == 6 and next.commands == earlier.empty.commands \
			and next.pending.is_empty(), "uninterrupted tick after repair appends no command"):
		return
	_write_oracle(REPAIRED, {"pid": OS.get_process_id(), "saved": earlier.empty, "next": next,
		"next_frame": JSON.stringify(host.frame), "sha": repaired_sha})


func _open_repaired() -> void:
	var repaired := _read_oracle(REPAIRED)
	var rotation := _read_oracle(ROTATION)
	if repaired.is_empty() or rotation.is_empty():
		return
	if not _expect(FileAccess.get_sha256(PRIMARY) == repaired.sha and _retained_bytes(rotation), \
			"new process starts with repaired, retained and unpublished bytes intact"):
		return
	if not await _resume():
		return
	var host := _host()
	if not _expect(not host.started and not host.is_processing() and _capture(host) == repaired.saved, \
			"public resume selects repaired primary over retained and unpublished generations"):
		return
	_start(host)
	_expect(host.step_operation() and _capture(host) == repaired.next \
		and JSON.stringify(host.frame) == repaired.next_frame, "repaired primary resumes exactly with no duplicate or unpublished command")
	_expect(FileAccess.get_sha256(PRIMARY) == repaired.sha and _retained_bytes(rotation), \
		"opening the repaired primary leaves all three file hashes unchanged")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var phase: String = args[0] if args.size() == 1 else ""
	var profile := OS.get_environment("SBTK_P03_CURSOR_PROFILE")
	var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").simplify_path().to_lower()
	if _expect(phase in ["retain", "recover", "open-repaired"] and not profile.is_empty() and actual == expected \
			and ProjectSettings.get_setting("application/run/main_scene") == ENTRY, "isolated profile and product default scene"):
		if _expect(change_scene_to_file(ENTRY) == OK, "load product default scene"):
			match phase:
				"retain": await _retain()
				"recover": await _recover()
				"open-repaired": await _open_repaired()
	print("P03_PUBLIC_CURSOR_RESULT phase=%s checks=%d failures=%d pid=%d" % [phase, _checks, _failures, OS.get_process_id()])
	quit(0 if _failures == 0 else 1)
