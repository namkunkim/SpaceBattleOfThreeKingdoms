extends SceneTree

# 선택 전대 정보 패널(P9a): 아군은 세부 항목이 있고, 적 접촉은 금지 항목이 없으며,
# 확인이 풀린 접촉은 "전력 ?"가 되는가. 헤드리스. 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var src: BattleSource = battle.presentation.src
	var deck = battle.presentation.hud
	deck.begin_battle()
	await process_frame
	var ally = battle.vm.alive(0)[0]
	# 아군 단일: 세부 항목과 범주별 사거리
	var d: Dictionary = src.detail(ally.id)
	for k in ["commander", "vice", "staff", "morale_bp", "hull", "ammo", "heat", "heat_max", "speed", "formation"]:
		if not TestCheck.ok(self, d.has(k), "아군 detail 키 " + k): return
	if not TestCheck.ok(self, d.commander == ally.fname and d.speed > 0.0 and not ally.ranges.is_empty(), "지휘관·최대 속도·사거리 범주"): return
	battle.selected.clear()
	battle.selected.append(ally)
	for i in 3:
		await process_frame
	deck.info.queue_redraw()
	await process_frame
	# 다중 선택
	battle.selected.append(battle.vm.alive(0)[1])
	deck.info.queue_redraw()
	await process_frame
	# 적 접촉: 확인 -> 금지 항목 없음
	TestPoke.foe_beside(battle, ally)
	for i in 30:
		battle.update_sim(0.1)
	var foe = null
	for f in battle.fleets:
		if f.side == 1 and f.contact == "confirmed":
			foe = f
	if not TestCheck.ok(self, foe != null, "확인 접촉"): return
	if not TestCheck.ok(self, src.detail(foe.id).is_empty() and foe.ranges.is_empty() and foe.formation_id == "" and src.form_name(foe) == "" and foe.counts.is_empty(), "적 접촉에 편성·진형·사거리 없음"): return
	if not TestCheck.ok(self, BattleSource.contact_strength_text(foe).begins_with("전력 ") and foe.band > 0, "확인: 전력 구간"): return
	battle.selected.clear()
	battle.selected.append(foe)
	deck.info.queue_redraw()
	await process_frame
	# 확인 해제(추정) -> 전력 ?
	var core_foe: FleetState = battle.sim.st.by_id(foe.id)
	core_foe.pos = ally.pos + Vector2(4000, 0)
	for i in 100:
		battle.update_sim(0.1)
		if foe.contact != "confirmed":
			break
	if not TestCheck.ok(self, foe.contact != "confirmed" and BattleSource.contact_strength_text(foe) == "전력 ?", "추정/상실: 전력 ? (%s)" % foe.contact): return
	deck.info.queue_redraw()
	await process_frame
	print("OK info_panel")
	quit(0)
