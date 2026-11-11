extends RefCounted

const SLOT_PATH := "user://pc-first-operation-dev.save"
const FORMAT := "pc-first-operation-save"
const VERSION := 1
const MAX_BYTES := 8 * 1024 * 1024
const MAX_DEPTH := 64
const MAX_JSON_INT := 9007199254740991
const PREVIOUS := ".previous"

static var _mutex := Mutex.new()


static func write(payload: Dictionary, path: String = SLOT_PATH, publisher := Callable()) -> Dictionary:
	if not _json_data(payload, 0):
		return _fail("invalid_payload", path)
	var body := JSON.stringify(payload, "", true, true)
	var envelope := {"format": FORMAT, "version": VERSION, "sha256": body.sha256_text(), "body": body}
	var bytes := JSON.stringify(envelope).to_utf8_buffer()
	if bytes.size() > MAX_BYTES:
		return _fail("file_too_large", path)
	_mutex.lock()
	var result := _write(bytes, path, publisher)
	_mutex.unlock()
	return result


static func read(path: String = SLOT_PATH) -> Dictionary:
	_mutex.lock()
	var result := _read_file(path)
	# A missing slot can be the gap between moving the old generation aside
	# and publishing the new one. A present invalid slot is reported as such.
	if result.get("error") == "file_not_found":
		result = _read_previous(path)
	_mutex.unlock()
	return result


static func _write(bytes: PackedByteArray, path: String, publisher: Callable) -> Dictionary:
	var existing := _read_file(path)
	if not existing.ok:
		if existing.error != "file_not_found":
			return existing
		# During interrupted rotation the previous file is the committed slot.
		var previous := _read_previous(path)
		if not previous.ok and previous.error != "file_not_found":
			return previous
	if DirAccess.dir_exists_absolute(path):
		return _fail("replace_failed", path)
	var temporary := "%s.pending-%s" % [path, Crypto.new().generate_random_bytes(16).hex_encode()]
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("write_failed", path)
	file.store_buffer(bytes)
	file.flush()
	var status := file.get_error()
	file.close()
	var result: Dictionary
	if status != OK:
		result = _fail("write_failed", path)
	elif not _read_file(temporary).ok:
		result = _fail("verify_failed", path)
	elif publisher.is_valid():
		result = publisher.call(temporary, path, existing.ok)
		if result.ok:
			return result
	# Windows DirAccess replacement may delete the destination first. Keep the
	# verified live file until it can be moved to its recovery name, and publish
	# the new file by renaming to the now vacant slot in the same directory.
	elif existing.ok and DirAccess.rename_absolute(path, path + PREVIOUS) != OK:
		result = _fail("replace_failed", path)
	elif DirAccess.rename_absolute(temporary, path) != OK:
		result = _fail("replace_failed", path)
	else:
		return {"ok": true}
	DirAccess.remove_absolute(temporary)
	return result


static func _read_previous(path: String) -> Dictionary:
	var result := _read_file(path + PREVIOUS)
	if not result.ok:
		result.path = path
	return result


static func _read_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		if not FileAccess.file_exists(path) and not DirAccess.dir_exists_absolute(path):
			return _fail("file_not_found", path)
		return _fail("read_failed", path)
	var size := file.get_length()
	if size > MAX_BYTES:
		return _fail("file_too_large", path)
	var bytes := file.get_buffer(size)
	if bytes.size() != size or file.get_length() != size:
		return _fail("read_failed", path)
	var source := bytes.get_string_from_utf8()
	if source.to_utf8_buffer() != bytes:
		return _fail("invalid_utf8", path)
	var parser := JSON.new()
	if parser.parse(source) != OK:
		return _fail("invalid_envelope", path)
	var envelope: Variant = parser.data
	if not envelope is Dictionary or envelope.get("format") != FORMAT or envelope.size() != 4:
		return _fail("invalid_envelope", path)
	var version: Variant = envelope.get("version")
	if typeof(version) not in [TYPE_FLOAT, TYPE_INT] or version != VERSION:
		return _fail("unsupported_version", path)
	var body: Variant = envelope.get("body")
	var checksum: Variant = envelope.get("sha256")
	if not body is String or not checksum is String:
		return _fail("invalid_envelope", path)
	if body.sha256_text() != checksum:
		return _fail("checksum_mismatch", path)
	if parser.parse(body) != OK:
		return _fail("invalid_payload", path)
	var payload: Variant = parser.data
	if not payload is Dictionary or not _json_data(payload, 0):
		return _fail("invalid_payload", path)
	return {"ok": true, "payload": payload}


static func _json_data(value: Variant, depth: int) -> bool:
	if depth > MAX_DEPTH:
		return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING:
			return true
		TYPE_INT:
			return value >= -MAX_JSON_INT and value <= MAX_JSON_INT
		TYPE_FLOAT:
			return is_finite(value)
		TYPE_ARRAY:
			for item: Variant in value:
				if not _json_data(item, depth + 1):
					return false
			return true
		TYPE_DICTIONARY:
			for key: Variant in value:
				if not key is String or not _json_data(value[key], depth + 1):
					return false
			return true
	return false


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}

