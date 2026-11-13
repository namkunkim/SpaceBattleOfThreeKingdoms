extends SceneTree

# Report v2.5 runtime sprites: three factions x eight roles, plus the Han escort fallback.
const ROOT := "res://assets/ships/fleet-report-v25/"
const FACTIONS := ["wei", "shu", "wu"]
const ROLES := ["line", "artillery", "siege", "supply", "electronic-warfare", "interceptor", "carrier", "fast-craft"]
const HAN := "han/imperial-falcon.png"

func _initialize() -> void:
	var paths: Array[String] = []
	for faction in FACTIONS:
		for role in ROLES:
			paths.append(ROOT + faction + "/" + role + ".png")
	paths.append(ROOT + HAN)
	for path in paths:
		var texture := load(path) as Texture2D
		if texture == null:
			push_error("Cannot load imported ship texture: " + path)
			quit(1)
			return
		var image := texture.get_image()
		if image == null or image.is_empty():
			push_error("Cannot load ship image: " + path)
			quit(1)
			return
		if image.get_width() < 32 or image.get_height() < 16 or image.get_used_rect().size == Vector2i.ZERO or image.detect_alpha() == Image.ALPHA_NONE:
			push_error("Invalid dimensions, empty image, or missing transparency: " + path)
			quit(1)
			return
		if not ResourceLoader.exists(path):
			push_error("Godot texture was not imported: " + path)
			quit(1)
			return
	var renderer := FleetRenderer.new()
	renderer._load_assets()
	for side in renderer.mats:
		for material: ShaderMaterial in side[""]:
			var fallback: Texture2D = material.get_shader_parameter("ship_tex")
			if fallback == null or fallback.resource_path != ROOT + HAN:
				push_error("Unknown faction did not use the Han escort")
				renderer.free()
				quit(1)
				return
	renderer.free()
	var legacy_view := BattleView3D.new()
	legacy_view._load_ship_textures()
	for texture: Texture2D in legacy_view.ship_textures["han"]:
		if texture == null or texture.resource_path != ROOT + HAN:
			push_error("Fallback view did not use the Han escort")
			quit(1)
			return
	print("FLEET_IMAGE_AUDIT_PASS: %d textures and Han escort fallback" % paths.size())
	quit(0)
