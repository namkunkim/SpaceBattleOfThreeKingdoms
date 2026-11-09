extends SceneTree

const SCENE_PATH := "res://scenes/WorldMap.tscn"
const SCREEN_PATH := "res://view/world/world_map_screen.gd"
const LINK_PATH := "res://scripts/world_link.gd"
const CANVAS_PATH := "res://view/world/world_canvas.gd"
const WORLD_PATH := "res://data/scenarios/base/world_208.json"
const REGION := "RGN-02"
const INITIAL := "contested"
const TARGET := "wu"

var checks := 0
var failures: Array[String] = []
var cases: Array[String] = []
var evidence: Dictionary = {}

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, name: String) -> void:
	checks += 1
	if not condition:
		failures.append(name)

func _require(condition: bool, name: String) -> bool:
	if not condition:
		failures.append(name)
	return condition

func _finish() -> void:
	var success := checks == 15 and cases.size() == 3 and failures.is_empty()
	var result := {"cases": cases, "checks": checks, "failures": failures, "evidence": evidence,
		"engine_pid": OS.get_process_id(), "engine_path": OS.get_executable_path(), "user_dir": OS.get_user_data_dir()}
	print(("P03_MAP_PASS " if success else "P03_MAP_FAIL ") + JSON.stringify(result))
	quit(0 if success else 1)

func _outcome(seed: int) -> BattleOutcome:
	var brief := BattleBrief.new()
	brief.seed = seed
	brief.difficulty = "표준"
	brief.mode = "direct"
	return BattleOutcome.from_facts({"win": true, "reason": "annihilation", "t_s": 1.0,
		"fingerprint": "a06-map-probe", "result": {}}, brief)

func _open(scene: PackedScene) -> WorldMapScreen:
	var screen := scene.instantiate() as WorldMapScreen
	if not _require(screen != null and screen.scene_file_path == SCENE_PATH and screen.get_script().resource_path == SCREEN_PATH, "canonical_screen"):
		return null
	root.add_child(screen)
	if not _require(screen.canvas != null and screen.canvas.get_script().resource_path == CANVAS_PATH, "canonical_canvas"):
		return null
	return screen

func _result_ready(screen: WorldMapScreen) -> bool:
	for frame in 12:
		if screen.state == "result":
			return true
		await process_frame
	return false

func _dismiss_button(screen: WorldMapScreen) -> Button:
	for node in screen._result.find_children("*", "Button", true, false):
		var button := node as Button
		if button.text == "천하 보기" and button.pressed.is_connected(Callable(screen, "_result_to_world")):
			return button
	return null

func _run() -> void:
	var link := root.get_node_or_null("WorldLink")
	var scene := load(SCENE_PATH) as PackedScene
	if not _require(link != null and link.get_script().resource_path == LINK_PATH and scene != null and scene.resource_path == SCENE_PATH, "canonical_scene_autoload"):
		_finish()
		return
	var world := WorldMapScreen.read_world()
	var initial: String = ""
	for region in world.regions:
		if region.id == REGION:
			initial = region.owner
	var normal_dto := _outcome(777)
	var early_dto := _outcome(777)
	var target: String = world.outcome_owners.get(normal_dto.kind, {}).get(REGION, "")
	if not _require(WorldMapScreen.WORLD_PATH == WORLD_PATH and initial == INITIAL and target == TARGET
		and normal_dto.kind == "alliance_win" and normal_dto.to_dict() == early_dto.to_dict(), "world_mapping_equal_dto"):
		_finish()
		return
	evidence["mapping"] = {"world_path": WORLD_PATH, "region": REGION, "kind": normal_dto.kind, "initial": initial, "target": target}

	cases.append("normal_map_effect")
	link.outcome = normal_dto
	var normal_start := Time.get_ticks_msec()
	var normal := _open(scene)
	if normal == null or not await _result_ready(normal):
		_require(false, "normal_result_timeout")
		_finish()
		return
	_check(normal.state == "result" and normal._result.visible, "normal_result_visible")
	_check(normal.outcome != null and normal.outcome.seed == 777, "normal_seed")
	_check(link.outcome == null, "normal_slot_consumed")
	var normal_initial: String = normal.canvas.owners_rgn.get(REGION, "")
	_check(normal_initial == INITIAL, "normal_initial_owner")
	await create_timer(0.7).timeout
	await process_frame
	var normal_target: String = normal.canvas.owners_rgn.get(REGION, "")
	_check(normal_target == TARGET, "normal_target_owner")
	evidence["normal"] = {"opened_ms": normal_start, "after_timer_ms": Time.get_ticks_msec(), "before": normal_initial, "after": normal_target}
	normal.queue_free()
	await process_frame

	cases.append("early_result_exit")
	link.outcome = early_dto
	var early_start := Time.get_ticks_msec()
	var early := _open(scene)
	if early == null or not await _result_ready(early):
		_require(false, "early_result_timeout")
		_finish()
		return
	var observed_ms := Time.get_ticks_msec()
	var button := _dismiss_button(early)
	if not _require(button != null and button.is_visible_in_tree() and early.outcome != null
		and early.outcome.seed == 777 and observed_ms - early_start < 600, "early_connected_button_and_window"):
		_finish()
		return
	_check(early.state == "result", "early_result")
	_check(link.outcome == null, "early_slot_consumed")
	var early_initial: String = early.canvas.owners_rgn.get(REGION, "")
	_check(early_initial == INITIAL, "early_initial_owner")
	button.pressed.emit()
	var dismissed_ms := Time.get_ticks_msec()
	if not _require(dismissed_ms - early_start < 600, "early_dismiss_before_timer"):
		_finish()
		return
	_check(early.state == "browse", "early_browse")
	_check(not early._result.visible, "early_result_hidden")
	await create_timer(0.7).timeout
	await process_frame
	var early_target: String = early.canvas.owners_rgn.get(REGION, "")
	_check(early_target == INITIAL, "early_owner_unchanged")
	evidence["early"] = {"opened_ms": early_start, "result_observed_ms": observed_ms, "dismissed_ms": dismissed_ms,
		"after_timer_ms": Time.get_ticks_msec(), "button": button.text, "connected": true,
		"before": early_initial, "after": early_target}
	early.queue_free()
	await process_frame

	cases.append("reentry_after_slot_consumed")
	var reentry := _open(scene)
	if reentry == null:
		_finish()
		return
	for frame in 4:
		await process_frame
	_check(reentry.state == "browse", "reentry_browse")
	_check(reentry.outcome == null, "reentry_no_outcome")
	_check(link.outcome == null, "reentry_slot_empty")
	var reentry_owner: String = reentry.canvas.owners_rgn.get(REGION, "")
	_check(reentry_owner == INITIAL, "reentry_owner_initial")
	evidence["reentry"] = {"state": reentry.state, "owner": reentry_owner, "outcome_present": reentry.outcome != null}
	reentry.queue_free()
	await process_frame
	_finish()
