extends "res://tmp/p02-sixth-20261108/product-host-common-v2.gd"

func snapshot(b: Node) -> Dictionary:
	var deck: Node = b.presentation.hud
	var o: Node = deck.screens.org
	var snap := {}
	for pair in [[b, ["org", "org_errors", "load_error", "battle_seed", "ALLY_DEF", "FOE_DEF", "G", "groups", "selected", "inspect", "marker", "drag", "placing", "multi", "cam_pos", "cam_z", "now_t"]],
		[deck, ["screen", "cut_data", "cut_cool", "cut_tween", "info_open"]],
		[o, ["scn", "prof", "skill_defs", "org", "officers", "names", "sel", "picked", "errors", "notice", "cards", "ship_ui", "skill_pick"]]]:
		for key in pair[1]:
			var value: Variant = pair[0].get(key)
			snap[str(pair[0].name) + "/" + key] = value.duplicate(true) if value is Dictionary or value is Array else value
	snap.sim = b.sim
	snap.fingerprint = b.sim.fingerprint()
	snap.tick = b.sim.st.tick
	snap.clock = b.clock
	snap.acc_clock = b._sim_acc_clock
	snap.clock_alpha = b.clock.alpha()
	snap.acc_alpha = b._sim_acc_clock.alpha()
	snap.vm = b.vm
	snap.fleets = b.fleets.duplicate()
	snap.fx = b.fx
	snap.floats = b.floats.duplicate(true)
	snap.search = o.search.text
	snap.notice_text = o.msg.text
	snap.log = deck.log_box.get_children()
	snap.trace_file = b.trace.file
	snap.trace_path = b.trace.path
	snap.trace_seq = b.trace.seq
	snap.trace_bytes = FileAccess.get_file_as_bytes(b.trace.path)
	snap.trace_files = DirAccess.get_files_at("user://battle_traces")
	snap.rig_margin = b.rig.margin
	snap.slow_mode = GameSettings.slow_mode
	return snap

func clear_profile(p: Dictionary) -> void:
	p.clear()

func wrong_roster(p: Dictionary) -> void:
	p.ally = "wrong roster type"

func assert_queue(b: Node, expected: BattleSim) -> void:
	var before: Array = b.sim._events.duplicate(true)
	check(before == expected._events and before.size() >= 2, "same pending queue")
	var projected: Array[Dictionary] = b.sim.drain_events_for(0)
	check(projected == expected.drain_events_for(0), "same filtered queue")
	check(projected.any(func(e): return e.kind == "charge"), "visible fixture")
	check(not projected.any(func(e): return e.kind == "morale_crisis"), "hidden fixture")
	check(b.sim.drain_events().is_empty(), "no duplicate drain")

func trace_rows(path: String) -> Array:
	var out := []
	for line in FileAccess.get_file_as_string(path).split("\n", false):
		out.append(JSON.parse_string(line))
	return out

func _run() -> void:
	check(not FileAccess.file_exists(GameSettings.PATH), "clean user")
	GameSettings.prologue_seen = true
	var b := native_setup()
	var deck: Node = b.presentation.hud
	var o: Node = deck.screens.org
	deck.show_screen("brief")
	for label in ["reject_clear_profile", "reject_wrong_roster_type", "deck_begin_changed_org_reject",
		"deck_begin_nonbrief_reject", "deck_restart_reject", "deck_unrouted_title_reject", "org_repair_reject",
		"org_auto_reject", "host_ready_restart_guards"]:
		var n := checks
		var fails := failed
		var queued: bool = label in ["reject_clear_profile", "reject_wrong_roster_type", "deck_begin_changed_org_reject"]
		var result: Variant = null
		var expected: BattleSim
		if label == "reject_wrong_roster_type":
			deck.begin_battle()
		if queued:
			expected = native(b)
			commands(expected)
			commands(b.sim)
			event_fixture(expected)
			event_fixture(b.sim)
		if label == "org_repair_reject":
			o.open_org()
			b.org = o.org.duplicate(true)
			b.org.fleets[0].admiral = "invalid_admiral"
			b.init_game()
			check(not b.org_errors.is_empty(), "repair precondition")
			o.search.text = "preserve"
		if label in ["org_repair_reject", "org_auto_reject"]:
			o.scn["probe_old_cache"] = true
			o.prof["probe_old_cache"] = true
			o.skill_defs["probe_old_cache"] = true
		if label == "org_auto_reject":
			b.org = {}
			b.init_game()
			deck.show_screen("brief")
		b.profile_patch = wrong_roster if label == "reject_wrong_roster_type" else clear_profile
		var old := snapshot(b)
		match label:
			"reject_clear_profile", "reject_wrong_roster_type":
				result = b.init_game()
			"deck_begin_changed_org_reject":
				var proposed: Dictionary = o.start_org(ScenarioProfile.load_profile(b.profile_def, b.difficulty), ProfileLoader.read_json(BattleBrief.SCENARIO))
				result = deck.begin_battle(proposed)
			"deck_begin_nonbrief_reject":
				check(b.G.state != "brief", "nonbrief precondition")
				result = deck.begin_battle()
			"deck_restart_reject":
				deck.restart()
			"deck_unrouted_title_reject":
				check(not b.routed(), "unrouted precondition")
				deck.to_title()
			"org_repair_reject":
				o.open_org()
			"org_auto_reject":
				var btn := button_named(deck.screens.brief, "자동 편성으로 시작")
				check(btn != null and btn.is_visible_in_tree(), "actual auto button")
				btn.emit_signal("pressed")
			"host_ready_restart_guards":
				b._restart()
				var empty := HOST.instantiate()
				empty.profile_patch = clear_profile
				root.add_child(empty)
				check(empty.sim == null and empty.presentation == null and not empty.is_processing(), "initial guard")
				empty.free()
		if label in ["reject_clear_profile", "reject_wrong_roster_type", "deck_begin_changed_org_reject", "deck_begin_nonbrief_reject"]:
			var path := "profile.ally" if label == "reject_wrong_roster_type" else "profile"
			check(result == {"ok": false, "error": "invalid_candidate_profile", "path": path}, label + " result")
		var now := snapshot(b)
		for key in old:
			check(old[key] == now[key], label + " preserves " + key)
		if queued:
			assert_queue(b, expected)
		row(label, {"result": result}, n, fails)
		b.profile_patch = Callable()
		if label == "reject_clear_profile":
			b.init_game()
		if label == "reject_wrong_roster_type":
			b.init_game()
			deck.begin_battle()
	var n := checks
	var fails := failed
	event_fixture(b.sim)
	var link := root.get_node("WorldLink")
	var brief := BattleBrief.new()
	brief.seed = SEED
	link.brief = brief
	var old := snapshot(b)
	var previous := trace_rows(old.trace_path)
	var publish: Dictionary = b.init_game()
	var next := snapshot(b)
	var closed := trace_rows(old.trace_path)
	var opened := trace_rows(next.trace_path)
	check(publish == {"ok": true}, "publish accepted")
	check(closed.size() == previous.size() + 1 and closed[-1].kind == "session_closed", "one close")
	check(FileAccess.get_file_as_bytes(old.trace_path).slice(0, old.trace_bytes.size()) == old.trace_bytes, "old trace prefix")
	check(next.trace_files.size() == old.trace_files.size() + 1 and old.trace_path != next.trace_path, "one new file")
	check(opened.size() == 1 and opened[0].kind == "session_start" and opened[0].seq == 1, "one new start")
	check(next.clock != old.clock and next.acc_clock != old.acc_clock and b.sim.st.tick == 0, "new clocks")
	check(next.fleets.all(func(f): return not old.fleets.has(f)), "fresh views")
	var oracle := native(b)
	check(roster(b.sim) == roster(oracle) and b.sim.drain_events().is_empty(), "fresh native roster and queue")
	check(b.cam_z == 0.9 and b.G.state == "brief" and b.selected.is_empty(), "fresh camera UI")
	check(opened[0].data.seed == b.battle_seed and opened[0].data.hz == oracle.st.hz and opened[0].data.fleet_state.size() == b.trace.fleets(oracle).size(), "trace native start fields")
	row("recover_publish_once", {"start": opened[0], "close": closed[-1], "start_file": next.trace_path,
		"close_file": old.trace_path}, n, fails)
	link.brief = null
	b.free()
	print("SIXTH_ATOMIC rows=", rows.size(), " checks=", checks, " fails=", failed)
	var f := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "\t"))
	f.close()
	quit(1 if failed or rows.size() != 10 else 0)
