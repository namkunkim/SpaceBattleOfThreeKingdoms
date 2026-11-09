extends SceneTree

func _initialize() -> void:
	print("PC0_USER ", JSON.stringify({
		"user": ProjectSettings.globalize_path("user://"),
		"project": ProjectSettings.globalize_path("res://"),
		"pid": OS.get_process_id(), "engine": Engine.get_version_info().string}))
	quit()
