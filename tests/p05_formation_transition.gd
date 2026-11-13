extends SceneTree

const Sweep := preload("res://scripts/p05_formation_transition.gd")
const Policy := preload("res://core/battle/p05_p07_first_operation.gd")
const Product := preload("res://scripts/first_operation_source_reference.gd")
const Dev := preload("res://core/battle/first_operation_dev.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	var profile := OS.get_environment("SBTK_P05_TRANSITION_PROFILE")
	var expected := profile.path_join("Godot/app_userdata/SpaceBattleOfThreeKingdoms").replace("\\", "/").to_lower()
	var actual := OS.get_user_data_dir().replace("\\", "/").to_lower()
	if _check(not profile.is_empty() and expected == actual, "isolated profile"):
		_adversarial()
		_red_cliffs()
	print("P05_FORMATION_TRANSITION checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)


func _red_cliffs() -> void:
	var loaded := Policy.load_source()
	if not _check(loaded.ok, "pinned operation definition"):
		return
	for key in ["roster", "combat_rules"]:
		if not _check(FileAccess.get_sha256(Dev.INPUT_PATHS[key]) == Product.INPUT_SHA256[key], "pinned " + key):
			return
	var roster: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Dev.INPUT_PATHS.roster))
	var combat: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Dev.INPUT_PATHS.combat_rules))
	var timing: Dictionary = combat.combat.formation_rules
	var formation_ids: Array = combat.combat.formations.keys()
	formation_ids.sort()
	_check(timing.transition_s == 5 and timing.untrained_transition_s == 5, "existing trained and untrained transition is 5 seconds")
	var renderer := FleetRenderer.new()
	_check(renderer._role_layout.source == FleetRenderer.RoleLayout.DOCUMENT_PATH, "uses versioned renderer role layout")
	for squad: Dictionary in roster.squadrons:
		if squad.id not in ["RC-LIU-SQ-01", "RC-LIU-SQ-02"]:
			continue
		var fleet: Dictionary = loaded.definition.fleets.filter(func(row): return row.id == squad.id)[0]
		_fleet(renderer, squad, fleet, formation_ids, roundi(timing.transition_s * 1000))
	renderer.free()


func _fleet(renderer: FleetRenderer, squad: Dictionary, fleet: Dictionary, formation_ids: Array, duration_ms: int) -> void:
	var counts := {}
	for entry: Dictionary in squad.composition:
		counts[entry.ship_type_id] = [int(entry.count)]
	var types := renderer._real_ship_ids(counts)
	_check(types.size() == int(fleet.ship_count), "%s full roster" % squad.id)
	var source := _points(renderer, fleet.formation_id, types, formation_ids)
	var destination := _points(renderer, "FRM-01" if fleet.formation_id == "FRM-03" else "FRM-03", types, formation_ids)
	var classes := types.map(func(type): return renderer._model_class(type))
	var assignments := renderer._assign_real(source, classes, squad.flagship, true)
	var ordinals := {}
	var rows: Array = []
	for i in types.size():
		var type: String = types[i]
		ordinals[type] = ordinals.get(type, 0) + 1
		var assignment: Dictionary = assignments[i]
		# Fixture x is forward, z is lateral. Renderer-local x is lateral, -z is forward. The ship plane's
		# local x is the length; renderer yaw aligns it with fleet forward.
		# Use the centered MODEL_LEN portion only. PLANE_K includes the trail.
		var scale: float = FleetRenderer.CLASS_LEN[assignment.cls] / FleetRenderer.MODEL_LEN
		if assignment.get("flag", false):
			scale *= 1.8
		var half: Vector2 = Vector2(FleetRenderer.MODEL_LEN * FleetRenderer.HULL_STRETCH.x,
			FleetRenderer.SHIP_WIDTH * FleetRenderer.HULL_STRETCH.z) * (0.5 * scale / CameraRig.S)
		rows.append({"id": "%s/%s/%d" % [squad.id, type, ordinals[type]],
			"from": Vector2(source[i].x, source[i].z), "to": Vector2(destination[i].x, destination[i].z), "half": half})
	var expected_counts := [13, 7] if squad.id == "RC-LIU-SQ-01" else [2, 10]
	_report_endpoint(rows, "from", fleet.formation_id, fleet.outer_radius, expected_counts[0])
	_report_endpoint(rows, "to", "FRM-01" if fleet.formation_id == "FRM-03" else "FRM-03",
		fleet.outer_radius, expected_counts[1])
	var frozen := rows.duplicate(true)
	var forward := Sweep.validate(rows, fleet.outer_radius)
	var reversed := rows.map(func(row): return {"id": row.id, "from": row.to, "to": row.from, "half": row.half})
	var backward := Sweep.validate(reversed, fleet.outer_radius)
	_check(forward == Sweep.validate(rows, fleet.outer_radius) and rows == frozen, "%s deterministic and read-only" % squad.id)
	var witness := ["SHP-04/1", "SHP-04/3" if squad.id == "RC-LIU-SQ-01" else "SHP-04/5"]
	var expected_pair := witness.map(func(id): return squad.id + "/" + id)
	_check(forward.get("error") == "swept_overlap" and backward.get("error") == "swept_overlap"
		and forward.ships == expected_pair and backward.ships == expected_pair
		and is_equal_approx(forward.fraction + backward.fraction, 1.0), "%s deterministic overlap in both directions" % squad.id)
	print("P05_FORMATION_OBSERVATION ", JSON.stringify({"fleet": squad.id, "ships": rows.size(),
		"from": fleet.formation_id, "duration_ms": duration_ms, "forward": forward, "reverse": backward}))


func _report_endpoint(rows: Array, endpoint: String, formation: String, radius: float, expected_count: int) -> void:
	var overlaps := 0
	var equal_hull_witness := {}
	var required_radius := 0.0
	for i in rows.size():
		var a: Dictionary = rows[i]
		var position: Vector2 = a[endpoint]
		required_radius = maxf(required_radius, (Vector2(absf(position.x), absf(position.y)) + a.half).length())
		for j in range(i + 1, rows.size()):
			var b: Dictionary = rows[j]
			var delta: Vector2 = position - b[endpoint]
			var penetration: Vector2 = a.half + b.half - Vector2(absf(delta.x), absf(delta.y))
			if penetration.x <= 0.0 or penetration.y <= 0.0:
				continue
			overlaps += 1
			if equal_hull_witness.is_empty() and a.half == b.half and a.id.get_slice("/", 1) == b.id.get_slice("/", 1):
				equal_hull_witness = {"ships": [a.id, b.id], "half": [a.half.x, a.half.y],
					"penetration": [penetration.x, penetration.y]}
	var stationary := rows.map(func(row):
		return {"id": row.id, "from": row[endpoint], "to": row[endpoint], "half": row.half})
	var result := Sweep.validate(stationary, radius)
	var fleet: String = rows[0].id.get_slice("/", 0)
	_check(overlaps == expected_count and not equal_hull_witness.is_empty()
		and result.get("error") == "swept_overlap", "%s %s endpoint overlaps while stationary" % [fleet, formation])
	print("P05_ENDPOINT_OBSERVATION ", JSON.stringify({"fleet": fleet, "formation": formation,
		"pairs": overlaps, "equal_hull_witness": equal_hull_witness,
		"required_radius": required_radius, "approved_radius": radius}))



func _points(renderer: FleetRenderer, formation_id: String, types: Array, formation_ids: Array) -> Array:
	var index := formation_ids.find(formation_id)
	return renderer._role_points(renderer.formation_points(BattleRules.FORM_SHAPE[index], types.size()), types)


func _adversarial() -> void:
	var a := {"id": "a", "from": Vector2(-4, 0), "to": Vector2(4, 0), "half": Vector2.ONE}
	var b := {"id": "b", "from": Vector2(4, 0), "to": Vector2(-4, 0), "half": Vector2.ONE}
	var cross := Sweep.validate([a, b], 10.0)
	_check(cross.get("error") == "swept_overlap" and cross.get("fraction") == 0.5, "separated endpoints cross in between")
	b.from.y = 2.0
	b.to.y = 2.0
	_check(Sweep.validate([a, b], 10.0).ok, "edge contact permitted")
	_check(Sweep.validate([a, a], 10.0).get("error") == "invalid_ship", "duplicate identity rejected")
	_check(Sweep.validate([a], 5.0).get("error") == "outer_radius", "hull corner outside approved radius rejected")
	b.from.y = 1.99
	b.to.y = 1.99
	_check(Sweep.validate([a, b], 10.0).get("error") == "swept_overlap", "interior overlap just inside contact rejected")


func _check(condition: bool, label: String) -> bool:
	checks += 1
	if not condition:
		failures += 1
	print("P05_FORMATION_CHECK ", condition, " ", label)
	return condition
