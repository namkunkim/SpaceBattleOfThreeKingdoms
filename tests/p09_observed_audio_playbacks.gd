extends SceneTree

const UiSoundScript = preload("res://hud/ui_kit/ui_sound.gd")
const Retirement = preload("res://tests/lib/observed_audio_playbacks.gd")
const RELEASE_TIMEOUT_MS := 1500

var checks: Array[Dictionary] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(name: String, condition: bool) -> void:
	checks.append({"name": name, "pass": condition})


func _run() -> void:
	var headless_dummy := DisplayServer.get_name() == "headless" and AudioServer.get_driver_name() == "Dummy"
	if not headless_dummy:
		push_error("Run the playback retirement probe with headless Dummy audio.")
		quit(1)
		return

	var use_battle := "--battle" in OS.get_cmdline_user_args()
	var scope: Node
	if use_battle:
		scope = (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	else:
		scope = UiSoundScript.new()
	root.add_child(scope)
	var owner: Node = scope
	if use_battle:
		var presentation: Node = scope.get("presentation")
		var deck: Node = presentation.get("hud") if presentation != null else null
		owner = deck.get("sound") if deck != null else null
	var player: AudioStreamPlayer = owner.get("_loops").get("engine_loop") if owner != null else null
	if player == null:
		push_error("The focused playback owner did not expose engine_loop.")
		scope.free()
		quit(1)
		return
	var set_level := func(level: float) -> void:
		if use_battle:
			scope.emit_signal("sfx_loop", "engine_loop", level)
		else:
			owner.call("set_loop", "engine_loop", level)
	var scope_ref: WeakRef = weakref(scope)
	var owner_ref: WeakRef = weakref(owner)
	var player_ref: WeakRef = weakref(player)
	var wav: AudioStreamWAV = UiSoundScript._synth(["tone", 180.0, 180.0, 0.25, 0.3])
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = int(wav.data.size() / 2)
	var wav_ref: WeakRef = weakref(wav)
	player.stream = wav
	wav = null

	var retirement := Retirement.new()
	_check("inactive-player-is-not-observed", retirement.observe(player) == 0)

	AudioServer.lock()
	set_level.call(0.65)
	var first_id := retirement.observe(player)
	_check("first-playback-is-registered-once", first_id != 0 and retirement.observe(player) == first_id
		and retirement.pending_ids() == [first_id])
	var first_ref: WeakRef = weakref(player.get_stream_playback()) if first_id != 0 else null
	set_level.call(0.0)
	_check("stopped-player-still-has-observed-pending-id", retirement.observe(player) == 0
		and retirement.pending_ids() == [first_id])
	set_level.call(0.65)
	var replacement_id := retirement.observe(player)
	_check("replacement-and-retired-playback-remain-distinct", replacement_id != 0 and replacement_id != first_id
		and retirement.pending_ids() == [first_id, replacement_id])

	var held: AudioStreamPlayback = first_ref.get_ref() if first_ref != null else null
	set_level.call(0.0)
	scope.free()
	AudioServer.unlock()

	_check("owner-and-player-freed", scope_ref.get_ref() == null and owner_ref.get_ref() == null and player_ref.get_ref() == null)
	var started := Time.get_ticks_msec()
	var pending := await retirement.wait_for_release(self, RELEASE_TIMEOUT_MS)
	var negative_wait_ms := Time.get_ticks_msec() - started
	_check("held-retired-playback-prevents-release", held != null and pending == [first_id]
		and negative_wait_ms >= RELEASE_TIMEOUT_MS)
	held = null
	_check("all-observed-playbacks-drain-after-release", (await retirement.wait_for_release(self, RELEASE_TIMEOUT_MS)).is_empty())
	_check("synthetic-stream-released", wav_ref.get_ref() == null)

	var failed: int = checks.filter(func(check: Dictionary) -> bool: return not check["pass"]).size()
	print("P09_OBSERVED_RESULT ", JSON.stringify({
		"pid": OS.get_process_id(),
		"driver": AudioServer.get_driver_name(),
		"scope": "battle_sfx_loop" if use_battle else "standalone_ui_sound",
		"godot": Engine.get_version_info(),
		"first_id": str(first_id),
		"replacement_id": str(replacement_id),
		"negative_pending_ids": pending.map(func(id: int) -> String: return str(id)),
		"negative_wait_ms": negative_wait_ms,
		"checks": checks,
		"passed": checks.size() - failed,
		"failed": failed,
	}))
	quit(0 if failed == 0 else 1)
