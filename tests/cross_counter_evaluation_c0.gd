extends SceneTree
## Isolated engine proof of candidate C0 and begin; not a public host or restore test.
const Candidate := preload("res://tests/support/cross_counter_evaluation.gd")
const DRILL_SHA := "0d076f5d8a99fa21e086d91e4de5d0d493cb7406246d75085b82dc69b060f45e"

class ReferenceDrill extends "res://tools/scenario/cross_counter_drill.gd":
    func _initialize() -> void: pass # Prevent the independent reference object from launching its UI.

var checks: Array[Dictionary] = []
var snapshots := {}
var owners: Array[RefCounted] = []
var reference: ReferenceDrill
var reference_sim: BattleSim
var output_dir := ""

func _initialize() -> void:
    _run.call_deferred()

func expect(value: bool, label: String) -> bool:
    checks.append({"pass": value, "name": label})
    print("CROSS_COUNTER_C0_CHECK ", value, " ", label)
    return value

func packet(owner: RefCounted) -> Dictionary:
    var result: Dictionary = owner.capture_checkpoint()
    if not expect(result.get("ok") == true, "capture actual owner diagnostic"):
        return {}
    return result.packet

func start_owner(operation_id: String) -> RefCounted:
    var prepared := Candidate.prepare_fresh(Candidate.request(), operation_id)
    if not expect(prepared.get("ok") == true, "normal candidate prepare_fresh"):
        return null
    var owner: RefCounted = prepared.owner
    owners.append(owner)
    var preview: Dictionary = owner.preview_initial_frame()
    expect(preview.ok and preview.frame.phase == "brief" and preview.frame.tick == 0
        and preview.frame.clock_ms == 0 and preview.frame.hz == 10, "shared preparer produces real paused C0")
    expect(not owner.advance().ok and not owner.issue({"kind": "begin_evaluation", "operation_id": operation_id}).ok,
        "prepared owner rejects commands and advance before publication")
    var published: Dictionary = owner.publish()
    expect(published.ok and published.frame == preview.frame, "normal owner publication installs preview unchanged")
    expect(not owner.publish().ok, "same candidate cannot be published twice")
    var initial := packet(owner)
    expect(initial.event_cursor == published.frame.events.size(), "C0 event cursor equals actual initial event drain")
    expect(owner.drain_events().events.is_empty(), "initial events do not drain twice")
    return owner

func _run() -> void:
    var expected_root := OS.get_environment("SBTK_CROSS_COUNTER_ISOLATED_ROOT").replace("\\", "/").trim_suffix("/")
    var user_dir := OS.get_user_data_dir().replace("\\", "/")
    output_dir = OS.get_environment("SBTK_CROSS_COUNTER_RESULT_DIR").replace("\\", "/")
    if expected_root.is_empty() or not user_dir.begins_with(expected_root + "/") or output_dir.is_empty():
        push_error("Refusing to run without a bound isolated user-data root")
        quit(90)
        return
    expect(true, "user-data root bound to fresh evaluation profile")
    var reference_hash := FileAccess.get_sha256("res://tools/scenario/cross_counter_drill.gd")
    if not expect(reference_hash == DRILL_SHA, "independent original drill source pin"):
        _finish(user_dir)
        return
    var id := Candidate.DEFINITION_ID + "/isolated-c0-01"
    var owner := start_owner(id)
    if owner == null:
        _finish(user_dir)
        return
    var c0 := packet(owner)
    snapshots.c0 = c0
    expect(c0.seed == 20824 and c0.tick == 0 and c0.clock_ms == 0 and not c0.bootstrap_done,
        "new operation uses target seed and unstarted tick0")
    expect(c0.commands.is_empty() and c0.pending.is_empty() and c0.native_witness.command_log.is_empty()
        and c0.native_witness.queue.is_empty(), "C0 user and native command histories and queues are empty")
    var fleets: Array = c0.native_witness.fleets
    expect(fleets.size() == 2 and fleets[0].ships == 60 * BattleRules.MILLI and fleets[1].ships == 60 * BattleRules.MILLI,
        "real native state has two 60-ship fleets")
    expect(fleets.all(func(row): return row.stages == {"SHP-03": [12, 0, 0, 0, 0],
        "SHP-04": [36, 0, 0, 0, 0], "SHP-07": [12, 0, 0, 0, 0]}),
        "both native fleets have the exact intact 12/36/12 composition")
    expect(fleets[0].pos == Vector2(350, 800) and fleets[1].pos == Vector2(1350, 350)
        and is_equal_approx(fleets[0].heading, deg_to_rad(-16.7))
        and is_equal_approx(fleets[1].heading, deg_to_rad(163.3)), "native starting coordinates and headings match drill")
    expect(fleets[0].sq_id == "RC-LIU-SQ-01", "inherited ally identity remains visible")
    expect(owner.summary().summary.settlement.is_empty(), "no campaign settlement invented")
    expect(not owner.advance().ok and not owner.queue({"kind": "stop"}).ok,
        "live brief rejects advance and combat queue before begin")
    expect(not owner.issue({"kind": "begin_evaluation", "operation_id": id + "-other"}).ok,
        "begin bound to exact new operation ID")
    expect(packet(owner).state_digest == c0.state_digest, "rejected actions preserve actual C0 state")

    # The control uses original script methods, independently of Candidate.patch_drill.
    reference = ReferenceDrill.new()
    reference.cfg = ProfileLoader.read_json("res://data/scenarios/cross_counter_drill.json")
    var profile := ScenarioProfile.load_profile("res://data/profiles/red_cliffs_rt.json")
    ScenarioProfile.enlarge_field(profile, Vector2(1700, 1150))
    ScenarioProfile.tune_for_play(profile, float(reference.cfg.move_mul), float(reference.cfg.turn_mul))
    reference._patch(profile)
    reference_sim = BattleSim.new(int(reference.cfg.seed), BattleRules.TICK_HZ, profile)
    reference_sim.drain_events_for(0) # Match common preparer's already-published C0 event drain.
    reference._prepare(reference_sim)
    var started: Dictionary = owner.issue({"kind": "begin_evaluation", "operation_id": id})
    expect(started.ok and not started.already_started, "explicit normal begin applies bootstrap")
    var begun := packet(owner)
    snapshots.after_begin = begun
    var reference_start := Candidate.native_witness(reference_sim)
    snapshots.reference_after_prepare = reference_start
    expect(begun.native_witness == reference_start
        and begun.state_digest == Candidate.state_digest(reference_start),
        "begin native witness exactly matches original drill _prepare")
    var log: Array = begun.native_witness.command_log
    expect(begun.bootstrap_done and begun.tick == 0 and log.size() == 2
        and log.all(func(row): return row.tick == 0 and row.kind == "move"),
        "bootstrap is exactly two native moves at tick0")
    expect(begun.commands.is_empty() and begun.pending.is_empty(), "scenario bootstrap does not become user history or pending")
    var repeated: Dictionary = owner.issue({"kind": "begin_evaluation", "operation_id": id})
    expect(repeated.ok and repeated.already_started and packet(owner).state_digest == begun.state_digest,
        "second begin cannot repeat native moves")
    reference._advance(reference_sim)
    reference_sim.step()
    expect(owner.advance().ok, "begun owner advances through normal runtime API")
    var first := packet(owner)
    snapshots.after_first_tick = first
    var reference_first := Candidate.native_witness(reference_sim)
    snapshots.reference_after_first_tick = reference_first
    expect(first.tick == 1 and first.clock_ms == 100 and first.native_witness == reference_first
        and first.state_digest == Candidate.state_digest(reference_first),
        "first native tick exactly matches original drill control")

    var same := start_owner(id)
    if same != null:
        var same_c0 := packet(same)
        expect(same_c0.state_digest == c0.state_digest and same_c0.meta == c0.meta,
            "same evaluation ID and inputs reconstruct identical C0 witness and meta")
        expect(same_c0.native_instance_id != first.native_instance_id and same_c0.tick == 0,
            "separate candidate owns separate native sim and was not advanced")
    var other := start_owner(Candidate.DEFINITION_ID + "/isolated-c0-02")
    if other != null:
        var other_c0 := packet(other)
        expect(other_c0.operation_id != c0.operation_id and other_c0.state_digest == c0.state_digest,
            "different operation ID is distinct while target C0 native state is deterministic")
    for field in ["capability", "definition_id", "definition_version", "roster_id", "seed", "difficulty", "mode"]:
        var wrong := Candidate.request()
        wrong[field] = 2 if field == "definition_version" else (20825 if field == "seed" else "unsupported")
        expect(not Candidate.prepare_fresh(wrong, id).ok, "normal factory rejects changed " + field)
    expect(Candidate.read_pinned("res://data/scenarios/cross_counter_drill.json", "0".repeat(64)).is_empty(),
        "source byte validator rejects a mismatched hash")
    var cancelled := Candidate.prepare_fresh(Candidate.request(), id + "-cancel")
    if expect(cancelled.ok, "prepare independent candidate for cancellation"):
        cancelled.owner.close()
        expect(not cancelled.owner.publish().ok and packet(owner).state_digest == first.state_digest,
            "cancelled prepared candidate cannot publish or disturb live owner")
    owner.close()
    expect(not owner.advance().ok and not owner.issue({"kind": "begin_evaluation", "operation_id": id}).ok,
        "closed owner rejects advance and begin")
    _finish(user_dir)

func json_value(value: Variant) -> Variant:
    if value is Vector2: return {"type": "Vector2", "x": value.x, "y": value.y}
    if value is Array:
        var out := []
        for item in value: out.append(json_value(item))
        return out
    if value is Dictionary:
        var out := {}
        for key in value: out[str(key)] = json_value(value[key])
        return out
    return value

func _finish(user_dir: String) -> void:
    var passed := checks.all(func(row): return row.pass)
    var result := {"schema": "cross-counter-engine-c0-proof/1", "status": "PASS" if passed else "FAIL",
        "checks_passed": checks.filter(func(row): return row.pass).size(), "checks_total": checks.size(),
        "checks": checks, "snapshots": json_value(snapshots), "user_data_dir": user_dir,
        "engine": Engine.get_version_info().string, "pid": OS.get_process_id(),
        "request": Candidate.request(), "input_pins": Candidate.INPUT_PINS,
        "normal_entry": "synthetic Preparer.prepare_fresh -> Owner.preview_initial_frame -> publish -> issue(begin_evaluation) -> advance",
        "public_host_installed": false, "restore_verified": false, "durable_transition_verified": false,
        "existing_user_saves_accessed": false, "policy_proposal_serial_implemented": false,
        "scope": "one-PC test-only native C0/begin/first-tick proof"}
    DirAccess.make_dir_recursive_absolute(output_dir)
    var witness_files := {}
    for label in snapshots:
        var row: Dictionary = snapshots[label]
        var native: Dictionary = row.get("native_witness", row)
        var path := output_dir.path_join(str(label) + ".native.bin")
        var raw := FileAccess.open(path, FileAccess.WRITE)
        if raw == null:
            passed = false
            continue
        raw.store_buffer(var_to_bytes(native))
        raw.close()
        witness_files[label] = {"file": path.get_file(), "sha256": FileAccess.get_sha256(path)}
    result.witness_files = witness_files
    var file := FileAccess.open(output_dir.path_join("result.json"), FileAccess.WRITE)
    if file == null:
        push_error("Cannot write isolated result")
        passed = false
    else:
        file.store_string(JSON.stringify(result, "\t", false, true) + "\n")
        file.close()
    for owner in owners: owner.close()
    Candidate.close_sim(reference_sim)
    reference_sim = null
    if reference != null: reference.free()
    print("CROSS_COUNTER_C0_RESULT ", result.status, " ", result.checks_passed, "/", result.checks_total)
    quit(0 if passed else 1)
