extends SceneTree
const WORLD := "res://scenes/WorldMap.tscn"
const BATTLE := "res://scenes/FleetBattle3D.tscn"
var args := OS.get_cmdline_user_args()
var action_key := false

class Spy extends Node:
	var capture: Callable
	func _input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			capture.call(["GODOT_MOUSE", e.button_index, e.pressed, e.position])
		if e is InputEventKey and not e.echo:
			capture.call(["GODOT_KEY", e.keycode, e.pressed])

func _initialize() -> void:
	call_deferred("_run")

func record(row: Variant) -> void:
	print("P02_GUI ", var_to_str([Time.get_ticks_usec(), Time.get_unix_time_from_system(), row]))

func _run() -> void:
	var title := "P02-8 QA " + args[0]
	root.title = title
	var spy := Spy.new()
	spy.capture = func(row):
		if row[0] == "GODOT_KEY" and row[1] == KEY_2 and row[2]:
			action_key = true
		record(row)
	spy.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(spy)
	change_scene_to_file(WORLD)
	await scene_changed
	var end := Time.get_ticks_msec() + 450000
	var last := ""
	var frame := 0
	var first_sim := 0
	var restart := false
	var placed_commands := 0
	var selected_by_key := false
	var placed := false
	var link := root.get_node("WorldLink")
	while Time.get_ticks_msec() < end:
		await process_frame
		frame += 1
		var scene := current_scene
		if scene == null:
			continue
		root.title = title
		var key := scene.scene_file_path
		var detail: Array = []
		var focus := root.gui_get_focus_owner()
		if key == WORLD:
			detail = [scene.state, scene.canvas.level(), scene._card.visible, scene._skip.visible, scene.outcome != null]
		elif key == BATTLE and scene.sim != null:
			var sim_id: int = scene.sim.get_instance_id()
			if first_sim == 0:
				first_sim = sim_id
			restart = restart or sim_id != first_sim
			placed = placed or scene.placing
			var commands: Array = scene.sim.command_log
			if scene.placing:
				placed_commands = maxi(placed_commands, commands.size())
			var ids := SelectionSet.ids(scene.selected)
			selected_by_key = selected_by_key or (action_key and not ids.is_empty() and ids == scene.groups.get(2, []))
			detail = [scene.G.state, scene.placing, scene.battle_seed, sim_id, ids, commands.size(), scene.presentation.hud.screen]
		var native := [OS.get_process_id(), DisplayServer.window_get_native_handle(DisplayServer.WINDOW_HANDLE), root.has_focus(), root.position, root.size, root.title]
		var row := [native, key, detail, str(focus.get_path()) if focus else ""]
		if last != str(row):
			last = str(row)
			record(row)
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if image != null:
				record(["capture", frame, image.save_png(args[1] + "/scene-%06d.png" % frame)])
		if args[2] == "gui-mouse" and key == BATTLE and placed and not scene.placing and placed_commands > 0:
			record(["ASSERT", "mouse-placement-observed", true])
			quit(0)
			return
		if args[2] == "gui-key" and key == WORLD and selected_by_key and restart and link.brief == null and link.outcome == null and scene.outcome == null:
			record(["ASSERT", "key-selection-and-mouse-restart-return-observed", true])
			quit(0)
			return
	quit(81)
