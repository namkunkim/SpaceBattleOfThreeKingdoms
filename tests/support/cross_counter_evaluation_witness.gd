extends RefCounted
## Exact native diagnostic fields, shared by evaluator and independent comparison.
const NativeFields := preload("res://core/battle/first_operation_native_tick.gd")

static func native_witness(sim: BattleSim) -> Dictionary:
    return {"state": NativeFields._fields(sim.st, ["fleets", "missiles", "swarms", "_idx", "_idx_n"]),
        "fleets": sim.st.fleets.map(func(item): return NativeFields._fields(item)),
        "missiles": sim.st.missiles.map(func(item): return NativeFields._fields(item)),
        "swarms": sim.st.swarms.map(func(item): return NativeFields._fields(item)),
        "events": sim._events.duplicate(true), "command_log": sim.command_log.duplicate(true),
        "queue": sim._queue.duplicate(true), "first_hit_tick": sim.first_hit_tick,
        "sub_ms": sim.sub_ms, "dt": sim.dt, "rng_context": sim.rng.profile_id,
        "contacts": sim.detect.contacts.duplicate(true) if sim.detect else []}

static func state_digest(value: Dictionary) -> String:
    return var_to_bytes(value).hex_encode().sha256_text()

static func close_sim(sim: BattleSim) -> void:
    if sim != null and sim.salvo != null: sim.salvo.sim = null

static func failure(error: String, path: String) -> Dictionary:
    return {"ok": false, "error": error, "path": path}
