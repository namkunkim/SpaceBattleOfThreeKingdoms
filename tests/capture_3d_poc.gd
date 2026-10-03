extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene := load("res://scenes/FleetBattle3D.tscn") as PackedScene
	var battle := scene.instantiate()
	root.add_child(battle)
	await process_frame
	battle._start()
	if not TestCheck.ok(self, battle.fleets[0].nodes.size() == 28, "nodes"): return
	var forms := {}
	for f in battle.fleets:
		forms[f.form_id] = true
	if not TestCheck.ok(self, forms.size() == battle.fleets.size(), "forms"): return
	# 전 함대 선택 후 일괄 이동 검증
	battle.do_cmd("all")
	if not TestCheck.ok(self, battle.selected.size() == 6, "selected"): return
	var before: Array = []
	for f in battle.selected:
		before.append(f.pos)
	battle.order_move(Vector2(1300.0, 1150.0))
	for i in 240:
		battle.update_sim(0.05)
	for i in 60:
		await process_frame
	var moved := 0
	for i in battle.selected.size():
		if battle.selected[i].pos.distance_to(before[i]) > 50.0:
			moved += 1
	if not TestCheck.ok(self, moved == 6, "moved %d" % moved): return
	var image := root.get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://out"))
	image.save_png(ProjectSettings.globalize_path("res://out/fleet-battle.png"))
	print("FLEET_3D_CAPTURE_PASS")
	quit(0)
