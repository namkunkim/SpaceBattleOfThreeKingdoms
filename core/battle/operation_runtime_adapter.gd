extends RefCounted

# Explicit fresh, runtime-ready restricted input. No source-space conversion,
# module removal, profile fallback, checkpoint, UI or worker ownership.
const Private := preload("res://core/battle/operation_private_state.gd")
const FORMAT := "p02/restricted-headless/1"
const FIELDS := ["mode", "format", "profile", "seed", "hz", "initial_controls", "policy", "max_ticks"]
const INTEGERS := ["ships", "lv", "p", "command", "might", "intellect", "level", "start_morale_bp"]
const LIMIT := 2147483647

static func fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}

static func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]: return false
	if not is_finite(float(value)) or value < minimum or value > maximum: return false
	return floor(float(value)) == value

# Pure normalization returns detached values, never an owner or live simulation.
static func normalize(input: Variant) -> Dictionary:
	if not input is Dictionary: return fail("invalid_container", "$")
	if input.has("definition"): return fail("unsupported_input_representation", "definition")
	if input.has("checkpoint"): return fail("unsupported_checkpoint", "checkpoint")
	for key in FIELDS:
		if not input.has(key): return fail("missing_field", key)
	for key in input:
		if key not in FIELDS: return fail("unsupported_field", str(key))
	if typeof(input.mode) != TYPE_STRING or input.mode != "operation": return fail("unsupported_mode", "mode")
	if typeof(input.format) != TYPE_STRING or input.format != FORMAT: return fail("unsupported_input_representation", "format")
	if not input.profile is Dictionary: return fail("invalid_container", "profile")
	var value: Dictionary = input.duplicate(true)
	for side in ["ally", "foe"]:
		if not value.profile.has(side): return fail("missing_field", "profile." + side)
		if not value.profile[side] is Array: return fail("invalid_container", "profile." + side)
		for i in value.profile[side].size():
			var path := "profile.%s[%d]" % [side, i]
			var fleet: Variant = value.profile[side][i]
			if not fleet is Dictionary: return fail("invalid_container", path)
			if fleet.has("composition"):
				if not fleet.composition is Array: return fail("invalid_container", path + ".composition")
				for j in fleet.composition.size():
					if not fleet.composition[j] is Dictionary: return fail("invalid_container", path + ".composition[%d]" % j)
	for key in ["seed", "hz", "max_ticks"]:
		var minimum := 0 if key == "seed" else 1
		var maximum := 4294967295 if key == "seed" else LIMIT
		if not _integer(value[key], minimum, maximum): return fail("invalid_integer", key)
		value[key] = int(value[key])
	if value.hz != 10: return fail("unsupported_hz", "hz")
	for side in ["ally", "foe"]:
		for i in value.profile[side].size():
			var path := "profile.%s[%d]" % [side, i]
			var fleet: Dictionary = value.profile[side][i]
			for key in INTEGERS:
				if not fleet.has(key): continue
				if not _integer(fleet[key], 1 if key in ["ships", "lv"] else 0, LIMIT): return fail("invalid_integer", path + "." + key)
				fleet[key] = int(fleet[key])
			var total := 0
			for j in fleet.get("composition", []).size():
				var item: Dictionary = fleet.composition[j]
				if not item.has("count"): return fail("missing_field", path + ".composition[%d].count" % j)
				if not _integer(item.count, 1, LIMIT): return fail("invalid_integer", path + ".composition[%d].count" % j)
				item.count = int(item.count)
				if total > LIMIT - item.count: return fail("integer_total_overflow", path + ".composition")
				total += item.count
	if not value.initial_controls is Array: return fail("invalid_container", "initial_controls")
	if value.initial_controls.size() not in [0, value.profile.ally.size() + value.profile.foe.size()]: return fail("initial_controls", "initial_controls")
	for i in value.initial_controls.size():
		if typeof(value.initial_controls[i]) != TYPE_STRING or value.initial_controls[i] not in ["direct", "delegate"]: return fail("initial_controls", "initial_controls[%d]" % i)
	if typeof(value.policy) != TYPE_STRING or value.policy not in ["none", "attack5"]: return fail("unsupported_policy", "policy")
	return {"ok": true, "value": value}

static func create(input: Variant) -> Dictionary:
	var normalized := normalize(input)
	if not normalized.ok: return normalized
	var value: Dictionary = normalized.value
	var created := Private.create(value.profile, value.seed, value.hz, value.initial_controls)
	if not created.ok:
		var paths := {"unsupported_reinforcement": "profile.reinf", "unsupported_module_config": "profile.combat", "initial_controls": "initial_controls"}
		return fail(created.error, paths.get(created.error, "profile"))
	return {"ok": true, "owner": created.owner, "meta": {"format": FORMAT, "transform": "identity/no-transform", "input_sha256": var_to_bytes(input).hex_encode().sha256_text()}, "policy": value.policy, "max_ticks": value.max_ticks}
