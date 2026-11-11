extends SceneTree

const Worker := preload("res://scripts/world/first_operation_auto_worker.gd")

class FailingStartWorker extends "res://scripts/world/first_operation_auto_worker.gd":
	var fail_once := true

	func _start_thread(thread: Thread, action: Callable) -> Error:
		if fail_once:
			fail_once = false
			return ERR_CANT_CREATE
		return super._start_thread(thread, action)

class WorkerScene extends Node:
	var worker := Worker.new()

	func _exit_tree() -> void:
		worker.cancel_and_join()

var _failures := 0
var _checks := 0

func _initialize() -> void:
	_run.call_deferred()

func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("AUTO_WORKER_FAIL " + message)

func _request(route: String) -> Dictionary:
	var brief := BattleBrief.new()
	brief.select_first_operation_dev(route)
	return brief.operation_request()

func _run() -> void:
	var worker := FailingStartWorker.new()
	var front := _request("front")
	var flank := _request("flank")
	var rejected := worker.start(front)
	_check(not rejected.ok and rejected.error == "worker_start_failed" and rejected.godot_error == ERR_CANT_CREATE
		and worker.poll().status == "idle", "injected thread-start failure is surfaced without publication")

	var invalid := front.duplicate()
	invalid.route_id = "unsupported"
	_check(worker.start(invalid).ok, "worker can retry after start failure")
	var result := await _await_result(worker)
	_check(not result.ok and result.error == "unsupported_route" and result.path == "route_id"
		and worker.poll().status == "idle", "preparation failure crosses join once with structured path")

	for route in ["front", "flank"]:
		var request := _request(route).duplicate()
		_check(worker.start(request).ok, "start " + route)
		request.route_id = "mutated-after-start"
		_check(worker.start(flank).get("error") == "busy", "duplicate start rejected")
		result = await _await_result(worker, true)
		var expected_kind := "objective_success" if route == "front" else "withdrawal_success"
		var expected_reason := "objective_conditions_met" if route == "front" else "withdrawal_conditions_met"
		var expected_tick := 5487 if route == "front" else 2151
		var dto: Dictionary = result.get("settlement", {})
		_check(result.get("status") == "completed" and result.get("policy") == Worker.POLICY
			and dto.get("kind") == expected_kind and dto.get("reason") == expected_reason
			and dto.get("tick") == expected_tick and dto.get("clock_ms") == expected_tick * 100,
			"authoritative settlement equals direct command run: %s" % result)
		var brief := BattleBrief.new()
		brief.select_first_operation_dev(route)
		var outcome := BattleOutcome.from_operation(dto, brief, expected_tick * 100)
		_check(outcome != null and outcome.settlement_id == dto.id and worker.poll().status == "idle",
			"main-thread conversion preserves settlement identity and publishes once")
		print("FIRST_OPERATION_AUTO_ROUTE %s %s %s tick=%d" % [route, dto.get("kind"), dto.get("reason"), dto.get("tick", -1)])

	_check(worker.start(front).ok, "start cancellation case")
	worker.request_cancel()
	result = await _await_result(worker)
	_check(result.get("status") == "cancelled" and not result.has("settlement"), "cancel suppresses publication")

	_check(worker.start(flank).ok, "start completed but unjoined cancellation case")
	var deadline := Time.get_ticks_msec() + 30000
	while worker._thread.is_alive() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not worker._thread.is_alive() and worker.start(front).get("error") == "busy", "finished thread still requires join")
	worker.request_cancel()
	result = worker.poll()
	_check(result.get("status") == "cancelled" and worker.poll().status == "idle",
		"cancel after worker completion suppresses unpublished settlement")

	var scene := WorkerScene.new()
	root.add_child(scene)
	var scene_worker := scene.worker
	_check(scene_worker.start(front).ok, "start scene exit fixture")
	root.remove_child(scene)
	scene.free()
	_check(scene_worker.poll().status == "idle" and scene_worker._thread == null, "scene exit cancels and joins")
	print("FIRST_OPERATION_AUTO_WORKER_%s checks=%d failures=%d" % ["PASS" if _failures == 0 else "FAIL", _checks, _failures])
	quit(0 if _failures == 0 else 1)

func _await_result(worker: RefCounted, expect_progress := false) -> Dictionary:
	var deadline := Time.get_ticks_msec() + 30000
	var last_tick := 0
	var progress_valid := true
	while Time.get_ticks_msec() < deadline:
		var result: Dictionary = worker.poll()
		if result.get("status") not in ["running", "cancelling"]:
			if expect_progress:
				_check(last_tick > 0 and progress_valid, "logical progress advances with consistent clock")
			return result
		var progress: Dictionary = result.progress
		progress_valid = progress_valid and progress.tick >= last_tick and progress.clock_ms == progress.tick * 100
		last_tick = progress.tick
		await process_frame
	worker.cancel_and_join()
	_check(false, "worker timed out")
	return {}

