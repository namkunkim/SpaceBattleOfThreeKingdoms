extends SceneTree
const BATTLE := "res://scenes/FleetBattle3D.tscn"
const FALLBACK := "res://data/profiles/p02_sixth_missing.json"
const FIXED := 27182818

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := load(BATTLE).instantiate() as Node
	battle.profile_def = FALLBACK
	root.add_child(battle)
	battle.set_process(false)
	var initial_trace: String = battle.trace.path
	seed(FIXED)
	var expected_seed := randi()
	seed(FIXED)
	var result: Dictionary = battle.init_game()
	var current_trace: String = battle.trace.path
	var record := {"result":result,"rng_seed":FIXED,"expected_candidate_seed":expected_seed,"seed":battle.battle_seed,"path":battle.profile_def,
		"message":battle.load_error,"profile":battle.sim.profile_id,"fingerprint":battle.sim.fingerprint(),
		"ally":battle.ALLY_DEF,"foe":battle.FOE_DEF,"seq":battle.trace.seq,
		"initial_trace":ProjectSettings.globalize_path(initial_trace),"trace":ProjectSettings.globalize_path(current_trace),
		"routed":battle.routed(),"pid":OS.get_process_id()}
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_line(JSON.stringify(record))
	f.close()
	battle.free()
	quit(0 if result.ok and record.seed == expected_seed and record.seq == 1 and initial_trace != current_trace else 1)

