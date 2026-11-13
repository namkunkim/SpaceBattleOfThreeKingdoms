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
	check(screen.flow.state == screen.Flow.State.READY, "story skip opens tactical preparation directly")
	check(screen.find_child("RedCliffsLocalMap", true, false) != null, "local map mounted")
	check(screen.find_child("PreparedMap", true, false) != null, "existing tactical preparation mounted")
	check(sorties.is_empty(), "opening detail does not launch battle")
	screen.gate_remaining = 0.0
	var sortie: Button
	for button: Button in screen.buttons:
		if button.text == "함대 편성으로 이동":
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
