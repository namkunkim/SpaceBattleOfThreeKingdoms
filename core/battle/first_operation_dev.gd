extends RefCounted

const Checkpoint := preload("res://core/battle/first_operation_checkpoint.gd")
const Preparer := preload("res://core/battle/first_operation_preparer.gd")
const Policy := preload("res://core/battle/p05_p07_first_operation.gd")
const Runtime := preload("res://core/battle/first_operation_dev_runtime.gd")
const CAPABILITY := Preparer.DEVELOPMENT_CAPABILITY
const DEFINITION_ID := "red-cliffs-first-operation-dev-v1"
const DEFINITION_VERSION := 1
const ROSTER_ID := "red-cliffs-dev-roster-v1"
const DIFFICULTY := "standard"
const SEED := 208
const DEFINITION_PATH := "res://data/scenarios/p05_p07_first_operation_dev_v1.json"
const INPUT_PATHS := {
	"roster": "res://data/scenarios/red_cliffs_208_realtime.json",
	"combat_rules": "res://data/profiles/combat_m3.json",
	"movement_rules": "res://data/profiles/poc_corridor.json",
}
const FLEETS := {
	"RC-LIU-SQ-01": "E", "RC-LIU-SQ-02": "E",
	"RC-CAO-SQ-04": "C", "RC-CAO-SQ-05": "R",
}

static func prepare_fresh(request: Variant) -> Dictionary:
	return _prepare(request, "")

static func begin_restore(packet: Variant) -> Dictionary:
	return Checkpoint.begin_restore(packet, _prepare, DEFINITION_ID)

static func prepare_restore(packet: Variant) -> Dictionary:
	return Checkpoint.prepare_restore(packet, _prepare, DEFINITION_ID)

static func _prepare(request: Variant, operation_id: String) -> Dictionary:
	return Preparer.new(_resolve, _build_runtime.bind(operation_id), CAPABILITY).prepare_fresh(request)

static func _resolve(id: String, version: int) -> Dictionary:
	if id != DEFINITION_ID or version != DEFINITION_VERSION:
		return {}
	var definition := ProfileLoader.read_json(DEFINITION_PATH)
	var space: Dictionary = definition.get("space", {})
	var paths: Dictionary = definition.get("inputs", {})
	if (definition.get("schema") != "p05-p07-first-operation/1"
			or definition.get("id") != id or definition.get("status") != "development_candidate"
			or definition.get("difficulty_id") != DIFFICULTY or definition.get("seed") != SEED
			or space.get("kind") != "source" or space.get("transform") != "identity"):
		return {}
	var inputs := {}
	for key in INPUT_PATHS:
		if paths.get(key) != INPUT_PATHS[key]:
			return {}
		var data := ProfileLoader.read_json(INPUT_PATHS[key])
		if data.is_empty():
			return {}
		inputs[key] = data
	return {
		"space": space.kind, "origin": space.get("origin"), "world_size": space.get("size"),
		"definition_id": id, "definition_version": version, "definition": definition,
		"rosters": {ROSTER_ID: {DIFFICULTY: {"inputs": inputs}}},
	}

static func _build_runtime(effective: Dictionary, selection: Dictionary, request: Dictionary, operation_id := "") -> Dictionary:
	if request.seed != SEED:
		return _fail("unsupported_dev_seed", "seed")
	var definition: Dictionary = effective.definition
	var inputs: Dictionary = selection.inputs
	var rows: Variant = definition.get("fleets")
	if not rows is Array or rows.size() != FLEETS.size():
		return _fail("invalid_dev_roster", "definition.fleets")
	var combat: Dictionary = inputs.combat_rules.combat.duplicate(true)
	# Legacy absolute terrain, resupply and scenario modules do not own this operation.
	for key in ["terrain", "supply", "morale", "victory", "command", "stratagem", "assault"]:
		combat.erase(key)
	var scenario: Dictionary = inputs.roster.duplicate(true)
	scenario.squadrons = scenario.squadrons.filter(func(row): return FLEETS.has(row.id))
	var profile := ScenarioProfile.build({
		"profile_id": DEFINITION_ID,
		"side_by_control": {"player": 0, "ai_delegate": 0, "ai": 1},
		"rule_overrides": {},
	}, scenario, inputs.movement_rules, "표준", combat)
	if profile.is_empty():
		return _fail("invalid_dev_profile", "definition.inputs")
	var source_fleets := {}
	for side in [0, 1]:
		for fleet in (profile.ally if side == 0 else profile.foe):
			source_fleets[fleet.squadron_id] = {"side": side, "fleet": fleet}
	profile.erase("scenario")
	profile.rules.world_w = float(effective.world_size[0])
	profile.rules.world_h = float(effective.world_size[1])
	profile.ally = []
	profile.foe = []
	var initial := {}
	var reserve := {}
	for row in rows:
		if not row is Dictionary:
			return _fail("invalid_dev_fleet", "definition.fleets")
		var id: Variant = row.get("id")
		var path := "definition.fleets.%s" % str(id)
		if not source_fleets.has(id) or initial.has(id) or reserve.get("id") == id:
			return _fail("invalid_dev_fleet_id", path)
		var source: Dictionary = source_fleets[id]
		var spawn: String = FLEETS[id]
		var fleet: Dictionary = source.fleet
		if (row.get("roster_id") != id or row.get("side") != source.side
				or row.get("spawn") != spawn or row.get("ship_count") != fleet.ships
				or not combat.formations.has(row.get("formation_id"))
				or not _valid_pose(row, definition.space.nodes.get(spawn))):
			return _fail("invalid_dev_fleet", path)
		var position := _vec(definition.space.nodes[spawn]) + _vec(row.offset_xy)
		if not Rect2(Vector2.ZERO, Vector2(profile.rules.world_w, profile.rules.world_h)).has_point(position):
			return _fail("dev_center_outside_world", path)
		fleet.x = position.x
		fleet.y = position.y
		fleet.wait = 0
		fleet.formation_id = row.formation_id
		var pose := {"heading": deg_to_rad(float(row.heading_deg)), "ammo_bp": int(row.initial_ammo_bp)}
		if spawn == "R":
			reserve = {"id": id, "status": "pending", "fleet": fleet, "pose": pose, "spawn": spawn}
		else:
			initial[id] = pose
			(profile.ally if source.side == 0 else profile.foe).append(fleet)
	if operation_id.is_empty():
		operation_id = DEFINITION_ID + "/" + Crypto.new().generate_random_bytes(16).hex_encode()
	var policy := Policy.create(effective, operation_id, request.route_id)
	if not policy.ok:
		return _fail(policy.error, "runtime.policy")
	return {"ok": true, "runtime": Runtime.new(profile, request.seed, initial, reserve, policy.policy, definition, request, operation_id)}

static func _valid_pose(row: Dictionary, node: Variant) -> bool:
	var heading: Variant = row.get("heading_deg")
	var ammo: Variant = row.get("initial_ammo_bp")
	return (_pair(node) and _pair(row.get("offset_xy")) and _number(heading)
		and _number(ammo) and float(ammo) == floorf(float(ammo)) and ammo >= 0 and ammo <= BattleRules.BP)

static func _pair(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1])

static func _number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value))

static func _vec(value: Array) -> Vector2:
	return Vector2(float(value[0]), float(value[1]))

static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}
