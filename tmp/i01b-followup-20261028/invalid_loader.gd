extends SceneTree
var cases := 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var valid := ProfileLoader.read_json(BundleLayout.LAYOUT_PATH)
	for label in ["missing-kind", "invalid-pattern", "invalid-coefficient"]:
		var invalid := valid.duplicate(true)
		if label == "missing-kind":
			invalid.erase("8")
		elif label == "invalid-pattern":
			invalid["8"].pattern = "unknown"
		else:
			invalid["8"].forward_scale = "0.9"
		var path: String = "res://tmp/i01b-followup-20261028/negative-" + label + ".json"
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify(invalid))
		file.close()
		var source := FileAccess.get_file_as_string("res://core/battle/bundle_layout.gd")
		source = source.replace("class_name BundleLayout", "# isolated invalid-loader fixture")
		source = source.replace(BundleLayout.LAYOUT_PATH, path)
		var fixture := GDScript.new()
		fixture.source_code = source
		if fixture.reload() != OK:
			quit(1)
			return
		var result: Array = fixture.offsets(3, 8, 100.0)
		if not result.is_empty() or fixture._layout_valid:
			push_error("INVALID_LAYOUT_SILENT_FALLBACK " + label)
			quit(1)
			return
		cases += 1
	print("BUNDLE_INVALID_LOADER_EXPECTED_REJECTION_PASS cases=%d" % cases)
	quit(0)
