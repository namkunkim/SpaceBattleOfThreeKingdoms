extends SceneTree

const Adapter := preload("res://scripts/a05_j210_receipt_replay.gd")
const PIN := "fd014ec38dd11fd7739d30f305c37f176e1e6f21d7acb5044a907d49b1ba3d0b"
const RECEIPT := "f0aecf60fc74d397bf9dec50b6f8b2ca/battle_settlement/1"
const DIGEST := "02f703bc93518d0caad0da6d5493100732f2991bd149d736c656371c0f8a2996"

var checks := 0
var failures := 0
var rows: Array[Dictionary] = []


class Viewer extends "res://scripts/first_operation_replay_viewer.gd":
	var budget := 0.0
	var updates := 0
	var installed: Array[Dictionary] = []

	func _process(delta: float) -> void:
		budget += delta
		updates += 1
		super._process(delta)

	func _install(frame: Dictionary) -> void:
		super._install(frame)
		installed.append({"tick": frame.tick, "clock_ms": frame.clock_ms, "delta_s": budget,
			"callbacks": updates, "mono_us": Time.get_ticks_usec(), "events": frame.events.duplicate(true)})


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var source := OS.get_environment("SBTK_A05_RECORD_SOURCE")
	var output := OS.get_environment("SBTK_A05_REPLAY_ROOT").replace("\\", "/")
	var profile := OS.get_environment("APPDATA").replace("\\", "/")
	if not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and output.is_absolute_path() and profile == output + "/profile/roaming"
			and ProjectSettings.globalize_path("user://").replace("\\", "/").begins_with(profile + "/"),
			"explicit isolated Windows headless profile"):
		quit(1)
		return
	var link := root.get_node("WorldLink")
	var before := [link.brief, link.outcome, link.routed()]
	Engine.max_fps = 120
	for speed in [1.0, 2.0, 4.0]:
		await _play(source, speed)
	Engine.time_scale = 1.0
	_check(before == [link.brief, link.outcome, link.routed()], "WorldLink unchanged across all trials")
	var artifact := FileAccess.open(output.path_join("matrix.json"), FileAccess.WRITE)
	if artifact != null:
		artifact.store_string(JSON.stringify({"checks": checks, "failures": failures, "pid": OS.get_process_id(),
			"record_sha256": PIN, "cases": rows}, "  "))
		artifact.close()
	else:
		failures += 1
	print("A05_J210_TIMED_VIEWER %d/%d" % [checks - failures, checks])
	quit(1 if failures else 0)


func _play(source: String, speed: float) -> void:
	var opened := Adapter.open_record(source, PIN)
	if not _check(opened.ok, "authentic receipt replay opens x%s" % speed):
		return
	var viewer := Viewer.new()
	root.add_child(viewer)
	if not _check(viewer.attach_playback(opened.replay, opened.frame).ok and viewer._frame.clock_ms == 0,
			"read-only session attaches at C0 x%s" % speed):
		opened.replay.close()
		viewer.free()
		return
	Engine.time_scale = speed
	viewer._play.pressed.emit()
	if not _check(await _wait_tick(viewer, 1) and viewer._frame.clock_ms == 100 and not viewer._finished,
			"real Play installs live 100 ms frame x%s" % speed):
		viewer.free()
		return
	viewer._play.pressed.emit()
	var paused_at := Time.get_ticks_usec()
	var pause_snapshot := [viewer._frame.duplicate(true), viewer.installed.size(), viewer.budget, viewer.updates]
	while Time.get_ticks_usec() - paused_at < 300000:
		await process_frame
	var pause_us := Time.get_ticks_usec() - paused_at
	_check(pause_snapshot == [viewer._frame, viewer.installed.size(), viewer.budget, viewer.updates]
		and not viewer.is_processing() and not viewer._finished and pause_us >= 275000,
		"real Pause freezes the 100 ms frame x%s" % speed)
	var resumed_at := Time.get_ticks_usec()
	var budget_before := viewer.budget
	viewer._play.pressed.emit()
	if not _check(await _wait_tick(viewer, 2), "real Resume installs terminal frame x%s" % speed):
		viewer.free()
		return
	var settled: Dictionary = viewer._frame.settlement
	var terminal: Dictionary = viewer.installed.back()
	_check(viewer._finished and not viewer.is_processing() and viewer._step.disabled
			and viewer._frame.clock_ms == 150 and settled.id == RECEIPT and settled.receipt_digest == DIGEST
			and settled.reason == "annihilation" and viewer._result.text.contains(RECEIPT)
			and viewer._frame.projection.outcome.result.is_empty(),
			"authentic terminal receipt displayed with native result unchanged x%s" % speed)
	var labels: Array[String] = []
	for window_frame: Dictionary in viewer.installed:
		for event: Dictionary in window_frame.events:
			labels.append(event.kind)
	_check(labels == ["spawn", "spawn", "destroyed", "battle_end"], "ordered native events exactly once x%s" % speed)
	viewer._step.pressed.emit()
	viewer._play.pressed.emit()
	await process_frame
	_check(viewer.installed.size() == 3 and viewer._frame.tick == 2 and not viewer.is_processing(),
		"terminal cannot advance or duplicate receipt x%s" % speed)
	rows.append({"engine_time_scale": speed, "pause_wall_us": pause_us, "terminal_after_resume_wall_us": terminal.mono_us - resumed_at,
		"terminal_after_resume_viewer_delta_us": roundi((terminal.delta_s - budget_before) * 1000000),
		"visual_playback_native_clock_interval_ms": terminal.clock_ms - pause_snapshot[0].clock_ms,
		"nominal_viewer_interval_ms": 1000.0 / viewer._frame.projection.hz,
		"installed": viewer.installed.duplicate(true), "terminal_receipt": settled, "terminal_text": viewer._result.text,
		"projection_native_result": viewer._frame.projection.outcome.result})
	viewer.free()
	_check(opened.replay.step().get("error") == "receipt_replay_closed", "viewer frees its isolated replay owner x%s" % speed)


func _wait_tick(viewer: Viewer, tick: int) -> bool:
	var deadline := Time.get_ticks_msec() + 3000
	while viewer.is_processing() and viewer._frame.tick < tick and Time.get_ticks_msec() < deadline:
		await process_frame
	return viewer._frame.tick == tick


func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("A05_J210_TIMED_CHECK ", ok, " ", label)
	return ok
