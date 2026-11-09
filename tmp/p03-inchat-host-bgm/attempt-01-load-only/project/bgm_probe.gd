extends SceneTree

const BGM := "res://assets/audio/music/stars_stripes.ogg"
const PLAY_FRAMES := 12
const STOP_FRAMES := 12
const MIXER_WAIT := 0.25

func _initialize() -> void:
	call_deferred("_run")

func _event(name: String, fields: Dictionary = {}) -> void:
	print("BGM ", JSON.stringify({"event": name, "fields": fields}))

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() == 1 else ""
	_event("engine", {"path": OS.get_executable_path(), "pid": OS.get_process_id(),
		"driver": AudioServer.get_driver_name(), "mode": mode})
	if not mode in ["load-only", "play", "ordered-stop"]:
		quit(2)
		return
	var player := AudioStreamPlayer.new()
	root.add_child(player)
	var exists := ResourceLoader.exists(BGM)
	if exists:
		player.stream = load(BGM) as AudioStream
	var typed := player.stream is AudioStreamOggVorbis
	_event("loaded", {"exists": exists, "ogg": typed, "attached": player.is_inside_tree()})
	if not typed:
		quit(1)
		return
	if mode != "load-only":
		player.play()
	_event("started", {"play_called": mode != "load-only", "playing": player.playing,
		"has_playback": player.has_stream_playback()})
	for frame in PLAY_FRAMES:
		await process_frame
	var observed := player.playing and player.has_stream_playback()
	_event("observed", {"playing": player.playing, "has_playback": player.has_stream_playback(),
		"position": player.get_playback_position(), "frames": PLAY_FRAMES})
	var valid := observed if mode != "load-only" else not player.playing and not player.has_stream_playback()
	player.stop()
	_event("stopped", {"attached": player.is_inside_tree(), "playing": player.playing})
	if mode == "ordered-stop":
		for frame in STOP_FRAMES:
			await process_frame
		await create_timer(MIXER_WAIT).timeout
		_event("mixer_wait", {"attached": player.is_inside_tree(), "frames": STOP_FRAMES,
			"seconds": MIXER_WAIT, "has_playback": player.has_stream_playback()})
	player.stream = null
	_event("cleared", {"attached": player.is_inside_tree(), "stream_null": player.stream == null})
	player.queue_free()
	await process_frame
	var freed := not is_instance_valid(player)
	_event("freed", {"freed": freed, "root_children": root.get_child_count()})
	_event("probe_result", {"ok": valid and freed})
	quit(0 if valid and freed else 1)
