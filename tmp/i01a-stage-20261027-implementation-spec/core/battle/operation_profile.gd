class_name OperationProfile
extends RefCounted

# I01a: pure configuration. Does not construct a runtime or execute saves.
const ADAPTERS := ["host_input", "headless_input", "replay_input"]
const FIELDS := ["schema_version", "rules_version", "canonical_version", "definition_id", "profile_id", "coordinate_space", "synthetic", "bounds", "target_size", "move_mul", "turn_mul", "envelope", "nodes", "edges", "required_routes", "regions", "effect_zones", "kinematics", "features"]

static func from_envelope(envelope: Dictionary) -> Dictionary:
	var adapter: String = str(envelope.get("adapter", ""))
	if adapter not in ADAPTERS:
		return _failure([{"path": "adapter", "code": "UNSUPPORTED_ADAPTER"}])
	var payload: Variant = envelope
	if adapter == "host_input" or adapter == "replay_input":
		var field := "selection" if adapter == "host_input" else "header"
		for key in envelope:
			if key not in ["adapter", field]:
				return _failure([{"path": str(key), "code": "UNSUPPORTED_ENVELOPE_FIELD"}])
		payload = envelope.get(field, null)
	if not payload is Dictionary:
		return _failure([{"path": "payload", "code": "INVALID_PAYLOAD"}])
	var request: Dictionary = payload.duplicate(true)
	if adapter == "headless_input":
		request.erase("adapter")
	request.erase("definition")
	return build(payload.get("definition", null), request)

static func build(definition: Variant, request: Dictionary = {}) -> Dictionary:
	var mode: Variant = request.get("mode", "legacy")
	if not mode is String or mode not in ["legacy", "operation"]:
		return _failure([{"path": "mode", "code": "UNSUPPORTED_MODE"}])
	if mode == "legacy":
		var legacy: Variant = request.get("legacy_profile", null)
		if not legacy is Dictionary or legacy.is_empty():
			return _failure([{"path": "legacy_profile", "code": "MISSING_LEGACY_PROFILE"}])
		return {"ok": true, "errors": [], "effective": legacy.duplicate(true), "manifest": {"scope": "legacy_passthrough", "effective_hash": canonical(legacy).sha256_text()}}
	var errors: Array = []
	for key in request:
		if key not in ["mode", "seed", "hz", "legacy_profile"]:
			_error(errors, "request." + str(key), "UNSUPPORTED_REQUEST_FIELD")
	if not _integer(request.get("seed")) or float(request.get("seed", -1)) < 0 or float(request.get("seed", -1)) > float((1 << (4 * 4 * 2)) - 1):
		_error(errors, "seed", "INVALID_SEED")
	if not _integer(request.get("hz")) or int(request.get("hz", 0)) != BattleRules.TICK_HZ:
		_error(errors, "hz", "UNSUPPORTED_HZ")
	if not definition is Dictionary:
		_error(errors, "definition", "MISSING_DEFINITION")
		return _failure(errors)
	_validate(definition, errors)
	if not errors.is_empty():
		return _failure(errors)
	var source_hash := canonical(definition).sha256_text()
	var effective: Dictionary = definition.duplicate(true)
	var scale := float(definition.target_size[0]) / float(definition.bounds[2])
	if not is_finite(scale) or scale <= 0:
		return _failure([{"path": "definition.target_size", "code": "INVALID_EFFECTIVE_GEOMETRY"}])
	effective.coordinate_space = "effective"
	effective.bounds = [0.0, 0.0, float(definition.target_size[0]), float(definition.target_size[1])]
	for node in effective.nodes:
		node.position = [float(node.position[0]) * scale, float(node.position[1]) * scale]
	effective.envelope.radius *= scale
	effective.envelope.safety *= scale
	effective.envelope.unit = "effective-coordinate"
	for region in effective.regions:
		region.radius *= scale
		region.unit = "effective-coordinate"
	for zone in effective.effect_zones:
		zone.rect = zone.rect.map(func(value): return float(value) * scale)
	effective.kinematics["face_turn_deg_per_s"] = float(effective.kinematics.turn_deg_per_s) * 4
	effective.kinematics.speed *= float(definition.move_mul)
	effective.kinematics.turn_deg_per_s *= float(definition.turn_mul)
	effective.kinematics.evasion_per_speed /= float(definition.move_mul)
	effective["seed"] = int(request.seed)
	effective["hz"] = int(request.hz)
	effective["clock_metadata"] = {"tick": 0, "clock_ms": 0, "last_applied_seq": 0, "next_command_seq": 1}
	if not _json_value(effective):
		return _failure([{"path": "effective", "code": "NONFINITE_EFFECTIVE_VALUE"}])
	if float(effective.envelope.radius) <= 0 or float(effective.envelope.safety) < 0:
		return _failure([{"path": "effective.envelope", "code": "INVALID_EFFECTIVE_GEOMETRY"}])
	for region in effective.regions:
		if float(region.radius) <= 0:
			return _failure([{"path": "effective.regions." + region.id, "code": "INVALID_EFFECTIVE_GEOMETRY"}])
	for zone in effective.effect_zones:
		if float(zone.rect[2]) <= 0 or float(zone.rect[3]) <= 0:
			return _failure([{"path": "effective.effect_zones." + zone.id, "code": "INVALID_EFFECTIVE_GEOMETRY"}])
	if not is_finite(float(effective.envelope.radius) + float(effective.envelope.safety)):
		return _failure([{"path": "effective.envelope", "code": "NONFINITE_EFFECTIVE_VALUE"}])
	var access := _access(effective)
	if not access.ok:
		return _failure(access.errors)
	return {"ok": true, "errors": [], "effective": effective, "manifest": {"scope": "i01a_config_fixture_only", "source_hash": source_hash, "effective_hash": canonical(effective).sha256_text(), "canonical_version": definition.canonical_version, "original_i01_status": "NOT_READY", "product_geometry": "NOT_READY", "runtime_snapshot": "NOT_IMPLEMENTED", "host_activation": false, "access": access}}

static func _validate(d: Dictionary, errors: Array) -> void:
	for key in FIELDS:
		if not d.has(key):
			_error(errors, "definition." + key, "MISSING_FIELD")
	for key in d:
		if key not in FIELDS:
			_error(errors, "definition." + str(key), "UNSUPPORTED_FIELD")
	if not errors.is_empty():
		return
	if not _json_value(d):
		_error(errors, "definition", "INVALID_JSON_VALUE")
		return
	if not _integer(d.schema_version) or int(d.schema_version) != 1 or d.rules_version != "i01a-fixture-v1" or d.canonical_version != "i01a-canonical-v1":
		_error(errors, "definition.version", "UNSUPPORTED_VERSION")
	if not _id(d.definition_id) or not _id(d.profile_id):
		_error(errors, "definition.id", "INVALID_ID")
	if d.coordinate_space != "source":
		_error(errors, "definition.coordinate_space", "SOURCE_REQUIRED")
	if not d.synthetic is bool or d.synthetic != true:
		_error(errors, "definition.synthetic", "NOT_READY_PRODUCT_ENVELOPE")
	if not _numbers(d.bounds, 4) or not _numbers(d.target_size, 2):
		_error(errors, "definition.bounds", "INVALID_GEOMETRY")
		return
	if float(d.bounds[0]) != 0 or float(d.bounds[1]) != 0:
		_error(errors, "definition.bounds", "UNSUPPORTED_ORIGIN")
	if float(d.bounds[2]) <= 0 or float(d.bounds[3]) <= 0 or float(d.target_size[0]) <= 0 or float(d.target_size[1]) <= 0:
		_error(errors, "definition.bounds", "INVALID_GEOMETRY")
		return
	if float(d.target_size[0]) / float(d.bounds[2]) != float(d.target_size[1]) / float(d.bounds[3]):
		_error(errors, "definition.target_size", "UNSUPPORTED_NONUNIFORM_SCALE")
	for key in ["move_mul", "turn_mul"]:
		if not _number(d[key]) or float(d[key]) <= 0:
			_error(errors, "definition." + key, "INVALID_MULTIPLIER")
	if not d.envelope is Dictionary or not _number(d.envelope.get("radius")) or not _number(d.envelope.get("safety")):
		_error(errors, "definition.envelope", "MISSING_ENVELOPE")
	elif d.envelope.get("kind") != "synthetic-circle" or d.envelope.get("unit") != "source-coordinate" or float(d.envelope.radius) <= 0 or float(d.envelope.safety) < 0:
		_error(errors, "definition.envelope", "INVALID_ENVELOPE")
	if not d.features is Dictionary:
		_error(errors, "definition.features", "UNSUPPORTED_FEATURE")
	else:
		for key in d.features:
			if key not in ["runtime", "save", "physical_obstacles"]:
				_error(errors, "definition.features." + str(key), "UNSUPPORTED_FEATURE")
		if d.features.get("runtime") != "deferred" or d.features.get("save") != "deferred" or not d.features.get("physical_obstacles") is bool or d.features.physical_obstacles != false:
			_error(errors, "definition.features", "UNSUPPORTED_FEATURE")
	if not d.kinematics is Dictionary:
		_error(errors, "definition.kinematics", "INVALID_KINEMATICS")
	else:
		for key in ["speed", "turn_deg_per_s", "evasion_per_speed"]:
			if not _number(d.kinematics.get(key)) or float(d.kinematics.get(key, -1)) < 0:
				_error(errors, "definition.kinematics." + key, "INVALID_KINEMATICS")
	for key in ["nodes", "edges", "required_routes", "regions", "effect_zones"]:
		if not d[key] is Array:
			_error(errors, "definition." + key, "ARRAY_REQUIRED")
	if not errors.is_empty():
		return
	_keys(d.envelope, ["radius", "safety", "unit", "kind"], "definition.envelope", errors)
	_keys(d.kinematics, ["speed", "turn_deg_per_s", "evasion_per_speed"], "definition.kinematics", errors)
	var ids := {}
	for node in d.nodes:
		if not node is Dictionary or not _id(node.get("id")) or not _numbers(node.get("position"), 2) or node.get("kind") not in ["entry", "junction", "facility"]:
			_error(errors, "definition.nodes", "INVALID_NODE")
			continue
		_keys(node, ["id", "kind", "position"], "definition.nodes." + node.id, errors)
		if ids.has(node.id):
			_error(errors, "definition.nodes." + node.id, "DUPLICATE_ID")
		ids[node.id] = node
	var edge_ids := {}
	for edge in d.edges:
		if not edge is Dictionary or not _id(edge.get("id")) or not edge.get("bidirectional") is bool:
			_error(errors, "definition.edges", "INVALID_EDGE")
			continue
		_keys(edge, ["id", "from", "to", "bidirectional"], "definition.edges." + edge.id, errors)
		if edge_ids.has(edge.id):
			_error(errors, "definition.edges." + edge.id, "DUPLICATE_ID")
		edge_ids[edge.id] = true
		if not ids.has(edge.get("from")) or not ids.has(edge.get("to")):
			_error(errors, "definition.edges." + edge.id, "UNKNOWN_NODE")
	for route in d.required_routes:
		if not route is Array or route.size() != 2 or not ids.has(route[0]) or not ids.has(route[1]):
			_error(errors, "definition.required_routes", "UNKNOWN_NODE")
	var region_ids := {}
	for region in d.regions:
		if not region is Dictionary or not _id(region.get("id")) or not ids.has(region.get("node")) or not _number(region.get("radius")):
			_error(errors, "definition.regions", "INVALID_REGION")
			continue
		_keys(region, ["id", "node", "radius", "unit", "shape", "admission"], "definition.regions." + region.id, errors)
		if region_ids.has(region.id):
			_error(errors, "definition.regions." + region.id, "DUPLICATE_ID")
		region_ids[region.id] = true
		if float(region.radius) <= 0 or region.get("unit") != "source-coordinate" or region.get("shape") != "circle" or region.get("admission") != "center-in-world/intersect-free-centers":
			_error(errors, "definition.regions." + region.id, "UNSUPPORTED_REGION_ADMISSION")
	var zone_ids := {}
	for zone in d.effect_zones:
		if not zone is Dictionary or not _id(zone.get("id")) or not _numbers(zone.get("rect"), 4) or zone.get("type") not in ["nebula", "debris", "planet_shadow"] or not zone.get("effects") is Dictionary:
			_error(errors, "definition.effect_zones", "INVALID_ZONE")
			continue
		_keys(zone, ["id", "type", "rect", "effects"], "definition.effect_zones." + zone.id, errors)
		_keys(zone.effects, ["movement_cost_bp"], "definition.effect_zones." + zone.id + ".effects", errors)
		if not _integer(zone.effects.get("movement_cost_bp")) or float(zone.effects.get("movement_cost_bp", 0)) <= 0:
			_error(errors, "definition.effect_zones." + zone.id + ".effects", "UNSUPPORTED_EFFECT")
		if zone_ids.has(zone.id):
			_error(errors, "definition.effect_zones." + zone.id, "DUPLICATE_ID")
		zone_ids[zone.id] = true
		if float(zone.rect[2]) <= 0 or float(zone.rect[3]) <= 0 or float(zone.rect[0]) < 0 or float(zone.rect[1]) < 0 or float(zone.rect[0]) + float(zone.rect[2]) > float(d.bounds[2]) or float(zone.rect[1]) + float(zone.rect[3]) > float(d.bounds[3]):
			_error(errors, "definition.effect_zones." + zone.id, "INVALID_GEOMETRY")

static func _access(effective: Dictionary) -> Dictionary:
	var errors: Array = []
	var width := float(effective.bounds[2])
	var height := float(effective.bounds[3])
	var margin := float(effective.envelope.radius) + float(effective.envelope.safety)
	var nodes := {}
	var graph := {}
	if margin > width - margin or margin > height - margin:
		_error(errors, "envelope", "NO_FREE_CENTER")
		return _failure(errors)
	for node in effective.nodes:
		nodes[node.id] = node
		graph[node.id] = []
		var point: Array = node.position
		if float(point[0]) < margin or float(point[0]) > width - margin or float(point[1]) < margin or float(point[1]) > height - margin:
			_error(errors, "nodes." + node.id, "OUTSIDE_FREE_CENTER")
	for edge in effective.edges:
		graph[edge.from].append(edge.to)
		if edge.bidirectional:
			graph[edge.to].append(edge.from)
	for route in effective.required_routes:
		if not _connected(graph, route[0], route[1]):
			_error(errors, "required_routes", "REQUIRED_ROUTE_DISCONNECTED")
	for region in effective.regions:
		var point: Array = nodes[region.node].position
		var x := float(point[0])
		var y := float(point[1])
		var nearest := Vector2(clampf(x, margin, width - margin), clampf(y, margin, height - margin))
		if Vector2(x, y).distance_to(nearest) > float(region.radius):
			_error(errors, "regions." + region.id, "NO_SERVICE_INTERSECTION")
	return {"ok": errors.is_empty(), "errors": errors, "geometry_scope": "one_synthetic_circle_no_obstacles", "free_bounds": [margin, margin, width - margin, height - margin]}

static func _connected(graph: Dictionary, start: String, goal: String) -> bool:
	var visited := {start: true}
	var pending: Array = [start]
	var index := 0
	while index < pending.size():
		var current: String = pending[index]
		index += 1
		if current == goal:
			return true
		for next in graph[current]:
			if not visited.has(next):
				visited[next] = true
				pending.append(next)
	return false

static func canonical(value: Variant) -> String:
	if value is Dictionary:
		var keys: Array = value.keys()
		keys.sort()
		var parts := PackedStringArray()
		for key in keys:
			parts.append(JSON.stringify(str(key)) + ":" + canonical(value[key]))
		return "{" + ",".join(parts) + "}"
	if value is Array:
		var parts := PackedStringArray()
		for item in value:
			parts.append(canonical(item))
		return "[" + ",".join(parts) + "]"
	return JSON.stringify(value, "", true, true)

static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floor(float(value))

static func _numbers(value: Variant, count: int) -> bool:
	if not value is Array or value.size() != count:
		return false
	for item in value:
		if not _number(item):
			return false
	return true

static func _id(value: Variant) -> bool:
	return value is String and not value.strip_edges().is_empty()

static func _json_value(value: Variant) -> bool:
	if value == null or value is String or value is bool:
		return true
	if value is int or value is float:
		return _number(value)
	if value is Array:
		for item in value:
			if not _json_value(item):
				return false
		return true
	if value is Dictionary:
		for key in value:
			if not key is String or not _json_value(value[key]):
				return false
		return true
	return false

static func _error(errors: Array, path: String, code: String) -> void:
	errors.append({"path": path, "code": code})

static func _failure(errors: Array) -> Dictionary:
	return {"ok": false, "errors": errors, "effective": null, "manifest": {"scope": "i01a_config_fixture_only", "original_i01_status": "NOT_READY"}}

static func _keys(value: Dictionary, allowed: Array, path: String, errors: Array) -> void:
	for key in value:
		if key not in allowed:
			_error(errors, path + "." + str(key), "UNSUPPORTED_FIELD")
