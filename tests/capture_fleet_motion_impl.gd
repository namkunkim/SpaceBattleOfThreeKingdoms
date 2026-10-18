extends SceneTree

# 함대 기동 PoC 반영 화면 확인(PC). godot --path . --resolution 1600x900 --script tests/capture_fleet_motion_impl.gd -- [출력 폴더]
# 아군 함대에 도착 방향을 준 이동 명령을 내리고 명령 직후 / 이동 중 / 도착 뒤를 캡처한다.

func _initialize() -> void:
	call_deferred("_run")

func _shot(dir: String, name: String) -> void:
	for i in 3:
		await process_frame
	var path := "%s/%s.png" % [dir, name]
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_viewport().get_texture().get_image().save_png(path)
	print("SHOT ", path)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := ProjectSettings.globalize_path(args[0] if args.size() > 0 else "res://out/fleet-motion-impl")
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	deck.guard.enabled = false
	deck.begin_battle()
	for i in 520:
		battle.update_sim(0.05)
	var f = battle.fleets[1]
	battle.selected.clear()
	battle.selected.append(f)
	var dest: Vector2 = f.pos + Vector2(900.0, 500.0)
	battle.issue(BattleCommands.make("move", [f.id], -1, dest, {"facing_deg": 90.0}))
	for i in 4:
		battle.update_sim(0.05)
	await _shot(dir, "1-ordered")
	for i in 60:
		battle.update_sim(0.1)
		await process_frame
	await _shot(dir, "2-moving")
	for i in 400:
		battle.update_sim(0.1)
		if not f.has_move:
			break
	for i in 90:
		battle.update_sim(0.1)
		await process_frame
	await _shot(dir, "3-arrived")
	print("MOTION_CAPTURE_DONE has_move=", f.has_move, " stretch=", battle.presentation.renderer.vis[f.id].stretch)
	quit(0)
