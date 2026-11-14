extends RefCounted
## Evaluation-only binary checkpoints. Caller supplies a trusted bind; no public save registration.
const FORMAT := "cross-counter-evaluation-checkpoint/1"
const FILE_FORMAT := "cross-counter-evaluation-file/1"
const MAX_TICKS := 650
const MAX_BATCH := 32
const MAX_BYTES := 2097152
const FIELDS := ["format", "request", "operation_id", "rules_digest", "source_digest", "effective_digest",
    "tick", "clock_ms", "seed", "bootstrap_done", "counter_phase", "commands", "pending",
    "event_cursor", "emitted_events", "state_digest"]

static func fail(error: String, path := "packet") -> Dictionary:
    return {"ok": false, "error": error, "path": path}

static func sha(bytes: PackedByteArray) -> String:
    var context := HashingContext.new()
    context.start(HashingContext.HASH_SHA256)
    context.update(bytes)
    return context.finish().hex_encode()

static func packet_digest(packet: Dictionary) -> String:
    return sha(var_to_bytes(packet))

static func _rule_paths(directory: String, paths: Array[String]) -> void:
    for file in DirAccess.get_files_at(directory):
        if file.ends_with(".gd"): paths.append(directory.path_join(file))
    for child in DirAccess.get_directories_at(directory):
        _rule_paths(directory.path_join(child), paths)

static func rules_digest() -> String:
    var paths: Array[String] = []
    _rule_paths("res://core", paths)
    paths.append_array(["res://tests/support/cross_counter_evaluation.gd",
        "res://tests/support/cross_counter_evaluation_witness.gd",
        "res://tests/support/cross_counter_evaluation_checkpoint.gd"])
    paths.sort()
    var pins := {"engine": Engine.get_version_info().string, "sources": {}}
    for path in paths: pins.sources[path] = FileAccess.get_sha256(path)
    return packet_digest(pins)

static func from_diagnostic(value: Dictionary) -> Dictionary:
    var packet := {"format": FORMAT, "request": value.request.duplicate(true),
        "operation_id": value.operation_id, "rules_digest": value.rules_digest,
        "source_digest": value.meta.source_digest, "effective_digest": value.meta.effective_digest,
        "tick": value.tick, "clock_ms": value.clock_ms, "seed": value.seed,
        "bootstrap_done": value.bootstrap_done, "counter_phase": value.counter_phase,
        "commands": value.commands.duplicate(true), "pending": value.pending.duplicate(true),
        "event_cursor": value.event_cursor, "emitted_events": value.emitted_events,
        "state_digest": value.state_digest}
    return {"ok": true, "packet": packet}

static func capture(owner: RefCounted) -> Dictionary:
    var result: Dictionary = owner.capture_checkpoint()
    if not result.ok: return result
    return from_diagnostic(result.packet)

# Only call this on a trusted capture or independently validated authority record.
static func binding_for(packet: Dictionary) -> Dictionary:
    return {"operation_id": packet.operation_id, "request_digest": packet_digest(packet.request),
        "packet_sha256": packet_digest(packet)}

static func _fields(value: Variant, keys: Array) -> bool:
    return value is Dictionary and value.size() == keys.size() and keys.all(func(key): return value.has(key))

static func _integer(value: Variant, maximum: int) -> bool:
    return typeof(value) == TYPE_INT and value >= 0 and value <= maximum

static func _digest(value: Variant) -> bool:
    if not value is String or value.length() != 64: return false
    for character in value:
        if not character in "0123456789abcdef": return false
    return true

static func validate(packet: Variant, bind: Variant) -> Dictionary:
    if not _fields(packet, FIELDS) or packet.format != FORMAT: return fail("invalid_checkpoint_shape")
    if not _fields(bind, ["operation_id", "request_digest", "packet_sha256"]): return fail("invalid_checkpoint_bind", "bind")
    if not packet.request is Dictionary or not packet.operation_id is String: return fail("invalid_checkpoint_identity")
    if not _digest(bind.request_digest) or not _digest(bind.packet_sha256): return fail("invalid_checkpoint_bind", "bind")
    if packet.operation_id != bind.operation_id or packet_digest(packet.request) != bind.request_digest \
            or packet_digest(packet) != bind.packet_sha256:
        return fail("checkpoint_bind_mismatch", "bind")
    for key in ["rules_digest", "source_digest", "effective_digest", "state_digest"]:
        if not _digest(packet[key]): return fail("invalid_checkpoint_digest", key)
    if packet.rules_digest != rules_digest(): return fail("checkpoint_rules_mismatch", "rules_digest")
    if not _integer(packet.tick, MAX_TICKS) or not _integer(packet.clock_ms, MAX_TICKS * 100) \
            or packet.clock_ms != packet.tick * 100 or not _integer(packet.seed, 4294967295):
        return fail("invalid_checkpoint_clock")
    if typeof(packet.bootstrap_done) != TYPE_BOOL or not _integer(packet.counter_phase, 1): return fail("invalid_checkpoint_phase")
    if not _integer(packet.event_cursor, 1000000) or not _integer(packet.emitted_events, 1000000) \
            or packet.event_cursor > packet.emitted_events: return fail("invalid_checkpoint_cursor")
    if not packet.commands is Array or not packet.pending is Array or packet.pending.size() > MAX_BATCH:
        return fail("invalid_checkpoint_commands")
    if not packet.bootstrap_done and (packet.tick != 0 or packet.counter_phase != 0 \
            or not packet.commands.is_empty() or not packet.pending.is_empty()):
        return fail("invalid_unstarted_checkpoint")
    var previous := -1
    for row in packet.commands:
        if not _fields(row, ["tick", "batch"]) or not _integer(row.tick, MAX_TICKS) \
                or row.tick <= previous or row.tick >= packet.tick or not row.batch is Array \
                or row.batch.is_empty() or row.batch.size() > MAX_BATCH:
            return fail("invalid_checkpoint_history")
        previous = row.tick
    return {"ok": true, "packet": packet.duplicate(true)}

static func _file_path(path: String) -> Dictionary:
    var root := OS.get_environment("SBTK_CROSS_COUNTER_ISOLATED_ROOT").replace("\\", "/").trim_suffix("/")
    var actual := OS.get_user_data_dir().replace("\\", "/")
    if root.is_empty() or not actual.begins_with(root + "/"): return fail("isolated_profile_required", "path")
    const PREFIX := "user://cross-counter-evaluation/"
    if not path.begins_with(PREFIX): return fail("unsupported_checkpoint_path", "path")
    var name := path.trim_prefix(PREFIX)
    var regex := RegEx.new()
    regex.compile("^[a-z0-9-]+[.]ccpeval$")
    if regex.search(name) == null: return fail("unsupported_checkpoint_path", "path")
    return {"ok": true}

static func write_new(path: String, packet: Dictionary) -> Dictionary:
    var allowed := _file_path(path)
    if not allowed.ok: return allowed
    if FileAccess.file_exists(path): return fail("checkpoint_exists", "path")
    var bind := binding_for(packet)
    var valid := validate(packet, bind)
    if not valid.ok: return valid
    var body := var_to_bytes(packet)
    var bytes := var_to_bytes({"format": FILE_FORMAT, "body": body, "sha256": sha(body)})
    if bytes.size() > MAX_BYTES: return fail("checkpoint_too_large", "path")
    var directory := ProjectSettings.globalize_path(path.get_base_dir())
    if DirAccess.make_dir_recursive_absolute(directory) != OK: return fail("checkpoint_directory", "path")
    var file := FileAccess.open(path, FileAccess.WRITE)
    if file == null: return fail("checkpoint_write", "path")
    file.store_buffer(bytes)
    file.flush()
    var error := file.get_error()
    file.close()
    if error != OK: return fail("checkpoint_write", "path")
    return {"ok": true, "binding": bind, "file_sha256": sha(bytes)}

static func read_bound(path: String, bind: Dictionary) -> Dictionary:
    var allowed := _file_path(path)
    if not allowed.ok: return allowed
    var file := FileAccess.open(path, FileAccess.READ)
    if file == null: return fail("checkpoint_read", "path")
    var size := file.get_length()
    if size <= 0 or size > MAX_BYTES:
        file.close()
        return fail("checkpoint_too_large", "path")
    var bytes := file.get_buffer(size)
    file.close()
    var envelope: Variant = bytes_to_var(bytes) # No objects-enabled decoder.
    if not _fields(envelope, ["format", "body", "sha256"]) or envelope.format != FILE_FORMAT \
            or not envelope.body is PackedByteArray or not _digest(envelope.sha256):
        return fail("invalid_checkpoint_file")
    if sha(envelope.body) != envelope.sha256: return fail("checkpoint_file_hash")
    var packet: Variant = bytes_to_var(envelope.body)
    return validate(packet, bind)

class RestoreJob extends RefCounted:
    var _owner: RefCounted
    var _packet: Dictionary
    var _tick := 0
    var _cursor := 0
    var _finished := false

    func _init(owner: RefCounted, packet: Dictionary) -> void:
        _owner = owner
        _packet = packet

    func step(budget_usec: int) -> Dictionary:
        if _owner == null: return {"ok": false, "error": "restore_job_closed", "path": "job"}
        if budget_usec <= 0: return {"ok": false, "error": "invalid_restore_budget", "path": "job"}
        var start := Time.get_ticks_usec()
        while _tick < _packet.tick:
            var batch: Array = []
            if _cursor < _packet.commands.size() and _packet.commands[_cursor].tick == _tick:
                batch = _packet.commands[_cursor].batch
            var advanced: Dictionary = _owner._replay_checkpoint_tick(batch, "commands[%d]" % _cursor)
            if not advanced.ok:
                cancel()
                return advanced
            if not batch.is_empty(): _cursor += 1
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
        _finished = true
        return {"ok": true, "done": true, "owner": restored}

    func cancel() -> void:
        if _owner != null: _owner.close()
        _owner = null
        _packet = {}

    func _notification(what: int) -> void:
        if what == NOTIFICATION_PREDELETE and _owner != null: _owner.close()

static func begin_restore(packet: Variant, bind: Variant, prepare: Callable) -> Dictionary:
    var valid := validate(packet, bind)
    if not valid.ok: return valid
    var prepared: Dictionary = prepare.call(valid.packet.request, valid.packet.operation_id)
    if not prepared.ok: return prepared
    var owner: RefCounted = prepared.owner
    var checked: Dictionary = owner._begin_prepared_checkpoint(valid.packet)
    if not checked.ok:
        owner.close()
        return checked
    return {"ok": true, "job": RestoreJob.new(owner, valid.packet)}

static func prepare_restore(packet: Variant, bind: Variant, prepare: Callable) -> Dictionary:
    var begun := begin_restore(packet, bind, prepare)
    if not begun.ok: return begun
    var job: RefCounted = begun.job
    var result: Dictionary = job.step(100000)
    while result.ok and not result.done: result = job.step(100000)
    return {"ok": true, "owner": result.owner} if result.ok else result
