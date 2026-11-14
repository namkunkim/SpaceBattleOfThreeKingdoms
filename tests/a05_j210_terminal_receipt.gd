extends SceneTree
## Test-only recording of a fresh J210 execution and its real O07 terminal receipt.
## This artifact is not a product replay format and does not grant payment authority.
const Host := preload("res://scenes/RestrictedOperationHost.tscn")
const Durable := preload("res://scripts/o07_supply_owner.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
var fixtures := ""
const PINS := {
	"j210-host.json": "da996e2de32de23e13e142e49d73b38b78784b1cdcbbf424ef780c9b87c5725a",
	"j210-replay.json": "4293251445fd2ebc1a6f5fc4ea3614b08b3b345d7b11eaf15d166d779897196a",
	"j210-replay-result.json": "021797aa69db525274418cd25c05e505525ee26b39ba94430487c26323cab909",
}
var checks := 0
var failures := 0
var output := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	output = OS.get_environment("SBTK_A05_RECEIPT_ROOT").replace("\\", "/").trim_suffix("/")
	fixtures = output + "/fixtures/"
	var profile := OS.get_environment("APPDATA").replace("\\", "/").trim_suffix("/")
	var isolated := output.is_absolute_path() and DirAccess.dir_exists_absolute(output) \
		and profile == output + "/profile/roaming" \
		and ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(profile + "/")
	if not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless" and isolated,
			"Windows headless with a new explicitly isolated profile"):
		_finish()
		return
	if not _check(OS.get_cmdline_user_args() == PackedStringArray([Durable.HOST_ARG]) \
			and ClassDB.class_exists(&"O07Win32"), "actual native O07 host selected"):
		_finish()
		return
	for name: String in PINS:
		if not _check(FileAccess.get_sha256(fixtures + name) == PINS[name], "frozen bytes " + name):
			_finish()
			return
	for path: String in [Durable.HOST_SLOT, Durable.HOST_SLOT + Store.PREVIOUS,
			output + "/record.json", output + "/observations.bin", output + "/terminal-slot.save", output + "/terminal-slot.previous"]:
		if not _check(not FileAccess.file_exists(path), "no existing artifact " + path.get_file()):
			_finish()
			return
	var host := Host.instantiate()
	root.add_child(host)
	_record(host)
	host.free()
	_finish()

func _record(host: Node) -> void:
	var input: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixtures + "j210-host.json"))
	var replay: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixtures + "j210-replay.json"))
	var reference: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(fixtures + "j210-replay-result.json"))
	if not _check(replay.format == "p02/restricted-fresh-replay/1" and replay.commands.is_empty() \
			and replay.input == input and input.seed == 20824 and input.profile.profile_id == "i01a-synthetic" \
			and input.profile.ally[0].x == 420 and input.profile.foe[0].x == 470,
			"the exact J210 input belongs to the archived no-command replay"):
		return
	var runtime_input_sha := var_to_bytes(input).hex_encode().sha256_text()
	if not _check(runtime_input_sha == reference.meta.input_sha256, "typed input identity matches CLI archive"):
		return
	if not _check(host.load_runtime_file(fixtures + "j210-host.json").ok and host._supply_mode \
			and host._summary.tick == 0 and host._summary.clock_ms == 0, "actual host prepares J210 at C0"):
		return
	var frames: Array = [_frame(host)]
	if not _check(host.save_slot().ok and host._durable != null, "actual host starts a fresh native authority slot"):
		return
	var authority: RefCounted = host._durable
	var identity: String = authority._state.operation_id
	if not _check(not identity.is_empty() and authority._state.generation == 0 \
			and authority._state.receipts.is_empty() and authority.settlement_key().is_empty(), "C0 has its own identity and no receipts"):
		return
	var first: Dictionary = host.advance()
	if not _check(first.ok and first.committed.is_empty() and host._summary.tick == 1 \
			and host._summary.clock_ms == 100 and not host._summary.over, "first host tick commits 100 ms without settlement"):
		return
	frames.append(_frame(host))
	var second: Dictionary = host.advance()
	if not _check(second.ok and host._summary.tick == 2 and host._summary.clock_ms == 150 \
			and host._summary.end_ms == 150 and host._summary.over and host._summary.reason == "annihilation",
			"second host tick naturally settles at 150 ms"):
		return
	frames.append(_frame(host))
	var observed: Dictionary = authority.observe()
	var events: Array = observed.sim._events
	if not _check(JSON.parse_string(JSON.stringify(host._summary)) == reference.summary \
			and JSON.parse_string(JSON.stringify(events)) == reference.events,
			"complete terminal summary and ordered native events match the archived CLI"):
		return
	var key: String = authority.settlement_key()
	if not _check(key == identity + "/battle_settlement/1" and authority._state.generation == 2 \
			and authority._state.sequence == 1 and second.committed.size() == 1 and second.committed.has(key) \
			and authority._state.receipts.size() == 1, "one authentic terminal receipt belongs to this operation"):
		return
	var effect: Dictionary = second.committed[key]
	var digest := JSON.stringify(effect, "", true, true).sha256_text()
	if not _check(effect == {"tick": 2, "clock_ms": 150, "win": true, "reason": "annihilation", "result": {}} \
			and digest == authority._state.receipts[key] \
			and events.filter(func(event): return event.kind == "battle_end").size() == 1,
			"receipt digest covers the actual native terminal effect and exactly one end event"):
		return
	var stored := Store.read(Durable.HOST_SLOT)
	if not _check(stored.ok, "read the committed native slot envelope"):
		return
	var packet: Dictionary = bytes_to_var(Marshalls.base64_to_raw(stored.payload.snapshot))
	if not _check(packet.view == observed and stored.payload.operation_id == identity \
			and stored.payload.settlement_key == key and stored.payload.receipts[key] == digest,
			"persisted state witness and receipt agree with the live authority"):
		return
	var primary_sha := FileAccess.get_sha256(Durable.HOST_SLOT)
	var previous_sha := FileAccess.get_sha256(Durable.HOST_SLOT + Store.PREVIOUS)
	var verified: Dictionary = authority.read_current_terminal_outcome()
	if not _check(verified.ok and verified.outcome != null and verified.outcome.settlement_id == key \
			and verified.outcome.seed == 20824 and verified.outcome.mode == "o07_native" \
			and verified.outcome.reason == "annihilation" and is_equal_approx(verified.outcome.t_s, 0.15),
			"current-head receipt verification yields the real native outcome"):
		return
	if not _check(host._projection.outcome.result.is_empty() and observed.state.result.is_empty(),
			"raw native result remains empty; no product settlement is fabricated"):
		return
	if not _check(host.advance().get("error") == "host_not_running" \
			and authority.advance().get("error") == "operation_already_settled" \
			and authority.observe() == observed and FileAccess.get_sha256(Durable.HOST_SLOT) == primary_sha \
			and FileAccess.get_sha256(Durable.HOST_SLOT + Store.PREVIOUS) == previous_sha,
			"terminal rejection preserves the observation and both committed generations"):
		return
	var artifacts := {
		"observations.bin": var_to_bytes({"input": input, "replay": replay, "frames": frames,
			"native_effect": effect, "terminal_packet": packet, "receipt": stored.payload}),
		"terminal-slot.save": FileAccess.get_file_as_bytes(Durable.HOST_SLOT),
		"terminal-slot.previous": FileAccess.get_file_as_bytes(Durable.HOST_SLOT + Store.PREVIOUS),
	}
	var artifact_sha := {}
	for name: String in artifacts:
		if not _check(_write_new(output + "/" + name, artifacts[name]), "retain exact artifact " + name):
			return
		artifact_sha[name] = FileAccess.get_sha256(output + "/" + name)
	var record := {
		"format": "a05/j210-native-terminal-record/1", "product_replay": false,
		"validation": "native committed receipt and verified current-head readback; not a signature",
		"pid": OS.get_process_id(), "engine": Engine.get_version_info().string,
		"fixture_sha256": PINS, "runtime_input_sha256": runtime_input_sha,
		"operation_id": identity, "settlement_key": key, "generation": stored.payload.generation,
		"sequence": stored.payload.sequence, "receipt_digest": digest, "native_effect": effect,
		"terminal_summary": host._summary, "events": events, "clock_ms": [0, 100, 150],
		"verified_outcome": {"id": verified.outcome.settlement_id, "kind": verified.outcome.kind,
			"reason": verified.outcome.reason, "t_s": verified.outcome.t_s, "seed": verified.outcome.seed,
			"mode": verified.outcome.mode},
		"native_slot_sha256": primary_sha, "native_previous_sha256": previous_sha,
		"artifact_sha256": artifact_sha,
	}
	_check(_write_new(output + "/record.json", (JSON.stringify(record, "  ", true, true) + "\n").to_utf8_buffer()),
		"write the bound test-only receipt record")

func _frame(host: Node) -> Dictionary:
	return {"summary": host._summary.duplicate(true), "projection": host._projection.duplicate(true),
		"owner": host._operation.observe(), "display": host._view.text}

func _write_new(path: String, bytes: PackedByteArray) -> bool:
	if FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(bytes)
	file.flush()
	var ok := file.get_error() == OK
	file.close()
	return ok and FileAccess.get_file_as_bytes(path) == bytes

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print("A05_J210_RECEIPT_CHECK ", condition, " ", label)
	return condition

func _finish() -> void:
	print("A05_J210_TERMINAL_RECEIPT ", checks - failures, "/", checks)
	quit(0 if failures == 0 else 1)