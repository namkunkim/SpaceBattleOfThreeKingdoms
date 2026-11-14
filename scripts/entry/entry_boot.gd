extends Control
# Routes only. Save validation, restoration and settlement remain WorldMap/host responsibilities.
const Entry := preload("res://scenes/entry/NewEntry.tscn")
const Host := preload("res://scripts/first_operation_host.gd")
const Settlements := preload("res://scripts/first_operation_settlement_store.gd")
const V2 := preload("res://scripts/entry/red_cliffs_v2_home.gd")
static var _v2_cli_routed := false
var screen: Control
var _route_error: VBoxContainer
var _route_retry: Button
var _route_target := ""

func _ready() -> void:
	_boot.call_deferred()

func _boot() -> void:
	var link := get_node("/root/WorldLink")
	var returning: bool = link.take_entry_restore()
	var args := OS.get_cmdline_user_args()
	if not _v2_cli_routed and OS.has_feature("windows") and args == PackedStringArray(["--red-cliffs-v2"]):
		_v2_cli_routed = true
		_route(V2.SCENE)
		return
	# Preserve existing explicit development/native entry contracts.
	if args.has(BattleBrief.FIRST_OPERATION_DEV_ARG) or args.has("--o07-supply"):
		_route("res://scenes/FleetBattle3D.tscn")
		return
	if not returning and (link.outcome != null or _has_progress()):
		_route(link.WORLD_SCENE)
		return
	screen = Entry.instantiate()
	screen.campaign_enabled = true
	screen.v2_enabled = OS.has_feature("windows")
	screen.v2_requested.connect(_open_v2)
	screen.sortie_requested.connect(_sortie)
	screen.continuation_requested.connect(_continue)
	add_child(screen)
	if returning: screen.restore_prepared_entry()

func _has_progress() -> bool:
	for path in [Host.PRODUCT_SLOT_PATH, Settlements.PRODUCT_SLOT_PATH]:
		if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".previous"):
			return true
	return false

func _route(path: String) -> void:
	var error := get_tree().change_scene_to_file(path)
	if error == OK:
		return
	_route_target = path
	if not is_instance_valid(_route_error):
		_route_error = VBoxContainer.new()
		_route_error.name = "RouteError"
		_route_error.add_theme_constant_override("separation", 20)
		add_child(_route_error)
		var label := Label.new()
		label.text = "기존 진행 화면을 열지 못했습니다. 다시 시도해 주세요."
		_route_error.add_child(label)
		_route_retry = Button.new()
		_route_retry.name = "RouteRetry"
		_route_retry.text = "재시도"
		_route_retry.pressed.connect(func(): _route(_route_target))
		_route_error.add_child(_route_retry)
	_route_retry.grab_focus()

func _continue(_origin: String) -> void:
	var error := get_tree().change_scene_to_file("res://scenes/WorldMap.tscn")
	if error != OK: screen.campaign_rejected("기존 진행 화면을 열지 못했습니다. 다시 시도해 주세요.")

func _sortie() -> void:
	if screen == null or screen.flow.state != screen.Flow.State.READY: return
	var candidate := BattleBrief.new()
	var link := get_node("/root/WorldLink")
	var error: Error = link.go_battle(candidate, {"entry": true, "difficulty": "표준", "mode": "direct"})
	if error != OK: screen.campaign_rejected("전장에 들어갈 수 없습니다. 준비 상태에서 다시 출격해 주세요.")


func _open_v2() -> void:
	var error := get_tree().change_scene_to_file(V2.SCENE)
	if error != OK:
		screen.campaign_rejected("적벽 v2 메뉴를 열지 못했습니다.")
