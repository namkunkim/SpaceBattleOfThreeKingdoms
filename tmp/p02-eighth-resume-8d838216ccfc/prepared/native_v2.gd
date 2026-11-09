extends SceneTree

class Host extends "res://scripts/FleetBattle3D.gd":
	func _ready() -> void: pass

const SEED := -27182818
var args := OS.get_cmdline_user_args()
var fail_count := 0
var report: FileAccess
var diff_filter := args[2]

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


func step_to(s: BattleSim, tick: int) -> void:
	while s.st.tick < tick and not s.st.over:
		s.step()

func compare_view(label: String, actual: BattleSim, oracle: BattleSim) -> void:
	for tick in [0, 1, 10, 100]:
		step_to(actual, tick)
		step_to(oracle, tick)
		var a := [actual.st.tick, actual.projection(0), actual.drain_events_for(0)]
		var b := [oracle.st.tick, oracle.projection(0), oracle.drain_events_for(0)]
		record(label + "/viewer/actual/" + str(tick), a)
		record(label + "/viewer/native/" + str(tick), b)
		check(label + "/viewer/" + str(tick), actual.st.tick == tick and var_to_bytes(a) == var_to_bytes(b))

func compare_reinf(label: String, actual: BattleSim, oracle: BattleSim) -> void:
	var prior := {}
	var oracle_prior := {}
	while not actual.st.reinf and not oracle.st.reinf and not actual.st.over and not oracle.st.over and actual.st.tick < 18000:
		prior = snapshot(actual)
		oracle_prior = snapshot(oracle)
		actual.step()
		oracle.step()
	var natural := [actual.st.reinf, oracle.st.reinf]
	record(label + "/reinf/natural", natural)
	check(label + "/reinf-before", var_to_bytes(prior) == var_to_bytes(oracle_prior))
	record(label + "/reinf/prior", [prior, oracle_prior])
	if natural == [false, false]:
		record(label + "/reinf/source", "DEBUG_FORCED_AFTER_NATURAL_UNOBSERVED")
		actual.debug_spawn_reinf()
		oracle.debug_spawn_reinf()
	var a := snapshot(actual)
	var b := snapshot(oracle)
	record(label + "/reinf/first", [a,b])
	check(label + "/reinf-first", natural[0] == natural[1] and actual.st.reinf and oracle.st.reinf and var_to_bytes(a) == var_to_bytes(b))

func _run() -> void:
	report = FileAccess.open(args[1], FileAccess.WRITE)
	var link := root.get_node("WorldLink")
	var b := BattleBrief.new()
	b.seed = SEED
	link.brief = b
	var f := Host.new()
	root.add_child(f)
	for diff in BattleBrief.difficulties():
		if diff != diff_filter:
			continue
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
		b.mode = "auto"
		var a := AutoResolver.new(b)
		check(diff + "/auto-prepare", a._prepare())
		record(diff + "/auto-effective", a.get("k6_effective"))
		check(diff + "/auto-effective", var_to_bytes(a.get("k6_effective")) == var_to_bytes(source(diff)))
		compare(diff + "/auto", a.sim, native(source(diff), SEED, "auto"))
		f.profile_patch = Callable()
		var direct_view: Dictionary = f._prepare_game({})
		compare_view(diff + "/direct", direct_view.sim, native(direct_effective(diff), SEED, "direct"))
		var auto_view := AutoResolver.new(b)
		check(diff + "/auto-view-prepare", auto_view._prepare())
		compare_view(diff + "/auto", auto_view.sim, native(source(diff), SEED, "auto"))
		var direct_reinf: Dictionary = f._prepare_game({})
		compare_reinf(diff + "/direct", direct_reinf.sim, native(direct_effective(diff), SEED, "direct"))
		var auto_reinf := AutoResolver.new(b)
		check(diff + "/auto-reinf-prepare", auto_reinf._prepare())
		compare_reinf(diff + "/auto", auto_reinf.sim, native(source(diff), SEED, "auto"))
	if diff_filter == "poc":
		var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
		battle.profile_def = ""
		root.add_child(battle)
		battle.set_process(false)
		var prior: BattleSim = battle.sim
		var init: Dictionary = battle.init_game()
		check("poc/published", init.ok and battle.sim != null and battle.sim != prior and battle.battle_seed == SEED and battle.sim.st.hz == 10)
		record("poc/effective", PocSetup.profile())
		var expected := native(PocSetup.profile(), SEED, "direct")
		expected.drain_events()
		compare("poc", battle.sim, expected)
		battle.free()
	f.free()
	if diff_filter == "invalid-brief":
		b.difficulty = "unknown-difficulty"
		var invalid := AutoResolver.new(b)
		var started := invalid.start()
		record("legacy-invalid-brief", [b.to_dict(), started, invalid.error, invalid._thread == null, invalid.outcome == null])
		check("legacy-invalid-brief", not started and invalid.error == "알 수 없는 난이도: unknown-difficulty" and invalid._thread == null and invalid.outcome == null)
	report.close()
	quit(0 if fail_count == 0 else 1)
