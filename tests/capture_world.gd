extends SceneTree

# 천하 지도 캡처. 화면이 있는 실행에서만 의미가 있다(헤드리스는 검은 화면).
# godot --path . --resolution 1600x1000 --script tests/capture_world.gd -- <장면> <출력 png>
# 장면: z0 | card | z3 | resolve | result | result_cao

func _initialize() -> void:
	call_deferred("_run")

func _wait(s: float) -> void:
	await create_timer(s).timeout

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() > 0 else "z0"
	var outp := args[1] if args.size() > 1 else "res://out/world-%s.png" % mode
	var s := (load("res://scenes/WorldMap.tscn") as PackedScene).instantiate() as WorldMapScreen
	root.add_child(s)
	current_scene = s
	await _wait(0.8)
	match mode:
		"card":
			s.open_card()
			await _wait(1.8)
		"z3":
			s.open_card()
			await _wait(1.6)
			s.sortie(5)
			await _wait(5.0)
		"resolve":
			s.open_card()
			await _wait(1.6)
			s._set_mode("auto")
			s.sortie(5)
			s._finish_sortie()
			await _wait(4.0)
		"result", "result_cao":
			var o := BattleOutcome.new()
			o.win = mode == "result"
			o.kind = "alliance_win" if o.win else "cao_win"
			o.reason = "cao_morale_collapse" if o.win else "alliance_morale_collapse"
			o.grade = "우세" if o.win else "패배"
			o.cao_status = "severe"
			o.t_s = 851.0
			o.loss_pct = {"alliance": 24, "foe": 61}
			o.mode = "auto"
			o.difficulty = "표준"
			o.seed = 5
			o.ending = BattleOutcome.ending_of(o)
			o.line = "E6" if o.win else "E11"
			s._show_result(o)
			await _wait(2.6)
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(outp)
	print("saved ", outp)
	quit(0)
