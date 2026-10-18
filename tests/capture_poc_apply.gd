extends SceneTree

# 함대 기동 PoC 본 게임 적용 화면 확인(PC). godot --path . --resolution 1600x900 --script tests/capture_poc_apply.gd -- [출력 폴더]
# 0 초기 화면(메뉴·함선·편성) / 1~2 제자리 반전(뒤쪽 이동 직후·반전 중) / 3~4 묶음 진형(직후·도착 뒤)

func _initialize() -> void:
	call_deferred("_run")

func _shot(dir: String, name: String) -> void:
	for i in 3:
		await process_frame
	DirAccess.make_dir_recursive_absolute(dir)
	root.get_viewport().get_texture().get_image().save_png("%s/%s.png" % [dir, name])
	print("SHOT ", name)

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dir := ProjectSettings.globalize_path(args[0] if args.size() > 0 else "res://out/poc-apply")
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	deck.guard.enabled = false
	deck.begin_battle()
	for i in 40:
		battle.update_sim(0.05)
	await _shot(dir, "0-start")
	var mine: Array = battle.alive(0)
	var f = mine[1]
	battle.selected.clear()
	battle.selected.append(f)
	var back: Vector2 = f.pos - Vector2(cos(f.heading), sin(f.heading)) * 300.0
	battle.issue(BattleCommands.make("move", [f.id], -1, back, {}))
	for i in 12:
		battle.update_sim(0.05)
		await process_frame
	var cf = battle.sim.st.by_id(f.id)
	print("FLIP flip=", cf.flip, " wait=", cf.flip_wait, " heading=", cf.heading)
	await _shot(dir, "1-flip-start")
	for i in 40:
		battle.update_sim(0.1)
		await process_frame
	await _shot(dir, "2-flip-moving")
	# 제자리 방향 지정 180° -> 제자리 반전: 반전 직전·직후·후에 함선 위치가 그대로인지 본다
	battle.selected.clear()
	battle.selected.append(f)
	battle.order_face(f.heading + PI)
	for i in 3:
		battle.update_sim(0.05)
		await process_frame
	await _shot(dir, "2b-face-flip-start")
	for i in 30:
		battle.update_sim(0.1)
		await process_frame
	await _shot(dir, "2c-face-flip-after")
	battle.selected.clear()
	for i in mini(3, mine.size()):
		battle.selected.append(mine[i])
	var ids := []
	for g in battle.selected:
		ids.append(g.id)
	var fids: Array = battle.sim.salvo.formation_ids()
	battle.issue(BattleCommands.make("formation", ids, -1, Vector2.ZERO, {"id": str(fids[0])}))
	for i in 10:
		battle.update_sim(0.05)
		await process_frame
	await _shot(dir, "3-bundle-start")
	for i in 150:
		battle.update_sim(0.1)
	for i in 30:
		await process_frame
	await _shot(dir, "4-bundle-done")
	print("POC_APPLY_CAPTURE_DONE")
	quit(0)
