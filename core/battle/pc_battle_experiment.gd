extends RefCounted

const PRESETS := ["baseline", "slow_only", "large_only", "large_slow", "terrain"]

# Opt-in experiment; shared by the playable host and headless measurements.
static func configure(p: Dictionary, preset: String) -> Dictionary:
	assert(preset in PRESETS, "Unknown PC battle experiment preset: " + preset)
	var large := preset in ["large_only", "large_slow", "terrain"]
	var size := Vector2(6800, 4600) if large else Vector2(1700, 1150)
	var speed := 30.0 if preset in ["slow_only", "large_slow", "terrain"] else 150.0
	ScenarioProfile.enlarge_field(p, size)
	ScenarioProfile.tune_for_play(p, speed, 15.0)
	if preset == "terrain":
		var rows := [
			["N1", "nebula", [1700, 350, 900, 650]],
			["N2", "debris", [3000, 650, 750, 700]],
			["N3", "planet_shadow", [4400, 250, 900, 650]],
			["C1", "debris", [2200, 1550, 800, 650]],
			["C2", "nebula", [3550, 2000, 850, 650]],
			["C3", "debris", [4700, 1500, 650, 650]],
			["S1", "planet_shadow", [1400, 3150, 1000, 650]],
			["S2", "nebula", [2850, 3500, 850, 650]],
			["S3", "debris", [4150, 3100, 900, 650]],
			["R1", "nebula", [5500, 2650, 650, 650]],
		]
		var templates := {}
		for z in p.combat.terrain.zones:
			templates[z.type] = z
		var zones := []
		for row in rows:
			var z: Dictionary = templates[row[1]].duplicate(true)
			z.id = "PC-" + row[0]
			z.name = "%s · %s" % [row[0], z.name]
			z.rect = row[2].duplicate()
			zones.append(z)
		p.combat.terrain.zones = zones
	return {"preset": preset, "world": [size.x, size.y], "move_mul": speed, "turn_mul": 15.0,
		"zones": p.combat.terrain.zones.size(), "physical_obstacles": false}
