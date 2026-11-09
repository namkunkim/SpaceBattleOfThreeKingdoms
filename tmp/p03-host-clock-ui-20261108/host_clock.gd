extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> bool:
	print("CHECK ", ok, " ", label)
	if not ok:
		quit(1)
	return ok

func _run() -> void:
	seed(20261108)
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	battle.set("profile_patch", func(_p): seed(20261108))
	root.add_child(battle)
	battle.set_process(false)
	battle.presentation.hud.guard.enabled = false
	battle.G.state = "play"
	battle.G.speed = 1.0
	battle.G.slow = 1.0
	battle.presentation.hud.show_screen("")
	var sim: BattleSim = battle.sim
	var clock: TickClock = battle.clock
	var phase := 0.75 if "--preserve" in OS.get_cmdline_user_args() else 0.0
	clock.acc = phase
	if not check(sim.st.tick == 0 and sim.st.clock_ms == 0 and not sim.st.over and not battle.placing, "start boundary"): return
	print("INITIAL_FP ", sim.fingerprint())
	battle._process(0.05)
	var expected := 1 if phase > 0 else 0
	print("FRAME phase=", phase, " tick=", sim.st.tick, " acc=", clock.acc)
	if not check(sim.st.tick == expected and is_equal_approx(clock.acc, 0.25 if expected == 1 else 0.5), "actual first frame"): return
	var vm = battle.vm
	var aux = battle._sim_acc_clock
	var presentation = battle.presentation
	presentation._process(0)
	var renderer = presentation.renderer
	var deck = presentation.hud
	var ids: Array = renderer.vis.keys()
	var fleets: Array = battle.fleets.duplicate()
	var state: Dictionary = battle.G.duplicate(true)
	var fingerprint := sim.fingerprint()
	var acc := clock.acc
	var alpha: float = vm.alpha
	var screen: String = deck.screen
	battle.profile_patch = func(p): p.ally = false
	var result: Dictionary = battle.init_game()
	if not check(not result.ok and result.error == "invalid_candidate_profile" and result.path == "profile.ally", "expected prepare rejection"): return
	if not check(is_same(battle.sim, sim) and is_same(battle.clock, clock) and is_same(battle._sim_acc_clock, aux) and clock.acc == acc and sim.fingerprint() == fingerprint, "sim and clocks retained"): return
	if not check(is_same(battle.vm, vm) and vm.alpha == alpha and battle.fleets == fleets and is_same(battle.presentation.renderer, renderer) and renderer.vis.keys() == ids and is_same(battle.presentation.hud, deck) and deck.screen == screen and battle.G == state, "display retained"): return
	print("HOST_CLOCK_PASS")
	for key in ["detect", "salvo", "supply", "morale", "victory", "cai", "decisions", "chain", "cmd", "assault", "skills"]:
		var module = sim.get(key)
		if module != null:
			module.set("sim", null)
	battle.queue_free()
	await process_frame
	quit(0)
