extends SceneTree

# 메인 씬(FleetBattle3D) 스모크: 씬 로드, 전투 시작, 방향 보정, 증원, 시뮬레이션 상태의 유효성.
# 현행 POC는 _ready()에서 randomize()를 부르므로 인스턴스 뒤에 seed()로 다시 고정한다.
const SEED := 20261003

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene := load("res://scenes/FleetBattle3D.tscn") as PackedScene
	if not TestCheck.ok(self, scene != null, "scene load"): return
	var battle := scene.instantiate()
	root.add_child(battle)
	await process_frame
	seed(SEED)
	if not TestCheck.ok(self, battle.fleets.size() == 13, "fleets %d" % battle.fleets.size()): return
	if not TestCheck.ok(self, battle.alive(0).size() == 6, "ally fleets"): return
	if not TestCheck.ok(self, battle.alive(1).size() == 7, "foe fleets"): return
	if not TestCheck.ok(self, battle.flag(0) != null and battle.flag(1) != null, "flagships"): return
	for f in battle.fleets:
		if not TestCheck.ok(self, f.nodes.size() == battle.MAX_VISIBLE, "nodes %s" % f.fname): return
	battle._start()
	if not TestCheck.ok(self, battle.G.state == "play", "state"): return
	# 방향 보정: 정면 <60°, 측면 60~120°, 후면 >120° (경계값 처리는 M3에서 Q33 기준으로 맞춘다)
	var tgt = battle.fleets[6]
	var att = battle.fleets[0]
	tgt.heading = 0.0
	att.pos = tgt.pos + Vector2(100.0, 0.0)
	if not TestCheck.ok(self, is_equal_approx(battle.flank_mul(att, tgt), 1.0), "front"): return
	att.pos = tgt.pos + Vector2(0.0, 100.0)
	if not TestCheck.ok(self, is_equal_approx(battle.flank_mul(att, tgt), 1.3), "flank"): return
	att.pos = tgt.pos + Vector2(-100.0, 0.0)
	if not TestCheck.ok(self, is_equal_approx(battle.flank_mul(att, tgt), 1.6), "rear"): return
	battle._restart()
	seed(SEED)
	# 120초 진행: 95초 증원과 상태 값의 유효성
	for i in 2400:
		battle.update_sim(0.05)
		if battle.G.over:
			break
	if not battle.G.over:
		if not TestCheck.ok(self, battle.G.reinf, "reinforcements not spawned"): return
		if not TestCheck.ok(self, battle.fleets.size() == 15, "fleets after reinf %d" % battle.fleets.size()): return
	for f in battle.fleets:
		if not TestCheck.ok(self, is_finite(f.pos.x) and is_finite(f.pos.y) and is_finite(f.heading), "non-finite %s" % f.fname): return
		if not TestCheck.ok(self, f.ships >= 0.0 and f.ships <= f.max_ships, "ships out of range %s %f" % [f.fname, f.ships]): return
	battle.queue_free()
	await process_frame
	print("FLEET_3D_SMOKE_PASS")
	quit(0)
