extends "res://tests/world_link.gd"

func _initialize() -> void:
	var settings := "user://settings.cfg"
	var has_settings := FileAccess.file_exists(settings)
	print("FIFTH_USER ", JSON.stringify({"dir": OS.get_user_data_dir(), "initial_files": DirAccess.get_files_at("user://"),
		"settings_sha": FileAccess.get_sha256(settings) if has_settings else ""}))
	super._initialize()
