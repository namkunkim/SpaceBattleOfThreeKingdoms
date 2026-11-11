extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size = Vector2i(1280,720)
	var screen = load("res://scenes/entry/NewEntry.tscn").instantiate()
	root.add_child(screen)
	await process_frame
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	Input.parse_input_event(pad)
	await process_frame
	pad.pressed = false
	Input.parse_input_event(pad)
	await process_frame
	var ok: bool = screen.flow.state == screen.Flow.State.STORY
	print("PASS pad A" if ok else "FAIL pad A")
	quit(0 if ok else 1)
