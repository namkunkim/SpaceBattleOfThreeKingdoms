extends SceneTree
const WORLD := "res://scenes/WorldMap.tscn"
const BATTLE := "res://scenes/FleetBattle3D.tscn"
var args := OS.get_cmdline_user_args()
var last := ""
var frame := 0
var guard_last := ""
var observed_battle := false

class Spy extends Node:
	var capture: Callable
	func _input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			capture.call(["OS_MOUSE", e.button_index, e.position])
		if e is InputEventKey and e.pressed and not e.echo:
			capture.call(["OS_KEY", e.keycode])

func _initialize() -> void:
	call_deferred("_run")

func logrow(row: Variant) -> void:
	print("P02_GUI ", var_to_str(row))

func _run() -> void:
	root.title = "P02-8 QA " + args[0]
	var spy := Spy.new()
	spy.capture = logrow
	spy.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(spy)
	change_scene_to_file(WORLD)
	await scene_changed
	root.title = "P02-8 QA " + args[0]
	var end := Time.get_ticks_msec() + 320000
	while Time.get_ticks_msec() < end:
		await process_frame
		frame += 1
		var scene := current_scene
		if scene == null:
			continue
		var key := scene.scene_file_path
		var guard := [OS.get_process_id(), DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE), root.has_focus(), root.position, root.size, root.title]
		if str(guard) != guard_last:
			guard_last = str(guard)
			logrow(["PID_HWND_FOCUS_RECT_TITLE", guard])
		root.title = "P02-8 QA " + args[0]
		var detail: Array = []
		var focus := root.gui_get_focus_owner()
		if key == WORLD:
			detail = [scene.state, scene.canvas.level(), scene._card.visible, scene._skip.visible, scene.canvas.w2s(scene.canvas.focus_pos()), scene.outcome != null]
		elif key == BATTLE and scene.sim != null:
			detail = [scene.G.state, scene.placing, scene.sim.st.seed_id, scene.sim.get_instance_id(), scene.battle_seed, scene.selected.size()]
			observed_battle = true
		var row := [key, detail, str(focus.get_path()) if focus else ""]
		if last != str(row):
			last = str(row)
			logrow(row)
			await RenderingServer.frame_post_draw
			if root.get_texture():
				root.get_texture().get_image().save_png(args[1] + "/scene-%06d.png" % frame)
		if observed_battle and key == WORLD:
			quit(0)
			return
	quit(81)


