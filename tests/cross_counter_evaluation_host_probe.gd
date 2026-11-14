extends "res://tests/cross_counter_publication_guard.gd"
## Private UI integration of the unchanged evaluator and reviewed final publication guard.
const EvaluationHost := preload("res://tests/support/cross_counter_evaluation_host.gd")
var host: EvaluationHost
var current_fence := ""
var next_fence := ""
var next_model: Dictionary = {}
var save_serial := 0
var save_session := ""

func _initialize() -> void: _setup.call_deferred()

func _setup() -> void:
    root.size = Vector2i(1600, 900)
    root.content_scale_size = Vector2i(1600, 900)
    root.title = "Cross Counter — isolated evaluation host"
    host = EvaluationHost.new()
    host.dispatch = _host_action
    root.add_child(host)
    save_session = Crypto.new().generate_random_bytes(16).hex_encode()
    super._initialize()

func _handle(request: Dictionary) -> Dictionary:
    var action: String = request.get("action", "")
    if action == "host_observe": return {"ok": true, "host": host.snapshot(), "observation": _observation(live)}
    if action == "host_control":
        var point := Vector2(float(request.get("x", 900)), float(request.get("y", 500)))
        var result: Dictionary = host.activate(request.get("control", ""), point)
        return {"ok": result.ok, "result": result, "host": host.snapshot(), "observation": _observation(live)}
    if action == "capture":
        if request.get("name") not in ["c0", "restored", "progressed"]: return Codec.fail("invalid_capture_name")
        if DisplayServer.get_name() == "headless": return {"ok": true, "rendered": false}
        _capture.call_deferred(request.name)
        return {"ok": true, "rendered": true}
    var before: Dictionary = host.snapshot().model
    var result: Dictionary = super._handle(request)
    if action == "prepare_install" and result.ok:
        var packet: Dictionary = bytes_to_var(Marshalls.base64_to_raw(request.record.packet_b64))
        var ready := EvaluationHost.prepare_model(publication_preview, packet)
        if not ready.ok:
            _cancel_publication()
            return ready
        next_model = ready.model
        next_fence = request.fence_json
        _expect(host.snapshot().model == before, "UI preflight does not replace the installed model")
    if action == "publish_guarded":
        if result.ok:
            _expect(host.operation_owner == live and host.model.tick == result.observation.packet.tick,
                "guarded publication swaps host owner and frame together")
        else:
            _expect(host.snapshot().model == before, "stale publication preserves the installed host model")
        next_model = {}
        next_fence = ""
    if action == "cancel":
        next_model = {}
        next_fence = ""
    result["host"] = host.snapshot()
    return result

func _locked_publish(request: Dictionary) -> Dictionary:
    if next_model.is_empty(): return Codec.fail("host_preflight_required")
    var result: Dictionary = super._locked_publish(request)
    if result.ok:
        # Synchronous, non-failing install of the preflighted copy while the same OS guard is held.
        host.install(live, next_model)
        current_fence = next_fence
    return result

func _host_action(action: String, payload: Dictionary) -> Dictionary:
    if live == null or host.operation_owner != live: return Codec.fail("host_owner_mismatch")
    if action == "save": return _save_checkpoint()
    if action == "load":
        var read := _helper("read")
        if not read.get("ok", false): return read
        var ready := _handle({"action": "prepare_install", "record": read.record, "fence_json": current_fence})
        if not ready.ok: return ready
        return _handle({"action": "publish_guarded", "case": "host-load"})
    return WindowsSlot.with_lock(database_path + ".publish", _locked_live_action.bind(action, payload))

func _locked_live_action(action: String, payload: Dictionary) -> Dictionary:
    var authorized := _helper("read")
    if not authorized.get("ok", false): return authorized
    if action == "begin": return live.issue({"kind": "begin_evaluation", "operation_id": operation_id})
    if action == "step": return live.advance()
    if action in ["move", "stop"]:
        var command := {"kind": action, "operation_id": operation_id, "side": 0, "ids": [1]}
        if action == "move": command.point = payload.point
        return live.queue(command)
    return Codec.fail("unknown_host_action")

func _save_checkpoint() -> Dictionary:
    var captured: Dictionary = Codec.capture(live)
    if not captured.ok: return captured
    var packet: Dictionary = captured.packet
    var bind := Codec.binding_for(packet)
    var checked := Codec.prepare_restore(packet, bind, Candidate.prepare_fresh)
    if not checked.ok: return checked
    checked.owner.close()
    save_serial += 1
    var name := "host-save-%s-%d" % [save_session, save_serial]
    var fence_value: Dictionary = JSON.parse_string(current_fence)
    _write(name + ".json", {"ok": true, "published": false, "pid": OS.get_process_id(),
        "operation_id": operation_id, "base_sha": fence_value.checkpoint_sha,
        "packet_b64": Marshalls.raw_to_base64(var_to_bytes(packet)), "binding": bind,
        "observation": _observation(live)})
    var result := _helper("save", output_dir.path_join(name + ".json"), name)
    if result.get("ok", false): current_fence = result.fence_json
    return result

func _helper(mode: String, artifact := "", intent := "") -> Dictionary:
    var output: Array = []
    var arguments := PackedStringArray(["-B", ProjectSettings.globalize_path("res://tests/cross_counter_evaluation_host_probe.py"),
        "--helper", mode, "--db", database_path, "--fence-b64", Marshalls.raw_to_base64(current_fence.to_utf8_buffer())])
    if mode == "save": arguments.append_array(["--artifact", artifact, "--intent", intent, "--engine-pid", str(OS.get_process_id())])
    var status := OS.execute(python_path, arguments, output, true, false)
    if status != 0 or output.size() != 1:
        return {"ok": false, "error": "host_authority_helper_failed", "exit_code": status, "output": output}
    var reply: Variant = JSON.parse_string(output[0])
    return reply if reply is Dictionary else Codec.fail("invalid_host_authority_reply")

func _capture(name: String) -> void:
    await process_frame
    await RenderingServer.frame_post_draw
    var picture := root.get_texture().get_image()
    var error := picture.save_png(output_dir.path_join(name + ".png"))
    _write(name + "-capture.json", {"ok": error == OK, "width": picture.get_width(), "height": picture.get_height(),
        "tick": host.model.tick, "clock_ms": host.model.clock_ms, "pid": OS.get_process_id()})

func _finish(intended: bool) -> void:
    if host != null:
        _write("host-final.json", host.snapshot())
        host.operation_owner = null
    super._finish(intended)
