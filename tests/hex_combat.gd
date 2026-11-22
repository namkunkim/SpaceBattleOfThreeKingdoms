extends SceneTree

const HexRules := preload("res://core/battle/hex_battle_rules.gd")

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var profile := Organization.load_auto("res://data/profiles/red_cliffs_rt.json", "표준")
	profile["hex_combat"] = true
	var sim := BattleSim.new(17, 10, profile)
	var source := sim.st.flag(0)
	var target := sim.st.flag(1)
	var base := Vector2(HexRules.WIDTH * 4, HexRules.ROW_HEIGHT * 4)
	source.pos = base
	target.pos = base + Vector2(HexRules.WIDTH * 4, 0)
	var old_equip := source.equip
	var old_scout: Array = source.stages.get("SHP-06", [])
	source.equip = ""
	source.stages["SHP-06"] = [0, 0, 0, 0]
	if not TestCheck.ok(self, not sim.detect.in_view(source, target), "ordinary detection rejects four cells"): return
	target.pos = base + Vector2(HexRules.WIDTH * 3, 0)
	if not TestCheck.ok(self, sim.detect.in_view(source, target), "ordinary detection accepts three cells"): return
	source.stages["SHP-06"] = [1, 0, 0, 0]
	target.pos = base + Vector2(HexRules.WIDTH * 4, 0)
	if not TestCheck.ok(self, sim.detect.in_view(source, target), "recon detection accepts four cells"): return
	target.pos = base + Vector2(HexRules.WIDTH * 5, 0)
	if not TestCheck.ok(self, not sim.detect.in_view(source, target), "recon detection rejects five cells"): return
	if old_scout.is_empty():
		source.stages.erase("SHP-06")
	else:
		source.stages["SHP-06"] = old_scout
	source.equip = old_equip

	for category in ["artillery", "line_fire", "fighter"]:
		var shooter: FleetState = null
		for fleet in sim.st.alive(0):
			if not sim.salvo.platforms(fleet, category).is_empty():
				shooter = fleet
				break
		if not TestCheck.ok(self, shooter != null, "fixture has " + category): return
		shooter.pos = base
		shooter.heading = 0.0
		var reach := 2 if category == "artillery" else 1
		target.pos = base + Vector2(HexRules.WIDTH * (reach + 1), 0)
		if not TestCheck.ok(self, sim.salvo.qualifying(shooter, category, target).is_empty(), "outside reach " + category): return
		target.pos = base + Vector2(HexRules.WIDTH * reach, 0)
		if not TestCheck.ok(self, not sim.salvo.qualifying(shooter, category, target).is_empty(), "inside reach " + category): return

	source.pos = base
	source.heading = 0.0
	target.pos = base + Vector2(HexRules.WIDTH, 0)
	var target_position := target.pos
	var destination := base + Vector2(HexRules.WIDTH * 2, 0)
	sim.detect._eval(0)
	sim.detect._eval(1)
	sim.apply({"kind": "ai_move", "side": 0, "ids": [source.id], "point": destination})
	sim.apply({"kind": "ai_move", "side": 1, "ids": [target.id], "point": base})
	sim.apply({"kind": "ai_target", "side": 0, "ids": [source.id], "target_id": target.id})
	sim._fleet_phase(true)
	if not TestCheck.ok(self, source.pos == base and target.pos == target_position and not source.has_move and not target.has_move, "contact and AI orders cannot move either side"): return

	sim.issue({"kind": "move", "side": 0, "ids": [source.id], "point": destination})
	sim.apply({"kind": "ai_move", "side": 0, "ids": [source.id], "point": base})
	if not TestCheck.ok(self, source.move_to.distance_to(destination) < 0.01, "AI cannot override explicit movement"): return
	for category in source.next_fire:
		source.next_fire[category] = 0
	# Isolate movement from terrain obstruction and fleet destruction.
	sim.terrain = null
	source.speed = 80.0
	for weapon in sim.salvo.C.weapons.values():
		weapon.base_damage = 0
	var fired_while_moving := false
	for i in 240:
		sim.st.tick += 1
		sim._fleet_phase(true)
		sim.salvo.step()
		for event in sim.drain_events():
			if event.kind == "salvo" and event.sq == source.id and source.has_move:
				fired_while_moving = true
		if not source.has_move:
			break
	if not TestCheck.ok(self, fired_while_moving and not source.has_move and source.pos.distance_to(destination) < sim.R.arrive_r, "explicit movement crosses engagement distance during fire (%s, %s, %s)" % [fired_while_moving, source.has_move, source.pos]): return
	var arrived := source.pos
	sim.apply({"kind": "ai_move", "side": 0, "ids": [source.id], "point": base})
	sim._fleet_phase(true)
	if not TestCheck.ok(self, source.pos == arrived and target.pos == target_position, "both fleets stay put without another movement order"): return
	if not TestCheck.ok(self, sim.salvo.evasion_bp(source, "line_fire") == 0, "hex engagements do not grant movement evasion"): return
	preload("res://scripts/legacy_battle_lifetime.gd").release(sim)
	print("HEX_COMBAT_PASS")
	quit(0)
