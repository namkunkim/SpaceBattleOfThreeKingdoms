extends SceneTree

# 진형 표시(P1): 코어 진형 전환이 뷰 모델 shape·정보 패널 진형 이름에 반영되고,
# 적 확인 접촉은 정확한 척 수·진형 없이 전력 구간만 보이는가. 헤드리스. 실패하면 종료 코드 1.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var src: BattleSource = battle.presentation.src
	var ally = battle.vm.alive(0)[0]
	var core: FleetState = battle.sim.st.by_id(ally.id)
	var before: int = ally.shape
	var name0: String = src.form_name(ally)
	if not TestCheck.ok(self, name0 != "" and ally.shape == core.shape, "초기 shape·진형 이름 (%s)" % name0): return
	# 다른 배치도의 진형으로 전환 명령 → 전환 시간이 지나면 뷰 모델 shape가 바뀐다.
	var ids: Array = battle.sim.salvo.formation_ids()
	var target := ""
	for fid in ids:
		if fid != core.formation_id and fid != "FRM-07" and BattleRules.FORM_SHAPE[ids.find(fid)] != before:
			target = fid
			break
	battle.sim.issue(BattleSim.command(0, [ally.id], "formation", -1, Vector2.ZERO, {"id": target}))
	for i in 700:
		battle.update_sim(0.1)
		if ally.formation_id == target:
			break
	if not TestCheck.ok(self, ally.formation_id == target, "전환 완료 (%s)" % target): return
	if not TestCheck.ok(self, ally.shape != before and ally.shape == core.shape, "뷰 모델 shape 갱신 %d -> %d" % [before, ally.shape]): return
	if not TestCheck.ok(self, src.squadron(ally.id).formation == ally.shape and src.form_name(ally) != name0, "렌더러 formation·패널 이름 갱신 (%s)" % src.form_name(ally)): return
	# 적 확인 접촉: 척 수·진형 비공개, 전력 구간만
	TestPoke.foe_beside(battle, ally)
	for i in 30:
		battle.update_sim(0.1)
	var foe = null
	for f in battle.fleets:
		if f.side == 1 and f.contact == "confirmed":
			foe = f
	if not TestCheck.ok(self, foe != null, "확인 접촉 존재"): return
	var txt: String = BattleSource.contact_strength_text(foe)
	if not TestCheck.ok(self, txt.begins_with("전력 ") and "/" in txt and "척" not in txt and src.form_name(foe) == "", "접촉 표기: " + txt): return
	print("OK formation_display")
	quit(0)
