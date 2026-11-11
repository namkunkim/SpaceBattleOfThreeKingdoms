extends RefCounted

const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const FORMAT := "p02/restricted-fresh-replay/1"
const MAX_BYTES := 16 * 1024 * 1024
const MAX_TICKS := 18000
const MAX_COMMANDS := 18000
const MAX_ID := 2147483647
const ENVELOPE_FIELDS := ["format", "input", "commands"]
const COMMAND_FIELDS := ["tick", "side", "ids", "kind", "target_id", "point", "args"]

static func _has_exact_fields(value: Variant, fields: Array) -> bool:
	if not value is Dictionary or value.size() != fields.size():
		return false
	for field in fields:
		if not value.has(field):
			return false
	return true

static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and floor(float(value)) == value

static func _int_in_range(value: Variant, minimum: int, maximum: int) -> bool:
	return _integer(value) and value >= minimum and value <= maximum

static func _invalid_command(path: String) -> Dictionary:
	return Adapter.fail("invalid_replay_command", path)

static func _command(raw: Variant, path: String, max_ticks: int, previous_tick: int) -> Dictionary:
	if not _has_exact_fields(raw, COMMAND_FIELDS):
		return _invalid_command(path)
	if not _integer(raw.tick):
		return _invalid_command(path + ".tick")
	if raw.tick < 0 or raw.tick >= max_ticks:
		return Adapter.fail("replay_command_tick", path + ".tick")
	var tick := int(raw.tick)
	if tick < previous_tick:
		return Adapter.fail("replay_command_order", path + ".tick")
	if not _int_in_range(raw.side, 0, 1):
		return _invalid_command(path + ".side")
	if not raw.ids is Array or raw.ids.is_empty():
		return _invalid_command(path + ".ids")
	var ids: Array = []
	var seen := {}
	for i in raw.ids.size():
		if not _int_in_range(raw.ids[i], 0, MAX_ID):
			return _invalid_command("%s.ids[%d]" % [path, i])
		var id := int(raw.ids[i])
		if seen.has(id):
			return _invalid_command("%s.ids[%d]" % [path, i])
		seen[id] = true
		ids.append(id)
	if not raw.kind is String:
		return _invalid_command(path + ".kind")
	if raw.kind not in ["move", "stop", "attack"]:
		return Adapter.fail("unsupported_replay_command", path + ".kind")
	if not _int_in_range(raw.target_id, -1, MAX_ID):
		return _invalid_command(path + ".target_id")
	if not raw.point is Array or raw.point.size() != 2 or not _number(raw.point[0]) or not _number(raw.point[1]):
		return _invalid_command(path + ".point")
	var point := Vector2(raw.point[0], raw.point[1])
	if not point.is_finite():
		return _invalid_command(path + ".point")
	if not raw.args is Dictionary or not raw.args.is_empty():
		return _invalid_command(path + ".args")
	return {"ok": true, "value": {"tick": tick, "side": int(raw.side), "ids": ids,
		"kind": raw.kind, "target_id": int(raw.target_id), "point": point, "args": {}}}

static func run(bundle: Variant, replay_file_sha256: String) -> Dictionary:
	if not _has_exact_fields(bundle, ENVELOPE_FIELDS):
		return Adapter.fail("invalid_replay_envelope", "$")
	if not bundle.format is String or bundle.format != FORMAT:
		return Adapter.fail("unsupported_replay_format", "format")
	var created := Adapter.create(bundle.input)
	if not created.ok:
		var path: String = created.path
		return Adapter.fail(created.error, "input" if path == "$" else "input." + path)
	var result := _play_and_close(created, bundle.commands)
	if not result.ok:
		return result
	result["meta"] = created.meta
	result.meta["executor"] = "replay"
	result.meta["replay_format"] = FORMAT
	result.meta["replay_file_sha256"] = replay_file_sha256
	result.meta["commands_consumed"] = result.commands_consumed
	result.erase("commands_consumed")
	return result

static func _play_and_close(created: Dictionary, raw_commands: Variant) -> Dictionary:
	var owner: OperationPrivateState = created.owner
	var result := _play(owner, created.policy, created.max_ticks, raw_commands)
	owner.close()
	return result

static func _play(owner: OperationPrivateState, policy: String, max_ticks: int, raw_commands: Variant) -> Dictionary:
	if policy != "none":
		return Adapter.fail("unsupported_replay_policy", "input.policy")
	if max_ticks > MAX_TICKS:
		return Adapter.fail("replay_tick_limit", "input.max_ticks")
	if not raw_commands is Array:
		return _invalid_command("commands")
	if raw_commands.size() > MAX_COMMANDS:
		return Adapter.fail("replay_command_limit", "commands")
	var commands: Array = []
	var previous_tick := -1
	for i in raw_commands.size():
		var parsed := _command(raw_commands[i], "commands[%d]" % i, max_ticks, previous_tick)
		if not parsed.ok:
			return parsed
		commands.append(parsed.value)
		previous_tick = parsed.value.tick

	var events: Array = []
	var consumed := 0
	var read := owner.summary()
	if not read.ok:
		return read
	while not read.summary.over and read.summary.tick < max_ticks:
		var next := consumed
		while next < commands.size() and commands[next].tick == read.summary.tick:
			var queued := owner.queue(commands[next])
			if not queued.ok:
				return Adapter.fail(queued.error, "commands[%d]" % next)
			next += 1
		var advanced := owner.advance()
		if not advanced.ok:
			return Adapter.fail(advanced.error, "owner")
		consumed = next
		var drained := owner.drain_events()
		if not drained.ok:
			return Adapter.fail(drained.error, "owner")
		events.append_array(drained.events)
		read = owner.summary()
		if not read.ok:
			return read
	if consumed < commands.size():
		return Adapter.fail("replay_unconsumed_command", "commands[%d].tick" % consumed)
	return {"ok": true, "summary": read.summary, "events": events, "event_count": events.size(),
		"commands_consumed": consumed}
