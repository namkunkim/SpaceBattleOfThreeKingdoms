extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle = load("res://scenes/FleetBattle3D.tscn").instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	battle.G.state = "play"
	if not TestCheck.ok(self, battle.sim.st.alive(0).filter(func(f): return f.faction == "liu_bei").all(func(f): return f.control == "direct"), "player Liu Bei fleets start in direct control"): return
	var f: FleetState = battle.sim.st.fleets[0]
	f.mstate = "retreat"
	f.morale_bp = 2000
	var before: String = battle.sim.fingerprint()
	battle.trace.sample(battle)
	if not TestCheck.ok(self, before == battle.sim.fingerprint(), "trace must not change simulation"): return
	battle.issue(BattleCommands.make("move", [f.id], -1, f.pos + Vector2(50, 50)))
	battle.sim.st.army_ev[0] = 10000
	battle.sim.victory.check()
	battle._pump()
	var path: String = battle.trace.path
	var lines := FileAccess.get_file_as_string(path).strip_edges().split("\n")
	var rejection := false
	var ending := false
	var request := false
	for line in lines:
		var row: Variant = JSON.parse_string(line)
		if not TestCheck.ok(self, row is Dictionary and row.has("tick") and row.has("seq"), "valid structured row"): return
		if row.kind == "command_request":
			request = row.data.command.point is Array
		if row.kind == "core_event" and row.data.event.kind == "rejected":
			rejection = row.data.event.value == "retreating" and row.data.fleets[0].forced_retreat
		if row.kind == "battle_end":
			ending = row.data.reason == "alliance_morale_collapse" and not row.data.win and row.data.result.has("conditions")
	if not TestCheck.ok(self, request and rejection and ending, "request, exact rejection, fleet status and ending persisted"): return
	print("PASS battle_trace ", ProjectSettings.globalize_path(path))
	battle.queue_free()
	await process_frame
	await process_frame
	quit(0)
