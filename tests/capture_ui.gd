extends SceneTree

# 상품화 표현 계층 캡처. 화면이 있는 실행에서만 의미가 있다.
# godot --path . --script tests/capture_ui.gd -- <장면> <출력 png> [UI 크기]
# 폰 130% 배치 확인: --resolution 1600x720 ... -- battle res://out/ui-phone.png 1.3
# 장면: title | brief | quiet | battle | select | hold | undo | decision | wu | pause | suspend | result
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
	if args.size() > 2:
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
		battle.refresh_panel()
		battle.cam_pos = battle.fleets[1].pos + Vector2(260.0, 40.0)
		battle.cam_z = 1.0
		for i in 150:
			await process_frame
		if mode == "pause":
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
			deck.decision_card.open_card({"speaker": "제갈량", "portrait": 3, "line": "황개 전대가 바람 창에 닿았습니다. 지금 불을 놓으시겠습니까?", "queue": 1, "time": 30.0,
				"options": [{"label": "화공 발동", "effects": [["표적 사기", "−3500"], ["적 군 사기", "−2500"]], "risk": {"level": "high", "why": "간파 위험: 의심 82"}, "rec": "제갈량"},
					{"label": "한 번 더 기다린다", "effects": [["기류 창 남은 시간", "약 40초"]], "risk": {"level": "mid", "why": "기류가 바뀔 수 있음"}, "rec": ""},
					{"label": "황개를 물린다", "effects": [["황개 전대", "후퇴"]], "risk": {"level": "low", "why": "기회 상실"}, "rec": ""}]})
			deck.decision_card.time_left = 21.0
			for i in 20:
				await process_frame
		elif mode == "wu":
			# 오(吳) 세력 표시 확인용: 아군 전대 둘을 동맹 세력으로 바꿔 그린다(캡처 전용)
			battle.presentation.src.faction_override = {battle.fleets[2].id: "wu", battle.fleets[3].id: "wu"}
			battle.selected.clear()
			battle.selected.append(battle.fleets[2])
			for i in 20:
				await process_frame
		elif mode == "suspend":
			# 포커스를 잃어 자동으로 멈춘 일시정지(Q53)
			deck.guard.suspend("focus")
			for i in 30:
				await process_frame
		elif mode == "result":
			battle.G.killed = 412.0
			battle.G.lost = 168.0
			battle.end_game(true, "위 원정군이 회랑에서 모두 사라졌습니다. 회랑은 연합의 손에 남습니다.")
			for i in 160:
				await process_frame
	print("UI_FPS ", Engine.get_frames_per_second(), " ships ", battle.presentation.renderer.vis.values().reduce(func(a, v): return a + v.alive_n, 0) if battle.presentation else 0)
	var image := root.get_viewport().get_texture().get_image()
	var path := ProjectSettings.globalize_path(outp) if outp.begins_with("res://") else outp
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	image.save_png(path)
	print("UI_CAPTURE_PASS ", path)
	quit(0)
