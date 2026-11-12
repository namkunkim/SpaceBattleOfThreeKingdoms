extends SceneTree

const ATLAS = preload("res://view/world/navigation_atlas.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var atlas = ATLAS.new()
	atlas.configure({})
	root.add_child(atlas)
	atlas.size = Vector2(1600, 1000)
	await process_frame
	var texture: Texture2D = atlas._facility_textures.get("relay")
	assert(texture != null, "Default relay texture must import and load")
	assert(texture.get_image().detect_alpha() != Image.ALPHA_NONE, "Relay requires transparency")
	var sheet := load("res://assets/world_atlas/relay_station_six_views_v2.png") as Texture2D
	assert(sheet != null and sheet.get_image().detect_alpha() != Image.ALPHA_NONE, "Reference sheet requires transparency")
	assert(ATLAS.FACILITY_PATHS.relay == ATLAS.FACILITY_PATHS.orbital)
	var counts := {}
	var checked := 0
	for point: Dictionary in atlas._data.points:
		if point.kind != "중계 정거장" and not point.get("detail", {}).has("station"):
			continue
		atlas._detail = point
		var orbital: bool = point.detail.has("station")
		var kind := "orbital" if orbital else "relay"
		var center: Vector2 = atlas._vector(point.detail.station.position if orbital else point.detail.center)
		var positions: Array[Vector2] = atlas._relay_positions(center, kind)
		assert(positions.size() == 1, "Each location must contain exactly one station")
		assert(positions == atlas._relay_positions(center, kind), "Placement must be stable")
		counts[positions.size()] = counts.get(positions.size(), 0) + 1
		var bounds: Rect2 = atlas._relay_group_rect(center, kind)
		assert(Rect2(Vector2.ZERO, atlas._map_size).encloses(bounds), "Group outside map")
		for i in range(positions.size()):
			var rect: Rect2 = atlas._facility_rect(positions[i], kind)
			assert(bounds.encloses(rect))
		if orbital:
			var habitable: Array = point.detail.planets.filter(func(body: Dictionary): return body.get("habitable", false))
			if not habitable.is_empty():
				var beside_host := false
				for body: Dictionary in habitable:
					if bounds.get_center().distance_to(atlas._vector(body.position)) < float(body.radius) * atlas._planet_art_scale(body) + 85.0:
						beside_host = true
				assert(beside_host, "Cluster must be beside a habitable planet")
		if orbital:
			var host: Dictionary = atlas._relay_host(center)
			if not host.is_empty():
				var symbol: Rect2 = atlas._facility_rect(center, kind)
				assert(maxf(symbol.size.x, symbol.size.y) < float(host.radius) * 2.0, "Station symbol must be smaller than its planet")
			atlas._update_planet_radii(point.detail, center)
			for position in positions:
				assert(atlas._nearest_detail_object(position, point.detail) == point.detail.station, "Each station must be clickable")
				for body: Dictionary in point.detail.planets + point.detail.stars:
					var radius := float(body.radius) * (1.88 if body.get("ringed", false) else 1.0)
					assert(position.distance_to(atlas._vector(body.position)) > radius + atlas._facility_rect(position, kind).size.length() * 0.5, "Station overlaps celestial body: " + str(point.id))
		checked += 1
	assert(counts.size() == 1 and counts.has(1), "Only single stations are allowed")
	print("RELAY PASS: ", checked, " locations; distribution ", counts)
	if "--relay-preview" in OS.get_cmdline_user_args():
		root.size = Vector2i(1600, 1000)
		for kind in ["relay", "orbital"]:
			for point: Dictionary in atlas._data.points:
				if (kind == "orbital" and point.get("detail", {}).has("station")) or (kind == "relay" and point.kind == "중계 정거장"):
					atlas._detail = point
					if atlas._relay_count(kind) == 1:
						break
			atlas._fit()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://tmp/relay-preview-" + kind + ".png")
	atlas.queue_free()
	quit()
