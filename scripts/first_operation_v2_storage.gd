extends RefCounted

const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const Files := preload("res://scripts/first_operation_external_save.gd")
const Restore := preload("res://scripts/first_operation_v2_restore.gd")
const WindowsSlot := preload("res://scripts/o07_windows_slot.gd")


static func available() -> bool:
	return OS.has_feature("windows") and ClassDB.class_exists(WindowsSlot.NATIVE)


static func has_save() -> bool:
	return FileAccess.file_exists(Codec.SLOT_PATH)


static func begin_slot_restore() -> Dictionary:
	if not available():
		return _fail("v2_storage_unavailable", Codec.SLOT_PATH)
	var raw := WindowsSlot.with_lock(Codec.SLOT_PATH, _read.bind(Codec.SLOT_PATH))
	return Restore.begin_restore(raw.bytes) if raw.ok else raw


static func save_slot(record: Dictionary) -> Dictionary:
	if not available():
		return _fail("v2_storage_unavailable", Codec.SLOT_PATH)
	var encoded := Codec.encode(record, Codec.SAVE_FORMAT)
	if not encoded.ok:
		return encoded
	return WindowsSlot.with_lock(Codec.SLOT_PATH, _replace_slot.bind(encoded.bytes))


static func export_replay(record: Dictionary, path: String) -> Dictionary:
	var target := _external_path(path, Codec.REPLAY_EXTENSION)
	if not available() or target.is_empty():
		return _fail("v2_replay_invalid_path", "path")
	var encoded := Codec.encode(record, Codec.REPLAY_FORMAT)
	return Files._publish_new(target, encoded.bytes, true) if encoded.ok else encoded


static func read_replay(path: String) -> Dictionary:
	var source := _external_path(path, Codec.REPLAY_EXTENSION)
	return _read(source) if not source.is_empty() else _fail("v2_replay_invalid_path", "path")


static func _external_path(path: String, extension: String) -> String:
	if not path.to_lower().ends_with(extension):
		return ""
	var base := path.left(path.length() - extension.length())
	if Files._windows_path(base + Files.EXTENSION).is_empty():
		return ""
	return path.replace("\\", "/")


static func _replace_slot(bytes: PackedByteArray) -> Dictionary:
	var path := Codec.SLOT_PATH
	var staged := path + ".pending-" + Crypto.new().generate_random_bytes(16).hex_encode()
	var file := FileAccess.open(staged, FileAccess.WRITE)
	if file == null:
		return _fail("v2_write_failed", path)
	file.store_buffer(bytes)
	file.flush()
	var status := file.get_error()
	file.close()
	var verified := _read(staged)
	var result := _fail("v2_write_failed", path)
	if status == OK and verified.ok and verified.bytes == bytes:
		result = WindowsSlot.publish(staged, path, FileAccess.file_exists(path))
	if not result.ok:
		DirAccess.remove_absolute(staged)
	return result


static func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("v2_read_failed", path)
	var length := file.get_length()
	if length > Codec.MAX_BYTES:
		return _fail("v2_file_too_large", path)
	var bytes := file.get_buffer(length)
	if bytes.size() != length or file.get_length() != length:
		return _fail("v2_read_failed", path)
	return {"ok": true, "bytes": bytes}


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
