extends SceneTree

const TRIAL := preload("res://scripts/red_cliffs_a04_trial.gd")
const BATTLE := preload("res://scenes/FleetBattle3D.tscn")

var checks := 0
var failures := 0

func _initialize() -> void:
	run.call_deferred()


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)


func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3 or args[0] != "--red-cliffs-a04-trial":
		quit(2)
		return
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
	var design: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(args[2]))
	if FileAccess.get_sha256(args[1]) != design.envelope_sha256:
		quit(2)
		return
	var brief := BattleBrief.new()
	brief.seed = int(envelope.seed)
	root.get_node("WorldLink").brief = brief
	var battle := BATTLE.instantiate()
	root.add_child(battle)
	var sim: BattleSim = battle.sim
	var radii := {}
	for row in envelope.rosters:
		radii[row.roster_id] = row.frozen_candidate_radius
	check(sim.st.tick == 0 and sim.st.fleets.size() == 16, "actual initial fleet snapshot")
	check(sim.rs.world == point(envelope.extent), "frozen effective extent")
	check(not sim.terrain.is_empty(), "native terrain available")
	var result := {}
	var routes := []
	var fingerprint := sim.fingerprint()
	var positive: Dictionary
	var clear_routes := []
	var excluded: Array[Rect2] = []
	for fleet in sim.st.fleets:
		var radius: float = radii[fleet.sq_id]
		for kind in ["supply", "exit"]:
			for id in design[kind].centers:
				var region := {"kind": kind, "id": int(id) if kind == "exit" else id,
					"center": point(design[kind].centers[id]), "radius": design[kind].radius}
				var verdict := TRIAL.assess(sim, TRIAL.FEATURE, fleet, radius, region, excluded)
				var key: String = kind + "/" + verdict
				result[key] = result.get(key, 0) + 1
				routes.append({"roster": fleet.sq_id, "spawn": xy(fleet.pos), "target": region.id,
					"kind": kind, "verdict": verdict})
				if verdict == "clear":
					var candidate := {"fleet": fleet, "region": region, "radius": radius}
					clear_routes.append(candidate)
					if positive.is_empty():
						positive = candidate
	check(routes.size() == 80, "complete spawn-to-region matrix")
	check(result.get("supply/supply_not_authorized", 0) == 26, "opposing bases denied")
	check(result.get("exit/exit_not_authorized", 0) == 16, "opposing exits denied")
	check(not positive.is_empty(), "actual spawn has at least one clear route")
	check(result.get("exit/spawn_outside_envelope", 0) > 0, "wall-overlapping actual spawn fails closed")
	if not positive.is_empty():
		var fleet: FleetState = positive.fleet
		var center: Vector2 = positive.region.center
		var middle := fleet.pos.lerp(center, 0.5)
		var blocker: Array[Rect2] = [Rect2(middle - Vector2.ONE, Vector2(2, 2))]
		check(TRIAL.assess(sim, "", fleet, positive.radius, positive.region, excluded) == "disabled",
			"legacy requires explicit opt-in")
		check(TRIAL.assess(sim, TRIAL.FEATURE, fleet, positive.radius, positive.region, blocker) == "obstructed",
			"explicit hard blocker on actual route fails closed")
		check(not TRIAL.simultaneous_clear(fleet.pos, center, positive.radius, center, fleet.pos, positive.radius),
			"simultaneous opposing traversals collide continuously")
		check(TRIAL.simultaneous_clear(fleet.pos, center, positive.radius, fleet.pos + Vector2(0, 500),
			center + Vector2(0, 500), positive.radius), "parallel nonoverlapping trajectories")
	var traffic := {"clear": 0, "conflict": 0}
	for i in clear_routes.size():
		for j in range(i + 1, clear_routes.size()):
			var a: Dictionary = clear_routes[i]
			var b: Dictionary = clear_routes[j]
			if a.fleet == b.fleet:
				continue
			var clear := TRIAL.simultaneous_clear(a.fleet.pos, a.region.center, a.radius,
				b.fleet.pos, b.region.center, b.radius)
			traffic["clear" if clear else "conflict"] += 1
	check(traffic.clear > 0 and traffic.conflict > 0, "actual route pairs exhibit both traffic outcomes")
	check(sim.fingerprint() == fingerprint and sim.st.tick == 0, "trial leaves product state unchanged")
	var report := FileAccess.open("user://a04-runtime-trial.json", FileAccess.WRITE)
	report.store_string(JSON.stringify({"status": "TRIAL_ONLY", "product_a04": "NOT_READY",
		"common_manifest": "UNMET", "consumers": {"direct": "UNMET", "auto": "UNMET", "replay": "UNMET"},
		"checks": checks, "failures": failures, "counts": result, "traffic": traffic, "routes": routes}, "\t"))
	report.close()
	print("A04_RUNTIME_TRIAL checks=%d failures=%d %s" % [checks, failures, JSON.stringify({"routes": result, "traffic": traffic})])
	root.remove_child(battle)
	battle.free()
	for key in ["salvo", "detect", "supply", "cai", "morale", "victory", "cmd", "skills", "decisions", "chain", "assault"]:
		var part: Variant = sim.get(key)
		if part is Object and "sim" in part:
			part.sim = null
	quit(0 if failures == 0 else 1)


func point(pair: Array) -> Vector2:
	return Vector2(pair[0], pair[1])


func xy(value: Vector2) -> Array:
	return [value.x, value.y]

