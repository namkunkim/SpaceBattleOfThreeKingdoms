extends SceneTree

const Slot := preload("res://scripts/cross_counter/public_slot.gd")
const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const PREVIOUS_SUFFIX := ".previous"
const ID := Slot.OPERATION_PREFIX + "12341234123412341234123412341234"

var _failed := 0
var _checks := 0
var _parent_id := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var profile := OS.get_environment("SBTK_CC_LIFECYCLE_PROFILE").replace("\\", "/")
	var actual := OS.get_user_data_dir().replace("\\", "/")
	if args.size() != 2 or not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless" \
			and profile.begins_with("F:/WorkSpace/Campaign-Orchestration/") and actual.begins_with(profile + "/"),
			"explicit isolated F profile"):
		quit(1)
		return
	_parent_id = args[1]
	var parent_file_hash := FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH)
	match args[0]:
		"hold":
			await _hold()
		"busy":
			_check(Slot.open().get("error") == "cross_counter_slot_busy", "separate active process refused")
		"resume":
			_resume()
		"closed":
			_completed()
		_:
			_check(false, "known check mode")
	_check(not parent_file_hash.is_empty() and FileAccess.get_sha256(Ledger.PRODUCT_SLOT_PATH) == parent_file_hash,
		"consumed ledger bytes preserved")
	print("CROSS_COUNTER_PUBLIC_SLOT %s %d/%d" % [args[0], _checks - _failed, _checks])
	quit(1 if _failed else 0)


func _hold() -> void:
	var opened := Slot.open()
	if not _check(opened.ok and opened.head.revision == 0, "empty native slot acquired"):
		return
	var slot: Slot = opened.lease
	var pending := _packet(0, false)
	_check(slot.start(Ledger.ID_PREFIX + "f".repeat(32) + Ledger.ID_SUFFIX, ID, pending).get("error")
		== "cross_counter_parent_ineligible", "unconsumed parent denied")
	_check(slot.start(_parent_id, ID, _packet(1, true)).get("error") == "cross_counter_invalid_c0",
		"only unstarted C0 can take durable authority")
	var parent := Slot.eligible_parent(_parent_id)
	_check(parent.ok and slot.start(_parent_id, ID, pending).ok, "real consumed objective commits C0")
	_check(slot.head().active.parent_sha256 == parent.digest and slot.head().active.packet == pending,
		"parent digest and exact typed C0 remain bound")
	_check(slot.start(_parent_id, ID, pending).get("error") == "cross_counter_owner_active",
		"active child cannot be replaced")
	var ready := FileAccess.open("user://test-lease-ready", FileAccess.WRITE)
	ready.store_string(str(OS.get_process_id()))
	ready.close()
	var deadline := Time.get_ticks_msec() + 50000
	while not FileAccess.file_exists("user://test-lease-release") and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(FileAccess.file_exists("user://test-lease-release"), "observed cross-process contention before exit")
	# Retain the lease until the process exits.
	set_meta("live_lease", slot)


func _resume() -> void:
	var opened := Slot.open()
	if not _check(opened.ok and opened.head.active.packet == _packet(0, false), "new process recovers committed C0"):
		return
	var slot: Slot = opened.lease
	var path := Slot.SLOT_PATH
	var started := _packet(7, true)
	_check(slot.save(started).ok and slot.head().active.packet == started, "save updates durable active checkpoint")
	var before := FileAccess.get_sha256(path)
	_check(slot.save(started).get("written") == false and FileAccess.get_sha256(path) == before,
		"same checkpoint retry does not rewrite")
	_check(slot.save(_packet(6, true)).get("error") == "cross_counter_stale_checkpoint", "backwards tick rejected")
	# A directory at the backup path causes the Win32 publisher to fail before primary replacement.
	DirAccess.remove_absolute(path + PREVIOUS_SUFFIX)
	DirAccess.make_dir_absolute(path + PREVIOUS_SUFFIX)
	_check(not slot.save(_packet(8, true)).ok and slot.head().active.packet == started
		and FileAccess.get_sha256(path) == before, "failed publisher preserves active checkpoint and lease")
	DirAccess.remove_absolute(path + PREVIOUS_SUFFIX)
	_check(slot.save(_packet(8, true)).ok, "same owner retries recovered publisher")
	var settlement := {"id": ID + "/settlement", "kind": "failure", "reason": "abandoned",
		"clock_ms": 850, "seed": 20824, "mode": "direct", "difficulty": "standard"}
	var terminal := _packet(9, true)
	terminal.clock_ms = 850
	terminal.settlement = settlement.duplicate(true)
	var malformed := terminal.duplicate(true)
	malformed.settlement.seed = true
	_check(slot.settle(malformed, settlement).get("error") == "cross_counter_invalid_terminal_checkpoint",
		"malformed terminal packet fails typed equality")
	_check(slot.settle(terminal, settlement).ok and slot.head().active.is_empty(), "single atomic settlement and tombstone")
	before = FileAccess.get_sha256(path)
	_check(slot.settle(terminal, settlement).get("written") == false and FileAccess.get_sha256(path) == before,
		"same terminal retry has no effect")
	terminal.settlement.reason = "different"
	_check(slot.settle(terminal, terminal.settlement).get("error") == "cross_counter_settlement_conflict"
		and FileAccess.get_sha256(path) == before, "different terminal retry conflicts without mutation")
	slot.close()
	_check(slot.save(started).get("error") == "cross_counter_lease_closed", "closed lease cannot write")


func _completed() -> void:
	var opened := Slot.open()
	if not _check(opened.ok and opened.head.active.is_empty() and opened.head.completed.has(_parent_id),
			"later process recovers child terminal tombstone"):
		return
	var slot: Slot = opened.lease
	_check(slot.start(_parent_id, ID, _packet(0, false)).get("error") == "cross_counter_parent_already_used",
		"same parent cannot start another child")
	slot.close()


func _packet(tick: int, started: bool) -> Dictionary:
	return {"operation_id": ID, "tick": tick, "clock_ms": tick * 100, "bootstrap_done": started, "settlement": {}}


func _check(ok: bool, label: String) -> bool:
	_checks += 1
	if not ok:
		_failed += 1
	print("CROSS_COUNTER_SLOT_CHECK ", ok, " ", label)
	return ok
