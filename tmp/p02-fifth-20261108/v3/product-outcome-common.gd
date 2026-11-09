extends SceneTree

const FIXTURE := preload("res://tmp/p02-fifth-20261108/v3/fixture.gd")
const ADAPTER := preload("res://core/battle/operation_runtime_adapter.gd")
var checks := 0
var failures := 0
var rows := {}
var profile_evidence := {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FIFTH_FAIL ", label)
	return ok

func frames(n: int) -> void:
	for i in n:
		await process_frame

func screen() -> WorldMapScreen:
	var world := (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate() as WorldMapScreen
	root.add_child(world)
	current_scene = world
	return world

func sortie(world: WorldMapScreen, mode: String, difficulty: String, seed: int) -> void:
	world._set_mode(mode)
	world._set_difficulty(difficulty)
	world.sortie(seed)
	check(world.state == "sortie" and world._skip.visible, mode + " sortie")
	world._skip.emit_signal("pressed")

func outcome(o: BattleOutcome) -> Dictionary:
	return {"dict": o.to_dict(), "ending_text": o.ending_text(), "line_text": o.line_text()}

func card(world: WorldMapScreen, label: String) -> Dictionary:
	await create_timer(0.8).timeout
	var o := world.outcome
	var labels := {}
	for key in ["eyebrow", "title", "ending", "time", "loss_a", "loss_f", "cao", "line", "src", "seed", "regions"]:
		labels[key] = world._res_labels[key].text
	check(world.state == "result" and world._result.visible and not world._resolve.visible and world.resolver == null, label + " result state")
	check(labels.ending == o.ending_text() and labels.line == o.line_text()[0] and labels.src == o.line_text()[1], label + " narrative")
	var expected: Dictionary = world.world.outcome_owners[o.kind]
	check(world.canvas.owners_rgn == expected, label + " region owners")
	return {"outcome": outcome(o), "labels": labels, "owners": world.canvas.owners_rgn.duplicate()}

func product() -> void:
	var world := screen()
	await frames(2)
	sortie(world, "auto", "입문", 11)
	var resolver := world.resolver
	if check(world.state == "resolve" and resolver != null and world._resolve.visible, "A01 resolver started"):
		var deadline := Time.get_ticks_msec() + 120000
		while world.state == "resolve" and Time.get_ticks_msec() < deadline:
			await process_frame
		if check(world.outcome != null and resolver._thread == null, "A01 natural join"):
			rows.A01 = await card(world, "A01")
		var blocking := AutoResolver.new(BattleBrief.from_dict(world.brief.to_dict())).run_blocking()
		if check(blocking != null and world.outcome != null and blocking.to_dict() == world.outcome.to_dict(), "A02 blocking equality"):
			rows.A02 = outcome(blocking)
	world.queue_free()
	await frames(3)

	world = screen()
	await frames(2)
	sortie(world, "direct", "표준", 777)
	await frames(8)
	await direct_product()

	if is_instance_valid(current_scene):
		current_scene.queue_free()
	await frames(3)

	world = screen()
	await frames(2)
	sortie(world, "auto", "입문", 11)
	resolver = world.resolver
	var stop := world._resolve.get_child(0).get_child(1) as Button
	if check(resolver != null and stop != null and stop.text == "중단하고 돌아가기" and stop.is_visible_in_tree(), "A04 native cancel button"):
		stop.emit_signal("pressed")
		rows.A04 = {"state": world.state, "joined": resolver._thread == null, "poll": resolver.poll(), "hidden": not world._result.visible and not world._resolve.visible, "unpublished": world.outcome == null and resolver.outcome == null}
		check(rows.A04 == {"state": "browse", "joined": true, "poll": false, "hidden": true, "unpublished": true}, "A04 cancel result")
	world.queue_free()
	await frames(3)
	world = screen()
	await frames(2)
	sortie(world, "auto", "입문", 11)
	resolver = world.resolver
	if check(resolver != null and resolver._thread != null and world.outcome == null, "A05 active unposted resolver"):
		world.queue_free()
		await frames(3)
		rows.A05 = {"removed": not is_instance_valid(world), "joined": resolver._thread == null, "poll": resolver.poll(), "unpublished": resolver.outcome == null}
		check(rows.A05 == {"removed": true, "joined": true, "poll": false, "unpublished": true}, "A05 exit join")

func button_named(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := button_named(child, label)
		if found != null:
			return found
	return null

func direct_product() -> void:
	var battle := current_scene
	var link := root.get_node("WorldLink")
	if not check(battle != null and battle.name == "FleetBattle3D" and link.routed() and link.brief.seed == 777, "A03 direct routed"):
		return
	var deck = battle.presentation.hud
	if not check(deck.screen == "prologue" and not GameSettings.prologue_seen and not FileAccess.file_exists(GameSettings.PATH), "A03 first-run native prologue"):
		return
	var skip := deck.screens.prologue.skip as Button
	if not check(skip != null and skip.is_visible_in_tree() and not skip.disabled, "A03 native prologue skip"):
		return
	skip.emit_signal("pressed")
	if not check(deck.screen == "brief" and GameSettings.prologue_seen and FileAccess.file_exists(GameSettings.PATH), "A03 native briefing and saved progress"):
		return
	var saved := ConfigFile.new()
	if not check(saved.load(GameSettings.PATH) == OK and saved.get_value("progress", "prologue_seen", false) == true, "A03 persisted progress value"):
		return
	var start := button_named(deck.screens.brief, "자동 편성으로 시작")
	if not check(start != null and start.is_visible_in_tree() and not start.disabled, "A03 native auto-organization start button"):
		return
	start.emit_signal("pressed")
	battle.set_process(false)
	if not check(battle.G.state == "play" and battle.sim.st.tick == 0, "A03 native start"):
		return
	for i in FIXTURE.DIRECT_TICK:
		battle.sim.step()
	var tick: int = battle.sim.st.tick
	if not check(tick == FIXTURE.DIRECT_TICK and not battle.sim.st.over, "A03 fixed terminal injection tick"):
		return
	battle.sim._end(true, "annihilation")
	battle.end_game(true, "테스트")
	battle.set_process(true)
	await create_timer(2.2).timeout
	var btn: Button = deck.screens.result.title_btn
	if not check(deck.screen == "result" and btn.text == "천하로" and btn.is_visible_in_tree() and not btn.disabled, "A03 native result button"):
		return
	btn.emit_signal("pressed")
	await frames(8)
	var returned := current_scene as WorldMapScreen
	if not check(returned != null and returned.outcome != null and returned.outcome.seed == 777, "A03 WorldMap consumed result"):
		return
	rows.A03 = await card(returned, "A03")
	rows.A03.tick = tick
	rows.A03.transitions = ["WorldMap sortie/skip", "FleetBattle3D prologue/skip", "brief auto-organization/start", "native result button", "WorldMap result"]
	rows.A03.consumed = link.brief == null and link.outcome == null and link.take_outcome() == null
	check(rows.A03.consumed, "A03 single consume")

func data() -> void:
	var brief := BattleBrief.new()
	brief.difficulty = "입문"
	var profile := brief.profile()
	var adapter_script: Script = ADAPTER
	check(adapter_script.resource_path == "res://core/battle/operation_runtime_adapter.gd", "A06 canonical adapter path")
	check(not profile.is_empty() and profile.reinf.is_empty() and not profile.scenario.is_empty(), "A06 original product profile")
	profile_evidence = {"profile": BattleBrief.PROFILE_DEF, "profile_source_sha": FileAccess.get_sha256(BattleBrief.PROFILE_DEF),
		"runtime_profile_sha": var_to_bytes(profile).hex_encode().sha256_text(), "adapter": adapter_script.resource_path}
	rows.A06 = ADAPTER.create({"mode": "operation", "format": ADAPTER.FORMAT, "profile": profile, "seed": 11, "hz": 10, "initial_controls": [], "policy": "none", "max_ticks": 18000})
	check(rows.A06 == FIXTURE.REJECTION, "A06 product profile rejected: " + str(rows.A06))
	var sim := BattleSim.new(11)
	sim._end(true, "annihilation")
	var o := BattleOutcome.from_sim(sim, null)
	rows.A07 = outcome(o)
	check(sim.st.over and sim.st.result.is_empty() and o.seed == 0 and o.mode == "" and o.difficulty == "" and o.grade == "승리" and o.line == "E1" and o.loss_pct == {"alliance": 0, "foe": 0}, "A07 POC null defaults")
	sim = BattleSim.new(11)
	o = BattleOutcome.from_sim(sim, brief)
	rows.A08 = outcome(o)
	check(not sim.st.over and not o.win and o.grade == "패배" and o.reason == "" and o.ending == "J-D7" and o.line == "E11", "A08 unfinished fallback semantics")
	for row in FIXTURE.OUTCOMES:
		sim.st.win = row[1]
		sim.st.end_reason = row[2]
		var candidates: Array = row[8]
		var values := []
		for seed in candidates.size():
			brief.seed = seed
			sim.st.result = FIXTURE.settlement(row[3], row[4], row[5])
			o = BattleOutcome.from_sim(sim, brief)
			check(o.grade == row[6] and o.ending == row[7] and o.line == candidates[seed], row[0] + " grade, ending, candidate %d" % seed)
			check(o.loss_pct == {"alliance": 30, "foe": 75} and o.cao_status == row[4][0] and o.liu_status == row[4][1] and o.limited == row[5], row[0] + " cost, commanders, limited")
			values.append(outcome(o))
		rows[row[0]] = values

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var guard := {"project": ProjectSettings.globalize_path("res://"), "user": OS.get_user_data_dir(),
		"classes": [BattleOutcome.new().get_script().resource_path, AutoResolver.new(BattleBrief.new()).get_script().resource_path],
		"version": Engine.get_version_info().string, "settings_at_start": FileAccess.file_exists(GameSettings.PATH)}
	check(guard.classes == ["res://scripts/world/battle_outcome.gd", "res://scripts/world/auto_resolver.gd"], "canonical class paths")
	check(not guard.settings_at_start, "canonical clean-user profile")
	await product()
	data()
	check(rows.size() == 18, "common row denominator")
	var output := FileAccess.open(args[0], FileAccess.WRITE)
	output.store_string(JSON.stringify({"rows": rows, "checks": checks, "failures": failures, "guard": guard, "profile": profile_evidence}, "", true, true))
	output.close()
	print("FIFTH_COMMON rows=%d checks=%d failures=%d" % [rows.size(), checks, failures])
	quit(int(failures != 0))
