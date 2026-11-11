extends RefCounted

const Dev := preload("res://core/battle/first_operation_dev.gd")
const Policy := preload("res://core/battle/p05_p07_first_operation.gd")
const Preparer := preload("res://core/battle/first_operation_preparer.gd")

const CAPABILITY := Preparer.CAPABILITY
const ROUTE := "front"
const REQUEST := {
	"capability": CAPABILITY, "definition_id": Dev.DEFINITION_ID,
	"definition_version": Dev.DEFINITION_VERSION, "roster_id": Dev.ROSTER_ID,
	"seed": Dev.SEED, "difficulty": Dev.DIFFICULTY, "mode": "direct",
}

# Approved source pins for the single Red Cliffs v1 product selection.
const INPUT_SHA256 := {
	"roster": "0d702495a1ac94e255b44948ba8ebb625d4cdae2f1605658d05ec47911edb208",
	"combat_rules": "78d89e8c65f9d5fc4ab7324cc99b9f9ab0578157149f3f58036959d21131aa4c",
	"movement_rules": "bb7c2dbaa8c258dc8b43f16894502a72cb66a22d2058b5d5314816a0488e9d8e",
}


static func prepare_fresh(request: Variant, operation_id: String) -> Dictionary:
	var preparer := Preparer.new(Callable(), Callable(), CAPABILITY)
	var invalid := preparer._validate_request(request)
	if not invalid.is_empty():
		return invalid
	if request.definition_id != Dev.DEFINITION_ID or request.definition_version != Dev.DEFINITION_VERSION:
		return _fail("unknown_definition_version", "definition_version")
	for field in ["roster_id", "difficulty", "seed"]:
		if request[field] != REQUEST[field]:
			return _fail("unsupported_" + field, field)
	var definition := _read_pinned(Dev.DEFINITION_PATH, Policy.SOURCE_SHA)
	if definition.is_empty():
		return _fail("source_reference_mismatch", "definition")
	var inputs := {}
	for key in Dev.INPUT_PATHS:
		var path: String = Dev.INPUT_PATHS[key]
		if definition.inputs.get(key) != path:
			return _fail("source_reference_mismatch", "definition.inputs." + key)
		var parsed := _read_pinned(path, INPUT_SHA256[key])
		if parsed.is_empty():
			return _fail("source_reference_mismatch", "definition.inputs." + key)
		inputs[key] = parsed

	# Preserve the source envelope, including insertion order used by v1 digests.
	var source := {
		"space": definition.space.kind, "origin": definition.space.origin, "world_size": definition.space.size,
		"definition_id": Dev.DEFINITION_ID, "definition_version": Dev.DEFINITION_VERSION, "definition": definition,
		"rosters": {Dev.ROSTER_ID: {Dev.DIFFICULTY: {"inputs": inputs}}},
	}
	var resolve := func(_id: String, _version: int) -> Dictionary: return source
	return Preparer.new(resolve, _build_runtime.bind(operation_id), CAPABILITY).prepare_fresh(request)


static func _build_runtime(effective: Dictionary, selection: Dictionary, request: Dictionary, operation_id: String) -> Dictionary:
	var definition: Dictionary = effective.definition
	# Placement uses the approved v1 layout disks, including the safety margin.
	for fleet: Dictionary in definition.fleets:
		if fleet.spawn not in ["E", "R"]:
			continue
		var offset := Vector2(fleet.offset_xy[0], fleet.offset_xy[1])
		var reach := offset.length() + float(fleet.outer_radius) + float(definition.space.safety_margin)
		if reach > float(definition.space.regions[fleet.spawn].deployment_radius):
			return _fail("invalid_deployment_envelope", "definition.fleets." + fleet.id)
	# The internal checkpoint format records the resolved route. The external
	# product request has no route field.
	request.route_id = ROUTE
	return Dev._build_runtime(effective, selection, request, operation_id)


static func _read_pinned(path: String, expected: String) -> Dictionary:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return {}
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	if hash.finish().hex_encode() != expected:
		return {}
	var decoded := bytes.get_string_from_utf8()
	var parser := JSON.new()
	if decoded.to_utf8_buffer() != bytes or parser.parse(decoded) != OK or not parser.data is Dictionary:
		return {}
	return parser.data


static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}

