extends SceneTree

const SERVICE_FIXTURE := "res://tests/fixtures/p02/services.json"
const SEED := 0
const HZ := 10
const CONTROLS := ["direct", "direct"]
const FAR_STEPS := 1
const NEAR_STEPS := 1200

func input(scenario: String) -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERVICE_FIXTURE))
	data.seed = SEED
	data.hz = HZ
	data.initial_controls = CONTROLS.duplicate()
	data.policy = "none"
	data.max_ticks = 120
	if scenario == "clear":
		data.profile.combat.erase("detection")
	if scenario == "near":
		# Scout radar sees 225 units. The enemy's ordinary view does not.
		# Artillery's 260-unit range permits a natural asymmetric engagement.
		data.profile.ally[0].composition = [{"ship_type_id": "SHP-03", "count": 3}, {"ship_type_id": "SHP-06", "count": 1}]
		data.profile.foe[0].ships = 4
		data.profile.foe[0].composition = [{"ship_type_id": "SHP-04", "count": 4}]
		data.profile.foe[0].x = 625
	else:
		data.profile.foe[0].x = 1550
	return data

func typed_profile(scenario: String) -> Dictionary:
	# Construct the native profile directly from trusted rules/combat and typed
	# roster literals. Do not use adapter normalization or an owner observation.
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SERVICE_FIXTURE))
	var combat: Dictionary = data.profile.combat
	if scenario == "clear":
		combat.erase("detection")
	var near := scenario == "near"
	var ally_comp := [{"ship_type_id": "SHP-01", "count": 1}, {"ship_type_id": "SHP-03", "count": 1}, {"ship_type_id": "SHP-04", "count": 2}]
	if near:
		ally_comp = [{"ship_type_id": "SHP-03", "count": 3}, {"ship_type_id": "SHP-06", "count": 1}]
	var ally := {"name": "A", "role": "A", "ships": 4, "lv": 1, "x": 400.0, "y": 500.0,
		"p": 0, "flag": true, "composition": ally_comp, "formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	var foe := {"name": "B", "role": "B", "ships": 4 if near else 40, "lv": 1,
		"x": 625.0 if near else 1550.0, "y": 500.0, "p": 0, "flag": true,
		"composition": [{"ship_type_id": "SHP-04" if near else "SHP-02", "count": 4 if near else 40}],
		"formation_id": "FRM-01", "command": 70, "start_morale_bp": 10000}
	return {"profile_id": "p02-explicit-services", "rules": data.profile.rules,
		"ally": [ally], "foe": [foe], "reinf": [], "combat": combat}

func native(scenario: String) -> BattleSim:
	var sim := BattleSim.new(SEED, HZ, typed_profile(scenario))
	for i in CONTROLS.size():
		sim.st.fleets[i].control = CONTROLS[i]
	sim.projection(0)
	return sim

func clean(sim: BattleSim) -> void:
	for field in ["salvo", "detect", "supply"]:
		var module: Variant = sim.get(field)
		if module:
			module.sim = null

func stop_commands() -> Array[Dictionary]:
	return [BattleSim.command(0, [1], "stop"), BattleSim.command(1, [2], "stop")]

func prepare_native(sim: BattleSim, steps: int) -> void:
	for command in stop_commands():
		sim.issue(command)
	for i in steps:
		sim.step()

func _initialize() -> void:
	for scenario in ["clear", "far", "near"]:
		for side in [-1, 0, 1]:
			var sim := native(scenario)
			prepare_native(sim, NEAR_STEPS if scenario == "near" else FAR_STEPS)
			var contacts: Array = sim.detect.contacts.duplicate(true) if sim.detect else []
			var events := sim.drain_events() if side == -1 else sim.drain_events_for(side)
			print("NATIVE ", scenario, " ", side, " ", JSON.stringify({"contacts": contacts, "events": events}))
			clean(sim)
	quit()

