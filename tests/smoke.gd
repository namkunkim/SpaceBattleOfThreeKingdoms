extends SceneTree

# 메인 씬(FleetBattle3D) 스모크: 씬 로드, 전투 시작, 시뮬레이션 진행, 방향 보정 값.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/FleetBattle3D.tscn") as PackedScene
	if not _check(scene != null): return
	var battle := scene.instantiate()
	root.add_child(battle)
	await process_frame
	if not _check(battle.fleets.size() == 13, "fleets %d" % battle.fleets.size()): return
	if not _check(battle.alive(0).size() == 6): return
	if not _check(battle.alive(1).size() == 7): return
	if not _check(battle.flag(0) != null and battle.flag(1) != null): return
	for f in battle.fleets:
		if not _check(f.nodes.size() == battle.MAX_VISIBLE): return
	battle._start()
	if not _check(battle.G.state == "play"): return
	# 방향 보정: 정면 <60°, 측면 60~120°, 후면 >120°
	var tgt = battle.fleets[6]
	var att = battle.fleets[0]
	tgt.heading = 0.0
	att.pos = tgt.pos + Vector2(100.0, 0.0)
	if not _check(is_equal_approx(battle.flank_mul(att, tgt), 1.0)): return
	att.pos = tgt.pos + Vector2(0.0, 100.0)
	if not _check(is_equal_approx(battle.flank_mul(att, tgt), 1.3)): return
	att.pos = tgt.pos + Vector2(-100.0, 0.0)
	if not _check(is_equal_approx(battle.flank_mul(att, tgt), 1.6)): return
	battle._restart()
	# 시뮬레이션 120초 진행 후에도 상태가 유효해야 한다
	for i in 2400:
		battle.update_sim(0.05)
	if not _check(battle.G.t > 100.0, "t %f" % battle.G.t): return
	print("FLEET_3D_SMOKE_PASS")
	quit(0)

# assert는 실패 시 멈춰서 프로세스가 끝나지 않는다. 실패를 종료 코드 1로 알린다.
func _check(ok: bool, msg: String = "") -> bool:
	if not ok:
		push_error("FLEET_3D_SMOKE_FAIL " + msg)
		quit(1)
	return ok
