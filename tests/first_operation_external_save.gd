extends SceneTree

const Codec := preload("res://scripts/first_operation_external_save.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const Dev := preload("res://core/battle/first_operation_dev.gd")
const REQUEST := {
	"capability": "pc/first-operation-dev/1", "definition_id": "red-cliffs-first-operation-dev-v1",
	"definition_version": 1, "roster_id": "red-cliffs-dev-roster-v1", "seed": 208,
	"difficulty": "standard", "mode": "direct", "route_id": "front",
}

var _checks := 0
var _failed := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "reopen":
		_reopen(args[1])
	elif args.is_empty():
		_check(false, "pass a new, isolated local directory and optional previous slot copy")
	else:
		_round_trip(args[0])
		if args.size() == 2:
			_migrate_copy(args[0], args[1])
	print("first_operation_external_save: %d checks, passed=%s" % [_checks, not _failed])
	quit(1 if _failed else 0)

func _round_trip(directory: String) -> void:
	var original_slot := ProjectSettings.globalize_path(Store.SLOT_PATH)
	var slot_hash := FileAccess.get_sha256(original_slot)
	var created := Dev.prepare_fresh(REQUEST)
	if not created.ok:
		_check(false, "fresh owner: %s" % created)
		return
	var owner: RefCounted = created.owner
	owner.publish()
	for tick in 1251:
		owner.advance()
	var ids: Array = owner.read_projection().projection.squadrons.filter(func(row): return row.side == 0).map(func(row): return row.id)
	_check(owner.queue({"kind": "stop", "side": 0, "ids": ids}).ok, "save pending stop")
	var packet: Dictionary = owner.capture_checkpoint().packet
	var path := directory.path_join("active.pcopsave")
	_check(Codec.write(packet, path).ok, "export through public API")
	var read := Codec.read(path)
	if not read.get("ok", false):
		_check(false, "read public export: %s" % read)
		owner.close()
		return
	_check(read.payload == packet, "exact internal payload recovered")
	var encoded := FileAccess.get_file_as_string(path)
	var envelope: Dictionary = JSON.parse_string(encoded)
	var public_payload := packet.duplicate(true)
	public_payload.erase("format")
	var expected_body := JSON.stringify(public_payload, "", true, true)
	_check(encoded == _wire(expected_body), "separate public golden field encoding and SHA")
	_check(not JSON.parse_string(envelope.body).has("format"), "internal format marker remains private")
	var hash := FileAccess.get_sha256(path)
	_check(Codec.write(packet, path).get("error") == "external_path_exists", "existing export is preserved")
	_check(FileAccess.get_sha256(path) == hash, "existing export bytes unchanged")

	var begun := Dev.begin_restore(read.payload)
	var restored := _complete(begun)
	if restored.get("ok", false):
		var other: RefCounted = restored.owner
		_check(other.preview_initial_frame().frame.tick == 1251, "import stays prepared at the saved tick")
		other.publish()
		_check(other.capture_checkpoint().packet == packet, "same owner state, pending queue and event cursor")
		_check(owner.advance().ok and other.advance().ok and owner.read_projection() == other.read_projection(), "same continuation after import")
		var events: Array = owner.drain_events().events
		_check(events == other.drain_events().events and events.any(func(event): return event.kind == "reinforcement_entered"), "ordered unread reserve event survives")
		other.close()
	else:
		_check(false, "import replay: %s" % restored)

	var before: Dictionary = owner.capture_checkpoint().packet
	_reject(directory, "bad-version", _wire(expected_body, 2), "external_unsupported_version")
	_reject(directory, "trailing-newline", encoded + "\n", "external_noncanonical_json")
	var bom_path := directory.path_join("bom.pcopsave")
	var bom := FileAccess.open(bom_path, FileAccess.WRITE)
	bom.store_buffer(PackedByteArray([0xef, 0xbb, 0xbf]))
	bom.store_string(encoded)
	bom.close()
	_check(Codec.read(bom_path).get("error") == "external_noncanonical_json", "BOM rejected before decoding")
	_reject(directory, "wrong-magic", _wire(expected_body).replace("pc-first-operation-external", "pc-first-operation-save"), "external_invalid_format")
	_reject(directory, "bad-checksum", encoded.replace(envelope.sha256, "0".repeat(64)), "external_checksum_mismatch")
	_reject(directory, "duplicate-envelope", '{"version":1,' + encoded.substr(1), "external_noncanonical_json")
	_reject(directory, "duplicate-body", _wire('{"tick":0,' + expected_body.substr(1)), "external_noncanonical_json")
	_reject(directory, "deep-body", _wire("[".repeat(9) + "]".repeat(9)), "external_json_too_deep")
	_reject(directory, "deep-envelope", "[".repeat(9) + "]".repeat(9), "external_json_too_deep")
	_reject(directory, "oversized", " ".repeat(Codec.MAX_BYTES + 1), "external_file_too_large")
	var invalid_path := directory.path_join("utf8.pcopsave")
	var invalid := FileAccess.open(invalid_path, FileAccess.WRITE)
	invalid.store_buffer(PackedByteArray([255]))
	invalid.close()
	_check(Codec.read(invalid_path).get("error") == "external_invalid_utf8", "invalid UTF-8 rejected")

	var changed := public_payload.duplicate(true)
	changed.rules_digest = "0".repeat(64)
	_reject(directory, "rules", _wire(JSON.stringify(changed)), "external_rules_mismatch")
	changed = public_payload.duplicate(true)
	changed.tick = 12000
	changed.clock_ms = 1200000
	_reject(directory, "terminal", _wire(JSON.stringify(changed)), "checkpoint_terminal")
	changed = public_payload.duplicate(true)
	changed.source_digest = "0".repeat(64)
	var changed_path := directory.path_join("input-mismatch.pcopsave")
	var mismatch := FileAccess.open(changed_path, FileAccess.WRITE)
	mismatch.store_string(_wire(JSON.stringify(changed)))
	mismatch.close()
	var decoded := Codec.read(changed_path)
	_check(decoded.ok and Dev.begin_restore(decoded.payload).get("error") == "checkpoint_source_mismatch",
		"source mismatch rejects at candidate boundary without publishing")
	changed = public_payload.duplicate(true)
	changed.request.mode = "auto"
	_reject(directory, "unsupported-mode", _wire(JSON.stringify(changed)), "external_unsupported_request")
	changed = public_payload.duplicate(true)
	changed.campaign = {}
	_reject(directory, "campaign", _wire(JSON.stringify(changed)), "external_invalid_payload")
	changed = public_payload.duplicate(true)
	changed.commands = []
	var batch := []
	batch.resize(256)
	batch.fill({"kind": "stop"})
	for i in 65:
		changed.commands.append({"tick": i, "batch": batch})
	_reject(directory, "command-limit", _wire(JSON.stringify(changed)), "external_too_many_commands")

	for invalid_target in [Store.SLOT_PATH, original_slot, "relative.pcopsave", "C:/../out.pcopsave", "C:/CON.pcopsave", "//server/share/test.pcopsave"]:
		_check(Codec.write(packet, invalid_target).get("error") == "external_invalid_path", "unsupported destination %s" % invalid_target)
	_check(FileAccess.get_sha256(original_slot) == slot_hash, "no default slot write")
	_check(owner.capture_checkpoint().packet == before, "rejected reads do not change active owner")
	owner.close()

func _reopen(path: String) -> void:
	var imported := Codec.read(path)
	if not imported.ok:
		_check(false, "separate process external read: %s" % imported)
		return
	var restored := _complete(Dev.begin_restore(imported.payload))
	if not restored.get("ok", false):
		_check(false, "separate process external replay: %s" % restored)
		return
	var owner: RefCounted = restored.owner
	var frame: Dictionary = owner.publish().frame
	_check(frame.tick == 1251 and frame.clock_ms == 125100, "separate process resumes the exact clock")
	_check(owner.capture_checkpoint().packet == imported.payload, "separate process reproduces complete authority")
	_check(owner.advance().ok and owner.drain_events().events.any(func(event): return event.kind == "reinforcement_entered"),
		"separate process continues the pending command and unread event")
	owner.close()

func _migrate_copy(directory: String, previous: String) -> void:
	var sha := FileAccess.get_sha256(previous)
	var slot := Store.read(previous)
	if not slot.ok:
		_check(false, "previous slot readable: %s" % slot)
		return
	var restored := _complete(Dev.begin_restore(slot.payload))
	if not restored.get("ok", false):
		_check(false, "approved old internal slot resumes: %s" % restored)
		return
	var owner: RefCounted = restored.owner
	owner.publish()
	var current: Dictionary = owner.capture_checkpoint().packet
	var path := directory.path_join("from-previous.pcopsave")
	_check(Codec.write(current, path).ok, "explicit new export from restored previous slot")
	var checked := Codec.read(path)
	_check(checked.ok and checked.payload.state_digest == slot.payload.state_digest, "previous operation identity and authority preserved")
	_check(FileAccess.get_sha256(previous) == sha, "previous slot copy unchanged")
	owner.close()

func _complete(begun: Dictionary) -> Dictionary:
	if not begun.ok:
		return begun
	var result: Dictionary = begun.job.step(2500)
	while result.ok and not result.done:
		result = begun.job.step(2500)
	return result

func _wire(body: String, version := 1) -> String:
	return JSON.stringify({"format": "pc-first-operation-external", "version": version,
		"body": body, "sha256": body.sha256_text()}, "", true, true)

func _reject(directory: String, label: String, content: String, error: String) -> void:
	var path := directory.path_join(label + ".pcopsave")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(content)
	file.close()
	var rejected := Codec.read(path)
	_check(rejected.get("error") == error, "%s expected %s, got %s" % [label, error, rejected])

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failed = true
		push_error(message)
