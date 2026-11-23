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
	var retry := map.find_child("ResultRetry", true, false) as Button
	if retry == null or not retry.is_visible_in_tree():
		push_error("Result retry button is unavailable")
		quit(1)
		return
	retry.pressed.emit()
	for i in range(30):
		await process_frame
		if current_scene != map and current_scene.get("screen") != null:
			var screen = current_scene.screen
			if screen.flow.state == screen.Flow.State.READY:
				print("Result retry opens tactical preparation")
				quit(0)
				return
	push_error("Result retry did not open tactical preparation")
	quit(1)
