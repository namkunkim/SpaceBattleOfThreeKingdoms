extends SceneTree
## Local authority bridge: prepare a detached C0 blob, or validate a committed blob before publish.
const Candidate := preload("res://tests/support/cross_counter_evaluation.gd")
const Codec := preload("res://tests/support/cross_counter_evaluation_checkpoint.gd")
var checks: Array[Dictionary] = []
var owners: Array[RefCounted] = []
var output_dir := ""

func _initialize() -> void: _run.call_deferred()

func expect(value: bool, label: String) -> bool:
    checks.append({"pass": value, "name": label})
    print("CROSS_COUNTER_DURABLE_CHECK ", value, " ", label)
    return value

func _run() -> void:
    var root_path := OS.get_environment("SBTK_CROSS_COUNTER_ISOLATED_ROOT").replace("\\", "/").trim_suffix("/")
    output_dir = OS.get_environment("SBTK_CROSS_COUNTER_RESULT_DIR").replace("\\", "/")
    var input_path := OS.get_environment("SBTK_CROSS_COUNTER_BRIDGE_INPUT").replace("\\", "/")
    if root_path.is_empty() or not OS.get_user_data_dir().replace("\\", "/").begins_with(root_path + "/") \
            or output_dir.is_empty() or not input_path.begins_with(output_dir + "/"):
        push_error("Refusing an unbound bridge invocation")
        quit(90)
        return
    var input: Variant = JSON.parse_string(FileAccess.get_file_as_string(input_path))
    if not input is Dictionary or input.get("mode") not in ["prepare", "restore"]:
        _finish({"mode": "invalid", "error": "invalid_bridge_input"}, false)
        return
    if input.mode == "prepare":
        _prepare(input)
    else:
        _restore(input)

func _prepare(input: Dictionary) -> void:
    var id: Variant = input.get("operation_id")
    if not id is String:
        _finish({"mode": "prepare", "error": "invalid_operation_id"}, false)
        return
    var prepared := Candidate.prepare_fresh(Candidate.request(), id)
    if not expect(prepared.ok, "normal factory validates and prepares detached real C0"):
        _finish({"mode": "prepare"}, false)
        return
    owners.append(prepared.owner)
    var packet: Dictionary = prepared.checkpoint
    var bind := Codec.binding_for(packet)
    expect(Codec.validate(packet, bind).ok and packet.tick == 0 and packet.clock_ms == 0 \
        and not packet.bootstrap_done and packet.commands.is_empty() and packet.pending.is_empty(),
        "prepared envelope is a strict unstarted C0")
    expect(not prepared.owner.advance().ok, "preparation does not publish or grant execution")
    var saved := Codec.write_new("user://cross-counter-evaluation/prepared.ccpeval", packet)
    expect(saved.ok and saved.binding == bind, "write actual bound C0 checkpoint before authority transaction")
    var bytes := var_to_bytes(packet)
    _finish({"mode": "prepare", "published": false, "operation_id": id, "packet": packet,
        "packet_b64": Marshalls.raw_to_base64(bytes), "binding": bind,
        "packet_sha256": Codec.sha(bytes), "checkpoint_file_sha256": saved.get("file_sha256", "")}, true)

func _restore(input: Dictionary) -> void:
    # This is an isolated fixture coordinator assertion, not real-service authentication.
    if input.get("authority_committed") != true or not input.get("record") is Dictionary:
        _finish({"mode": "restore", "error": "committed_fixture_record_required"}, false)
        return
    var record: Dictionary = input.record
    var old := Candidate.prepare_fresh(Candidate.request(), Candidate.DEFINITION_ID + "/preserved-old-owner")
    if not expect(old.ok, "prepare independent old live owner for replacement guard"):
        _finish({"mode": "restore"}, false)
        return
    owners.append(old.owner)
    expect(old.owner.publish().ok and old.owner.issue({"kind": "begin_evaluation", "operation_id": Candidate.DEFINITION_ID + "/preserved-old-owner"}).ok
        and old.owner.advance().ok, "old owner is live at tick1 before candidate restoration")
    var old_packet: Dictionary = Codec.capture(old.owner).packet
    var old_digest := Codec.packet_digest(old_packet)
    var blob: PackedByteArray = Marshalls.base64_to_raw(record.get("packet_b64", ""))
    var packet: Variant = null
    var restored: Dictionary
    if not record.get("binding") is Dictionary or Codec.sha(blob) != record.binding.get("packet_sha256"):
        restored = Codec.fail("authority_blob_hash_mismatch")
    elif blob.size() > Codec.MAX_BYTES:
        restored = Codec.fail("authority_blob_too_large")
    else:
        packet = bytes_to_var(blob)
        if not packet is Dictionary or packet.get("operation_id") != record.get("operation_id"):
            restored = Codec.fail("authority_operation_mismatch")
        else:
            restored = Codec.prepare_restore(packet, record.binding, Candidate.prepare_fresh)
    if input.get("expect_rejection") == true:
        expect(not restored.ok, "bad committed envelope is rejected before publication")
        if restored.ok:
            owners.append(restored.owner)
            restored.owner.close()
        var unchanged := Codec.packet_digest(Codec.capture(old.owner).packet) == old_digest
        expect(unchanged, "failed candidate leaves the old live owner unchanged")
        _finish({"mode": "restore", "rejected": true, "published": false,
            "old_owner_unchanged": unchanged, "error": restored.get("error", "unexpected_success")}, true)
        return
    if not expect(restored.ok, "committed C0 restores and validates its witness before publish"):
        _finish({"mode": "restore", "error": restored.get("error", "restore_failed"),
            "old_owner_unchanged": Codec.packet_digest(Codec.capture(old.owner).packet) == old_digest}, false)
        return
    owners.append(restored.owner)
    expect(not restored.owner.advance().ok, "validated replacement remains detached before publish")
    expect(Codec.packet_digest(Codec.capture(old.owner).packet) == old_digest,
        "successful validation also preserves old owner until publication")
    var preview: Dictionary = restored.owner.preview_initial_frame()
    var published: Dictionary = restored.owner.publish()
    expect(preview.ok and published.ok and published.frame == preview.frame
        and published.frame.tick == 0 and published.frame.clock_ms == 0, "publish exact validated committed C0 frame")
    var captured: Dictionary = Codec.capture(restored.owner).packet
    expect(Codec.packet_digest(captured) == record.binding.packet_sha256 and captured.operation_id == record.operation_id,
        "published operation ID and complete checkpoint equal the committed authority record")
    old.owner.close()
    expect(not old.owner.advance().ok, "replace and close old owner only after candidate publication")
    _finish({"mode": "restore", "published": true, "rejected": false,
        "operation_id": captured.operation_id, "packet_sha256": Codec.packet_digest(captured),
        "state_digest": captured.state_digest, "tick": captured.tick, "clock_ms": captured.clock_ms,
        "bootstrap_done": captured.bootstrap_done, "event_cursor": captured.event_cursor}, true)

func _finish(details: Dictionary, intended: bool) -> void:
    var passed := intended and checks.all(func(row): return row.pass)
    var result := {"schema": "cross-counter-durable-bridge-proof/1", "status": "PASS" if passed else "FAIL",
        "checks": checks, "checks_passed": checks.filter(func(row): return row.pass).size(), "checks_total": checks.size(),
        "details": details, "pid": OS.get_process_id(), "engine": Engine.get_version_info().string,
        "user_data_dir": OS.get_user_data_dir(), "public_activation": false,
        "existing_user_saves_accessed": false, "real_service_authentication": false,
        "scope": "single-PC evaluation authority bridge"}
    DirAccess.make_dir_recursive_absolute(output_dir)
    var file := FileAccess.open(output_dir.path_join("result.json"), FileAccess.WRITE)
    if file == null:
        passed = false
    else:
        file.store_string(JSON.stringify(result, "\t", false, true) + "\n")
        file.close()
    for owner in owners: owner.close()
    print("CROSS_COUNTER_DURABLE_BRIDGE ", result.status)
    quit(0 if passed else 1)
