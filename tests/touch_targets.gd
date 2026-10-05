extends SceneTree

# 터치 목표 크기 점검(헤드리스, 제안서 §7.2 48dp). 1차 목표: 안드로이드 태블릿 + 윈도우 PC.
# 모든 화면(전투 HUD, 결정 카드, 타이틀, 브리핑, 일시정지, 설정 3쪽, 결과)의 누를 수 있는 컨트롤을 모아
# 기준 기기별 dp(짧은 변)를 계산해 out/touch-targets.md에 남긴다. 태블릿(UI 100%)에서 모두 48dp 이상이어야 한다.

func _initialize() -> void:
	call_deferred("_run")

var rows := []
var seen := {}

func _collect(n: Node, screen: String) -> void:
	if (n is BaseButton or n is Slider) and (n as Control).is_visible_in_tree():
		var key := "%s · %s" % [screen, _name(n)]
		if not seen.has(key):
			seen[key] = true
			rows.append([key, (n as Control).size])
	for c in n.get_children():
		_collect(c, screen)

func _name(c: Control) -> String:
	if "cmd" in c:
		return "명령 " + c.cmd.label
	if c is DeckWidgets.TabButton:
		return "탭 " + str(c.get_meta("label"))
	if c is DeckWidgets.IconButton:
		return "아이콘 " + (c.tooltip_text.split(" (")[0].split(" · ")[0] if c.tooltip_text != "" else c.caption)
	if c is Slider:
		return "슬라이더"
	if c is Button and (c as Button).text != "":
		return (c as Button).text.strip_edges()
	return c.get_class()

func _frames(n := 4) -> void:
	for i in n:
		await process_frame

func _mark(dp: float) -> String:
	return ("%d" if dp >= TouchMetrics.MIN_DP else "⚠%d") % roundi(dp)

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await _frames()
	var deck = battle.presentation.hud
	_collect(deck.screens["title"], "타이틀")
	deck.show_screen("brief")
	await _frames()
	_collect(deck.screens["brief"], "브리핑")
	deck.begin_battle()
	await _frames()
	_collect(deck.hud, "전투")
	deck.decision_card.open_card({"speaker_id": "zhuge_liang", "line": "견본", "time": 30.0,
		"options": [{"label": "가"}, {"label": "나"}, {"label": "다"}]})
	await _frames()
	_collect(deck.decision_card, "결정 카드")
	deck.decision_card.close_card()
	deck.undo_bar.visible = true
	_collect(deck.undo_bar, "되돌리기")
	deck.undo_bar.visible = false
	deck.open_pause()
	await _frames()
	_collect(deck.screens["pause"], "일시정지")
	deck.show_screen("settings_pause")
	for i in 3:
		deck.screens["settings_pause"]._show_page(i)
		await _frames(2)
		_collect(deck.screens["settings_pause"], "설정")
	deck.show_screen("result")
	await _frames()
	_collect(deck.screens["result"], "결과")
	var lines := ["# 터치 목표 크기 점검", "", "기준 %d dp, UI 크기 100%%. 값은 짧은 변의 dp. ⚠는 기준 미달." % int(TouchMetrics.MIN_DP), ""]
	var head := "| 컨트롤 | 크기(단위) |"
	var sep := "|---|---|"
	for d in TouchMetrics.DEVICES:
		head += " %s |" % d[0]
		sep += "---|"
	lines.append(head)
	lines.append(sep)
	var bad := []
	for r in rows:
		var sz: Vector2 = r[1]
		var short := minf(sz.x, sz.y)
		var line := "| %s | %d×%d |" % [r[0], roundi(sz.x), roundi(sz.y)]
		for i in TouchMetrics.DEVICES.size():
			var d: Array = TouchMetrics.DEVICES[i]
			var dp := short * TouchMetrics.dp_per_unit(d[1], d[2], 1.0)
			line += " %s |" % _mark(dp)
			if i < TouchMetrics.TOUCH_DEVICES and dp < TouchMetrics.MIN_DP and not bad.has(r[0]):
				bad.append(r[0])
		lines.append(line)
	var text := "\n".join(lines) + "\n"
	print(text)
	var path := ProjectSettings.globalize_path("res://out/touch-targets.md")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	if not TestCheck.ok(self, bad.is_empty(), "all targets >= 48dp on tablets: %s" % [bad]): return
	# 태블릿 첫 실행 UI 크기는 100%(HUD가 다 들어가고 명령 버튼이 이미 48dp 이상)
	for i in TouchMetrics.TOUCH_DEVICES:
		var d: Array = TouchMetrics.DEVICES[i]
		if not TestCheck.ok(self, is_equal_approx(TouchMetrics.pick_ui_scale(d[1], d[2], GameSettings.UI_SCALES), 1.0), "tablet default scale %s" % d[0]): return
	print("TOUCH_TARGETS_PASS")
	quit(0)
