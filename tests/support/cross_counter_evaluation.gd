extends RefCounted
## Test-only candidate factory. No public registry, persistence, settlement or user-save integration.
const Preparer := preload("res://core/battle/first_operation_preparer.gd")
const Helpers := preload("res://tests/support/cross_counter_evaluation_witness.gd")
const DEFINITION_ID := "cross-counter-drill-successor-eval-v1"
const ROSTER_ID := "cross-counter-60v60-eval-v1"
const CAPABILITY := Preparer.SYNTHETIC_CAPABILITY
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
    var validator := Preparer.new(Callable(), Callable(), CAPABILITY)
    var invalid: Dictionary = validator._validate_request(value)
    if not invalid.is_empty(): return invalid
    var expected := request()
    for key in expected:
        if value[key] != expected[key]: return failure("unsupported_candidate_input", key)
    if not operation_id.begins_with(DEFINITION_ID + "/") or operation_id.get_file().is_empty():
        return failure("invalid_evaluation_operation_id", "operation_id")
    var inputs := {}
    for path in INPUT_PINS:
        var parsed := read_pinned(path, INPUT_PINS[path])
        if parsed.is_empty(): return failure("source_reference_mismatch", path)
        inputs[path] = parsed
    var source := {"space": "source", "origin": [0, 0], "world_size": [1700, 1150],
        "definition_id": DEFINITION_ID, "definition_version": 1,
        "rosters": {ROSTER_ID: {"standard": {"inputs": inputs}}}}
    var resolve := func(_id: String, _version: int) -> Dictionary: return source
    return Preparer.new(resolve, _build_runtime.bind(operation_id), CAPABILITY).prepare_fresh(value)

static func read_pinned(path: String, expected: String) -> Dictionary:
    var bytes := FileAccess.get_file_as_bytes(path)
    var hash := HashingContext.new()
    hash.start(HashingContext.HASH_SHA256)
    hash.update(bytes)
    if bytes.is_empty() or hash.finish().hex_encode() != expected: return {}
    var parser := JSON.new()
    if parser.parse(bytes.get_string_from_utf8()) != OK or not parser.data is Dictionary: return {}
    return parser.data

static func _build_runtime(_effective: Dictionary, selection: Dictionary, _request: Dictionary, operation_id: String) -> Dictionary:
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
    patch_drill(profile, cfg)
    return {"ok": true, "runtime": EvaluationRuntime.new(profile, cfg, operation_id)}

static func patch_drill(profile: Dictionary, cfg: Dictionary) -> void:
    profile.profile_id = cfg.scenario_id
    var fleets := [profile.ally[0].duplicate(true), profile.foe[0].duplicate(true)]
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

static func native_witness(sim: BattleSim) -> Dictionary:
    return Helpers.native_witness(sim)

static func state_digest(value: Dictionary) -> String:
    return Helpers.state_digest(value)

static func close_sim(sim: BattleSim) -> void:
    Helpers.close_sim(sim)

static func failure(error: String, path: String) -> Dictionary:
    return Helpers.failure(error, path)

class EvaluationRuntime extends RefCounted:
    const RuntimeHelpers := preload("res://tests/support/cross_counter_evaluation_witness.gd")
    var _sim: BattleSim
    var _profile: Dictionary
    var _cfg: Dictionary
    var _operation_id: String
    var _begun := false
    var _closed := false
    var _counter_phase := 0
    var _event_cursor := 0

    func _init(profile: Dictionary, cfg: Dictionary, operation_id: String) -> void:
        _profile = profile.duplicate(true)
        _cfg = cfg.duplicate(true)
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
            "over": _sim.st.over, "settlement": {}, "operation_id": _operation_id,
            "evaluation_started": _begun}}

    func read_projection(side: int) -> Dictionary:
        if side != 0: return RuntimeHelpers.failure("invalid_side", "side")
        return {"ok": true, "projection": _sim.projection(side)}

    func drain_events_for(side: int) -> Dictionary:
        if side != 0: return RuntimeHelpers.failure("invalid_side", "side")
        var events := _sim.drain_events_for(side)
        _event_cursor += events.size()
        return {"ok": true, "events": events}

    func issue(command: Dictionary) -> Dictionary:
        if command.keys().size() != 2 or command.get("kind") != "begin_evaluation":
            return RuntimeHelpers.failure("unsupported_evaluation_command", "command")
        if command.get("operation_id") != _operation_id:
            return RuntimeHelpers.failure("operation_id_mismatch", "command.operation_id")
        if _begun: return {"ok": true, "already_started": true}
        # Construct start effects detached. Failure cannot mutate the published brief C0.
        var candidate := _fresh_sim()
        candidate.drain_events_for(0) # C0 events have already left through the common preparer.
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

    func queue(_command: Dictionary) -> Dictionary:
        return RuntimeHelpers.failure("evaluation_not_started" if not _begun else "unsupported_evaluation_command", "command")

    func advance() -> Dictionary:
        if not _begun: return RuntimeHelpers.failure("evaluation_not_started", "runtime")
        if _counter_phase == 0 and _sim.st.fleets[0].pos.x > _sim.st.fleets[1].pos.x + 180.0:
            _counter_phase = 1
            for side in 2:
                _sim.issue(BattleSim.command(side, [_sim.st.fleets[side].id], "attack", _sim.st.fleets[1 - side].id))
        _sim.step()
        return {"ok": true}

    func checkpoint_packet(meta: Dictionary) -> Dictionary:
        # Diagnostic output only. No restore decoder and no production checkpoint claim.
        var witness: Dictionary = RuntimeHelpers.native_witness(_sim)
        return {"ok": true, "packet": {"format": "cross-counter-evaluation-diagnostic/1",
            "operation_id": _operation_id, "tick": _sim.st.tick, "clock_ms": _sim.st.clock_ms,
            "seed": _sim.st.seed_id, "bootstrap_done": _begun, "counter_phase": _counter_phase,
            "commands": [], "pending": [], "event_cursor": _event_cursor,
            "proposal_serial": null, "policy_proposal_protocol": "not-implemented",
            "native_instance_id": _sim.get_instance_id(), "state_digest": RuntimeHelpers.state_digest(witness),
            "native_witness": witness, "meta": meta.duplicate(true)}}

    func close() -> void:
        if _closed: return
        _closed = true
        RuntimeHelpers.close_sim(_sim)
        _sim = null
