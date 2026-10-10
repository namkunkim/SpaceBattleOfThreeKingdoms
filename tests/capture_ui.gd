extends SceneTree

# 상품화 표현 계층 캡처. 화면이 있는 실행에서만 의미가 있다.
# godot --path . --script tests/capture_ui.gd -- <장면> <출력 png> [UI 크기]
# 폰 130% 배치 확인: --resolution 1600x720 ... -- battle res://out/ui-phone.png 1.3
# 장면: fog(안개 접촉) | title | prologue [장 0~7] | brief | quiet | battle | select | hold | undo | decision | wu | pause | suspend | result | settings | incoming | salvo | roster | roster_full | nohud(F1 HUD 숨김) | terrain(지형 3구역, 축소)
const SEED := 20261003

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var mode := args[0] if args.size() > 0 else "battle"
	var outp := args[1] if args.size() > 1 else "res://out/ui-%s.png" % mode
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	seed(SEED)
	var deck = battle.presentation.hud if battle.presentation else null
	if deck and mode != "suspend":
		deck.guard.enabled = false   # 캡처 창이 포커스를 잃어도 일시정지하지 않는다
	if args.size() > 2 and mode != "settings" and mode != "prologue":
		GameSettings.ui_scale = float(args[2])
		GameSettings.apply(root.get_window())
	if mode == "title":
		for i in 90:
			await process_frame
	elif mode == "quiet":
		# 접근 구간: 조용한 구간 자동 ×4 표시(Q52)
		if deck:
			deck.begin_battle()
		for i in 120:
			await process_frame
	elif mode == "settings":
		deck.show_screen("settings")
		deck.screens["settings"]._show_page(int(args[2]) if args.size() > 2 else 2)
		for i in 30:
			await process_frame
	elif mode == "roster" or mode == "roster_full":
		deck.screens["roster"].open_roster(mode == "roster_full", "표준")
		for i in 30:
			await process_frame
	elif mode == "prologue":
		deck.open_prologue()
		deck.screens["prologue"].open_at(int(args[2]) if args.size() > 2 else 0)
		for i in 60:
			await process_frame
	elif mode == "brief":
		if deck:
			deck.show_screen("brief")
		for i in 60:
			await process_frame
	else:
		if deck:
			deck.begin_battle()
		else:
			battle._start()
		# 접근 구간을 건너뛰고 교전 직전까지 진행한다.
		for i in 520:
			battle.update_sim(0.05)
		battle.selected.clear()
		battle.selected.append(battle.fleets[1])
		TestPoke.foe_beside(battle, battle.fleets[1], Vector2(380.0, -40.0))   # 안개 시작이라 적을 곁으로 옮겨 접촉·교전 장면을 만든다
		battle.update_sim(0.5)
		if mode == "select":
			battle.groups[1] = [battle.fleets[0].id, battle.fleets[1].id]
			battle.groups[2] = [battle.fleets[2].id]
			battle.multi = true   # 다중 모드 버튼 강조 확인
			if deck:
				deck._set_info_open(true)
				deck._set_tab(2)   # 무장 탭: 미사일·함재기 남은 횟수 표시 확인(Q69)
		battle.refresh_panel()
		battle.cam_pos = battle.fleets[1].pos + Vector2(260.0, 40.0)
		battle.cam_z = 1.0
		for i in 150:
			await process_frame
		if mode == "nohud":
			battle.toggle_hud()
			for i in 5:
				await process_frame
		elif mode == "terrain":
			battle.cam_z = 0.5   # 지형 3구역이 한 화면에 들어오게 축소
			battle.cam_pos = battle.FIELD_SIZE * 0.5
			for i in 5:
				await process_frame
		elif mode == "fog":
			# 안개 UI 확인: 적 접촉 하나는 추정(오차 반경·신뢰도), 하나는 상실. 캡처 전용.
			battle.G.speed = 0   # 시계를 세워 값을 고정한다
			var k := 0
			for f in battle.fleets:
				if f.side == 1 and not f.dead:
					f.contact = "estimated" if k == 0 else "lost"
					f.err_r = 90.0
					f.conf = 0.55
					k += 1
					if k == 2:
						break
			for i in 10:
				await process_frame
		elif mode == "pause":
			battle._toggle_menu()
			for i in 30:
				await process_frame
		elif mode == "hold":
			# 터치로 돌격 버튼을 길게 누른 상태
			for b in deck.cmd_buttons:
				if b.cmd.id == "charge":
					var m := InputEventMouseButton.new()
					m.device = InputEvent.DEVICE_ID_EMULATION
					m.button_index = MOUSE_BUTTON_LEFT
					m.position = b.get_global_rect().get_center()
					m.pressed = true
					root.push_input(m, true)
			for i in 50:
				await process_frame
		elif mode == "undo":
			battle.order_move(battle.fleets[1].pos + Vector2(260, -120))
			for i in 20:
				await process_frame
		elif mode == "decision":
			# 자리 확인용 견본(캡처 전용). 게임에는 코어의 분기만 뜬다.
			deck.decision_card.open_card({"speaker_id": "CHR-0217", "line": "바람 창이 열렸습니다. 지금 배에 불을 붙이겠습니까?", "queue": 1, "time": 30.0,
				"options": [{"label": "화공 발동", "effects": [["표적 사기", "−3500"], ["적 군 사기", "−2500"]], "risk": {"level": "high", "why": "간파 위험: 의심 82"}, "rec": "제갈량"},
					{"label": "한 번 더 기다린다", "effects": [["기류 창 남은 시간", "약 40초"]], "risk": {"level": "mid", "why": "기류가 바뀔 수 있음"}, "rec": ""},
					{"label": "황개를 물린다", "effects": [["황개 전대", "후퇴"]], "risk": {"level": "low", "why": "기회 상실"}, "rec": ""}]})
			deck.decision_card.time_left = 21.0
			for i in 20:
				await process_frame
		elif mode == "wu":
			# 오(吳) 세력 표시 확인: 적벽 프로필의 손권군 전대 3개(주유·정보·황개)가 오 인장·보라 선체로 뜬다
			battle.selected.clear()
			battle.selected.append(battle.fleets[4])
			battle.cam_pos = battle.fleets[4].pos + Vector2(120.0, 40.0)
			for i in 20:
				await process_frame
		elif mode == "incoming":
			# 분기 예고(화면 밖 오른쪽 아래) + 빠른 선택 알림 견본(캡처 전용)
			battle.presentation.src.incoming_override = {"secs": 3.0, "pos": battle.s2w(Vector2(2400, 1200))}
			deck.quick_alert.open_alert({"text": "정욱의 의심이 커지고 있습니다", "options": [{"label": "황개를 늦춘다", "rec": true}, {"label": "그대로 간다"}], "time": 60.0})
			for i in 20:
				await process_frame
		elif mode == "salvo":
			for f in battle.alive(0):
				if f.fire_t and not f.fire_t.dead:
					deck.renderer.emphasis_volley(f.id)
					break
			for i in 14:
				await process_frame
		elif mode == "suspend":
			# 포커스를 잃어 자동으로 멈춘 일시정지(Q53)
			deck.guard.suspend("focus")
			for i in 30:
				await process_frame
		elif mode == "result":
			battle.G.killed = 412.0
			battle.G.lost = 168.0
			battle.end_game(true, "조조군이 적벽에서 모두 사라졌습니다. 적벽의 궤도는 연합의 손에 남습니다.")
			for i in 160:
				await process_frame
	print("UI_FPS ", Engine.get_frames_per_second(), " ships ", battle.presentation.renderer.vis.values().reduce(func(a, v): return a + v.alive_n, 0) if battle.presentation else 0)
	var image := root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(outp) if outp.begins_with("res://") else outp
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("UI_CAPTURE_PASS ", path)
	quit(0)
