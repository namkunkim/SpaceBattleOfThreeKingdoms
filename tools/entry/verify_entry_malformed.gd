extends SceneTree
const Map = preload("res://scripts/entry/entry_map.gd")
const Check = preload("res://scripts/entry/entry_map_data.gd")
const OP := "res://data/scenarios/p05_p07_first_operation_dev_v1.json"
const ATLAS := "res://data/galaxy_navigation.json"
var failures := 0
var checks := 0
var emissions := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	if not ProjectSettings.globalize_path("res://").replace("\\", "/").begins_with("F:/WorkSpace/new-entry-fix-20261111-"):
		printerr("Fixture mutations require an isolated F follow-up project.")
		quit(2)
		return
	root.size = Vector2i(1280, 720)
	var originals := {OP: FileAccess.get_file_as_string(OP), ATLAS: FileAccess.get_file_as_string(ATLAS)}
	# [detail, field path, replacement]; "__REMOVE__" removes the field.
	var cases := [
		[true, ["space"], null],
		[true, ["space", "size"], [0,1150]],
		[true, ["space", "size"], [-1,1150]],
		[true, ["space", "size"], [1700]],
		[true, ["space", "size"], ["1700",1150]],
		[true, ["space", "nodes"], []],
		[true, ["space", "nodes", "R"], "__REMOVE__"],
		[true, ["space", "nodes", "E"], [1]],
		[true, ["space", "nodes", "J"], [true,2]],
		[true, ["space", "nodes", "A"], [-1,20]],
		[true, ["space", "nodes", "C"], [1701,20]],
		[true, ["space", "routes"], []],
		[true, ["space", "routes", "front"], "__REMOVE__"],
		[true, ["space", "routes", "front"], []],
		[true, ["space", "routes", "front", "nodes"], "__REMOVE__"],
		[true, ["space", "routes", "front", "nodes"], []],
		[true, ["space", "routes", "front", "nodes"], ["E","unknown"]],
		[true, ["space", "routes", "front", "nodes"], ["E",1]],
		[true, ["space", "routes", "front", "nodes"], ["E","E"]],
		[false, ["width"], "__REMOVE__"],
		[false, ["height"], "__REMOVE__"],
		[false, ["width"], "1600"],
		[false, ["height"], 0],
		[false, ["height"], true],
		[false, ["points"], {}],
		[false, ["points", 0], null],
		[false, ["points", 0, "position"], [1]],
		[false, ["points", 0, "kind"], "__REMOVE__"],
		[false, ["regions"], []],
		[false, ["regions", 0, "position"], [0,901]],
		[false, ["regions", 0, "name"], null],
		[false, ["regions", 4, "name"], "다른 권역"],
		[false, ["routes"], {}],
		[false, ["routes", 0], null],
		[false, ["routes", 0, "points"], "__REMOVE__"],
		[false, ["routes", 0, "points"], [[1,2]]],
		[false, ["routes", 0, "points"], [[1,2],["3",4]]]
	]
	for index in range(cases.size()):
		var fixture: Array = cases[index]
		var path: String = OP if fixture[0] else ATLAS
		var broken: Dictionary = JSON.parse_string(originals[path])
		var parent: Variant = broken
		var keys: Array = fixture[1]
		for key: Variant in keys.slice(0, -1): parent = parent[key]
		if fixture[2] is String and fixture[2] == "__REMOVE__":
			parent.erase(keys[-1])
		else:
			parent[keys[-1]] = fixture[2]
		var map := Map.new()
		map.detailed = fixture[0]
		check(map.prepare(), "%02d valid initial prepare" % index)
		write_text(path, JSON.stringify(broken))
		check(not map.prepare() and not map.prepared and map.data.is_empty() and map.sky == null and map.terrain == null and not map.failure.is_empty(), "%02d atomic rejection" % index)
		map.free()
		var screen = load("res://scenes/entry/NewEntry.tscn").instantiate()
		screen.auto_prompt_seconds = 10.0
		emissions = 0
		screen.detail_prepared.connect(func(_context): emissions += 1)
		root.add_child(screen)
		screen.flow.act("start", screen.flow.revision)
		screen.flow.act("skip", screen.flow.revision)
		if fixture[0]:
			screen.flow.act("enter", screen.flow.revision)
			screen.flow.act("yes", screen.flow.revision)
		screen._render()
		await process_frame
		await process_frame
		await process_frame
		check(screen.flow.state == screen.Flow.State.ERROR and screen.prepared_count == 0 and emissions == 0 and screen.buttons.size() == 2 and not screen.flow.error.is_empty(), "%02d ERROR retry/exit no signal" % index)
		write_text(path, originals[path])
		check(screen.request("retry", screen.flow.revision), "%02d retry accepted" % index)
		await process_frame
		await process_frame
		if not fixture[0]:
			screen.gate_remaining = 0
			screen.request("enter", screen.flow.revision)
			screen.gate_remaining = 0
			screen.request("yes", screen.flow.revision)
			await process_frame
			await process_frame
		check(screen.flow.state == screen.Flow.State.READY and screen.prepared_count == 1 and emissions == 1, "%02d recovered READY signal once" % index)
		screen.queue_free()
		await process_frame
	# Non-JSON numeric edge cases exercise validator without serialization coercion.
	for number in [INF, -INF, NAN, 1e100]:
		var invalid: Dictionary = JSON.parse_string(originals[OP])
		invalid.space.size[0] = number
		check(not Check.validate(invalid, true).is_empty(), "nonfinite/unrepresentable dimension")
	# Real error-screen exit, after restoring the fixture first.
	var broken: Dictionary = JSON.parse_string(originals[OP])
	broken.space.routes.erase("front")
	write_text(OP, JSON.stringify(broken))
	var last = load("res://scenes/entry/NewEntry.tscn").instantiate()
	root.add_child(last)
	last.flow.act("start", last.flow.revision)
	last.flow.act("skip", last.flow.revision)
	last.flow.act("enter", last.flow.revision)
	last.flow.act("yes", last.flow.revision)
	last._render()
	await process_frame
	await process_frame
	write_text(OP, originals[OP])
	check(last.flow.state == last.Flow.State.ERROR, "final real error screen")
	print("MALFORMED_RESULT fixtures=%d checks=%d failures=%d" % [cases.size(), checks, failures])
	if failures:
		quit(1)
		return
	print("EXPECT_NORMAL_ERROR_EXIT")
	last.request("exit", last.flow.revision)
	await create_timer(1.0).timeout
	printerr("FAIL error screen did not quit")
	quit(1)
