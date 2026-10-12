extends SceneTree

# 초기 배치 흐름(호스트): 직접 배치를 켜고 출격하면 시간이 멈추고 이동 명령이 배치가 되며, 확정하면 시간이 흐른다.
# 기본(자동 배치)은 배치 막대가 없고 바로 흐른다. 헤드리스. 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var deck = battle.presentation.hud
	# 자동 배치(기본): 막대 없음
	deck.begin_battle()
	await process_frame
	if not TestCheck.ok(self, not battle.placing and not deck.place_bar.visible, "기본은 자동 배치"): return
	# 직접 배치
	battle.place_mode = true
	deck.restart()
	for i in 3:
		await process_frame
	if not TestCheck.ok(self, battle.placing and deck.place_bar.visible, "직접 배치: 막대 표시"): return
	var f = battle.alive(0)[0]
	var s0: Vector2 = battle.sim.st.by_id(f.id).spawn
	battle.selected.assign([f])
	battle.cmds.order_move(s0 + Vector2(4000, 0))
	var fs: FleetState = battle.sim.st.by_id(f.id)
	if not TestCheck.ok(self, absf(fs.pos.distance_to(s0) - BattleSim.PLACE_RADIUS) < 1.0 and not fs.has_move, "이동 명령 = 반경 안 배치: %.1f" % fs.pos.distance_to(s0)): return
	if not TestCheck.ok(self, f.pos.distance_to(fs.pos) < 1.0, "화면 위치도 바로 따라감"): return
	battle.update_sim(0.0)
	for i in 5:
		await process_frame
	if not TestCheck.ok(self, battle.sim.st.tick == 0, "배치 중 틱 정지: %d" % battle.sim.st.tick): return
	battle.cmds.order_attack(battle.alive(1)[0] if not battle.alive(1).is_empty() else f)
	if not TestCheck.ok(self, fs.target_id == -1, "배치 중 공격 지시는 막힘"): return
	battle.place_auto()
	if not TestCheck.ok(self, fs.pos.distance_to(s0) < 1.0, "자동 배치로 복귀"): return
	battle.place_confirm()
	for i in 20:
		await process_frame
	if not TestCheck.ok(self, not battle.placing and battle.sim.st.tick > 0, "확정 뒤 틱 진행: %d" % battle.sim.st.tick): return
	var placed := 0
	for c in battle.sim.command_log:
		if c.kind == "place":
			placed += 1
	if not TestCheck.ok(self, placed >= 2, "배치 명령이 기록에 남음: %d" % placed): return
	print("PLACEMENT_UI_PASS")
	quit(0)
