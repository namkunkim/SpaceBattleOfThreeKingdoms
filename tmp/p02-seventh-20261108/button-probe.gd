extends SceneTree

const BATTLE := "res://scenes/FleetBattle3D.tscn"
const LANES := ["03-confirm", "04-auto", "05-repair", "06-restart", "07-title", "08-legacy"]
const BUTTONS := ["확정 · 출격", "자동 편성으로 시작", "편  성", "다시 출격", "타이틀로", "처음부터"]
var report_path: String
var lane := 0
var battle: Node
var deck: Node
var old: Dictionary
var target: Button

class InputSpy extends Node:
	var report: Callable
	func _input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			report.call({"phase":"os-input","type":"mouse","code":e.button_index,"x":e.position.x,"y":e.position.y})

func _initialize() -> void:
	report_path = OS.get_cmdline_user_args()[1]
	call_deferred("_begin")

func _begin() -> void:
	var spy := InputSpy.new()
	spy.report = write_row
	root.add_child(spy)
	scene_changed.connect(_setup)
	change_scene_to_file(BATTLE)
	create_timer(250).timeout.connect(func(): quit(81))

func _setup() -> void:
	battle = current_scene
	battle.set_process(false)
	deck = battle.presentation.hud
	_prepare.call_deferred()

func _prepare() -> void:
	root.title = "P02-7 Buttons " + LANES[lane]
	battle.profile_patch = Callable()
	battle.org = {}
	battle.init_game()
	deck.show_screen("brief")
	var o: Node = deck.screens.org
	match lane:
		0:
			o.open_org()
			target = o.confirm
		1:
			target = button_named(deck.screens.brief, BUTTONS[lane])
		2:
			o.open_org()
			battle.org = o.org.duplicate(true)
			battle.org.fleets[0].admiral = "invalid_admiral"
			battle.init_game()
			deck.show_screen("brief")
			target = button_named(deck.screens.brief, BUTTONS[lane])
		3, 4:
			deck.show_screen("result")
			target = button_named(deck.screens.result, BUTTONS[lane])
		5:
			battle.presentation.get_node("CommandDeckLayer").hide()
			(battle.ui.get_parent() as CanvasLayer).show()
			battle.hud.menu_ov.show()
			target = button_named(battle.hud.menu_ov, BUTTONS[lane])
	if not is_instance_valid(target):
		write_row({"phase":"setup-error","lane":LANES[lane],"button":BUTTONS[lane]})
		quit(82)
		return
	battle.profile_patch = func(profile: Dictionary): profile.clear()
	await process_frame
	await process_frame
	old = snapshot()
	target.pressed.connect(_observed, CONNECT_ONE_SHOT)
	write_row({"phase":"ready","lane":LANES[lane],"path":str(target.get_path()),"text":target.text,"visible":target.is_visible_in_tree(),"enabled":not target.disabled,"rect":str(target.get_global_rect()),"repair_errors":battle.org_errors.size()})

func snapshot() -> Dictionary:
	return {"sim":battle.sim.get_instance_id(),"tick":battle.sim.st.tick,"org":battle.org.duplicate(true),"state":battle.G.state,"selected":battle.selected.duplicate(),"events":battle.sim._events.duplicate(true)}

func _observed() -> void:
	var warning := battle.get_node_or_null("BattlePrepareError") as CanvasLayer
	var now := snapshot()
	var differences := []
	for key in old:
		if old[key] != now[key]:
			differences.append(key)
	write_row({"phase":"button","lane":LANES[lane],"path":str(target.get_path()),"warning":warning != null and warning.visible,"differences":differences})
	lane += 1
	if lane == LANES.size():
		quit(0)
	else:
		_prepare.call_deferred()

func button_named(n: Node, label: String) -> Button:
	if n is Button and n.text == label:
		return n
	for child in n.get_children():
		var found := button_named(child, label)
		if found:
			return found
	return null

func write_row(row: Dictionary) -> void:
	var mode := FileAccess.READ_WRITE if FileAccess.file_exists(report_path) else FileAccess.WRITE
	var f := FileAccess.open(report_path, mode)
	f.seek_end()
	f.store_line(JSON.stringify(row))
	f.close()
	print("P02_7 ", JSON.stringify(row))
