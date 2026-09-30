extends SceneTree

const MODEL_NAMES: Array[String] = [
	"전열함",
	"전열함_기함급",
	"화력함",
	"항모",
	"공성함",
	"전자전함",
	"보급_수리함",
	"호위함",
]
const MODEL_ROOT := "res://assets/models/user_ver3/"

func _initialize() -> void:
	for model_name in MODEL_NAMES:
		var packed := load(MODEL_ROOT + model_name + ".glb") as PackedScene
		assert(packed != null, "Could not load %s" % model_name)
		var instance := packed.instantiate()
		var row := {
			"bounds": AABB(),
			"has_bounds": false,
			"mesh_nodes": 0,
			"surfaces": 0,
			"vertices": 0,
			"indices": 0,
			"materials": 0,
		}
		_scan(instance, Transform3D.IDENTITY, row)
		var bounds: AABB = row.bounds
		print("VER3_MODEL %s size=%s center=%s meshes=%d surfaces=%d vertices=%d triangles=%d materials=%d" % [
			model_name,
			bounds.size,
			bounds.get_center(),
			row.mesh_nodes,
			row.surfaces,
			row.vertices,
			int(row.indices / 3),
			row.materials,
		])
		instance.free()
	print("USER_VER3_MODEL_AUDIT_PASS")
	quit(0)

func _scan(node: Node, parent_transform: Transform3D, row: Dictionary) -> void:
	var current_transform := parent_transform
	if node is Node3D:
		current_transform = parent_transform * (node as Node3D).transform
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			row.mesh_nodes += 1
			var transformed := current_transform * mesh_instance.mesh.get_aabb()
			row.bounds = transformed if not row.has_bounds else (row.bounds as AABB).merge(transformed)
			row.has_bounds = true
			row.surfaces += mesh_instance.mesh.get_surface_count()
			for surface_index in mesh_instance.mesh.get_surface_count():
				var arrays := mesh_instance.mesh.surface_get_arrays(surface_index)
				row.vertices += arrays[Mesh.ARRAY_VERTEX].size()
				row.indices += arrays[Mesh.ARRAY_INDEX].size()
				if mesh_instance.mesh.surface_get_material(surface_index) != null:
					row.materials += 1
	for child in node.get_children():
		_scan(child, current_transform, row)
