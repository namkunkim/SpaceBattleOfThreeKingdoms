extends SceneTree

const WORLD := "res://scenes/WorldMap.tscn"
const BATTLE := preload("res://scenes/FleetBattle3D.tscn")
const SEED := 777
const EXCLUDED := "RC-LIU-SQ-02"
var checks := {}
var facts := {}
var lane := ""
var phase := ""
var difficulty := ""
var expected: Dictionary
var link: Node

func _initialize() -> void:
	call_deferred("_run")

func check(id: String, value: bool) -> void:
	if checks.has(id):
		checks["duplicate." + id] = false
	checks[id] = value

func finish() -> void:
	var failed := checks.keys().filter(func(id): return not checks[id])
	var result := {"lane": lane, "phase": phase, "checks": checks, "facts": facts, "failed": failed}
	var raw := JSON.stringify(result)
	var out := FileAccess.open(OS.get_environment("P02_DIFFICULTY_RAW"), FileAccess.WRITE)
	if out == null:
		print("P02_DIFFICULTY_OUTPUT_ERROR")
		quit(2)
		return
	out.store_line(raw)
	out.close()
	print("P02_DIFFICULTY_DONE ", checks.size(), " ", failed.size())
	quit(0 if failed.is_empty() else 1)

func frames(count := 4) -> void:
	for i in count:
		await process_frame

func button(n: Node, title: String) -> Button:
	if n is Button and n.text == title and n.is_visible_in_tree() and not n.disabled:
		return n
	for child in n.get_children():
		var found := button(child, title)
		if found != null:
			return found
	return null

func press(b: Button, id: String) -> bool:
	if b == null or not b.is_visible_in_tree() or b.disabled:
		check("fixture." + id, false)
		return false
	b.pressed.emit()
	return true

func install_battle(standalone := false, patch := Callable(), empty_profile := false) -> Node:
	if not standalone:
		var brief := BattleBrief.new()
		brief.seed = SEED
		brief.difficulty = difficulty
		link.brief = brief
		link.last_difficulty = difficulty
	var b = BATTLE.instantiate()
	b.profile_patch = patch
	if empty_profile:
		b.profile_def = ""
	root.add_child(b)
	current_scene = b
	return b

func map_scene() -> WorldMapScreen:
	if change_scene_to_file(WORLD) != OK:
		check("fixture.map_load", false)
		return null
	await frames()
	return current_scene as WorldMapScreen

# The actual sortie signal consumes the next global randi synchronously.
# Only headless lanes reset the RNG. Physical input observes the generated brief.
func seed_next_sortie() -> bool:
	for candidate in range(5000000):
		seed(candidate)
		if randi() % 1000000 == SEED:
			seed(candidate)
			return true
	return false

func sortie(s: WorldMapScreen, mode := "direct") -> bool:
	if not press(button(s, "적벽으로"), "card"):
		return false
	await create_timer(1.6).timeout
	if not press(s._diff_btns.get(difficulty), "difficulty") or not press(s._mode_btns.get(mode), "mode"):
		return false
	if not seed_next_sortie():
		check("fixture.seed", false)
		return false
	if not press(button(s, "출  격"), "sortie"):
		return false
	return press(s._skip, "skip")

func roster(b: Node) -> Dictionary:
	var sides := [[], []]
	for fleet in b.sim.st.fleets:
		sides[fleet.side].append({
			"id": fleet.sq_id, "faction_id": fleet.faction,
			"wait_ticks": fleet.wait, "start_morale_bp": fleet.start_morale_bp,
		})
	return {"ally": sides[0], "foe": sides[1]}

func expected_roster(config: Dictionary, excluded := "") -> Dictionary:
	var result := {"ally": [], "foe": []}
	for side in ["ally", "foe"]:
		for row in config[side]:
			if row.id == excluded:
				continue
			var record: Dictionary = row.duplicate()
			record.erase("wait_s")
			result[side].append(record)
	return result

func roster_facts(b: Node, exclude := "", variant := "") -> void:
	var actual := roster(b)
	var want := expected_roster(expected, exclude)
	var ids := func(rows: Array): return rows.map(func(row): return [row.id, row.faction_id])
	var morals := func(rows: Array): return rows.map(func(row): return row.start_morale_bp)
	var waits := func(rows: Array): return rows.map(func(row): return [row.id, row.wait_ticks])
	facts["roster" + variant] = actual
	check("roster.full" + variant, ids.call(actual.ally) == ids.call(want.ally) and ids.call(actual.foe) == ids.call(want.foe) and morals.call(actual.ally) == morals.call(want.ally) and morals.call(actual.foe) == morals.call(want.foe))
	check("roster.wait" + variant, waits.call(actual.ally) == waits.call(want.ally) and waits.call(actual.foe) == waits.call(want.foe))

func rules_match(b: Node) -> bool:
	facts["rules"] = {"difficulty": b.sim.rs.scenario.get("difficulty"), "ai": b.sim.rs.difficulty_ai()}
	return facts.rules.difficulty == difficulty and facts.rules.ai == expected.ai

func brief_screen(deck: Node) -> bool:
	if deck.screen == "prologue" and not press(deck.screens.prologue.skip, "prologue_skip"):
		return false
	return deck.screen == "brief"

func start_and_place(b: Node) -> bool:
	var deck: Node = b.presentation.hud
	if not brief_screen(deck):
		check("fixture.brief", false)
		return false
	var place := button(deck, "직접 배치")
	if place == null:
		check("fixture.place_mode", false)
		return false
	place.button_pressed = true
	if not press(button(deck, "자동 편성으로 시작"), "start"):
		return false
	await frames()
	var tick: int = b.sim.st.tick
	check("start.controls", b.placing and deck.place_bar.is_visible_in_tree() and tick == 0)
	if not press(button(deck.place_bar, "배치 확정"), "place"):
		return false
	await create_timer(0.45).timeout
	check("placement.tick", not b.placing and b.sim.st.tick > tick)
	return true

func force_result(b: Node) -> bool:
	facts["result_fixture"] = "synthetic annihilation"
	b.sim._end(true, "annihilation")
	b.end_game(true, "P02 difficulty fixture")
	await create_timer(2.2).timeout
	return b.presentation.hud.screen == "result"

func direct() -> void:
	var s := await map_scene()
	if s == null or not await sortie(s):
		return
	await frames(8)
	var b := current_scene
	if b == null or b.name != "FleetBattle3D" or b.sim == null:
		check("fixture.battle", false)
		return
	var deck: Node = b.presentation.hud
	if lane == "D03":
		check("fixture.clean_prologue", deck.screen == "prologue")
	check("route.seed", link.brief.seed == SEED and b.battle_seed == SEED)
	check("route.difficulty", link.brief.difficulty == difficulty and link.brief.mode == "direct")
	check("profile.host", b.difficulty == difficulty)
	check("profile.rules", rules_match(b))
	roster_facts(b)
	var foe_ids: Array = b.FOE_DEF.map(func(row): return row.squadron_id)
	check("roster.brief", foe_ids == expected.brief_foe_ids)
	if not await start_and_place(b):
		return
	if not await force_result(b):
		check("fixture.result", false)
		return
	if not press(deck.screens.result.title_btn, "result_return"):
		return
	await frames(8)
	var w := current_scene as WorldMapScreen
	var o: BattleOutcome = w.outcome if w != null else null
	check("result.seed", o != null and o.seed == SEED)
	check("result.difficulty", o != null and o.difficulty == difficulty)
	check("result.once", o != null and w.state == "result" and link.take_outcome() == null and not link.routed())

func organization() -> void:
	var b := install_battle()
	var deck: Node = b.presentation.hud
	if not brief_screen(deck) or not press(button(deck, "편  성"), "organization"):
		check("fixture.organization", false)
		return
	var org_screen: Node = deck.screens.org
	if lane == "D05":
		check("org.open.rules", org_screen.prof.get("difficulty") == difficulty)
		var target := -1
		for i in org_screen.org.fleets.size():
			if org_screen.org.fleets[i].get("squadron_id") == EXCLUDED:
				target = i
				break
		if target < 0 or org_screen.is_flag(target):
			check("fixture.excludable", false)
			return
		if not press(button(org_screen.cards[target], "출전"), "exclude_squadron"):
			return
		if not press(org_screen.confirm, "confirm_organization"):
			return
		check("org.apply.excluded", not roster(b).ally.any(func(row): return row.id == EXCLUDED))
		check("profile.rules", rules_match(b))
		roster_facts(b, EXCLUDED)
	else:
		var corrupt: Dictionary = org_screen.org.duplicate(true)
		corrupt.fleets[0].squadron_id = "P02-NO-SUCH-SQUADRON"
		var result: Dictionary = b.init_game(corrupt)
		check("fallback.org.errors", result.ok and not b.org_errors.is_empty())
		var prior: Variant = b.G.get("state")
		check("fallback.rules", rules_match(b))
		facts["fallback_roster"] = roster(b)
		check("fallback.roster", facts.fallback_roster == expected_roster(expected))
		deck.begin_battle()
		check("fallback.start.blocked", b.G.get("state") == prior and deck.screen == "org" and not b.placing)

func retry() -> void:
	var b := install_battle()
	var original = b.sim
	var brief: Dictionary = link.brief.to_dict()
	var same_rules := rules_match(b)
	var same_roster := roster(b) == expected_roster(expected)
	if not await start_and_place(b) or not await force_result(b):
		check("fixture.retry_result", false)
		return
	if not press(button(b.presentation.hud.screens.result, "다시 출격"), "retry"):
		return
	check("retry.same.brief", link.brief.to_dict() == brief)
	check("retry.new.sim", original != b.sim)
	check("retry.same.seed", b.battle_seed == SEED)
	check("retry.same.rules", rules_match(b) and same_rules)
	check("retry.same.roster", roster(b) == expected_roster(expected) and same_roster)

func failure() -> void:
	var b := install_battle(false, func(profile: Dictionary): profile.foe = "invalid")
	check("prepare.no.sim", b.sim == null and not b.G.has("state"))
	check("prepare.no.deck", b.presentation == null)
	var reason := b.find_child("Reason", true, false) as Label
	check("prepare.notice", reason != null and reason.text == "함대 편성 데이터가 올바르지 않습니다.")
	if not press(b.find_child("ExitBattlePrepareError", true, false) as Button, "error_exit"):
		return
	await frames(8)
	var w := current_scene as WorldMapScreen
	check("return.map", w != null)
	check("return.no.result", w != null and w.outcome == null and link.outcome == null and not link.routed())
	check("return.last.difficulty", link.last_difficulty == difficulty)

func trace_stamp(b: Node) -> Array:
	return [b.trace.path, b.trace.seq, FileAccess.get_sha256(b.trace.path)]

func atomic_failure() -> void:
	var b := install_battle()
	if not await start_and_place(b):
		return
	var sim = b.sim
	var fingerprint: String = sim.fingerprint()
	var host_seed: int = b.battle_seed
	var host_difficulty: String = b.difficulty
	var g: Dictionary = b.G.duplicate(true)
	var clocks := [b.clock, b._sim_acc_clock, b.clock.alpha(), b._sim_acc_clock.alpha(), b.clock.speed, b._sim_acc_clock.speed]
	var selection := [b.selected.duplicate(), b.multi, b.inspect, b.rig.cam_pos, b.rig.cam_z, b.presentation.hud.screen]
	var trace := trace_stamp(b)
	link.brief.difficulty = "극한"
	var route := [link.brief, link.brief.to_dict(), link.outcome, link.last_difficulty, link.last_mode]
	b.profile_patch = func(profile: Dictionary): profile.clear()
	var result: Dictionary = b.init_game()
	check("fail.same.sim", b.sim == sim and b.sim.fingerprint() == fingerprint)
	check("fail.same.seed", b.battle_seed == host_seed)
	check("fail.same.difficulty", b.difficulty == host_difficulty)
	check("fail.same.g", b.G == g)
	check("fail.same.clocks", clocks == [b.clock, b._sim_acc_clock, b.clock.alpha(), b._sim_acc_clock.alpha(), b.clock.speed, b._sim_acc_clock.speed])
	check("fail.same.selection", selection == [b.selected, b.multi, b.inspect, b.rig.cam_pos, b.rig.cam_z, b.presentation.hud.screen])
	check("fail.same.trace", trace == trace_stamp(b))
	check("fail.same.link", route == [link.brief, link.brief.to_dict(), link.outcome, link.last_difficulty, link.last_mode])
	var reason := b.find_child("Reason", true, false) as Label
	check("fail.notice", not result.ok and reason != null and reason.text == "전투 프로필이 비어 있습니다.")
	b.profile_patch = Callable()
	check("retry.valid", b.init_game().ok and b.sim != sim and b._prepare_error_layer == null)

func standalone() -> void:
	seed(SEED)
	var b := install_battle(true, Callable(), lane == "D12")
	if lane == "D12":
		check("poc.rs.empty", b.sim.rs.difficulty_ai().is_empty())
		check("poc.no.scenario", b.sim.rs.scenario.is_empty())
		check("poc.legacy.difficulty", b.difficulty == "표준")
		check("poc.no.link", not link.routed())
		return
	var deck: Node = b.presentation.hud
	check("legacy.title", deck.screen == "title")
	check("legacy.default.rules", rules_match(b))
	check("legacy.roster", roster(b) == expected_roster(expected))
	if not press(button(deck.screens.title, "출격 준비"), "title_start") or not await start_and_place(b) or not await force_result(b):
		check("fixture.standalone_start", false)
		return
	var old = b.sim
	seed(SEED)
	var wanted_seed := randi()
	seed(SEED)
	if not press(button(deck.screens.result, "다시 출격"), "legacy_restart"):
		return
	check("legacy.restart", b.sim != old and b.battle_seed == wanted_seed and rules_match(b) and roster(b) == expected_roster(expected))

func auto_resolve() -> void:
	var w := await map_scene()
	if w == null or not await sortie(w, "auto"):
		return
	var worker: AutoResolver = w.resolver
	check("auto.validate", w.brief.validate().is_empty() and w.brief.mode == "auto")
	check("auto.worker.started", w.state == "resolve" and worker != null and worker._thread != null)
	if worker == null:
		return
	while w.state == "resolve":
		await process_frame
	check("auto.completed", w.state == "result" and w.outcome != null)
	check("auto.joined", worker._thread == null)
	check("auto.outcome.seed", w.outcome != null and w.outcome.seed == SEED)
	check("auto.outcome.difficulty", w.outcome != null and w.outcome.difficulty == difficulty)

func invalid() -> void:
	var brief := BattleBrief.new()
	brief.seed = SEED
	brief.difficulty = "P02-INVALID"
	check("fixture.invalid_auto_contract", not AutoResolver.new(brief).start())
	if link.go_battle(brief) != OK:
		check("fixture.invalid_dispatch", false)
		return
	await frames(8)
	var b := current_scene
	var no_sim: bool = b != null and b.name == "FleetBattle3D" and b.sim == null
	check("invalid.no.sim", no_sim and not b.G.has("state") and b.battle_seed == 0 and b.difficulty == "표준")
	var reason := b.find_child("Reason", true, false) as Label if b != null else null
	check("invalid.notice", reason != null and reason.text == "난이도가 올바르지 않습니다.")
	var exit := b.find_child("ExitBattlePrepareError", true, false) as Button if b != null else null
	if exit != null and press(exit, "invalid_exit"):
		await frames(8)
	var w := current_scene as WorldMapScreen
	check("invalid.return.no.result", w != null and w.outcome == null and link.outcome == null and not link.routed())

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		check("fixture.arguments", false)
		finish()
		return
	lane = args[0]
	phase = args[1]
	link = root.get_node("WorldLink")
	var actual_project := ProjectSettings.globalize_path("res://").replace("\\", "/").trim_suffix("/")
	var actual_user := OS.get_user_data_dir().replace("\\", "/")
	if actual_project != OS.get_environment("P02_PC_EXPECT_PROJECT") or actual_user != OS.get_environment("P02_PC_EXPECT_USER"):
		check("fixture.scope", false)
		finish()
		return
	difficulty = {"D01": "입문", "D02": "표준", "D04": "극한", "D09": "표준", "D12": "표준"}.get(lane, "상급")
	var oracle = JSON.parse_string(FileAccess.get_file_as_string("res://tests/p02_difficulty_oracle.json"))
	if not oracle is Dictionary or not oracle.get("difficulty", {}).has(difficulty):
		check("fixture.oracle", false)
		finish()
		return
	expected = oracle.difficulty[difficulty]
	if phase == "after-physical":
		await physical()
	elif lane in ["D01", "D02", "D03", "D04"]:
		await direct()
	elif lane in ["D05", "D11"]:
		organization()
	elif lane == "D06":
		await retry()
	elif lane == "D07":
		await failure()
	elif lane == "D08":
		await atomic_failure()
	elif lane in ["D09", "D12"]:
		await standalone()
	elif lane == "D10":
		await auto_resolve()
	elif lane == "D13":
		await invalid()
	else:
		check("fixture.lane", false)
	finish()

var physical_target := Rect2()
var physical_events: Array[Dictionary] = []

func observe_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		physical_events.append({"down": event.pressed, "at_us": Time.get_ticks_usec(),
			"x": event.position.x, "y": event.position.y,
			"inside": physical_target.has_point(event.position), "focused": root.has_focus()})

func request_click(target: Button, step: String) -> bool:
	if target == null or not target.is_visible_in_tree() or target.disabled:
		check("physical.target." + step, false)
		return false
	await RenderingServer.frame_post_draw
	var viewport_image := root.get_texture().get_image()
	var dir := OS.get_environment("P02_PHYSICAL_DIR")
	var saved := viewport_image != null and viewport_image.save_png(dir + "/" + step + ".viewport.png") == OK
	var transform := target.get_global_transform_with_canvas()
	physical_target = Rect2(transform * Vector2.ZERO, target.size * transform.get_scale())
	physical_events.clear()
	var request := {"step": step, "pid": OS.get_process_id(), "viewport_w": root.get_visible_rect().size.x,
		"viewport_h": root.get_visible_rect().size.y, "x": physical_target.get_center().x,
		"y": physical_target.get_center().y, "w": physical_target.size.x,
		"h": physical_target.size.y, "focus": root.has_focus(), "saved": saved}
	var file := FileAccess.open(dir + "/" + step + ".request.tmp", FileAccess.WRITE)
	if not saved or file == null:
		check("physical.target." + step, false)
		return false
	file.store_string(JSON.stringify(request))
	file.close()
	if DirAccess.rename_absolute(dir + "/" + step + ".request.tmp", dir + "/" + step + ".request.json") != OK:
		check("physical.target." + step, false)
		return false
	var deadline := Time.get_ticks_msec() + 18000
	while physical_events.size() < 2 and Time.get_ticks_msec() < deadline:
		await process_frame
	var ok := physical_events.size() == 2 and physical_events[0].down and not physical_events[1].down
	ok = ok and physical_events.all(func(ev): return ev.inside and ev.focused)
	facts["physical." + step] = {"request": request, "events": physical_events.duplicate(true)}
	check("physical.input." + step, ok)
	await frames()
	return ok

func physical() -> void:
	root.window_input.connect(observe_input)
	var w := await map_scene()
	if w == null:
		check("physical.map", false)
		return
	if not await request_click(button(w, "적벽으로"), "01-card"):
		return
	await create_timer(1.6).timeout
	if not await request_click(w._diff_btns.get(difficulty), "02-difficulty"):
		return
	if not await request_click(w._mode_btns.get("direct"), "03-mode"):
		return
	if not await request_click(button(w, "출  격"), "04-sortie"):
		return
	if not await request_click(w._skip, "05-sortie-skip"):
		return
	await frames(8)
	var b := current_scene
	if b == null or b.name != "FleetBattle3D" or b.sim == null:
		check("physical.battle", false)
		return
	var deck: Node = b.presentation.hud
	check("route.seed", link.brief != null and b.battle_seed == link.brief.seed)
	facts["physical.seed"] = b.battle_seed
	check("route.difficulty", link.brief.difficulty == difficulty and link.brief.mode == "direct")
	check("profile.host", b.difficulty == difficulty)
	check("profile.rules", rules_match(b))
	roster_facts(b)
	if not await request_click(deck.screens.prologue.skip, "06-prologue-skip"):
		return
	if not await request_click(button(deck, "직접 배치"), "07-place-mode"):
		return
	if not await request_click(button(deck, "자동 편성으로 시작"), "08-start"):
		return
	check("start.controls", b.placing and b.sim.st.tick == 0)
	if not await request_click(button(deck.place_bar, "배치 확정"), "09-place-confirm"):
		return
	await create_timer(0.45).timeout
	check("placement.tick", not b.placing and b.sim.st.tick > 0)
	await RenderingServer.frame_post_draw
	check("physical.final_viewport", root.get_texture().get_image().save_png(OS.get_environment("P02_PHYSICAL_DIR") + "/10-playing.viewport.png") == OK)
