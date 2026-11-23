extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var map := (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate()
	root.add_child(map)
	current_scene = map
	await process_frame
	await process_frame
	var outcome := BattleOutcome.new()
	outcome.win = true
	map._show_result(outcome, false)
	await process_frame
	var button := map.find_child("ResultTitle", true, false) as Button
	if button == null or not button.is_visible_in_tree() or button.disabled:
		push_error("Result title button is unavailable")
		quit(1)
		return
	button.pressed.emit()
	await process_frame
	await process_frame
	if current_scene == map or current_scene.scene_file_path != "res://scenes/campaign/OpenJumpMenu.tscn":
		push_error("Result title button did not open the title menu")
		quit(1)
		return
	print("Result title navigation passed")
	quit(0)
