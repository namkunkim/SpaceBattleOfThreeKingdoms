extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	battle.pc_preset = "terrain"
	root.add_child(battle)
	await process_frame
	if not TestCheck.ok(self, battle.sim.rs.world == Vector2(6800, 4600), "PC live world = benchmark world"): return
	if not TestCheck.ok(self, battle.move_mul == 30.0 and battle.turn_mul == 15.0, "PC live tuning"): return
	if not TestCheck.ok(self, battle.sim.terrain.zones.size() == 10, "PC live terrain has ten zones"): return
	if not TestCheck.ok(self, battle.presentation.hud.overlay.terrain_zones().size() == 10, "PC terrain visible in overlay"): return
	if not TestCheck.ok(self, not battle.presentation.hud.pacing.auto_enabled(), "PC automatic fast-forward disabled for session"): return
	var first_speed: float = battle.sim.st.fleets[0].speed
	battle.init_game()
	if not TestCheck.ok(self, is_equal_approx(battle.sim.st.fleets[0].speed, first_speed), "restart does not multiply movement twice"): return
	if not TestCheck.ok(self, battle.sim.terrain.zones.size() == 10, "restart retains terrain preset"): return
	battle.pc_preset = ""
	battle.move_mul = 150.0
	battle.init_game()
	if not TestCheck.ok(self, battle.sim.rs.world == Vector2(1700, 1150) and battle.sim.terrain.zones.size() == 3, "default game unchanged when preset removed"): return
	battle.queue_free()
	await process_frame
	print("PC_BATTLE_SMOKE_PASS")
	quit(0)
