extends SceneTree

const Retirement = preload("res://tests/lib/observed_audio_playbacks.gd")
const RELEASE_TIMEOUT_MS := 1500

var checks: Dictionary[String, bool] = {}
var retirement := Retirement.new()
var transitions: Array[Dictionary] = []
var playback_id := 0
var stop_events: Array[Dictionary] = []
var final_battle := {}
var visible_explosions := 0
var mode := "filtered-stop"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if DisplayServer.get_name() != "headless" or AudioServer.get_driver_name() != "Dummy":
		push_error("Run this probe with headless Dummy audio.")
		quit(1)
		return
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		mode = args[0]
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

	battle.connect("sfx_event", func(key: String) -> void:
		if key == "chain_explosion":
			visible_explosions += 1
	)

	var hidden_first := mode in ["hidden-start", "hidden-first-visible-overlap"]
	AudioServer.lock()
	sim.st.ai_timer = 0
	sim.step()
	if hidden_first:
		sim.detect.contacts[0].erase(target.id)
	battle.call("_pump")
	checks["ai-start-without-human-command"] = int(sim.chain.stats.fires) == 1 and sim.command_log.is_empty()
	if hidden_first:
		checks["hidden-start-produces-no-loop"] = transitions.is_empty() and not player.playing \
			and retirement.pending_ids().is_empty()
	else:
		checks["passive-start-observed-after-deck"] = transitions.size() == 1 and transitions[0].level == 1.0 \
			and transitions[0].playing and playback_id != 0 and retirement.pending_ids() == [playback_id]

	# Stop further AI decisions; the original stratagem continues on ordinary ticks.
	sim.st.ai_timer = 1 << 40
	var interval := BattleRules.ticks(float(sim.chain.O.spread.interval_s), sim.st.hz)
	var first_fire: Dictionary = sim.chain.fires[0] if not sim.chain.fires.is_empty() else {}
	var other: FleetState
	if mode in ["hidden-overlap", "visible-overlap", "hidden-first-visible-overlap"]:
		for tick in floori(float(interval) / 2.0):
			sim.step()
		for fleet in sim.st.fleets:
			if fleet.side == 1 and not fleet.is_flag and fleet != target and sim.chain.dense(fleet):
				other = fleet
				break
		checks["distinct-overlap-fire-started"] = false
		if other != null:
			var other_home := other.pos
			var host_home := host.pos
			host.pos = Vector2(662, 650)
			other.pos = Vector2(900, 650)
			sim.detect.contacts[0][other.id] = {"seen": sim.st.tick, "pos": other.pos,
				"state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}
			var why := sim.chain.ignite(host, other)
			if mode == "hidden-overlap":
				sim.detect.contacts[0].erase(other.id)
			other.pos = other_home
			host.pos = host_home
			checks["distinct-overlap-fire-started"] = why.is_empty() and sim.chain.fires.size() == 2
		if mode == "hidden-overlap":
			battle.call("_pump")
			checks["hidden-overlap-emits-no-extra-start"] = transitions.size() == 1
	if mode == "reset-unbound":
		var old_sim := sim
		var reset: Dictionary = battle.call("init_game")
		sim = battle.get("sim")
		checks["new-sim-stops-existing-audio"] = bool(reset.ok) and not is_same(old_sim, sim) \
			and transitions.size() == 2 and transitions[1].level == 0.0 and not player.playing
		var previous_id := playback_id
		sim.emit("fire_loop", -1, -1, Vector2.ZERO, {"on": true})
		battle.call("_pump")
		checks["unbound-visible-start-still-plays"] = transitions.size() == 3 and transitions[2].level == 1.0 \
			and player.playing and playback_id != previous_id
		sim.emit("fire_loop", -1, -1, Vector2.ZERO, {"on": false})
		battle.call("_pump")
		checks["unbound-visible-global-off-stops"] = transitions.size() == 4 and transitions[3].level == 0.0 and not player.playing
		battle.free()
		AudioServer.unlock()
		checks["retired-playback-drained"] = (await retirement.wait_for_release(self, RELEASE_TIMEOUT_MS)).is_empty()
		_finish()
		return
	for tick in interval * (int(sim.chain.O.spread.max) + 1):
		if first_fire.is_empty() or int(first_fire.next) < 0 or sim.st.over:
			break
		sim.step()
	for event: Dictionary in sim.get("_events"):
		if event.kind == "fire_loop" and not event.value.on:
			stop_events.append({"tick": event.tick, "target": event.sq,
				"contact_known": sim.detect.contacts[0].has(event.sq)})
	if mode in ["visible-overlap", "hidden-first-visible-overlap"] and other != null:
		# The second explosion and the first retirement share this presentation batch.
		sim.detect.contacts[0][other.id] = {"seen": sim.st.tick, "pos": other.pos,
			"state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}
	var before_overlap_pump := visible_explosions
	battle.call("_pump")
	battle.call("_pump")
	if mode in ["visible-overlap", "hidden-first-visible-overlap"]:
		checks["second-visible-explosion-delivered-in-retirement-batch"] = visible_explosions == before_overlap_pump + 1
		checks["second-fire-survives-first-retirement"] = sim.chain.fires.size() == 2 \
			and int(first_fire.next) < 0 and int(sim.chain.fires[1].next) > sim.st.tick
		if mode == "visible-overlap":
			checks["visible-overlap-keeps-same-loop"] = transitions.size() == 1 and player.playing \
				and retirement.observe(player) == playback_id
		else:
			checks["hidden-first-visible-overlap-does-not-start-loop"] = transitions.is_empty() and not player.playing
		if sim.chain.fires.size() == 2:
			for tick in interval * (int(sim.chain.O.spread.max) + 1):
				if int(sim.chain.fires[1].next) < 0 or sim.st.over:
					break
				sim.step()
			checks["second-fire-naturally-ends"] = int(sim.chain.fires[1].next) < 0 and not sim.st.over
		if other != null:
			sim.detect.contacts[0][other.id] = {"seen": sim.st.tick, "pos": other.pos,
				"state": "confirmed", "conf_bp": BattleRules.BP, "err_r": 0.0}
		battle.call("_pump")
	final_battle = {"tick": sim.st.tick, "over": sim.st.over, "playing_before_teardown": player.playing,
		"next_fire_ticks": sim.chain.fires.map(func(fire: Dictionary) -> int: return int(fire.next))}
	checks["first-fire-naturally-ended"] = not first_fire.is_empty() and int(first_fire.next) < 0 and not sim.st.over
	if hidden_first:
		checks["hidden-fire-remains-inaudible"] = transitions.is_empty() and not player.playing
	else:
		checks["heard-fire-stops-once-without-target-payload"] = transitions.size() == 2 \
			and transitions[1].level == 0.0 and not transitions[1].playing and not player.playing
		if mode == "hidden-overlap":
			checks["hidden-fire-still-active-when-heard-fire-stops"] = sim.chain.fires.size() == 2 \
				and int(sim.chain.fires[1].next) > sim.st.tick and stop_events.is_empty()
		elif mode == "filtered-stop":
			checks["core-stop-retained-but-target-hidden"] = stop_events.size() == 1 and not stop_events[0].contact_known
		checks["retired-playback-still-tracked-under-mixer-lock"] = playback_id != 0 \
			and retirement.pending_ids() == [playback_id]
	var player_ref: WeakRef = weakref(player)
	battle.free()
	AudioServer.unlock()
	checks["player-freed"] = player_ref.get_ref() == null
	checks["retired-playback-drained"] = (await retirement.wait_for_release(self, RELEASE_TIMEOUT_MS)).is_empty()
	_finish()


func _finish() -> void:
	var passed := checks.values().count(true)
	print("P09_AUTONOMOUS_RESULT ", JSON.stringify({
		"pid": OS.get_process_id(), "mode": mode, "driver": AudioServer.get_driver_name(), "checks": checks,
		"transitions": transitions, "visible_explosions": visible_explosions, "core_stop_events": stop_events, "final_battle": final_battle, "passed": passed, "failed": checks.size() - passed,
	}))
	quit(0 if passed == checks.size() else 1)
