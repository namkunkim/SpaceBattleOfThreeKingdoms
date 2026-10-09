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
	# 적벽 프로필: 안개 시작이라 아군(유비 4 + 손권 3)만 보이고 적은 접촉이 생길 때 나타난다
	if not TestCheck.ok(self, battle.fleets.size() == 7, "fleets %d" % battle.fleets.size()): return
	if not TestCheck.ok(self, battle.alive(0).size() == 7 and battle.alive(1).is_empty(), "ally fleets"): return
	if not TestCheck.ok(self, battle.flag(0) != null and battle.flag(1) == null, "flagships"): return
	for f in battle.fleets:
		if not TestCheck.ok(self, f.nodes.size() == battle.MAX_VISIBLE, "nodes %s" % f.fname): return
	battle._start()
	if not TestCheck.ok(self, battle.G.state == "play", "state"): return
	battle._restart()
	battle.G.hold = false   # 전투는 일시정지로 시작하므로 시간을 흘린다
	seed(SEED)
	# 120초 진행: 상태 값의 유효성(증원 전대는 프로필 투입 시각에 접촉으로만 나타난다)
	for i in 2400:
		battle.update_sim(0.05)
		if battle.G.over:
			break
	for f in battle.fleets:
		if not TestCheck.ok(self, is_finite(f.pos.x) and is_finite(f.pos.y) and is_finite(f.heading), "non-finite %s" % f.fname): return
		if not TestCheck.ok(self, f.ships >= 0.0 and f.ships <= f.max_ships, "ships out of range %s %f" % [f.fname, f.ships]): return
	battle.queue_free()
	await process_frame
	print("FLEET_3D_SMOKE_PASS")
	quit(0)
