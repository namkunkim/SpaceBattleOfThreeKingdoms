extends SceneTree
const Screens = preload("res://hud/ui_kit/deck_screens.gd")
const Alternative = preload("res://view/world/world_atlas_f_alternative.gd")
var failures := 0
var checks := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)
func buttons(n: Node) -> Array:
	var out: Array = []
	for child in n.get_children():
		if child is Button: out.append(child.text)
		out.append_array(buttons(child))
	return out
func _initialize() -> void:
	run.call_deferred()
func run() -> void:
	var deck := Control.new()
	var title = Screens.TitleScreen.new(deck)
	check(buttons(title).has("함대 도감") and buttons(title).has("천하 지도"), "title retains catalog and E campaign entry")
	var col: VBoxContainer = title.get_child(0)
	check(col.position.y + col.get_combined_minimum_size().y <= 870, "title menu fits 900px design height")
	var notice := Screens.world_return_notice()
	var pause = Screens.PauseScreen.new(deck, notice)
	check(buttons(pause).has("함대 도감") and buttons(pause).size() == 6, "pause retains six actions")
	var panel: Control = pause.get_child(0)
	var menu: VBoxContainer = panel.get_child(0)
	check(menu.position.y + menu.get_combined_minimum_size().y <= notice.position.y, "pause buttons do not overlap failure notice")
	check(notice.position.y + notice.size.y <= 580, "failure notice stays inside panel")
	check(not notice.visible, "failure notice initially hidden")
	var alt = Alternative.new()
	alt.configure({"systems": [], "routes": []})
	check(buttons(alt).has("좌표 보기"), "F coordinate UI instantiates")
	check(alt._map_art != null and alt._coordinate_systems.size() > 0, "F renderer and coordinate data connect")
	check(alt._zoom == 1.0 and alt.MAX_ZOOM == 4.0, "F zoom bounds preserved")
	alt.free()
	pause.free()
	title.free()
	deck.free()
	print("EF_MERGE_UI checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
