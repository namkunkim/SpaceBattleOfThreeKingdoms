extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://" + label + ".png")
func run() -> void:
	root.size = Vector2i(1280,720)
	var screen = load("res://scenes/entry/NewEntry.tscn").instantiate()
	screen.auto_prompt_seconds = 0.3
	root.add_child(screen)
	await capture("select")
	screen.request("start", screen.flow.revision)
	await capture("story")
	await create_timer(0.4).timeout
	screen.request("skip", screen.flow.revision)
	await create_timer(0.7).timeout
	await capture("confirm")
	screen.request("yes", screen.flow.revision)
	await create_timer(0.4).timeout
	await capture("ready")
	root.size = Vector2i(800,600)
	await capture("ready-small")
	quit(0)
