extends RefCounted

const FileRules := preload("res://scripts/first_operation_external_save.gd")
const V1Replay := preload("res://scripts/first_operation_replay_codec.gd")
const Owner := preload("res://scripts/first_operation_v2_owner.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

const SAVE_FORMAT := "red-cliffs-v2-checkpoint"
const REPLAY_FORMAT := "red-cliffs-v2-replay"
const SAVE_EXTENSION := ".pcop2save"
const REPLAY_EXTENSION := ".pcop2replay"
const SLOT_PATH := "user://red-cliffs-v2.pcop2save"
const VERSION := 1
const MAX_BYTES := 1024 * 1024
const MAX_TICKS := 12000
const TICK_MS := 100
const MAX_BATCH := 256
const KINDS := ["move", "stop", "withdraw", "finalize_withdrawal", "formation"]
const SETTLEMENT_KINDS := ["objective_success", "withdrawal_success", "failure"]


static func encode(record: Variant, format: String) -> Dictionary:
	var normalized := normalize(record, format)
	if not normalized.ok:
		return normalized
	var rules := rules_digest()
	if rules.is_empty():
		return _fail("v2_rules_unavailable", "rules_digest")
	var body := JSON.stringify(normalized.record, "", true, true)
	var bytes := _envelope(format, body, rules).to_utf8_buffer()
	return {"ok": true, "bytes": bytes} if bytes.size() <= MAX_BYTES else _fail("v2_file_too_large", "file")


static func decode(bytes: PackedByteArray, format: String) -> Dictionary:
	if bytes.size() > MAX_BYTES:
		return _fail("v2_file_too_large", "file")
	if not FileRules._valid_utf8(bytes):
		return _fail("v2_invalid_utf8", "file")
	var text := bytes.get_string_from_utf8()
	var parsed := FileRules._parse(text, "file")
	if not parsed.ok:
		return parsed
	var value: Variant = parsed.value
	if not FileRules._has_fields(value, ["format", "version", "body", "sha256", "rules_digest"]) \
			or value.format != format or value.version != VERSION or not value.body is String:
		return _fail("v2_invalid_envelope", "file")
	if value.sha256 != value.body.sha256_text():
		return _fail("v2_checksum_mismatch", "file.sha256")
	var rules := rules_digest()
	if rules.is_empty() or value.rules_digest != rules:
		return _fail("v2_rules_mismatch", "file.rules_digest")
	if text != _envelope(format, value.body, rules):
		return _fail("v2_noncanonical_envelope", "file")
	parsed = FileRules._parse(value.body, "file.body")
	if not parsed.ok:
		return parsed
	var normalized := normalize(parsed.value, format)
	if normalized.ok and JSON.stringify(normalized.record, "", true, true) != value.body:
		return _fail("v2_noncanonical_body", "file.body")
	return normalized


## Validation here establishes the wire contract. A restore job must independently
## replay and compare the committed state witness before publishing an owner.
static func normalize(value: Variant, format: String) -> Dictionary:
	if format not in [SAVE_FORMAT, REPLAY_FORMAT] or not FileRules._has_fields(value,
			["capability", "operation_id", "tick", "clock_ms", "history", "pending", "state_digest", "settlement"]):
		return _fail("v2_invalid_record", "record")
	if value.capability != Owner.CAPABILITY or not _identity(value.operation_id):
		return _fail("v2_invalid_identity", "record.operation_id")
	if not _integer(value.tick, 0, MAX_TICKS) or not _integer(value.clock_ms, 0, MAX_TICKS * TICK_MS) \
			or value.clock_ms != int(value.tick) * TICK_MS:
		return _fail("v2_invalid_clock", "record.tick")
	if not _sha256(value.state_digest):
		return _fail("v2_invalid_witness", "record.state_digest")
	if not value.history is Array or value.history.size() > MAX_TICKS:
		return _fail("v2_invalid_history", "record.history")
	var history := []
	var previous := -1
	for entry in value.history:
		if not FileRules._has_fields(entry, ["tick", "batch"]) \
				or not _integer(entry.tick, previous + 1, int(value.tick) - 1):
			return _fail("v2_invalid_history_tick", "record.history")
		var batch := _batch(entry.batch)
		if not batch.ok or batch.value.is_empty():
			return _fail("v2_invalid_history_batch", "record.history")
		previous = int(entry.tick)
		history.append({"tick": previous, "batch": batch.value})
	var pending := _batch(value.pending)
	if not pending.ok:
		return _fail("v2_invalid_pending", "record.pending")
	var settlement := {}
	if format == SAVE_FORMAT:
		if not value.settlement is Dictionary or not value.settlement.is_empty():
			return _fail("v2_save_already_settled", "record.settlement")
	else:
		if not pending.value.is_empty() or not _valid_settlement(value):
			return _fail("v2_invalid_settlement", "record.settlement")
		settlement = value.settlement.duplicate()
		settlement.tick = int(value.tick)
		settlement.clock_ms = int(value.clock_ms)
	return {"ok": true, "record": {"capability": Owner.CAPABILITY, "operation_id": value.operation_id,
		"tick": int(value.tick), "clock_ms": int(value.clock_ms), "history": history,
		"pending": pending.value, "state_digest": value.state_digest, "settlement": settlement}}


static func _batch(entries: Variant) -> Dictionary:
	if not entries is Array or entries.size() > MAX_BATCH:
		return _fail("v2_invalid_batch", "batch")
	var normalized := []
	for command in entries:
		if not command is Dictionary or command.get("kind") not in KINDS:
			return _fail("v2_invalid_command", "batch")
		match command.kind:
			"formation":
				if entries.size() != 1 or command != Owner.FORMATION:
					return _fail("v2_invalid_formation", "batch")
				normalized.append(Owner.FORMATION.duplicate())
			"move":
				if not FileRules._has_fields(command, ["kind", "waypoint"]) or not _integer(command.waypoint, 1, 3):
					return _fail("v2_invalid_move", "batch")
				normalized.append({"kind": "move", "waypoint": int(command.waypoint)})
			_:
				if command.size() != 1:
					return _fail("v2_invalid_command", "batch")
				normalized.append({"kind": command.kind})
	return {"ok": true, "value": normalized}


static func _valid_settlement(record: Dictionary) -> bool:
	var value: Variant = record.settlement
	return FileRules._has_fields(value, ["id", "operation_id", "kind", "reason", "tick", "clock_ms"]) \
		and value.operation_id == record.operation_id and value.id == record.operation_id + "/settlement" \
		and value.kind in SETTLEMENT_KINDS and value.reason is String and not value.reason.is_empty() \
		and _integer(value.tick, int(record.tick), int(record.tick)) \
		and _integer(value.clock_ms, int(record.clock_ms), int(record.clock_ms))


static func _identity(value: Variant) -> bool:
	return value is String and value.begins_with(Owner.ID_PREFIX) \
		and _hex(value.substr(Owner.ID_PREFIX.length()), 32)


static func _sha256(value: Variant) -> bool:
	return value is String and _hex(value, 64)


static func _hex(value: String, length: int) -> bool:
	if value.length() != length:
		return false
	for digit in value:
		if digit not in "0123456789abcdef":
			return false
	return true


static func _integer(value: Variant, lower: int, upper: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and value >= lower and value <= upper and floor(value) == value


static func rules_digest() -> String:
	var native := V1Replay._rules_and_inputs_digest()
	# This versioned behavior tag must change when the outer command semantics change.
	return Checkpoint.digest_value([Owner.CAPABILITY, "sq01-frm03-to-frm01/1", native]) if not native.is_empty() else ""


static func _envelope(format: String, body: String, rules: String) -> String:
	return JSON.stringify({"format": format, "version": VERSION, "body": body,
		"sha256": body.sha256_text(), "rules_digest": rules}, "", true, true)


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
