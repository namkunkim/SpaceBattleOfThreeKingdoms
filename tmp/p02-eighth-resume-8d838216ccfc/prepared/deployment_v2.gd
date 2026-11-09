extends SceneTree

const SEED := -27182818
const FIELD := Vector2(1700, 1150)
const PLACE_OFFSET := Vector2(10, 5)
const MOVE_OFFSET := Vector2(40, 0)
const WORLD_BATTLE := "res://scenes/FleetBattle3D.tscn"
var args := OS.get_cmdline_user_args()
var failures := 0
var sink: FileAccess

func _initialize() -> void:
	call_deferred("_run")

func observe(key: String, value: Variant) -> void:
	sink.store_line(key + " " + var_to_str(value))
	sink.flush()

func check(key: String, yes: bool) -> void:
	print("ASSERT ", key, " ", yes)
	if not yes:
		failures += 1

func _run() -> void:
	sink = FileAccess.open(args[0], FileAccess.WRITE)
	var b := BattleBrief.new()
	b.seed = SEED
	root.get_node("WorldLink").go_battle(b)
	await scene_changed
	var f := current_scene
	f.set_process(false)
	var source := ScenarioProfile.load_profile(BattleBrief.PROFILE_DEF, "표준")
	var scenario := ProfileLoader.read_json(BattleBrief.SCENARIO)
	var org := Organization.auto_all(source, scenario)
	var effective := Organization.apply(source, org, scenario)
	check("confirmed-org-valid", not org.is_empty() and not effective.has("errors"))
	observe("confirmed-org", org)
	observe("source-fleet-definitions", [effective.ally, effective.foe])
	ScenarioProfile.enlarge_field(effective, FIELD)
	ScenarioProfile.tune_for_play(effective, 150.0, 15.0)
	var n := BattleSim.new(SEED, BattleRules.TICK_HZ, effective)
	for fleet in n.st.fleets:
		if fleet.side == 0 and fleet.faction == "liu_bei":
			fleet.control = "direct"
	var projected_events: Array[Dictionary] = []
	var s: Node = f.presentation.hud
	var begun: Dictionary = s.begin_battle(org)
	f.place_mode = true
	f._start()
	f.k6_events.clear()
	var actual: BattleSim = f.sim
	n.drain_events()
	check("published-confirmed-org", begun.ok and f.org == org and f.org_errors.is_empty() and f.placing and actual.st.tick == 0)
	check("pre-action-native", actual.fingerprint() == n.fingerprint())
	var id: int = f.flag(0).id
	var pos: Vector2 = n.st.by_id(id).pos
	var place := pos + PLACE_OFFSET
	var move := pos + MOVE_OFFSET
	observe("fixture-actions", [["place", 0, id, place], ["confirm", 0], ["move", 0, id, move], ["advance", 1]])
	f.issue(BattleCommands.make("move", [id], -1, place))
	n.issue(BattleSim.command(0, [id], "place", -1, place, {}))
	projected_events.append_array(n.drain_events_for(0))
	check("place-state", actual.st.tick == 0 and actual.fingerprint() == n.fingerprint())
	f.place_confirm()
	f.issue(BattleCommands.make("move", [id], -1, move))
	n.issue(BattleSim.command(0, [id], "move", -1, move, {}))
	projected_events.append_array(n.drain_events_for(0))
	check("same-tick-command", not f.placing and actual.st.tick == 0 and var_to_bytes(actual.command_log) == var_to_bytes(n.command_log))
	f.update_sim(0.1)
	n.step()
	projected_events.append_array(n.drain_events_for(0))
	observe("viewer-native", projected_events)
	observe("viewer-product", f.k6_events)
	check("typed-viewer-events", var_to_bytes(f.k6_events) == var_to_bytes(projected_events))
	observe("next-actual", [actual.st.tick, actual.st.clock_ms, actual.fingerprint(), actual.projection(0), actual.command_log])
	observe("next-native", [n.st.tick, n.st.clock_ms, n.fingerprint(), n.projection(0), n.command_log])
	observe("camera-selection", [f.cam_pos, f.cam_z, SelectionSet.ids(f.selected)])
	var raw_trace := FileAccess.get_file_as_string(f.trace.path)
	observe("trace-path", f.trace.path)
	check("trace-command-record", raw_trace.contains("command_request") and raw_trace.contains("command_applied"))
	check("next-tick-native", actual.st.tick == 1 and n.st.tick == 1 and actual.fingerprint() == n.fingerprint() and var_to_bytes(actual.projection(0)) == var_to_bytes(n.projection(0)))
	sink.close()
	quit(0 if failures == 0 else 1)
