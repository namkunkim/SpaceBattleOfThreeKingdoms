extends SceneTree

# 진형 전환 뒤 FxLayer.ship_pos가 현재 진형 배치를 따르는가(P1 F-2). 헤드리스.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var ally = battle.vm.alive(0)[0]
	var core: FleetState = battle.sim.st.by_id(ally.id)
	var before: int = ally.shape
	var fx := FxLayer.new()
	var ids: Array = battle.sim.salvo.formation_ids()
	var target := ""
	for fid in ids:
		if fid != core.formation_id and fid != "FRM-07" and BattleRules.FORM_SHAPE[ids.find(fid)] != before:
			target = fid
			break
	battle.sim.issue(BattleSim.command(0, [ally.id], "formation", -1, Vector2.ZERO, {"id": target}))
	for i in 700:
		battle.update_sim(0.1)
		if ally.formation_id == target:
			break
	if not TestCheck.ok(self, ally.shape != before, "진형 전환됨"): return
	var want: Vector2 = ally.pos + core.form[5 % core.form.size()].rotated(ally.heading)
	if not TestCheck.ok(self, fx.ship_pos(ally, 5).is_equal_approx(want), "효과 위치가 현재 배치"): return
	print("FX_FOLLOW_FORMATION_PASS")
	quit(0)
