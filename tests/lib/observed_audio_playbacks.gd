extends RefCounted
## Tracks only stream playbacks explicitly observed by a headless test.
## Observe a test-owned player immediately after each start, before any stop or
## replacement. Keep the observations through teardown to detect retired playbacks.

var _playbacks: Dictionary[int, WeakRef] = {}


func observe(player: AudioStreamPlayer) -> int:
	if not is_instance_valid(player) or not player.playing:
		return 0
	var playback := player.get_stream_playback()
	if playback == null:
		return 0
	var id := playback.get_instance_id()
	_playbacks[id] = weakref(playback)
	return id


func pending_ids() -> Array[int]:
	var pending: Array[int] = []
	for id: int in _playbacks:
		if _playbacks[id].get_ref() != null:
			pending.append(id)
	return pending


func wait_for_release(tree: SceneTree, timeout_ms: int) -> Array[int]:
	var deadline := Time.get_ticks_msec() + timeout_ms
	var pending := pending_ids()
	while not pending.is_empty() and Time.get_ticks_msec() < deadline:
		await tree.process_frame
		pending = pending_ids()
	return pending
