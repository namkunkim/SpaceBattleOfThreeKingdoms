extends SceneTree

const PREPARE := preload("res://scripts/FleetBattle3D.gd")
const DENSITY := preload("res://tests/bench_density.gd")
const DRILL := preload("res://tools/scenario/cross_counter_drill.gd")
const FIXED_SEED := -27182818
var failed := 0
var sink: FileAccess

class Host extends "res://scripts/FleetBattle3D.gd":
	func _ready() -> void: pass

func _initialize() -> void:
	call_deferred("_run")

func check(k: String, ok: bool) -> void:
	print("ASSERT ", k, " ", ok)
	if not ok:
		failed += 1

func write(k: String, v: Variant) -> void:
	sink.store_line(k + " " + var_to_str(v))
	sink.flush()

func raw(p: Dictionary) -> BattleSim:
	var sim := BattleSim.new(FIXED_SEED, 10, p)
	for f in sim.st.fleets:
		if f.side == 0 and f.faction == "liu_bei":
			f.control = "direct"
	return sim

func effective() -> Dictionary:
	var p := Organization.load_auto(BattleBrief.PROFILE_DEF, "표준")
	ScenarioProfile.enlarge_field(p, Vector2(1700.0, 1150.0))
	ScenarioProfile.tune_for_play(p, 150.0, 15.0)
	return p

func sample(h: Host, label: String, cb: Callable) -> void:
	var refs := []
	h.profile_patch = func(p: Dictionary):
		cb.call(p)
		refs.assign([p, p.reinf, null if p.reinf.is_empty() else p.reinf[0], p.combat])
	var r: Dictionary = h._prepare_game({})
	var s: BattleSim = r.sim
	var oracle_p := effective()
	cb.call(oracle_p)
	var o := raw(oracle_p)
	check(label + "/prepared-seed", r.ok and s.st.seed_id == FIXED_SEED and s.st.hz == 10)
	check(label + "/typed-effective", var_to_bytes(refs[0]) == var_to_bytes(oracle_p))
	check(label + "/alias-reinf-combat", is_same(refs[1], s._reinf_def) and is_same(refs[3], s.salvo.C) and is_same(oracle_p.reinf, o._reinf_def) and is_same(oracle_p.combat, o.salvo.C))
	check(label + "/initial", s.fingerprint() == o.fingerprint() and var_to_bytes(s._events) == var_to_bytes(o._events))
	write(label + "/effective", refs[0])
	write(label + "/initial-events", s.drain_events())
	o.drain_events()
	if label == "synthetic":
		check("synthetic/element-alias", is_same(refs[2], s._reinf_def[0]) and is_same(oracle_p.reinf[0], o._reinf_def[0]))
		refs[2].name = "P02_ALIAS_AFTER_PREPARE"
		oracle_p.reinf[0].name = "P02_ALIAS_AFTER_PREPARE"
		s.debug_spawn_reinf()
		o.debug_spawn_reinf()
		var a := s.st.fleets.filter(func(f): return f.name == "P02_ALIAS_AFTER_PREPARE")
		var b := o.st.fleets.filter(func(f): return f.name == "P02_ALIAS_AFTER_PREPARE")
		check("synthetic/after-mutation-name-and-id", a.size() == 1 and b.size() == 1 and a[0].id == b[0].id and a[0].control == b[0].control)
		check("synthetic/after-mutation-state-events", s.fingerprint() == o.fingerprint() and var_to_bytes(s._events) == var_to_bytes(o._events))
		write("synthetic/forced-reinf", [s.st.tick, s.st.clock_ms, s.fingerprint(), s.drain_events()])
	h.profile_patch = Callable()

func _run() -> void:
	sink = FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	var b := BattleBrief.new()
	b.seed = FIXED_SEED
	root.get_node("WorldLink").brief = b
	var h := Host.new()
	root.add_child(h)
	var dn := DENSITY.new()
	var dr := DRILL.new()
	dr.cfg = ProfileLoader.read_json(dr.CONFIG)
	sample(h, "density", dn._big_preset)
	sample(h, "cross-counter", dr._patch)
	var patch := func(p: Dictionary):
		p.ally[0].x = 313.125
		p.combat.ship_types.values()[0].speed_per_turn = 177.25
	sample(h, "synthetic", patch)
	var bad: Dictionary = h._prepare_game({"fleets": 3})
	check("invalid-org-auto-fallback", bad.ok and not bad.errors.is_empty() and not bad.fallback and bad.sim.fingerprint() == raw(effective()).fingerprint())
	write("invalid-org-fallback", [bad.errors, bad.message, bad.fallback, bad.sim.fingerprint()])
	dn.free()
	dr.free()
	h.free()
	sink.close()
	quit(0 if failed == 0 else 1)
