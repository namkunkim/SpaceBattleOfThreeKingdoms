extends RefCounted

const Store := preload("res://scripts/first_operation_save_store.gd")
const SLOT_PATH := "user://pc-first-operation-settlements.save"
const PRODUCT_SLOT_PATH := "user://pc-first-operation-product-v1-settlements.save"
const FORMAT := "pc-first-operation-settlements/1"
const ID_PREFIX := "red-cliffs-first-operation-dev-v1/"
const ID_SUFFIX := "/settlement"
const KINDS := ["objective_success", "withdrawal_success", "failure"]

const LOCK_SUFFIX := ".lock"


static func consume(outcome: BattleOutcome, path := SLOT_PATH) -> Dictionary:
	if outcome == null:
		return _fail("invalid_settlement", path)
	var clock_ms := roundi(outcome.t_s * 1000.0)
	var record := {"id": outcome.settlement_id, "kind": outcome.kind, "reason": outcome.reason,
		"clock_ms": clock_ms, "seed": outcome.seed, "mode": outcome.mode, "difficulty": outcome.difficulty}
	if not _valid_record(record) or outcome.win != (outcome.kind != "failure") \
			or not is_equal_approx(outcome.t_s, clock_ms / 1000.0):
		return _fail("invalid_settlement", path)
	return _with_slot_lock(path, _consume.bind(record, path))


static func restore_latest(path := SLOT_PATH) -> Dictionary:
	return _with_slot_lock(path, _restore_latest.bind(path))


static func product_settlement_status(operation_id: String) -> Dictionary:
	var restored := _read(PRODUCT_SLOT_PATH)
	if not restored.ok:
		return restored
	return {"ok": true, "settled": restored.payload.consumed.has(operation_id + ID_SUFFIX)}


static func _with_slot_lock(path: String, operation: Callable) -> Dictionary:
	var lock_path := ProjectSettings.globalize_path(path).simplify_path() + LOCK_SUFFIX
	# The filesystem creates the directory exclusively across processes.
	# An orphaned lock deliberately blocks access until verified and cleared.
	var acquired := DirAccess.make_dir_absolute(lock_path)
	if acquired == ERR_ALREADY_EXISTS:
		return _fail("settlement_slot_busy", path)
	if acquired != OK:
		return _fail("settlement_lock_failed", path)
	var result: Dictionary = operation.call()
	if DirAccess.remove_absolute(lock_path) != OK:
		# Keep the original result, including any completed write.
		push_warning("SETTLEMENT_LOCK_RELEASE_FAILED %s" % lock_path)
	return result


static func _restore_latest(path: String) -> Dictionary:
	var restored := _read(path)
	if not restored.ok:
		return restored
	var payload: Dictionary = restored.payload
	var latest: String = payload.latest
	return {"ok": true, "outcome": null if latest.is_empty() else _to_outcome(payload.consumed[latest])}


static func _consume(record: Dictionary, path: String) -> Dictionary:
	var restored := _read(path)
	if not restored.ok:
		return restored
	var payload: Dictionary = restored.payload
	var id: String = record.id
	if payload.consumed.has(id):
		if _to_outcome(payload.consumed[id]).to_dict() != _to_outcome(record).to_dict():
			return _fail("settlement_id_conflict", path)
		return {"ok": true, "applied": false, "outcome": _to_outcome(payload.consumed[payload.latest])}
	payload.consumed[id] = record
	payload["latest"] = id
	var written := Store.write(payload, path)
	if not written.ok:
		return written
	return {"ok": true, "applied": true, "outcome": _to_outcome(record)}


static func _read(path: String) -> Dictionary:
	var stored := Store.read(path)
	if not stored.ok:
		if stored.error == "file_not_found":
			return {"ok": true, "payload": {"format": FORMAT, "latest": "", "consumed": {}}}
		return stored
	var payload: Dictionary = stored.payload
	if payload.size() != 3 or payload.get("format") != FORMAT or not payload.get("latest") is String \
			or not payload.get("consumed") is Dictionary or not payload.consumed.has(payload.latest):
		return _fail("invalid_settlement_ledger", path)
	for id: String in payload.consumed:
		var record: Variant = payload.consumed[id]
		if not _valid_record(record) or id != record.id:
			return _fail("invalid_settlement_ledger", path)
	return stored


static func _valid_record(record: Variant) -> bool:
	if not record is Dictionary or record.size() != 7 or not record.get("id") is String \
			or not record.get("reason") is String or record.reason.is_empty() \
			or record.get("kind") not in KINDS or record.get("mode") not in ["direct", "auto"] \
			or not record.get("difficulty") is String or record.difficulty.is_empty() \
			or not _integer(record.get("clock_ms")) or record.clock_ms < 0 or not _integer(record.get("seed")):
		return false
	var id: String = record.id
	if not id.begins_with(ID_PREFIX) or not id.ends_with(ID_SUFFIX):
		return false
	var unique := id.trim_prefix(ID_PREFIX).trim_suffix(ID_SUFFIX)
	if unique.length() != 32:
		return false
	for digit in unique:
		if not digit in "0123456789abcdef":
			return false
	return true


static func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and absf(value) <= 9007199254740991.0 \
		and value == int(value)


static func _to_outcome(record: Dictionary) -> BattleOutcome:
	var outcome := BattleOutcome.new()
	outcome.settlement_id = record.id
	outcome.kind = record.kind
	outcome.reason = record.reason
	outcome.win = record.kind != "failure"
	outcome.t_s = record.clock_ms / 1000.0
	outcome.seed = int(record.seed)
	outcome.mode = record.mode
	outcome.difficulty = record.difficulty
	return outcome


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
