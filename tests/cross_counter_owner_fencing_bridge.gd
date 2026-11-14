extends SceneTree
## Private persistent evaluator IPC; SQLite authority belongs to the test coordinator.
## A local cached owner can still compute after revocation. Only fenced durable work is authoritative.
const Candidate := preload("res://tests/support/cross_counter_evaluation.gd")
const Codec := preload("res://tests/support/cross_counter_evaluation_checkpoint.gd")
var output_dir := ""
var operation_id := ""
var live: RefCounted
var staged: RefCounted
var staged_packet: Dictionary = {}
var sequence := 1
var checks: Array[Dictionary] = []
var expires_at := 0

func _initialize() -> void:
    var root_path := OS.get_environment("SBTK_CROSS_COUNTER_ISOLATED_ROOT").replace("\\", "/").trim_suffix("/")
    output_dir = OS.get_environment("SBTK_CROSS_COUNTER_RESULT_DIR").replace("\\", "/").trim_suffix("/")
    operation_id = OS.get_environment("SBTK_CROSS_COUNTER_OPERATION_ID")
    if root_path.is_empty() or not OS.get_user_data_dir().replace("\\", "/").begins_with(root_path + "/") \
            or output_dir.is_empty() or root_path != output_dir + "/profile" \
            or not operation_id.begins_with(Candidate.DEFINITION_ID + "/"):
        push_error("Unbound fencing bridge")
        quit(90)
        return
    expires_at = Time.get_ticks_msec() + 600000
    _write("ready.json", {"pid": OS.get_process_id(), "engine": Engine.get_version_info().string,
        "user_data_dir": OS.get_user_data_dir(), "operation_id": operation_id, "live": false})

func _process(_delta: float) -> bool:
    if output_dir.is_empty(): return false
    if Time.get_ticks_msec() > expires_at:
        _finish(false)
        return false
    var request_path := output_dir.path_join("request-%03d.json" % sequence)
    if not FileAccess.file_exists(request_path): return false
    # A just-renamed file may exist while Windows temporarily denies opening it.
    # Do not consume the sequence or parse an empty fallback on that transient failure.
    var request_file := FileAccess.open(request_path, FileAccess.READ)
    if request_file == null: return false
    var request_text := request_file.get_as_text()
    request_file.close()
    var request: Variant = JSON.parse_string(request_text)
    var reply := {"ok": false, "error": "invalid_request"}
    if request is Dictionary:
        reply = _handle(request)
    reply["pid"] = OS.get_process_id()
    reply["sequence"] = sequence
    _write("response-%03d.json" % sequence, reply)
    sequence += 1
    if request is Dictionary and request.get("action") == "shutdown": _finish(true)
    return false

func _expect(value: bool, label: String) -> bool:
    checks.append({"pass": value, "name": label})
    print("CROSS_COUNTER_FENCE_ENGINE ", value, " ", label)
    return value

func _observation(owner: RefCounted) -> Dictionary:
    if owner == null: return {"live": false}
    var diagnostic: Dictionary = owner.capture_checkpoint().packet
    var packet: Dictionary = Codec.from_diagnostic(diagnostic).packet
    return {"live": true, "packet": packet, "packet_sha256": Codec.packet_digest(packet),
        "native_instance_id": diagnostic.native_instance_id, "native_witness": diagnostic.native_witness}

func _restore(record: Dictionary) -> Dictionary:
    var blob := Marshalls.base64_to_raw(record.get("packet_b64", ""))
    if not record.get("binding") is Dictionary or blob.size() > Codec.MAX_BYTES \
            or Codec.sha(blob) != record.binding.get("packet_sha256"):
        return Codec.fail("authority_blob_hash_mismatch")
    var packet: Variant = bytes_to_var(blob)
    if not packet is Dictionary or packet.get("operation_id") != operation_id \
            or record.get("operation_id") != operation_id:
        return Codec.fail("authority_operation_mismatch")
    var restored := Codec.prepare_restore(packet, record.binding, Candidate.prepare_fresh)
    if restored.ok: restored["packet"] = packet
    return restored

func _handle(request: Dictionary) -> Dictionary:
    var action: String = request.get("action", "")
    if action == "observe": return {"ok": true, "observation": _observation(live), "staged": staged != null}
    if action == "cancel":
        if staged != null: staged.close()
        staged = null
        staged_packet = {}
        return {"ok": true, "observation": _observation(live)}
    if action == "shutdown": return {"ok": true, "observation": _observation(live)}
    if action == "install":
        # This assertion is supplied only by the private test coordinator after a fenced read.
        # It is not an authenticated product RPC or a cross-process publication protocol.
        if request.get("fixture_authority_validated") != true or not request.get("record") is Dictionary:
            return Codec.fail("fixture_authority_required")
        var before := _observation(live)
        var restored := _restore(request.record)
        if not restored.ok: return {"ok": false, "error": restored.error, "observation": _observation(live)}
        var candidate: RefCounted = restored.owner
        _expect(not candidate.advance().ok, "restored candidate remains detached before install")
        _expect(_observation(live) == before, "detached replay preserves previous live owner")
        var published: Dictionary = candidate.publish()
        if not _expect(published.ok, "publish only the validated committed checkpoint"):
            candidate.close()
            return Codec.fail("publish_failed")
        var old := live
        live = candidate
        if old != null: old.close()
        if staged != null: staged.close()
        staged = null
        staged_packet = {}
        var after := _observation(live)
        _expect(after.packet_sha256 == request.record.binding.packet_sha256,
            "installed packet equals authority checkpoint byte hash")
        var begin: Dictionary = live.issue({"kind": "begin_evaluation", "operation_id": operation_id}) if after.packet.bootstrap_done else {}
        _expect(not after.packet.bootstrap_done or (begin.get("already_started") == true \
            and _observation(live) == after), "restart cannot duplicate already committed bootstrap")
        return {"ok": true, "observation": after}
    if action == "stage":
        if live == null or staged != null: return Codec.fail("stage_unavailable")
        var before := _observation(live)
        if before.packet_sha256 != request.get("base_sha"): return Codec.fail("local_base_mismatch")
        var replay := Codec.prepare_restore(Codec.capture(live).packet,
            Codec.binding_for(Codec.capture(live).packet), Candidate.prepare_fresh)
        if not replay.ok: return replay
        var scratch: RefCounted = replay.owner
        if not scratch.publish().ok:
            scratch.close()
            return Codec.fail("scratch_publish_failed")
        var success := true
        if request.get("plan") == "start_pending":
            success = scratch.issue({"kind": "begin_evaluation", "operation_id": operation_id}).ok
            success = scratch.advance().ok and success
            success = scratch.queue({"kind": "stop", "operation_id": operation_id, "side": 0, "ids": [1]}).ok and success
        elif request.get("plan") == "advance":
            success = scratch.issue({"kind": "begin_evaluation", "operation_id": operation_id}).get("already_started") == true
            success = scratch.advance().ok and success
        else:
            success = false
        var diagnostic := _observation(scratch)
        var packet: Dictionary = Codec.capture(scratch).packet
        scratch.close()
        if not success: return Codec.fail("stage_plan_failed")
        var bind := Codec.binding_for(packet)
        var validated := Codec.prepare_restore(packet, bind, Candidate.prepare_fresh)
        if not _expect(validated.ok, "staged real native checkpoint passes detached replay witness"):
            return Codec.fail("stage_replay_failed")
        staged = validated.owner
        staged_packet = packet
        _expect(not staged.advance().ok, "staged validated replacement remains unpublished")
        _expect(_observation(live) == before, "staging preserves live packet, pending commands and native instance")
        return {"ok": true, "published": false, "base_sha": before.packet_sha256,
            "packet_b64": Marshalls.raw_to_base64(var_to_bytes(packet)), "binding": bind,
            "operation_id": operation_id, "observation": diagnostic, "old_observation": before}
    return Codec.fail("unknown_action")

func _write(name: String, value: Dictionary) -> void:
    var file: FileAccess
    for attempt in 100:
        file = FileAccess.open(output_dir.path_join(name + ".tmp"), FileAccess.WRITE)
        if file != null: break
        OS.delay_msec(10)
    if file == null:
        push_error("IPC response unavailable: " + name)
        quit(91)
        return
    file.store_string(JSON.stringify(value, "\t", false, true) + "\n")
    file.close()
    for attempt in 100:
        if DirAccess.rename_absolute(output_dir.path_join(name + ".tmp"), output_dir.path_join(name)) == OK: return
        OS.delay_msec(10)
    push_error("IPC response rename unavailable: " + name)
    quit(92)

func _finish(intended: bool) -> void:
    var passed := intended and checks.all(func(row): return row.pass)
    if staged != null: staged.close()
    if live != null: live.close()
    staged = null
    live = null
    _write("result.json", {"schema": "cross-counter-owner-fencing-engine/1",
        "status": "PASS" if passed else "FAIL", "checks": checks,
        "checks_total": checks.size(), "checks_passed": checks.filter(func(row): return row.pass).size(),
        "pid": OS.get_process_id(), "public_activation": false, "real_service_authentication": false})
    quit(0 if passed else 1)
