extends SceneTree
const WORLD := "res://scenes/WorldMap.tscn"
const RNG_INPUT := 27182818
var args := OS.get_cmdline_user_args()
var w: WorldMapScreen
var rows: Array[Dictionary] = []
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(label: String, ok: bool, details: Dictionary = {}) -> void:
	rows.append({"assertion":label,"ok":ok,"details":details})
	if not ok:
		failures += 1
	var f := FileAccess.open(args[1], FileAccess.WRITE)
	f.store_line(JSON.stringify(rows))
	f.close()

func button_named(n: Node, label: String) -> Button:
	if n is Button and n.text == label:
		return n
	for child in n.get_children():
		var found := button_named(child, label)
		if found:
			return found
	return null

func click(b: Button, label: String, fixed_rng := false) -> void:
	await process_frame
	await process_frame
	var enabled := b != null and b.is_visible_in_tree() and not b.disabled
	check(label + "-control", enabled, {"path":str(b.get_path()) if b else "", "rect":str(b.get_global_rect()) if b else ""})
	if not enabled:
		return
	var counter := [0]
	b.pressed.connect(func(): counter[0] += 1, CONNECT_ONE_SHOT)
	var pos := b.get_global_rect().get_center()
	if fixed_rng:
		seed(RNG_INPUT)
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = pos
		e.global_position = pos
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		root.push_input(e, true)
	check(label + "-pressed-once", counter[0] == 1)

func _run() -> void:
	change_scene_to_file(WORLD)
	await scene_changed
	w = current_scene as WorldMapScreen
	check("world-real-scene", w != null and w.scene_file_path == WORLD)
	for _i in 6:
		await process_frame
	var mark := w.canvas.w2s(w.canvas.focus_pos())
	for down in [true, false]:
		var event := InputEventScreenTouch.new()
		event.index = 0
		event.position = mark
		event.pressed = down
		root.push_input(event, true)
	await create_timer(1.7).timeout
	check("world-product-marker-card", w._card.visible and w.canvas.level() == "z2", {"marker":str(mark),"level":w.canvas.level(),"viewport":str(root.get_visible_rect())})
	await click(w._mode_btns.auto, "mode-auto")
	await click(w._diff_btns["표준"], "standard")
	seed(RNG_INPUT)
	var expected_seed := randi() % 1000000
	seed(RNG_INPUT)
	await click(button_named(w._card, "출  격"), "sortie", true)
	check("sortie-brief", w.state == "sortie" and w.brief != null and w.brief.mode == "auto" and w.brief.seed == expected_seed and w.brief.difficulty == "표준", {"brief":w.brief.to_dict() if w.brief else {}})
	await click(w._skip, "skip")
	var resolver: AutoResolver = w.resolver
	check("resolver-start", w.state == "resolve" and resolver != null and resolver._thread != null and resolver._thread.is_started() and resolver.brief == w.brief, {"resolve_visible":w._resolve.visible})
	if resolver == null:
		quit(2)
		return
	var visible_count := [0]
	w._result.visibility_changed.connect(func():
		if w._result.visible:
			visible_count[0] += 1)
	if args[0] == "cancel":
		await click(button_named(w._resolve, "중단하고 돌아가기"), "stop")
		var poll := [resolver.poll(), resolver.poll()]
		check("cancel-join", resolver._thread == null and resolver._cancel and poll == [false, false] and w.resolver == null and w.outcome == null and resolver.outcome == null and w.state == "browse" and w._card.visible and not w._result.visible and not w._resolve.visible and visible_count[0] == 0,
			{"thread_joined":resolver._thread == null, "cancelled":resolver._cancel, "poll":poll, "resolver_released":w.resolver == null,
			"screen_outcome":w.outcome.to_dict() if w.outcome else null, "resolver_outcome":resolver.outcome.to_dict() if resolver.outcome else null,
			"state":w.state, "card_visible":w._card.visible, "result_visible":w._result.visible, "resolve_visible":w._resolve.visible, "show_count":visible_count[0]})
	else:
		var deadline := Time.get_ticks_msec() + 175000
		while w.state == "resolve" and Time.get_ticks_msec() < deadline:
			await process_frame
		var result := w.outcome
		await process_frame
		await process_frame
		var fingerprint: String = resolver.sim.fingerprint()
		check("result-join", resolver._thread == null and resolver.outcome == result and result != null and w.resolver == null and w.state == "result" and w._result.visible and not w._resolve.visible and visible_count[0] == 1, {"outcome":result.to_dict() if result else {}, "fingerprint":fingerprint,"show_count":visible_count[0]})
		var poll := [resolver.poll(), resolver.poll()]
		check("poll-idempotent", poll == [true,true] and resolver.outcome == result and w.outcome == result and visible_count[0] == 1,
			{"thread_joined":resolver._thread == null, "resolver_released":w.resolver == null, "state":w.state,
			"result_visible":w._result.visible, "resolve_visible":w._resolve.visible, "poll":poll, "show_count":visible_count[0]})
	quit(0 if failures == 0 else 1)

