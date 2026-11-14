extends SceneTree

const Runtime := preload("res://scripts/lantern_escort/runtime.gd")
const ID := "lantern-escort-v1/0123456789abcdef0123456789abcdef"
var checks := 0
var failures := 0


func _initialize() -> void:
	var mode := OS.get_environment("SBTK_LANTERN_TEST_ROOT").replace("\\", "/")
	var user_dir := OS.get_user_data_dir().replace("\\", "/")
	if not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and mode.begins_with("F:/WorkSpace/Campaign-Orchestration/LanternRuntime-")
			and user_dir == mode + "/roaming/Godot/app_userdata/SpaceBattleOfThreeKingdoms", "isolated Windows profile"):
		quit(1)
		return
	for count in [0, 1, 2]:
		var run := _sortie(count)
		var report: Dictionary = run.projection()
		var expected := ["transports_destroyed", "one_escaped", "both_escaped"]
		_check(report.settlement.get("escaped") == count and report.settlement.get("reason") == expected[count],
			"legal commands produce %d escapes at tick %d: %s" % [count, report.tick, report.settlement])
		var replay := Runtime.restore(run.capture())
		_check(replay.ok and replay.runtime.capture() == run.capture() and replay.runtime.projection() == report,
			"terminal replay reconstructs entire ordered event stream and state for %d escapes" % count)
		print("LANTERN_OUTCOME ", count, " ", report.events)
	_pending_replay()
	_boundary()
	_escaped_frontier()
	print("LANTERN_RUNTIME %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _sortie(count: int) -> RefCounted:
	var run := Runtime.create(ID)
	run.begin()
	if count >= 1:
		run.queue("move", Vector2(820, 200))
	while run.settlement.is_empty():
		if count == 2 and run.tick == 390:
			run.queue("move", Vector2(1360, 930))
		run.advance()
	return run


func _pending_replay() -> void:
	var run := Runtime.create(ID)
	_check(Runtime.restore(run.capture()).ok and not run.queue("stop"), "unstarted frontier restores and rejects orders")
	run.begin()
	for i in 180:
		run.advance()
	run.queue("move", Vector2(820, 200))
	run.queue("stop")
	var packet: Dictionary = run.capture()
	var replay := Runtime.restore(packet)
	if not _check(replay.ok and replay.runtime.capture() == packet and replay.runtime.projection() == run.projection(),
			"snapshot restores pending commands, clock and ordered events"):
		return
	run.advance()
	replay.runtime.advance()
	var next: Dictionary = replay.runtime.capture()
	_check(next == run.capture() and next.pending.is_empty() and next.applied.size() == 1 \
		and next.applied[0] == {"tick": 180, "batch": [{"kind": "move", "x": 820, "y": 200}, {"kind": "stop"}]},
		"pending batch applies exactly once in order")
	replay.runtime.advance()
	_check(replay.runtime.capture().applied == next.applied, "next frame does not reapply the pending batch")
	var tampered := packet.duplicate(true)
	tampered.pending.reverse()
	_check(not Runtime.restore(tampered).ok, "reordered pending or forged witness rejected")


func _escaped_frontier() -> void:
	var run := Runtime.create(ID)
	run.begin()
	run.queue("move", Vector2(820, 200))
	while run.projection().escaped == 0 and run.settlement.is_empty():
		if run.tick == 390:
			run.queue("move", Vector2(1360, 930))
		run.advance()
	if not _check(run.projection().escaped == 1 and run.settlement.is_empty() and run.tick == 956,
			"first escape leaves a live checkpoint before the second transport arrives"):
		return
	var events: Array = run.drain_events()
	var packet: Dictionary = run.capture()
	var valid_cursor: bool = packet.event_cursor == events.size() and events.back().kind == "transport_escaped" \
			and events.back().ship_id == "transport-1" and run.drain_events().is_empty()
	var replay := Runtime.restore(packet)
	if not _check(valid_cursor and replay.ok and replay.runtime.capture() == packet \
			and replay.runtime.drain_events().is_empty(), "persisted cursor does not redeliver the first escape"):
		return
	var undrained := Runtime.create(ID)
	undrained.begin()
	for i in 180:
		undrained.advance()
	var outstanding := Runtime.restore(undrained.capture())
	_check(outstanding.ok and outstanding.runtime.drain_events() == undrained.drain_events() \
			and outstanding.runtime.drain_events().is_empty(), "restore preserves unread events until explicitly consumed")
	for bad_cursor in [-1, 0.0, 0, int(packet.event_cursor) + 1]:
		var tampered := packet.duplicate(true)
		tampered.event_cursor = bad_cursor
		_check(not Runtime.restore(tampered).ok, "invalid event cursor %s rejected" % bad_cursor)
	while run.settlement.is_empty():
		run.advance()
		replay.runtime.advance()
	var new_events: Array = replay.runtime.drain_events()
	_check(new_events.map(func(event): return event.kind) == ["transport_escaped", "operation_settled"] \
			and new_events[0].ship_id == "transport-2" and new_events == run.drain_events() \
			and replay.runtime.drain_events().is_empty() and replay.runtime.capture() == run.capture(),
			"restored cursor consumes only the later escape and terminal receipt once")


func _boundary() -> void:
	var last := _exit_fixture(false)
	last.advance()
	var receipt: Dictionary = last.settlement
	_check(receipt.kind == "success" and receipt.escaped_ids == ["transport-1"] and receipt.tick == Runtime.LIMIT,
		"living transport crossing on inclusive deadline counts")
	var events: Array = last.projection().events
	_check(events.map(func(event): return event.kind) == ["transport_escaped", "operation_settled"],
		"exit event precedes final receipt")
	var destroyed := _exit_fixture(true)
	destroyed.advance()
	_check(destroyed.settlement.escaped == 0 and destroyed.settlement.kind == "failure" \
		and destroyed.projection().events[0].kind == "transport_destroyed",
		"lethal damage on exit tick prevents escape")
	var abandoned := _exit_fixture(false)
	abandoned._ships[1].status = "escaped"
	abandoned._escaped.append("transport-2")
	abandoned.queue("abandon")
	abandoned.advance()
	_check(abandoned.settlement.reason == "abandoned" and abandoned.settlement.kind == "failure" \
		and abandoned.settlement.escaped_ids == ["transport-2"], "abandon preserves prior committed escapes as failure")


func _exit_fixture(lethal: bool) -> RefCounted:
	# Isolated boundary fixture deliberately stages a same-tick arrival and fire at the deadline.
	var run := Runtime.create(ID)
	run.begin()
	run.tick = Runtime.LIMIT - 1
	run._ships[0].position = Runtime.ROUTE.back() + Vector2(-25, 0)
	run._ships[0].waypoint = Runtime.ROUTE.size() - 1
	if lethal:
		run._ships[0].hp = Runtime.PURSUER_DAMAGE
		run._ships[3].status = "active"
		run._ships[3].position = Runtime.ROUTE.back() + Vector2(70, 0)
	return run


func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("LANTERN_CHECK ", ok, " ", label)
	return ok
