extends RefCounted
## The two headless legacy battle tests own the AudioStreamPlayers in their battle.
## Godot 4.7.2's stream mixer traverses its playback list from newest to oldest.
## A stopped stream inserted after teardown witnesses traversal and reclamation of
## older stopped playbacks, including generations no longer held by their players.

const STREAM_DEFAULT_SETTING := 0
const RELEASE_TIMEOUT_MS := 2000


static func release(tree: SceneTree, battle: Node) -> bool:
	var players := battle.find_children("*", "AudioStreamPlayer", true, false)
	var use_fence := _supports_fence(players)
	var owner: WeakRef = weakref(battle)
	if use_fence:
		battle.tree_exiting.connect(_stop_playbacks.bind(players), Object.CONNECT_ONE_SHOT)
	battle.queue_free()
	await tree.process_frame
	if not use_fence:
		return true
	if owner.get_ref() != null:
		return false

	var silence := AudioStreamWAV.new()
	silence.format = AudioStreamWAV.FORMAT_16_BITS
	silence.mix_rate = 8000
	silence.loop_mode = AudioStreamWAV.LOOP_FORWARD
	silence.loop_end = 800
	var pcm := PackedByteArray()
	pcm.resize(1600)
	silence.data = pcm

	var fence := AudioStreamPlayer.new()
	fence.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	fence.stream = silence

	# The owner is gone. Insert and stop the witness atomically with respect
	# to the mixer, then let it reclaim the retired stream playbacks.
	AudioServer.lock()
	tree.root.add_child(fence)
	fence.play()
	var witness: WeakRef = weakref(fence.get_stream_playback())
	var inserted := witness.get_ref() != null
	fence.stop()
	fence.free()
	AudioServer.unlock()
	if not inserted:
		return false

	var deadline := Time.get_ticks_msec() + RELEASE_TIMEOUT_MS
	while witness.get_ref() != null:
		if Time.get_ticks_msec() >= deadline:
			return false
		await tree.process_frame
	print_verbose("P09_AUDIO_RELEASED players=%d" % players.size())
	return true


static func _stop_playbacks(players: Array[Node]) -> void:
	# Descendants have exited the tree and may have requested a pause.
	# Stop their playbacks under the mixer lock before the nodes are deleted.
	AudioServer.lock()
	for player in players:
		(player as AudioStreamPlayer).stop()
	AudioServer.unlock()


static func _supports_fence(players: Array[Node]) -> bool:
	if DisplayServer.get_name() != "headless" or AudioServer.get_driver_name() != "Dummy":
		return false
	if int(ProjectSettings.get_setting("audio/general/default_playback_type", STREAM_DEFAULT_SETTING)) != STREAM_DEFAULT_SETTING:
		return false
	for player in players:
		if (player as AudioStreamPlayer).playback_type == AudioServer.PLAYBACK_TYPE_SAMPLE:
			return false
	return true
