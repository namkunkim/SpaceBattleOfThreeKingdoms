extends RefCounted
## Fixed authored campaign roster. Generic auto_fill/repair is deliberately not used:
## it would replace story commanders and fill the Guan/Huang detachments.
const PROFILE_PATH := "res://data/profiles/red_cliffs_open_jump.json"
const ALIASES := ["liu", "guan", "zhou", "cheng", "huang", "cao", "ren", "wen", "xu", "patrol", "chun"]
const EVENTS := ["initial", "escort", "capture", "base_captured", "extraction"]
const DEPLOYMENTS := {"initial": ["liu", "guan", "huang", "patrol", "wen"], "escort": ["ren"],
	"capture": [], "base_captured": ["zhou", "cheng", "cao", "xu"], "extraction": ["chun"]}

static func load_definition(path: String = PROFILE_PATH) -> Dictionary:
	var descriptor := ProfileLoader.read_json(path)
	if not _valid_descriptor(descriptor):
		return _fail("invalid_descriptor")
	var spec := ProfileLoader.read_json(descriptor.scenario_path)
	if not _valid_spec(spec):
		return _fail("invalid_definition")
	var canonical := ProfileLoader.read_json(spec.source_path)
	if canonical.is_empty():
		return _fail("source_missing")
	# Reuse exact canonical identities/traits and the existing combat/AI resources.
	var combat: Variant = ProfileLoader.read_json(descriptor.combat_rules_path).get("combat", {})
	var ai: Variant = ProfileLoader.read_json(descriptor.ai_rules_path).get("ai", {})
	if typeof(combat) != TYPE_DICTIONARY or typeof(ai) != TYPE_DICTIONARY:
		return _fail("invalid_resource")
	return build(spec, canonical, descriptor, ProfileLoader.read_json(descriptor.base_profile), combat, ai)

static func build(spec: Dictionary, canonical: Dictionary, descriptor: Dictionary,
		base: Dictionary, combat: Dictionary, ai: Dictionary = {}) -> Dictionary:
	if not _valid_spec(spec):
		return _fail("invalid_definition")
	if not _valid_descriptor(descriptor):
		return _fail("invalid_descriptor")
	if not _valid_resources(canonical, base, combat):
		return _fail("invalid_resource")
	var pools := {}
	for faction in canonical.factions:
		var pool := {}
		for person in faction.available_officers:
			pool[person.id] = person
		pools[faction.id] = pool
	var expanded := canonical.duplicate(true)
	expanded.scenario_id = spec.scenario_id
	expanded.title = spec.title
	expanded.battlefield_bounds = spec.battlefield_bounds.duplicate()
	expanded.difficulty_order = ["standard"]
	expanded.difficulty_profiles = {"standard": {
		"cao_fleets": ALIASES.size(), "cao_last_fill_bp": 10000,
		"start_morale_bp": {"northern": 8000, "jing_navy": 6500},
		"ai": canonical.difficulty_profiles[canonical.difficulty_order[1]].ai.duplicate(true)}}
	expanded.difficulty_policy = {"scope": "event-gated campaign; no automatic roster scaling"}
	expanded.squadrons = []
	expanded.realtime_rules = canonical.realtime_rules.duplicate(true)
	expanded.realtime_rules.erase("auto_organization")
	expanded.realtime_rules.deploy_rule = "campaign event only; all native waits are zero"
	var aliases := {}
	var ids := {}
	for row in spec.fleets:
		if typeof(row) != TYPE_DICTIONARY:
			return _fail("invalid_fleet")
		for key in ["alias", "id", "name", "faction_id", "commander_id", "vice_id", "formation_id", "deployment_event"]:
			if typeof(row.get(key)) != TYPE_STRING:
				return _fail("invalid_fleet")
		if row.alias not in ALIASES or aliases.has(row.alias) or ids.has(row.id) or row.deployment_event not in EVENTS:
			return _fail("duplicate_or_unknown_fleet")
		if not pools.has(row.faction_id) or not pools[row.faction_id].has(row.commander_id):
			return _fail("foreign_commander")
		var pool: Dictionary = pools[row.faction_id]
		if row.vice_id != "" and not pool.has(row.vice_id):
			return _fail("foreign_vice")
		if typeof(row.get("staff")) != TYPE_ARRAY or typeof(row.get("composition")) != TYPE_ARRAY:
			return _fail("invalid_fleet")
		if not _point(row.get("initial_position")) or typeof(row.get("flagship")) != TYPE_BOOL:
			return _fail("invalid_pose")
		if row.has("skill_slots") and (typeof(row.skill_slots) != TYPE_ARRAY or not row.skill_slots.all(func(value): return typeof(value) == TYPE_STRING)):
			return _fail("invalid_skill_slots")
		if row.staff.size() > 3:
			return _fail("invalid_staff")
		var staff := []
		for post in row.staff:
			if typeof(post) != TYPE_DICTIONARY or typeof(post.get("id")) != TYPE_STRING or typeof(post.get("post")) != TYPE_STRING or not pool.has(post.id):
				return _fail("invalid_staff")
			var person: Dictionary = pool[post.id].duplicate(true)
			person.post = post.post
			staff.append(person)
		# Reject negative/fractional counts before ScenarioProfile casts them.
		for item in row.composition:
			if typeof(item) != TYPE_DICTIONARY or not _integer(item.get("count")) or item.count <= 0 or item.count > 10000:
				return _fail("invalid_count")
			if typeof(item.get("ship_type_id")) != TYPE_STRING or not combat.ship_types.has(item.ship_type_id):
				return _fail("unknown_ship")
		var squadron := {"id": row.id, "faction_id": row.faction_id, "name": row.name,
			"commander": pool[row.commander_id].duplicate(true),
			"vice_commander": pool[row.vice_id].duplicate(true) if row.vice_id != "" else null,
			"staff": staff, "flagship": row.flagship, "initial_position": row.initial_position.duplicate(),
			"formation_id": row.formation_id, "composition": row.composition.duplicate(true), "deploy_delay_s": 0}
		if row.faction_id == "cao_cao":
			squadron.morale_group = "jing_navy" if row.alias == "wen" else "northern"
		expanded.squadrons.append(squadron)
		aliases[row.alias] = row
		ids[row.id] = true
	var operation: Dictionary = spec.operation.duplicate(true)
	if not _valid_operation(operation, aliases):
		return _fail("invalid_operation")
	var campaign_combat := combat.duplicate(true)
	campaign_combat.supply.bases = [{"id": "OPEN-JUMP-BASE", "faction_id": "cao_cao",
		"position": operation.regions.base.center.duplicate()}]
	expanded.escape_points = {"liu_sun_alliance": {"position": operation.regions.exit.center.duplicate(),
		"arrival_radius": operation.regions.exit.radius}, "cao_cao": {"position": [1600, 300], "arrival_radius": 60}}
	var profile := ScenarioProfile.build(descriptor, expanded, base, "standard", campaign_combat)
	if profile.is_empty():
		return _fail("profile_build_failed")
	profile.ai = ai.duplicate(true)
	var organization := Organization.default_org(profile)
	for fleet in organization.fleets:
		var row: Dictionary = aliases.values().filter(func(entry): return entry.id == fleet.squadron_id)[0]
		# Do not infer posts from stats: the authored post assignment is authoritative.
		fleet.staff = row.staff.duplicate(true)
		fleet.skill_slots = row.skill_slots.duplicate() if row.has("skill_slots") else Organization.default_slots(fleet, profile)
	var errors := Organization.validate(organization, expanded, profile)
	if not errors.is_empty():
		return {"ok": false, "error": "invalid_organization", "details": errors}
	profile = Organization.apply(profile, organization, expanded)
	var fleets := {}
	for alias in aliases:
		var row: Dictionary = aliases[alias]
		var side := 1 if row.faction_id == "cao_cao" else 0
		var found: Array = (profile.foe if side == 1 else profile.ally).filter(func(entry): return entry.squadron_id == row.id)
		if found.size() != 1:
			return _fail("missing_profile_fleet")
		fleets[alias] = {"definition": found[0].duplicate(true), "side": side, "deploy_on": row.deployment_event}
	var initial_profile := profile.duplicate(true)
	initial_profile.ally = []
	initial_profile.foe = []
	initial_profile.reinf = []
	for alias in operation.deployments.initial:
		var row: Dictionary = fleets[alias]
		(initial_profile.ally if row.side == 0 else initial_profile.foe).append(row.definition.duplicate(true))
	return {"ok": true, "source": expanded, "spec": spec.duplicate(true), "profile": profile,
		"initial_profile": initial_profile, "fleets": fleets, "operation": operation}

static func _valid_operation(operation: Dictionary, aliases: Dictionary) -> bool:
	if not _integer(operation.get("version")) or operation.version != 1 or operation.get("recon_on") != "escort":
		return false
	if typeof(operation.get("recon")) != TYPE_DICTIONARY or not _point(operation.recon.get("cao_approach")) or operation.recon.get("exit_region") != "exit":
		return false
	if typeof(operation.get("briefing")) != TYPE_STRING or operation.briefing.is_empty():
		return false
	if typeof(operation.get("regions")) != TYPE_DICTIONARY or typeof(operation.get("deployments")) != TYPE_DICTIONARY or typeof(operation.get("fleet_ids")) != TYPE_DICTIONARY:
		return false
	if not _integer(operation.get("capture_ticks")) or operation.capture_ticks < 1 or operation.capture_ticks > 36000:
		return false
	for key in ["rendezvous", "base", "jump", "exit"]:
		var zone: Variant = operation.regions.get(key)
		if typeof(zone) != TYPE_DICTIONARY or not _point(zone.get("center")):
			return false
		if not _number(zone.get("radius")) or zone.radius <= 0:
			return false
	var seen := {}
	for event in EVENTS:
		if typeof(operation.deployments.get(event)) != TYPE_ARRAY or operation.deployments[event] != DEPLOYMENTS[event]:
			return false
		for alias in operation.deployments[event]:
			if not aliases.has(alias) or seen.has(alias) or aliases[alias].deployment_event != event:
				return false
			if operation.fleet_ids.get(alias) != aliases[alias].id:
				return false
			seen[alias] = true
	return seen.size() == ALIASES.size() and operation.fleet_ids.size() == ALIASES.size() and operation.deployments.size() == EVENTS.size()

static func _valid_descriptor(value: Dictionary) -> bool:
	for key in ["profile_id", "scenario_path", "base_profile", "combat_rules_path", "ai_rules_path"]:
		if typeof(value.get(key)) != TYPE_STRING or value[key].is_empty():
			return false
	if typeof(value.get("rule_overrides")) != TYPE_DICTIONARY or typeof(value.get("side_by_control")) != TYPE_DICTIONARY:
		return false
	for key in ["player", "ai_delegate", "ai"]:
		if not _integer(value.side_by_control.get(key)) or value.side_by_control[key] != (1 if key == "ai" else 0):
			return false
	return true

static func _valid_spec(value: Dictionary) -> bool:
	if not _integer(value.get("schema_version")) or value.schema_version != 1:
		return false
	for key in ["scenario_id", "title", "source_path"]:
		if typeof(value.get(key)) != TYPE_STRING or value[key].is_empty():
			return false
	if typeof(value.get("fleets")) != TYPE_ARRAY or value.fleets.size() != ALIASES.size() or typeof(value.get("operation")) != TYPE_DICTIONARY:
		return false
	var bounds: Variant = value.get("battlefield_bounds")
	if typeof(bounds) != TYPE_ARRAY or bounds.size() != 4 or not bounds.all(_number):
		return false
	return bounds[2] > bounds[0] and bounds[3] > bounds[1]

static func _valid_resources(canonical: Dictionary, base: Dictionary, combat: Dictionary) -> bool:
	if typeof(base.get("rules")) != TYPE_DICTIONARY or typeof(combat.get("ship_types")) != TYPE_DICTIONARY or typeof(combat.get("supply")) != TYPE_DICTIONARY:
		return false
	if typeof(canonical.get("factions")) != TYPE_ARRAY or typeof(canonical.get("realtime_rules")) != TYPE_DICTIONARY:
		return false
	if typeof(canonical.get("difficulty_order")) != TYPE_ARRAY or canonical.difficulty_order.size() < 2 or typeof(canonical.get("difficulty_profiles")) != TYPE_DICTIONARY:
		return false
	var difficulty: Variant = canonical.difficulty_profiles.get(canonical.difficulty_order[1])
	if typeof(difficulty) != TYPE_DICTIONARY or typeof(difficulty.get("ai")) != TYPE_DICTIONARY:
		return false
	var faction_ids := []
	for faction in canonical.factions:
		if typeof(faction) != TYPE_DICTIONARY or typeof(faction.get("id")) != TYPE_STRING or faction.get("control") not in ["player", "ai_delegate", "ai"] or typeof(faction.get("available_officers")) != TYPE_ARRAY:
			return false
		if faction.id in faction_ids:
			return false
		faction_ids.append(faction.id)
		for person in faction.available_officers:
			if typeof(person) != TYPE_DICTIONARY or typeof(person.get("id")) != TYPE_STRING or typeof(person.get("name")) != TYPE_STRING:
				return false
			for stat in ["command", "might", "intellect", "politics", "charm"]:
				if not _integer(person.get(stat)) or person[stat] < 0 or person[stat] > 100:
					return false
			if typeof(person.get("traits")) != TYPE_ARRAY or not person.traits.all(func(trait_name): return typeof(trait_name) == TYPE_STRING):
				return false
	for id in ["liu_bei", "sun_quan", "cao_cao"]:
		if id not in faction_ids:
			return false
	for i in range(1, 9):
		var ship: Variant = combat.ship_types.get("SHP-%02d" % i)
		if typeof(ship) != TYPE_DICTIONARY or not _integer(ship.get("cost")) or ship.cost <= 0:
			return false
	var skills: Variant = canonical.realtime_rules.get("special_skills")
	if typeof(skills) != TYPE_DICTIONARY or skills.get("slots") != 3 or typeof(skills.get("slot_default")) != TYPE_ARRAY or typeof(skills.get("by_officer")) != TYPE_DICTIONARY or typeof(skills.get("skills")) != TYPE_ARRAY:
		return false
	for entry in skills.skills:
		if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("id")) != TYPE_STRING:
			return false
	for entry in skills.by_officer.values():
		if typeof(entry) != TYPE_DICTIONARY or typeof(entry.get("skill")) != TYPE_STRING:
			return false
	return true

static func _point(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and value.size() == 2 and _number(value[0]) and _number(value[1])

static func _number(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value))

static func _integer(value: Variant) -> bool:
	return _number(value) and float(value) == floor(float(value))

static func _fail(code: String) -> Dictionary:
	return {"ok": false, "error": code}
