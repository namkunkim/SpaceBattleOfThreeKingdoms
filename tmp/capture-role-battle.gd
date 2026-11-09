extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _shot(path: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 8:
		await process_frame
	var deck = battle.presentation.hud
	deck.guard.enabled = false
	deck.begin_battle()
	if battle.placing:
		battle.place_confirm()
	deck.cut.visible = false
	var best = battle.vm.alive(0)[0]
	var variety := -1
	for f in battle.vm.alive(0):
		if f.counts.size() > variety:
			variety = f.counts.size()
			best = f
	battle.selected.assign([best])
	battle.refresh_panel()
	deck._set_tab(1)
	battle.cam_pos = best.pos + Vector2(100, 0)
	battle.cam_z = 1.1
	await _shot("C:/WorkSpace/SpaceBattleOfThreeKingdoms/out/formation-battle-overview.png")
	battle.cam_pos = best.pos + Vector2(65, 0)
	battle.cam_z = 2.8
	await _shot("C:/WorkSpace/SpaceBattleOfThreeKingdoms/out/formation-battle-close.png")
	print("BATTLE_CAPTURE_PASS ", best.fname, " ", best.counts)
	quit()
