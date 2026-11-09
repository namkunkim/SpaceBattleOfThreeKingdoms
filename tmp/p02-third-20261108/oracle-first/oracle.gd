extends SceneTree

const Root := "res://tmp/p02-third-20261108/"

func _initialize() -> void:
	call_deferred("_run")

func run_native(profile: Dictionary, commands: Array, controls: Array, limit: int) -> Dictionary:
	var sim := BattleSim.new(0, 10, profile)
	for i in controls.size():
		sim.st.fleets[i].control = controls[i]
	var events: Array = []
	var i := 0
	var st := sim.st
	while not st.over and st.tick < limit:
		while i < commands.size() and commands[i].tick == st.tick:
			sim.queue(commands[i])
			i += 1
		sim.step()
		events.append_array(sim.drain_events())
	var summary := {"tick": st.tick, "clock_ms": st.clock_ms, "over": st.over,
		"win": st.over and st.win, "reason": st.end_reason if st.over else "timeout",
		"t": st.end_ms / 1000.0 if st.over else st.clock_s(), "end_tick": st.end_tick, "end_ms": st.end_ms,
		"lost": st.lost / 1000.0, "killed": st.killed / 1000.0,
		"reinf_t": st.reinf_ms / 1000.0 if st.reinf else -1.0,
		"ally_alive": st.alive(0).size(), "foe_alive": st.alive(1).size(),
		"fp": sim.fingerprint(), "commands": sim.command_log.size()}
	for field in ["salvo", "detect", "supply"]:
		var module: Variant = sim.get(field)
		if module: module.sim = null
	return {"summary": summary, "events": events, "event_count": events.size(), "commands_consumed": i}

func _run() -> void:
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/p02/timeout-poc.json")).profile
	for fleet in profile.ally + profile.foe:
		fleet.ships = 30
		fleet.lv = 1
		fleet.p = 0
	var move := BattleSim.command(0, [1], "move", -1, Vector2(720, 510))
	var stop := BattleSim.command(0, [1], "stop")
	var reject := BattleSim.command(0, [9999], "attack", 2)
	move.tick = 0
	stop.tick = 0
	reject.tick = 2
	var commands := [move, stop, reject]
	var expected := run_native(profile, commands, ["direct", "direct"], 3)
	var reordered := run_native(profile, [stop, move, reject], ["direct", "direct"], 3)
	var removed := run_native(profile, [move, stop], ["direct", "direct"], 3)
	var defaults := run_native(profile, commands, [], 3)
	var legacy := BattleSim.replay(0, 10, commands, 3, profile)
	var explicit_delegate := run_native(profile, commands, ["direct", "delegate"], 3)
	var results := {"expected": expected, "reordered": reordered, "removed": removed, "defaults": defaults, "delegate": explicit_delegate,
		"legacy_fingerprint": legacy.fingerprint()}
	var data := FileAccess.open(Root + "oracle.native", FileAccess.WRITE)
	data.store_var(results)
	data.close()
	print("P02_REPLAY_ORACLE " + JSON.stringify(results))
	var passed: bool = expected.events != reordered.events and expected.events != removed.events and defaults.summary.fp == legacy.fingerprint() and explicit_delegate.summary.fp != expected.summary.fp
	passed = passed and expected.events[-1].kind == "rejected" and expected.events[-1].tick == 2 and typeof(expected.events[-1].pos) == TYPE_VECTOR2
	quit(0 if passed else 1)

