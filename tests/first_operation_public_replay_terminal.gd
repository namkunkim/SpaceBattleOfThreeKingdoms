extends "res://tests/first_operation_public_replay_guard.gd"

const WRONG_SETTLEMENT := "user://wrong-settlement.pcopreplay"


func _file_hashes() -> Array[String]:
	var output: Array[String] = []
	for path: String in [ORIGINAL, WRONG_SETTLEMENT, PRIMARY, PREVIOUS]:
		output.append(FileAccess.get_sha256(path))
	return output


func _find_action(viewer: Node, label: String) -> Button:
	for button: Button in viewer.find_children("*", "Button", true, false):
		if button.text == label and button.is_visible_in_tree() and not button.disabled:
			return button
	return null


func _wait_for_verification(viewer: Node) -> bool:
	for attempt in 60:
		if viewer._verification == null:
			return true
		await process_frame
	return false


func _atlas_restored(map: WorldMapScreen, watch: Button, link: Node, state: Array) -> bool:
	return current_scene == map and _watch() == watch and watch.has_focus() \
		and map._replay_dialog == null and map._replay_overlay == null and _snapshot(map, link) == state


func _exercise() -> void:
	if not _check(await _wait_watch(), "EntryBoot routes saved profile to the public Atlas replay action"):
		return
	var map := current_scene as WorldMapScreen
	var link := root.get_node("WorldLink")
	var watch := _watch()
	var state := _snapshot(map, link)
	var hashes := _file_hashes()
	var storage := _storage_files()
	if not _check(Slot.read(PRIMARY).ok and Slot.read(PREVIOUS).ok and not hashes.has("") \
			and storage == PackedStringArray([PRIMARY.get_file(), PREVIOUS.get_file()]),
			"two original slots and two replay fixtures, no settlement ledger"):
		return
	var original := Codec.read(ProjectSettings.globalize_path(ORIGINAL))
	var changed := Codec.read(ProjectSettings.globalize_path(WRONG_SETTLEMENT))
	if not _check(original.ok and changed.ok and original.bundle.max_ticks == 2,
			"both exact replay envelopes pass current codec admission"):
		return
	var expected: Dictionary = original.bundle.duplicate(true)
	expected.expected_settlement.reason = "p02_wrong_terminal_reason"
	if not _check(changed.bundle == expected, "only the declared terminal reason differs"):
		return

	node_added.connect(_record_viewer)
	if not _select(map, watch, WRONG_SETTLEMENT) or not _check(_viewers.size() == 1 and map._replay_overlay != null \
			and map.canvas.input_lock and not map.hud.visible, "public Atlas admits wrong witness to private verifier"):
		return
	var rejected: Node = _viewers[0].get_ref()
	var verifier: RefCounted = rejected._verification
	if not _check(verifier != null and verifier._owner != null and verifier._tick == 0 \
			and rejected._verified_bundle == changed.bundle and rejected._replay == null and rejected._frame.is_empty(),
			"wrong witness begins real asynchronous verification at tick zero"):
		return
	if not _check(await _wait_for_verification(rejected), "asynchronous verifier returns a result"):
		return
	if not _check(verifier._tick == 2 and verifier._cursor == 2 and verifier._owner == null \
			and rejected._verification == null and rejected._verified_bundle.is_empty() \
			and rejected._result.text == "replay_settlement_mismatch",
			"real verifier reaches terminal tick two, rejects the mismatch and closes the private owner"):
		return
	if not _check(rejected._replay == null and rejected._frame.is_empty() and rejected._clock.text.is_empty() \
			and rejected._events.text.is_empty() and rejected._play.disabled and rejected._step.disabled \
			and not rejected.is_processing(), "late failure publishes no replay frame or terminal playback"):
		return
	var close := _find_action(rejected, "Close replay")
	if not _check(close != null, "failed verifier leaves a usable public close action"):
		return
	close.pressed.emit()
	await process_frame
	if not _check(_viewers[0].get_ref() == null and _atlas_restored(map, watch, link, state) \
			and _file_hashes() == hashes and _storage_files() == storage,
			"closing failed verification restores Atlas and focus with all files intact"):
		return

	if not _select(map, watch, ORIGINAL) or not _check(_viewers.size() == 2 and map._replay_overlay != null,
			"same Atlas action admits the untouched original"):
		return
	var accepted: Node = _viewers[1].get_ref()
	var good_verifier: RefCounted = accepted._verification
	if not _check(good_verifier != null and good_verifier._tick == 0 and accepted._frame.is_empty(),
			"original also starts privately without publishing an unverified frame"):
		return
	if not _check(await _wait_for_verification(accepted), "original asynchronous verification completes"):
		return
	if not _check(good_verifier._tick == 2 and good_verifier._owner == null \
			and accepted._replay != null and accepted._frame.tick == 0 and accepted._frame.clock_ms == 0,
			"verified original publishes fresh playback at tick zero"):
		return
	var step := _find_action(accepted, "Step one tick")
	if not _check(step != null, "verified replay exposes enabled manual stepping"):
		return
	step.pressed.emit()
	if not _check(accepted._frame.tick == 1 and accepted._frame.clock_ms == 100 and not accepted._finished,
			"first public step publishes tick one"):
		return
	step.pressed.emit()
	var settlement: Dictionary = original.bundle.expected_settlement
	if not _check(accepted._frame.tick == 2 and accepted._frame.clock_ms == 200 and accepted._finished \
			and accepted._step.disabled and accepted._result.text.contains(settlement.id) \
			and accepted._result.text.contains(settlement.reason), "second step shows exact original terminal ID and reason"):
		return
	close = _find_action(accepted, "Close replay")
	if not _check(close != null, "terminal replay still exposes a public close action"):
		return
	close.pressed.emit()
	await process_frame
	_check(_viewers[1].get_ref() == null and _atlas_restored(map, watch, link, state) \
		and _file_hashes() == hashes and _storage_files() == storage,
		"closing authentic replay restores the same Atlas and preserves save and replay bytes")
