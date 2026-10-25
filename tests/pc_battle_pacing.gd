extends SceneTree

const Experiment = preload("res://core/battle/pc_battle_experiment.gd")

func _initialize() -> void:
	call_deferred("_run")

func _arg(key: String, fallback: String) -> String:
	var args := OS.get_cmdline_user_args()
	var i := args.find(key)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else fallback

func _run() -> void:
	var result := {"meta": {"game_speed": 1, "difficulty": "표준", "human_playtest": false,
		"policy": "Liu Bei direct control; advance to public map centre then attack known contacts every 5s; Sun delegated",
		"physical_obstacles": false}, "runs": []}
	var count := int(_arg("--runs", "3"))
	var presets := _arg("--presets", "baseline,slow_only,large_only,large_slow,terrain").split(",")
	if count <= 0:
		push_error("--runs must be positive")
		quit(1)
		return
	for preset in presets:
		if preset not in Experiment.PRESETS:
			push_error("Unknown PC battle experiment preset: " + preset)
			quit(1)
			return
	var replay_failed := false
	for preset in presets:
		for i in count:
			var row := _play(preset, 20824 + i)
			result.runs.append(row)
			replay_failed = replay_failed or (row.has("replay_match") and not row.replay_match)
			print("PC_PACING %s seed=%d end=%.2fs first_hit=%.2fs reason=%s replay=%s" % [preset, row.seed, row.t, row.first_hit_s, row.reason, str(row.get("replay_match", "not_requested"))])
	var path := _arg("--out", "res://docs/battle-core/pc-pacing-results.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write benchmark result: " + path)
		quit(1)
		return
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	if replay_failed:
		push_error("PC pacing command-log replay mismatch")
		quit(1)
		return
	print("PC_PACING_DONE ", path)
	quit(0)

func _play(preset: String, seed_id: int) -> Dictionary:
	var p := Organization.load_auto("res://data/profiles/red_cliffs_rt.json", "표준")
	assert(not p.is_empty())
	var config := Experiment.configure(p, preset)
	var replay_profile := p.duplicate(true) if _arg("--replay", "0") == "1" else {}
	var sim := BattleSim.new(seed_id, 10, p)
	var first_fire := -1
	var first_hit := -1
	var crisis := -1
	var shots := []
	var morale_after_hit := {}
	var curve := []
	var hit_morale := [0, 0]
	var advance_ids := []
	for f in sim.st.fleets:
		if f.side == 0 and f.faction == "liu_bei":
			f.control = "direct"
			advance_ids.append(f.id)
	# Use a public map location, never hidden enemy coordinates.
	sim.queue(BattleSim.command(0, advance_ids, "move", -1, sim.rs.world * 0.5))
	sim.drain_events()
	while not sim.st.over and sim.st.tick < 12000:
		if sim.st.tick % 50 == 0:
			for f in sim.st.alive(0):
				if f.faction != "liu_bei":
					continue
				var enemy := sim.sight_foe(f, 1e9)
				if enemy:
					sim.queue(BattleSim.command(0, [f.id], "attack", enemy.id))
		sim.step()
		for e in sim.drain_events():
			if e.kind == "salvo":
				shots.append(e.tick)
				if first_fire < 0:
					first_fire = e.tick
				if e.value.hit and first_hit < 0:
					first_hit = e.tick
					hit_morale = [sim.morale.army_bp(0), sim.morale.army_bp(1)]
			elif e.kind == "morale_crisis" and int(e.other) == 0 and crisis < 0:
				crisis = e.tick
		if first_hit >= 0:
			for seconds in [1, 5, 10]:
				if sim.st.tick == first_hit + seconds * 10:
					morale_after_hit[str(seconds)] = [sim.morale.army_bp(0), sim.morale.army_bp(1)]
		if sim.st.tick % 300 == 0:
			curve.append([sim.st.clock_s(), sim.morale.army_bp(0), sim.morale.army_bp(1)])
	var burst := {}
	for seconds in [1, 5, 10]:
		var n := 0
		for tick in shots:
			if first_fire >= 0 and tick <= first_fire + seconds * 10:
				n += 1
		burst[str(seconds)] = n
	var row := {"preset": preset, "seed": seed_id, "config": config,
		"t": sim.st.clock_s(), "reason": sim.st.end_reason, "win": sim.st.win,
		"first_fire_s": first_fire / 10.0 if first_fire >= 0 else -1.0, "first_hit_s": first_hit / 10.0 if first_hit >= 0 else -1.0,
		"first_crisis_s": crisis / 10.0 if crisis >= 0 else -1.0,
		"combat_s": sim.st.clock_s() - first_hit / 10.0 if first_hit >= 0 else 0.0,
		"burst_shots": burst, "morale_at_first_hit": hit_morale, "morale_after_hit": morale_after_hit,
		"army_end": [sim.morale.army_bp(0), sim.morale.army_bp(1)],
		"curve": curve, "fingerprint": sim.fingerprint()}
	if not replay_profile.is_empty():
		var replay := BattleSim.replay(seed_id, 10, sim.command_log, sim.st.tick, replay_profile)
		row.replay_match = replay.fingerprint() == sim.fingerprint()
		row.replay_fingerprint = replay.fingerprint()
		_release(replay)
	_release(sim)
	return row

func _release(sim: BattleSim) -> void:
	# Core subsystems retain their simulator; release these test-owned cycles.
	for subsystem in [sim.salvo, sim.morale, sim.victory, sim.detect, sim.supply, sim.chain, sim.cmd, sim.assault, sim.skills, sim.decisions]:
		if subsystem != null:
			subsystem.sim = null
