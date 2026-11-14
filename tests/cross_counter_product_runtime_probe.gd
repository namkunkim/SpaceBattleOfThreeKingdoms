extends SceneTree
## Approved runtime only; fresh profiles. Destructive native cases below are explicit test injection.
const Factory := preload("res://scripts/cross_counter/runtime.gd")
const Codec := preload("res://scripts/cross_counter/checkpoint.gd")
const Outcome := preload("res://scripts/cross_counter/outcome.gd")
var checks: Array[Dictionary] = []
var owners: Array[RefCounted] = []
var evidence := {}
var output_dir := ""
var phase := "generate"

func _initialize() -> void: _run.call_deferred()

func expect(value: bool, name: String) -> bool:
    checks.append({"pass": value, "name": name})
    print("CROSS_COUNTER_PRODUCT_CHECK ", value, " ", name)
    return value

func packet(owner: RefCounted) -> Dictionary:
    return Codec.capture(owner).packet

func fresh(suffix: String) -> RefCounted:
    var result := Factory.prepare_fresh(Factory.request(), Factory.DEFINITION_ID + "/" + suffix)
    if not expect(result.ok, "factory prepares " + suffix): return null
    var owner: RefCounted = result.owner
    owners.append(owner)
    expect(not owner.advance().ok, "prepared owner cannot execute " + suffix)
    expect(owner.publish().ok, "publish validated C0 " + suffix)
    return owner

func begin(owner: RefCounted) -> void:
    expect(owner.issue({"kind": "begin_operation", "operation_id": owner.summary().summary.operation_id}).ok, "explicit begin")

func command(owner: RefCounted, kind: String, point := Vector2.ZERO) -> Dictionary:
    var result := {"operation_id": owner.summary().summary.operation_id, "kind": kind}
    if kind != "abandon":
        result.side = 0
        result.ids = [1]
    if kind == "move": result.point = point
    return result

func save_packet(name: String, value: Dictionary) -> void:
    expect(Codec.validate(value, Codec.binding_for(value)).ok, "valid product envelope " + name)
    var file := FileAccess.open(output_dir.path_join(name + ".packet"), FileAccess.WRITE)
    file.store_buffer(var_to_bytes(value))
    file.close()
    var binding := FileAccess.open(output_dir.path_join(name + ".bind.json"), FileAccess.WRITE)
    binding.store_string(JSON.stringify(Codec.binding_for(value), "  "))
    binding.close()
    evidence[name] = {"tick": value.tick, "clock_ms": value.clock_ms, "settlement": value.settlement,
        "counter_phase": value.counter_phase, "counter_salvos": value.counter_salvos,
        "packet_sha256": Codec.packet_digest(value), "state_digest": value.state_digest,
        "pending": value.pending.size(), "history": value.commands.size()}

func load_packet(name: String) -> Dictionary:
    return bytes_to_var(FileAccess.get_file_as_bytes(output_dir.path_join(name + ".packet")))

func restore(name: String) -> RefCounted:
    var original := load_packet(name)
    var binding: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output_dir.path_join(name + ".bind.json")))
    var result := Codec.prepare_restore(original, binding, Factory.prepare_fresh)
    if not expect(result.ok, "new PID detached replay validates " + name): return null
    var owner: RefCounted = result.owner
    owners.append(owner)
    expect(not owner.advance().ok and owner.publish().ok, "restored candidate requires publication " + name)
    expect(packet(owner) == original, "exact packet incl terminal/events/pending restored " + name)
    return owner

func run_until_terminal(owner: RefCounted) -> bool:
    var steps := 0
    while not owner.summary().summary.over and steps <= 650:
        if not owner.advance().ok: return false
        steps += 1
    return owner.summary().summary.over

func terminal_guards(owner: RefCounted, label: String) -> void:
    var before := packet(owner)
    expect(not owner.advance().ok, label + " rejects late tick")
    expect(not owner.issue({"kind": "begin_operation", "operation_id": before.operation_id}).ok, label + " rejects late begin")
    expect(not owner.queue(command(owner, "move", Vector2(900, 500))).ok, label + " rejects late move")
    expect(not owner.queue(command(owner, "abandon")).ok, label + " rejects late abandon")
    expect(packet(owner) == before, label + " terminal and native state immutable")

func policy_rows() -> void:
    var rows := [
        [64900, true, true, 0, [0, 0], false, "", "before deadline continues"],
        [65000, true, true, 0, [0, 0], false, "deadline", "deadline inclusive"],
        [65000, true, true, 1, [1, 1], false, "counter_salvos_completed", "goal at exact deadline wins"],
        [65000, true, false, 0, [0, 0], false, "enemy_annihilated", "enemy loss at exact deadline wins"],
        [65000, false, false, 1, [1, 1], true, "ally_annihilated", "mutual loss outranks all"],
        [100, false, true, 1, [1, 1], false, "ally_annihilated", "ally loss outranks salvos"],
        [100, true, false, 1, [1, 1], true, "abandoned", "accepted abandon outranks new success"],
        [100, true, true, 1, [1, 0], false, "", "both sides must fire"],
        [100, true, true, 0, [1, 1], false, "", "pre-cross fire cannot win"],
        [100, true, true, 1, [1, 1], false, "counter_salvos_completed", "post-cross bilateral fire wins"],
    ]
    for row in rows:
        var result := Outcome.decide(row[0], row[1], row[2], row[3], row[4], row[5])
        expect(result.get("reason", "") == row[6], "policy: " + row[7])

func generate() -> void:
    policy_rows()
    expect(not Factory.prepare_fresh(Factory.request(), Factory.DEFINITION_ID + "/../bad").ok, "path-like operation ID rejected")
    var bad_request := Factory.request()
    bad_request.seed = 20824.0
    expect(not Factory.prepare_fresh(bad_request, Factory.DEFINITION_ID + "/bad-type").ok, "float seed rejected")
    var c0 := fresh("c0")
    if c0 == null: return
    var raw: Dictionary = c0.capture_checkpoint().packet.native_witness
    var ally: Dictionary = raw.fleets[0]
    var foe: Dictionary = raw.fleets[1]
    expect(ally.sq_id == "RC-SUN-SQ-01" and ally.commander_id == "CHR-0211"
        and ally.vice.id == "CHR-0185" and ally.staff[0].id == "CHR-0186", "actual native canonical Zhou Yu Gan Ning Lu Su")
    expect(foe.sq_id == "RC-CAO-SQ-01" and foe.commander_id == "CHR-0034", "actual native canonical Cao Cao")
    expect(ally.ships == 60000 and foe.ships == 60000 and raw.command_log.is_empty(), "60 each, no C0 bootstrap commands")
    save_packet("c0", packet(c0))
    begin(c0)
    begin(c0)
    expect(c0.capture_checkpoint().packet.native_witness.command_log.size() == 2, "bootstrap moves issued exactly once")
    var before := packet(c0)
    var bad_command := command(c0, "move", Vector2(900, 500))
    bad_command.operation_id += "-wrong"
    expect(not c0.queue(bad_command).ok and packet(c0) == before, "wrong operation command preserves state")
    expect(c0.queue(command(c0, "move", Vector2(900, 500))).ok, "queue real move")
    save_packet("pending-move", packet(c0))
    expect(c0.advance().ok, "apply pending move once")
    save_packet("after-move", packet(c0))
    expect(packet(c0).pending.is_empty() and packet(c0).commands.size() == 1
        and c0.capture_checkpoint().packet.native_witness.command_log.size() == 3, "move committed history exactly once")

    var default_owner := fresh("normal")
    if default_owner == null: return
    begin(default_owner)
    var pre_success_saved := false
    var progressed := true
    while not default_owner.summary().summary.over and default_owner.summary().summary.tick < 650:
        if not default_owner.advance().ok:
            progressed = false
            break
        var summary: Dictionary = default_owner.summary().summary
        if not pre_success_saved and summary.counter_phase == 1 and not summary.over:
            save_packet("pre-success", packet(default_owner))
            pre_success_saved = true
        if not pre_success_saved and summary.tick % 17 == 0: default_owner.drain_events()
    expect(progressed and pre_success_saved, "real native sequence crosses with pre-terminal checkpoint")
    var success := packet(default_owner)
    expect(success.settlement.get("kind") == "objective_success" and success.settlement.get("reason") == "counter_salvos_completed"
        and success.counter_salvos[0] > 0 and success.counter_salvos[1] > 0 and success.clock_ms <= 65000,
        "actual canonical default play achieves bilateral counter salvo success")
    save_packet("success", success)
    terminal_guards(default_owner, "success")

    var abandon_owner := fresh("abandon")
    if abandon_owner == null: return
    begin(abandon_owner)
    expect(abandon_owner.queue(command(abandon_owner, "stop")).ok
        and abandon_owner.queue(command(abandon_owner, "abandon")).ok, "accept stop plus abandon pending batch")
    save_packet("pending-abandon", packet(abandon_owner))
    expect(abandon_owner.advance().ok, "abandon commits next logical tick")
    expect(abandon_owner.summary().summary.settlement.get("reason") == "abandoned"
        and abandon_owner.summary().summary.clock_ms == 100, "abandon stable failure at tick1")
    save_packet("abandoned", packet(abandon_owner))
    terminal_guards(abandon_owner, "abandon")

    var deadline_owner := fresh("deadline")
    if deadline_owner == null: return
    begin(deadline_owner)
    expect(deadline_owner.queue(command(deadline_owner, "move", Vector2(50, 1100))).ok, "accepted user maneuver away from counter trigger")
    progressed = true
    for _i in 649:
        if not deadline_owner.advance().ok:
            progressed = false
            break
    expect(progressed and deadline_owner.summary().summary.clock_ms == 64900
        and deadline_owner.summary().summary.settlement.is_empty(), "actual native 64900 remains nonterminal")
    if not progressed: return
    save_packet("pre-deadline", packet(deadline_owner))
    expect(deadline_owner.advance().ok and deadline_owner.summary().summary.clock_ms == 65000
        and deadline_owner.summary().summary.settlement.get("reason") == "deadline", "actual native deadline at65000")
    save_packet("deadline", packet(deadline_owner))
    terminal_guards(deadline_owner, "deadline")

    var protected := packet(c0)
    var cancellation := Codec.begin_restore(success, Codec.binding_for(success), Factory.prepare_fresh)
    expect(cancellation.ok, "detached cancellation job prepares")
    if cancellation.ok:
        cancellation.job.step(1)
        cancellation.job.cancel()
    expect(packet(c0) == protected, "cancel preserves existing live owner")
    var corrupt := success.duplicate(true)
    corrupt.counter_salvos[0] += 1
    var rejected := Codec.prepare_restore(corrupt, Codec.binding_for(corrupt), Factory.prepare_fresh)
    expect(not rejected.ok and packet(c0) == protected, "rebound forged salvo count rejected by native replay")
    if rejected.ok: rejected.owner.close()
    corrupt = success.duplicate(true)
    corrupt.settlement.reason = "enemy_annihilated"
    rejected = Codec.prepare_restore(corrupt, Codec.binding_for(corrupt), Factory.prepare_fresh)
    expect(not rejected.ok and packet(c0) == protected, "rebound forged settlement rejected by native replay")
    if rejected.ok: rejected.owner.close()
    var wrong_bind := Codec.binding_for(success)
    wrong_bind.operation_id += "-wrong"
    expect(not Codec.prepare_restore(success, wrong_bind, Factory.prepare_fresh).ok, "wrong authority bind rejected before publish")

    # These cases inject native destruction to exercise runtime outcome wiring, not natural combat or replay provenance.
    for loss_case in ["enemy", "ally", "mutual"]:
        var loss_owner := fresh("injected-" + loss_case)
        if loss_owner == null: continue
        begin(loss_owner)
        var sim: BattleSim = loss_owner._runtime._sim
        if loss_case in ["enemy", "mutual"]: sim._kill(sim.st.fleets[1], sim.st.fleets[0])
        if loss_case in ["ally", "mutual"]: sim._kill(sim.st.fleets[0], sim.st.fleets[1])
        expect(loss_owner.advance().ok, "injected native loss completes tick " + loss_case)
        var state: Dictionary = loss_owner.summary().summary
        var expected_reason := "enemy_annihilated" if loss_case == "enemy" else "ally_annihilated"
        expect(state.settlement.get("reason") == expected_reason and state.clock_ms == 50,
            "injected native " + loss_case + " honors precedence and50ms partial terminal")
        expect(Codec.validate(packet(loss_owner), Codec.binding_for(packet(loss_owner))).ok, "partial native terminal envelope shape accepted " + loss_case)
        evidence["injected-" + loss_case] = {"test_injection": true, "settlement": state.settlement, "tick": state.tick}

func reopen() -> void:
    var c0 := restore("c0")
    if c0 == null: return
    expect(not c0.summary().summary.started and not c0.advance().ok, "restarted C0 remains unstarted")
    begin(c0)
    begin(c0)
    expect(c0.capture_checkpoint().packet.native_witness.command_log.size() == 2, "new PID bootstrap exactly once")
    var pending_move := restore("pending-move")
    if pending_move == null: return
    begin(pending_move)
    expect(pending_move.advance().ok and packet(pending_move) == load_packet("after-move"), "pending move after restart exactly matches original committed tick")
    var pending_abandon := restore("pending-abandon")
    if pending_abandon == null: return
    expect(pending_abandon.advance().ok and packet(pending_abandon) == load_packet("abandoned"), "pending abandon after restart exactly matches terminal")
    for name in ["success", "abandoned", "deadline"]:
        var terminal := restore(name)
        if terminal != null: terminal_guards(terminal, "restored " + name)
    var pre_success := restore("pre-success")
    if pre_success != null:
        expect(run_until_terminal(pre_success) and packet(pre_success) == load_packet("success"), "resumed counter phase reproduces exact original success")
    var pre_deadline := restore("pre-deadline")
    if pre_deadline != null:
        expect(pre_deadline.advance().ok and packet(pre_deadline) == load_packet("deadline"), "64900 resume reaches exact same65000 terminal")

func _run() -> void:
    output_dir = OS.get_environment("SBTK_CC_RESULT_DIR").replace("\\", "/")
    var isolated := OS.get_environment("SBTK_CC_TEST_ROOT").replace("\\", "/").trim_suffix("/")
    if output_dir.is_empty() or isolated.is_empty() or not OS.get_user_data_dir().replace("\\", "/").begins_with(isolated + "/"):
        push_error("isolated profile required")
        quit(90)
        return
    if "--reopen" in OS.get_cmdline_user_args(): phase = "reopen"
    expect(true, "fresh isolated user data")
    if phase == "generate": generate()
    else: reopen()
    for owner in owners: owner.close()
    var passed := checks.all(func(check): return check.pass)
    var result := {"status": "PASS" if passed else "FAIL", "pid": OS.get_process_id(), "phase": phase,
        "checks_total": checks.size(), "checks": checks, "evidence": evidence, "engine": Engine.get_version_info().string,
        "rules_digest": Codec.rules_digest(), "request": Factory.request(), "input_pins": Factory.INPUT_PINS}
    var file := FileAccess.open(output_dir.path_join(phase + "-result.json"), FileAccess.WRITE)
    file.store_string(JSON.stringify(result, "  "))
    file.close()
    print("CROSS_COUNTER_PRODUCT_RESULT ", result.status, " ", checks.size(), " PID=", OS.get_process_id())
    quit(0 if passed else 1)
