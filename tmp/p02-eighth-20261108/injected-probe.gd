extends SceneTree
const FACTORY := preload("res://core/battle/operation_runtime_adapter.gd")
const BATTLE := "res://scenes/FleetBattle3D.tscn"
const WORLD := "res://scenes/WorldMap.tscn"
const SEED := -27182818
var failures := 0
var link: Node

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, yes: bool) -> void:
	print("ASSERT ", label, " ", yes)
	if not yes:
		failures += 1

func reset_counts() -> void:
	FACTORY.probe_enter = 0
	FACTORY.probe_ctor = 0
	FACTORY.probe_publish = 0
	FACTORY.probe_thread = 0
	FACTORY.probe_error = {}

func counts() -> Array:
	return [FACTORY.probe_enter, FACTORY.probe_ctor, FACTORY.probe_publish, FACTORY.probe_thread]

func bad() -> Dictionary:
	return {"ok":false, "error":"unsupported_mode", "path":"mode"}

func brief(mode: String) -> BattleBrief:
	var b := BattleBrief.new()
	b.seed = SEED
	b.mode = mode
	return b

func report(label: String, data: Variant) -> void:
	print("OBS ", label, " ", var_to_str(data))

func state(f: Node) -> Array:
	return [f.sim, f.sim.st.tick, f.sim.fingerprint(), f.sim._queue.duplicate(true), f.sim._events.duplicate(true), f.org.duplicate(true), f.clock, f.cam_pos, f.cam_z, f.selected.duplicate(), f.trace]

func _run() -> void:
	link = root.get_node("WorldLink")
	OS.set_environment("P02_PROBE_MODE", "")
	reset_counts()
	link.go_battle(brief("direct"))
	await scene_changed
	var f := current_scene
	f.set_process(false)
	check("direct-normal", counts() == [1,1,1,0] and f.sim.st.seed_id == SEED)
	f.profile_patch = func(p: Dictionary): p.foe = false
	reset_counts()
	check("direct-old-guard-no-entry", f.init_game() == {"ok":false, "error":"invalid_candidate_profile", "path":"profile.foe"} and counts() == [0,0,0,0])
	f.profile_patch = Callable()
	var before := state(f)
	reset_counts()
	OS.set_environment("P02_PROBE_MODE", "direct")
	var error: Dictionary = f.init_game()
	report("direct-fail", [counts(), error, FACTORY.probe_seed, FACTORY.probe_profile.keys()])
	check("direct-factory-reject", counts() == [1,0,0,0] and error == bad() and FACTORY.probe_error == bad() and FACTORY.probe_seed == SEED and not FACTORY.probe_profile.is_empty())
	check("direct-active-unchanged", state(f) == before)
	reset_counts()
	OS.set_environment("P02_PROBE_MODE", "")
	check("direct-retry", f.init_game().ok and counts() == [1,1,1,0] and f.sim != before[0])
	reset_counts()
	OS.set_environment("P02_PROBE_MODE", "direct")
	link.go_battle(brief("direct"))
	await scene_changed
	f = current_scene
	var exit := root.gui_get_focus_owner() as Button
	check("direct-initial-reject", counts() == [1,0,0,0] and f.sim == null and f.presentation == null and exit != null and exit.name == "ExitBattlePrepareError")
	if exit == null:
		quit(2)
		return
	exit.pressed.emit()
	await scene_changed
	check("direct-initial-return", current_scene.scene_file_path == WORLD and link.brief == null and link.outcome == null)
	var w := current_scene as WorldMapScreen
	w.brief = brief("auto")
	reset_counts()
	OS.set_environment("P02_PROBE_MODE", "auto")
	w._start_resolve()
	report("auto-fail", [counts(), FACTORY.probe_error, FACTORY.probe_seed, FACTORY.probe_profile.keys()])
	check("auto-factory-reject", counts() == [1,0,0,0] and FACTORY.probe_error == bad() and FACTORY.probe_seed == SEED and not FACTORY.probe_profile.is_empty())
	check("auto-browse", w.state == "browse" and w.resolver == null and w.outcome == null and not w._resolve.visible)
	reset_counts()
	OS.set_environment("P02_PROBE_MODE", "")
	w._start_resolve()
	var a := w.resolver
	check("auto-retry-start", counts() == [1,1,0,1] and a != null and a._thread != null and a._thread.is_started())
	var deadline := Time.get_ticks_msec() + 175000
	while w.state == "resolve" and Time.get_ticks_msec() < deadline:
		await process_frame
	check("auto-retry-join-result", w.outcome != null and w.state == "result" and a != null and a._thread == null and a.outcome == w.outcome)
	if w.outcome:
		report("auto-retry-outcome", w.outcome.to_dict())
	quit(0 if failures == 0 else 1)
