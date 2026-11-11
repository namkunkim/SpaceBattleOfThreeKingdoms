extends SceneTree

const Adapter := preload("res://core/battle/operation_runtime_adapter.gd")
const Scene := preload("res://scenes/RestrictedOperationHost.tscn")

var _checks := 0
var _fails := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var host := Scene.instantiate()
	root.add_child(host)
	for name in ["poc", "services"]:
		var fixture := FileAccess.get_file_as_string("res://tests/fixtures/p02/" + name + ".json")
		# Keep canonical combat data bytes intact while selecting a short manual run.
		var input := fixture.replace('"policy": "attack5"', '"policy": "none"').replace('"max_ticks": 1200', '"max_ticks": 2')
		_run_fixture(host, input, name)
	_natural_150ms(host)
	var last: OperationPrivateState = host._operation
	root.remove_child(host)
	host.free()
	_check(last != null and not last.summary().ok, "scene exit closes owner")
	print("RESTRICTED_OPERATION_HOST_%s checks=%d failures=%d" % ["PASS" if _fails == 0 else "FAIL", _checks, _fails])
	quit(0 if _fails == 0 else 1)

func _run_fixture(host: Node, encoded: String, name: String) -> void:
	var input: Dictionary = JSON.parse_string(encoded)
	_write_text("user://" + name + "-input.json", encoded)
	var before := var_to_bytes(input)
	var prepared: Dictionary = host.load_runtime_file("user://" + name + "-input.json")
	if not _check(prepared.ok and var_to_bytes(input) == before, name + " prepares detached input through scene: " + str(prepared)):
		return
	var host_owner: OperationPrivateState = host._operation
	var direct := Adapter.create(input)
	if not _check(direct.ok, name + " shared preparation"):
		return
	var oracle: OperationPrivateState = direct.owner
	var initial := host_owner.observe()
	_check(initial == oracle.observe() and initial.state.tick == 0 and initial.state.clock_ms == 0
		and initial.sim.command_log.is_empty() and initial.sim._queue.is_empty(),
		name + " C0 matches independent adapter owner including queues and initial controls")
	var rejected: Dictionary = input.duplicate(true)
	rejected["definition"] = {"synthetic": true}
	var rejected_result: Dictionary = host.prepare(rejected)
	_check(rejected_result.get("error") == "unsupported_input_representation"
		and host._operation == host_owner and host_owner.observe() == initial, name + " unsupported definition preserves active C0")
	_check(host.load_runtime_file("user://missing-operation.json").get("error") == "input_read_failed"
		and host._operation == host_owner and host_owner.observe() == initial, name + " missing input preserves active C0")

	var fleet: Dictionary = host._projection.squadrons[0]
	var point: Vector2 = fleet.pos + Vector2(90, 0)
	var command := BattleSim.command(0, [fleet.id], "move", -1, point)
	_check(host.issue(command).ok and oracle.issue(command).ok and host_owner.observe() == oracle.observe()
		and host._summary.tick == 0 and host._summary.clock_ms == 0 and host._summary.commands == 1,
		name + " immediate issue applies without advancing")
	var stop := BattleSim.command(0, [fleet.id], "stop")
	_check(host.queue(stop).ok and oracle.queue(stop).ok and host_owner.observe() == oracle.observe()
		and host._summary.commands == 1 and host_owner.observe().sim._queue.size() == 1,
		name + " queue remains pending at the same clock")
	_check(host.advance().ok and oracle.advance().ok and host_owner.observe() == oracle.observe()
		and host._summary.tick == 1 and host._summary.clock_ms == 100 and host._summary.commands == 2
		and host_owner.observe().sim._queue.is_empty(), name + " queued stop applies exactly once at tick 1")
	oracle.close()

	if not _check(host.prepare(input).ok and not host_owner.summary().ok, name + " valid preparation replaces old owner"):
		return
	var replay_command := command.duplicate(true)
	replay_command.tick = 0
	replay_command.point = [point.x, point.y]
	_write_text("user://" + name + "-replay.json",
		'{"format":"p02/restricted-fresh-replay/1","input":%s,"commands":%s}' % [encoded, JSON.stringify([replay_command])])
	_check(host.queue(command).ok, name + " queue same command as restricted replay CLI")
	_record_ticks(host, "user://" + name + "-host-replay.json")

	_check(host.prepare(input).ok, name + " reset for headless no-command comparison")
	_record_ticks(host, "user://" + name + "-host-input.json")
	_check(var_to_bytes(input) == before, name + " input remains immutable")

func _natural_150ms(host: Node) -> void:
	var source := FileAccess.get_file_as_string("res://tests/fixtures/p02/poc.json")
	# Two nearby squadrons, with the same native rules and no injected ending.
	# The allied beam removes 176 of 1000 milli-ships per 50 ms substep.
	# The foe first crosses the existing 500 milli-ship cutoff on substep three.
	var input := source.replace('"ships": 30', '"ships": 320').replace('"delegate"', '"direct"') \
		.replace('"policy": "attack5"', '"policy": "none"').replace('"max_ticks": 1200', '"max_ticks": 2')
	_write_text("user://natural-150ms-input.json", input)
	_write_text("user://natural-150ms-replay.json",
		'{"format":"p02/restricted-fresh-replay/1","input":%s,"commands":[]}' % input)
	if not _check(host.load_runtime_file("user://natural-150ms-input.json").ok, "natural ending fixture prepares"):
		return
	var events: Array = []
	for i in 2:
		_check(host.advance().ok, "native natural ending step")
		var drained: Dictionary = host._operation.drain_events()
		_check(drained.ok, "native natural ending events")
		events.append_array(drained.events)
		if i == 0:
			_check(host._summary.tick == 1 and host._summary.clock_ms == 100 and not host._summary.over,
				"battle is live after the first two substeps")
	var outcome: Dictionary = host._summary.duplicate(true)
	_check(outcome.tick == 2 and outcome.clock_ms == 150 and outcome.end_tick == 2
		and outcome.end_ms == 150 and outcome.over and outcome.win and outcome.reason == "annihilation",
		"natural win is committed at tick 2 / 150 ms")
	var ends := events.filter(func(event): return event.kind == "battle_end")
	_check(ends.size() == 1 and ends[0].tick == 2 and ends[0].value == outcome.reason,
		"natural terminal event appears once")
	_check(host.advance().get("error") == "host_not_running" and host._summary == outcome,
		"post-terminal host command cannot advance the clock")
	var observed := JSON.stringify({"summary": outcome, "events": events, "event_count": events.size()})
	_write_text("user://natural-150ms-host-input.json", observed)
	_write_text("user://natural-150ms-host-replay.json", observed)

func _record_ticks(host: Node, path: String) -> void:
	var events: Array = []
	for i in 2:
		_check(host.advance().ok, "host step")
		var drained: Dictionary = host._operation.drain_events()
		_check(drained.ok, "test-only raw event comparison")
		events.append_array(drained.events)
	_write_text(path, JSON.stringify({"summary": host._summary, "events": events, "event_count": events.size()}))

func _write_text(path: String, data: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if _check(file != null, "write isolated evidence " + path):
		file.store_string(data)
		file.close()

func _check(ok: bool, message: String) -> bool:
	_checks += 1
	if not ok:
		_fails += 1
		push_error("RESTRICTED_HOST_FAIL " + message)
	return ok

