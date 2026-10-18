extends SceneTree

# 함종별 배치: 기존 점 집합·척 수·결정성, 역할별 위치 및 7종 진형의 대응을 검사한다.
func _initialize() -> void:
	var r := FleetRenderer.new()
	var loader = FleetRenderer.RoleLayout
	assert(r._role_layout.source == loader.DOCUMENT_PATH, "runtime reads markdown")
	var document := FileAccess.get_file_as_string(loader.DOCUMENT_PATH)
	assert(not loader.parse_document(document).is_empty(), "valid document")
	assert(loader.parse_document("no config").is_empty())
	assert(loader.parse_document(document + "\n" + document).is_empty(), "reject duplicate blocks")
	var changed: Dictionary = loader.DEFAULT_CONFIG.duplicate(true)
	changed.targets["SHP-05"] = [1.0, 0.0]
	changed.targets["SHP-04"] = [0.0, 0.0]
	var altered: Dictionary = loader.parse_document("```fleet-role-layout\n" + JSON.stringify(changed) + "\n```")
	assert(not altered.is_empty())
	r._role_layout = altered
	var swapped := r._role_points([Vector3(-10, 0, 0), Vector3(10, 0, 0)], ["SHP-05", "SHP-04"])
	assert(swapped[0].x > swapped[1].x, "document settings change actual placement")
	changed.targets["SHP-05"] = [1.1, 0.0]
	assert(loader.parse_document("```fleet-role-layout\n" + JSON.stringify(changed) + "\n```").is_empty(), "reject out of range")
	changed = loader.DEFAULT_CONFIG.duplicate(true)
	changed.order[0] = changed.order[1]
	assert(loader.parse_document("```fleet-role-layout\n" + JSON.stringify(changed) + "\n```").is_empty(), "reject duplicate ship IDs")
	var invalid_path := "res://tmp/invalid-fleet-role-layout.md"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://tmp"))
	var invalid_file := FileAccess.open(invalid_path, FileAccess.WRITE)
	invalid_file.store_string("invalid config")
	invalid_file.close()
	assert(loader.load_config(invalid_path).source == "built-in fallback", "invalid file falls back")
	r._role_layout = loader.load_config()
	var export_config := ConfigFile.new()
	assert(export_config.load("res://export_presets.cfg") == OK)
	assert("data/fleet-role-layout.md" in export_config.get_value("preset.0", "include_filter"), "runtime document packaged")
	var ids := []
	var counts := [6, 4, 8, 14, 4, 4, 10, 6]
	for t in 8:
		for i in counts[t]:
			ids.append("SHP-%02d" % (t + 1))
	var layouts := []
	for shape in BattleRules.FORM_SHAPE:
		var raw := r.formation_points(shape, ids.size())
		var pts := r._role_points(raw, ids)
		assert(pts == r._role_points(raw, ids), "deterministic")
		var remaining := raw.duplicate()
		var sums := {}
		for i in ids.size():
			assert(remaining.has(pts[i]), "each slot used once")
			remaining.erase(pts[i])
			var sum: Vector2 = sums.get(ids[i], Vector2.ZERO)
			sums[ids[i]] = sum + Vector2(pts[i].x, absf(pts[i].z))
		assert(remaining.is_empty())
		assert(sums["SHP-04"].x / 14.0 > sums["SHP-05"].x / 4.0, "line ahead of supply")
		assert(sums["SHP-08"].x / 6.0 > sums["SHP-01"].x / 6.0, "scouts ahead of carriers")
		var records := []
		for i in pts.size():
			records.append({"t": ids[i], "f": snappedf(pts[i].x, 0.01), "l": snappedf(pts[i].z, 0.01)})
		layouts.append(records)
	assert(r._role_points([], []).is_empty())
	assert(r._role_points([Vector3.ZERO], ["unknown"]) == [Vector3.ZERO])
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var textures := []
		for k in 7:
			var img := Image.load_from_file("res://assets/ships/silhouette/%d.png" % k)
			img.resize(256, 64, Image.INTERPOLATE_LANCZOS)
			textures.append("data:image/png;base64," + Marshalls.raw_to_base64(img.save_png_to_buffer()))
		var out := FileAccess.open(args[0], FileAccess.WRITE)
		out.store_string(JSON.stringify({"layouts": layouts, "textures": textures}))
	r.free()
	print("FORMATION_ROLE_LAYOUT_PASS")
	quit()
