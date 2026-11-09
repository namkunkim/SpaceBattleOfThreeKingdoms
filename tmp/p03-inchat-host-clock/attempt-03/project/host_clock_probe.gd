extends SceneTree

const CASE_SEED := 20261109
const EPS := 0.000001
const HOST := preload("res://scripts/FleetBattle3D.gd")
const SCENE := preload("res://scenes/FleetBattle3D.tscn")

var checks: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(label: String, passed: bool) -> void:
	checks.append({"name": label, "pass": passed})
	print("CHECK ", passed, " ", label)

func _near(a: float, b: float) -> bool:
	return absf(a - b) <= EPS

func _clock_state(c: TickClock) -> Array:
	return [c.hz, c.speed, c.acc, c.dropped]

func _fleet_ids(battle) -> Array:
	return battle.vm.by_id.keys() if battle.vm.get("by_id") != null else battle.sim.st.fleets.map(func(f): return f.id)

func _visible(battle) -> Dictionary:
	return {
		"ids": battle.presentation.renderer.vis.keys(),
		"fleet_ids": _fleet_ids(battle),
		"alpha": battle.vm.alpha,
		"selected": battle.selected.duplicate(),
		"marker": battle.marker.duplicate(true),
		"screen": battle.presentation.hud.screen,
	}

func _observe(battle) -> Dictionary:
	return {
		"seed": battle.battle_seed,
		"tick": battle.sim.st.tick,
		"clock_ms": battle.sim.st.clock_ms,
		"fingerprint": battle.sim.fingerprint(),
		"projection": battle.sim.projection(0),
		"main": _clock_state(battle.clock),
		"aux": _clock_state(battle._sim_acc_clock),
		"display": _visible(battle),
	}

func _detach_modules(old_sim: BattleSim) -> void:
	for key in ["detect", "salvo", "supply", "morale", "victory", "cai", "decisions", "chain", "cmd", "assault", "skills"]:
		var module = old_sim.get(key)
		if module != null:
			module.set("sim", null)

func _retire(battle) -> void:
	var old_sim: BattleSim = battle.sim
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	root.remove_child(battle)
	battle.free()
	_detach_modules(old_sim)

func _branch(phase: float, reject: bool) -> Dictionary:
	var battle = SCENE.instantiate()
	root.add_child(battle)
	battle.process_mode = Node.PROCESS_MODE_DISABLED
	battle.presentation.hud.guard.enabled = false
	battle.G.state = "play"
	battle.G.speed = 1.0
	battle.G.slow = 1.0
	battle.presentation.hud.show_screen("")
	battle.presentation._process(0)
	var base := _observe(battle)
	var identity_ok: bool = (
		is_same(battle.get_script(), HOST)
		and battle.sim.get_script().resource_path == "res://core/battle/battle_sim.gd"
		and battle.clock.get_script().resource_path == "res://core/battle/tick_clock.gd"
	)
	battle.clock.acc = phase
	battle._process(0.05)
	battle.presentation._process(0)
	var first := _observe(battle)
	var sim = battle.sim
	var main = battle.clock
	var aux = battle._sim_acc_clock
	var vm = battle.vm
	var renderer = battle.presentation.renderer
	var hud = battle.presentation.hud
	var game: Dictionary = battle.G.duplicate(true)
	var fleet_objects: Array = battle.fleets.duplicate()
	var rejection := true
	var preservation := true
	if reject:
		battle.profile_patch = func(profile): profile.ally = false
		var result: Dictionary = battle.init_game()
		rejection = (
			not result.ok and result.error == "invalid_candidate_profile"
			and result.path == "profile.ally" and is_instance_valid(battle._prepare_error_layer)
		)
		preservation = (
			is_same(battle.sim, sim) and is_same(battle.clock, main)
			and is_same(battle._sim_acc_clock, aux) and is_same(battle.vm, vm)
			and is_same(battle.presentation.renderer, renderer)
			and is_same(battle.presentation.hud, hud) and battle.G == game
			and battle.fleets == fleet_objects and _observe(battle) == first
		)
	battle._process(0.05)
	battle.presentation._process(0)
	var after := _observe(battle)
	var ordinary_publish := true
	if not reject:
		var publication: Dictionary = battle.init_game()
		ordinary_publish = (
			publication.ok and not is_same(battle.sim, sim)
			and not is_same(battle.clock, main) and not is_same(battle._sim_acc_clock, aux)
			and _clock_state(battle.clock) == base.main and _clock_state(battle._sim_acc_clock) == base.aux
			and battle.sim.st.tick == 0 and battle.G.state == "brief"
		)
	_retire(battle)
	if not reject:
		_detach_modules(sim)
	return {
		"base": base, "first": first, "after": after, "identity": identity_ok,
		"rejection": rejection, "preservation": preservation, "ordinary_publish": ordinary_publish,
	}

func _run() -> void:
	print("ENGINE ", JSON.stringify({"path": OS.get_executable_path(), "pid": OS.get_process_id()}))
	var link := root.get_node("WorldLink")
	var brief := BattleBrief.new()
	brief.seed = CASE_SEED
	link.brief = brief
	var reset := _branch(0.0, true)
	var reset_control := _branch(0.0, false)
	var preserve := _branch(0.75, true)
	var preserve_control := _branch(0.75, false)
	link.brief = null
	var base: Dictionary = reset.base
	var same: bool = (
		base == preserve.base and base == reset_control.base and base == preserve_control.base
		and base.seed == CASE_SEED and base.tick == 0 and base.clock_ms == 0
		and base.main == [10, 1.0, 0.0, 0.0] and base.aux == base.main
		and not base.display.ids.is_empty() and not base.display.fleet_ids.is_empty()
		and reset.identity and preserve.identity and reset_control.identity and preserve_control.identity
	)
	print("BASE ", JSON.stringify({"fingerprint": base.fingerprint, "preserve": preserve.base.fingerprint, "seed": base.seed}))
	_check("same_initial_host_state", same)
	print("FIRST ", JSON.stringify({
		"reset": {"tick": reset.first.tick, "ms": reset.first.clock_ms, "clock": reset.first.main, "alpha": reset.first.display.alpha},
		"preserve": {"tick": preserve.first.tick, "ms": preserve.first.clock_ms, "clock": preserve.first.main, "alpha": preserve.first.display.alpha},
	}))
	_check("actual_first_frame_phase_fork", (
		reset.first.tick == 0 and reset.first.clock_ms == 0
		and preserve.first.tick == 1 and preserve.first.clock_ms == 100
		and _near(reset.first.main[2], 0.5) and _near(preserve.first.main[2], 0.25)
		and _near(reset.first.display.alpha, 0.5) and _near(preserve.first.display.alpha, 0.25)
		and reset.first.aux == base.aux and preserve.first.aux == base.aux
		and reset.first == reset_control.first and preserve.first == preserve_control.first
	))
	_check("prepare_rejection_preserves_prior_host", (
		reset.rejection and preserve.rejection and reset.preservation and preserve.preservation
		and reset.after == reset_control.after and preserve.after == preserve_control.after
		and reset.after.tick == 1 and preserve.after.tick == 1
		and reset_control.ordinary_publish and preserve_control.ordinary_publish
	))
	await process_frame
	_check("clean_teardown_and_exact_gate", root.get_child_count() == 1 and root.get_node_or_null("WorldLink") == link)
	var ok := checks.size() == 4 and checks.all(func(row): return row.pass)
	print("HOST_CLOCK_RESULT ", JSON.stringify({"checks": checks, "pass": ok}))
	quit(0 if ok else 1)
