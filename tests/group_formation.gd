extends SceneTree

# 그룹 저장·호출 → 진형 카드 → 선택된 함대 전체의 공동 배치.
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	deck.begin_battle()
	var allies: Array = battle.alive(0)
	var members: Array = [allies[1], allies[2], allies[3]]
	battle.selected.assign(members)
	battle.assign_group(1)
	battle.selected.clear()
	battle.select_group(1)
	if not TestCheck.ok(self, SelectionSet.same(battle.my_sel(), members), "저장된 3함대 그룹 호출"): return
	var outsider = allies[0]
	var old_move: Vector2 = outsider.move_to
	var old_form: String = outsider.formation_id
	var states: Array = []
	for f in members:
		states.append(battle.sim.st.by_id(f.id))
	# 같은 전환 목표를 다시 지정하거나 다른 진형으로 바꾸어도 그룹 슬롯을 받는다.
	for fid in ["FRM-02", "FRM-02", "FRM-03"]:
		var kind: int = BattleRules.FORM_SHAPE[battle.sim.salvo.formation_ids().find(fid)]
		var option := {}
		for o in deck.src.formation_options():
			if o.id == fid:
				option = o
		if not TestCheck.ok(self, not option.is_empty() and option.state != "locked", "그룹 진형 카드 사용 가능"): return
		var card := FormationTab.FormButton.new(option, deck)
		deck._on_formation_pressed(card)
		card.free()
		var expected := BundleLayout.slots(states, kind, float(battle.sim.salvo.C.movement.bundle_gap), battle.sim.R.edge, battle.sim.rs.world)
		for f in states:
			if not TestCheck.ok(self, f.has_move and f.strafe and f.move_grp != 0 and f.move_grp == states[0].move_grp, "선택 그룹 공동 재배치"): return
			if not TestCheck.ok(self, f.move_to == expected[f.id], "진형 카드가 그룹 슬롯 지정"): return
			if not TestCheck.ok(self, f.form_to == fid or f.formation_id == fid, "선택 함대 진형 전환"): return
		if not TestCheck.ok(self, outsider.move_to == old_move and outsider.formation_id == old_form, "비선택 함대 유지"): return
	var audio_released: bool = await preload("res://tests/lib/headless_audio_shutdown.gd").release(self, battle)
	if not TestCheck.ok(self, audio_released, "headless battle audio cleanup"): return
	print("GROUP_FORMATION_PASS")
	quit(0)
