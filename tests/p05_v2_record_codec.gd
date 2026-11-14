extends SceneTree

const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const Owner := preload("res://scripts/first_operation_v2_owner.gd")
const V1 := preload("res://scripts/first_operation_replay_codec.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")

var tests := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var id := Owner.ID_PREFIX + "a".repeat(32)
	var save := {"capability": Owner.CAPABILITY, "operation_id": id, "tick": 12, "clock_ms": 1200,
		"history": [{"tick": 0, "batch": [{"kind": "stop"}]}, {"tick": 1, "batch": [Owner.FORMATION]}],
		"pending": [], "state_digest": "b".repeat(64), "settlement": {}}
	var saved := Codec.encode(save, Codec.SAVE_FORMAT)
	if not _check(saved.ok, "encode v2 save"):
		quit(1)
		return
	_check(Codec.decode(saved.bytes, Codec.SAVE_FORMAT).record == save, "exact v2 round trip")
	_check(not Codec.decode(saved.bytes, Codec.REPLAY_FORMAT).ok, "save rejected by replay codec")
	_check(not Codec.decode((saved.bytes.get_string_from_utf8() + "\n").to_utf8_buffer(), Codec.SAVE_FORMAT).ok,
		"noncanonical envelope denied")
	var envelope: Dictionary = JSON.parse_string(saved.bytes.get_string_from_utf8())
	envelope.body += " "
	_check(not Codec.decode(JSON.stringify(envelope, "", true, true).to_utf8_buffer(), Codec.SAVE_FORMAT).ok,
		"changed body checksum denied")
	var altered := save.duplicate(true)
	altered.operation_id = "red-cliffs-first-operation-dev-v1/" + "a".repeat(32)
	_check(not Codec.encode(altered, Codec.SAVE_FORMAT).ok, "v1 identity denied")
	altered = save.duplicate(true)
	altered.clock_ms += 1
	_check(not Codec.encode(altered, Codec.SAVE_FORMAT).ok, "tick and logical time must agree")
	altered = save.duplicate(true)
	altered.history[1].tick = 0
	_check(not Codec.encode(altered, Codec.SAVE_FORMAT).ok, "duplicate history tick denied")
	altered = save.duplicate(true)
	altered.pending = [Owner.FORMATION, {"kind": "stop"}]
	_check(not Codec.encode(altered, Codec.SAVE_FORMAT).ok, "formation cannot share a batch")
	altered.pending = [Owner.FORMATION.duplicate()]
	altered.pending[0].squadron_id = "RC-LIU-SQ-02"
	_check(not Codec.encode(altered, Codec.SAVE_FORMAT).ok, "unapproved formation denied")
	altered = save.duplicate(true)
	altered.state_digest = "not-a-digest"
	_check(not Codec.encode(altered, Codec.SAVE_FORMAT).ok, "invalid state witness denied")
	var replay := save.duplicate(true)
	replay.settlement = {"id": id + "/settlement", "operation_id": id, "tick": 12, "clock_ms": 1200,
		"kind": "objective_success", "reason": "objective_conditions_met"}
	var recorded := Codec.encode(replay, Codec.REPLAY_FORMAT)
	_check(recorded.ok and Codec.decode(recorded.bytes, Codec.REPLAY_FORMAT).record == replay,
		"separate replay round trip binds terminal witness")
	_check(not Codec.encode(replay, Codec.SAVE_FORMAT).ok, "settled operation denied by save codec")
	_reject_malformed_wire(saved.bytes, save, replay)
	replay.settlement.operation_id += "-foreign"
	_check(not Codec.encode(replay, Codec.REPLAY_FORMAT).ok, "foreign settlement denied")
	_check(Checkpoint.rules_digest() == "b7189ae8f3408fd4e053a792491ac5f6457a520218df2b709c4a8e3986863658"
		and V1._rules_and_inputs_digest() != Codec.rules_digest(), "native v1 stable and outer v2 digest separate")
	print("P05_V2_RECORD_CODEC %d/%d" % [tests - failures, tests])
	quit(0 if failures == 0 else 1)


func _reject_malformed_wire(saved: PackedByteArray, save: Dictionary, replay: Dictionary) -> void:
	for field in ["format", "version", "sha256", "rules_digest", "body"]:
		var envelope: Dictionary = JSON.parse_string(saved.get_string_from_utf8())
		envelope.version = Codec.VERSION
		envelope[field] = true
		_check(_is_failure(Codec.decode(_canonical_bytes(envelope), Codec.SAVE_FORMAT)),
			"structured failure for malformed envelope " + field)

	for field in ["capability", "operation_id", "tick", "history", "pending", "state_digest"]:
		var changed := save.duplicate(true)
		changed[field] = false
		_check(_is_failure(Codec.decode(_wire(changed, Codec.SAVE_FORMAT), Codec.SAVE_FORMAT)),
			"structured failure for valid-checksum malformed save body " + field)
	var changed := save.duplicate(true)
	changed.pending = [{"kind": "formation", "squadron_id": false, "formation_id": "FRM-01"}]
	_check(_is_failure(Codec.decode(_wire(changed, Codec.SAVE_FORMAT), Codec.SAVE_FORMAT)),
		"structured failure for malformed formation identifier")
	changed.pending = [{"kind": {"unexpected": true}}]
	_check(_is_failure(Codec.decode(_wire(changed, Codec.SAVE_FORMAT), Codec.SAVE_FORMAT)),
		"structured failure for nonstring command name")

	for field in ["id", "operation_id", "kind", "reason", "tick"]:
		changed = replay.duplicate(true)
		changed.settlement[field] = true
		_check(_is_failure(Codec.decode(_wire(changed, Codec.REPLAY_FORMAT), Codec.REPLAY_FORMAT)),
			"structured failure for valid-checksum malformed settlement " + field)


func _wire(body: Dictionary, format: String) -> PackedByteArray:
	var text := JSON.stringify(body, "", true, true)
	return _canonical_bytes({"format": format, "version": Codec.VERSION, "body": text,
		"sha256": text.sha256_text(), "rules_digest": Codec.rules_digest()})


func _canonical_bytes(value: Dictionary) -> PackedByteArray:
	return JSON.stringify(value, "", true, true).to_utf8_buffer()


func _is_failure(result: Dictionary) -> bool:
	return result.get("ok") == false and result.get("error") is String and result.get("path") is String


func _check(ok: bool, label: String) -> bool:
	tests += 1
	if not ok:
		failures += 1
	print("P05_V2_CODEC_CHECK ", ok, " ", label)
	return ok
