extends RefCounted

const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const Source := preload("res://scripts/first_operation_source_reference.gd")
const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")


## The exact consumed identifier is authoritative. The most recent displayed
## outcome is only a route hint and cannot substitute for a consumed record.
static func read(parent_id: String) -> Dictionary:
	return Ledger._with_slot_lock(Ledger.PRODUCT_SLOT_PATH, _read_consumed.bind(parent_id))


static func _read_consumed(parent_id: String) -> Dictionary:
	var result := Ledger._read(Ledger.PRODUCT_SLOT_PATH)
	if not result.ok:
		return result
	var record: Dictionary = result.payload.consumed.get(parent_id, {})
	if record.is_empty() or record.kind != "objective_success" or record.reason != "objective_conditions_met" \
			or int(record.seed) != Source.REQUEST.seed or record.mode != Source.REQUEST.mode \
			or record.difficulty != Source.REQUEST.difficulty:
		return {"ok": false, "error": "cross_counter_parent_ineligible", "path": Ledger.PRODUCT_SLOT_PATH}
	var parent := {"id": record.id, "kind": record.kind, "reason": record.reason,
		"clock_ms": int(record.clock_ms), "seed": int(record.seed), "mode": record.mode, "difficulty": record.difficulty}
	return {"ok": true, "parent": parent, "digest": Checkpoint.digest_value(parent)}
