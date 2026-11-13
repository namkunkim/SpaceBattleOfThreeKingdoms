extends RefCounted
# Isolated opt-in operation owner. Only a native Supply completion can
# create a receipt. Consumers can acknowledge a committed receipt by key.
const Private := preload("res://core/battle/operation_private_state.gd")
const EventReferences := preload("res://scripts/operation_event_references.gd")
const Runtime := preload("res://core/battle/operation_runtime_adapter.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const WindowsSlot := preload("res://scripts/o07_windows_slot.gd")
const FORMAT := "pc-operation-supply-commit/1"
const HOST_SLOT := "user://operation-supply.save"
const HOST_ARG := "--o07-supply"

var _owner: OperationPrivateState
var _path: String
var _state: Dictionary
var _head_hash: String
var _read_only := false

static func create(input: Variant, path: String) -> Dictionary:
	var made := Runtime.create(input)
	if not made.ok:
		return made
	var started := begin(made.owner, path, made.max_ticks)
	if not started.ok:
		made.owner.close()
	return started

static func begin(owner: OperationPrivateState, path: String, max_ticks := 1000) -> Dictionary:
	var snapshot := owner.capture_completed()
	if not snapshot.ok:
		return snapshot
	if snapshot.packet.view.state.over:
		return _fail("cannot_initialize_terminal_operation")
	return _locked(path, _start.bind(owner, path, snapshot.packet, max_ticks))

static func _start(owner: OperationPrivateState, path: String, snapshot: Dictionary, max_ticks: int) -> Dictionary:
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + Store.PREVIOUS):
		return _fail("slot_already_initialized")
	if OS.has_feature("windows") and WindowsSlot.has_pending(path):
		return _fail("supply_authority_unavailable")
	var state := {"format": FORMAT, "operation_id": Crypto.new().generate_random_bytes(16).hex_encode(),
		"generation": 0, "sequence": 0, "max_ticks": max_ticks, "receipts": {}, "snapshot": _encode(snapshot)}
	var saved := _write(state, path)
	if not saved.ok:
		return saved
	return _session(owner, path, state, false)

static func open(path: String, previous := false) -> Dictionary:
	return _locked(path, _open.bind(path, previous))

# The authority path is selected by the caller. A backup never replaces it.
static func open_recovery(authority_path: String, backup_path: String) -> Dictionary:
	return _locked(authority_path, _recover.bind(authority_path, backup_path))

static func _recover(authority_path: String, backup_path: String) -> Dictionary:
	if not FileAccess.file_exists(authority_path):
		return _fail("supply_authority_unavailable")
	var authority_hash := FileAccess.get_sha256(authority_path)
	var backup_hash := FileAccess.get_sha256(backup_path)
	if authority_hash.is_empty() or backup_hash.is_empty():
		return _fail("supply_recovery_read_failed")
	if backup_hash != authority_hash:
		return _fail("supply_recovery_generation_mismatch")
	return _open(authority_path, false)

static func _open(path: String, previous: bool) -> Dictionary:
	# An earlier generation can describe local history but cannot establish
	# the latest issued sequence or external payment watermark.
	var fallback := previous or not FileAccess.file_exists(path)
	var stored := Store.read(path + Store.PREVIOUS if previous else path)
	if not stored.ok:
		return stored
	var state: Dictionary = stored.payload
	if state.get("format") != FORMAT or not state.get("operation_id") is String \
			or not state.get("receipts") is Dictionary or not state.get("snapshot") is String \
			or not _counter(state.get("generation")) or not _counter(state.get("sequence")) \
			or not _counter(state.get("max_ticks")) or state.max_ticks <= 0 \
			or state.receipts.size() != int(state.sequence):
		return _fail("invalid_supply_generation")
	var packet: Variant = bytes_to_var(Marshalls.base64_to_raw(state.snapshot))
	var prepared := Private.prepare(packet)
	if not prepared.ok:
		return prepared
	if not EventReferences.valid(packet.view, EventReferences.Scope.O07):
		prepared.owner.close()
		return _fail("event_reference")
	var end: Dictionary = packet.view.state
	if end.over:
		var expected := _settlement_key(state)
		if state.get("settlement_key") != expected or state.receipts.get(expected) != _effect_digest(_settlement(end)):
			prepared.owner.close()
			return _fail("invalid_terminal_receipt")
	elif state.has("settlement_key"):
		prepared.owner.close()
		return _fail("invalid_terminal_receipt")
	return _session(prepared.owner, path, state, fallback)

static func _session(owner: OperationPrivateState, path: String, state: Dictionary, read_only: bool) -> Dictionary:
	var session: RefCounted = new()
	session._owner = owner
	session._path = path
	session._state = state
	session._read_only = read_only
	session._head_hash = FileAccess.get_sha256(path)
	return {"ok": true, "session": session, "read_only": read_only}

func fork() -> Dictionary:
	return _fail("branch_external_payment_disabled")

func read_current_terminal_outcome() -> Dictionary:
	if _read_only:
		return _fail("historical_read_only")
	return _locked(_path, _read_terminal.bind(_path, _head_hash))

static func read_terminal_outcome(path: String) -> Dictionary:
	return _locked(path, _read_terminal.bind(path, ""))

static func _read_terminal(path: String, expected_hash: String) -> Dictionary:
	if not expected_hash.is_empty() and FileAccess.get_sha256(path) != expected_hash:
		return _fail("stale_supply_generation")
	var opened := _open(path, false)
	if not opened.ok:
		return {"ok": true, "outcome": null} if opened.error == "file_not_found" else opened
	var session: RefCounted = opened.session
	var key: String = session.settlement_key()
	var outcome: BattleOutcome
	if not opened.read_only and not key.is_empty():
		var state: Dictionary = session.observe().state
		var facts := {"win": state.win, "reason": state.end_reason,
			"t_s": state.end_ms / 1000.0, "result": state.result, "fingerprint": ""}
		outcome = BattleOutcome.from_facts(facts, null)
		outcome.seed = state.seed_id
		outcome.mode = "o07_native"
		outcome.settlement_id = key
	session.close()
	return {"ok": true, "outcome": outcome}

func observe() -> Dictionary:
	return _owner.observe()

func max_ticks() -> int:
	return int(_state.max_ticks)

func last_key() -> String:
	var sequence := int(_state.sequence) - int(_state.has("settlement_key"))
	return "" if sequence == 0 else "%s/supply_completion/%d" % [_state.operation_id, sequence]

func settlement_key() -> String:
	return _state.get("settlement_key", "")

func save() -> Dictionary:
	if _read_only:
		return _fail("historical_read_only")
	return _locked(_path, _save_head)

func _save_head() -> Dictionary:
	if not _is_head():
		return _fail("stale_supply_generation")
	var snapshot := _owner.capture_completed()
	if not snapshot.ok:
		return snapshot
	var next := _state.duplicate(true)
	next["generation"] = int(next.generation) + 1
	next["snapshot"] = _encode(snapshot.packet)
	var saved := _write(next, _path)
	if saved.ok:
		_state = next
		_head_hash = FileAccess.get_sha256(_path)
	return saved

func acknowledge(key: String, effect: Dictionary) -> Dictionary:
	if _read_only:
		return _fail("historical_read_only")
	return _locked(_path, _ack.bind(key, effect))

func request_external_payment(key: String, effect: Dictionary) -> Dictionary:
	if _read_only:
		return _fail("historical_read_only")
	return _locked(_path, _external_payment.bind(key, effect))

func _external_payment(key: String, effect: Dictionary) -> Dictionary:
	var receipt := _ack(key, effect)
	if not receipt.ok:
		return receipt
	# Local receipts do not grant authority to pay an external recipient.
	return _fail("external_payment_contract_missing")

func _ack(key: String, effect: Dictionary) -> Dictionary:
	if not _is_head():
		return _fail("stale_supply_generation")
	if not _state.receipts.has(key):
		return _fail("unknown_supply_transaction")
	if _state.receipts[key] != _effect_digest(effect):
		return _fail("supply_transaction_conflict")
	return {"ok": true, "applied": false}

func advance() -> Dictionary:
	if _read_only:
		return _fail("historical_read_only")
	return _locked(_path, _commit_step)

func _commit_step() -> Dictionary:
	if not _is_head():
		return _fail("stale_supply_generation")
	var before := _owner.capture_completed()
	if not before.ok:
		return before
	if before.packet.view.state.over:
		return _fail("operation_already_settled")
	var staged := Private.prepare(before.packet)
	if not staged.ok:
		return staged
	var candidate: OperationPrivateState = staged.owner
	var result := _stage_and_write(candidate, before.packet.view.sim._events.size())
	if not result.ok:
		candidate.close()
		return result
	var retired := _owner
	_owner = candidate
	retired.close()
	_state = result.state
	_head_hash = FileAccess.get_sha256(_path)
	return {"ok": true, "committed": result.committed}

func _stage_and_write(candidate: OperationPrivateState, prior_events: int) -> Dictionary:
	var advanced := candidate.advance()
	if not advanced.ok:
		return advanced
	var after := candidate.capture_completed()
	if not after.ok:
		return after
	var next := _state.duplicate(true)
	next["generation"] = int(next.generation) + 1
	next["snapshot"] = _encode(after.packet)
	var committed := {}
	var events: Array = after.packet.view.sim._events
	for i in range(prior_events, events.size()):
		var event: Dictionary = events[i]
		if event.kind != "supply":
			continue
		next["sequence"] = int(next.sequence) + 1
		var key := "%s/supply_completion/%d" % [next.operation_id, next.sequence]
		var effect := {"source": event.other, "receiver": event.sq, "value": event.value}
		next.receipts[key] = _effect_digest(effect)
		committed[key] = effect
	var end: Dictionary = after.packet.view.state
	if end.over:
		var terminal_events := events.slice(prior_events).filter(func(event): return event.kind == "battle_end")
		if terminal_events.size() != 1 or terminal_events[0].tick != end.end_tick or terminal_events[0].value != end.end_reason:
			return _fail("invalid_terminal_event")
		next["sequence"] = int(next.sequence) + 1
		var key := _settlement_key(next)
		var effect := _settlement(end)
		next["settlement_key"] = key
		next.receipts[key] = _effect_digest(effect)
		committed[key] = effect
	var saved := _write(next, _path)
	if not saved.ok:
		return saved
	return {"ok": true, "state": next, "committed": committed}

func _is_head() -> bool:
	return not _head_hash.is_empty() and FileAccess.get_sha256(_path) == _head_hash

func close() -> void:
	_owner.close()

static func _settlement_key(state: Dictionary) -> String:
	return "%s/battle_settlement/%d" % [state.operation_id, state.sequence]

static func _settlement(state: Dictionary) -> Dictionary:
	return {"tick": state.end_tick, "clock_ms": state.end_ms, "win": state.win, "reason": state.end_reason,
		"result": state.result}

static func _effect_digest(effect: Dictionary) -> String:
	return JSON.stringify(effect, "", true, true).sha256_text()

static func _encode(value: Variant) -> String:
	return Marshalls.raw_to_base64(var_to_bytes(value))

static func _counter(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and value >= 0 and value <= Store.MAX_JSON_INT and int(value) == value

static func _write(state: Dictionary, path: String) -> Dictionary:
	if OS.has_feature("windows"):
		return Store.write(state, path, WindowsSlot.publish)
	return Store.write(state, path)


static func _locked(path: String, action: Callable) -> Dictionary:
	if OS.has_feature("windows"):
		return WindowsSlot.with_lock(path, action)
	var lock_path := ProjectSettings.globalize_path(path).simplify_path() + ".lock"
	var acquired := DirAccess.make_dir_absolute(lock_path)
	if acquired != OK:
		return _fail("supply_slot_busy" if acquired == ERR_ALREADY_EXISTS else "supply_lock_failed")
	var result: Dictionary = action.call()
	if DirAccess.remove_absolute(lock_path) != OK:
		push_warning("SUPPLY_LOCK_RELEASE_FAILED")
	return result

static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}
