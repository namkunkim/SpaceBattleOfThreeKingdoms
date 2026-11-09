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

func _run() -> void:
	rows = FileAccess.open(args[1], FileAccess.WRITE)
	change_scene_to_file(WORLD)
	await scene_changed
	var w := current_scene as WorldMapScreen
	var brief := BattleBrief.new()
	brief.seed = FIXED_SEED
	brief.mode = "auto"
	brief.difficulty = "표준"
	w.brief = brief
	if args[0] == "instrumented":
		OS.set_environment("P02_PROBE_MODE", "auto")
		w._start_resolve()
		record("injected_reject", [w.state, w.resolver == null, w.outcome == null, w._resolve.visible])
		check("injected-reject", w.state == "browse" and w.resolver == null and w.outcome == null and not w._resolve.visible)
	OS.set_environment("P02_PROBE_MODE", "")
	var started := Time.get_ticks_msec()
	var last := started - 5000
	w._start_resolve()
	var r := w.resolver
	record("brief", brief.to_dict())
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
