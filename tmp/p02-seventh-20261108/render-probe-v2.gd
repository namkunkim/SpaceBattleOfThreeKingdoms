extends SceneTree

const BATTLE := "res://scenes/FleetBattle3D.tscn"
var lane := ""
var link: Node
var active: Node
var phase := 0
var report_path := ""

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	lane = args[0]
	report_path = args[1]
	call_deferred("_begin")

func _begin() -> void:
	get_root().title = "P02-7 Godot QA " + lane
	link = root.get_node("WorldLink")
	node_added.connect(_inject)
	scene_changed.connect(_scene_changed)
	if lane == "routed":
		var brief := BattleBrief.new()
		brief.seed = 747
		brief.difficulty = "표준"
		brief.mode = "auto"
		link.go_battle(brief)
	else:
		change_scene_to_file(BATTLE)
	create_timer(12).timeout.connect(func(): quit(81))

func _inject(n: Node) -> void:
	if n.scene_file_path == BATTLE:
		active = n
		if lane in ["routed", "standalone"]:
			active.profile_patch = func(profile: Dictionary): profile.clear()

func _scene_changed() -> void:
	if current_scene == active:
		observe.call_deferred("initial")
		if lane != "live":
			capture.call_deferred("initial")
		if lane == "live":
			active.profile_patch = func(profile: Dictionary): profile["foe"] = 1
			active.init_game()
			observe.call_deferred("live-warning")
			capture.call_deferred("live-warning")
			create_timer(4).timeout.connect(_recover)
	else:
		write_row({"phase":"return", "scene":current_scene.scene_file_path, "brief_null":link.brief == null, "outcome_null":link.outcome == null, "last_difficulty":link.last_difficulty, "last_mode":link.last_mode})
		quit(0)

func _recover() -> void:
	active.profile_patch = Callable()
	var result: Dictionary = active.init_game()
	write_row({"phase":"recover-result", "result":result})
	observe("recover")
	capture("recover")

func observe(label: String) -> void:
	var layer := active.get_node_or_null("BattlePrepareError") as CanvasLayer
	var focus := root.gui_get_focus_owner()
	write_row({"phase":label, "layer":layer != null and layer.visible, "sim":active.sim != null, "presentation":active.presentation != null, "host_process":active.is_processing(), "legacy_visible":active.ui.get_parent().visible, "focus":str(focus.get_path()) if focus else ""})

func write_row(row: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(report_path) else FileAccess.WRITE
	var f := FileAccess.open(report_path, mode)
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()
	print("P02_7 ", JSON.stringify(row))

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	write_row({"phase":"capture","label":label,"width":img.get_width(),"height":img.get_height(),"save":img.save_png(report_path.get_base_dir().path_join(label + ".png"))})
	if label == "recover":
		quit(0)

