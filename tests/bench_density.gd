extends SceneTree

# 표시 함선 밀도(낮음·보통·높음)별 프레임 시간 측정. 창이 있는 실행에서만 의미가 있다(헤드리스는 무의미).
# 태블릿 기본 밀도를 정하는 근거를 만든다. 결과는 out/bench-density.md에도 남긴다.
#   godot --path . --resolution 1920x1200 --script tests/bench_density.gd
# 안드로이드 실기기에서는 이 스크립트를 임시 메인 씬으로 돌리거나, 설정 화면에서 밀도를 바꿔 가며 FPS를 본다.

const WARM := 2.0
const SPAN := 6.0
# 1,500척 프리셋(O0, Q80·Q82): 연합은 지휘 한도까지 채운 함대(척 수 배율), 조조는 함대 수를 늘린다(전대 복제).
# 추정: 연합 비용 4,308 ÷ 척당 약 9 ≈ 480척, 조조 약 9,200 ÷ 9 ≈ 1,020척.
const BIG_ALLY := 480
const BIG_FOE := 1020

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	GameSettings.load_cfg()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)   # 화면 주사율에 막히지 않게
	Engine.max_fps = 0
	var rows := []
	# 첫 라운드는 셰이더·자원 준비가 섞이므로 버린다(보통으로 한 번 더 돌린다). [밀도, 1,500척 프리셋]
	var order := [[1, false], [0, false], [1, false], [2, false], [0, true], [1, true], [2, true]]
	for round_i in order.size():
		var dens: int = order[round_i][0]
		var big: bool = order[round_i][1]
		var discard := round_i == 0
		var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
		if big:
			battle.profile_patch = _big_preset
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
			rows.append(["1,500척" if big else "현재", ["낮음", "보통", "높음"][dens], _real_ships(battle), ships, frames / secs, 1000.0 * secs / frames, worst])
		battle.queue_free()
		await process_frame
		await process_frame
	var out := "# 표시 밀도 측정\n\n창 %s, 렌더러 %s, 어댑터 %s\n\n| 프리셋 | 밀도 | 실제 함선 | 표시 함선 | FPS | 평균 ms | 최악 ms |
|---|---|---|---|---|---|---|
" % [
		root.size, ProjectSettings.get_setting("rendering/renderer/rendering_method"), RenderingServer.get_video_adapter_name()]
	for r in rows:
		out += "| %s | %s | %d | %d | %.1f | %.2f | %.1f |
" % r
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

func _real_ships(battle: Node) -> int:
	var n := 0
	for f in battle.sim.st.fleets:   # 증원 대기 전대 포함(정원 기준)
		n += f.max_ships / BattleRules.MILLI
	return n

# 연합 전대는 척 수를 늘리고(지휘 한도까지 채운 함대), 조조 전대는 복제해 함대 수를 늘린다(Q82). 증원 대기 전대도 같이 복제한다.
func _big_preset(p: Dictionary) -> void:
	var ally_n := 0
	for d in p.ally:
		ally_n += int(d.ships)
	for d in p.ally:
		_scale(d, float(BIG_ALLY) / ally_n)
	var base: Array = p.foe.duplicate()
	var foe_n := 0
	for d in base:
		foe_n += int(d.ships)
	var k := 0
	while foe_n < BIG_FOE:
		var c: Dictionary = base[k % base.size()].duplicate(true)
		k += 1
		c.squadron_id = "%s-B%d" % [c.squadron_id, k]
		c.flag = false
		c.y = float(c.y) + (40.0 if k % 2 else -40.0) * (1 + k / base.size())
		p.foe.append(c)
		foe_n += int(c.ships)

func _scale(d: Dictionary, f: float) -> void:
	var n := 0
	for c in d.composition:
		c.count = maxi(1, roundi(int(c.count) * f))
		n += c.count
	d.ships = n
