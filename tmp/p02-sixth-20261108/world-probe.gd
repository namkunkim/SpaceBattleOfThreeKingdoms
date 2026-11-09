extends "res://tests/world_link.gd"

func _initialize() -> void:
	print("SIXTH_USER ", JSON.stringify({"dir": OS.get_user_data_dir(),
		"settings": FileAccess.get_sha256("user://settings.cfg") if FileAccess.file_exists("user://settings.cfg") else ""}))
	super._initialize()
