extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var atlas = load("res://view/world/navigation_atlas.gd").new()
	atlas.configure({})
	root.add_child(atlas)
	atlas.size = Vector2(1600, 900)
	await process_frame
	var checked := 0
	for point: Dictionary in atlas._data.points:
		if not point.get("detail", {}).has("planets"):
			continue
		atlas.show_overview()
		atlas._focus_point(point)
		atlas._zoom = 2.5
		var cursor: Vector2 = atlas._map_to_screen(atlas._vector(point.position))
		atlas._zoom_at(cursor, 1.25)
		assert(atlas._detail.id == point.id, "Zoom must open pointed system")
		atlas._zoom_at(atlas._surface.size * 0.5, 1.25)
		assert(atlas._zoom > 1.0, "Detail supports further zoom")
		atlas._zoom_at(atlas._surface.size * 0.5, 0.8)
		atlas._zoom_at(atlas._surface.size * 0.5, 0.8)
		assert(atlas._detail.is_empty(), "Zoom out must return to overview")
		checked += 1
	print("ZOOM PASS: ", checked, " systems; detail entry, enlargement, overview return")
	atlas.queue_free()
	quit()
