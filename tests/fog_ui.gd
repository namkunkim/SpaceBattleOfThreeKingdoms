extends SceneTree

# 안개 UI·감속 검증(헤드리스): 접촉 필드(오차 반경·신뢰도·상실)가 뷰 모델에 오고, quiet()가 상실 접촉을 무시하며,
# 선택 감속이 Engine.time_scale이 아니라 코어 TickClock 배율로 먹는지, 코어 heading 틱 간 변화가 계단로 보일 크기인지 본다.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	for i in 6:
		await process_frame
	var src: BattleSource = battle.presentation.src
	battle.presentation.hud.begin_battle()
	battle.G.hold = false   # 전투는 일시정지로 시작하므로 시간을 흘린다
	await process_frame
	# 접촉 필드: 적 전대를 아군 곁으로 옮겨 접촉시키고, 다시 멀리 보내 추정·상실로 흘려 본다.
	var ally = battle.vm.alive(0)[0]
	TestPoke.foe_beside(battle, ally)
	for i in 30:
		battle.update_sim(0.1)
	var foe = null
	for f in battle.fleets:
		if f.side == 1 and f.contact != "":
			foe = f
	if not TestCheck.ok(self, foe != null, "foe appears as a contact"): return
	if not TestCheck.ok(self, foe.contact in ["confirmed", "estimated"] and foe.conf > 0.0, "contact fields (%s conf %.2f)" % [foe.contact, foe.conf]): return
	if not TestCheck.ok(self, not src.quiet(), "confirmed contact next to ally -> not quiet"): return
	# 상실 접촉은 quiet() 판정에서 빠진다.
	for f in battle.fleets:
		if f.side == 1:
			f.contact = "lost"
	battle.missiles.clear()
	battle.swarms.clear()
	if not TestCheck.ok(self, src.quiet(), "lost contact ignored by quiet()"): return
	# 감속은 코어 틱 배율이다.
	src.set_time_scale(0.2)
	if not TestCheck.ok(self, is_equal_approx(Engine.time_scale, 1.0) and is_equal_approx(src.slow(), 0.2), "slow uses G.slow, Engine.time_scale untouched"): return
	var t0: int = battle.sim.st.tick
	battle.G.state = "play"
	for i in 10:
		battle._process(0.1)
	var n: int = battle.sim.st.tick - t0
	if not TestCheck.ok(self, n >= 1 and n <= 3, "x0.2 runs ~2 ticks per 1s (got %d)" % n): return
	src.set_time_scale(1.0)
	# heading 틱 간 최대 변화(라디안)
	battle.selected.assign([ally])
	battle.issue(BattleCommands.make("move", [ally.id], -1, ally.pos - Vector2(cos(ally.theading), sin(ally.theading)) * 400.0))
	var h0: float = ally.theading
	var worst := 0.0
	for i in 200:
		battle.sim.step()
		battle._sync()
		worst = maxf(worst, absf(angle_difference(h0, ally.theading)))
		h0 = ally.theading
	print("HEADING_STEP_MAX_DEG ", rad_to_deg(worst))
	print("FOG_UI_PASS")
	quit()
