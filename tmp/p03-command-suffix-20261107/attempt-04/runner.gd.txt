extends SceneTree

const Private := preload("res://core/battle/operation_private_state.gd")
const SimScript := preload("res://core/battle/battle_sim.gd")
const StateScript := preload("res://core/battle/battle_state.gd")
const FleetScript := preload("res://core/battle/fleet_state.gd")
const TICK := 2
const CONTROLS := ["direct", "direct"]
const NAMES := [
	"suffix_01_prefix_pending_applied",
	"suffix_02_live_same_tick_suffix",
	"suffix_03_restore_and_replay_suffix",
	"suffix_04_reject_tick_and_content_cutters",
	"suffix_05_reject_context_keeps_active",
	"suffix_06_reject_structure_keeps_active",
]

var checks := 0
var failed := false
var completed: Array[String] = []
var context_rejects := 0
var structure_rejects := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failed = true
		push_error("P03_SUFFIX_FAIL " + label)
	return condition

func _exact(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if not _exact(_dict_type(a), _dict_type(b)) or not _exact(a.keys(), b.keys()): return false
		for key in a:
			if not _exact(a[key], b[key]): return false
		return true
	if a is Array:
		if a.get_typed_builtin() != b.get_typed_builtin() or a.get_typed_class_name() != b.get_typed_class_name(): return false
		if not is_same(a.get_typed_script(), b.get_typed_script()) or a.size() != b.size(): return false
		for i in a.size():
			if not _exact(a[i], b[i]): return false
		return true
	if a is Object: return is_same(a, b)
	return a == b

func _dict_type(value: Dictionary) -> Array:
	return [value.get_typed_key_builtin(), value.get_typed_key_class_name(), value.get_typed_key_script(),
		value.get_typed_value_builtin(), value.get_typed_value_class_name(), value.get_typed_value_script()]

func _properties(value: Object) -> Array:
	var fields: Array = []
	for property in value.get_property_list():
		if int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE and str(property.name) not in ["_idx", "_idx_n"]:
			fields.append([property.name, _snapshot(value.get(property.name))])
	return [value.get_script(), fields]

func _snapshot(value: Variant) -> Variant:
	if value is Object: return _properties(value)
	if value is Dictionary:
		var entries: Array = []
		for key in value: entries.append([key, _snapshot(value[key])])
		return ["dictionary", _dict_type(value), entries]
	if value is Array:
		var entries: Array = []
		for item in value: entries.append(_snapshot(item))
		return ["array", value.get_typed_builtin(), value.get_typed_class_name(), value.get_typed_script(), entries]
	return value

func _profile() -> Dictionary:
	var rules: Dictionary = PocSetup.profile().rules
	rules.world_w = 3400
	rules.world_h = 2300
	var note_array: Array[int] = [7]
	return {"profile_id": "p03-command-suffix", "rules": rules,
		"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
		"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 2600, "y": 1500, "p": 0, "flag": true}],
		"reinf": [], "note": {"typed_probe": note_array, "key_probe": {7: "value"}, "order_probe": {"first": 1, "last": 2}}}

func _command(label: String, applied := false) -> Dictionary:
	var ids: Array[int] = [999 if label == "R" else 1]
	var point := Vector2(900, 500) if label == "Q" else Vector2(1100, 500) if label == "B" else Vector2.ZERO
	var input_tick: int = {"Q": 77, "S": -1, "I": 88, "B": 89, "R": -1}[label]
	return {"tick": TICK if applied else input_tick, "side": 0, "ids": ids,
		"kind": "move" if label in ["Q", "B"] else "stop", "target_id": -1, "point": point, "args": {}}

func _commands(labels: Array, applied: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for label in labels: out.append(_command(label, applied))
	return out

func _say(pos: Vector2, value: String) -> Dictionary:
	return {"tick": TICK, "kind": "say", "sq": 1, "other": -1, "pos": pos, "value": value}

func _reject_event() -> Dictionary:
	return {"tick": TICK, "kind": "rejected", "sq": -1, "other": 0, "pos": Vector2.ZERO, "value": "no_selection"}

func _stage(owner: OperationPrivateState, raw: BattleSim, label: String) -> void:
	if raw != null:
		_check(_exact(_properties(owner._sim), _properties(raw)), label)

func _class_guard() -> bool:
	var classes := [Private, SimScript, StateScript, FleetScript]
	var names := ["operation_private_state", "battle_sim", "battle_state", "fleet_state"]
	for i in classes.size():
		var script: Script = classes[i]
		if not _check(script.resource_path == "res://core/battle/" + names[i] + ".gd", "canonical " + names[i]): return false
	return _check(Private._classes() == "", "canonical transitive class map")

func _binding(owner: OperationPrivateState) -> bool:
	var sim := owner._sim
	return _check(is_same(owner.get_script(), Private) and is_same(sim.get_script(), SimScript)
		and is_same(sim.st.get_script(), StateScript) and sim.st.fleets.size() == 2
		and is_same(sim.st.fleets[0].get_script(), FleetScript)
		and is_same(sim.st.fleets[1].get_script(), FleetScript)
		and is_same(sim.st.by_id(1), sim.st.fleets[0]) and is_same(sim.st.by_id(2), sim.st.fleets[1]),
		"runtime class identity and fleet bindings")

func _prefix(owner: OperationPrivateState, raw: BattleSim) -> Vector2:
	for i in TICK:
		_check(owner.advance().ok, "real prefix advance")
		raw.step()
		_stage(owner, raw, "prefix advance raw parity")
	_check(_exact(owner.drain_events().events, raw.drain_events()), "initial events before cut")
	var sim := owner._sim
	var pos := sim.st.fleets[0].pos
	_check(sim.st.tick == TICK and sim.st.clock_ms > 0 and not sim.st.over, "noninitial live T=2")
	var caller := _command("Q")
	for i in 2:
		_check(owner.queue(caller).ok, "repeat same caller queue")
		raw.queue(_command("Q"))
		_check(sim.command_log.is_empty() and sim._events.is_empty(), "enqueue not applied")
		_stage(owner, raw, "enqueue raw parity")
	caller.ids[0] = 2
	caller.point = Vector2(1500, 600)
	_check(_exact(sim._queue, _commands(["Q", "Q"], false)), "caller mutation did not alias pending")
	_check(owner.queue(_command("S")).ok, "queue distinct stop")
	raw.queue(_command("S"))
	_stage(owner, raw, "third enqueue raw parity")
	_check(owner.issue(_command("I")).ok, "prefix issue")
	raw.issue(_command("I"))
	_stage(owner, raw, "prefix issue raw parity")
	_check(_exact(sim._queue, _commands(["Q", "Q", "S"], false))
		and _exact(sim.command_log, _commands(["I"], true))
		and _exact(sim._events, _say_list(pos, ["stop"])), "checkpoint literal pending/log/event")
	completed.append(NAMES[0])
	return pos

func _say_list(pos: Vector2, values: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for value in values:
		out.append(_reject_event() if value == "no_selection" else _say(pos, value))
	return out

func _structure(owner: OperationPrivateState) -> void:
	var sim := owner._sim
	var handle := owner.get_instance_id()
	var before := _properties(sim)
	var duplicate_ids := _command("I")
	duplicate_ids.ids.append(1)
	var missing_key := _command("S")
	missing_key.erase("point")
	for i in 2:
		var command: Dictionary = [duplicate_ids, missing_key][i]
		var command_before := command.duplicate(true)
		var result := owner.issue(command) if i == 0 else owner.queue(command)
		if _check(_exact(result, {"ok": false, "error": "invalid_command"}), "structure rejection " + str(i)):
			structure_rejects += 1
		_check(_exact(command, command_before) and _exact(before, _properties(owner._sim))
			and is_same(sim, owner._sim) and handle == owner.get_instance_id()
			and owner._ready and not owner._busy, "structure rejection atomic " + str(i))
	completed.append(NAMES[5])

func _capture(owner: OperationPrivateState) -> Dictionary:
	var result := owner.capture_completed()
	if not _check(result.ok, "capture completed: " + str(result.get("error", ""))): return {}
	return result.packet

func _context(owner: OperationPrivateState) -> void:
	var sim := owner._sim
	var handle := owner.get_instance_id()
	var before := _properties(sim)
	for variant in ["controls", "typed", "order", "key_type"]:
		var profile := _profile()
		var controls: Array = CONTROLS.duplicate()
		match variant:
			"controls": controls.clear()
			"typed": profile.note.typed_probe = [7]
			"order": profile.note.order_probe = {"last": 2, "first": 1}
			"key_type": profile.note.key_probe = {"7": "value"}
		var alternate := Private.create(profile, 7, 10, controls)
		if not _check(alternate.ok, "context input create " + variant): continue
		var candidate: OperationPrivateState = alternate.owner
		var packet := _capture(candidate)
		candidate.close()
		if packet.is_empty(): continue
		var packet_before := packet.duplicate(true)
		var prepared := Private.prepare(packet)
		if not _check(prepared.ok, "context input standalone prepare " + variant): continue
		prepared.owner.close()
		var result := owner.restore_completed(packet)
		if _check(_exact(result, {"ok": false, "error": "replacement_context_mismatch"}), "context mismatch " + variant):
			context_rejects += 1
		_check(_exact(packet_before, packet) and _exact(before, _properties(owner._sim))
			and is_same(sim, owner._sim) and handle == owner.get_instance_id()
			and owner._ready and not owner._busy, "context rejection atomic " + variant)
	completed.append(NAMES[4])

func _suffix(owner: OperationPrivateState, raw: BattleSim, pos: Vector2) -> Array:
	var sim := owner._sim
	var observations: Array = []
	for label in ["B", "R"]:
		_check(owner.issue(_command(label)).ok, "same-tick structural acceptance " + label)
		if raw != null: raw.issue(_command(label))
		_stage(owner, raw, "suffix raw issue " + label)
		observations.append(_properties(sim))
	_check(sim.st.tick == TICK and _exact(sim.command_log, _commands(["I", "B", "R"], true))
		and _exact(sim._queue, _commands(["Q", "Q", "S"], false))
		and _exact(sim._events, _say_list(pos, ["stop", "move", "no_selection"]))
		and sim.st.fleets[0].has_move and sim.st.fleets[0].move_to == Vector2(1100, 500), "same-tick exact literals and movement")
	var applied := _commands(["I", "B", "R", "Q", "Q", "S"], true)
	for i in 2:
		_check(owner.advance().ok, "real suffix advance")
		if raw != null: raw.step()
		_stage(owner, raw, "suffix raw advance " + str(i))
		_check(sim.st.tick == TICK + i + 1 and sim._queue.is_empty() and _exact(sim.command_log, applied)
			and not sim.st.fleets[0].has_move, "Q/Q/S applied once and S wins")
		observations.append(_properties(sim))
		var drained := owner.drain_events()
		_check(drained.ok, "suffix drain succeeds")
		if raw != null: _check(_exact(drained.events, raw.drain_events()), "suffix raw drain " + str(i))
		if i == 0:
			var expected := _say_list(pos, ["stop", "move", "no_selection", "move", "move", "stop"])
			_check(drained.events.size() >= expected.size()
				and _exact(drained.events.slice(0, expected.size()), expected), "first drain literal ordered payload")
			var empty := owner.drain_events()
			_check(empty.ok and empty.events.is_empty(), "immediate second drain is empty")
			if raw != null: _check(_exact(empty.events, raw.drain_events()), "raw immediate empty drain")
			observations.append(empty.events)
		observations.append(drained.events)
		observations.append(_properties(sim))
	return observations

func _wrong_cuts(applied: Array[Dictionary]) -> void:
	_check(applied.filter(func(c): return c.tick > TICK).is_empty(), "tick greater loses same-tick B and R")
	var inclusive := applied.filter(func(c): return c.tick >= TICK)
	_check(inclusive.size() == 6 and _exact(inclusive[0], _command("I", true)), "tick inclusive reapplies I")
	_check(_exact(applied[3], applied[4]) and _exact(applied[5], _command("S", true)), "content dedup would lose a legitimate Q")
	_check(_exact(applied[0], _command("I", true)) and _exact(applied[3], _command("Q", true)), "Q accepted before I but applied after")
	completed.append(NAMES[3])

func _run() -> void:
	if not _class_guard():
		quit(1)
		return
	if "--p03-timeout-probe" in OS.get_cmdline_user_args():
		print("P03_TIMEOUT_PROBE ", JSON.stringify({"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id()}))
		OS.delay_msec(15000)
		quit(3)
		return
	var created := Private.create(_profile(), 7, 10, CONTROLS)
	if not _check(created.ok, "fixture create: " + str(created.get("error", ""))):
		quit(1)
		return
	var owner: OperationPrivateState = created.owner
	var raw := BattleSim.new(7, 10, _profile())
	for fleet in raw.st.fleets: fleet.control = "direct"
	_binding(owner)
	var pos := _prefix(owner, raw)
	_structure(owner)
	var packet := _capture(owner)
	if packet.is_empty():
		owner.close()
		quit(1)
		return
	var frozen := packet.duplicate(true)
	var before := _properties(owner._sim)
	_context(owner)
	var first := _suffix(owner, raw, pos)
	completed.append(NAMES[1])
	_wrong_cuts(owner._sim.command_log)
	var handle := owner.get_instance_id()
	var previous := owner._sim
	_check(previous.st.tick == TICK + 2 and previous.command_log.size() == 6
		and previous._queue.is_empty() and not _exact(before, _properties(previous)), "proved live timeline advanced before restore")
	var restored := owner.restore_completed(packet)
	if _check(restored.ok, "active restore " + str(restored.get("error", ""))):
		_check(handle == owner.get_instance_id() and not is_same(previous, owner._sim), "same handle and new sim")
		_binding(owner)
		_check(_exact(before, _properties(owner._sim)) and _exact(frozen, packet)
			and owner._ready and not owner._busy, "exact checkpoint and immutable packet")
		_check(_exact(first, _suffix(owner, null, pos)), "replayed suffix exact against first raw-validated run")
		_check(_exact(frozen, packet), "replayed suffix did not alias packet")
		completed.append(NAMES[2])
	owner.close()
	_check(completed.size() == NAMES.size() and NAMES.all(func(name): return name in completed)
		and context_rejects == 4 and structure_rejects == 2, "named case and reject denominator complete")
	print("P03_SUFFIX_RESULT ", JSON.stringify({"cases": completed, "checks": checks,
		"engine_path": OS.get_executable_path(), "engine_pid": OS.get_process_id(),
		"context_rejects": context_rejects, "structure_rejects": structure_rejects, "ok": not failed}))
	quit(1 if failed else 0)
