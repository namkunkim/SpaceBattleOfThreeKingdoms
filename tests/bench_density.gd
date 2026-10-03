extends SceneTree

# 표시 함선 밀도(낮음·보통·높음)별 프레임 시간 측정. 창이 있는 실행에서만 의미가 있다(헤드리스는 무의미).
# 태블릿 기본 밀도를 정하는 근거를 만든다. 결과는 out/bench-density.md에도 남긴다.
#   godot --path . --resolution 1920x1200 --script tests/bench_density.gd
# 안드로이드 실기기에서는 이 스크립트를 임시 메인 씬으로 돌리거나, 설정 화면에서 밀도를 바꿔 가며 FPS를 본다.

const WARM := 2.0
const SPAN := 6.0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GameSettings.load_cfg()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)   # 화면 주사율에 막히지 않게
	Engine.max_fps = 0
	var rows := []
	# 첫 라운드는 셰이더·자원 준비가 섞이므로 버린다(보통으로 한 번 더 돌린다).
	var order := [1, 0, 1, 2]
	for round_i in order.size():
		var dens: int = order[round_i]
		var discard := round_i == 0
		var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
		GameSettings.ship_density = dens
		root.add_child(battle)
		for i in 5:
			await process_frame
		var deck = battle.presentation.hud
		deck.guard.enabled = false
		deck.begin_battle()
		await create_timer(WARM).timeout
		var frames := 0
		var worst := 0.0
		var t0 := Time.get_ticks_usec()
		var last := t0
		while (Time.get_ticks_usec() - t0) < int(SPAN * 1e6):
			await process_frame
			var now := Time.get_ticks_usec()
			worst = maxf(worst, (now - last) / 1000.0)
			last = now
			frames += 1
		var secs := (Time.get_ticks_usec() - t0) / 1e6
		var ships := _count_ships(battle)
		if not discard:
			rows.append([["낮음", "보통", "높음"][dens], ships, frames / secs, 1000.0 * secs / frames, worst])
		battle.queue_free()
		await process_frame
		await process_frame
	var out := "# 표시 밀도 측정\n\n창 %s, 렌더러 %s, 어댑터 %s\n\n| 밀도 | 표시 함선 | FPS | 평균 ms | 최악 ms |\n|---|---|---|---|---|\n" % [
		root.size, ProjectSettings.get_setting("rendering/renderer/rendering_method"), RenderingServer.get_video_adapter_name()]
	for r in rows:
		out += "| %s | %d | %.1f | %.2f | %.1f |\n" % r
	print(out)
	DirAccess.make_dir_recursive_absolute("res://out")
	var f := FileAccess.open("res://out/bench-density.md", FileAccess.WRITE)
	f.store_string(out)
	f.close()
	quit()

func _count_ships(battle: Node) -> int:
	var n := 0
	var r = battle.presentation.renderer
	if r and r.has_method("visible_ship_count"):
		n = r.visible_ship_count()
	return n
