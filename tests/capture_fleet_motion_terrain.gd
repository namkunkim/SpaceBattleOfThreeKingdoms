extends SceneTree

# develop 실제 FleetBattle3D·renderer·HUD의 PC 화면 확인 도구(일반 헤드리스 게이트 제외).
# godot --path . --resolution 1600x900 -s tests/capture_fleet_motion_terrain.gd -- res://out/fleet-motion-terrain
# 같은 명령을 1280x720에서 반복해 펼침 정보·지형 팝업 배치도 확인한다.
# 초기 배치만 통제한 뒤 이동/선회/진형/평행 명령은 실제 코어 경로로 실행한다.
# --frames를 둘째 인자로 주면 0.2초마다 PNG 시퀀스도 저장한다. 추가 인코더/서버 불필요.

var battle: Node
var renderer: FleetRenderer
var deck: Control
var fleet
var out_dir := ""
var sequence := false
var frame := 0
var measurements := []
var fails := 0
var fixture_positions := {}
var initial_hull := 0
var combat_mode := false
var combat_fixture := {}

func _fixture_ok() -> bool:
	if combat_mode:
		return ReferenceMotionFixture.stationary_ok(battle, combat_fixture)
	var core: FleetState = battle.sim.st.by_id(fleet.id)
	if core.dead or core.ships <= 0 or core.hull != initial_hull or battle.sim.st.over or battle.sim.first_hit_tick >= 0 or core.fire_id >= 0:
		return false
	if battle.sim.st.alive(1).is_empty():
		return false
	for id in fixture_positions:
		var parked: FleetState = battle.sim.st.by_id(id)
		if parked.dead or parked.pos.distance_to(fixture_positions[id]) > 0.01:
			return false
		if parked.side == 1 and parked.pos.distance_to(core.pos) <= battle.sim.R.ai_engage_r:
			return false   # 대기 시간을 무시하는 가까운 접촉 범위 밖이어야 한다
	return true

func _isolate_input(node: Node) -> void:
	# 실제 마우스/터치/핫키만 격리한다. _command의 직접 명령과 화면 _process는 유지한다.
	node.set_process_input(false)
	node.set_process_unhandled_input(false)
	node.set_process_unhandled_key_input(false)
	for child in node.get_children():
		_isolate_input(child)

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		push_error("MOTION_TERRAIN_CAPTURE_FAIL " + what)

func _slot_errors() -> Vector2:
	var core: FleetState = battle.sim.st.by_id(fleet.id)
	if core.dead or core.ships <= 0 or not renderer.vis.has(fleet.id):
		_check(false, "오차 측정 대상 함대가 살아 있음")
		return Vector2.INF
	var sq := renderer.src.squadron(fleet.id)
	var v: FleetRenderer.FleetVis = renderer.vis[fleet.id]
	var fpos := renderer.src.to3(sq.pos)
	var frot := -float(sq.heading) - PI * 0.5
	var errors := Vector2.ZERO
	var living := 0
	for s in v.slots:
		if s.alive:
			living += 1
			errors.x = maxf(errors.x, s.pos.distance_to(renderer._target(s, fpos, frot)))
			errors.y = maxf(errors.y, absf(angle_difference(s.yaw, -float(sq.heading) - PI)))
	_check(living > 0, "오차 측정 생존 슬롯이 1개 이상")
	return errors if living > 0 else Vector2.INF

func _initialize() -> void:
	call_deferred("_run")

func _command(kind: String, point := Vector2.ZERO, args := {}) -> void:
	battle.issue(BattleCommands.make(kind, [fleet.id], -1, point, args))

func _step(count: int, stage: String) -> void:
	for i in count:
		battle.update_sim(0.05)
		battle.vm.interpolate(battle._sim_acc_clock.alpha())
		renderer.update(0.05)
		battle.rig.update()
		await process_frame
		frame += 1
		if sequence and frame % 4 == 0:
			await _save("frames/%04d-%s" % [frame, stage], false)
	_check(_fixture_ok(), stage + (" 실제 정지 교전·양측 생존" if combat_mode else " 교전 없음·피격 없음·주차 함대 AI 이동 없음·승패 미종료"))

func _save(stage: String, record := true) -> void:
	deck.info.queue_redraw()
	deck.overlay.queue_redraw()
	deck.radar.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	var path := out_dir.path_join(stage + ".png")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var err := root.get_texture().get_image().save_png(path)
	if err != OK:
		push_error("CAPTURE_SAVE_FAILED %s %s" % [stage, err])
		quit(1)
		return
	if record:
		var sq := renderer.src.squadron(fleet.id)
		var v: FleetRenderer.FleetVis = renderer.vis[fleet.id]
		var first: FleetRenderer.Slot = v.slots[0]
		var errors := _slot_errors()
		measurements.append({"stage": stage, "clock_s": battle.sim.st.clock_s(),
			"fleet_pos": [sq.pos.x, sq.pos.y], "heading": sq.heading, "strafe": sq.strafe,
			"form_to": battle.sim.st.by_id(fleet.id).form_to, "form_left_s": float(battle.sim.st.by_id(fleet.id).form_left) / battle.sim.st.hz, "visual_formation": v.formation,
			"ship_pos": [first.pos.x, first.pos.y, first.pos.z], "ship_yaw": first.yaw,
			"max_slot_error": errors.x, "max_yaw_error": errors.y,
			"living_slots": v.slots.filter(func(s): return s.alive).size(),
			"fixture_ok": _fixture_ok(), "selected_count": battle.my_sel().size(),
			"core_combat_active": ReferenceMotionFixture.active(battle, combat_fixture) if combat_mode else false,
			"terrain_effects": renderer.src.terrain_effects(fleet.pos),
			"fingerprint": battle.sim.fingerprint()})
		print("MOTION_TERRAIN_CAPTURE ", stage, " ", path)

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("화면 있는 Godot 실행이 필요한 캡처 도구입니다")
		quit(2)
		return
	var args := OS.get_cmdline_user_args()
	out_dir = ProjectSettings.globalize_path(args[0] if not args.is_empty() else "res://out/fleet-motion-terrain")
	sequence = args.has("--frames")
	combat_mode = args.has("--combat")
	root.gui_disable_input = true   # HUD 버튼/미니맵의 실제 GUI 클릭도 받지 않는다
	battle = (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	_isolate_input(battle)
	for i in 6:
		await process_frame
	deck = battle.presentation.hud
	deck.guard.enabled = false
	deck.begin_battle()
	battle.set_process(false)
	battle.presentation.set_process(false)
	deck.pacing.set_process(false)
	battle.G.speed = 1
	battle.G.slow = 1.0
	renderer = battle.presentation.renderer
	if combat_mode:
		await _run_combat()
		return
	fleet = battle.vm.alive(0)[0]
	# wait는 가까운 접촉이면 무시되므로 거리까지 격리한다(CommanderAi._think_fleet).
	# 동서 모서리에 주차하고 이동/표적을 비운다. 아군 직접 지휘, 적 AI+wait는 그대로 실행한다.
	# 탈출점에서 떨어진 배치이며 양측 모두 살아 있어 승패가 끝나지 않는다.
	var field: Vector2 = battle.FIELD_SIZE
	var margin: float = maxf(float(battle.sim.R.edge), 30.0) + 10.0
	for f in battle.sim.st.fleets:
		if f.id == fleet.id:
			continue
		f.pos = field - Vector2.ONE * margin if f.side == 1 else Vector2.ONE * margin
		f.home = f.pos
		f.has_move = false
		f.target_id = -1
		f.face_set = false
		f.route.clear()
		f.charge = 0
		f.wait = 9000
		if f.side == 0:
			f.control = "direct"
		fixture_positions[f.id] = f.pos
	TestPoke.fleet(battle, fleet, {"pos": Vector2(300, 340), "heading": 0.0, "has_move": false, "target_id": -1, "face_set": false, "control": "direct"})
	initial_hull = battle.sim.st.by_id(fleet.id).hull
	battle.selected.assign([fleet])
	battle.cam_pos = fleet.pos + Vector2(100, 0)
	battle.cam_z = 1.45
	battle.rig.update()
	renderer.reset()
	renderer.update(0.0)
	deck._set_info_open(false)
	await _save("01-start")
	var core: FleetState = battle.sim.st.by_id(fleet.id)
	var start_pos := core.pos
	var start_clock: float = battle.sim.st.clock_s()
	_command("move", fleet.pos + Vector2(240, 0))
	_check(core.has_move, "직진 명령 수락")
	await _step(30, "straight")
	_check(core.pos.distance_to(start_pos) > 1.0 and battle.sim.st.clock_s() > start_clock, "직진 실제 코어 위치·시간 진행")
	await _save("02-straight")
	var heading_before := core.heading
	_command("move", fleet.pos + Vector2(0, 240))
	await _step(20, "turn90")
	_check(absf(angle_difference(heading_before, core.heading)) > 0.05, "90도 경로 명령 선회 진행")
	await _save("03-turn90")
	_command("stop")
	await _step(100, "settle")
	await _save("04-settled")
	var original := core.formation_id
	var target := "FRM-02" if original != "FRM-02" else "FRM-05"
	_command("formation", Vector2.ZERO, {"id": target})
	_check(core.form_to == target and core.form_left > 0, "진형 전환 명령 수락")
	await _step(40, "formation")
	_check(core.form_to == target and core.form_left > 0 and renderer.vis[fleet.id].formation == renderer.src.squadron(fleet.id).formation, "코어 진형 전환 대기 중 develop 화면 진형 일치")
	await _save("05-formation-mid")
	_command("formation", Vector2.ZERO, {"id": original})
	_check(core.form_to == "" and core.formation_id == original, "현재 진형 재선택 취소 수락")
	await _step(20, "cancel")
	await _save("06-formation-cancel")
	_command("move", fleet.pos - Vector2(cos(fleet.heading), sin(fleet.heading)) * 250.0, {"strafe": true})
	_check(core.has_move and core.strafe, "평행 후퇴 수락")
	start_pos = core.pos
	heading_before = core.heading
	await _step(30, "strafe")
	# yaw의 기존 시정수0.35초: 최악π에서0.01까지 약2.013초가 필요하다.
	# 1.5초 샘플 뒤 같은 실제 명령을 bounded하게 더 진행하며 임계값은 유지한다.
	for i in 70:   # 추가 최대3.5초(총5초), 조건을 만족하면 즉시 기록
		if _slot_errors().y < 0.01:
			break
		await _step(1, "strafe-settle")
	_check(core.pos.distance_to(start_pos) > 1.0 and absf(angle_difference(heading_before, core.heading)) < 0.01, "평행 후퇴 실제 이동·함대 방향 유지")
	_check(_slot_errors().y < 0.01, "평행 후퇴 화면 함수 방향 유지")
	await _save("07-strafe-back")
	_command("stop")
	await _step(100, "stop")
	heading_before = core.heading
	var target_heading := fposmod(heading_before + PI, TAU)
	start_pos = core.pos
	_command("face", Vector2.ZERO, {"facing_deg": rad_to_deg(target_heading)})
	_check(core.face_set and absf(angle_difference(core.face_to, target_heading)) < 0.002, "현재 방향에서 180도 선회 명령 수락")
	var settled := false
	for i in 30:   # 최대15초: 기본 제자리36도/초로180도 선회 후 슬롯/yaw 정돈 포함
		await _step(10, "turn180")
		var errors := _slot_errors()
		if not core.face_set and absf(angle_difference(core.heading, target_heading)) < 0.002 and errors.x < 0.02 and errors.y < 0.003:
			settled = true
			break
	_check(settled and core.pos.distance_to(start_pos) < 0.01 and absf(angle_difference(heading_before, core.heading)) > PI - 0.01, "180도 실제 완료·제자리·화면 정돈")
	await _save("08-turn180")
	# 별도 공개 지형 fixture: 성운·잔해 겹침에 선택 함대를 놓고 경유 경로를 보여 준다.
	var scale: Vector2 = battle.FIELD_SIZE / Vector2(1600, 900)
	TestPoke.fleet(battle, fleet, {"pos": Vector2(700, 130) * scale, "heading": 0.0, "has_move": false})
	renderer.reset()
	renderer.update(0.0)
	_command("move", Vector2(1000, 350) * scale, {"via": [Vector2(850, 230) * scale, Vector2(880, 330) * scale]})
	_check(not core.dead and core.ships > 0 and core.has_move and core.route.size() == 2 and core.move_to.distance_to(Vector2(850, 230) * scale) < 0.01, "지형 경유 경로 실제 명령 수락·함대 생존")
	_check(battle.my_sel().size() == 1 and battle.my_sel()[0] == fleet, "지형 fixture 단일 선택 유지")
	battle.cam_pos = battle.FIELD_SIZE * 0.5
	battle.cam_z = 0.5
	battle.rig.update()
	deck._set_info_open(true)
	var te: Dictionary = renderer.src.terrain_effects(fleet.pos)
	_check(deck.info_open and deck.info.visible and is_equal_approx(te.move, battle.sim.terrain.move_cost_bp(core.pos) / 10000.0) and te.sensor == -25 and te.conceal == 11, "펼침 INFO 공개 지형 효과·실제 코어 겹침 일치")
	_check(_fixture_ok() and _slot_errors().x < 0.02, "지형 fixture 살아 있는 슬롯·교전 분리")
	await _save("09-terrain-route-info")
	deck.hold_tip.toggle(deck.terrain_info)
	for i in 12:
		await process_frame
	await _save("10-terrain-legend")
	var f := FileAccess.open(out_dir.path_join("stages.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"viewport": [root.size.x, root.size.y], "input_isolated": true, "failures": fails, "stages": measurements}, "\t"))
	f.close()
	print("MOTION_TERRAIN_CAPTURE_", "PASS" if fails == 0 else "FAIL", " stages=", measurements.size(), " sequence=", sequence)
	quit(1 if fails else 0)

func _run_combat() -> void:
	# 실제 적벽 코어 자동 사격 + 양측 core fire_id를 사용한다. 기동/피해 수치 조정 없음.
	combat_fixture = ReferenceMotionFixture.prepare(battle)
	if combat_fixture.is_empty():
		_check(false, "교전 fixture 선택 실패")
		quit(1)
		return
	fleet = battle.vm.fleet(combat_fixture.ally_id)
	battle.selected.assign([fleet])
	battle.cam_pos = Vector2(730, 450)
	battle.cam_z = 1.6
	battle.rig.update()
	deck._set_info_open(false)
	var v: FleetRenderer.FleetVis = renderer.vis[fleet.id]
	var before := {}
	for s in v.slots:
		before[s] = {"pos": s.pos, "home": s.home, "yaw": s.yaw}
	var peak := Vector2.ZERO
	var active_frames := 0
	await _save("combat-00-start")
	for i in 240:   # 12 게임초, 기존 renderer.update의 동일50ms 경로
		await _step(1, "combat")
		if ReferenceMotionFixture.active(battle, combat_fixture):
			active_frames += 1
		var alive := 0
		for s in v.slots:
			if s.alive:
				alive += 1
				_check(before.has(s) and s.home == before[s].home, "실제 교전 생존 슬롯 유지")
				peak.x = maxf(peak.x, s.pos.distance_to(before[s].pos))
				peak.y = maxf(peak.y, absf(angle_difference(s.yaw, before[s].yaw)))
		_check(alive > 0, "실제 교전 생존 슬롯 1개 이상")
		if i in [59, 119, 239]:
			await _save("combat-%02d-seconds" % ((i + 1) / 20))
	_check(active_frames > 0 and peak.x < 0.0001 and peak.y < 0.0001, "실제 core 자동 사격 중 살아 있는 함선 왕복/회전 없음")
	var f := FileAccess.open(out_dir.path_join("stages.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"input_isolated": true, "mode": "core-combat", "failures": fails,
		"fixture": combat_fixture, "ally_final_ships": battle.sim.st.by_id(combat_fixture.ally_id).ships, "enemy_final_ships": battle.sim.st.by_id(combat_fixture.enemy_id).ships, "active_frames": active_frames, "max_position_drift": peak.x, "max_yaw_drift": peak.y, "stages": measurements}, "\t"))
	f.close()
	print("REFERENCE_COMBAT_CAPTURE_", "PASS" if fails == 0 else "FAIL", " fleet=", combat_fixture.ally_name, " active_frames=", active_frames, " peak=", peak)
	quit(1 if fails else 0)
