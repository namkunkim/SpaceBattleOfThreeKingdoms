extends SceneTree

const HOST := preload("res://scenes/FleetBattle3D.tscn")
const ADAPTER := preload("res://core/battle/operation_runtime_adapter.gd")
const SEED := 777
var rows := {}
var checks := 0
var failed := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failed += 1
		printerr("SIXTH_FAIL ", label)

func row(label: String, value: Dictionary, count: int, failures: int) -> void:
	rows[label] = {"value": value, "assertions": checks - count, "failures": failed - failures}

func button_named(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := button_named(child, label)
		if found:
			return found
	return null

func profile(b: Node) -> Dictionary:
	var p := Organization.load_auto(b.profile_def, b.difficulty) if b.org.is_empty() else Organization.apply(
		ScenarioProfile.load_profile(b.profile_def, b.difficulty), b.org, ProfileLoader.read_json(BattleBrief.SCENARIO))
	ScenarioProfile.enlarge_field(p, b.FIELD_SIZE)
	ScenarioProfile.tune_for_play(p, b.move_mul, b.turn_mul)
	return p

func native(b: Node) -> BattleSim:
	var oracle := BattleSim.new(b.battle_seed, BattleRules.TICK_HZ, profile(b))
	for f in oracle.st.fleets:
		if f.side == 0 and f.faction == "liu_bei":
			f.control = "direct"
	oracle.drain_events()
	return oracle

func roster(sim: BattleSim) -> Array:
	var out := []
	for f in sim.st.fleets:
		out.append([f.id, f.side, f.faction, f.sq_id, f.control, f.ships, str(f.pos), f.heading])
	return out

func commands(sim: BattleSim) -> void:
	var f: FleetState = sim.st.fleets[0]
	sim.issue(BattleSim.command(0, [f.id], "move", -1, f.pos + Vector2(40, 20)))
	sim.issue(BattleSim.command(0, [f.id], "stop"))

func event_fixture(sim: BattleSim) -> void:
	var ally: FleetState = sim.st.fleets[0]
	var foe: FleetState = null
	for f in sim.st.fleets:
		if f.side == 1 and not sim.detect.contacts[0].has(f.id):
			foe = f
			break
	check(foe != null, "unseen fleet exists")
	if foe != null:
		sim.emit("bench_visible", ally.id, -1, ally.pos, "visible")
		sim.emit("bench_hidden", foe.id, -1, foe.pos, "hidden")

func native_setup() -> Node:
	var b := HOST.instantiate()
	root.add_child(b)
	b.set_process(false)
	return b

func _run() -> void:
	check(ADAPTER.resource_path == "res://core/battle/operation_runtime_adapter.gd", "adapter class")
	check(FileAccess.get_sha256("res://.godot/global_script_class_cache.cfg") == "0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1", "classcache")
	check(not FileAccess.file_exists(GameSettings.PATH), "clean user")
	await exercise()
	print("SIXTH_COMMON rows=", rows.size(), " checks=", checks, " fails=", failed)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "\t"))
	f.close()
	quit(1 if failed or rows.size() != 8 else 0)

func exercise() -> void:
	var n := checks
	var fails := failed
	var world := (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate() as WorldMapScreen
	root.add_child(world)
	current_scene = world
	await process_frame
	world._set_mode("direct")
	world._set_difficulty("표준")
	world.sortie(SEED)
	world._skip.emit_signal("pressed")
	for i in 8:
		await process_frame
	var b := current_scene
	b.set_process(false)
	var deck: Node = b.presentation.hud
	var oracle := native(b)
	check(b.get_script().resource_path == "res://scripts/FleetBattle3D.gd", "host script")
	check(b.sim.get_script().resource_path == "res://core/battle/battle_sim.gd", "native class")
	check(b.battle_seed == SEED and b.difficulty == "표준" and b.routed(), "routed seed")
	check(roster(b.sim) == roster(oracle) and b.sim.st.hz == 10, "native initial roster controls")
	row("routed_seed_roster_controls", {"roster": roster(oracle), "seed": b.battle_seed, "hz": b.sim.st.hz, "ally_dto": b.ALLY_DEF, "foe_dto": b.FOE_DEF}, n, fails)
	n = checks
	fails = failed
	check(deck.screen == "prologue", "prologue")
	deck.screens.prologue.skip.emit_signal("pressed")
	check(deck.screen == "brief", "brief")
	button_named(deck.screens.brief, "자동 편성으로 시작").emit_signal("pressed")
	check(b.G.state == "play" and deck.screen == "", "started")
	var old: BattleSim = b.sim
	deck.restart()
	check(b.sim != old and b.G.state == "play" and deck.screen == "" and b.selected.size() == 1 and b.trace.seq > 0, "restart publishes")
	row("deck_start_restart", {"state": b.G.state, "camera": str(b.cam_pos), "zoom": b.cam_z, "screen": deck.screen, "selected": b.selected[0].id, "trace": b.trace.seq}, n, fails)
	n = checks
	fails = failed
	b.place_mode = true
	deck.restart()
	check(b.placing and b.sim.st.tick == 0, "placing")
	b._process(0.1)
	check(b.sim.st.tick == 0, "paused placement")
	b.place_turn(15.0)
	check(b.sim.st.tick == 0 and not b.sim.command_log.is_empty(), "tick zero command")
	b.place_confirm()
	b._process(0.1)
	check(not b.placing and b.sim.st.tick == 1, "resumed")
	row("placement_clock", {"tick": b.sim.st.tick, "commands": b.sim.command_log.duplicate(true)}, n, fails)
	n = checks
	fails = failed
	b.place_mode = false
	deck.restart()
	oracle = native(b)
	commands(b.sim)
	commands(oracle)
	event_fixture(b.sim)
	event_fixture(oracle)
	var raw: Array = b.sim._events.duplicate(true)
	var filtered := oracle.drain_events_for(0)
	check(b.sim.command_log == oracle.command_log and b.sim.command_log.size() == 2, "same tick command order")
	check(raw.any(func(e): return e.kind == "bench_hidden") and not filtered.any(func(e): return e.kind == "bench_hidden"), "fog removes event")
	check(filtered.any(func(e): return e.kind == "bench_visible"), "visible event")
	b._sync()
	b._pump()
	check(b.sim.drain_events().is_empty(), "host drained")
	row("same_tick_commands_events", {"raw": raw, "filtered": filtered, "commands": b.sim.command_log.duplicate(true)}, n, fails)
	n = checks
	fails = failed
	var result_oracle := ADAPTER.create({"mode": "operation", "format": ADAPTER.FORMAT,
		"profile": profile(b), "seed": SEED, "hz": 10, "initial_controls": [], "policy": "none", "max_ticks": 1})
	check(not result_oracle.ok and result_oracle.error == "unsupported_scenario" and result_oracle.path == "profile", "legacy operation rejection")
	row("actual_profile_operation_rejection", {"result": result_oracle, "profile_sha": FileAccess.get_sha256(b.profile_def)}, n, fails)
	n = checks
	fails = failed
	b.org.fleets[0].admiral = "invalid_admiral"
	b.init_game()
	check(not b.org_errors.is_empty() and b.load_error.contains("편성"), "invalid org preview")
	var errors: Array = b.org_errors.duplicate(true)
	check(b.org_blocked() and deck.screen == "org" and not deck.screens.org.notice.is_empty(), "org repair")
	row("invalid_org_legacy_preview", {"errors": errors, "notice": deck.screens.org.notice}, n, fails)
	n = checks
	fails = failed
	b.sim._end(true, "annihilation")
	b.end_game(true, "테스트")
	b.set_process(true)
	await create_timer(2.2).timeout
	deck.screens.result.title_btn.emit_signal("pressed")
	for i in 8:
		await process_frame
	var returned := current_scene as WorldMapScreen
	var link := root.get_node("WorldLink")
	check(returned != null and returned.outcome != null and returned.outcome.seed == SEED, "world consumes direct result")
	check(link.brief == null and link.outcome == null and link.take_outcome() == null, "one shot")
	row("direct_outcome_once", {"outcome": returned.outcome.to_dict()}, n, fails)
	returned.free()
	n = checks
	fails = failed
	b = HOST.instantiate()
	b.profile_def = "res://data/profiles/p02_sixth_missing.json"
	root.add_child(b)
	b.set_process(false)
	check(b.sim != null and b.load_error.contains("시험 전장"), "POC fallback")
	row("legacy_profile_fallback", {"load_error": b.load_error, "roster": roster(b.sim)}, n, fails)
	b.free()
