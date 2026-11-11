extends SceneTree

const Preparer := preload("res://core/battle/first_operation_preparer.gd")

# A lifecycle test double. It models neither the P05 map nor P07 rules.
class RuntimeDouble extends RefCounted:
	var ticks := 0
	var close_calls := 0
	var drain_calls := 0
	var bad_projection := false
	var bad_events := false
	var seen_commands: Array[Dictionary] = []
	var pending := [{"id": 1, "kind": "synthetic_init"}, {"id": 2, "kind": "synthetic_ready"}]

	func summary() -> Dictionary:
		return {"ok": true, "summary": {"tick": ticks, "clock_ms": ticks * 100, "over": false}}

	func read_projection(side: int) -> Dictionary:
		return {"ok": true, "projection": {
			"tick": ticks + int(bad_projection), "clock_s": ticks / 10.0,
			"side": side, "hz": 10, "squadrons": [{"id": "synthetic"}],
		}}

	func drain_events_for(_side: int) -> Dictionary:
		drain_calls += 1
		if bad_events:
			return {"ok": false}
		var events := pending
		pending = []
		return {"ok": true, "events": events}

	func advance() -> Dictionary:
		ticks += 1
		pending.append({"id": 3, "kind": "synthetic_advance"})
		return {"ok": true}

	func issue(command: Dictionary) -> Dictionary:
		seen_commands.append(command)
		return {"ok": true}

	func queue(command: Dictionary) -> Dictionary:
		return issue(command)

	func close() -> void:
		close_calls += 1

var _checks := 0
var _failures := 0
var _resolve_calls := 0
var _build_calls := 0
var _last_runtime: RuntimeDouble
var _reused_runtime: RuntimeDouble
var _failure_mode := ""
var _source := {
	"space": "source", "definition_id": "synthetic", "definition_version": 1,
	"origin": [0, 0], "world_size": [1700, 1150],
	"rosters": {"demo": {"standard": {"tag": "synthetic"}}},
}

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(message)

func _error(result: Dictionary, error: String, path: String) -> void:
	_check(result == {"ok": false, "error": error, "path": path}, "expected %s at %s, got %s" % [error, path, result])

func _resolve(id: String, version: int) -> Dictionary:
	_resolve_calls += 1
	return _source if id == "synthetic" and version == 1 else {}

func _build(effective: Dictionary, selection: Dictionary, request: Dictionary) -> Dictionary:
	_build_calls += 1
	_check(effective.space == "effective" and effective.origin == [0, 0] and effective.world_size == [1700, 1150], "builder must receive the single identity effective")
	_check(selection.tag == "synthetic" and request.seed == 42, "builder must receive the selected roster and seed")
	_check(not is_same(effective, _source) and not is_same(effective.origin, _source.origin), "effective must be detached from source")
	_check(effective.is_read_only() and effective.origin.is_read_only() and selection.is_read_only(), "effective and selection must be immutable")
	request.seed = -1
	if _failure_mode == "reuse":
		return {"ok": true, "runtime": _reused_runtime}
	_last_runtime = RuntimeDouble.new()
	match _failure_mode:
		"placement":
			return {"ok": false, "error": "fixture_rejected", "path": "runtime.fixture", "runtime": _last_runtime}
		"clock":
			_last_runtime.bad_projection = true
		"events":
			_last_runtime.bad_events = true
	return {"ok": true, "runtime": _last_runtime}

func _run() -> void:
	var request := {
		"capability": Preparer.SYNTHETIC_CAPABILITY, "definition_id": "synthetic",
		"definition_version": 1, "roster_id": "demo", "difficulty": "standard",
		"seed": 42, "mode": "direct",
	}
	var preparer := Preparer.new(_resolve, _build, Preparer.SYNTHETIC_CAPABILITY)
	var product_request := request.duplicate(true)
	product_request.capability = Preparer.CAPABILITY
	_error(Preparer.new().prepare_fresh(product_request), "unconfigured_operation", "runtime")
	_error(preparer.prepare_fresh(product_request), "unsupported_capability", "capability")
	_error(preparer.prepare_fresh(_with(request, "mode", "auto")), "unsupported_mode", "mode")
	_error(preparer.prepare_fresh(_with(request, "seed", -1)), "invalid_seed", "seed")
	_error(preparer.prepare_fresh(_with(request, "definition_version", 0)), "invalid_definition_version", "definition_version")
	_error(preparer.prepare_fresh(_with(request, "effective", {})), "unsupported_field", "effective")
	_check(_resolve_calls == 0 and _build_calls == 0, "request rejection must precede resolution")
	_error(preparer.prepare_fresh(_with(request, "definition_version", 2)), "unknown_definition_version", "definition_version")
	_error(preparer.prepare_fresh(_with(request, "roster_id", "missing")), "unsupported_roster", "roster_id")
	_error(preparer.prepare_fresh(_with(request, "difficulty", "missing")), "unsupported_difficulty", "difficulty")
	_source.space = "effective"
	_error(preparer.prepare_fresh(request), "unsupported_source_space", "source.space")
	_source.space = "source"
	_source.origin = [1, 0]
	_error(preparer.prepare_fresh(request), "unsupported_origin", "source.origin")
	_source.origin = [0, 0]
	_check(_build_calls == 0, "no rejected source reaches the runtime")

	var source_before := var_to_bytes(_source)
	var request_before := var_to_bytes(request)
	var a: Dictionary = preparer.prepare_fresh(request)
	var first_runtime := _last_runtime
	var b: Dictionary = preparer.prepare_fresh(request)
	var second_runtime := _last_runtime
	if not a.get("ok", false) or not b.get("ok", false):
		_check(false, "fresh preparations failed: %s / %s" % [a, b])
		_finish()
		return
	var frame: Dictionary = a.owner.preview_initial_frame().frame
	_check(a.owner != b.owner and first_runtime != second_runtime, "fresh owners must be independent")
	_check(frame == b.owner.preview_initial_frame().frame, "identical input must produce the same initial frame")
	_check(frame.tick == 0 and frame.clock_ms == 0 and frame.hz == 10 and frame.phase == "brief", "fresh clock and phase")
	_check(frame.events.map(func(event): return event.id) == [1, 2], "initial event order")
	_check(frame.meta.capability == Preparer.SYNTHETIC_CAPABILITY, "synthetic scope must be visible")
	_check(frame.meta.source_digest != frame.meta.effective_digest, "source and effective must be distinct representations")
	_check(var_to_bytes(_source) == source_before and var_to_bytes(request) == request_before, "builder must not alias caller input")
	frame.events[0].id = 999
	frame.projection.squadrons.clear()
	_error(a.owner.advance(), "owner_not_published", "owner")
	_error(a.owner.issue({}), "owner_not_published", "owner")
	_error(a.owner.drain_events(), "owner_not_published", "owner")
	var published: Dictionary = a.owner.publish()
	_check(published.frame == b.owner.preview_initial_frame().frame, "preview mutations must not reach publication")
	_error(a.owner.publish(), "owner_already_published", "owner")
	_check(first_runtime.drain_calls == 1 and a.owner.drain_events().events.is_empty(), "published initial events must not replay")
	var command := {"args": {"point": 1}}
	_check(a.owner.queue(command).ok, "live owner accepts a queued command")
	command.args.point = 2
	_check(first_runtime.seen_commands[0].args.point == 1, "queued input must be detached")
	_check(a.owner.advance().ok and a.owner.summary().summary.tick == 1, "only the published owner advances")
	_check(a.owner.drain_events().events[0].id == 3, "live events follow the initial frame")

	_check(a.owner.advance().ok, "queue a live event before failed preparation")
	_reused_runtime = first_runtime
	_failure_mode = "reuse"
	_error(preparer.prepare_fresh(request), "reused_runtime", "runtime")
	_check(first_runtime.close_calls == 0 and a.owner.summary().summary.tick == 2, "reuse rejection must preserve the live owner")
	_failure_mode = "placement"
	_error(preparer.prepare_fresh(request), "fixture_rejected", "runtime.fixture")
	_check(_last_runtime.close_calls == 1, "partial runtime closed on builder rejection")
	_failure_mode = "clock"
	_error(preparer.prepare_fresh(request), "invalid_initial_clock", "runtime.clock")
	_check(_last_runtime.close_calls == 1 and _last_runtime.drain_calls == 0, "clock rejection closes before draining")
	_failure_mode = "events"
	_error(preparer.prepare_fresh(request), "invalid_initial_events", "runtime.events")
	_check(_last_runtime.close_calls == 1, "event rejection closes the candidate")
	_check(a.owner.summary().summary.tick == 2 and first_runtime.close_calls == 0, "failed preparation preserves existing owner and clock")

	_check(first_runtime.seen_commands.size() == 1 and a.owner.drain_events().events[0].id == 3, "failed preparations preserve command history and pending events")
	a.owner.close()
	a.owner.close()
	_error(a.owner.advance(), "owner_closed", "owner")
	_check(first_runtime.close_calls == 1, "published owner closes once")
	_check(b.owner.preview_initial_frame().frame.tick == 0 and second_runtime.close_calls == 0, "advance and close do not affect another candidate")
	b.owner.close()
	_error(b.owner.publish(), "owner_closed", "owner")
	_check(second_runtime.close_calls == 1, "discarded candidate closes once")

	_failure_mode = ""
	var retry: Dictionary = preparer.prepare_fresh(request)
	_check(retry.get("ok", false), "valid preparation retries after failures")
	if retry.get("ok", false):
		var abandoned_runtime := _last_runtime
		retry.clear()
		_check(abandoned_runtime.close_calls == 1, "dropping the last owner reference disposes its runtime")
	_finish()

func _finish() -> void:
	print("first_operation_fresh synthetic lifecycle: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _with(request: Dictionary, key: String, value: Variant) -> Dictionary:
	var copy := request.duplicate(true)
	copy[key] = value
	return copy
