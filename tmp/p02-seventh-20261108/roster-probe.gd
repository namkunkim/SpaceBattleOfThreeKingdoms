extends SceneTree
const BATTLE := "res://scenes/FleetBattle3D.tscn"
var output: String

func _initialize() -> void:
	output = OS.get_cmdline_user_args()[1]
	call_deferred("_run")

func _run() -> void:
	var b := load(BATTLE).instantiate() as Node
	root.add_child(b)
	b.set_process(false)
	var initial := b.get_node_or_null("BattlePrepareError") == null
	var sim: BattleSim = b.sim
	var rows := []
	var first_layer: CanvasLayer
	for path in ["profile", "profile.ally", "profile.foe", "profile.foe"]:
		b.profile_patch = func(profile: Dictionary):
			if path == "profile":
				profile.clear()
			else:
				profile[path.get_slice(".", 1)] = 1
		var result: Dictionary = b.init_game()
		var layer := b.get_node_or_null("BattlePrepareError") as CanvasLayer
		if rows.is_empty():
			first_layer = layer
		var reason := layer.find_child("Reason", true, false) as Label if layer else null
		rows.append({"path":path,"result":result,"same_sim":sim == b.sim,"same_layer":first_layer == layer,"layer":layer != null,"text":reason.text if reason else ""})
	b.profile_patch = Callable()
	var recover: Dictionary = b.init_game()
	var shown := b.get_node_or_null("BattlePrepareError") as CanvasLayer
	var immediate := shown == null or not shown.visible
	await process_frame
	var clear := b.get_node_or_null("BattlePrepareError") == null
	var f := FileAccess.open(output, FileAccess.WRITE)
	f.store_line(JSON.stringify({"initial_clear":initial,"rows":rows,"recovery":recover,"immediate_clear":immediate,"cleared":clear}))
	f.close()
	b.free()
	quit(0)
