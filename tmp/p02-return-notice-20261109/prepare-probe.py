from pathlib import Path
BASE = Path(__file__).resolve().parent
old = BASE.parent / "p02-pc-next2-20261109" / "return-probe-v2.gd.txt"
s = old.read_text(encoding="utf-8-sig")

def edit(old, new):
    global s
    assert s.count(old) == 1, old
    s = s.replace(old, new, 1)

edit("var transitions := 0", """var transitions := 0

func _notice(battle: Node) -> Array:
	return battle.find_children("WorldReturnNotice", "Label", true, false).filter(func(child): return child.is_visible_in_tree())

func _facts(o: BattleOutcome) -> Array:
	return [o.kind, o.win, o.limited, o.reason, o.grade, o.cao_status, o.liu_status, o.t_s, o.loss_pct, o.ending, o.line, o.fingerprint, o.seed, o.mode, o.difficulty]

func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	_check("capture-" + name, image != null and image.get_size() == Vector2i(1600, 900) and image.save_png(OS.get_environment("P02_NOTICE_CAPTURE") + "/" + name + ".png") == OK)
""")
edit('var reject := not lane.ends_with("-ok")', '''var reject := not lane.ends_with("-ok")
	var native := not OS.get_environment("P02_NOTICE_CAPTURE").is_empty()''')
edit('var expected_fingerprint: String = sim.fingerprint() if phase == "result" else ""', '''var expected_fingerprint: String = sim.fingerprint() if sim != null else ""
	var clock_before: float = sim.st.clock_s() if sim != null else 0.0
	var selected_before: Array = battle.selected.duplicate()
	var result_before: Dictionary = sim.st.result.duplicate(true) if sim != null else {}
	var paused_before := paused
	var guidance: Label = button.get_parent().get_child(2) if phase == "prepare" and button != null else null
	var reason: Label = battle.find_child("Reason", true, false) if phase == "prepare" else null
	var guidance_before := guidance.text if guidance != null else ""
	var reason_before := reason.text if reason != null else ""''')
edit('scene_changed.connect(func(): transitions += 1)', '''await process_frame
	var button_rect := button.get_global_rect()
	var focus := root.gui_get_focus_owner()
	_check("hidden", _notice(battle).is_empty())
	if native:
		await create_timer(0.35, true, false, true).timeout
		print("P02_NOTICE_RECT button ", button_rect)
		await _capture("initial")
	scene_changed.connect(func(): transitions += 1)''')
edit('var repetitions := 1 if variant == "before" else 2', 'var repetitions := 2')
start = s.index('\t\t\t\tif variant == "after":')
end = s.index('\t\t_check("restore-map"', start)
s = s[:start] + '''				_check(tag + "brief", link.brief == brief and link.routed())
				_check(tag + "queue", link.outcome == previous and previous.seed == -117)
				_check(tag + "sim", battle.selected == selected_before and paused == paused_before and (sim == null or (sim.fingerprint() == expected_fingerprint and sim.st.clock_s() == clock_before and sim.st.result == result_before)))
				_check(tag + "focus-geometry", button.get_global_rect() == button_rect and root.gui_get_focus_owner() == focus)
				_check(tag + "guidance", phase != "prepare" or (reason != null and guidance != null and reason.text == reason_before and guidance.text == guidance_before))
				_check(tag + "request", link.p02_notice_requests.size() == i + 1 and ((link.p02_notice_requests[i] is BattleOutcome) if phase == "result" else link.p02_notice_requests[i] == null))
				_check(tag + "actual-error", link.p02_notice_errors.size() == i + 1 and link.p02_notice_errors[i] == 19)
				var visible := _notice(battle)
				_check(tag + "notice", visible.size() == (1 if variant == "after" else 0))
				if variant == "after":
					var label: Label = visible[0] if visible.size() == 1 else null
					_check(tag + "layout", label != null and label.text == "천하로 돌아가지 못했습니다. 다시 눌러 주세요." and label.mouse_filter == Control.MOUSE_FILTER_IGNORE and not label.get_global_rect().intersects(button_rect) and root.get_visible_rect().encloses(label.get_global_rect()) and label.get_minimum_size().y <= label.size.y)
				if native:
					if visible.size() == 1:
						print("P02_NOTICE_RECT warning ", visible[0].get_global_rect())
					await _capture("reject-%d" % (i + 1))
''' + s[end:]
edit('if fails or variant == "before":', 'if fails:')
edit('print("P02_RETURN_ACTION accept")', '''if reject and deck != null and variant == "after":
		deck.show_screen("settings_pause" if phase == "pause" else "title")
		deck.show_screen(phase)
		_check("reentry-hidden", _notice(battle).is_empty())
	print("P02_RETURN_ACTION accept")''')
edit('var world := current_scene as WorldMapScreen', '''var world := current_scene as WorldMapScreen
	var requests: Array = link.p02_notice_requests
	var errors: Array = link.p02_notice_errors
	_check("accept-request", requests.size() == (3 if reject else 1) and errors.size() == requests.size() and errors.back() == OK)
	_check("accept-old-scene", not is_instance_valid(battle))''')
edit('_check("accept-facts", o != null', '''_check("accept-dto", o != null and o == requests.back() and (not reject or (requests.size() == 3 and requests[0] is BattleOutcome and requests[1] is BattleOutcome and requests[0] != requests[1] and requests[0] != o and requests[1] != o and _facts(requests[0]) == _facts(o) and _facts(requests[1]) == _facts(o))))
		_check("accept-facts", o != null''')
edit('else:\n\t\t_check("accept-view", world.state == "browse"', 'else:\n\t\t_check("accept-null", requests.all(func(request): return request == null))\n\t\t_check("accept-view", world.state == "browse"')
edit('var reject := not lane.ends_with("-ok")', '''var standalone := lane.begins_with("standalone-")
	var reject := not standalone and not lane.ends_with("-ok")''')
edit('["result", "pause", "prepare", "result-ok", "pause-ok", "prepare-ok"]', '["result", "pause", "prepare", "result-ok", "pause-ok", "prepare-ok", "standalone-pause", "standalone-result", "standalone-prepare"]')
edit('var phase := lane.trim_suffix("-ok")', 'var phase := lane.trim_suffix("-ok").trim_prefix("standalone-")')
edit('link.brief = brief', 'link.brief = null if standalone else brief')
edit('link.brief == brief and link.outcome == previous and link.routed()', 'link.brief == (null if standalone else brief) and link.outcome == previous and link.routed() != standalone')
edit('button.text == "천하로")', 'button.text == (("종료" if phase == "prepare" else "타이틀로") if standalone else "천하로"))')
edit('scene_changed.connect(func(): transitions += 1)', '''if standalone:
		_check("standalone-hidden", _notice(battle).is_empty())
		if phase == "prepare":
			if fails:
				_finish()
				return
			print("P02_RETURN_DONE ", checks, " ", fails)
			button.pressed.emit()
			await create_timer(2.0).timeout
			_check("standalone-quit-failed", false)
			_finish()
			return
		button.pressed.emit()
		await process_frame
		_check("standalone-title", current_scene == battle and deck.screen == "title" and battle.sim != sim and link.p02_notice_requests.is_empty() and link.outcome == previous and _notice(battle).is_empty())
		_finish()
		return
	scene_changed.connect(func(): transitions += 1)''')
(BASE / "notice-probe.gd.txt").write_text(s, encoding="utf-8")
for side in ("before", "candidate"):
    s = (BASE / f"world_link.gd.{side}.txt").read_bytes()
    nl = b"\r\n" if b"\r\n" in s else b"\n"
    for a, b in [
        (b"func routed() -> bool:", b"var p02_notice_requests: Array[BattleOutcome] = []\nvar p02_notice_errors: Array[int] = []\n\nfunc routed() -> bool:"),
        (b"\toutcome = o\n\tbrief = null", b"\tp02_notice_requests.append(o)\n\toutcome = o\n\tbrief = null"),
        (b"\tvar error := get_tree().change_scene_to_file(WORLD_SCENE)", b"\tvar error := get_tree().change_scene_to_file(WORLD_SCENE)\n\tp02_notice_errors.append(error)"),
    ]:
        a, b = (part.replace(b"\n", nl) for part in (a, b))
        assert s.count(a) == 1, a
        s = s.replace(a, b, 1)
    (BASE / f"world_link.gd.{side}.fixture.txt").write_bytes(s)


