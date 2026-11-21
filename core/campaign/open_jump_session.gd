extends RefCounted
## Replay checkpoint for this campaign only. Never writes the legacy first-operation slot.
const Definition = preload("res://core/campaign/open_jump_definition.gd")
const Runtime = preload("res://core/campaign/open_jump_runtime.gd")
const Store = preload("res://scripts/first_operation_save_store.gd")
const RuleIdentity := preload("res://scripts/campaign/open_jump_rule_identity.gd")
const FORMAT := "red-cliffs-open-jump-checkpoint"
const SLOT := "user://red-cliffs-open-jump.save"
const MAX_TICKS := 108000 # Three hours at the native 10 Hz; bound synchronous replay work.
const MAX_COMMANDS := 50000
var runtime: RefCounted
var _rules_hash := ""
var _definition_hash := ""

static func fresh(seed_id: int = 208) -> Dictionary:
	if seed_id < 0 or seed_id > 2147483647:
		return _fail("invalid_seed")
	var identity := rules_hash()
	if identity.is_empty():
		return _fail("checkpoint_rules_unavailable")
	var definition: Dictionary = Definition.load_definition()
	if not definition.get("ok", false):
		return definition
	var session = load("res://core/campaign/open_jump_session.gd").new()
	session.runtime = Runtime.new(definition, seed_id)
	session._rules_hash = identity
	session._definition_hash = canonical(definition).sha256_text()
	return {"ok": true, "session": session}

func capture() -> Dictionary:
	if runtime.sim.st.tick > MAX_TICKS or runtime.journal.size() > MAX_COMMANDS:
		return _fail("checkpoint_limit")
	return {"ok": true, "packet": {
		"format": FORMAT, "version": 1, "seed": runtime.seed,
		"tick": runtime.sim.st.tick, "rules_hash": _rules_hash,
		"definition_hash": _definition_hash,
		"commands": _json_value(runtime.journal),
		"witness": canonical(runtime.snapshot()).sha256_text()}}

func save_to(path: String = SLOT) -> Dictionary:
	var result := capture()
	return Store.write(result.packet, path) if result.ok else result

static func load_from(path: String = SLOT) -> Dictionary:
	var saved: Dictionary = Store.read(path)
	return restore(saved.payload) if saved.ok else saved

## Return a fully verified candidate. Caller swaps sessions only on success.
static func restore(packet: Dictionary) -> Dictionary:
	if packet.size() != 8 or packet.get("format") != FORMAT or packet.get("version") != 1:
		return _fail("invalid_checkpoint")
	for field in ["seed", "tick"]:
		if not _integer(packet.get(field)):
			return _fail("invalid_checkpoint")
	if packet.seed < 0 or packet.seed > 2147483647 or packet.tick < 0 or packet.tick > MAX_TICKS:
		return _fail("checkpoint_limit")
	for field in ["rules_hash", "definition_hash", "witness"]:
		if typeof(packet.get(field)) != TYPE_STRING or packet[field].length() != 64:
			return _fail("invalid_checkpoint")
	if typeof(packet.get("commands")) != TYPE_ARRAY or packet.commands.size() > MAX_COMMANDS:
		return _fail("invalid_commands")
	var previous_tick := -1
	for command in packet.commands:
		if typeof(command) != TYPE_DICTIONARY or not _integer(command.get("tick")) or command.tick < previous_tick or command.tick < 0 or command.tick > packet.tick:
			return _fail("invalid_commands")
		previous_tick = int(command.tick)
	var built := fresh(int(packet.seed))
	if not built.ok:
		return built
	var session: RefCounted = built.session
	if not RuleIdentity.matches(packet.rules_hash, session._rules_hash) or packet.definition_hash != session._definition_hash:
		return _fail("checkpoint_rules_changed")
	var runtime: RefCounted = session.runtime
	var index := 0
	for tick in int(packet.tick) + 1:
		while index < packet.commands.size() and int(packet.commands[index].tick) == tick:
			var command: Dictionary = packet.commands[index].duplicate(true)
			command.erase("tick")
			var accepted: Dictionary = runtime.queue(command)
			if not accepted.get("ok", false):
				return _fail("checkpoint_command_rejected")
			index += 1
		if tick < int(packet.tick):
			var advanced: Dictionary = runtime.advance()
			if not advanced.get("ok", false) or runtime.sim.st.tick != tick + 1:
				return _fail("checkpoint_replay_stalled")
			runtime.drain_events()
	if canonical(runtime.snapshot()).sha256_text() != packet.witness:
		return _fail("checkpoint_state_mismatch")
	# Do not replay historical briefing/deployment notifications into a new UI.
	runtime.drain_events()
	return {"ok": true, "session": session}

static func canonical(value: Variant) -> String:
	return JSON.stringify(_json_value(value), "", true, true)

static func _json_value(value: Variant) -> Variant:
	if typeof(value) == TYPE_STRING_NAME:
		return str(value)
	if value is Vector2:
		return [_json_value(value.x), _json_value(value.y)]
	if value is Dictionary:
		var out := {}
		for key in value:
			out[str(key)] = _json_value(value[key])
		return out
	if value is Array:
		var out := []
		for item in value:
			out.append(_json_value(item))
		return out
	if typeof(value) == TYPE_FLOAT and is_finite(value) and value == floor(value) and abs(value) < 9007199254740991:
		return int(value)
	return value

static func rules_hash() -> String:
	return RuleIdentity.current()

static func _integer(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and float(value) == floor(float(value))

static func _fail(error: String) -> Dictionary:
	return {"ok": false, "error": error}

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and runtime != null:
		runtime.close()

