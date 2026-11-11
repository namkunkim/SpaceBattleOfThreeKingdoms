extends SceneTree
var screen: Control
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	root.size = Vector2i(1280, 720)
	screen = load("res://scenes/entry/NewEntry.tscn").instantiate()
	screen.auto_prompt_seconds = 0.3
	root.add_child(screen)
	await process_frame
	await process_frame
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	key.pressed = false
	Input.parse_input_event(key)
	await create_timer(0.35).timeout
	if screen.flow.state != screen.Flow.State.STORY:
		printerr("FAIL keyboard")
		quit(1)
		return
	print("PASS keyboard Enter")
	var touch := InputEventScreenTouch.new()
	touch.position = screen.buttons[1].global_position + Vector2(20,20)
	touch.pressed = true
	Input.parse_input_event(touch)
	await process_frame
	touch.pressed = false
	Input.parse_input_event(touch)
	await create_timer(0.7).timeout
	if screen.flow.state != screen.Flow.State.CONFIRM:
		printerr("FAIL touch skip")
		quit(1)
		return
	print("PASS touch skip / auto modal")
	# Activate NO through mouse GUI, exercising actual SceneTree.quit(0).
	var button: Button = screen.buttons[1]
	var click := InputEventMouseButton.new()
	click.position = button.global_position + Vector2(20,20)
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	Input.parse_input_event(click)
	await process_frame
	click.pressed = false
	print("EXPECT_NORMAL_EXIT mouse no")
	Input.parse_input_event(click)
	await create_timer(1.0).timeout
	printerr("FAIL no did not quit")
	quit(1)

