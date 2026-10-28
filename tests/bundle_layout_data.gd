extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

var _checks := 0
var _ok := true
func _check(value: bool, label: String) -> void:
	_checks += 1
	if not value:
		_ok = false
		push_error("BUNDLE_LAYOUT_DATA_FAIL " + label)

func _run() -> void:
	var data := ProfileLoader.read_json(BundleLayout.LAYOUT_PATH)
	_check(BundleLayout._valid_layout(data), "valid complete geometry")
	var patterns := ["grid", "wedge", "grid", "grid", "ring", "arc", "grid", "grid", "wedge", "grid"]
	var columns := ["half", "auto", "auto", "pair", "auto", "auto", "auto", "auto", "auto", "pair"]
	var forward := [0.0, -0.9, 0.0, 0.0, 0.0, 0.45, 0.0, 0.0, 0.9, 0.0]
	for kind in 10:
		var entry: Dictionary = data[str(kind)]
		_check(entry.pattern == patterns[kind] and entry.columns_mode == columns[kind], "original branch mapping %d" % kind)
		_check(entry.forward_scale == forward[kind] and entry.shear == (0.7 if kind == 6 else 0.0) and entry.stagger == (0.25 if kind == 7 else 0.0), "original coefficients %d" % kind)
		var missing := data.duplicate(true)
		missing.erase(str(kind))
		_check(not BundleLayout._valid_layout(missing), "missing known kind %d rejected" % kind)
	var extra := data.duplicate(true)
	extra["10"] = data["0"]
	_check(not BundleLayout._valid_layout(extra), "extra kind rejected")
	for field in ["pattern", "columns_mode", "forward_scale", "shear", "stagger"]:
		var missing := data.duplicate(true)
		missing["0"].erase(field)
		_check(not BundleLayout._valid_layout(missing), "missing field " + field)
		var wrong_type := data.duplicate(true)
		wrong_type["0"][field] = 1
		_check(not BundleLayout._valid_layout(wrong_type), "wrong type " + field)
	for field in ["pattern", "columns_mode"]:
		var invalid := data.duplicate(true)
		invalid["0"][field] = "unknown"
		_check(not BundleLayout._valid_layout(invalid), "unknown enum " + field)
	for value in [INF, -INF, NAN]:
		for field in ["forward_scale", "shear", "stagger"]:
			var invalid := data.duplicate(true)
			invalid["0"][field] = value
			_check(not BundleLayout._valid_layout(invalid), "nonfinite " + field)
	var wrong_entry := data.duplicate(true)
	wrong_entry["0"] = []
	_check(not BundleLayout._valid_layout(wrong_entry), "wrong entry type")
	# 범위 밖 배치도는 원래 자동 격자 분기와 같다.
	_check(BundleLayout.offsets(7, -1, 100.0) == BundleLayout.offsets(7, 2, 100.0), "negative unknown grid")
	_check(BundleLayout.offsets(7, 10, 100.0) == BundleLayout.offsets(7, 2, 100.0), "positive unknown grid")
	print("BUNDLE_LAYOUT_DATA_PASS checks=%d" % _checks if _ok else "BUNDLE_LAYOUT_DATA_FAIL")
	quit(0 if _ok else 1)
