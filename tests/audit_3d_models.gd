extends SceneTree

const MODELS := ["Imperial", "Executioner", "Insurgent", "Omen", "Pancake", "Dispatcher", "Challenger"]
const ROOT := "res://assets/models/quaternius_ultimate_spaceships/"

func _initialize() -> void:
	for model_name in MODELS:
		var packed := load(ROOT + model_name + "/" + model_name + ".fbx") as PackedScene
		assert(packed != null, "Could not load %s" % model_name)
		var instance := packed.instantiate()
		var bounds := _bounds_for(instance)
		print("MODEL_AUDIT %s position=%s size=%s" % [model_name, bounds.position, bounds.size])
		for child in instance.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := child as MeshInstance3D
			if mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
				var material := mesh_instance.mesh.surface_get_material(0)
				if material is StandardMaterial3D:
					print("MODEL_MATERIAL %s color=%s metallic=%.2f roughness=%.2f emission=%s texture=%s" % [model_name, material.albedo_color, material.metallic, material.roughness, material.emission_enabled, material.albedo_texture])
				break
		instance.free()
	print("FLEET_3D_MODEL_AUDIT_PASS")
	quit()

func _bounds_for(root: Node) -> AABB:
	var bounds := AABB()
	var has_bounds := false
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := child as MeshInstance3D
		if mesh_instance.mesh == null:
			continue
		var transformed := mesh_instance.transform * mesh_instance.mesh.get_aabb()
		bounds = transformed if not has_bounds else bounds.merge(transformed)
		has_bounds = true
	return bounds
