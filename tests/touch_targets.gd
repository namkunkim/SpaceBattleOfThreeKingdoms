extends SceneTree

# 터치 목표 크기 점검(헤드리스). 전투 HUD의 누를 수 있는 컨트롤을 모아 기준 기기별 dp를 계산하고
# out/touch-targets.md에 표로 남긴다. 명령 버튼은 폰에서 UI 크기 130%일 때 48dp 이상이어야 한다.

func _initialize() -> void:
	call_deferred("_run")

func _collect(n: Node, out: Array) -> void:
	if n is BaseButton and (n as Control).is_visible_in_tree():
		out.append(n)
	for c in n.get_children():
		_collect(c, out)

func _name(c: Control) -> String:
	if "cmd" in c:
		return "명령 · " + c.cmd.label
	if c is DeckWidgets.GroupButton:
		return "그룹 탭"
	if c is DeckWidgets.TabButton:
		return "명령 탭 · " + str(c.get_meta("label"))
	if c is DeckWidgets.IconButton:
		return "시스템 · " + (c.tooltip_text.split(" (")[0] if c.tooltip_text != "" else c.caption)
	return c.get_class()

func _mark(dp: float) -> String:
	return ("%d" if dp >= TouchMetrics.MIN_DP else "⚠%d") % roundi(dp)

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	deck.begin_battle()
	for i in 4:
		await process_frame
	var btns := []
	_collect(deck.hud, btns)
	var seen := {}
	var rows := []
	for b in btns:
		var key := _name(b)
		if seen.has(key):
			continue
		seen[key] = true
		rows.append([key, b.size])
	var phone: Array = TouchMetrics.DEVICES[0]
	var lines := ["# 터치 목표 크기 점검", "", "기준 %d dp. 값은 짧은 변의 dp(UI 크기 100%% / 130%%)." % int(TouchMetrics.MIN_DP), ""]
	var head := "| 컨트롤 | 크기(단위) |"
	var sep := "|---|---|"
	for d in TouchMetrics.DEVICES:
		head += " %s |" % d[0]
		sep += "---|"
	lines.append(head)
	lines.append(sep)
	var cmd_ok := true
	for r in rows:
		var sz: Vector2 = r[1]
		var short := minf(sz.x, sz.y)
		var line := "| %s | %d×%d |" % [r[0], roundi(sz.x), roundi(sz.y)]
		for d in TouchMetrics.DEVICES:
			var a := short * TouchMetrics.dp_per_unit(d[1], d[2], 1.0)
			var b := short * TouchMetrics.dp_per_unit(d[1], d[2], 1.3)
			line += " %s / %s |" % [_mark(a), _mark(b)]
		lines.append(line)
		if str(r[0]).begins_with("명령 ·") and short * TouchMetrics.dp_per_unit(phone[1], phone[2], 1.3) < TouchMetrics.MIN_DP:
			cmd_ok = false
	var text := "\n".join(lines) + "\n"
	print(text)
	var path := ProjectSettings.globalize_path("res://out/touch-targets.md")
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
	if not TestCheck.ok(self, cmd_ok, "command buttons >= 48dp on phone at 130%"): return
	# 첫 실행 UI 크기: 폰(가로가 긴 화면)은 130%, 4:3 태블릿은 HUD가 들어가는 100%
	var s_phone := TouchMetrics.pick_ui_scale(phone[1], phone[2], GameSettings.UI_SCALES)
	var s_tab := TouchMetrics.pick_ui_scale(TouchMetrics.DEVICES[1][1], TouchMetrics.DEVICES[1][2], GameSettings.UI_SCALES)
	if not TestCheck.ok(self, is_equal_approx(s_phone, 1.3) and is_equal_approx(s_tab, 1.0), "default ui scale phone %.2f tablet %.2f" % [s_phone, s_tab]): return
	print("TOUCH_TARGETS_PASS")
	quit(0)
