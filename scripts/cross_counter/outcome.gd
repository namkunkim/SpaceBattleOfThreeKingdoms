extends RefCounted
## Approved policy, evaluated once after a native tick. All terminal state is immutable.
const DEADLINE_MS := 65000

static func decide(clock_ms: int, ally_alive: bool, enemy_alive: bool, counter_phase: int,
        counter_salvos: Array, abandoned: bool) -> Dictionary:
    # An accepted abandon is processed before new success; an existing terminal rejects commands.
    # Goal achieved on exactly the deadline wins; unmet goals fail at that same instant.
    if not ally_alive: return {"kind": "failure", "reason": "ally_annihilated"}
    if abandoned: return {"kind": "failure", "reason": "abandoned"}
    if not enemy_alive: return {"kind": "objective_success", "reason": "enemy_annihilated"}
    if counter_phase == 1 and counter_salvos[0] > 0 and counter_salvos[1] > 0:
        return {"kind": "objective_success", "reason": "counter_salvos_completed"}
    if clock_ms >= DEADLINE_MS: return {"kind": "failure", "reason": "deadline"}
    return {}
