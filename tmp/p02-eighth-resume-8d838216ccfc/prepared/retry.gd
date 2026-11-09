extends SceneTree

const WORLD := "res://scenes/WorldMap.tscn"
const FIXED_SEED := -27182818
const OBSERVATION_DEADLINE_MS := 600000
var args := OS.get_cmdline_user_args()
var rows: FileAccess
var fail_count := 0

func _initialize() -> void:
	call_deferred("_run")

func record(name: String, payload: Variant) -> void:
	rows.store_line(name + " " + var_to_str(payload))
	rows.flush()

func check(name: String, value: bool) -> void:
	print("ASSERT ", name, " ", value)
	if not value:
		fail_count += 1

func button_named(n: Node, label: String) -> Button:
	if n is Button and n.text == label:
		return n
	for child in n.get_children():
		var found := button_named(child, label)
		if found:
			return found
	return null

func click(button: Button, label: String) -> void:
	await process_frame
	var enabled := button != null and button.is_visible_in_tree() and not button.disabled
	check(label + "/enabled", enabled)
	if not enabled:
		return
	var pos := button.get_global_rect().get_center()
	var count := [0]
	button.pressed.connect(func(): count[0] += 1, CONNECT_ONE_SHOT)
	record(label + "/input", ["VIEWPORT_MOUSE", str(button.get_path()), pos])
	for down in [true, false]:
		var e := InputEventMouseButton.new()
		e.position = pos
		e.global_position = pos
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		root.push_input(e, true)
	check(label + "/pressed", count[0] == 1)

func run_sortie(w: WorldMapScreen, label: String) -> void:
	var cta := button_named(w._cta, "적벽으로")
	if not w._card.visible and cta == null:
		w.open_card()
	elif not w._card.visible:
		await click(cta, label + "/open")
	for frame in range(240):
		if w._card.visible:
			break
		await process_frame
	await click(w._mode_btns.auto, label + "/mode")
	await click(w._diff_btns["표준"], label + "/difficulty")
	await click(button_named(w._card, "출  격"), label + "/sortie")
	check(label + "/brief-created", w.state == "sortie" and w.brief != null and w.brief.mode == "auto" and w.brief.difficulty == "표준")
	if w.brief == null or w.state != "sortie":
		return
	var before := w.brief.to_dict()
	w.brief.seed = FIXED_SEED
	var after := w.brief.to_dict()
	record(label + "/brief-before-after-fixture", [before, after])
	before.seed = FIXED_SEED
	check(label + "/fixture-seed-only", var_to_bytes(before) == var_to_bytes(after) and w.brief.validate() == "")
	await click(w._skip, label + "/skip")

func _run() -> void:
	rows = FileAccess.open(args[1], FileAccess.WRITE)
	change_scene_to_file(WORLD)
	await scene_changed
	var w := current_scene as WorldMapScreen
	var first := {}
	var factory: Script = load("res://core/battle/operation_runtime_adapter.gd")
	if args[0] == "instrumented":
		OS.set_environment("P02_PROBE_MODE", "auto")
		await run_sortie(w, "injected")
		if w.brief != null:
			first = w.brief.to_dict()
		var counts := [factory.get("probe_enter"), factory.get("probe_ctor"), factory.get("probe_thread")]
		record("injected-reject", [counts, w.state, w.resolver == null, w.outcome == null, w._resolve.visible, w._chip.visible, w._chip_label.text, factory.get("probe_profile"), factory.get("probe_seed")])
		check("injected-reject", counts == [1,0,0] and w.state == "browse" and w.resolver == null and w.outcome == null and not w._resolve.visible and w._chip.visible and w._chip_label.text == "자동 해결을 시작하지 못했다: unsupported_mode at mode")
		check("injected-valid-profile", var_to_bytes(factory.get("probe_profile")) == var_to_bytes(w.brief.profile()) and factory.get("probe_seed") == FIXED_SEED)
		for k in ["probe_enter", "probe_ctor", "probe_thread"]:
			factory.set(k, 0)
	OS.set_environment("P02_PROBE_MODE", "")
	await run_sortie(w, "terminal")
	var started := Time.get_ticks_msec()
	var last := started - 5000
	var brief := w.brief
	if args[0] == "instrumented":
		check("retry-same-brief", brief != null and var_to_bytes(brief.to_dict()) == var_to_bytes(first))
		check("retry-start-counts", [factory.get("probe_enter"),factory.get("probe_ctor"),factory.get("probe_thread")] == [1,1,1])
	var r := w.resolver
	record("brief", brief.to_dict() if brief else {})
	check("started", w.state == "resolve" and r != null and r._thread != null and r._thread.is_started())
	if r == null:
		quit(2)
		return
	var result_visibility := [0]
	w._result.visibility_changed.connect(func():
		if w._result.visible:
			result_visibility[0] += 1)
	while w.state == "resolve":
		var now := Time.get_ticks_msec()
		if now - last >= 5000:
			last = now
			record("progress", [now - started, r.clock_s(), r._thread != null and r._thread.is_alive(), w.state, w._result.visible])
		if now - started >= OBSERVATION_DEADLINE_MS:
			record("deadline", [now - started, r.clock_s(), r._thread != null and r._thread.is_alive(), w.state])
			w._cancel_resolve()
			record("cancel_join", [r._thread == null, w.state])
			quit(1)
			return
		await process_frame
	record("completion_timing", Time.get_ticks_msec() - started)
	var o := w.outcome
	check("joined", w.state == "result" and r._thread == null and w.resolver == null and r.outcome == o and o != null)
	check("one-visible-outcome", result_visibility[0] == 1 and w._result.visible)
	if o != null and r._thread == null:
		record("terminal", [r.sim.st.tick, r.sim.st.clock_ms, r.sim.fingerprint(), o.to_dict(), result_visibility[0]])
		check("poll-idempotent", r.poll() and r.poll() and r.outcome == o and result_visibility[0] == 1)
	rows.close()
	quit(0 if fail_count == 0 else 1)

