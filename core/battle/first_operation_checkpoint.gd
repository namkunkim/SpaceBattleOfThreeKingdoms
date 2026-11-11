extends RefCounted

const FORMAT := "pc-first-operation-internal-replay/1"
const MAX_TICKS := 12000
const MAX_COUNT := 2147483647
const MAX_BATCH := 256
const FIELDS := ["format", "request", "operation_id", "rules_digest", "source_digest",
	"effective_digest", "tick", "clock_ms", "commands", "pending", "event_cursor",
	"proposal_serial", "state_digest"]
const REQUEST_FIELDS := ["capability", "definition_id", "definition_version", "roster_id",
	"seed", "difficulty", "mode", "route_id"]

const COMPATIBILITY := "res://data/first_operation_checkpoint_compat.json"

class RestoreJob extends RefCounted:
	var _owner: RefCounted
	var _packet: Dictionary
	var _tick := 0
	var _cursor := 0
	var _closed_error := ""

	func _init(owner: RefCounted, packet: Dictionary) -> void:
		_owner = owner
		_packet = packet

	# A committed tick is indivisible. An exhausted budget leaves the job
	# between ticks, including before final verification.
	func step(budget_usec: int) -> Dictionary:
		if _owner == null:
			return {"ok": false, "error": _closed_error, "path": "restore_job"}
		if budget_usec <= 0:
			return {"ok": false, "error": "invalid_restore_budget", "path": "restore_job.budget_usec"}
		var start := Time.get_ticks_usec()
		var commands: Array = _packet.commands
		while _tick < _packet.tick:
			var batch: Array = []
			if _cursor < commands.size() and commands[_cursor].tick == _tick:
				batch = commands[_cursor].batch
			var advanced: Dictionary = _owner._replay_checkpoint_tick(batch, "packet.commands[%d].batch" % _cursor)
			if not advanced.ok:
				cancel()
				return advanced
			if not batch.is_empty():
				_cursor += 1
			_tick += 1
			if Time.get_ticks_usec() - start >= budget_usec:
				return {"ok": true, "done": false, "tick": _tick, "total": _packet.tick}
		var verified: Dictionary = _owner._finish_prepared_checkpoint(_packet)
		if not verified.ok:
			cancel()
			return verified
		var restored := _owner
		_owner = null
		_packet = {}
		_closed_error = "restore_job_finished"
		return {"ok": true, "done": true, "owner": restored}

	func cancel() -> void:
		if _owner == null:
			return
		_owner.close()
		_owner = null
		_packet = {}
		_closed_error = "restore_job_cancelled"

static func begin_restore(packet: Variant, prepare: Callable, definition_id: String) -> Dictionary:
	var validated := _normalize(packet, definition_id)
	if not validated.ok:
		return validated
	var value: Dictionary = validated.packet
	if not _compatible_rules(value.rules_digest, rules_digest()):
		return fail("checkpoint_rules_mismatch", "packet.rules_digest")
	var candidate: Dictionary = prepare.call(value.request, value.operation_id)
	if not candidate.ok:
		return candidate
	var owner: RefCounted = candidate.owner
	var checked: Dictionary = owner._begin_prepared_checkpoint(value)
	if not checked.ok:
		owner.close()
		return checked
	return {"ok": true, "job": RestoreJob.new(owner, value)}

static func prepare_restore(packet: Variant, prepare: Callable, definition_id: String) -> Dictionary:
	var begun := begin_restore(packet, prepare, definition_id)
	if not begun.ok:
		return begun
	var job: RestoreJob = begun.job
	var result := job.step(100000)
	while result.ok and not result.done:
		result = job.step(100000)
	return {"ok": true, "owner": result.owner} if result.ok else result

static func _compatible_rules(saved: String, actual: String) -> bool:
	if saved == actual:
		return true
	if actual.is_empty() or not FileAccess.file_exists(COMPATIBILITY):
		return false
	var pair: Variant = JSON.parse_string(FileAccess.get_file_as_string(COMPATIBILITY))
	return (_has_fields(pair, ["current_digest", "previous_digest"]) and actual == pair.current_digest
		and saved == pair.previous_digest)

static func rules_digest() -> String:
	if OS.has_feature("template"):
		return _packaged_rules_digest()
	var root := "res://core/battle"
	var scripts: Array[String] = []
	_collect_scripts(root, scripts)
	if scripts.is_empty():
		return ""
	scripts.sort()
	var inventory: Array = [Engine.get_version_info().string]
	for path in scripts:
		var digest := FileAccess.get_sha256(path)
		if digest.is_empty():
			return ""
		inventory.append([path, digest])
	return digest_value(inventory)

# Reconstruct the original sorted source inventory from the audited token export.
static func _packaged_rules_digest() -> String:
	const MANIFEST := "res://data/first_operation_replay_fingerprint.json"
	const ANCHOR := "res://data/operation_checkpoint_anchor.gd"
	if not FileAccess.file_exists(MANIFEST) or not ResourceLoader.exists(ANCHOR):
		return ""
	var text := FileAccess.get_file_as_string(MANIFEST)
	var anchor := load(ANCHOR) as Script
	if anchor == null or anchor.get_script_constant_map().get("REPLAY_SHA256") != text.sha256_text():
		return ""
	var manifest: Variant = JSON.parse_string(text)
	if not _has_fields(manifest, ["format", "engine", "sources", "tokens", "remaps"]) \
			or manifest.format != "first-operation-replay-fingerprint/1":
		return ""
	var version := Engine.get_version_info()
	var engine := "%d.%d.%d.%s.%s" % [version.major, version.minor, version.patch, version.status, str(version.hash).left(9)]
	if manifest.engine != engine or not manifest.sources is Dictionary or manifest.sources.is_empty() \
			or not manifest.tokens is Dictionary or not manifest.remaps is Dictionary:
		return ""
	var paths: Array = manifest.sources.keys()
	if manifest.tokens.size() != paths.size() or manifest.remaps.size() != paths.size():
		return ""
	paths.sort()
	var inventory: Array = [version.string]
	for name: String in paths:
		if not name.ends_with(".gd") or name.is_absolute_path() or name.simplify_path() != name or name.begins_with("../"):
			return ""
		var source := "res://core/battle/" + name
		if OS.has_feature("template") and FileAccess.file_exists(source):
			return ""
		var digest: Variant = manifest.sources[name]
		if not digest is String or digest.length() != 64 or not digest.is_valid_hex_number() \
				or digest.begins_with("+") or digest.begins_with("-") or digest != digest.to_lower():
			return ""
		var token := FileAccess.get_sha256(source + "c")
		var remap := FileAccess.get_sha256(source + ".remap")
		if token.is_empty() or remap.is_empty() or token != manifest.tokens.get(name) or remap != manifest.remaps.get(name):
			return ""
		inventory.append([source, digest])
	return digest_value(inventory)


static func _collect_scripts(directory: String, scripts: Array[String]) -> void:
	for file in DirAccess.get_files_at(directory):
		if file.ends_with(".gd"):
			scripts.append(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory):
		_collect_scripts(directory.path_join(child), scripts)

static func digest_value(value: Variant) -> String:
	return var_to_bytes(value).hex_encode().sha256_text()

static func _normalize(packet: Variant, definition_id: String) -> Dictionary:
	if not _has_fields(packet, FIELDS) or packet.format != FORMAT:
		return fail("unsupported_checkpoint_format", "packet.format")
	for key in ["rules_digest", "source_digest", "effective_digest", "state_digest"]:
		if not _hex(packet[key], 64):
			return fail("invalid_checkpoint_digest", "packet." + key)
	var prefix := definition_id + "/"
	var operation_id: Variant = packet.operation_id
	if not operation_id is String or not operation_id.begins_with(prefix) or not _hex(operation_id.trim_prefix(prefix), 32):
		return fail("invalid_checkpoint_operation_id", "packet.operation_id")
	if not _has_fields(packet.request, REQUEST_FIELDS):
		return fail("invalid_checkpoint_request", "packet.request")
	var request := {}
	for key in REQUEST_FIELDS:
		var field: Variant = packet.request[key]
		if key in ["definition_version", "seed"]:
			if not _uint(field, 4294967295):
				return fail("invalid_checkpoint_request", "packet.request." + key)
			request[key] = int(field)
		else:
			if not field is String or field.length() > 128:
				return fail("invalid_checkpoint_request", "packet.request." + key)
			request[key] = field

	if not _uint(packet.tick, MAX_TICKS) or not _uint(packet.clock_ms, MAX_TICKS * 100) or int(packet.clock_ms) != int(packet.tick) * 100:
		return fail("invalid_checkpoint_clock", "packet.clock_ms")
	if int(packet.tick) == MAX_TICKS:
		return fail("checkpoint_terminal", "packet.tick")
	for key in ["event_cursor", "proposal_serial"]:
		if not _uint(packet[key], MAX_COUNT):
			return fail("invalid_checkpoint_counter", "packet." + key)
	if int(packet.proposal_serial) < int(packet.tick):
		return fail("invalid_checkpoint_counter", "packet.proposal_serial")
	var tick := int(packet.tick)
	var pending := _normalize_commands(packet.pending, "packet.pending")
	if not pending.ok:
		return pending
	if not packet.commands is Array or packet.commands.size() > tick:
		return fail("invalid_checkpoint_commands", "packet.commands")
	var commands: Array[Dictionary] = []
	var previous := -1
	for i in packet.commands.size():
		var row: Variant = packet.commands[i]
		var path := "packet.commands[%d]" % i
		if not _has_fields(row, ["tick", "batch"]) or not _uint(row.tick, tick - 1) or int(row.tick) <= previous:
			return fail("invalid_checkpoint_command_tick", path + ".tick")
		var batch := _normalize_commands(row.batch, path + ".batch")
		if not batch.ok:
			return batch
		if batch.commands.is_empty():
			return fail("invalid_checkpoint_commands", path + ".batch")
		previous = int(row.tick)
		commands.append({"tick": previous, "batch": batch.commands})
	return {"ok": true, "packet": {
		"format": FORMAT, "request": request, "operation_id": operation_id,
		"rules_digest": packet.rules_digest, "source_digest": packet.source_digest, "effective_digest": packet.effective_digest,
		"tick": tick, "clock_ms": int(packet.clock_ms), "commands": commands, "pending": pending.commands,
		"event_cursor": int(packet.event_cursor), "proposal_serial": int(packet.proposal_serial), "state_digest": packet.state_digest,
	}}

static func _normalize_commands(value: Variant, path: String) -> Dictionary:
	if not value is Array or value.size() > MAX_BATCH:
		return fail("invalid_checkpoint_commands", path)
	var normalized: Array[Dictionary] = []
	for i in value.size():
		var command: Variant = value[i]
		var command_path := "%s[%d]" % [path, i]
		if not command is Dictionary or command.get("kind") not in ["move", "stop", "withdraw", "finalize_withdrawal"]:
			return fail("invalid_checkpoint_command", command_path)
		var kind: String = command.kind
		if kind == "move":
			if not _has_fields(command, ["kind", "goal"]) or not _uint(command.goal, 4):
				return fail("invalid_checkpoint_command", command_path)
			normalized.append({"kind": kind, "goal": int(command.goal)})
		else:
			if not _has_fields(command, ["kind"]):
				return fail("invalid_checkpoint_command", command_path)
			normalized.append({"kind": kind})
	return {"ok": true, "commands": normalized}

static func _has_fields(value: Variant, fields: Array) -> bool:
	return value is Dictionary and value.size() == fields.size() and fields.all(func(key): return value.has(key))

static func _uint(value: Variant, maximum: int) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return is_finite(number) and number >= 0.0 and number <= maximum and floorf(number) == number

static func _hex(value: Variant, length: int) -> bool:
	if not value is String or value.length() != length:
		return false
	for character in value:
		if not character in "0123456789abcdef":
			return false
	return true

static func fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
