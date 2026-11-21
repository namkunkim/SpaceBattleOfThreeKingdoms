extends RefCounted

const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const CrossCounter := preload("res://scripts/cross_counter/public_slot.gd")
const External := preload("res://scripts/first_operation_external_save.gd")
const Runtime := preload("res://scripts/lantern_escort/runtime.gd")

const EXTENSION := ".pclanternsave"
const FORMAT := "lantern-escort-checkpoint/1"
const RULES_VERSION := "lantern-escort/1"
const MAX_PACKET_BYTES := 2 * 1024 * 1024
const MAX_ENCODED_BYTES := 4 * ((MAX_PACKET_BYTES + 2) / 3)
const MAX_FILE_BYTES := MAX_ENCODED_BYTES + 4096
const ACTIVE_FIELDS := ["parent_id", "parent_sha256", "operation_id", "packet"]
const BODY_FIELDS := ["parent_id", "parent_sha256", "operation_id", "rules_sha256", "checkpoint"]
const ENVELOPE_FIELDS := ["format", "body", "sha256"]


static func write(active: Dictionary, path: String) -> Dictionary:
	if not OS.has_feature("windows"):
		return _fail("lantern_external_unavailable", "platform")
	var target := External._windows_path(path, EXTENSION)
	if target.is_empty():
		return _fail("lantern_external_invalid_path", "path")
	var checked := _validate_active(active)
	if not checked.ok:
		return checked
	var packet := var_to_bytes(checked.active.packet)
	if packet.size() > MAX_PACKET_BYTES:
		return _fail("lantern_external_too_large", "checkpoint")
	var bytes := _envelope(_body(checked.active, Marshalls.raw_to_base64(packet))).to_utf8_buffer()
	return External._publish_new(target, bytes, true)


static func read(path: String) -> Dictionary:
	if not OS.has_feature("windows"):
		return _fail("lantern_external_unavailable", "platform")
	var source := External._windows_path(path, EXTENSION)
	if source.is_empty():
		return _fail("lantern_external_invalid_path", "path")
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		return _fail("lantern_external_read_failed", "file")
	var size := file.get_length()
	if size <= 0 or size > MAX_FILE_BYTES:
		return _fail("lantern_external_invalid_size", "file")
	var bytes := file.get_buffer(size)
	if bytes.size() != size or file.get_length() != size:
		return _fail("lantern_external_read_failed", "file")
	if not External._valid_utf8(bytes):
		return _fail("lantern_external_invalid_utf8", "file")
	var encoded := bytes.get_string_from_utf8()
	var parsed := External._parse(encoded, "file")
	if not parsed.ok:
		return parsed
	var envelope: Variant = parsed.value
	if not Runtime._has_fields(envelope, ENVELOPE_FIELDS) or envelope.format != FORMAT:
		return _fail("lantern_external_invalid_format", "file.format")
	if not envelope.body is String or not envelope.sha256 is String or envelope.sha256 != envelope.body.sha256_text():
		return _fail("lantern_external_checksum_mismatch", "file.sha256")
	if encoded.to_utf8_buffer() != bytes or encoded != _envelope(envelope.body):
		return _fail("lantern_external_noncanonical_json", "file")
	var inner := External._parse(envelope.body, "file.body")
	if not inner.ok:
		return inner
	return _decode_body(inner.value, envelope.body)


static func rules_sha256() -> String:
	return Checkpoint.digest_value([RULES_VERSION, Runtime.definition()])


static func _decode_body(body: Variant, encoded: String) -> Dictionary:
	if not Runtime._has_fields(body, BODY_FIELDS):
		return _fail("lantern_external_invalid_payload", "file.body")
	if not body.rules_sha256 is String or body.rules_sha256 != rules_sha256():
		return _fail("lantern_external_rules_mismatch", "file.body.rules_sha256")
	if not body.checkpoint is String or not _base64_shape(body.checkpoint):
		return _fail("lantern_external_invalid_checkpoint", "file.body.checkpoint")
	var bytes := Marshalls.base64_to_raw(body.checkpoint)
	if bytes.is_empty() or bytes.size() > MAX_PACKET_BYTES or Marshalls.raw_to_base64(bytes) != body.checkpoint:
		return _fail("lantern_external_invalid_checkpoint", "file.body.checkpoint")
	# The typed Variant checkpoint is decoded with object construction disabled.
	var packet: Variant = bytes_to_var(bytes)
	var checked := _validate_active({"parent_id": body.parent_id, "parent_sha256": body.parent_sha256,
		"operation_id": body.operation_id, "packet": packet})
	if not checked.ok:
		return checked
	if var_to_bytes(checked.active.packet) != bytes or encoded != _body(checked.active, body.checkpoint):
		return _fail("lantern_external_noncanonical_payload", "file.body")
	return checked


static func _base64_shape(value: String) -> bool:
	var length := value.length()
	if length == 0 or length > MAX_ENCODED_BYTES or length % 4 != 0:
		return false
	var end := length
	if value.ends_with("="):
		end -= 2 if value.ends_with("==") else 1
	var bytes := value.to_utf8_buffer()
	if bytes.size() != length:
		return false
	for index in end:
		var code := bytes[index]
		if not ((code >= 65 and code <= 90) or (code >= 97 and code <= 122) \
				or (code >= 48 and code <= 57) or code == 43 or code == 47):
			return false
	return true


static func _validate_active(active: Dictionary) -> Dictionary:
	if not Runtime._has_fields(active, ACTIVE_FIELDS):
		return _fail("lantern_external_invalid_payload", "checkpoint")
	var parent: Variant = active.parent_id
	if not parent is String or not parent.begins_with(CrossCounter.OPERATION_PREFIX) or not parent.ends_with("/settlement") \
			or not Runtime._hex(parent.trim_prefix(CrossCounter.OPERATION_PREFIX).trim_suffix("/settlement"), 32) \
			or not Runtime._hex(active.parent_sha256, 64) or not Runtime._valid_id(active.operation_id):
		return _fail("lantern_external_invalid_identity", "checkpoint")
	var packet: Variant = active.packet
	if not Runtime._has_fields(packet, Runtime.PACKET_FIELDS) or packet.operation_id != active.operation_id \
			or not packet.settlement is Dictionary or not packet.settlement.is_empty():
		return _fail("lantern_external_invalid_checkpoint", "checkpoint")
	var restored := Runtime.restore(packet)
	if not restored.ok:
		return _fail(restored.error, "checkpoint")
	var canonical := active.duplicate()
	canonical.packet = restored.runtime.capture()
	return {"ok": true, "active": canonical}


static func _body(active: Dictionary, checkpoint: String) -> String:
	return JSON.stringify({"parent_id": active.parent_id, "parent_sha256": active.parent_sha256,
		"operation_id": active.operation_id, "rules_sha256": rules_sha256(), "checkpoint": checkpoint}, "", true, true)


static func _envelope(body: String) -> String:
	return JSON.stringify({"format": FORMAT, "body": body, "sha256": body.sha256_text()}, "", true, true)


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
