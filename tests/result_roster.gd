extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	battle.set_process(false)
	var sim: BattleSim = battle.sim
	if not TestCheck.ok(self, sim.projection(0).outcome.roster.is_empty() and sim.projection(1).outcome.roster.is_empty(), "no result information during battle"): return
	var enemies: Array = sim.st.fleets.filter(func(f): return f.side == 1)
	var contact := BattleProjection.contact(sim, {"id":enemies[0].id,"state":"confirmed","pos":enemies[0].pos,"err_r":0,"conf_bp":10000})
	if not TestCheck.ok(self, not contact.has("ships") and not contact.has("ships_milli"), "tactical contact keeps exact counts private"): return
	var fresh: Array[BattleViewModel.FleetView] = []
	battle.vm._apply_contact(contact, false, fresh)
	if not TestCheck.ok(self, battle.vm.fleet(enemies[0].id).ships == BattleViewModel.CONTACT_SHIPS, "reproduce contact placeholder"): return
	# 68척으로 출발한 전대에서 7척 격침: 최초 편성이 아닌 실제 잔존 61척이어야 한다.
	enemies[0].stages["SHP-04"][0] -= 7
	enemies[0].stages["SHP-04"][4] += 7
	enemies[0].ships -= 7 * BattleRules.MILLI
	# 격침·항복·탈출을 구분하고 미탐지 증원을 포함한 모든 함대를 결산한다.
	sim.remove_fleet(enemies[1], "surrender")
	sim.remove_fleet(enemies[2], "escaped")
	sim._kill(enemies[3], null)
	sim.debug_end(false, "flagship_lost")
	battle._pump()
	var rows: Array = battle.vm.result_fleets
	if not TestCheck.ok(self, rows.size() == sim.st.fleets.size(), "result includes all deployed fleets including unseen enemies"): return
	for f in sim.st.fleets:
		var row: Dictionary = rows.filter(func(r): return r.id == f.id)[0]
		var expected := 0 if f.out == "sunk" else sim.salvo.present_ships(f)
		if not TestCheck.ok(self, row.ships == expected and row.max_ships == sim.salvo.total0(f) and row.out == f.out, "actual counts and status " + f.name): return
	var first: Dictionary = rows.filter(func(r): return r.id == enemies[0].id)[0]
	var screen = battle.presentation.hud.screens.result
	if not TestCheck.ok(self, first.ships == 61 and screen.fleet_count_text(first) == "61척", "result replaces placeholder and initial count with real 61 survivors"): return
	for pair in [[enemies[1].id,"항복"],[enemies[2].id,"탈출"],[enemies[3].id,"격침"]]:
		var row: Dictionary = rows.filter(func(r): return r.id == pair[0])[0]
		if not TestCheck.ok(self, screen.fleet_count_text(row).ends_with(pair[1]), "result status " + pair[1]): return
	# 결산 배열을 고쳐도 코어 상태는 변하지 않는다.
	var core_ships: int = enemies[0].ships
	first.ships = 999
	if not TestCheck.ok(self, enemies[0].ships == core_ships, "result snapshot detached from core"): return
	battle._pump()
	battle.G.state = "end"
	battle.presentation.hud.show_screen("result")
	for i in 5:
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://out/result-roster-20261025.png")
	battle.vm.reset()
	if not TestCheck.ok(self, battle.vm.result_fleets.is_empty() and battle.vm.outcome.is_empty(), "restart clears result snapshot"): return
	battle.queue_free()
	await process_frame
	print("RESULT_ROSTER_PASS")
	quit()
