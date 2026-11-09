extends SceneTree

const BGM := "res://assets/audio/music/stars_stripes.ogg"
const SEED := 20261109

func _initialize() -> void:
	call_deferred("_run")

func _event(name: String, fields: Dictionary = {}) -> void:
	print("BGM ", JSON.stringify({"event": name, "fields": fields}))

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() == 1 else ""
	_event("engine", {"path": OS.get_executable_path(), "pid": OS.get_process_id(),
		"driver": AudioServer.get_driver_name(), "mode": mode})
	if not mode in ["legacy-host", "ordered-host"]:
		quit(2)
		return
	var link := root.get_node("WorldLink")
	var brief := BattleBrief.new()
	brief.seed = SEED
	link.brief = brief
	var battle = (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	var music: AudioStreamPlayer = battle.presentation.hud.sound._music
	var playing_before_disable := music.playing
	var playback_before_disable := music.has_stream_playback()
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	battle.presentation.hud.guard.enabled = false
	battle.G.state = "play"
	battle.G.speed = 1.0
	battle.G.slow = 1.0
	battle.presentation.hud.show_screen("")
	battle.presentation._process(0)
	var sim: BattleSim = battle.sim
	var clock: TickClock = battle.clock
	var loaded: bool = ResourceLoader.exists(BGM) and music.stream is AudioStreamOggVorbis and music.stream.resource_path == BGM
	var identity: bool = (
		battle.get_script().resource_path == "res://scripts/FleetBattle3D.gd"
		and sim.get_script().resource_path == "res://core/battle/battle_sim.gd"
		and clock.get_script().resource_path == "res://core/battle/tick_clock.gd"
		and battle.presentation.hud.sound.get_script().resource_path == "res://hud/ui_kit/ui_sound.gd"
	)
	_event("before_frame", {"tick": sim.st.tick, "clock_ms": sim.st.clock_ms, "seed": battle.battle_seed,
		"fingerprint": sim.fingerprint(), "canonical": identity, "bgm": loaded,
		"playing": playing_before_disable, "has_playback": playback_before_disable,
		"playing_after_disable": music.playing, "has_playback_after_disable": music.has_stream_playback()})
	var ready: bool = identity and loaded and playing_before_disable and playback_before_disable and battle.battle_seed == SEED and sim.st.tick == 0
	clock.acc = 0.75
	battle._process(0.05)
	battle.presentation._process(0)
	var tick := sim.st.tick
	var acc := clock.acc
	_event("manual_frame", {"tick": tick, "acc": acc, "playing": music.playing})
	var players: Array[Node] = battle.find_children("*", "AudioStreamPlayer", true, false)
	for child in players:
		var player := child as AudioStreamPlayer
		for connection in player.finished.get_connections():
			player.finished.disconnect(connection.callable)
		player.stop()
	_event("stopped", {"tree_attached": music.is_inside_tree(), "playing": music.playing})
	var stable := true
	if mode == "ordered-host":
		for frame in 12:
			await process_frame
		await create_timer(0.25).timeout
		stable = sim.st.tick == tick and is_equal_approx(clock.acc, acc)
		_event("mixer_wait", {"tree_attached": music.is_inside_tree(), "frames": 12,
			"seconds": 0.25, "same_tick_and_phase": stable, "has_playback": music.has_stream_playback()})
	for child in players:
		(child as AudioStreamPlayer).stream = null
	_event("cleared", {"tree_attached": music.is_inside_tree(), "stream_null": music.stream == null})
	root.remove_child(battle)
	battle.free()
	for key in ["detect", "salvo", "supply", "morale", "victory", "cai", "decisions", "chain", "cmd", "assault", "skills"]:
		var module = sim.get(key)
		if module != null:
			module.set("sim", null)
	link.brief = null
	await create_timer(0.25).timeout
	var freed := not is_instance_valid(battle) and not is_instance_valid(music)
	_event("freed", {"freed": freed, "root_children": root.get_child_count()})
	var ok := ready and stable and freed and tick == 1 and is_equal_approx(acc, 0.25)
	_event("probe_result", {"ok": ok})
	quit(0 if ok else 1)
