extends RefCounted

const Owner := preload("res://core/battle/first_operation_owner.gd")
const CAPABILITY := "pc/first-operation/1"
const DEVELOPMENT_CAPABILITY := "pc/first-operation-dev/1"
const SYNTHETIC_CAPABILITY := "pc/first-operation-synthetic/1"
const SOURCE_SPACE := "source"
const EFFECTIVE_SPACE := "effective"
const TRANSFORM := "pc/identity-1700x1150/1"
const REQUEST_FIELDS := ["capability", "definition_id", "definition_version", "roster_id", "seed", "difficulty", "mode"]
const RUNTIME_METHODS := ["summary", "read_projection", "drain_events_for", "advance", "issue", "queue", "close"]
const RUNTIME_CLAIM := &"p03_first_operation_claimed"

var _resolve_source: Callable
var _build_runtime: Callable
var _capability: String

# The composition root supplies trusted, synchronous dependencies.
# resolve_source(id, version) returns a versioned source Dictionary or {}.
# Source metadata: space, definition_id, definition_version, origin [x,y],
# world_size [w,h], and rosters[roster_id][difficulty] selection dictionaries.
# The approved backend validates the remaining map, roster and policy payload.
# build_runtime(read_only_effective, read_only_selection, request_copy)
# returns {ok, runtime} or
# {ok:false, error, path, runtime?}. Every newly returned runtime transfers
# ownership, including a partially initialized runtime returned on failure.
# The backend owns placement/rule validation and must close all its bindings.
# With no dependencies wired, a valid product request fails closed.
func _init(resolve_source := Callable(), build_runtime := Callable(), capability := CAPABILITY) -> void:
	_resolve_source = resolve_source
	_build_runtime = build_runtime
	_capability = capability

func prepare_fresh(request: Variant) -> Dictionary:
	var invalid := _validate_request(request)
	if not invalid.is_empty():
		return invalid
	if not _resolve_source.is_valid() or not _build_runtime.is_valid():
		return _fail("unconfigured_operation", "runtime")
	var source: Variant = _resolve_source.call(request.definition_id, request.definition_version)
	if source is Dictionary and source.is_empty():
		return _fail("unknown_definition_version", "definition_version")
	invalid = _validate_source(source, request)
	if not invalid.is_empty():
		return invalid

	var effective: Dictionary = source.duplicate(true)
	effective.space = EFFECTIVE_SPACE
	effective.origin = [0, 0]
	effective.world_size = [int(source.world_size[0]), int(source.world_size[1])]
	var selection: Dictionary = effective.rosters[request.roster_id][request.difficulty]
	var meta := {
		"capability": _capability,
		"definition_id": request.definition_id,
		"definition_version": request.definition_version,
		"roster_id": request.roster_id,
		"difficulty": request.difficulty,
		"seed": request.seed,
		"transform": TRANSFORM,
		"source_digest": _digest(source),
		"effective_digest": _digest(effective),
		"world_size": Vector2(effective.world_size[0], effective.world_size[1]),
	}
	_freeze(effective)
	var built: Variant = _build_runtime.call(effective, selection, request.duplicate(true))
	if not built is Dictionary:
		return _fail("invalid_runtime_result", "runtime")
	var runtime: Variant = built.get("runtime")
	if runtime is RefCounted and is_instance_valid(runtime):
		if runtime.has_meta(RUNTIME_CLAIM):
			return _fail("reused_runtime", "runtime")
		runtime.set_meta(RUNTIME_CLAIM, true)
	if built.get("ok") != true:
		var error: Variant = built.get("error")
		var path: Variant = built.get("path")
		var failure := _fail("invalid_runtime_result", "runtime")
		if error is String and not error.is_empty() and path is String and not path.is_empty():
			failure = _fail(error, path)
		return _discard(runtime, failure)
	if not runtime is RefCounted or not is_instance_valid(runtime):
		return _fail("invalid_runtime", "runtime")
	for method in RUNTIME_METHODS:
		if not runtime.has_method(method):
			return _discard(runtime, _fail("invalid_runtime", "runtime." + method))

	var summary: Variant = runtime.summary()
	var view: Variant = runtime.read_projection(0)
	if not _has_value(summary, "summary", TYPE_DICTIONARY):
		return _discard(runtime, _fail("invalid_initial_summary", "runtime.summary"))
	if not _has_value(view, "projection", TYPE_DICTIONARY):
		return _discard(runtime, _fail("invalid_initial_projection", "runtime.projection"))
	var state: Dictionary = summary.summary
	var projection: Dictionary = view.projection
	if not _initial_clock_matches(state, projection):
		return _discard(runtime, _fail("invalid_initial_clock", "runtime.clock"))
	var drained: Variant = runtime.drain_events_for(0)
	if not _has_value(drained, "events", TYPE_ARRAY):
		return _discard(runtime, _fail("invalid_initial_events", "runtime.events"))

	# The initial events leave the backend queue exactly once and travel in
	# this detached frame until publication or disposal.
	var frame := {
		"tick": state.tick, "clock_ms": state.clock_ms, "hz": projection.hz, "phase": "brief",
		"projection": projection.duplicate(true), "events": drained.events.duplicate(true),
		"meta": meta,
	}
	return {"ok": true, "owner": Owner.new(runtime, frame)}

func _validate_request(request: Variant) -> Dictionary:
	if not request is Dictionary:
		return _fail("invalid_request", "request")
	var fields := REQUEST_FIELDS + (["route_id"] if _capability == DEVELOPMENT_CAPABILITY else [])
	for key in fields:
		if not request.has(key):
			return _fail("missing_field", key)
	for key in request:
		if key not in fields:
			return _fail("unsupported_field", str(key))
	if not request.capability is String or request.capability != _capability or _capability not in [CAPABILITY, DEVELOPMENT_CAPABILITY, SYNTHETIC_CAPABILITY]:
		return _fail("unsupported_capability", "capability")
	if not request.mode is String or request.mode != "direct":
		return _fail("unsupported_mode", "mode")
	if _capability == DEVELOPMENT_CAPABILITY and request.route_id not in ["front", "flank"]:
		return _fail("unsupported_route", "route_id")
	for key in ["definition_id", "roster_id", "difficulty"]:
		if not request[key] is String or request[key].is_empty():
			return _fail("invalid_id", key)
	if typeof(request.definition_version) != TYPE_INT or request.definition_version < 1:
		return _fail("invalid_definition_version", "definition_version")
	if typeof(request.seed) != TYPE_INT or request.seed < 0 or request.seed > 4294967295:
		return _fail("invalid_seed", "seed")
	return {}

func _validate_source(source: Variant, request: Dictionary) -> Dictionary:
	if not source is Dictionary or source.get("space") != SOURCE_SPACE:
		return _fail("unsupported_source_space", "source.space")
	if source.get("definition_id") != request.definition_id:
		return _fail("definition_mismatch", "source.definition_id")
	if typeof(source.get("definition_version")) != TYPE_INT or source.definition_version != request.definition_version:
		return _fail("definition_version_mismatch", "source.definition_version")
	if not _matches_pair(source.get("origin"), 0, 0):
		return _fail("unsupported_origin", "source.origin")
	if not _matches_pair(source.get("world_size"), 1700, 1150):
		return _fail("unsupported_extent", "source.world_size")
	var rosters: Variant = source.get("rosters")
	if not rosters is Dictionary or not rosters.get(request.roster_id) is Dictionary:
		return _fail("unsupported_roster", "roster_id")
	if not rosters[request.roster_id].get(request.difficulty) is Dictionary:
		return _fail("unsupported_difficulty", "difficulty")
	return {}

static func _matches_pair(value: Variant, x: int, y: int) -> bool:
	return (value is Array and value.size() == 2
		and typeof(value[0]) in [TYPE_INT, TYPE_FLOAT] and float(value[0]) == x
		and typeof(value[1]) in [TYPE_INT, TYPE_FLOAT] and float(value[1]) == y)

static func _initial_clock_matches(summary: Dictionary, projection: Dictionary) -> bool:
	return (typeof(summary.get("tick")) == TYPE_INT and summary.tick == 0
		and typeof(summary.get("clock_ms")) == TYPE_INT and summary.clock_ms == 0
		and typeof(summary.get("over")) == TYPE_BOOL and not summary.over
		and typeof(projection.get("tick")) == TYPE_INT and projection.tick == summary.tick
		and typeof(projection.get("side")) == TYPE_INT and projection.side == 0
		and typeof(projection.get("hz")) == TYPE_INT and projection.hz == 10
		and projection.get("clock_s") == 0.0
		and projection.get("squadrons") is Array)

static func _has_value(result: Variant, key: String, type: int) -> bool:
	return result is Dictionary and result.get("ok") == true and typeof(result.get(key)) == type

static func _discard(runtime: Variant, failure: Dictionary) -> Dictionary:
	if runtime is RefCounted and is_instance_valid(runtime) and runtime.has_method("close"):
		runtime.close()
	return failure

static func _freeze(value: Variant) -> void:
	if value is Dictionary:
		for item in value.values():
			_freeze(item)
		value.make_read_only()
	elif value is Array:
		for item in value:
			_freeze(item)
		value.make_read_only()

static func _digest(value: Dictionary) -> String:
	return var_to_bytes(value).hex_encode().sha256_text()

static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
