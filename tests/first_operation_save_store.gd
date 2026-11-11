extends SceneTree

const Store := preload("res://scripts/first_operation_save_store.gd")
var checks := 0
var failed := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var path: String = args[1]
		var result := Store.write({"generation": 2 if args[0] == "locked" else 1}, path)
		if args[0] == "locked":
			expect(result.get("error") == "replace_failed" and result.path == path, "real Windows replacement denied")
			expect(Store.read(path).get("payload") == {"generation": 1.0}, "locked overwrite preserves previous save")
		else:
			expect(result.ok, "seed real Windows locked fixture")
		finish()
		return

	var slot := Store.SLOT_PATH
	var original := {"label": "격리 저장 🚀", "nested": [null, false, {"clock": 123456, "ratio": 0.25}]}
	expect(Store.read().get("error") == "file_not_found", "absent default slot")
	expect(Store.write(original).ok and Store.read().get("payload") == JSON.parse_string(JSON.stringify(original)), "default UTF-8 round trip")
	expect(Store.write({"generation": 2}).ok and Store.read().get("payload") == {"generation": 2.0}, "replace populated slot")
	expect(Store.read(slot + Store.PREVIOUS).get("payload") == JSON.parse_string(JSON.stringify(original)), "verified old generation")
	expect(Store.write({"value": Vector2.ZERO}).get("error") == "invalid_payload", "non-data payload rejected")
	expect(Store.write({3: "numeric key"}).get("error") == "invalid_payload", "numeric key rejected")
	expect(Store.write({"value": INF}).get("error") == "invalid_payload", "infinite number rejected")
	expect(Store.write({"value": 9007199254740992}).get("error") == "invalid_payload", "lossy integer rejected")
	expect(Store.write({"value": "a".repeat(Store.MAX_BYTES)}).get("error") == "file_too_large", "oversize write rejected")
	expect(Store.read().get("payload") == {"generation": 2.0}, "rejected writes preserve slot")

	# Simulate termination after writing the complete pending file, and in
	# the rotation gap. A pending name never becomes the committed generation.
	var pending := slot + ".pending-interrupted"
	expect(Store.write({"generation": 3}, pending).ok, "complete pending generation fixture")
	expect(Store.read().get("payload") == {"generation": 2.0}, "unpublished temporary file ignored")
	expect(DirAccess.rename_absolute(slot, slot + Store.PREVIOUS) == OK, "simulate slot rotation")
	expect(Store.read().get("payload") == {"generation": 2.0}, "recovery reads previous generation")
	var recovery_bytes := FileAccess.get_file_as_bytes(slot + Store.PREVIOUS)
	expect(Store.write({"generation": 4}).ok and Store.read().get("payload") == {"generation": 4.0}, "next save repairs rotation gap")
	expect(FileAccess.get_file_as_bytes(slot + Store.PREVIOUS) == recovery_bytes, "successful repair retains the recovered generation")

	var rotation := "user://rotation-gap.save"
	var previous := rotation + Store.PREVIOUS
	raw(previous, "{".to_utf8_buffer())
	var corrupt_bytes := FileAccess.get_file_as_bytes(previous)
	expect(Store.read(rotation).get("error") == "invalid_envelope", "read rejects corrupt recovery generation")
	expect(Store.write({"generation": 5}, rotation).get("error") == "invalid_envelope", "write rejects corrupt recovery generation")
	expect(not FileAccess.file_exists(rotation) and FileAccess.get_file_as_bytes(previous) == corrupt_bytes,
		"failed write preserves the corrupt recovery generation and leaves the main slot vacant")

	var old := {"format": Store.FORMAT, "version": 0, "sha256": "{}".sha256_text(), "body": "{}"}
	var old_bytes := JSON.stringify(old).to_utf8_buffer()
	raw(previous, old_bytes)
	var incompatible := Store.write({"generation": 5}, rotation)
	expect(incompatible.get("error") == "unsupported_version" and incompatible.get("path") == rotation,
		"write reports incompatible recovery generation at the main slot path")
	expect(not FileAccess.file_exists(rotation) and FileAccess.get_file_as_bytes(previous) == old_bytes,
		"failed write preserves the incompatible recovery generation and leaves the main slot vacant")


	var invalid := "user://invalid.save"
	raw(invalid, "{".to_utf8_buffer())
	expect(Store.read(invalid).get("error") == "invalid_envelope", "truncated file rejected")
	raw(invalid, PackedByteArray([255, 254, 65]))
	expect(Store.read(invalid).get("error") == "invalid_utf8", "malformed UTF-8 rejected")
	var envelope := {"format": Store.FORMAT, "version": 0, "sha256": "{}".sha256_text(), "body": "{}"}
	raw(invalid, JSON.stringify(envelope).to_utf8_buffer())
	expect(Store.read(invalid).get("error") == "unsupported_version", "old version rejected")
	expect(Store.write({}, invalid).get("error") == "unsupported_version", "old file preserved on overwrite")
	envelope.version = Store.VERSION
	envelope.body = "{\"modified\":true}"
	raw(invalid, JSON.stringify(envelope).to_utf8_buffer())
	expect(Store.read(invalid).get("error") == "checksum_mismatch", "modified body rejected")
	envelope.body = "[]"
	envelope.sha256 = "[]".sha256_text()
	raw(invalid, JSON.stringify(envelope).to_utf8_buffer())
	expect(Store.read(invalid).get("error") == "invalid_payload", "body must be a dictionary")
	raw(invalid, "{\"format\":\"legacy-packet\"}".to_utf8_buffer())
	expect(Store.read(invalid).get("error") == "invalid_envelope", "legacy format rejected")
	var large := PackedByteArray()
	large.resize(Store.MAX_BYTES + 1)
	raw(invalid, large)
	expect(Store.read(invalid).get("error") == "file_too_large", "size rejected before decode")
	raw(slot, "{".to_utf8_buffer())
	expect(Store.read().get("error") == "invalid_envelope", "present corrupt slot is reported even with backup")
	finish()

func raw(path: String, value: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(value)
	file.close()

func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("FAIL: ", label)

func finish() -> void:
	print("first_operation_save_store: %d/%d" % [checks - failed, checks])
	quit(0 if failed == 0 else 1)

