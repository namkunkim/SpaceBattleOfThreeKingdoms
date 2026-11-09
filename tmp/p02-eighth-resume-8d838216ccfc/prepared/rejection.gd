extends SceneTree

const FACTORY_PATH := "res://core/battle/operation_runtime_adapter.gd"
const SEED := -27182818
const WORLD := "res://scenes/WorldMap.tscn"
const BATTLE := "res://scenes/FleetBattle3D.tscn"
var args := OS.get_cmdline_user_args()
var failures := 0
var sink: FileAccess
var link: Node

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, ok: bool) -> void:
	print("ASSERT ", label, " ", ok)
	if not ok:
		failures += 1

func save(label: String, value: Variant) -> void:
	sink.store_line(label + " " + var_to_str(value))
	sink.flush()

func adapter() -> Script:
	return load(FACTORY_PATH)

func reset() -> void:
	var factory := adapter()
	for k in ["probe_enter", "probe_ctor", "probe_publish", "probe_thread"]:
		factory.set(k, 0)
	factory.set("probe_error", {})

func counters() -> Array:
	var a := adapter()
	return [a.get("probe_enter"), a.get("probe_ctor"), a.get("probe_publish"), a.get("probe_thread")]

func brief() -> BattleBrief:
	var b := BattleBrief.new()
	b.seed = SEED
	return b

func unsupported() -> Dictionary:
	return {"ok":false, "error":"unsupported_mode", "path":"mode"}

func snapshot(f: Node) -> Dictionary:
	var s: BattleSim = f.sim
	var path: String = f.trace.path
	return {"tick":s.st.tick, "clock_ms":s.st.clock_ms, "hz":s.st.hz, "rng":s.rng.profile_id,
		"fingerprint":s.fingerprint(), "queue":s._queue.duplicate(true), "events":s._events.duplicate(true),
		"commands":s.command_log.duplicate(true), "trace_seq":f.trace.seq,
		"trace_text":FileAccess.get_file_as_string(path), "org":f.org.duplicate(true),
		"camera":[f.cam_pos, f.cam_z], "selected":SelectionSet.ids(f.selected), "G":f.G.duplicate(true),
		"placing":f.placing, "route":link.brief.to_dict(), "outcome":link.outcome != null}

func subsequent(f: Node) -> Array:
	var id: int = f.flag(0).id
	var cmd := BattleCommands.make("move", [id], -1, f.sim.st.by_id(id).pos + Vector2(2, 2))
	f.issue(cmd)
	f.update_sim(0.1)
	return [f.sim.st.tick, f.sim.fingerprint(), f.sim.command_log.duplicate(true), f.sim.projection(0)]

func route() -> void:
	link.go_battle(brief())
	await scene_changed
	current_scene.set_process(false)

func active(injected: bool) -> void:
	var i := args[0] == "instrumented"
	await route()
	var control := subsequent(current_scene)
	if i:
		reset()
	await route()
	var f := current_scene
	if i:
		check("active-normal-counts", counters() == [1,1,1,0])
		reset()
	var s: BattleSim = f.sim
	var trace: RefCounted = f.trace
	var clock: RefCounted = f.clock
	var presentation: Node = f.presentation
	var prior := snapshot(f)
	save("active/before", prior)
	if injected:
		OS.set_environment("P02_PROBE_MODE", "direct")
	else:
		f.profile_patch = func(p: Dictionary): p.foe = false
	var result: Dictionary = f.init_game()
	var now := snapshot(f)
	save("active/after", now)
	save("active/error", result)
	check("active-exact-rejection", result == (unsupported() if injected else {"ok":false, "error":"invalid_candidate_profile", "path":"profile.foe"}))
	check("active-identity", f.sim == s and f.trace == trace and f.clock == clock and f.presentation == presentation)
	check("active-snapshot", var_to_bytes(now) == var_to_bytes(prior))
	check("active-error-visibility", f._prepare_error_layer != null and f._prepare_error_reason.text == "함대 편성 데이터가 올바르지 않습니다.")
	if i:
		save("active/counters", counters())
		check("active-rejection-counts", counters() == ([1,0,0,0] if injected else [0,0,0,0]))
	if injected:
		var p: Dictionary = adapter().get("probe_profile")
		save("active/effective", p)
		check("active-mode-only", adapter().get("probe_seed") == SEED and p.ally is Array and p.foe is Array and adapter().get("probe_error") == unsupported())
	OS.set_environment("P02_PROBE_MODE", "")
	f.profile_patch = Callable()
	var next := subsequent(f)
	save("active/control-next", control)
	save("active/after-next", next)
	check("active-next-tick", next[0] == 1 and var_to_bytes(next) == var_to_bytes(control))
	if i:
		reset()
	f._restart()
	check("active-restart", f.sim != s and f.sim.st.seed_id == SEED and f._prepare_error_layer == null and f.G.state == "play")
	if i:
		check("active-recovery-counts", counters() == [1,1,1,0])

func initial(injected: bool) -> void:
	var i := args[0] == "instrumented"
	if i:
		reset()
	OS.set_environment("P02_PROBE_MODE", "direct" if injected else "")
	OS.set_environment("P02_K6_INITIAL_GUARD", "" if injected else "1")
	await route()
	OS.set_environment("P02_K6_INITIAL_GUARD", "")
	OS.set_environment("P02_PROBE_MODE", "")
	var f := current_scene
	var button := root.gui_get_focus_owner() as Button
	var ready := button != null and button.name == "ExitBattlePrepareError" and button.is_visible_in_tree()
	check("initial-rejected", f.sim == null and f.presentation == null and f.routed() and link.outcome == null and ready)
	if i:
		save("initial/counters", counters())
		check("initial-counts", counters() == ([1,0,0,0] if injected else [0,0,0,0]))
	if not ready:
		return
	await process_frame
	var pos := button.get_global_rect().get_center()
	save("initial/input", ["VIEWPORT_MOUSE", str(button.get_path()), pos])
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = pos
		event.global_position = pos
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
	for k in range(60):
		if current_scene != null and current_scene.scene_file_path == WORLD:
			break
		await process_frame
	var w := current_scene as WorldMapScreen
	save("initial/return", [w != null, link.brief == null, link.outcome == null, w.outcome == null if w else false])
	check("initial-returned-without-result", w != null and link.brief == null and link.outcome == null and w.outcome == null and not w._result.visible)

func factory_contract() -> void:
	for mode in ["direct", "auto"]:
		for seed_id in [-1, 4294967296]:
			var p := Organization.load_auto(BattleBrief.PROFILE_DEF, "표준")
			reset()
			var value: Dictionary = adapter().call("create_product_native", p, seed_id, mode)
			var id := "%s/%d" % [mode, seed_id]
			check("shape/" + id, value.keys() == ["ok", "sim"] and value.ok is bool and value.ok and value.sim is BattleSim)
			if value.get("sim") is BattleSim:
				var s: BattleSim = value.sim
				check("state/" + id, s.st.seed_id == seed_id and s.st.hz == 10 and is_same(p.reinf, s._reinf_def))
				save(id, [s.st.seed_id, s.st.hz, s.fingerprint(), counters()])
			check("calls/" + id, counters() == [1,1,0,0])
	for mode in ["invalid", ""]:
		reset()
		var fail: Dictionary = adapter().call("create_product_native", Organization.load_auto(BattleBrief.PROFILE_DEF, "표준"), SEED, mode)
		save("reject/" + mode, [fail, counters()])
		check("reject/" + mode, var_to_bytes(fail) == var_to_bytes(unsupported()) and counters() == [1,0,0,0])

func _run() -> void:
	sink = FileAccess.open(args[2], FileAccess.WRITE)
	link = root.get_node("WorldLink")
	match args[1]:
		"contract": factory_contract()
		"guard-active": await active(false)
		"guard-initial": await initial(false)
		"mode-active": await active(true)
		"mode-initial": await initial(true)
		_: check("known-case", false)
	sink.close()
	quit(0 if failures == 0 else 1)
