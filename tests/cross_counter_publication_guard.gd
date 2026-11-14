extends "res://tests/cross_counter_owner_fencing_bridge.gd"
## Test-only final publication fence. Heavy replay stays outside the native mutex.
const WindowsSlot := preload("res://scripts/o07_windows_slot.gd")
var publication: RefCounted
var publication_preview: Dictionary = {}
var publication_sha := ""
var publication_fence := ""
var database_path := ""
var python_path := ""
var publications: Array[Dictionary] = []

func _initialize() -> void:
    database_path = OS.get_environment("SBTK_PUBLICATION_DB").replace("\\", "/")
    python_path = OS.get_environment("SBTK_PUBLICATION_PYTHON")
    var directory := OS.get_environment("SBTK_CROSS_COUNTER_RESULT_DIR").replace("\\", "/").trim_suffix("/")
    if database_path != directory.get_base_dir().path_join("authority.sqlite") \
            or not FileAccess.file_exists(python_path) or not ClassDB.class_exists(WindowsSlot.NATIVE):
        push_error("Unbound publication guard")
        quit(93)
        return
    super._initialize()

func _handle(request: Dictionary) -> Dictionary:
    var action: String = request.get("action", "")
    if action == "install": return Codec.fail("unguarded_install_disabled")
    if action == "prepare_install":
        if publication != null: return Codec.fail("publication_already_prepared")
        if not request.get("record") is Dictionary or not request.get("fence_json") is String:
            return Codec.fail("invalid_publication_input")
        var before := _observation(live)
        var started_usec := Time.get_ticks_usec()
        var restored := _restore(request.record)
        if not restored.ok: return {"ok": false, "error": restored.error, "observation": _observation(live)}
        publication = restored.owner
        publication_preview = publication.preview_initial_frame().frame
        publication_sha = request.record.binding.packet_sha256
        # Preserve the canonical integer representation for the Python authority.
        publication_fence = request.fence_json
        _expect(not publication.advance().ok, "publication replay is detached before the mutex")
        _expect(_observation(live) == before, "preparation preserves old live native state")
        return {"ok": true, "published": false, "packet_sha256": publication_sha,
            "prepare_usec": Time.get_ticks_usec() - started_usec, "observation": before}
    if action == "publish_guarded":
        if publication == null: return Codec.fail("publication_not_prepared")
        var before := _observation(live)
        var started_usec := Time.get_ticks_usec()
        var result := WindowsSlot.with_lock(database_path + ".publish", _locked_publish.bind(request))
        var completed_usec := Time.get_ticks_usec()
        # Expensive diagnostics and candidate cleanup are outside the mutex.
        _cancel_publication()
        result["observation"] = _observation(live)
        result["call_usec"] = completed_usec - started_usec
        result["case"] = request.get("case", "normal")
        if not result.ok:
            _expect(result.observation == before, "rejected final fence preserves old instance, packet and pending")
        else:
            _expect(result.observation.packet_sha256 == result.committed_sha,
                "installed real checkpoint equals the checked authority head")
        publications.append({"case": result.case, "ok": result.ok, "error": result.get("error", ""),
            "call_usec": result.call_usec, "mutex_usec": result.get("mutex_usec", 0),
            "barrier_usec": result.get("barrier_usec", 0), "authority_pid": result.get("authority_pid", 0)})
        return result
    if action == "cancel": _cancel_publication()
    return super._handle(request)

func _locked_publish(request: Dictionary) -> Dictionary:
    var started_usec := Time.get_ticks_usec()
    var output: Array = []
    var arguments := PackedStringArray(["-B", ProjectSettings.globalize_path("res://tests/cross_counter_publication_guard.py"),
        "--authority-read", "--db", database_path, "--fence-b64", Marshalls.raw_to_base64(publication_fence.to_utf8_buffer())])
    # This helper closes its short SQLite transaction before returning.
    # The native mutex, not a SQLite transaction, spans this IPC and the final swap.
    var status := OS.execute(python_path, arguments, output, true, false)
    if status != 0 or output.size() != 1:
        var failure := _timed_fail("authority_helper_failed", started_usec)
        failure["helper_exit_code"] = status
        failure["helper_output"] = output
        return failure
    var reply: Variant = JSON.parse_string(output[0])
    if not reply is Dictionary or reply.get("transaction_closed") != true:
        return _timed_fail("invalid_authority_reply", started_usec)
    if reply.has("error"): return _timed_fail(reply.error, started_usec)
    if reply.get("checkpoint_sha") != publication_sha or reply.get("operation_id") != operation_id:
        return _timed_fail("publication_record_mismatch", started_usec)
    var barrier_usec := 0
    if request.get("barrier") == "contending-transfer":
        var barrier_start := Time.get_ticks_usec()
        _write("publication-entered.json", {"pid": OS.get_process_id(), "authority_pid": reply.pid,
            "checkpoint_sha": publication_sha, "transaction_closed": true})
        # A bounded test latch creates the ordering; this is not a product timeout/lease.
        while not FileAccess.file_exists(output_dir.path_join("publication-release.json")):
            if Time.get_ticks_usec() - barrier_start > 5000000:
                return _timed_fail("test_barrier_timeout", started_usec)
            OS.delay_msec(2)
        barrier_usec = Time.get_ticks_usec() - barrier_start
    var published: Dictionary = publication.publish()
    if not published.ok or published.get("frame") != publication_preview:
        return _timed_fail("publication_frame_mismatch", started_usec)
    var previous := live
    live = publication
    publication = null
    if previous != null: previous.close()
    if staged != null: staged.close()
    staged = null
    staged_packet = {}
    return {"ok": true, "published": true, "committed_sha": publication_sha,
        "authority_pid": reply.pid, "mutex_usec": Time.get_ticks_usec() - started_usec,
        "barrier_usec": barrier_usec, "transaction_closed": true}

func _timed_fail(error: String, started_usec: int) -> Dictionary:
    return {"ok": false, "error": error, "mutex_usec": Time.get_ticks_usec() - started_usec}

func _cancel_publication() -> void:
    if publication != null: publication.close()
    publication = null
    publication_preview = {}
    publication_sha = ""
    publication_fence = ""

func _finish(intended: bool) -> void:
    _cancel_publication()
    _write("publications.json", {"publications": publications, "pid": OS.get_process_id(),
        "guard": "O07Win32 exclusive file handle", "public_activation": false,
        "publication_order_only": true, "lifetime_owner_exclusion": false})
    super._finish(intended)
