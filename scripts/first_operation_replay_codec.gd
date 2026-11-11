extends RefCounted

const FileRules := preload("res://scripts/first_operation_external_save.gd")
const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const Dev := preload("res://core/battle/first_operation_dev.gd")
const EXTENSION := ".pcopreplay"
const FORMAT := "pc-first-operation-replay"
const RUN_FORMAT := "pc-first-operation-run/1"
const VERSION := 1
const MAX_BYTES := 1024 * 1024

static var _write_lock := Mutex.new()


static func write(bundle: Dictionary, path: String) -> Dictionary:
	var target := _path(path)
	if target.is_empty():
		return _fail("replay_invalid_path", "path")
	var normalized := _normalize(bundle)
	if not normalized.ok:
		return normalized
	var body := JSON.stringify(normalized.bundle, "", true, true)
	var rules := _rules_and_inputs_digest()
	if rules.is_empty():
		return _fail("replay_rules_unavailable", "file.rules_digest")
	var bytes := _envelope(body, rules).to_utf8_buffer()
	if bytes.size() > MAX_BYTES:
		return _fail("replay_file_too_large", "file")
	_write_lock.lock()
	var result := FileRules._publish_new(target, bytes)
	_write_lock.unlock()
	if not result.ok:
		return _fail(result.error.replace("external_", "replay_"), result.path)
	return result


static func read(path: String) -> Dictionary:
	var source := _path(path)
	if source.is_empty():
		return _fail("replay_invalid_path", "path")
	var file := FileAccess.open(source, FileAccess.READ)
	if file == null:
		return _fail("replay_read_failed", "file")
	var size := file.get_length()
	if size > MAX_BYTES:
		return _fail("replay_file_too_large", "file")
	var bytes := file.get_buffer(size)
	if bytes.size() != size or file.get_length() != size:
		return _fail("replay_read_failed", "file")
	if not FileRules._valid_utf8(bytes):
		return _fail("replay_invalid_utf8", "file")
	var encoded := bytes.get_string_from_utf8()
	var parsed := FileRules._parse(encoded, "file")
	if not parsed.ok:
		return _fail(parsed.error.replace("external_", "replay_"), parsed.path)
	var envelope: Variant = parsed.value
	if not FileRules._has_fields(envelope, ["format", "version", "body", "sha256", "rules_digest"]) or envelope.format != FORMAT:
		return _fail("replay_invalid_format", "file.format")
	if typeof(envelope.version) not in [TYPE_INT, TYPE_FLOAT] or envelope.version != VERSION:
		return _fail("replay_unsupported_version", "file.version")
	if not envelope.body is String or not envelope.sha256 is String:
		return _fail("replay_invalid_format", "file")
	if envelope.body.sha256_text() != envelope.sha256:
		return _fail("replay_checksum_mismatch", "file.sha256")
	var rules := _rules_and_inputs_digest()
	if rules.is_empty() or envelope.rules_digest != rules:
		return _fail("replay_rules_mismatch", "file.rules_digest")
	if encoded != _envelope(envelope.body, rules):
		return _fail("replay_noncanonical_json", "file")
	parsed = FileRules._parse(envelope.body, "file.body")
	if not parsed.ok:
		return _fail(parsed.error.replace("external_", "replay_"), parsed.path)
	var normalized := _normalize(parsed.value)
	if not normalized.ok:
		return normalized
	if envelope.body != JSON.stringify(normalized.bundle, "", true, true):
		return _fail("replay_noncanonical_json", "file.body")
	return normalized


static func _normalize(bundle: Variant) -> Dictionary:
	if not bundle is Dictionary or bundle.get("format") != RUN_FORMAT:
		return _fail("replay_invalid_bundle", "bundle")
	if not bundle.has("operation_id") or not bundle.has("expected_settlement"):
		return _fail("replay_missing_settlement", "bundle.expected_settlement")
	return Adapter.normalize(bundle)


static func _path(path: String) -> String:
	if not path.to_lower().ends_with(EXTENSION):
		return ""
	# Share the external Windows path policy without sharing its file format.
	var base := path.left(path.length() - EXTENSION.length())
	if FileRules._windows_path(base + FileRules.EXTENSION).is_empty():
		return ""
	return path.replace("\\", "/")


static func _rules_and_inputs_digest() -> String:
	var code := Checkpoint.rules_digest()
	if code.is_empty():
		return ""
	var paths: Array = Dev.INPUT_PATHS.values() + [Dev.DEFINITION_PATH]
	paths.sort()
	var inventory: Array = [code]
	for path: String in paths:
		var hash := FileAccess.get_sha256(path)
		if hash.is_empty():
			return ""
		inventory.append([path, hash])
	return Checkpoint.digest_value(inventory)



static func _packaged_rules_digest() -> String:
	return Checkpoint._packaged_rules_digest()


static func _envelope(body: String, rules: String) -> String:
	return JSON.stringify({"format": FORMAT, "version": VERSION, "body": body,
		"sha256": body.sha256_text(), "rules_digest": rules}, "", true, true)


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}

