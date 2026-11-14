extends SceneTree
## Test-only source of a real, consumed parent. No successor activation or user-save access.
const Adapter := preload("res://scripts/first_operation_adapter.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Ledger := preload("res://scripts/first_operation_settlement_store.gd")
const SLOT := "user://cross-counter-real-parent.save"
const COMMANDS := [{"tick": 0, "kind": "move", "waypoint": 2}, {"tick": 900, "kind": "move", "waypoint": 3}]
const FINAL_TICK := 5487
var checks: Array[Dictionary] = []
var output_dir := ""
var lane := ""
var owner: RefCounted

func _initialize() -> void: _run.call_deferred()

func expect(value: bool, label: String) -> bool:
    checks.append({"pass": value, "name": label})
    print("CROSS_COUNTER_REAL_PARENT_CHECK ", value, " ", label)
    return value

func _run() -> void:
    var guard := OS.get_environment("SBTK_CROSS_COUNTER_ISOLATED_ROOT").replace("\\", "/").simplify_path().to_lower().trim_suffix("/")
    output_dir = OS.get_environment("SBTK_CROSS_COUNTER_RESULT_DIR").replace("\\", "/").simplify_path()
    var actual := OS.get_user_data_dir().replace("\\", "/").simplify_path().to_lower()
    var args := OS.get_cmdline_user_args()
    if guard.is_empty() or not actual.begins_with(guard + "/") or output_dir.is_empty() or args.size() != 1 or args[0] not in ["generate", "reopen"]:
        push_error("Refusing an unbound parent fixture invocation")
        quit(90)
        return
    lane = args[0]
    # These paths resolve only below the checked, fresh test profile.
    if not expect(not FileAccess.file_exists(Ledger.PRODUCT_SLOT_PATH) and not FileAccess.file_exists(Ledger.SLOT_PATH), "isolated profile contains no product or development settlement slot"):
        _finish({}, false)
        return
    if lane == "reopen":
        _reopen()
    else:
        _generate()

func _generate() -> void:
    if not expect(not FileAccess.file_exists(SLOT) and not FileAccess.file_exists(SLOT + ".previous"), "new fixture ledger does not exist before the real battle"):
        _finish({}, false)
        return
    var brief := BattleBrief.new()
    brief.select_first_operation_product()
    var request: Dictionary = brief.operation_request().duplicate(true)
    if not expect(request == Product.REQUEST, "use the unchanged approved product request"):
        _finish({}, false)
        return
    var prepared := Adapter.prepare_fresh(request)
    if not expect(prepared.ok, "normal adapter prepares an actual approved first-operation owner"):
        _finish({"error": prepared}, false)
        return
    owner = prepared.owner
    var published: Dictionary = owner.publish()
    if not expect(published.ok and published.frame.tick == 0 and published.frame.clock_ms == 0, "publish real parent C0"):
        _finish({}, false)
        return
    var initial: Dictionary = published.frame
    var checkpoint: Dictionary = owner.capture_checkpoint()
    expect(checkpoint.ok and checkpoint.packet.pending.is_empty() and checkpoint.packet.commands.is_empty(), "parent starts without injected history or pending commands")
    var events: Array = initial.events.duplicate(true)
    var receipts: Array = []
    var final: Dictionary
    var blocked := 0
    for tick in FINAL_TICK:
        if tick in [0, 900]:
            var projection: Dictionary = owner.read_projection().projection
            var ids: Array = []
            for fleet: Dictionary in projection.squadrons:
                if fleet.side == 0 and not fleet.dead and fleet.get("out", "") == "": ids.append(fleet.id)
            var waypoint := 2 if tick == 0 else 3
            if tick == 900:
                expect(projection.operation.sites.A.active, "A has naturally activated before the scheduled C command")
            var queued := Adapter.queue(owner, {"side": 0, "kind": "move", "ids": ids, "point": projection.operation.route_points[waypoint]})
            if not expect(queued.ok and queued.record == COMMANDS[receipts.size()], "actual command receipt matches the approved schedule"):
                _finish({}, false)
                return
            receipts.append(queued.record)
        final = Adapter.advance(owner)
        if not final.ok or final.summary.tick != tick + 1 or final.summary.over != (tick + 1 == FINAL_TICK):
            expect(false, "native advancement reaches the approved terminal tick without early settlement")
            _finish({"last": final, "scheduled_tick": tick}, false)
            return
        events.append_array(final.frame.events)
        blocked += int(final.has("movement_error"))
    expect(final.summary.tick == FINAL_TICK and final.summary.clock_ms == 548700 and blocked == 0, "5487 native ticks complete with no movement rejection")
    var facts: Dictionary = final.summary.settlement
    expect(facts.kind == "objective_success" and facts.reason == "objective_conditions_met" and facts.operation_id == prepared.operation_id and facts.id == prepared.operation_id + "/settlement", "objective success is generated by the real parent under its fresh identity")
    var terminal: Array = events.filter(func(event): return event.get("kind") == "operation_settled")
    expect(terminal.size() == 1 and terminal[0].fact == facts and final.frame.projection.operation.settlement == facts, "one actual terminal event agrees with summary and projection")
    expect(owner.advance().get("error") == "operation_terminal" and owner.drain_events().events.is_empty(), "parent freezes and emits no second settlement after terminal")
    var outcome := BattleOutcome.from_operation(facts, brief, final.summary.clock_ms)
    if not expect(outcome != null and outcome.is_product_operation, "normal product outcome conversion preserves actual terminal facts"):
        _finish({}, false)
        return
    expect(not FileAccess.file_exists(SLOT), "terminal computation alone has not consumed the parent")
    var accepted := Ledger.consume(outcome, SLOT)
    if not expect(accepted.ok and accepted.applied == true, "real SettlementStore accepts the completed parent once"):
        _finish({"error": accepted}, false)
        return
    var stored := Ledger._read(SLOT)
    if not expect(stored.ok and stored.payload.consumed.size() == 1 and stored.payload.latest == facts.id, "checksummed ledger contains the exact accepted parent"):
        _finish({}, false)
        return
    var decoded_parent: Dictionary = stored.payload.consumed[facts.id]
    var parent := _canonical_parent(decoded_parent)
    expect(parent == {"id": facts.id, "kind": facts.kind, "reason": facts.reason, "clock_ms": facts.clock_ms, "seed": request.seed, "mode": request.mode, "difficulty": request.difficulty}, "all seven consumed fields derive from the real outcome and approved request")
    var bad_seed: Dictionary = decoded_parent.duplicate(true)
    bad_seed.seed = true
    expect(_canonical_parent(bad_seed).is_empty(), "boolean is not a canonical parent seed")
    var bad_clock: Dictionary = decoded_parent.duplicate(true)
    bad_clock.clock_ms = 548700.5
    expect(_canonical_parent(bad_clock).is_empty(), "fractional clock is rejected before integer canonicalization")
    var ledger_sha := FileAccess.get_sha256(SLOT)
    var duplicate := Ledger.consume(outcome, SLOT)
    expect(duplicate.ok and duplicate.applied == false and FileAccess.get_sha256(SLOT) == ledger_sha, "same parent duplicate is idempotent without changing ledger bytes")
    var recording := Adapter.make_recording(request, prepared.operation_id, receipts, facts)
    expect(recording.ok, "actual receipts and terminal fields form a valid recorded run")
    var details := {"parent": parent, "ledger": stored.payload, "ledger_sha256": ledger_sha,
        "ledger_path": ProjectSettings.globalize_path(SLOT), "request": request, "decoded_parent": decoded_parent,
        "operation_id": prepared.operation_id, "terminal": facts, "meta": initial.meta,
        "commands": receipts, "event_count": events.size(), "terminal_event_count": terminal.size(),
        "blocked_ticks": blocked, "computed_before_consumed": true}
    expect(_write_json("parent-fixture.json", details), "write exact actual consumed parent fixture")
    expect(_write_json("parent-recording.json", recording.bundle), "write recorded input for later targeted verification")
    expect(_write_json("parent-run.json", {"initial": initial, "summary": final.summary, "projection": final.frame.projection, "events": events}), "write complete observed parent frames and events")
    var binary := FileAccess.open(output_dir.path_join("parent-run.bin"), FileAccess.WRITE)
    if expect(binary != null, "preserve native Variant evidence without JSON conversion"):
        binary.store_buffer(var_to_bytes({"initial": initial, "checkpoint": checkpoint, "final": final, "events": events}))
        binary.close()
    _finish(details, true)

func _reopen() -> void:
    var fixture: Variant = JSON.parse_string(FileAccess.get_file_as_string(output_dir.path_join("parent-fixture.json")))
    if not expect(fixture is Dictionary and fixture.get("parent") is Dictionary, "reopen reads this generated fixture"):
        _finish({}, false)
        return
    var before := FileAccess.get_sha256(SLOT)
    var stored := Ledger._read(SLOT)
    if not expect(stored.ok and stored.payload == fixture.ledger and before == fixture.ledger_sha256, "new engine PID reads the exact persisted parent ledger and bytes"):
        _finish({}, false)
        return
    var parent: Dictionary = stored.payload.consumed[fixture.parent.id]
    expect(_canonical_parent(parent) == _canonical_parent(fixture.parent) and parent.kind == "objective_success" and parent.reason == "objective_conditions_met", "reopened consumed record remains the actual objective-success parent")
    var restored := Ledger.restore_latest(SLOT)
    expect(restored.ok and restored.outcome != null and restored.outcome.settlement_id == parent.id, "normal restore returns the accepted parent outcome")
    var repeated := Ledger.consume(restored.outcome, SLOT)
    expect(repeated.ok and repeated.applied == false and FileAccess.get_sha256(SLOT) == before, "new process retry consumes no second copy and preserves ledger bytes")
    _finish({"parent": parent, "ledger_sha256": before, "ledger_path": ProjectSettings.globalize_path(SLOT)}, true)

func _canonical_parent(record: Dictionary) -> Dictionary:
    # The existing save codec parses JSON numbers as floats. Its record validator
    # accepts only finite, exactly integral safe-range values for these two fields.
    # Preserve the ledger; export a separate language-independent integer DTO.
    if not Ledger._valid_record(record): return {}
    var result: Dictionary = record.duplicate(true)
    result.clock_ms = int(result.clock_ms)
    result.seed = int(result.seed)
    return result
func _json(value: Variant) -> Variant:
    if value is Vector2: return [value.x, value.y]
    if value is Dictionary:
        var out := {}
        for key in value: out[key] = _json(value[key])
        return out
    if value is Array:
        var out := []
        for item in value: out.append(_json(item))
        return out
    return value

func _write_json(name: String, value: Dictionary) -> bool:
    var file := FileAccess.open(output_dir.path_join(name), FileAccess.WRITE)
    if file == null: return false
    file.store_string(JSON.stringify(_json(value), "\t", false, true) + "\n")
    file.close()
    return true

func _finish(details: Dictionary, intended: bool) -> void:
    var passed := intended and checks.all(func(row): return row.pass)
    if owner != null: owner.close()
    var result := {"schema": "cross-counter-real-parent-fixture-proof/1", "status": "PASS" if passed else "FAIL",
        "checks": checks, "checks_total": checks.size(), "checks_passed": checks.filter(func(row): return row.pass).size(),
        "details": details, "lane": lane, "pid": OS.get_process_id(), "engine": Engine.get_version_info().string,
        "user_data_dir": OS.get_user_data_dir(), "single_pc": true, "parent_synthetic": false,
        "public_successor_activation": false, "product_ui_tested": false, "real_service_authentication": false,
        "actual_parent_sqlite_transition_tested": false, "existing_user_saves_accessed": false}
    if not _write_json(lane + "-result.json", result): passed = false
    print("CROSS_COUNTER_REAL_PARENT_RESULT ", result.status)
    quit(0 if passed else 1)
