extends SceneTree

# 화면 흐름 검증(헤드리스): 실제 버튼 위치를 마우스로 눌러 타이틀 → 서막(첫 회) → 브리핑 → 전투 → 일시정지 → 계속 → 결과 → 타이틀.
# 터치(탭)로도 HUD 버튼이 눌리는지 확인한다.

func _initialize() -> void:
	call_deferred("_run")

func _click(c: Control, touch := false) -> void:
	var p := c.get_global_rect().get_center()
	if touch:
		# 터치는 Godot가 마우스로 흉내 내어 GUI에 전달한다(DEVICE_ID_EMULATION).
		for down in [true, false]:
			var m := InputEventMouseButton.new()
			m.device = InputEvent.DEVICE_ID_EMULATION
			m.button_index = MOUSE_BUTTON_LEFT
			m.position = p
			m.global_position = p
			m.pressed = down
			m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
			root.push_input(m, true)
	else:
		var mv := InputEventMouseMotion.new()
		mv.position = p
		mv.global_position = p
		root.push_input(mv, true)
		for down in [true, false]:
			var m := InputEventMouseButton.new()
			m.button_index = MOUSE_BUTTON_LEFT
			m.position = p
			m.global_position = p
			m.pressed = down
			m.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
			root.push_input(m, true)

func _find_button(n: Node, text: String) -> Button:
	if n is Button and (n as Button).text == text and (n as Control).is_visible_in_tree():
		return n
	for c in n.get_children():
		var b := _find_button(c, text)
		if b:
			return b
	return null

func _key(code: Key) -> void:
	var k := InputEventKey.new()
	k.keycode = code
	k.pressed = true
	root.push_input(k, true)

func _restore_cfg(bytes: PackedByteArray) -> void:
	if bytes.is_empty():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameSettings.PATH))
	else:
		var f := FileAccess.open(GameSettings.PATH, FileAccess.WRITE)
		f.store_buffer(bytes)
		f.close()

func _frames(n := 6) -> void:
	for i in n:
		await process_frame

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	if not TestCheck.ok(self, deck.screen == "title" and battle.G.state == "brief", "starts at title"): return
	# 서막(NARRATIVE-RED-CLIFFS §11): 첫 회만 출격 준비 → 서막 → 브리핑. 실제 설정 파일은 끝나고 되돌린다.
	var saved_cfg := FileAccess.get_file_as_bytes(GameSettings.PATH) if FileAccess.file_exists(GameSettings.PATH) else PackedByteArray()
	GameSettings.load_cfg()
	GameSettings.prologue_seen = false
	_click(_find_button(deck, "출격 준비"))
	await _frames()
	var pro = deck.screens["prologue"]
	if not TestCheck.ok(self, deck.screen == "prologue" and pro.page == 0, "first run: title -> prologue (%s)" % deck.screen): return
	_click(pro, true)
	await _frames()
	if not TestCheck.ok(self, pro.page == 1, "tap -> next page"): return
	_key(KEY_SPACE)
	await _frames()
	if not TestCheck.ok(self, pro.page == 2 and deck.screen == "prologue" and battle.G.state == "brief", "space -> next page, no pause"): return
	for i in PrologueText.PAGES.size() - 3:
		_click(pro)
		await _frames()
	if not TestCheck.ok(self, pro.page == PrologueText.PAGES.size() - 1, "last page"): return
	_click(pro)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "brief" and GameSettings.prologue_seen, "last page -> brief, seen saved"): return
	var cf := ConfigFile.new()
	if not TestCheck.ok(self, cf.load(GameSettings.PATH) == OK and bool(cf.get_value("progress", "prologue_seen", false)), "prologue_seen in settings.cfg"): return
	_click(_find_button(deck, "뒤로"))
	await _frames()
	_click(_find_button(deck, "출격 준비"))
	await _frames()
	if not TestCheck.ok(self, deck.screen == "brief", "second run: title -> brief (%s)" % deck.screen): return
	# 다시 보기 + 건너뛰기(버튼·Esc)
	_click(_find_button(deck, "뒤로"))
	await _frames()
	_click(_find_button(deck, "서막"))
	await _frames()
	if not TestCheck.ok(self, deck.screen == "prologue" and pro.page == 0, "title replay button -> prologue"): return
	_click(_find_button(deck, "건너뛰기  Esc"), true)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "brief", "skip button -> brief"): return
	deck.open_prologue()
	await _frames()
	_key(KEY_ESCAPE)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "brief", "esc -> brief"): return
	_restore_cfg(saved_cfg)
	_click(_find_button(deck, "출  격"), true)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "" and battle.G.state == "play", "brief -> battle by touch"): return
	if not TestCheck.ok(self, deck.hud.visible and battle.ui.get_parent().visible == false, "new hud replaces legacy"): return
	# 명령 패널 터치: 전체 선택
	var all_btn: Control = null
	for b in deck.cmd_buttons:
		if b.cmd.id == "all":
			all_btn = b
	battle.selected.clear()
	_click(all_btn, true)
	await _frames()
	if not TestCheck.ok(self, battle.selected.size() == battle.alive(0).size(), "touch command button"): return
	# Space로 일시정지
	_key(KEY_SPACE)
	await _frames()
	if not TestCheck.ok(self, deck.screen == "pause" and battle.G.state == "pause", "space -> pause (%s/%s)" % [deck.screen, battle.G.state]): return
	_click(_find_button(deck, "계속"))
	await _frames()
	if not TestCheck.ok(self, deck.screen == "" and battle.G.state == "play", "resume"): return
	battle.end_game(false, "테스트")
	# 종료 연출(1.6초)은 실제 시간으로 흐른다
	await create_timer(2.2).timeout
	await _frames()
	if not TestCheck.ok(self, deck.screen == "result" and not deck.overlay.visible, "result screen"): return
	_click(_find_button(deck, "타이틀로"))
	await _frames()
	if not TestCheck.ok(self, deck.screen == "title" and battle.G.state == "brief", "back to title"): return
	print("UI_FLOW_PASS")
	quit(0)
