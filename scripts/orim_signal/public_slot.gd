extends RefCounted

const LanternSlot := preload("res://scripts/lantern_escort/public_slot.gd")
const LanternRuntime := preload("res://scripts/lantern_escort/runtime.gd")
const ParentReceipts := preload("res://scripts/campaign_successor_parent_receipts.gd")
const Lease := preload("res://scripts/cross_counter/public_lease.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const Publisher := preload("res://scripts/o07_windows_slot.gd")
const Runtime := preload("res://scripts/orim_signal/runtime.gd")

const SLOT_PATH := "user://orim-signal-v1.save"
const FORMAT := "orim-signal-slot/1"
const MAX_PACKET_BYTES := 2 * 1024 * 1024
const MAX_TICKS := Runtime.LIMIT
const SETTLEMENT_FIELDS := ["id", "operation_id", "kind", "reason", "tick", "clock_ms", "seed", "mode", "difficulty"]

var _lease: Lease
var _head: Dictionary


static func read_parents() -> Dictionary:
	return ParentReceipts.collect(LanternSlot.inspect(), func(settlement: Dictionary) -> bool:
		return settlement.kind == "success" and settlement.escaped >= 1)


static func validate_parent(parent_id: String, digest: String) -> Dictionary:
	var parent := _find_parent(parent_id)
	if not parent.ok:
		return parent
	return parent if parent.digest == digest else _fail("orim_parent_changed")


static func _find_parent(parent_id: String) -> Dictionary:
	var source := read_parents()
	if not source.ok:
		return source
	if not source.parents.has(parent_id):
		return _fail("orim_parent_ineligible")
	var result: Dictionary = source.parents[parent_id]
	result.ok = true
	return result


static func open() -> Dictionary:
	var acquired := Lease.acquire(SLOT_PATH)
	if not acquired.ok:
		match acquired.error:
			"cross_counter_slot_busy":
				acquired.error = "orim_slot_busy"
			"cross_counter_windows_unavailable":
				acquired.error = "orim_windows_unavailable"
			_:
				acquired.error = "orim_lease_failed"
		return acquired
	var slot := new()
	slot._lease = acquired.lease
	var saved := Store.read(SLOT_PATH)
	if not saved.ok and saved.error == "file_not_found":
		slot._head = {"format": FORMAT, "revision": 0, "active": {}, "completed": {}}
	elif saved.ok:
		slot._head = saved.payload
		if not slot._valid_head():
			slot.close()
			return _fail("orim_invalid_head")
	else:
		slot.close()
		return saved
	return {"ok": true, "lease": slot, "head": slot.head()}


static func inspect() -> Dictionary:
	var result := open()
	if result.ok:
		result.lease.close()
		result.erase("lease")
	return result


func head() -> Dictionary:
	if not _held():
		return {}
	var result := _head.duplicate(true)
	if not result.active.is_empty():
		result.active.packet = _decode_packet(result.active)
		result.active.erase("packet_bytes")
	return result


func start(parent_id: String, operation_id: String, packet: Dictionary) -> Dictionary:
	if not _held():
		return _fail("orim_lease_closed")
	var completed: Dictionary = _head.completed.get(parent_id, {})
	if not completed.is_empty():
		var checked := validate_parent(parent_id, completed.parent_sha256)
		if not checked.ok:
			return checked
		return {"ok": true, "written": false, "completed": true, "operation_id": completed.operation_id,
			"settlement": completed.settlement.duplicate(true)}
	var active: Dictionary = _head.active
	if not active.is_empty():
		if active.parent_id != parent_id:
			return _fail("orim_owner_active")
		var checked := validate_parent(parent_id, active.parent_sha256)
		if not checked.ok:
			return checked
		return {"ok": true, "written": false, "completed": false, "operation_id": active.operation_id,
			"packet": _decode_packet(active)}
	if not _operation_id(operation_id) or not _valid_packet(packet, operation_id)\
			or packet.tick != 0 or packet.started or not packet.settlement.is_empty():
		return _fail("orim_invalid_c0")
	for receipt: Dictionary in _head.completed.values():
		if receipt.operation_id == operation_id:
			return _fail("orim_operation_already_used")
	var parent := _find_parent(parent_id)
	if not parent.ok:
		return parent
	var checked := _canonical_packet(packet)
	if not checked.ok:
		return checked
	active = {"parent_id": parent_id, "parent_sha256": parent.digest, "operation_id": operation_id}
	var stored := _store_active(active, checked.packet)
	if stored.ok:
		stored.merge({"completed": false, "operation_id": operation_id, "packet": checked.packet,
			"escaped": parent.receipt.settlement.escaped})
	return stored


func save(packet: Dictionary) -> Dictionary:
	if not _held():
		return _fail("orim_lease_closed")
	var active: Dictionary = _head.active
	if active.is_empty() or not _valid_packet(packet, active.operation_id) or not packet.settlement.is_empty():
		return _fail("orim_invalid_active_checkpoint")
	var previous := _decode_packet(active)
	if packet == previous:
		return {"ok": true, "written": false}
	if not _extends_checkpoint(previous, packet):
		return _fail("orim_stale_checkpoint")
	var checked := _canonical_packet(packet)
	if not checked.ok:
		return checked
	return _store_active(active, checked.packet)


func settle(packet: Dictionary) -> Dictionary:
	if not _held():
		return _fail("orim_lease_closed")
	var operation_id: Variant = packet.get("operation_id")
	if not _operation_id(operation_id) or not _valid_packet(packet, operation_id)\
			or not packet.started or not _valid_settlement(packet.settlement, operation_id)\
			or packet.settlement.tick != packet.tick or not packet.pending.is_empty():
		return _fail("orim_invalid_terminal_checkpoint")
	var checked := _canonical_packet(packet)
	if not checked.ok:
		return checked
	var canonical: Dictionary = checked.packet
	var digest := _sha(var_to_bytes(canonical))
	for receipt: Dictionary in _head.completed.values():
		if receipt.operation_id == operation_id:
			if receipt.packet_sha256 != digest or receipt.settlement != packet.settlement:
				return _fail("orim_settlement_conflict")
			return {"ok": true, "written": false}
	var active: Dictionary = _head.active
	if active.get("operation_id") != operation_id or not _extends_checkpoint(_decode_packet(active), packet):
		return _fail("orim_stale_checkpoint")
	var next := _head.duplicate(true)
	next.completed[active.parent_id] = {"parent_sha256": active.parent_sha256, "operation_id": operation_id,
		"packet_sha256": digest, "settlement": canonical.settlement}
	next.active = {}
	return _publish(next)


func close() -> void:
	if _lease != null:
		_lease.close()
		_lease = null
	_head = {}


func _held() -> bool:
	return _lease != null and _lease.held()


func _store_active(active: Dictionary, packet: Dictionary) -> Dictionary:
	var bytes := var_to_bytes(packet)
	if bytes.size() > MAX_PACKET_BYTES:
		return _fail("orim_checkpoint_too_large")
	var next := _head.duplicate(true)
	next.active = active.duplicate(true)
	next.active["packet_bytes"] = Marshalls.raw_to_base64(bytes)
	next.active["packet_sha256"] = _sha(bytes)
	return _publish(next)


func _publish(next: Dictionary) -> Dictionary:
	if int(_head.revision) >= Store.MAX_JSON_INT:
		return _fail("orim_revision_exhausted")
	next.revision = int(_head.revision) + 1
	var stored := Store.write(next, SLOT_PATH, Publisher.publish)
	if not stored.ok:
		return stored
	_head = next
	return {"ok": true, "written": true}


func _valid_head() -> bool:
	if not _fields(_head, ["format", "revision", "active", "completed"]) or _head.format != FORMAT\
			or not _json_integer(_head.revision, 1, Store.MAX_JSON_INT)\
			or not _head.active is Dictionary or not _head.completed is Dictionary:
		return false
	var identities := {}
	for parent_id: Variant in _head.completed:
		var receipt: Variant = _head.completed[parent_id]
		if not _parent_id(parent_id) or not _fields(receipt, ["parent_sha256", "operation_id", "packet_sha256", "settlement"])\
				or not _hex(receipt.parent_sha256, 64) or not _hex(receipt.packet_sha256, 64)\
				or not _operation_id(receipt.operation_id) or identities.has(receipt.operation_id)\
				or not _valid_settlement(receipt.settlement, receipt.operation_id):
			return false
		# Store.read decodes JSON numbers as floats. Validate before restoring the integer types.
		for field: String in ["tick", "clock_ms", "seed"]:
			receipt.settlement[field] = int(receipt.settlement[field])
		identities[receipt.operation_id] = true
	var active: Dictionary = _head.active
	if active.is_empty():
		return not identities.is_empty()
	if not _fields(active, ["parent_id", "parent_sha256", "operation_id", "packet_bytes", "packet_sha256"])\
			or not _parent_id(active.parent_id) or _head.completed.has(active.parent_id)\
			or not _hex(active.parent_sha256, 64) or not _hex(active.packet_sha256, 64)\
			or not _operation_id(active.operation_id) or identities.has(active.operation_id):
		return false
	var packet := _decode_packet(active)
	return _valid_packet(packet, active.operation_id) and packet.settlement.is_empty()


static func _decode_packet(active: Dictionary) -> Dictionary:
	var encoded: Variant = active.get("packet_bytes")
	if not encoded is String or encoded.is_empty() or encoded.length() > 4 * ceili(MAX_PACKET_BYTES / 3.0):
		return {}
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.is_empty() or bytes.size() > MAX_PACKET_BYTES or Marshalls.raw_to_base64(bytes) != encoded\
			or _sha(bytes) != active.get("packet_sha256"):
		return {}
	var packet: Variant = bytes_to_var(bytes)
	return packet if packet is Dictionary and var_to_bytes(packet) == bytes else {}


static func _valid_packet(packet: Dictionary, operation_id: String) -> bool:
	return _fields(packet, Runtime.PACKET_FIELDS)\
		and packet.operation_id == operation_id and typeof(packet.tick) == TYPE_INT\
		and packet.tick >= 0 and packet.tick <= MAX_TICKS and packet.started is bool\
		and (packet.started or packet.tick == 0) and packet.settlement is Dictionary\
		and packet.pending is Array and packet.pending.size() <= 8\
		and packet.applied is Array and packet.applied.size() <= packet.tick \
		and typeof(packet.event_cursor) == TYPE_INT and packet.event_cursor >= 0 and _hex(packet.witness, 64)


static func _canonical_packet(packet: Dictionary) -> Dictionary:
	if var_to_bytes(packet).size() > MAX_PACKET_BYTES:
		return _fail("orim_checkpoint_too_large")
	var restored := Runtime.restore(packet)
	return {"ok": true, "packet": restored.runtime.capture()} if restored.ok else restored


static func _extends_checkpoint(previous: Dictionary, packet: Dictionary) -> bool:
	if packet.tick < previous.tick or packet.event_cursor < previous.event_cursor \
			or (previous.started and not packet.started) \
			or packet.applied.slice(0, previous.applied.size()) != previous.applied:
		return false
	var additional: Array = packet.applied.slice(previous.applied.size())
	if not additional.is_empty():
		var first: Variant = additional[0]
		# A newly supplied history row cannot change any already committed tick.
		if not first is Dictionary or typeof(first.get("tick")) != TYPE_INT or first.tick < previous.tick:
			return false
	if packet.tick == previous.tick:
		return packet.pending.slice(0, previous.pending.size()) == previous.pending
	if previous.pending.is_empty():
		return true
	if additional.is_empty():
		return false
	var first: Dictionary = additional[0]
	return first.tick == previous.tick and first.get("batch") is Array \
		and first.batch.slice(0, previous.pending.size()) == previous.pending

static func _valid_settlement(value: Variant, operation_id: String) -> bool:
	if not _fields(value, SETTLEMENT_FIELDS) or value.id != operation_id + "/settlement" \
			or value.operation_id != operation_id or value.mode != "direct" or value.difficulty != "standard" \
			or not _json_integer(value.tick, 1, MAX_TICKS) \
			or not _json_integer(value.clock_ms, 0, MAX_TICKS * Runtime.TICK_MS) \
			or value.clock_ms != int(value.tick) * Runtime.TICK_MS or not _json_integer(value.seed, Runtime.SEED, Runtime.SEED):
		return false
	match value.reason:
		"signal_sent":
			return value.kind == "success"
		"command_destroyed", "abandoned":
			return value.kind == "failure"
		"deadline":
			return value.kind == "failure" and value.tick == MAX_TICKS
	return false

static func _parent_id(value: Variant) -> bool:
	return value is String and value.begins_with(LanternRuntime.ID_PREFIX) and value.ends_with("/settlement")\
		and _hex(value.trim_prefix(LanternRuntime.ID_PREFIX).trim_suffix("/settlement"), 32)


static func _operation_id(value: Variant) -> bool:
	return value is String and value.begins_with(Runtime.ID_PREFIX) and _hex(value.trim_prefix(Runtime.ID_PREFIX), 32)


static func _sha(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()


static func _json_integer(value: Variant, min_value: int, max_value: int) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and value >= min_value and value <= max_value and value == int(value)


static func _hex(value: Variant, length: int) -> bool:
	if not value is String or value.length() != length:
		return false
	for digit in value:
		if digit not in "0123456789abcdef":
			return false
	return true


static func _fields(value: Variant, keys: Array) -> bool:
	return value is Dictionary and value.size() == keys.size() and keys.all(func(key): return value.has(key))


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "path": SLOT_PATH}
