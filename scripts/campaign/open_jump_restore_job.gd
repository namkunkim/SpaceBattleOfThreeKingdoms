extends RefCounted
## Frame-budgeted replay of the v1 checkpoint. Keep the hashed combat and session scripts intact.
const Session := preload("res://core/campaign/open_jump_session.gd")
const FRAME_BUDGET_USEC := 8000

var _path: String
var _read_pending := true
var _packet: Dictionary
var _candidate: RefCounted
var _validated := 0
var _previous_tick := -1
var _index := 0
var _tick := 0
var _total := 0
var _result := {}

func _init(path: String) -> void:
	_path = path

func step(budget_usec: int = FRAME_BUDGET_USEC) -> Dictionary:
	if not _result.is_empty():
		return _result
	if _read_pending:
		var saved := Session.Store.read(_path)
		_read_pending = false
		if not saved.ok:
			_result = saved
			return _result
		_packet = saved.payload
		if _packet.size() != 8 or _packet.get("format") != Session.FORMAT or _packet.get("version") != 1:
			return _fail("invalid_checkpoint")
		for field in ["seed", "tick"]:
			if not Session._integer(_packet.get(field)):
				return _fail("invalid_checkpoint")
		if _packet.seed < 0 or _packet.seed > 2147483647 or _packet.tick < 0 or _packet.tick > Session.MAX_TICKS:
			return _fail("checkpoint_limit")
		for field in ["rules_hash", "definition_hash", "witness"]:
			if typeof(_packet.get(field)) != TYPE_STRING or _packet[field].length() != 64:
				return _fail("invalid_checkpoint")
		if typeof(_packet.get("commands")) != TYPE_ARRAY or _packet.commands.size() > Session.MAX_COMMANDS:
			return _fail("invalid_commands")
		_total = int(_packet.tick)
		return _progress()

	var deadline := Time.get_ticks_usec() + maxi(1, budget_usec)
	var commands: Array = _packet.commands
	if _candidate == null:
		while _validated < commands.size():
			var command: Variant = commands[_validated]
			if typeof(command) != TYPE_DICTIONARY or not Session._integer(command.get("tick")) or command.tick < _previous_tick or command.tick < 0 or command.tick > _total:
				return _fail("invalid_commands")
			_previous_tick = int(command.tick)
			_validated += 1
			if Time.get_ticks_usec() >= deadline:
				return _progress()
		var built := Session.fresh(int(_packet.seed))
		if not built.ok:
			_result = built
			return _result
		_candidate = built.session
		if not Session.RuleIdentity.matches(_packet.rules_hash, _candidate._rules_hash) or _packet.definition_hash != _candidate._definition_hash:
			return _fail("checkpoint_rules_changed")
		return _progress()

	var runtime: RefCounted = _candidate.runtime
	while true:
		while _index < commands.size() and int(commands[_index].tick) == _tick:
			var command: Dictionary = commands[_index].duplicate(true)
			command.erase("tick")
			if not runtime.queue(command).get("ok", false):
				return _fail("checkpoint_command_rejected")
			_index += 1
			if Time.get_ticks_usec() >= deadline:
				return _progress()
		if _tick == _total:
			if Session.canonical(runtime.snapshot()).sha256_text() != _packet.witness:
				return _fail("checkpoint_state_mismatch")
			runtime.drain_events()
			_result = {"ok": true, "done": true, "session": _candidate}
			_candidate = null
			_packet.clear()
			return _result
		if not runtime.advance().get("ok", false) or runtime.sim.st.tick != _tick + 1:
			return _fail("checkpoint_replay_stalled")
		runtime.drain_events()
		_tick += 1
		if Time.get_ticks_usec() >= deadline:
			return _progress()
	return _progress()

func _progress() -> Dictionary:
	return {"ok": true, "done": false, "tick": _tick, "total": _total}

func cancel() -> void:
	_fail("checkpoint_cancelled")

func _fail(error: String) -> Dictionary:
	_candidate = null
	_packet.clear()
	_result = {"ok": false, "error": error}
	return _result