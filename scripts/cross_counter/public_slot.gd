extends RefCounted

const Lease := preload("res://scripts/cross_counter/public_lease.gd")
const Parent := preload("res://scripts/cross_counter/public_parent.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const Publisher := preload("res://scripts/o07_windows_slot.gd")

const SLOT_PATH := "user://cross-counter-successor-v1.save"
const FORMAT := "cross-counter-successor-slot/1"
const OPERATION_PREFIX := "cross-counter-successor-v1/"
const MAX_PACKET_BYTES := 2 * 1024 * 1024
const MAX_TICKS := 650

var _lease: Lease
var _head: Dictionary


static func open() -> Dictionary:
	var acquired := Lease.acquire(SLOT_PATH)
	if not acquired.ok:
		return acquired
	var slot := new()
	slot._lease = acquired.lease
	var read := Store.read(SLOT_PATH)
	if not read.ok and read.error == "file_not_found":
		slot._head = {"format": FORMAT, "revision": 0, "active": {}, "completed": {}}
	elif read.ok:
		slot._head = read.payload
		if not slot._valid_head():
			slot.close()
			return _fail("cross_counter_invalid_head")
	else:
		slot.close()
		return read
	return {"ok": true, "lease": slot, "head": slot.head()}


static func inspect() -> Dictionary:
	var result := open()
	if not result.ok:
		return result
	result.lease.close()
	result.erase("lease")
	return result


static func eligible_parent(parent_id: String) -> Dictionary:
	return Parent.read(parent_id)


func head() -> Dictionary:
	if not _held():
		return {}
	var result := _head.duplicate(true)
	if not result.active.is_empty():
		result.active.packet = _decode_packet(result.active)
	return result


func start(parent_id: String, operation_id: String, packet: Dictionary) -> Dictionary:
	if not _held():
		return _fail("cross_counter_lease_closed")
	if not _head.active.is_empty():
		return _fail("cross_counter_owner_active")
	if _head.completed.has(parent_id):
		return _fail("cross_counter_parent_already_used")
	if not _operation_id(operation_id) or not _valid_packet(packet, operation_id) or packet.tick != 0 \
			or packet.bootstrap_done or not packet.settlement.is_empty():
		return _fail("cross_counter_invalid_c0")
	for receipt: Dictionary in _head.completed.values():
		if receipt.operation_id == operation_id:
			return _fail("cross_counter_operation_already_used")
	var parent := Parent.read(parent_id)
	if not parent.ok:
		return parent
	var active := {"parent_id": parent_id, "parent_sha256": parent.digest, "operation_id": operation_id,
		"packet_bytes": "", "packet_sha256": ""}
	return _store_active(active, packet)


func save(packet: Dictionary) -> Dictionary:
	if not _held():
		return _fail("cross_counter_lease_closed")
	var active: Dictionary = _head.active
	if active.is_empty() or not _valid_packet(packet, active.operation_id) or not packet.settlement.is_empty():
		return _fail("cross_counter_invalid_active_checkpoint")
	var previous := _decode_packet(active)
	if packet.tick < previous.tick or (previous.bootstrap_done and not packet.bootstrap_done):
		return _fail("cross_counter_stale_checkpoint")
	if packet == previous:
		return {"ok": true, "written": false}
	return _store_active(active, packet)


func settle(packet: Dictionary, settlement: Dictionary) -> Dictionary:
	if not _held():
		return _fail("cross_counter_lease_closed")
	var operation_id: Variant = packet.get("operation_id")
	if not _operation_id(operation_id) or not _valid_packet(packet, operation_id) \
			or not packet.bootstrap_done or not _valid_settlement(settlement, operation_id, packet.clock_ms) \
			or not _valid_settlement(packet.settlement, operation_id, packet.clock_ms) or packet.settlement != settlement:
		return _fail("cross_counter_invalid_terminal_checkpoint")
	var digest := _sha(var_to_bytes(packet))
	for receipt: Dictionary in _head.completed.values():
		if receipt.operation_id == operation_id:
			if receipt.packet_sha256 == digest and receipt.settlement == settlement:
				return {"ok": true, "written": false}
			return _fail("cross_counter_settlement_conflict")
	var active: Dictionary = _head.active
	if active.get("operation_id") != operation_id or packet.tick < _decode_packet(active).tick:
		return _fail("cross_counter_stale_checkpoint")
	var next := _head.duplicate(true)
	next.completed[active.parent_id] = {"parent_sha256": active.parent_sha256, "operation_id": operation_id,
		"packet_sha256": digest, "settlement": settlement.duplicate(true)}
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
		return _fail("cross_counter_checkpoint_too_large")
	var next := _head.duplicate(true)
	next.active = active.duplicate(true)
	next.active.packet_bytes = Marshalls.raw_to_base64(bytes)
	next.active.packet_sha256 = _sha(bytes)
	return _publish(next)


func _publish(next: Dictionary) -> Dictionary:
	if int(_head.revision) >= Store.MAX_JSON_INT:
		return _fail("cross_counter_revision_exhausted")
	next.revision = int(_head.revision) + 1
	var stored := Store.write(next, SLOT_PATH, Publisher.publish)
	if not stored.ok:
		return stored
	_head = next
	return {"ok": true, "written": true}


func _valid_head() -> bool:
	if not _fields(_head, ["format", "revision", "active", "completed"]) \
			or not _head.format is String or _head.format != FORMAT \
			or not _json_integer(_head.revision) or int(_head.revision) <= 0 \
			or not _head.active is Dictionary or not _head.completed is Dictionary:
		return false
	var identities := {}
	for parent_id: Variant in _head.completed:
		var receipt: Variant = _head.completed[parent_id]
		if not _parent_id(parent_id) or not _fields(receipt, ["parent_sha256", "operation_id", "packet_sha256", "settlement"]) \
				or not _digest(receipt.parent_sha256) or not _digest(receipt.packet_sha256) \
				or not _operation_id(receipt.operation_id) or identities.has(receipt.operation_id) \
				or not receipt.settlement is Dictionary or not _json_integer(receipt.settlement.get("clock_ms")):
			return false
		# JSON decodes numbers as floats. Verify bounded integral fields first.
		if not _json_integer(receipt.settlement.get("seed")):
			return false
		receipt.settlement.clock_ms = int(receipt.settlement.clock_ms)
		receipt.settlement.seed = int(receipt.settlement.seed)
		if not _valid_settlement(receipt.settlement, receipt.operation_id, receipt.settlement.clock_ms):
			return false
		identities[receipt.operation_id] = true
	var active: Dictionary = _head.active
	if active.is_empty():
		return not identities.is_empty()
	if not _fields(active, ["parent_id", "parent_sha256", "operation_id", "packet_bytes", "packet_sha256"]) \
			or not _parent_id(active.parent_id) or _head.completed.has(active.parent_id) \
			or not _digest(active.parent_sha256) or not _digest(active.packet_sha256) \
			or not _operation_id(active.operation_id) or identities.has(active.operation_id):
		return false
	var packet := _decode_packet(active)
	return _valid_packet(packet, active.operation_id) and packet.settlement.is_empty()


static func _decode_packet(active: Dictionary) -> Dictionary:
	var encoded: Variant = active.get("packet_bytes")
	if not encoded is String or encoded.is_empty() or encoded.length() > 4 * ceili(MAX_PACKET_BYTES / 3.0):
		return {}
	var bytes := Marshalls.base64_to_raw(encoded)
	if bytes.is_empty() or bytes.size() > MAX_PACKET_BYTES or Marshalls.raw_to_base64(bytes) != encoded:
		return {}
	var packet: Variant = bytes_to_var(bytes)
	if not packet is Dictionary or _sha(bytes) != active.get("packet_sha256"):
		return {}
	return packet


static func _valid_packet(packet: Dictionary, operation_id: String) -> bool:
	return (packet.get("operation_id") is String and packet.operation_id == operation_id \
		and typeof(packet.get("tick")) == TYPE_INT and packet.tick >= 0 and packet.tick <= MAX_TICKS \
		and typeof(packet.get("clock_ms")) == TYPE_INT and packet.clock_ms >= 0 \
		and typeof(packet.get("bootstrap_done")) == TYPE_BOOL and packet.get("settlement") is Dictionary \
		and (packet.bootstrap_done or packet.tick == 0)
		and (packet.clock_ms == packet.tick * 100 or (not packet.settlement.is_empty()
			and packet.clock_ms == packet.tick * 100 - 50)))


static func _valid_settlement(settlement: Dictionary, operation_id: String, clock_ms: int) -> bool:
	return _fields(settlement, ["id", "kind", "reason", "clock_ms", "seed", "mode", "difficulty"]) \
		and settlement.id is String and settlement.id == operation_id + "/settlement" \
		and settlement.kind is String and settlement.kind in ["objective_success", "withdrawal_success", "failure"] \
		and settlement.reason is String and not settlement.reason.is_empty() \
		and typeof(settlement.clock_ms) == TYPE_INT and settlement.clock_ms == clock_ms and clock_ms >= 0 \
		and typeof(settlement.seed) == TYPE_INT and settlement.seed >= 0 and settlement.seed <= 4294967295 \
		and settlement.mode is String and settlement.mode == "direct" \
		and settlement.difficulty is String and not settlement.difficulty.is_empty()


static func _json_integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and value >= 0 and value <= Store.MAX_JSON_INT and value == int(value)


static func _parent_id(value: Variant) -> bool:
	return value is String and value.begins_with(Parent.Ledger.ID_PREFIX) and value.ends_with(Parent.Ledger.ID_SUFFIX) \
		and _hex(value.trim_prefix(Parent.Ledger.ID_PREFIX).trim_suffix(Parent.Ledger.ID_SUFFIX), 32)


static func _operation_id(value: Variant) -> bool:
	return value is String and value.begins_with(OPERATION_PREFIX) and _hex(value.trim_prefix(OPERATION_PREFIX), 32)


static func _sha(bytes: PackedByteArray) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(bytes)
	return hashing.finish().hex_encode()


static func _digest(value: Variant) -> bool:
	return value is String and _hex(value, 64)


static func _hex(value: String, length: int) -> bool:
	if value.length() != length:
		return false
	for digit in value:
		if not digit in "0123456789abcdef":
			return false
	return true


static func _fields(value: Variant, keys: Array) -> bool:
	return value is Dictionary and value.size() == keys.size() and keys.all(func(key): return value.has(key))


static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error, "path": SLOT_PATH}
