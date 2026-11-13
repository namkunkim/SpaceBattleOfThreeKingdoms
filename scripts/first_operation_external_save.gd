extends RefCounted

const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const WindowsSlot := preload("res://scripts/o07_windows_slot.gd")

const EXTENSION := ".pcopsave"
const FORMAT := "pc-first-operation-external"
const VERSION := 1
const MAX_BYTES := 1024 * 1024
const MAX_DEPTH := 8
const MAX_COMMANDS := 16384
const DEFINITION_ID := "red-cliffs-first-operation-dev-v1"
const ENVELOPE_FIELDS := ["format", "version", "sha256", "body"]
const PAYLOAD_FIELDS := ["request", "operation_id", "rules_digest", "source_digest", "effective_digest",
	"tick", "clock_ms", "commands", "pending", "event_cursor", "proposal_serial", "state_digest"]
const REQUEST := {
	"capability": "pc/first-operation-dev/1", "definition_id": DEFINITION_ID,
	"definition_version": 1, "roster_id": "red-cliffs-dev-roster-v1",
	"seed": 208, "difficulty": "standard", "mode": "direct",
}

static var _write_lock := Mutex.new()

static func write(packet: Dictionary, path: String, product := false) -> Dictionary:
	if product and not OS.has_feature("windows"):
		return _fail("external_save_unavailable", "platform")
	var target := _windows_path(path)
	if target.is_empty():
		return _fail("external_invalid_path", "path")
	if not _has_fields(packet, PAYLOAD_FIELDS + ["format"]):
		return _fail("external_invalid_payload", "packet")
	var normalized := _validate(packet, product)
	if not normalized.ok:
		return normalized
	var body := _body(normalized.payload)
	var bytes := _envelope(body).to_utf8_buffer()
	if bytes.size() > MAX_BYTES:
		return _fail("external_file_too_large", "file")
	_write_lock.lock()
	var written := _publish_new(target, bytes, product)
	_write_lock.unlock()
	return written

static func read(path: String, product := false) -> Dictionary:
	if product and not OS.has_feature("windows"):
		return _fail("external_save_unavailable", "platform")
	var source := _windows_path(path)
	if source.is_empty():
		return _fail("external_invalid_path", "path")
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		return _fail("external_read_failed", "file")
	var size := file.get_length()
	if size > MAX_BYTES:
		return _fail("external_file_too_large", "file")
	var bytes := file.get_buffer(size)
	if bytes.size() != size or file.get_length() != size:
		return _fail("external_read_failed", "file")
	if not _valid_utf8(bytes):
		return _fail("external_invalid_utf8", "file")
	if bytes.size() >= 3 and bytes[0] == 0xef and bytes[1] == 0xbb and bytes[2] == 0xbf:
		return _fail("external_noncanonical_json", "file")
	var encoded := bytes.get_string_from_utf8()
	var outer := _parse(encoded, "file")
	if not outer.ok:
		return outer
	var envelope: Variant = outer.value
	if not _has_fields(envelope, ENVELOPE_FIELDS) or envelope.format != FORMAT:
		return _fail("external_invalid_format", "file.format")
	if typeof(envelope.version) not in [TYPE_INT, TYPE_FLOAT] or envelope.version != VERSION:
		return _fail("external_unsupported_version", "file.version")
	if not envelope.body is String or not envelope.sha256 is String:
		return _fail("external_invalid_envelope", "file")
	if envelope.sha256 != envelope.body.sha256_text():
		return _fail("external_checksum_mismatch", "file.sha256")
	if encoded != _envelope(envelope.body):
		return _fail("external_noncanonical_json", "file")
	var parsed := _parse(envelope.body, "file.body")
	if not parsed.ok:
		return parsed
	if not _has_fields(parsed.value, PAYLOAD_FIELDS):
		return _fail("external_invalid_payload", "file.body")
	var packet: Dictionary = parsed.value
	packet.format = Checkpoint.FORMAT
	var validated := _validate(packet, product)
	if not validated.ok:
		return validated
	if envelope.body != _body(validated.payload):
		return _fail("external_noncanonical_json", "file.body")
	return validated

static func _validate(packet: Dictionary, product: bool) -> Dictionary:
	# Bound total work before the internal validator walks every command.
	if not packet.commands is Array or not packet.pending is Array or packet.commands.size() > Checkpoint.MAX_TICKS:
		return _fail("external_invalid_commands", "packet.commands")
	var count: int = packet.pending.size()
	for row in packet.commands:
		if not row is Dictionary or not row.get("batch") is Array:
			return _fail("external_invalid_commands", "packet.commands")
		count += row.batch.size()
		if count > MAX_COMMANDS:
			return _fail("external_too_many_commands", "packet.commands")
	var checked := Checkpoint._normalize(packet, DEFINITION_ID)
	if not checked.ok:
		return checked
	var normalized: Dictionary = checked.packet
	var expected := Product.REQUEST if product else REQUEST
	for key in expected:
		if normalized.request[key] != expected[key]:
			return _fail("external_unsupported_request", "packet.request." + key)
	var routes := [Product.ROUTE] if product else ["front", "flank"]
	if normalized.request.route_id not in routes:
		return _fail("external_unsupported_request", "packet.request.route_id")
	if normalized.rules_digest != Checkpoint.rules_digest():
		return _fail("external_rules_mismatch", "packet.rules_digest")
	return {"ok": true, "payload": normalized}

static func _body(packet: Dictionary) -> String:
	var public := {}
	for key in PAYLOAD_FIELDS:
		public[key] = packet[key]
	return JSON.stringify(public, "", true, true)

static func _envelope(body: String) -> String:
	return JSON.stringify({"format": FORMAT, "version": VERSION, "sha256": body.sha256_text(), "body": body}, "", true, true)

# Bound nesting before Godot parses. Canonical re-encoding after validation
# also rejects duplicate keys, whitespace variants and parser extensions.
static func _parse(encoded: String, path: String) -> Dictionary:
	var depth := 0
	var quoted := false
	var escaped := false
	for code in encoded.to_utf8_buffer():
		if quoted:
			if escaped:
				escaped = false
			elif code == 92:
				escaped = true
			elif code == 34:
				quoted = false
		elif code == 34:
			quoted = true
		elif code == 91 or code == 123:
			depth += 1
			if depth > MAX_DEPTH:
				return _fail("external_json_too_deep", path)
		elif code == 93 or code == 125:
			depth -= 1
			if depth < 0:
				return _fail("external_invalid_json", path)
	if depth != 0 or quoted:
		return _fail("external_invalid_json", path)
	var parser := JSON.new()
	if parser.parse(encoded) != OK:
		return _fail("external_invalid_json", path)
	return {"ok": true, "value": parser.data}

static func _valid_utf8(bytes: PackedByteArray) -> bool:
	var index := 0
	while index < bytes.size():
		var lead := int(bytes[index])
		if lead < 0x80:
			index += 1
			continue
		if lead < 0xc2 or lead > 0xf4:
			return false
		var width := 2 if lead < 0xe0 else (3 if lead < 0xf0 else 4)
		if index + width > bytes.size():
			return false
		var second := int(bytes[index + 1])
		if (lead == 0xe0 and second < 0xa0) or (lead == 0xed and second > 0x9f):
			return false
		if (lead == 0xf0 and second < 0x90) or (lead == 0xf4 and second > 0x8f):
			return false
		for offset in range(1, width):
			if (bytes[index + offset] & 0xc0) != 0x80:
				return false
		index += width
	return true

static func _publish_new(path: String, bytes: PackedByteArray, product := false) -> Dictionary:
	if product and not ClassDB.class_exists(WindowsSlot.NATIVE):
		return _fail("external_save_unavailable", "publisher")
	if FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		return _fail("external_path_exists", "path")
	var temporary := path + ".pending-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("external_write_failed", "file")
	file.store_buffer(bytes)
	file.flush()
	var status := file.get_error()
	file.close()
	var result: Dictionary
	if status != OK or FileAccess.get_file_as_bytes(temporary) != bytes:
		result = _fail("external_write_failed", "file")
	elif FileAccess.file_exists(path) or DirAccess.dir_exists_absolute(path):
		result = _fail("external_path_exists", "path")
	elif product:
		# The Windows publisher with existing=false cannot replace a target
		# created by a different process after the existence checks.
		if WindowsSlot.publish(temporary, path, false).ok:
			return {"ok": true}
		result = _fail("external_publish_failed", "file")
	elif DirAccess.rename_absolute(temporary, path) != OK:
		result = _fail("external_publish_failed", "file")
	else:
		return {"ok": true}
	DirAccess.remove_absolute(temporary)
	return result

static func _windows_path(path: String) -> String:
	var normalized := path.replace("\\", "/")
	if normalized.length() < 4 or not normalized.substr(0, 1).to_upper() in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		return ""
	if normalized.substr(1, 2) != ":/" or not normalized.to_lower().ends_with(EXTENSION):
		return ""
	var reserved := ["CON", "PRN", "AUX", "NUL", "CONIN$", "CONOUT$"]
	for segment in normalized.substr(3).split("/"):
		if segment.is_empty() or segment.ends_with(".") or segment.ends_with(" "):
			return ""
		var stem := segment.get_slice(".", 0).strip_edges().to_upper()
		if stem in reserved or (stem.length() == 4 and stem.left(3) in ["COM", "LPT"] and stem.right(1) in "0123456789¹²³"):
			return ""
		for code in segment.to_utf8_buffer():
			if code < 32 or code in [34, 42, 58, 60, 62, 63, 124]:
				return ""
	return normalized

static func _has_fields(value: Variant, fields: Array) -> bool:
	return value is Dictionary and value.size() == fields.size() and fields.all(func(key): return value.has(key))

static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
