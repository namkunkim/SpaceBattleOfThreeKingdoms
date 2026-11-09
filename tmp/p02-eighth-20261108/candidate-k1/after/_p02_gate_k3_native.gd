extends SceneTree

class Host extends "res://scripts/FleetBattle3D.gd":
	func _ready() -> void: pass

const SEED := -27182818
var args := OS.get_cmdline_user_args()
var fail_count := 0
var report: FileAccess

func _initialize() -> void:
	call_deferred("_run")

func record(name: String, value: Variant) -> void:
	report.store_line(name + " " + var_to_str(value))

func check(name: String, yes: bool) -> void:
	print("ASSERT ", name, " ", yes)
	if not yes:
		fail_count += 1

func native(profile: Dictionary, seed_id: int, mode: String) -> BattleSim:
	var s := BattleSim.new(seed_id, 10, profile)
	if mode == "direct":
		for f in s.st.fleets:
			if f.side == 0 and f.faction == "liu_bei":
				f.control = "direct"
	else:
		s.set_manual_all(false)
	return s

func source(diff: String) -> Dictionary:
	return Organization.load_auto(BattleBrief.PROFILE_DEF, diff)

func direct_effective(diff: String) -> Dictionary:
	var p := source(diff)
	var k := Vector2(1700.0 / float(p.rules.world_w), 1150.0 / float(p.rules.world_h))
	p.rules.world_w = 1700.0
	p.rules.world_h = 1150.0
	for f in p.ally + p.foe:
		f.x *= k.x
		f.y *= k.y
	for z in p.combat.get("terrain", {}).get("zones", []):
		z.rect = [z.rect[0] * k.x, z.rect[1] * k.y, z.rect[2] * k.x, z.rect[3] * k.y]
	for b in p.combat.get("supply", {}).get("bases", []):
		b.position = [b.position[0] * k.x, b.position[1] * k.y]
	for e in p.scenario.get("escape_points", {}).values():
		e.position = [e.position[0] * k.x, e.position[1] * k.y]
	for t in p.combat.ship_types.values():
		t.speed_per_turn *= 150.0
	if p.combat.has("evasion"):
		p.combat.evasion.bp_per_speed = float(p.combat.evasion.bp_per_speed) / 150.0
	var m: Dictionary = p.combat.movement
	m.face_turn_deg_per_s = m.turn_deg_per_s * 4
	m.turn_deg_per_s *= 15.0
	return p

func snapshot(s: BattleSim) -> Dictionary:
	var mods := {}
	for k in ["morale", "victory", "salvo", "terrain", "cai", "decisions", "detect", "supply", "chain", "cmd", "assault", "skills"]:
		mods[k] = s.get(k) != null
	var fleets := []
	for f in s.st.fleets:
		fleets.append([f.id, f.name, f.side, f.faction, f.control, f.pos])
	return {"tick":s.st.tick, "clock_ms":s.st.clock_ms, "hz":s.st.hz, "dt":s.dt, "seed":s.st.seed_id, "fleets":fleets, "mods":mods, "rng":s.rng.profile_id, "fingerprint":s.fingerprint(), "commands":s.command_log.duplicate(true), "events":s.drain_events()}

func compare(label: String, actual: BattleSim, expected: BattleSim) -> void:
	for tick in [0, 1, 10, 100]:
		while actual.st.tick < tick and not actual.st.over:
			actual.step()
		while expected.st.tick < tick and not expected.st.over:
			expected.step()
		var a := snapshot(actual)
		var b := snapshot(expected)
		record(label + "/actual/" + str(tick), a)
		record(label + "/native/" + str(tick), b)
		check(label + "/" + str(tick), var_to_bytes(a) == var_to_bytes(b))

func _run() -> void:
	report = FileAccess.open(args[1], FileAccess.WRITE)
	var link := root.get_node("WorldLink")
	var b := BattleBrief.new()
	b.seed = SEED
	link.brief = b
	var f := Host.new()
	root.add_child(f)
	for diff in BattleBrief.difficulties():
		f.difficulty = diff
		b.difficulty = diff
		var captured := [{}]
		f.profile_patch = func(p: Dictionary): captured[0] = p
		var d: Dictionary = f._prepare_game({})
		var eff := direct_effective(diff)
		record(diff + "/effective", captured[0])
		record(diff + "/effective-native", eff)
		check(diff + "/effective", var_to_bytes(captured[0]) == var_to_bytes(eff))
		check(diff + "/reinf-alias", is_same(captured[0].reinf, d.sim._reinf_def))
		record(diff + "/display-ally", d.ally)
		record(diff + "/display-foe", d.foe)
		compare(diff + "/direct", d.sim, native(eff, SEED, "direct"))
		var a := AutoResolver.new(b)
		check(diff + "/auto-prepare", a._prepare())
		compare(diff + "/auto", a.sim, native(source(diff), SEED, "auto"))
	f.profile_def = ""
	f.profile_patch = Callable()
	var poc: Dictionary = f._prepare_game({})
	compare("poc", poc.sim, native(PocSetup.profile(), SEED, "direct"))
	f.profile_def = BattleBrief.PROFILE_DEF
	f.profile_patch = func(p: Dictionary): p.ally = null
	check("legacy-roster-guard", f._prepare_game({}) == {"ok":false, "error":"invalid_candidate_profile", "path":"profile.ally"})
	f.free()
	b.difficulty = "unknown-difficulty"
	var invalid := AutoResolver.new(b)
	check("legacy-invalid-brief", not invalid.start() and invalid.error == "알 수 없는 난이도: unknown-difficulty" and invalid._thread == null and invalid.outcome == null)
	if args[0] == "after":
		var factory: RefCounted = load("res://core/battle/operation_runtime_adapter.gd").new()
		for mode in ["direct", "auto"]:
			for s in [-1, 4294967296]:
				var p := source("표준")
				var n: Dictionary = factory.call("create_product_native", p, s, mode)
				check("factory-success/%s/%d" % [mode, s], n.keys() == ["ok", "sim"] and n.ok and n.sim.st.seed_id == s and n.sim.st.hz == 10 and is_same(p.reinf, n.sim._reinf_def))
				compare("factory/%s/%d" % [mode, s], n.sim, native(source("표준"), s, mode))
		for mode in ["invalid", ""]:
			check("factory-rejection/" + mode, factory.call("create_product_native", source("표준"), SEED, mode) == {"ok":false, "error":"unsupported_mode", "path":"mode"})
	report.close()
	quit(0 if fail_count == 0 else 1)


