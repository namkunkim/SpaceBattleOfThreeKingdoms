extends SceneTree
const Adapter := preload("res://scripts/a05_j210_receipt_replay.gd")
const Viewer := preload("res://scripts/first_operation_replay_viewer.gd")
const Codec := preload("res://scripts/first_operation_replay_codec.gd")
const PIN := "fd014ec38dd11fd7739d30f305c37f176e1e6f21d7acb5044a907d49b1ba3d0b"
var checks := 0
var failures := 0
var source := ""
var output := ""
var rows: Array = []

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	source = OS.get_environment("SBTK_A05_RECORD_SOURCE").replace("\\", "/")
	output = OS.get_environment("SBTK_A05_REPLAY_ROOT").replace("\\", "/")
	var profile := OS.get_environment("APPDATA").replace("\\", "/")
	if not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless" \
			and output.is_absolute_path() and profile == output + "/profile/roaming" \
			and ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(profile + "/"),
			"isolated Windows headless profile"):
		_finish()
		return
	if not _check(FileAccess.get_sha256(source.path_join("record.json")) == PIN, "independently reviewed record pin"):
		_finish()
		return
	_reject(Adapter.open_record(source, ""), "receipt_replay_trust_required", "no trust anchor")
	_reject(Adapter.open_record(source, "0".repeat(64)), "receipt_replay_hash", "wrong trust anchor")
	_reject(Adapter.new().step(), "receipt_replay_closed", "factory is required before a session can step")
	_normal()
	_mismatches()
	_finish()

func _normal() -> void:
	var link := root.get_node("WorldLink")
	var brief: Variant = link.brief
	var outcome: Variant = link.outcome
	var routed: bool = link.routed()
	var opened := Adapter.open_record(source, PIN)
	if not _check(opened.ok, "full native preflight verifies every recorded frame before C0"):
		print(opened)
		return
	var replay: RefCounted = opened.replay
	_check(opened.frame.tick == 0 and opened.frame.clock_ms == 0 and opened.frame.events.size() == 2 \
		and not opened.frame.has("settlement"), "C0 has original spawn events and no settlement")
	_check(not replay.has_method("issue") and not replay.has_method("queue") and not replay.has_method("save") \
		and not replay.has_method("acknowledge") and not replay.has_method("request_external_payment") \
		and not replay.has_method("fork"), "session exposes no command save receipt or payment operations")
	opened.frame.projection.clear()
	opened.frame.events.clear()
	var first: Dictionary = replay.step()
	_check(first.ok and not first.done and first.frame.tick == 1 and first.frame.clock_ms == 100 \
		and first.frame.events.is_empty() and not first.frame.has("settlement"), "100 ms frame survives caller mutation of C0")
	first.frame.projection.clear()
	var last: Dictionary = replay.step()
	_check(last.ok and last.done and last.frame.tick == 2 and last.frame.clock_ms == 150 \
		and last.frame.events.size() == 2 and last.frame.events[1].kind == "battle_end" \
		and last.frame.settlement.id == "f0aecf60fc74d397bf9dec50b6f8b2ca/battle_settlement/1" \
		and last.frame.settlement.receipt_digest == "02f703bc93518d0caad0da6d5493100732f2991bd149d736c656371c0f8a2996" \
		and last.frame.projection.outcome.result.is_empty(), "150 ms completion displays the authentic receipt without changing native result")
	_reject(replay.step(), "receipt_replay_finished", "terminal step cannot repeat settlement")
	replay.close()
	replay.close()
	_reject(replay.step(), "receipt_replay_closed", "close is idempotent and blocks steps")
	var viewer := Viewer.new()
	root.add_child(viewer)
	opened = Adapter.open_record(source, PIN)
	if not _check(opened.ok and viewer.attach_playback(opened.replay, opened.frame).ok, "existing viewer attaches dedicated C0 session"):
		viewer.free()
		return
	viewer.step_replay()
	_check(viewer._frame.clock_ms == 100 and not viewer._finished and viewer._result.text.is_empty(), "viewer is not prematurely complete")
	viewer.step_replay()
	_check(viewer._finished and viewer._frame.clock_ms == 150 and viewer._step.disabled \
		and viewer._result.text.contains("f0aecf60fc74d397bf9dec50b6f8b2ca/battle_settlement/1") \
		and viewer._result.text.contains("annihilation") and not viewer._result.text.contains("replay_missing_settlement"),
		"existing viewer completes normally at the same recorded receipt")
	viewer.step_replay()
	_check(viewer._frame.tick == 2, "viewer terminal action does not advance")
	viewer.free()
	_reject(opened.replay.step(), "receipt_replay_closed", "viewer teardown closes only its dedicated owner")
	opened = Adapter.open_record(source, PIN)
	if _check(opened.ok, "new session can reopen the immutable record at C0"):
		opened.replay.close()
		_reject(opened.replay.step(), "receipt_replay_closed", "early cancellation releases native owner")
	_check(link.brief == brief and link.outcome == outcome and link.routed() == routed, "replay leaves WorldLink unchanged")
	var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source.path_join("record.json")))
	_reject(Codec._normalize(record), "replay_invalid_bundle", "public v1 codec still rejects the internal record")
	viewer = Viewer.new()
	root.add_child(viewer)
	_reject(viewer.open_file(source.path_join("record.json")), "replay_development_only", "public entry gate remains enforced")
	viewer.free()

func _mismatches() -> void:
	for label: String in ["artifact_hash", "input", "clock", "identity", "key", "digest", "outcome", "summary", "events",
			"projection", "initial_owner", "terminal_owner", "effect", "previous_generation", "snapshot_code", "slot_checksum",
			"witness_shape", "missing_slot"]:
		var directory := output.path_join("cases").path_join(label)
		DirAccess.make_dir_recursive_absolute(directory.path_join("fixtures"))
		for name: String in Adapter.ARTIFACTS + ["record.json"]:
			_write(directory.path_join(name), FileAccess.get_file_as_bytes(source.path_join(name)))
		for name: String in Adapter.FIXTURES:
			_write(directory.path_join("fixtures/" + name), FileAccess.get_file_as_bytes(source.path_join("fixtures/" + name)))
		var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("record.json")))
		var witness: Dictionary = bytes_to_var(FileAccess.get_file_as_bytes(directory.path_join("observations.bin")))
		var expected := ""
		var update_witness := false
		match label:
			"artifact_hash":
				_write(directory.path_join("observations.bin"), PackedByteArray([1, 2, 3]))
				expected = "receipt_replay_hash"
			"input":
				witness.input.seed += 1
				update_witness = true
				expected = "receipt_replay_input"
			"clock":
				witness.frames[1].summary.clock_ms = 99
				update_witness = true
				expected = "receipt_replay_frame"
			"identity":
				record.operation_id = "0".repeat(32)
				expected = "receipt_replay_identity"
			"key":
				record.settlement_key = "different/battle_settlement/1"
				expected = "receipt_replay_identity"
			"digest":
				record.receipt_digest = "0".repeat(64)
				expected = "receipt_replay_receipt"
			"outcome":
				record.verified_outcome.id = "different"
				expected = "receipt_replay_outcome"
			"summary":
				record.terminal_summary.fp = "0".repeat(64)
				expected = "receipt_replay_terminal"
			"events":
				record.events.pop_back()
				expected = "receipt_replay_terminal"
			"projection":
				witness.frames[1].projection.squadrons[0].pos.x += 1
				update_witness = true
				expected = "receipt_replay_diverged"
			"initial_owner":
				witness.frames[0].owner.state.cp += 1
				update_witness = true
				expected = "receipt_replay_diverged"
			"terminal_owner":
				witness.frames[2].owner.state.cp += 1
				update_witness = true
				expected = "receipt_replay_witness"
			"effect":
				witness.native_effect.clock_ms = 200
				update_witness = true
				expected = "receipt_replay_receipt"
			"previous_generation":
				var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("terminal-slot.previous")))
				var previous: Dictionary = JSON.parse_string(envelope.body)
				previous.generation = 0
				envelope.body = JSON.stringify(previous, "", true, true)
				envelope.sha256 = envelope.body.sha256_text()
				_write(directory.path_join("terminal-slot.previous"), JSON.stringify(envelope).to_utf8_buffer())
				record.artifact_sha256["terminal-slot.previous"] = FileAccess.get_sha256(directory.path_join("terminal-slot.previous"))
				record.native_previous_sha256 = record.artifact_sha256["terminal-slot.previous"]
				expected = "receipt_replay_identity"
			"snapshot_code":
				var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("terminal-slot.save")))
				var payload: Dictionary = JSON.parse_string(envelope.body)
				var packet: Dictionary = bytes_to_var(Marshalls.base64_to_raw(payload.snapshot))
				packet.code["battle_sim.gd"] = "0".repeat(64)
				payload.snapshot = Marshalls.raw_to_base64(var_to_bytes(packet))
				witness.receipt = payload
				witness.terminal_packet = packet
				update_witness = true
				envelope.body = JSON.stringify(payload, "", true, true)
				envelope.sha256 = envelope.body.sha256_text()
				_write(directory.path_join("terminal-slot.save"), JSON.stringify(envelope).to_utf8_buffer())
				record.artifact_sha256["terminal-slot.save"] = FileAccess.get_sha256(directory.path_join("terminal-slot.save"))
				record.native_slot_sha256 = record.artifact_sha256["terminal-slot.save"]
				expected = "receipt_replay_snapshot"
			"slot_checksum":
				var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(directory.path_join("terminal-slot.save")))
				envelope.sha256 = "0".repeat(64)
				_write(directory.path_join("terminal-slot.save"), JSON.stringify(envelope).to_utf8_buffer())
				record.artifact_sha256["terminal-slot.save"] = FileAccess.get_sha256(directory.path_join("terminal-slot.save"))
				expected = "receipt_replay_slot"
			"witness_shape":
				witness.frames = []
				update_witness = true
				expected = "receipt_replay_witness"
			"missing_slot":
				DirAccess.remove_absolute(directory.path_join("terminal-slot.save"))
				expected = "receipt_replay_read"
		if update_witness:
			_write(directory.path_join("observations.bin"), var_to_bytes(witness))
			record.artifact_sha256["observations.bin"] = FileAccess.get_sha256(directory.path_join("observations.bin"))
		_write(directory.path_join("record.json"), JSON.stringify(record, "  ", true, true).to_utf8_buffer())
		# These separately trusted copies probe semantic validation after hashes pass.
		var test_pin := FileAccess.get_sha256(directory.path_join("record.json"))
		_reject(Adapter.open_record(directory, test_pin), expected, "reject " + label)

func _write(path: String, bytes: PackedByteArray) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_buffer(bytes)
	file.close()

func _reject(result: Dictionary, error: String, label: String) -> void:
	_check(not result.ok and not result.has("replay") and result.get("error") == error, label + " [" + str(result.get("error")) + "]")
	if result.ok and result.has("replay"):
		result.replay.close()

func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	rows.append({"pass": condition, "label": label})
	print("A05_J210_REPLAY_CHECK ", condition, " ", label)
	return condition

func _finish() -> void:
	_write(output.path_join("matrix.json"), JSON.stringify({"checks": checks, "passed": checks - failures, "rows": rows}, "  ").to_utf8_buffer())
	print("A05_J210_READONLY_REPLAY ", checks - failures, "/", checks)
	quit(0 if failures == 0 else 1)
