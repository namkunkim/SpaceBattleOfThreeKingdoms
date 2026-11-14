extends SceneTree
## Fresh-profile checkpoint/restart proof. No public route or existing user save access.
const Candidate := preload("res://tests/support/cross_counter_evaluation.gd")
const Codec := preload("res://tests/support/cross_counter_evaluation_checkpoint.gd")
var checks: Array[Dictionary] = []
var owners: Array[RefCounted] = []
var snapshots := {}
var output_dir := ""
var protected_owner: RefCounted
var protected_digest := ""
var protected_file := ""
var protected_file_sha := ""

func _initialize() -> void: _run.call_deferred()

func expect(value: bool, label: String) -> bool:
    checks.append({"pass": value, "name": label})
    print("CROSS_COUNTER_RESTORE_CHECK ", value, " ", label)
    return value

func capture(owner: RefCounted) -> Dictionary:
    var value := Codec.capture(owner)
    if not expect(value.ok, "capture real checkpoint from live owner"): return {}
    return value.packet

func diagnostic(owner: RefCounted) -> Dictionary:
    return owner.capture_checkpoint().packet

func fresh(suffix: String) -> Dictionary:
    var prepared := Candidate.prepare_fresh(Candidate.request(), Candidate.DEFINITION_ID + "/restore-" + suffix)
    if not expect(prepared.ok, "normal fresh candidate prepares " + suffix): return {}
    owners.append(prepared.owner)
    expect(prepared.checkpoint.tick == 0 and not prepared.checkpoint.bootstrap_done
        and prepared.checkpoint.commands.is_empty() and prepared.checkpoint.pending.is_empty(),
        "detached prepared C0 checkpoint exists before publication")
    expect(not prepared.owner.advance().ok, "detached prepared C0 has no execution permission")
    return prepared

func publish(owner: RefCounted) -> bool:
    var preview: Dictionary = owner.preview_initial_frame()
    var result: Dictionary = owner.publish()
    return expect(preview.ok and result.ok and result.frame == preview.frame, "publish only validated prepared frame")

func begin(owner: RefCounted) -> bool:
    var id: String = owner.summary().summary.operation_id
    return expect(owner.issue({"kind": "begin_evaluation", "operation_id": id}).ok, "begin bound evaluation")

func command(owner: RefCounted, kind: String, point := Vector2.ZERO) -> Dictionary:
    var value := {"kind": kind, "operation_id": owner.summary().summary.operation_id, "side": 0, "ids": [1]}
    if kind == "move": value.point = point
    return value

func restore_bound(packet: Dictionary, bind: Dictionary) -> RefCounted:
    var restored := Codec.prepare_restore(packet, bind, Candidate.prepare_fresh)
    if not expect(restored.ok, "bound replay and state witness validate before publication"): return null
    var owner: RefCounted = restored.owner
    owners.append(owner)
    expect(not owner.advance().ok, "restored candidate stays detached before publish")
    if not publish(owner): return null
    expect(capture(owner) == packet, "restored checkpoint equals the complete original envelope")
    return owner

func save_read(name: String, packet: Dictionary) -> Dictionary:
    var path := "user://cross-counter-evaluation/" + name + ".ccpeval"
    var saved := Codec.write_new(path, packet)
    if not expect(saved.ok, "write real isolated checkpoint file " + name): return {}
    var read := Codec.read_bound(path, saved.binding)
    expect(read.ok and read.packet == packet, "read file validates exact trusted envelope bind " + name)
    return {"path": path, "binding": saved.binding, "packet": read.packet}

func unchanged(label: String) -> void:
    expect(Codec.packet_digest(capture(protected_owner)) == protected_digest
        and FileAccess.get_sha256(protected_file) == protected_file_sha, label)

func reject_semantic(packet: Dictionary, label: String) -> void:
    # Rebind malformed test input deliberately, exercising semantic checks beyond hash rejection.
    var restored := Codec.prepare_restore(packet, Codec.binding_for(packet), Candidate.prepare_fresh)
    expect(not restored.ok, label)
    if restored.ok: restored.owner.close()
    unchanged("rejected candidate leaves old owner and checkpoint unchanged")

func _run() -> void:
    var bound := OS.get_environment("SBTK_CROSS_COUNTER_ISOLATED_ROOT").replace("\\", "/").trim_suffix("/")
    output_dir = OS.get_environment("SBTK_CROSS_COUNTER_RESULT_DIR").replace("\\", "/")
    if bound.is_empty() or not OS.get_user_data_dir().replace("\\", "/").begins_with(bound + "/") or output_dir.is_empty():
        push_error("Fresh isolated user profile is required")
        quit(90)
        return
    expect(true, "user-data root is isolated and bound")
    var prepared := fresh("c0")
    if prepared.is_empty():
        _finish()
        return
    var c0: Dictionary = prepared.checkpoint
    snapshots.c0 = c0
    var c0_file := save_read("c0", c0) # Save before publish; no live candidate needed.
    if not publish(prepared.owner):
        _finish()
        return
    expect(capture(prepared.owner) == c0, "publishing does not change the prepared C0 checkpoint")
    var restored_c0 := restore_bound(c0_file.packet, c0_file.binding)
    if restored_c0 == null:
        _finish()
        return
    expect(not restored_c0.summary().summary.evaluation_started, "C0 restore remains unstarted")
    begin(prepared.owner)
    begin(restored_c0)
    expect(capture(prepared.owner) == capture(restored_c0), "C0 restore starts with the same two native bootstrap moves")

    var zero := fresh("started-zero")
    publish(zero.owner)
    begin(zero.owner)
    expect(zero.owner.queue(command(zero.owner, "stop")).ok, "queue stop at started tick0")
    var zero_packet := capture(zero.owner)
    var zero_file := save_read("started-zero", zero_packet)
    var zero_restored := restore_bound(zero_file.packet, zero_file.binding)
    if zero_restored == null:
        _finish()
        return
    var before_repeat := diagnostic(zero_restored)
    begin(zero_restored)
    expect(diagnostic(zero_restored).native_witness.command_log == before_repeat.native_witness.command_log,
        "restored started tick0 does not repeat bootstrap")
    expect(zero.owner.advance().ok and zero_restored.advance().ok, "tick0 pending stop applies on first advance")
    var after_zero := capture(zero_restored)
    expect(after_zero == capture(zero.owner) and after_zero.commands.size() == 1 and after_zero.pending.is_empty()
        and diagnostic(zero_restored).native_witness.command_log.size() == 3, "restored tick0 pending executes exactly once")

    var active := fresh("history")
    publish(active.owner)
    begin(active.owner)
    expect(active.owner.queue(command(active.owner, "move", Vector2(1200, 600))).ok and active.owner.advance().ok,
        "commit first real queued move at local tick0")
    active.owner.drain_events()
    expect(active.owner.queue(command(active.owner, "stop")).ok and active.owner.advance().ok,
        "commit stop at local tick1")
    expect(active.owner.queue(command(active.owner, "move", Vector2(1100, 700))).ok and active.owner.advance().ok,
        "commit second move at local tick2")
    expect(active.owner.queue(command(active.owner, "stop")).ok, "retain a new unapplied stop at tick3")
    var started := capture(active.owner)
    snapshots.started = started
    expect(started.tick == 3 and started.commands.size() == 3 and started.pending.size() == 1,
        "checkpoint distinguishes applied history from unapplied pending")
    var saved := save_read("started", started)
    protected_owner = active.owner
    protected_digest = Codec.packet_digest(started)
    protected_file = saved.path
    protected_file_sha = FileAccess.get_sha256(saved.path)
    var restored := restore_bound(saved.packet, saved.binding)
    if restored == null:
        _finish()
        return
    expect(restored.drain_events().events == active.owner.drain_events().events,
        "unread events survive reconstruction and match original once")
    expect(restored.drain_events().events.is_empty() and active.owner.drain_events().events.is_empty(),
        "restored unread events cannot drain twice")
    expect(restored.advance().ok and active.owner.advance().ok, "restored pending commits at next local tick")
    var committed := capture(restored)
    expect(committed == capture(active.owner) and committed.tick == 4 and committed.commands.size() == 4
        and committed.pending.is_empty() and diagnostic(restored).native_witness.command_log.size() == 6,
        "pending appended once with matching original native state and log")
    expect(restored.advance().ok and active.owner.advance().ok, "empty next tick advances normally")
    expect(capture(restored) == capture(active.owner) and diagnostic(restored).native_witness.command_log.size() == 6,
        "empty next tick does not duplicate history or pending")
    protected_digest = Codec.packet_digest(capture(protected_owner))

    expect(not Codec.write_new(saved.path, committed).ok and FileAccess.get_sha256(saved.path) == protected_file_sha,
        "save API refuses to overwrite the existing isolated checkpoint")
    expect(not Codec.write_new("user://first-operation.save", committed).ok,
        "codec cannot write the public save namespace")
    expect(not Codec.write_new("user://cross-counter-evaluation/../escape.ccpeval", committed).ok,
        "checkpoint path cannot escape its dedicated namespace")
    var changed: Dictionary = saved.packet.duplicate(true)
    changed.pending[0].kind = "move"
    expect(not Codec.prepare_restore(changed, saved.binding, Candidate.prepare_fresh).ok,
        "changed pending fails the original trusted packet bind")
    var bind: Dictionary = saved.binding.duplicate(true)
    bind.operation_id += "-other"
    expect(not Codec.prepare_restore(saved.packet, bind, Candidate.prepare_fresh).ok,
        "wrong operation authority bind rejected before prepare")
    unchanged("preflight bind rejection preserves old owner and file")

    for key in ["rules_digest", "source_digest", "effective_digest", "state_digest"]:
        var bad: Dictionary = saved.packet.duplicate(true)
        bad[key] = "0".repeat(64)
        reject_semantic(bad, "reject malformed trusted " + key)
    var bad_clock: Dictionary = saved.packet.duplicate(true)
    bad_clock.tick = 3.0
    reject_semantic(bad_clock, "reject floating-point tick despite integral value")
    var bad_phase: Dictionary = saved.packet.duplicate(true)
    bad_phase.bootstrap_done = false
    reject_semantic(bad_phase, "reject unstarted phase with applied history")
    var bad_counter: Dictionary = saved.packet.duplicate(true)
    bad_counter.counter_phase = 1
    reject_semantic(bad_counter, "reject forged counter phase after replay")
    var bad_cursor: Dictionary = saved.packet.duplicate(true)
    bad_cursor.event_cursor = 0
    reject_semantic(bad_cursor, "reject cursor below actual C0 event drain")
    var bad_pending: Dictionary = saved.packet.duplicate(true)
    bad_pending.pending[0].ids = [999]
    reject_semantic(bad_pending, "reject invalid pending selection after replay")
    var bad_history: Dictionary = saved.packet.duplicate(true)
    bad_history.commands[0].batch[0].point = Vector2(-1, 600)
    reject_semantic(bad_history, "reject invalid committed command during detached replay")

    var envelope: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(saved.path))
    envelope.body[envelope.body.size() - 1] ^= 1
    var tampered := FileAccess.open("user://cross-counter-evaluation/tampered.ccpeval", FileAccess.WRITE)
    tampered.store_buffer(var_to_bytes(envelope))
    tampered.close()
    expect(not Codec.read_bound("user://cross-counter-evaluation/tampered.ccpeval", saved.binding).ok,
        "file checksum rejects altered checkpoint bytes")
    unchanged("file corruption rejection preserves old owner and source file")

    var cancelled := Codec.begin_restore(saved.packet, saved.binding, Candidate.prepare_fresh)
    if expect(cancelled.ok, "create incremental restore job"):
        expect(not cancelled.job.step(0).ok, "invalid restore budget rejected without publication")
        var partial: Dictionary = cancelled.job.step(1)
        expect(partial.ok and not partial.done and partial.tick == 1, "restore yields after one committed replay tick")
        cancelled.job.cancel()
        expect(not cancelled.job.step(1000).ok, "cancelled restore cannot finish or publish")
    unchanged("partial replay cancellation preserves live owner and file")
    var retry := restore_bound(saved.packet, saved.binding)
    expect(retry != null, "same validated checkpoint can retry after cancellation")

    var crossing := fresh("counter")
    publish(crossing.owner)
    begin(crossing.owner)
    var advances := 0
    while advances < Codec.MAX_TICKS and crossing.owner.summary().summary.evaluation_counter_phase == 0:
        if not crossing.owner.advance().ok: break
        advances += 1
    var counter := capture(crossing.owner)
    snapshots.counter = counter
    expect(counter.counter_phase == 1 and counter.tick > 1 and counter.tick < Codec.MAX_TICKS,
        "reach real crossing counter phase through normal native advances")
    var counter_file := save_read("counter", counter)
    var counter_restored := restore_bound(counter_file.packet, counter_file.binding)
    if counter_restored != null:
        begin(counter_restored)
        expect(diagnostic(counter_restored).native_witness.command_log.size() == 4,
            "restored counter phase has two bootstrap and two auto-attack commands only")
        expect(counter_restored.advance().ok and crossing.owner.advance().ok,
            "advance both restored and original counter phase")
        expect(capture(counter_restored) == capture(crossing.owner)
            and diagnostic(counter_restored).native_witness.command_log.size() == 4,
            "counter attack is not emitted a second time after restore")
    snapshots.final = committed
    _finish()

func json_safe(value: Variant) -> Variant:
    if value is Vector2: return {"type": "Vector2", "x": value.x, "y": value.y}
    if value is Array:
        var out := []
        for row in value: out.append(json_safe(row))
        return out
    if value is Dictionary:
        var out := {}
        for key in value: out[str(key)] = json_safe(value[key])
        return out
    return value

func _finish() -> void:
    var passed := checks.all(func(row): return row.pass)
    var result := {"schema": "cross-counter-checkpoint-proof/1", "status": "PASS" if passed else "FAIL",
        "checks_passed": checks.filter(func(row): return row.pass).size(), "checks_total": checks.size(),
        "checks": checks, "snapshots": json_safe(snapshots), "engine": Engine.get_version_info().string,
        "pid": OS.get_process_id(), "user_data_dir": OS.get_user_data_dir(), "rules_digest": Codec.rules_digest(),
        "public_activation": false, "public_host_installed": false, "durable_transition_verified": false,
        "existing_user_saves_accessed": false, "scope": "single-PC isolated real checkpoint and detached restore"}
    DirAccess.make_dir_recursive_absolute(output_dir)
    var file := FileAccess.open(output_dir.path_join("result.json"), FileAccess.WRITE)
    if file == null:
        passed = false
    else:
        file.store_string(JSON.stringify(result, "\t", false, true) + "\n")
        file.close()
    for owner in owners: owner.close()
    print("CROSS_COUNTER_RESTORE_RESULT ", result.status, " ", result.checks_passed, "/", result.checks_total)
    quit(0 if passed else 1)
