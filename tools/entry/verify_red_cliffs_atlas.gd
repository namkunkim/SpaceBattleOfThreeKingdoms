extends SceneTree

const Sites := preload("res://view/world/red_cliffs_sites.gd")
var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, description: String) -> void:
	print(("PASS " if ok else "FAIL ") + description)
	if not ok:
		failures += 1

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var atlas: Control = load("res://view/world/navigation_atlas.gd").new()
	atlas.configure({})
	root.add_child(atlas)
	atlas.size = Vector2(900, 600)
	await process_frame
	check(atlas._points[Sites.RED_CLIFFS].position == [852.5, 510.0], "Red Cliffs coordinate")
	check(atlas._points[Sites.WULIN].position == [834.0, 487.0], "Wulin coordinate")
	var opened: Array[bool] = []
	atlas.red_cliffs_requested.connect(func(): opened.append(true))
	atlas._tap(atlas._map_to_screen(Vector2(852.5, 510)))
	check(opened.size() == 1 and atlas._detail.is_empty(), "atlas marker opens operation, not legacy zoom")
	atlas.queue_free()
	await process_frame

	var screen: Control = load("res://scenes/entry/NewEntry.tscn").instantiate()
	screen.campaign_enabled = true
	screen.auto_prompt_seconds = 0.3
	var sorties: Array[bool] = []
	screen.sortie_requested.connect(func(): sorties.append(true))
	root.add_child(screen)
	await process_frame
	screen.request("start", screen.flow.revision)
	screen.gate_remaining = 0.0
	screen.request("skip", screen.flow.revision)
	await create_timer(0.55).timeout
	check(screen.flow.state == screen.Flow.State.MAP, "campaign map waits for an explicit selection")
	var marker := screen.find_child("RedCliffsMarker", true, false) as Button
	check(marker != null, "campaign map has a native Red Cliffs button")
	if marker == null:
		quit(1)
		return
	check(marker.get_rect().has_point(marker.get_parent().red_cliffs_position()), "button covers the projected marker")
	var click := InputEventMouseButton.new()
	click.position = marker.get_global_transform_with_canvas() * (marker.size / 2.0)
	click.global_position = click.position
	var motion := InputEventMouseMotion.new()
	motion.position = click.position
	motion.global_position = click.position
	root.push_input(motion, true)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	root.push_input(click, true)
	await process_frame
	click.pressed = false
	root.push_input(click, true)
	await process_frame
	await process_frame
	check(screen.flow.state == screen.Flow.State.READY, "marker opens detail directly")
	check(screen.find_child("RedCliffsLocalMap", true, false) != null, "local map mounted")
	check(screen.find_child("PreparedMap", true, false) != null, "existing tactical preparation mounted")
	check(sorties.is_empty(), "opening detail does not launch battle")
	screen.gate_remaining = 0.0
	check(screen.request("map", screen.flow.revision), "back to navigation map")
	await process_frame
	check(screen.flow.state == screen.Flow.State.MAP, "navigation map restored")
	screen.gate_remaining = 0.0
	marker = screen.find_child("RedCliffsMarker", true, false) as Button
	if marker == null:
		quit(1)
		return
	marker.pressed.emit()
	await process_frame
	await process_frame
	screen.gate_remaining = 0.0
	var sortie: Button
	for button: Button in screen.buttons:
		if button.text.begins_with("출격"):
			sortie = button
			break
	check(sortie != null, "sortie button exists in detail")
	if sortie != null:
		sortie.pressed.emit()
		sortie.pressed.emit()
	check(sorties.size() == 1, "explicit sortie dispatches exactly once")
	screen.queue_free()
	await process_frame
	print("RED_CLIFFS_ATLAS failures=%d" % failures)
	quit(1 if failures else 0)
