from pathlib import Path
p = Path(__file__).with_name("retry.gd")
s = p.read_text(encoding="utf-8-sig")
i=s.index("func _run() -> void:")
j=s.index("\tvar r := w.resolver",i)
s=s[:i]+'''func button_named(n: Node, label: String) -> Button:
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
'''+s[j:]
s=s.replace('record("brief", brief.to_dict())','record("brief", brief.to_dict() if brief else {})')
s=s.replace('w._cancel_resolve()','w._cancel_resolve()')
p.write_text(s,encoding="utf-8")


