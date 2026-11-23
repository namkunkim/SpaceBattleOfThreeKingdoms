extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var map := (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate()
	root.add_child(map)
	current_scene = map
	await process_frame
	await process_frame
	map._result.hide()
	map._enter_browse()
	if map.find_child("FirstOperationProduct", true, false) != null or map.find_child("OpenRedCliffsSkirmish", true, false) != null:
		push_error("Retired operation entry is still present")
		quit(1)
		return
	map.open_card()
	for i in range(30):
		await process_frame
		if current_scene != map and current_scene.get("screen") != null:
			var screen = current_scene.screen
			if screen.flow.state == screen.Flow.State.READY:
				print("Retired map entry opens tactical preparation")
				quit(0)
				return
	push_error("Retired map entry did not open tactical preparation")
	quit(1)
