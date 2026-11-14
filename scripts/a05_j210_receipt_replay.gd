extends RefCounted
## Internal, read-only J210 receipt replay. Not a product file codec or authority.
## The caller must obtain the record hash independently of the record directory.
## All decoded bytes are pinned before use. No saved owner is advanced or written.
## Historical evidence only: this does not establish the live head or payment rights.
const Runtime := preload("res://core/battle/operation_runtime_adapter.gd")
const Private := preload("res://core/battle/operation_private_state.gd")
const Durable := preload("res://scripts/o07_supply_owner.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const References := preload("res://scripts/operation_event_references.gd")
const FORMAT := "a05/j210-native-terminal-record/1"
const MAX_BYTES := 1024 * 1024
const FIXTURES := ["j210-host.json", "j210-replay.json", "j210-replay-result.json"]
const ARTIFACTS := ["observations.bin", "terminal-slot.save", "terminal-slot.previous"]

var _owner: OperationPrivateState
var _frames: Array = []
var _settlement: Dictionary = {}
var _index := 0
var _event_count := 0
var _closed := true

static func open_record(directory: String, trusted_record_sha256: String) -> Dictionary:
	if not directory.is_absolute_path() or not _hash(trusted_record_sha256):
		return _fail("receipt_replay_trust_required")
	var loaded := _read(directory.path_join("record.json"), trusted_record_sha256)
	if not loaded.ok:
		return loaded
	var record: Variant = _json(loaded.bytes)
	if not record is Dictionary or record.get("format") != FORMAT or record.get("product_replay") != false \
			or not _hashes(record.get("fixture_sha256"), FIXTURES) or not _hashes(record.get("artifact_sha256"), ARTIFACTS):
		return _fail("receipt_replay_record")
	var files := {}
	for name: String in FIXTURES + ARTIFACTS:
		var fixture := name in FIXTURES
		var path := directory.path_join(("fixtures/" if fixture else "") + name)
		var pins: Dictionary = record.fixture_sha256 if fixture else record.artifact_sha256
		loaded = _read(path, pins[name])
		if not loaded.ok:
			return loaded
		files[name] = loaded.bytes
	var witness: Variant = bytes_to_var(files["observations.bin"])
	var checked := _validate(record, witness, files)
	if not checked.ok:
		return checked
	# Verify the complete two-tick execution before publishing even C0 to a viewer.
	var trial := _session(witness, checked.settlement)
	if not trial.ok:
		return trial
	var session: RefCounted = trial.replay
	for i in 2:
		var result: Dictionary = session.step()
		if not result.ok:
			session.close()
			return result
	session.close()
	return _session(witness, checked.settlement)

static func _validate(record: Dictionary, witness: Variant, files: Dictionary) -> Dictionary:
	if not witness is Dictionary or not witness.get("input") is Dictionary \
			or not witness.get("replay") is Dictionary or not witness.get("frames") is Array \
			or witness.frames.size() != 3 or not witness.get("terminal_packet") is Dictionary \
			or not witness.get("receipt") is Dictionary or not witness.get("native_effect") is Dictionary:
		return _fail("receipt_replay_witness")
	var input: Variant = _json(files["j210-host.json"])
	var bundle: Variant = _json(files["j210-replay.json"])
	var reference: Variant = _json(files["j210-replay-result.json"])
	if not input is Dictionary or not bundle is Dictionary or not reference is Dictionary \
			or bundle.get("format") != "p02/restricted-fresh-replay/1" or bundle.get("commands") != [] \
			or bundle.get("input") != input or witness.input != input or witness.replay != bundle \
			or input.get("seed") != 20824 or input.get("policy") != "none" or input.get("max_ticks") != 2 \
			or var_to_bytes(input).hex_encode().sha256_text() != record.get("runtime_input_sha256") \
			or not reference.get("meta") is Dictionary or reference.meta.get("input_sha256") != record.runtime_input_sha256:
		return _fail("receipt_replay_input")
	for i in 3:
		var frame: Variant = witness.frames[i]
		if not frame is Dictionary or not frame.get("summary") is Dictionary \
				or not frame.get("projection") is Dictionary or not frame.get("owner") is Dictionary \
				or frame.summary.get("tick") != i or frame.summary.get("clock_ms") != [0, 100, 150][i] \
				or frame.summary.get("over") != (i == 2):
			return _fail("receipt_replay_frame")
	var current := _slot(files["terminal-slot.save"])
	var prior := _slot(files["terminal-slot.previous"])
	if not current.ok or not prior.ok:
		return _fail("receipt_replay_slot")
	var receipt: Dictionary = current.payload
	var previous: Dictionary = prior.payload
	var identity: Variant = record.get("operation_id")
	if not identity is String or identity.length() != 32 or not identity.is_valid_hex_number() \
			or identity != identity.to_lower() or identity.begins_with("+") or identity.begins_with("-"):
		return _fail("receipt_replay_identity")
	var key: String = identity + "/battle_settlement/1"
	if receipt.get("format") != Durable.FORMAT or previous.get("format") != Durable.FORMAT \
			or receipt.get("operation_id") != identity or previous.get("operation_id") != identity \
			or receipt.get("generation") != 2 or previous.get("generation") != 1 \
			or receipt.get("sequence") != 1 or previous.get("sequence") != 0 \
			or receipt.get("max_ticks") != 2 or previous.get("max_ticks") != 2 \
			or previous.get("receipts") != {} or previous.has("settlement_key") \
			or not receipt.get("receipts") is Dictionary or receipt.receipts.size() != 1 \
			or receipt.get("settlement_key") != key or record.get("settlement_key") != key \
			or record.get("generation") != 2 or record.get("sequence") != 1 \
			or witness.receipt != receipt:
		return _fail("receipt_replay_identity")
	if not receipt.get("snapshot") is String or not previous.get("snapshot") is String:
		return _fail("receipt_replay_snapshot")
	var packet: Variant = bytes_to_var(Marshalls.base64_to_raw(receipt.snapshot))
	var previous_packet: Variant = bytes_to_var(Marshalls.base64_to_raw(previous.snapshot))
	for candidate: Variant in [packet, previous_packet]:
		var prepared := Private.prepare(candidate)
		if not prepared.ok:
			return _fail("receipt_replay_snapshot")
		prepared.owner.close()
		if not References.valid(candidate.view, References.Scope.O07):
			return _fail("receipt_replay_snapshot")
	if witness.terminal_packet != packet or packet.view != witness.frames[2].owner \
			or previous_packet.view != witness.frames[1].owner:
		return _fail("receipt_replay_witness")
	var state: Dictionary = packet.view.state
	var effect := Durable._settlement(state)
	var digest := Durable._effect_digest(effect)
	if not state.over or state.end_tick != 2 or state.end_ms != 150 or not state.win \
			or state.end_reason != "annihilation" or not state.result.is_empty() \
			or effect != witness.native_effect or _plain(effect) != record.get("native_effect") \
			or receipt.receipts.get(key) != digest or record.get("receipt_digest") != digest:
		return _fail("receipt_replay_receipt")
	var terminal: Dictionary = witness.frames[2]
	var events: Array = packet.view.sim._events
	var endings := events.filter(func(event): return event.kind == "battle_end")
	if endings.size() != 1 or endings[0].tick != 2 or endings[0].value != "annihilation" \
			or _plain(terminal.summary) != record.get("terminal_summary") \
			or _plain(terminal.summary) != reference.get("summary") or _plain(events) != record.get("events") \
			or _plain(events) != reference.get("events") or record.get("clock_ms") != _plain([0, 100, 150]) \
			or record.get("native_slot_sha256") != _sha(files["terminal-slot.save"]) \
			or record.get("native_previous_sha256") != _sha(files["terminal-slot.previous"]):
		return _fail("receipt_replay_terminal")
	var expected := {"id": key, "kind": "alliance_win", "reason": state.end_reason,
		"t_s": state.end_ms / 1000.0, "seed": state.seed_id, "mode": "o07_native"}
	if record.get("verified_outcome") != _plain(expected):
		return _fail("receipt_replay_outcome")
	# Display DTO only. Never put an invented value into the native result.
	return {"ok": true, "settlement": {"id": key, "kind": expected.kind, "reason": expected.reason,
		"clock_ms": state.end_ms, "tick": state.end_tick, "receipt_digest": digest}}

static func _session(witness: Dictionary, settlement: Dictionary) -> Dictionary:
	var created := Runtime.create(witness.input)
	if not created.ok:
		return _fail("receipt_replay_runtime")
	var session: RefCounted = new()
	session._owner = created.owner
	session._closed = false
	session._frames = witness.frames.duplicate(true)
	session._settlement = settlement.duplicate(true)
	var initial: Dictionary = session._frame()
	if not initial.ok:
		session.close()
		return initial
	return {"ok": true, "replay": session, "frame": initial.frame}

func step() -> Dictionary:
	if _closed:
		return _fail("receipt_replay_closed")
	if _index == 2:
		return _fail("receipt_replay_finished")
	var advanced := _owner.advance()
	if not advanced.ok:
		close()
		return _fail("receipt_replay_runtime")
	_index += 1
	var result := _frame()
	if not result.ok:
		close()
	return result

func _frame() -> Dictionary:
	var summary := _owner.summary()
	var projected := _owner.read_projection(0)
	var observed := _owner.observe()
	var expected: Dictionary = _frames[_index]
	if not summary.ok or not projected.ok or not observed.ok or summary.summary != expected.summary \
			or projected.projection != expected.projection or observed != expected.owner:
		return _fail("receipt_replay_diverged")
	var events: Array = observed.sim._events
	var frame := {"tick": int(summary.summary.tick), "clock_ms": int(summary.summary.clock_ms),
		"projection": projected.projection.duplicate(true), "events": events.slice(_event_count).duplicate(true)}
	_event_count = events.size()
	if _index == 2:
		frame["settlement"] = _settlement.duplicate(true)
	return {"ok": true, "frame": frame, "done": _index == 2}

func close() -> void:
	if _closed:
		return
	_closed = true
	if _owner != null:
		_owner.close()
		_owner = null
	_frames.clear()
	_settlement.clear()

static func _read(path: String, expected_sha: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _fail("receipt_replay_read")
	var size := file.get_length()
	if size <= 0 or size > MAX_BYTES:
		file.close()
		return _fail("receipt_replay_size")
	var bytes := file.get_buffer(size)
	var complete := bytes.size() == size and file.get_length() == size
	file.close()
	if not complete or _sha(bytes) != expected_sha:
		return _fail("receipt_replay_hash")
	return {"ok": true, "bytes": bytes}

static func _slot(bytes: PackedByteArray) -> Dictionary:
	var envelope: Variant = _json(bytes)
	if not envelope is Dictionary or envelope.get("format") != Store.FORMAT \
			or envelope.get("version") != Store.VERSION or not envelope.get("body") is String \
			or envelope.body.sha256_text() != envelope.get("sha256"):
		return _fail("receipt_replay_slot")
	var payload: Variant = _json(envelope.body.to_utf8_buffer())
	return {"ok": true, "payload": payload} if payload is Dictionary else _fail("receipt_replay_slot")

static func _json(bytes: PackedByteArray) -> Variant:
	var source := bytes.get_string_from_utf8()
	if source.to_utf8_buffer() != bytes:
		return null
	var parser := JSON.new()
	return parser.data if parser.parse(source) == OK else null

static func _plain(value: Variant) -> Variant:
	return JSON.parse_string(JSON.stringify(value))

static func _sha(bytes: PackedByteArray) -> String:
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(bytes)
	return digest.finish().hex_encode()

static func _hash(value: Variant) -> bool:
	return value is String and value.length() == 64 and value.is_valid_hex_number() \
		and value == value.to_lower() and not value.begins_with("+") and not value.begins_with("-")

static func _hashes(value: Variant, names: Array) -> bool:
	if not value is Dictionary or value.size() != names.size():
		return false
	for name: String in names:
		if not _hash(value.get(name)):
			return false
	return true

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}
