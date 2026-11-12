extends SceneTree

const Retirement = preload("res://tests/lib/observed_audio_playbacks.gd")
const RELEASE_TIMEOUT_MS := 1500

var checks: Dictionary[String, bool] = {}
var retirement := Retirement.new()
var transitions: Array[Dictionary] = []
var playback_id := 0
var stop_events: Array[Dictionary] = []
var final_battle := {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() != "headless" or AudioServer.get_driver_name() != "Dummy":
		push_error("Run this probe with headless Dummy audio.")
		quit(1)
		return
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	battle.set("difficulty", "입문")
	root.add_child(battle)
	battle.set_process(false)
	var sim: BattleSim = battle.get("sim")
	var player: AudioStreamPlayer = battle.get("presentation").get("hud").get("sound").get("_loops").get("fire_loop")
	var host: FleetState = sim.chain.host()
	var target: FleetState
	for fleet in sim.st.fleets:
		if fleet.sq_id == "RC-CAO-SQ-04":
			target = fleet
		else:
			fleet.pos = Vector2(100 + fleet.id * 55, 850) if fleet.side == 0 else Vector2(1500, 80 + fleet.id * 35)
	checks["ready-with-imported-fire-loop"] = player.stream != null and not player.playing and target != null and host != null
	if not checks["ready-with-imported-fire-loop"]:
		battle.free()
		_finish()
		return

	host.pos = Vector2(780, 450)
	host.control = "delegate"
	target.pos = Vector2(900, 450)
	sim.first_hit_tick = 0
	sim.chain.win_start = 0
	sim.chain.win_end = 1000
	sim.chain.mode = "open"
	sim.detect.contacts[0][target.id] = {
		"seen": sim.st.tick, "pos": target.pos, "state": "confirmed",
		"conf_bp": BattleRules.BP, "err_r": 0.0,
	}

	# CommandDeck has already attached its consumer during scene setup.
	battle.connect("sfx_loop", func(key: String, level: float) -> void:
		if key != "fire_loop":
			return
		if level > 0.0:
			playback_id = retirement.observe(player)
		transitions.append({
			"tick": sim.st.tick, "level": level, "playing": player.playing,
			"id": str(playback_id), "pending": retirement.pending_ids().map(func(id: int) -> String: return str(id)),
		})
	)

	AudioServer.lock()
	sim.st.ai_timer = 0
	sim.step()
	battle.call("_pump")
	checks["ai-start-without-human-command"] = int(sim.chain.stats.fires) == 1 and sim.command_log.is_empty()
	checks["passive-start-observed-after-deck"] = transitions.size() == 1 and transitions[0].level == 1.0 \
		and transitions[0].playing and playback_id != 0 and retirement.pending_ids() == [playback_id]

	# Stop further AI decisions; the original stratagem can continue in ordinary ticks.
	sim.st.ai_timer = 1 << 40
	var interval := BattleRules.ticks(float(sim.chain.O.spread.interval_s), sim.st.hz)
	for spread in int(sim.chain.O.spread.max) + 1:
		for tick in interval:
			sim.step()
		for event: Dictionary in sim.get("_events"):
			if event.kind == "fire_loop" and not event.value.on:
				stop_events.append({"tick": event.tick, "target": event.sq,
					"contact_known": sim.detect.contacts[0].has(event.sq)})
		battle.call("_pump")
		if not stop_events.is_empty() or sim.st.over:
			break
	final_battle = {"tick": sim.st.tick, "over": sim.st.over, "playing_before_teardown": player.playing,
		"next_fire_ticks": sim.chain.fires.map(func(fire: Dictionary) -> int: return int(fire.next))}
	checks["observed-id-still-pending-before-teardown"] = playback_id != 0 \
		and retirement.pending_ids() == [playback_id]
	var player_ref: WeakRef = weakref(player)
	battle.free()
	checks["retired-id-still-pending-before-mixer-resumes"] = retirement.pending_ids() == [playback_id]
	AudioServer.unlock()
	checks["player-freed"] = player_ref.get_ref() == null
	checks["retired-playback-drained"] = (await retirement.wait_for_release(self, RELEASE_TIMEOUT_MS)).is_empty()
	_finish()


func _finish() -> void:
	var passed := checks.values().count(true)
	print("P09_AUTONOMOUS_RESULT ", JSON.stringify({
		"pid": OS.get_process_id(), "driver": AudioServer.get_driver_name(), "checks": checks,
		"transitions": transitions, "core_stop_events": stop_events, "final_battle": final_battle, "passed": passed, "failed": checks.size() - passed,
	}))
	quit(0 if passed == checks.size() else 1)
