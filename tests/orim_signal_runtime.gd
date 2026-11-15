extends SceneTree

const Runtime := preload("res://scripts/orim_signal/runtime.gd")
const ID := "orim-signal-v1/0123456789abcdef0123456789abcdef"
var checks := 0
var failures := 0


func _initialize() -> void:
	var path := OS.get_environment("SBTK_ORIM_RUNTIME_PROFILE").replace("\\", "/")
	var local := OS.get_environment("LOCALAPPDATA").replace("\\", "/")
	var roaming := OS.get_environment("APPDATA").replace("\\", "/")
	if not _check(OS.has_feature("windows") and DisplayServer.get_name() == "headless"
			and path.begins_with("F:/WorkSpace/Campaign-Orchestration/OrimRuntime-")
			and roaming == path + "/roaming" and local == path + "/local"
			and OS.get_user_data_dir().replace("\\", "/") == roaming + "/Godot/app_userdata/SpaceBattleOfThreeKingdoms",
			"isolated Windows profile"):
		quit(1)
		return
	_full_runs()
	_capture_and_repair()
	_deadline()
	print("ORIM_RUNTIME %d/%d" % [checks - failures, checks])
	quit(0 if failures == 0 else 1)


func _full_runs() -> void:
	var idle := Runtime.create(ID)
	_check(Runtime.restore(idle.capture()).ok and not idle.queue("stop", Runtime.COMMAND_ID),
		"C0 restores and rejects commands before start")
	idle.begin()
	_advance_to_end(idle)
	_check(idle.settlement.reason == "deadline" and idle.settlement.tick == Runtime.LIMIT,
		"idle sortie fails on deadline")
	_check(Runtime.restore(idle.capture()).ok, "terminal idle path replays")
	var success := Runtime.create(ID)
	success.begin()
	success.queue("move", Runtime.COMMAND_ID, Runtime.STATION)
	success.queue("move", Runtime.SUPPORT_ID, Vector2(850, 630))
	for tick in Runtime.LIMIT:
		success.advance()
		var view: Dictionary = success.projection()
		if view.transmission == 10 and view.owner == "ally":
			break
	if not _check(success.projection().transmission == 10, "public commands reach live transmission frontier %s" % success.settlement):
		return
	var events: Array = success.drain_events()
	_check(not events.is_empty() and events.back().kind == "station_captured" and success.drain_events().is_empty(),
		"station capture is delivered once before transmission completes")
	_check(success.queue("stop", Runtime.COMMAND_ID) and not success.queue("move", Runtime.ADVANCE_ID, Runtime.STATION),
		"player Stop queues; enemy control rejected")
	var packet: Dictionary = success.capture()
	var resumed := Runtime.restore(packet)
	if not _check(resumed.ok and resumed.runtime.capture() == packet and resumed.runtime.projection() == success.projection()
			and resumed.runtime.drain_events().is_empty(), "save/restore preserves pending order, state, and consumed cursor"):
		return
	var cursor := packet.duplicate(true)
	cursor.event_cursor = 0
	_check(not Runtime.restore(cursor).ok, "altered in-range event cursor fails witness")
	success.advance()
	resumed.runtime.advance()
	var committed: Dictionary = resumed.runtime.capture()
	_check(committed == success.capture() and committed.pending.is_empty()
			and committed.applied.back().tick == packet.tick and committed.applied.back().batch == packet.pending,
			"restored Stop applies once on the next tick")
	_advance_to_end(success)
	_advance_to_end(resumed.runtime)
	_check(success.settlement.reason == "signal_sent" and success.settlement.kind == "success"
			and resumed.runtime.capture() == success.capture() and resumed.runtime.projection() == success.projection(),
			"uninterrupted and resumed paths send the signal in exact replay state")
	var suffix: Array = resumed.runtime.drain_events()
	_check(suffix == success.drain_events() and suffix.back().kind == "operation_settled" and resumed.runtime.drain_events().is_empty(),
		"same ordered terminal suffix delivered once")
	var terminal := Runtime.restore(success.capture())
	_check(terminal.ok and terminal.runtime.projection() == success.projection() and terminal.runtime.drain_events().is_empty(),
		"terminal replay has same settlement and ordered audit history")
	print("ORIM_NORMAL_OUTCOME ", success.settlement)


func _capture_and_repair() -> void:
	# Staged fixtures isolate ownership and repairs from combat timing.
	var run := Runtime.create(ID)
	run.begin()
	var ally: Dictionary = run._fleets[Runtime.COMMAND_ID]
	var support: Dictionary = run._fleets[Runtime.SUPPORT_ID]
	var enemy: Dictionary = run._fleets[Runtime.ADVANCE_ID]
	ally.position = Runtime.STATION + Vector2(-Runtime.STATION_RADIUS, 0)
	support.position = Runtime.STATION
	enemy.position = Vector2(1500, 1000)
	enemy.state = "stopped"
	for i in Runtime.CAPTURE_TICKS:
		run.advance()
	_check(run.projection().owner == "ally" and run.projection().transmission == 0,
		"inclusive boundary and ID tie break secure on tick 100 without ticking transmission")
	run.advance()
	_check(run.projection().transmission == 1 and run.projection().transmission_fleet == Runtime.COMMAND_ID,
		"first transmission tick uses chosen incumbent")
	ally.position = Vector2(200, 200)
	run.advance()
	_check(run.projection().transmission == 0 and run.projection().transmission_fleet == Runtime.SUPPORT_ID,
		"entrant change resets and consumes no tick")
	run.advance()
	_check(run.projection().transmission == 1, "replacement transmits from following tick")
	enemy.position = Runtime.STATION + Vector2(Runtime.STATION_RADIUS + 2, 0)
	enemy.state = "moving"
	enemy.target = enemy.position + Vector2(-30, 0)
	run.advance()
	_check(run.projection().transmission == 0 and run.projection().owner == "ally",
		"moving enemy that enters range this tick resets transmission without changing owner")
	support.position = Runtime.REPAIR_POINT
	enemy.position = Runtime.STATION
	enemy.state = "stopped"
	support.health[0] = 0
	support.health[1] = 20
	support.health[2] = 29
	for i in Runtime.CAPTURE_TICKS:
		run.advance()
	_check(run.projection().owner == "enemy" and run.projection().repair == 100, "single enemy recaptures and support repair proceeds")
	run._fleets[Runtime.ADVANCE_ID].position = Vector2(1500, 1000)
	ally.position = Runtime.STATION
	for i in Runtime.CAPTURE_TICKS:
		run.advance()
	_check(run.projection().owner == "ally" and run.projection().transmission == 0,
		"allies must recapture and transmit starting next tick")
	_check(run.projection().repair_used and support.health.slice(0, 3) == [0, 26, 30],
		"repair restores each live ship up to six HP and does not revive a lost ship")
	support.health[1] = 10
	support.position = Vector2(200, 200)
	run.advance()
	support.position = Runtime.REPAIR_POINT
	for i in Runtime.REPAIR_TICKS:
		run.advance()
	var repair_count := 0
	for event: Dictionary in run.projection().events:
		if event.kind == "repair_completed":
			repair_count += 1
	_check(repair_count == 1 and support.health[1] == 10, "moving out and returning cannot repair twice")


func _deadline() -> void:
	var alive := _deadline_fixture(false)
	alive.advance()
	_check(alive.settlement.tick == Runtime.LIMIT and alive.settlement.reason == "signal_sent",
		"transmission completes successfully on inclusive deadline")
	var lethal := _deadline_fixture(true)
	lethal.advance()
	_check(lethal.settlement.tick == Runtime.LIMIT and lethal.settlement.reason == "command_destroyed"
			and lethal.projection().transmission == Runtime.TRANSMISSION_TICKS,
		"command annihilation takes precedence over would-be transmission completion at deadline")
	var deaths: Array = lethal.projection().events
	_check(deaths.map(func(event): return event.kind) == ["fleet_destroyed", "operation_settled"],
		"lethal shot precedes settlement without a successful transmission event")
	var abandoned := _deadline_fixture(false)
	abandoned.queue("move", Runtime.SUPPORT_ID, Vector2(100, 100))
	abandoned.queue("abandon")
	abandoned.advance()
	_check(abandoned.settlement.reason == "abandoned" and abandoned.projection().transmission == Runtime.TRANSMISSION_TICKS - 1
			and abandoned.projection().events.size() == 1, "abandon precedes same-tick movement and signal mechanics")


func _deadline_fixture(lethal: bool) -> RefCounted:
	# Arrange a shot just outside the station but in range of the command fleet.
	var run := Runtime.create(ID)
	run.begin()
	run.tick = Runtime.LIMIT - 1
	run._owner = "ally"
	run._transmission = {"fleet": Runtime.SUPPORT_ID, "ticks": Runtime.TRANSMISSION_TICKS - 1}
	var ally: Dictionary = run._fleets[Runtime.COMMAND_ID]
	ally.position = Runtime.STATION + Vector2(80, 0)
	run._fleets[Runtime.SUPPORT_ID].position = Runtime.STATION
	var enemy: Dictionary = run._fleets[Runtime.ADVANCE_ID]
	enemy.state = "stopped"
	enemy.position = Vector2(1300, 570)
	if lethal:
		ally.health.fill(0)
		ally.health[0] = 1
		enemy.position = Runtime.STATION + Vector2(185, 0)
	return run


func _advance_to_end(run: RefCounted) -> void:
	while run.settlement.is_empty() and run.tick < Runtime.LIMIT:
		run.advance()


func _check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
	print("ORIM_CHECK ", ok, " ", label)
	return ok
