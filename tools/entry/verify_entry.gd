extends SceneTree
const Flow = preload("res://scripts/entry/entry_flow.gd")
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var f = Flow.new()
	f.begin("new")
	check(not f.act("start", f.revision, "locked"), "scenario request lock")
	check(f.act("start", f.revision), "start story")
	var old: int = f.revision
	check(f.act("next", old) and not f.act("next", old), "stale double next")
	check(Flow.Prologue.PAGES.size() == 8, "eight story chapters")
	for chapter in range(1, Flow.Prologue.PAGES.size()):
		check(f.state == Flow.State.STORY and f.page == chapter, "story chapter %d" % (chapter + 1))
		f.act("next", f.revision)
	check(f.state == Flow.State.MAP, "full story to map")
	check(not f.act("enter", f.revision, "locked"), "region request lock")
	f.act("enter", f.revision)
	check(not f.act("enter", f.revision), "modal background blocked")
	check(not f.act("escape", f.revision), "escape does not quit")
	old = f.revision
	check(f.act("yes", old) and not f.act("no", old), "yes/no first wins")
	check(not f.act("yes", f.revision), "loading duplicate blocked")
	check(f.loaded(f.revision, false, "fixture"), "load failure")
	f.act("retry", f.revision)
	check(f.loaded(f.revision, true) and f.state == Flow.State.READY, "retry ready")
	check(not f.loaded(f.revision, true), "duplicate completion blocked")
	for origin in ["resume", "settlement"]:
		var bypass = Flow.new()
		bypass.begin(origin)
		check(bypass.state == Flow.State.BYPASS and not bypass.act("start", bypass.revision), origin + " bypass")
	var screen = load("res://scenes/entry/NewEntry.tscn").instantiate()
	screen.auto_prompt_seconds = 0.3
	root.add_child(screen)
	await process_frame
	check(screen.flow.state == Flow.State.SELECT, "scene boots select")
	var home_token: int = screen.flow.revision
	var home_focus: Control = root.gui_get_focus_owner()
	check(screen.buttons.size() == 2 and screen.buttons[0].text == "적벽대전 시작"
		and screen.buttons[1].text == "설정", "fresh home shows start and settings")
	check(screen.request("settings", home_token) and not screen.body.visible, "settings overlays home")
	check(not screen.request("start", home_token), "settings blocks launcher actions")
	screen._settings_overlay.closed.emit()
	check(screen.body.visible and screen.flow.revision == home_token
		and root.gui_get_focus_owner() == home_focus, "settings restores home and focus")
	screen.request("start", screen.flow.revision)
	var story_map: Control = screen.find_child("PrologueAtlas", true, false)
	check(story_map != null and story_map.prepared and story_map.story_focus == Flow.Prologue.PAGES[0][2],
		"first story chapter mounts and highlights strategy atlas")
	await create_timer(0.3).timeout
	screen.request("skip", screen.flow.revision)
	await create_timer(0.4).timeout
	check(screen.flow.state == Flow.State.CONFIRM, "auto prompt after map")
	await create_timer(0.3).timeout
	screen.detail_scene = "res://missing.tscn"
	screen.request("yes", screen.flow.revision)
	await process_frame
	await process_frame
	check(screen.flow.state == Flow.State.ERROR, "real loader failure UI")
	screen.detail_scene = "res://scenes/entry/PreparedMap.tscn"
	await create_timer(0.3).timeout
	screen.request("retry", screen.flow.revision)
	await process_frame
	await process_frame
	check(screen.flow.state == Flow.State.READY and screen.prepared_count == 1, "real detail prepared once")
	check(screen.find_child("PreparedMap", true, false) != null, "detail map mounted")
	screen.queue_free()
	await process_frame
	var n = Flow.new()
	n.begin("new")
	n.act("start", n.revision)
	n.act("skip", n.revision)
	n.act("enter", n.revision)
	check(n.act("no", n.revision) and n.state == Flow.State.EXIT, "no exit")
	var err = Flow.new()
	err.begin("new")
	err.act("start", err.revision)
	err.act("skip", err.revision)
	err.act("enter", err.revision)
	err.act("yes", err.revision)
	err.loaded(err.revision, false)
	check(err.act("exit", err.revision), "error exit")
	print("ENTRY_RESULT checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)

