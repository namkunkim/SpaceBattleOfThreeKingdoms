extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene := load("res://scenes/FleetBattle3D.tscn") as PackedScene
	assert(scene != null)
	var battle := scene.instantiate()
	root.add_child(battle)
	for frame in 100:
		await process_frame
	assert(battle.model_scenes.size() == 7)
	assert(battle.fleets.size() == 6)
	var image := root.get_viewport().get_texture().get_image()
	var output_path := ProjectSettings.globalize_path("res://out/fleet-battle-3d-poc.png")
	var result := image.save_png(output_path)
	assert(result == OK, "Screenshot save failed: %s" % result)
	print("FLEET_3D_CAPTURE_PASS " + output_path)
	quit(0)
