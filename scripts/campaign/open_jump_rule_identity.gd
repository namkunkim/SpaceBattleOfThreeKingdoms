extends RefCounted

const MANIFEST := "res://data/open_jump_runtime_fingerprint.json"
const ANCHOR := "res://data/operation_checkpoint_anchor.gd"
const LEGACY_F_RULES := "0d45277be3740ef859fc7b72c9148c295f182292f4d0326b017cd263b7e8a1e6"
const VERIFIED_CANONICAL_RULES := "45357d021c9ff20a599a8ceff2871b42c0367b2279379e79fdb3626a9f0a6294"

static func matches(saved: String, current_digest: String) -> bool:
	return not current_digest.is_empty() and (saved == current_digest or
		(saved == LEGACY_F_RULES and current_digest == VERIFIED_CANONICAL_RULES))

static func current() -> String:
	if OS.has_feature("template"):
		return packaged_digest()
	var paths: Array[String] = []
	_list_sources("res://core/battle", paths)
	_list_sources("res://core/campaign", paths)
	if paths.is_empty():
		return ""
	paths.sort()
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	for path in paths:
		var source := FileAccess.get_file_as_bytes(path)
		if source.is_empty():
			return ""
		var normalized := source.get_string_from_utf8()
		if normalized.to_utf8_buffer() != source:
			return ""
		context.update(path.to_utf8_buffer())
		context.update(normalized.replace("\r\n", "\n").to_utf8_buffer())
	return context.finish().hex_encode()

static func packaged_digest() -> String:
	if not FileAccess.file_exists(MANIFEST) or not ResourceLoader.exists(ANCHOR):
		return ""
	var text := FileAccess.get_file_as_string(MANIFEST)
	var anchor := load(ANCHOR) as Script
	if anchor == null or anchor.get_script_constant_map().get("OPEN_JUMP_SHA256") != text.sha256_text():
		return ""
	var data: Variant = JSON.parse_string(text)
	if not data is Dictionary or data.get("format") != "open-jump-runtime-fingerprint/1" \
			or not _digest(data.get("rules_sha256")) or not data.get("entries") is Dictionary \
			or data.entries.is_empty():
		return ""
	var version := Engine.get_version_info()
	var engine := "%d.%d.%d.%s.%s" % [version.major, version.minor, version.patch, version.status, str(version.hash).left(9)]
	if data.get("engine") != engine:
		return ""
	for name: String in data.entries:
		if not (name.begins_with("core/battle/") or name.begins_with("core/campaign/")) \
				or not name.ends_with(".gd") or name.contains(".."):
			return ""
		var path := "res://" + name
		var entry: Variant = data.entries[name]
		if not entry is Dictionary or not _digest(entry.get("token")) or not _digest(entry.get("remap")) \
				or (OS.has_feature("template") and FileAccess.file_exists(path)) or FileAccess.get_sha256(path + "c") != entry.token \
				or FileAccess.get_sha256(path + ".remap") != entry.remap:
			return ""
	return data.rules_sha256

static func _digest(value: Variant) -> bool:
	return value is String and value.length() == 64 and value.is_valid_hex_number() \
		and not value.begins_with("+") and not value.begins_with("-") and value == value.to_lower()

static func _list_sources(path: String, files: Array[String]) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".gd"):
			files.append(path.path_join(file))
	for folder in DirAccess.get_directories_at(path):
		_list_sources(path.path_join(folder), files)
