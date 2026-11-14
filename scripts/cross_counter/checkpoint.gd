extends RefCounted
## Product checkpoint validation/replay. Storage supplies the trusted bind and owns disk I/O.
const FORMAT := "cross-counter-product-checkpoint/1"
const FILE_FORMAT := "cross-counter-product-file/1"
const MAX_TICKS := 650
const MAX_BATCH := 32
const MAX_BYTES := 2097152
const FIELDS := ["format", "request", "operation_id", "rules_digest", "source_digest", "effective_digest",
    "tick", "clock_ms", "seed", "bootstrap_done", "counter_phase", "counter_salvos", "settlement", "commands", "pending",
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

const NativeCheckpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const CODE := ["runtime.gd", "checkpoint.gd", "witness.gd", "outcome.gd"]
const CODE_ROOT := "res://scripts/cross_counter/"

static func rules_digest() -> String:
    var native := NativeCheckpoint.rules_digest()
    var sources := _packaged_sources() if OS.has_feature("template") else _source_hashes()
    return _combined_digest(native, sources)

static func _combined_digest(native: String, sources: Dictionary) -> String:
    if native.is_empty() or sources.size() != CODE.size(): return ""
    var inventory: Array = ["cross-counter-product-runtime/1", Engine.get_version_info().string, native]
    var names := CODE.duplicate()
    names.sort()
    for name in names:
        if not _digest(sources.get(name)): return ""
        inventory.append([CODE_ROOT + name, sources[name]])
    return packet_digest(inventory_dict(inventory))

static func inventory_dict(inventory: Array) -> Dictionary:
    return {"inventory": inventory}

static func _source_hashes() -> Dictionary:
    var sources := {}
    for name in CODE:
        var digest := FileAccess.get_sha256(CODE_ROOT + name)
        if not _digest(digest): return {}
        sources[name] = digest
    return sources

# The existing two-pass Windows builder binds original source hashes to token/remap bytes.
# It is intentionally fail-closed when the manifest, anchor or any token differs.
static func _packaged_sources() -> Dictionary:
    const MANIFEST := "res://data/cross_counter_runtime_fingerprint.json"
    const ANCHOR := "res://data/operation_checkpoint_anchor.gd"
    if not FileAccess.file_exists(MANIFEST) or not ResourceLoader.exists(ANCHOR): return {}
    var text := FileAccess.get_file_as_string(MANIFEST)
    var anchor := load(ANCHOR) as Script
    if anchor == null or anchor.get_script_constant_map().get("CROSS_COUNTER_SHA256") != text.sha256_text(): return {}
    var manifest: Variant = JSON.parse_string(text)
    if not _fields(manifest, ["format", "engine", "sources", "tokens", "remaps"]) \
            or manifest.format != "cross-counter-runtime-fingerprint/1": return {}
    var version := Engine.get_version_info()
    var engine := "%d.%d.%d.%s.%s" % [version.major, version.minor, version.patch, version.status, str(version.hash).left(9)]
    if manifest.engine != engine or not _fields(manifest.sources, CODE) \
            or not _fields(manifest.tokens, CODE) or not _fields(manifest.remaps, CODE): return {}
    for name in CODE:
        var source: String = CODE_ROOT + name
        if OS.has_feature("template") and FileAccess.file_exists(source): return {}
        if not _digest(manifest.sources[name]) or not _digest(manifest.tokens[name]) or not _digest(manifest.remaps[name]): return {}
        if FileAccess.get_sha256(source + "c") != manifest.tokens[name] \
                or FileAccess.get_sha256(source + ".remap") != manifest.remaps[name]: return {}
    return manifest.sources.duplicate()

static func _packaged_rules_digest() -> String:
    return _combined_digest(NativeCheckpoint._packaged_rules_digest(), _packaged_sources())

static func from_diagnostic(value: Dictionary) -> Dictionary:
    var packet := {"format": FORMAT, "request": value.request.duplicate(true),
        "operation_id": value.operation_id, "rules_digest": value.rules_digest,
        "source_digest": value.meta.source_digest, "effective_digest": value.meta.effective_digest,
        "tick": value.tick, "clock_ms": value.clock_ms, "seed": value.seed,
        "bootstrap_done": value.bootstrap_done, "counter_phase": value.counter_phase,
        "counter_salvos": value.counter_salvos.duplicate(), "settlement": value.settlement.duplicate(true),
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
    var current_rules := rules_digest()
    if current_rules.is_empty() or packet.rules_digest != current_rules: return fail("checkpoint_rules_mismatch", "rules_digest")
    if not _integer(packet.tick, MAX_TICKS) or not _integer(packet.clock_ms, MAX_TICKS * 100) \
            or not _integer(packet.seed, 4294967295):
        return fail("invalid_checkpoint_clock")
    if not packet.settlement is Dictionary: return fail("invalid_checkpoint_settlement")
    if packet.settlement.is_empty():
        if packet.clock_ms != packet.tick * 100: return fail("invalid_checkpoint_clock")
    elif not _fields(packet.settlement, ["id", "kind", "reason", "clock_ms", "seed", "mode", "difficulty"]) \
            or packet.settlement.id != packet.operation_id + "/settlement" \
            or typeof(packet.settlement.clock_ms) != TYPE_INT or packet.settlement.clock_ms != packet.clock_ms \
            or typeof(packet.settlement.seed) != TYPE_INT or packet.settlement.seed != packet.seed \
            or packet.settlement.mode != "direct" or packet.settlement.difficulty != "standard" \
            or packet.settlement.kind not in ["objective_success", "failure"] \
            or packet.settlement.reason not in ["ally_annihilated", "abandoned", "enemy_annihilated", "counter_salvos_completed", "deadline"] \
            or packet.tick == 0 or packet.clock_ms not in [packet.tick * 100, packet.tick * 100 - 50]:
        return fail("invalid_checkpoint_settlement")
    if not packet.counter_salvos is Array or packet.counter_salvos.size() != 2 \
            or not _integer(packet.counter_salvos[0], 1000000) or not _integer(packet.counter_salvos[1], 1000000):
        return fail("invalid_checkpoint_counter_salvos")
    if typeof(packet.bootstrap_done) != TYPE_BOOL or not _integer(packet.counter_phase, 1): return fail("invalid_checkpoint_phase")
    if not _integer(packet.event_cursor, 1000000) or not _integer(packet.emitted_events, 1000000) \
            or packet.event_cursor > packet.emitted_events: return fail("invalid_checkpoint_cursor")
    if not packet.commands is Array or not packet.pending is Array or packet.pending.size() > MAX_BATCH:
        return fail("invalid_checkpoint_commands")
    if not packet.bootstrap_done and (packet.tick != 0 or packet.counter_phase != 0 \
            or not packet.commands.is_empty() or not packet.pending.is_empty() \
            or packet.counter_salvos != [0, 0] or not packet.settlement.is_empty()):
        return fail("invalid_unstarted_checkpoint")
    if not packet.settlement.is_empty() and not packet.pending.is_empty(): return fail("terminal_checkpoint_pending")
    var previous := -1
    for row in packet.commands:
        if not _fields(row, ["tick", "batch"]) or not _integer(row.tick, MAX_TICKS) \
                or row.tick <= previous or row.tick >= packet.tick or not row.batch is Array \
                or row.batch.is_empty() or row.batch.size() > MAX_BATCH:
            return fail("invalid_checkpoint_history")
        previous = row.tick
    return {"ok": true, "packet": packet.duplicate(true)}

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
