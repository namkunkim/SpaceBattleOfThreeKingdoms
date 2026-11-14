extends RefCounted
## Approved Cross Counter product factory. Persistence and authorization belong to the caller.
const Preparer := preload("res://core/battle/first_operation_preparer.gd")
const Helpers := preload("res://scripts/cross_counter/witness.gd")
const Checkpoint := preload("res://scripts/cross_counter/checkpoint.gd")
const DEFINITION_ID := "cross-counter-successor-v1"
const ROSTER_ID := "cross-counter-60v60-v1"
const CAPABILITY := Preparer.CAPABILITY
const INPUT_PINS := {
    "res://data/scenarios/cross_counter_drill.json": "d1cb135e574a05963d8c7f3071a02194612f2d09bea479734a408cde2f95f6a2",
    "res://data/scenarios/red_cliffs_208_realtime.json": "0d702495a1ac94e255b44948ba8ebb625d4cdae2f1605658d05ec47911edb208",
    "res://data/scenarios/base/red-cliffs-movement-field.json": "8ae6d74a6a5f27105b318ff8efedec5c06686a39fafc6f86af95a1dca66226c9",
    "res://data/profiles/red_cliffs_rt.json": "392631eb98db72391c724a7554503581f6fc97ed9ef0645457d52a9c107b0bdb",
    "res://data/profiles/poc_corridor.json": "bb7c2dbaa8c258dc8b43f16894502a72cb66a22d2058b5d5314816a0488e9d8e",
    "res://data/profiles/combat_m3.json": "78d89e8c65f9d5fc4ab7324cc99b9f9ab0578157149f3f58036959d21131aa4c",
    "res://data/profiles/ai_m7.json": "a1a7fa6f2460bc38abe14c48f4ee89fc49e40e1cfca76cf89644df34864749a0",
}

static func request() -> Dictionary:
    return {"capability": CAPABILITY, "definition_id": DEFINITION_ID,
        "definition_version": 1, "roster_id": ROSTER_ID, "seed": 20824,
        "difficulty": "standard", "mode": "direct"}

static func prepare_fresh(value: Variant, operation_id: String) -> Dictionary:
    if Checkpoint.rules_digest().is_empty(): return failure("cross_counter_rules_unavailable", "rules_digest")
    var validator := Preparer.new(Callable(), Callable(), CAPABILITY)
    var invalid: Dictionary = validator._validate_request(value)
    if not invalid.is_empty(): return invalid
    var expected := request()
    for key in expected:
        if value[key] != expected[key]: return failure("unsupported_candidate_input", key)
    var id_pattern := RegEx.new()
    id_pattern.compile("^" + DEFINITION_ID + "/[a-z0-9][a-z0-9-]{0,127}$")
    if id_pattern.search(operation_id) == null:
        return failure("invalid_cross_counter_operation_id", "operation_id")
    var inputs := {}
    for path in INPUT_PINS:
        var parsed := read_pinned(path, INPUT_PINS[path])
        if parsed.is_empty(): return failure("source_reference_mismatch", path)
        inputs[path] = parsed
    var source := {"space": "source", "origin": [0, 0], "world_size": [1700, 1150],
        "definition_id": DEFINITION_ID, "definition_version": 1,
        "rosters": {ROSTER_ID: {"standard": {"inputs": inputs}}}}
    var resolve := func(_id: String, _version: int) -> Dictionary: return source
    var retained := {}
    var prepared := Preparer.new(resolve, _build_runtime.bind(operation_id, retained), CAPABILITY).prepare_fresh(value)
    if not prepared.ok: return prepared
    var preview: Dictionary = prepared.owner.preview_initial_frame()
    var captured: Dictionary = retained.runtime.checkpoint_packet(preview.frame.meta)
    # A detached, read-only-by-copy C0 envelope for a later authority transaction.
    prepared.checkpoint = Checkpoint.from_diagnostic(captured.packet).packet
    return prepared

static func read_pinned(path: String, expected: String) -> Dictionary:
    var bytes := FileAccess.get_file_as_bytes(path)
    var hash := HashingContext.new()
    hash.start(HashingContext.HASH_SHA256)
    hash.update(bytes)
    if bytes.is_empty() or hash.finish().hex_encode() != expected: return {}
    var parser := JSON.new()
    if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary: return {}
    return parser.data

static func _build_runtime(_effective: Dictionary, selection: Dictionary, selected_request: Dictionary, operation_id: String, retained: Dictionary) -> Dictionary:
    # Read from the already pinned, frozen source payload. No second unpinned disk read.
    var inputs: Dictionary = selection.inputs
    var definition: Dictionary = inputs["res://data/profiles/red_cliffs_rt.json"]
    var combat: Dictionary = inputs[definition.combat_rules_path].combat.duplicate(true)
    var movement: Dictionary = inputs[definition.movement_field_path]
    if not BattleTerrain.valid_movement_field(movement): return failure("invalid_movement_field", "profile")
    combat.terrain.movement_field = movement.duplicate(true)
    var profile := ScenarioProfile.build(definition, inputs[definition.scenario_path],
        inputs[definition.base_profile], definition.default_difficulty, combat)
    if profile.is_empty(): return failure("invalid_candidate_profile", "profile")
    # ScenarioProfile.build can retain nested source dictionaries; detach before scaling.
    profile = profile.duplicate(true)
    profile.ai = inputs[definition.ai_rules_path].get("ai", {}).duplicate(true)
    var cfg: Dictionary = inputs["res://data/scenarios/cross_counter_drill.json"].duplicate(true)
    ScenarioProfile.enlarge_field(profile, Vector2(1700, 1150))
    ScenarioProfile.tune_for_play(profile, float(cfg.move_mul), float(cfg.turn_mul))
    if not patch_drill(profile, cfg): return failure("invalid_canonical_roster", "profile")
    var runtime := OperationRuntime.new(profile, cfg, operation_id, selected_request)
    retained.runtime = runtime
    return {"ok": true, "runtime": runtime}

static func patch_drill(profile: Dictionary, cfg: Dictionary) -> bool:
    profile.profile_id = DEFINITION_ID
    var ally: Array = profile.ally.filter(func(f): return f.squadron_id == "RC-SUN-SQ-01")
    var foe: Array = profile.foe.filter(func(f): return f.squadron_id == "RC-CAO-SQ-01")
    if ally.size() != 1 or foe.size() != 1: return false
    if ally[0].commander_id != "CHR-0211" or ally[0].vice_commander.get("id") != "CHR-0185" \
            or ally[0].staff.size() != 1 or ally[0].staff[0].get("id") != "CHR-0186" \
            or foe[0].commander_id != "CHR-0034": return false
    var fleets := [ally[0].duplicate(true), foe[0].duplicate(true)]
    for side in 2:
        var fleet: Dictionary = fleets[side]
        var spec: Dictionary = cfg.fleets[side]
        fleet.name = spec.name
        fleet.role = spec.role
        fleet.faction_id = "sun_quan" if side == 0 else "cao_cao"
        fleet.x = spec.position[0]
        fleet.y = spec.position[1]
        fleet.flag = true
        fleet.wait = 0
        fleet.formation_id = "FRM-01"
        fleet.composition = cfg.composition.duplicate(true)
        fleet.ships = 0
        for row in fleet.composition: fleet.ships += int(row.count)
        fleet.command = 100
        fleet.might = 80
        fleet.intellect = 80
        fleet.start_morale_bp = 10000
        fleet.erase("morale_group")
        fleet.erase("fill_bp")
    profile.ally = [fleets[0]]
    profile.foe = [fleets[1]]
    profile.reinf = []
    profile.erase("ai")
    profile.scenario = {}
    for key in ["terrain", "supply", "detection"]: profile.combat.erase(key)
    profile.combat.period_s = cfg.period_s
    return true

static func native_witness(sim: BattleSim) -> Dictionary:
    return Helpers.native_witness(sim)

static func state_digest(value: Dictionary) -> String:
    return Helpers.state_digest(value)

static func close_sim(sim: BattleSim) -> void:
    Helpers.close_sim(sim)

static func failure(error: String, path: String) -> Dictionary:
    return Helpers.failure(error, path)

class OperationRuntime extends RefCounted:
    const Outcome := preload("res://scripts/cross_counter/outcome.gd")
    const RuntimeHelpers := preload("res://scripts/cross_counter/witness.gd")
    const RuntimeCheckpoint := preload("res://scripts/cross_counter/checkpoint.gd")
    var _sim: BattleSim
    var _profile: Dictionary
    var _cfg: Dictionary
    var _request: Dictionary
    var _operation_id: String
    var _begun := false
    var _closed := false
    var _counter_phase := 0
    var _counter_salvos := [0, 0]
    var _settlement := {}
    var _event_cursor := 0
    var _commands: Array[Dictionary] = []
    var _pending: Array[Dictionary] = []

    func _init(profile: Dictionary, cfg: Dictionary, operation_id: String, selected_request: Dictionary) -> void:
        _profile = profile.duplicate(true)
        _cfg = cfg.duplicate(true)
        _request = selected_request.duplicate(true)
        _operation_id = operation_id
        _sim = _fresh_sim()

    func _fresh_sim() -> BattleSim:
        var sim := BattleSim.new(int(_cfg.seed), BattleRules.TICK_HZ, _profile)
        sim.st.ai_timer = 1 << 50
        for side in 2:
            sim.st.fleets[side].heading = deg_to_rad(float(_cfg.fleets[side].heading_deg))
        return sim

    func summary() -> Dictionary:
        return {"ok": true, "summary": {"tick": _sim.st.tick, "clock_ms": _sim.st.clock_ms,
            "over": not _settlement.is_empty(), "settlement": _settlement.duplicate(true), "operation_id": _operation_id,
            "started": _begun, "counter_phase": _counter_phase, "counter_salvos": _counter_salvos.duplicate()}}

    func read_projection(side: int) -> Dictionary:
        if side != 0: return RuntimeHelpers.failure("invalid_side", "side")
        var projection := _sim.projection(side)
        projection.operation = {"definition_id": "cross-counter-successor-v1", "started": _begun,
            "counter_phase": _counter_phase, "counter_salvos": _counter_salvos.duplicate(),
            "settlement": _settlement.duplicate(true)}
        if not _settlement.is_empty():
            projection.outcome.over = true
            projection.outcome.win = _settlement.kind == "objective_success"
            projection.outcome.reason = _settlement.reason
            projection.outcome.end_tick = _sim.st.tick
            projection.outcome.result = _settlement.duplicate(true)
        return {"ok": true, "projection": projection}

    func drain_events_for(side: int) -> Dictionary:
        if side != 0: return RuntimeHelpers.failure("invalid_side", "side")
        var events := _sim.drain_events_for(side)
        _event_cursor += events.size()
        return {"ok": true, "events": events}

    func issue(command: Dictionary) -> Dictionary:
        if command.get("kind") != "begin_operation": return queue(command)
        if command.keys().size() != 2: return RuntimeHelpers.failure("unsupported_cross_counter_command", "command")
        if command.get("operation_id") != _operation_id:
            return RuntimeHelpers.failure("operation_id_mismatch", "command.operation_id")
        if not _settlement.is_empty(): return RuntimeHelpers.failure("cross_counter_terminal", "command")
        if _begun: return {"ok": true, "already_started": true}
        var candidate := _fresh_sim()
        candidate.drain_events_for(0)
        for side in 2:
            var destination: Array = _cfg.fleets[side].destination
            candidate.issue(BattleSim.command(side, [candidate.st.fleets[side].id], "move", -1,
                Vector2(destination[0], destination[1])))
        for event in candidate._events:
            if event.kind == "rejected":
                RuntimeHelpers.close_sim(candidate)
                return RuntimeHelpers.failure("bootstrap_rejected", "bootstrap")
        var previous := _sim
        _sim = candidate
        _begun = true
        RuntimeHelpers.close_sim(previous)
        return {"ok": true, "already_started": false}

    func _normalize_command(command: Variant) -> Dictionary:
        if not command is Dictionary: return RuntimeHelpers.failure("invalid_cross_counter_command", "command")
        var kind: Variant = command.get("kind")
        if kind == "abandon":
            if command.size() != 2 or typeof(command.get("operation_id")) != TYPE_STRING \
                    or command.operation_id != _operation_id:
                return RuntimeHelpers.failure("invalid_abandon_command", "command")
            return {"ok": true, "command": {"operation_id": _operation_id, "kind": "abandon"}}
        if kind not in ["move", "stop"]: return RuntimeHelpers.failure("unsupported_cross_counter_command", "command.kind")
        var keys := ["operation_id", "kind", "side", "ids"] + (["point"] if kind == "move" else [])
        if command.size() != keys.size() or not keys.all(func(key): return command.has(key)):
            return RuntimeHelpers.failure("invalid_cross_counter_command", "command")
        if typeof(command.operation_id) != TYPE_STRING or command.operation_id != _operation_id:
            return RuntimeHelpers.failure("operation_id_mismatch", "command.operation_id")
        if typeof(command.side) != TYPE_INT or command.side != 0 or not command.ids is Array \
                or command.ids.size() != 1 or typeof(command.ids[0]) != TYPE_INT \
                or command.ids[0] != _sim.st.fleets[0].id:
            return RuntimeHelpers.failure("invalid_cross_counter_selection", "command.ids")
        var normalized := {"operation_id": _operation_id, "kind": kind, "side": 0, "ids": command.ids.duplicate()}
        if kind == "move":
            var point: Variant = command.point
            if not point is Vector2 or not point.is_finite() or point.x < 0 or point.x > 1700 or point.y < 0 or point.y > 1150:
                return RuntimeHelpers.failure("invalid_cross_counter_point", "command.point")
            normalized.point = point
        return {"ok": true, "command": normalized}

    func queue(command: Dictionary) -> Dictionary:
        if not _begun: return RuntimeHelpers.failure("cross_counter_not_started", "command")
        if not _settlement.is_empty() or _sim.st.clock_ms >= Outcome.DEADLINE_MS:
            return RuntimeHelpers.failure("cross_counter_terminal", "command")
        if _pending.size() >= RuntimeCheckpoint.MAX_BATCH: return RuntimeHelpers.failure("cross_counter_queue_full", "command")
        var normalized := _normalize_command(command)
        if not normalized.ok: return normalized
        _pending.append(normalized.command)
        return {"ok": true}

    func advance() -> Dictionary:
        if not _begun: return RuntimeHelpers.failure("cross_counter_not_started", "runtime")
        if not _settlement.is_empty() or _sim.st.clock_ms >= Outcome.DEADLINE_MS:
            return RuntimeHelpers.failure("cross_counter_terminal", "runtime")
        # Scenario reaction precedes the normal queued human batch, then one native step.
        if _counter_phase == 0 and _sim.st.fleets[0].pos.x > _sim.st.fleets[1].pos.x + 180.0:
            _counter_phase = 1
            for side in 2:
                _sim.issue(BattleSim.command(side, [_sim.st.fleets[side].id], "attack", _sim.st.fleets[1 - side].id))
        var tick := _sim.st.tick
        var event_start := _sim._events.size()
        var abandoned := false
        for command in _pending:
            if command.kind == "abandon":
                abandoned = true
                continue
            _sim.queue(BattleSim.command(command.side, command.ids, command.kind, -1, command.get("point", Vector2.ZERO)))
        _sim.step()
        if _counter_phase == 1:
            for event in _sim._events.slice(event_start):
                if event.kind == "salvo":
                    for side in 2:
                        if event.sq == _sim.st.fleets[side].id: _counter_salvos[side] += 1
        var result := Outcome.decide(_sim.st.clock_ms, not _sim.st.alive(0).is_empty(),
            not _sim.st.alive(1).is_empty(), _counter_phase, _counter_salvos, abandoned)
        if not result.is_empty():
            _settlement = {"id": _operation_id + "/settlement", "kind": result.kind, "reason": result.reason,
                "clock_ms": _sim.st.clock_ms, "seed": _request.seed, "mode": _request.mode, "difficulty": _request.difficulty}
            _sim.emit("cross_counter_settlement", -1, -1, Vector2.ZERO, result.reason)
        if not _pending.is_empty(): _commands.append({"tick": tick, "batch": _pending.duplicate(true)})
        _pending.clear()
        return {"ok": true}

    func replay_tick(batch: Array, path: String) -> Dictionary:
        if not _begun:
            var started := issue({"kind": "begin_operation", "operation_id": _operation_id})
            if not started.ok: return started
        for command in batch:
            var normalized := _normalize_command(command)
            if not normalized.ok: return RuntimeHelpers.failure(normalized.error, path)
            var queued := queue(normalized.command)
            if not queued.ok: return RuntimeHelpers.failure(queued.error, path)
        return advance()

    func finish_restore_replay(packet: Dictionary) -> Dictionary:
        if packet.bootstrap_done and not _begun:
            var started := issue({"kind": "begin_operation", "operation_id": _operation_id})
            if not started.ok: return started
        if _sim.st.tick != packet.tick or _sim.st.clock_ms != packet.clock_ms or _sim.st.seed_id != packet.seed \
                or _begun != packet.bootstrap_done or _counter_phase != packet.counter_phase or _commands != packet.commands \
                or _counter_salvos != packet.counter_salvos or _settlement != packet.settlement:
            return RuntimeHelpers.failure("checkpoint_replay_mismatch", "packet")
        if _event_cursor + _sim._events.size() != packet.emitted_events:
            return RuntimeHelpers.failure("checkpoint_event_count_mismatch", "event_cursor")
        var discard: int = packet.event_cursor - _event_cursor
        if discard < 0 or discard > _sim._events.size():
            return RuntimeHelpers.failure("checkpoint_event_cursor_mismatch", "event_cursor")
        _sim._events = _sim._events.slice(discard)
        _event_cursor = packet.event_cursor
        var witness: Dictionary = RuntimeHelpers.native_witness(_sim)
        if RuntimeHelpers.state_digest(witness) != packet.state_digest:
            return RuntimeHelpers.failure("checkpoint_state_witness_mismatch", "state_digest")
        var pending: Array[Dictionary] = []
        for command in packet.pending:
            var normalized := _normalize_command(command)
            if not normalized.ok: return RuntimeHelpers.failure(normalized.error, "pending")
            pending.append(normalized.command)
        _pending = pending
        return {"ok": true}

    func checkpoint_packet(meta: Dictionary) -> Dictionary:
        var witness: Dictionary = RuntimeHelpers.native_witness(_sim)
        return {"ok": true, "packet": {"format": "cross-counter-product-diagnostic/1",
            "request": _request.duplicate(true), "rules_digest": RuntimeCheckpoint.rules_digest(),
            "operation_id": _operation_id, "tick": _sim.st.tick, "clock_ms": _sim.st.clock_ms,
            "seed": _sim.st.seed_id, "bootstrap_done": _begun, "counter_phase": _counter_phase,
            "counter_salvos": _counter_salvos.duplicate(), "settlement": _settlement.duplicate(true),
            "commands": _commands.duplicate(true), "pending": _pending.duplicate(true), "event_cursor": _event_cursor,
            "emitted_events": _event_cursor + _sim._events.size(),
            "proposal_serial": null, "policy_proposal_protocol": "not-implemented",
            "native_instance_id": _sim.get_instance_id(), "state_digest": RuntimeHelpers.state_digest(witness),
            "native_witness": witness, "meta": meta.duplicate(true)}}

    func close() -> void:
        if _closed: return
        _closed = true
        RuntimeHelpers.close_sim(_sim)
        _sim = null
