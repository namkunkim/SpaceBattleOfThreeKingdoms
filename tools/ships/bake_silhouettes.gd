extends SceneTree

# The former silhouette baker is retired. The current fleet uses approved transparent
# v2.5 sprites; use the fleet image audit rather than regenerating legacy silhouettes.
func _initialize() -> void:
	push_error("Retired tool: use res://tests/audit_fleet_images.gd to validate current fleet sprites.")
	quit(1)
