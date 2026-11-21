extends Control

const Host := preload("res://scripts/first_operation_v2_product_host.gd")
const Storage := preload("res://scripts/first_operation_v2_storage.gd")
const Replay := preload("res://scripts/first_operation_v2_product_replay.gd")
const Codec := preload("res://scripts/first_operation_v2_record_codec.gd")
const SCENE := "res://scenes/entry/RedCliffsV2.tscn"
const V3_SCENE := "res://scenes/entry/RedCliffsV3.tscn"
const V3Storage := preload("res://scripts/first_operation_v3_storage.gd")
const V3Codec := preload("res://scripts/first_operation_v3_record_codec.gd")

@export var multi_formation := false

@onready var _storage: Script = V3Storage if multi_formation else Storage
@onready var _codec: Script = V3Codec if multi_formation else Codec
@onready var _title := "적벽 v2 · 다중 진형" if multi_formation else "적벽 v2"

var _menu: VBoxContainer
var _fresh: Button
var _resume: Button
var _host: Host
var _viewer: Replay
var _replay_dialog: FileDialog
var _notice: Label
var _watch: Button


func _ready() -> void:
	GameSettings.apply(get_window())
	if DisplayServer.get_name() != "headless":
		get_window().title = "성한지 — " + _title
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_menu = VBoxContainer.new()
	_menu.custom_minimum_size.x = 340
	_menu.add_theme_constant_override("separation", 16)
	_menu.theme = UiTheme.build()
	center.add_child(_menu)
	var heading := Label.new()
	heading.text = _title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 32)
	_menu.add_child(heading)
	_fresh = _button("새 출격", _open_sortie.bind(false))
	_resume = _button("저장한 작전 재개", _open_sortie.bind(true))
	_watch = _button(_title + " 리플레이 보기", _select_replay)
	if not multi_formation:
		_button("다중 진형 확장 출격", _open_multi_formation)
	_button("적벽 v2 메뉴" if multi_formation else "기존 적벽으로 돌아가기", _return_to_entry)
	_notice = Label.new()
	_menu.add_child(_notice)
	if not _storage.available():
		_fresh.disabled = true
		_watch.disabled = true
		var notice := Label.new()
		notice.text = "적벽 v2를 실행할 Windows 구성 요소를 불러오지 못했습니다."
		_menu.add_child(notice)
	_refresh()
	if not _fresh.disabled:
		_fresh.grab_focus()


func _button(caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = caption
	button.custom_minimum_size.y = 48
	button.pressed.connect(action)
	_menu.add_child(button)
	return button


func _refresh() -> void:
	_resume.disabled = not _storage.available() or not _storage.has_save()


func _open_sortie(resume: bool) -> void:
	if _host != null or _viewer != null or _replay_dialog != null or not _storage.available() or (resume and not _storage.has_save()):
		return
	_host = Host.new()
	_host.name = "RedCliffsV2Host"
	_host.configure(resume, multi_formation)
	_host.returned.connect(_close_sortie)
	_menu.hide()
	add_child(_host)


func _close_sortie() -> void:
	_host.queue_free()
	_host = null
	_refresh()
	_menu.show()
	_fresh.grab_focus()


func _return_to_entry() -> void:
	if _host == null and _viewer == null and _replay_dialog == null:
		get_tree().change_scene_to_file(SCENE if multi_formation else "res://scenes/entry/EntryBoot.tscn")


func _open_multi_formation() -> void:
	if _host == null and _viewer == null and _replay_dialog == null:
		get_tree().change_scene_to_file(V3_SCENE)


func _select_replay() -> void:
	if _host != null or _viewer != null or _replay_dialog != null:
		return
	_replay_dialog = FileDialog.new()
	_replay_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_replay_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_replay_dialog.title = _title + " 리플레이 열기"
	_replay_dialog.filters = PackedStringArray(["*" + _codec.REPLAY_EXTENSION + " ; " + _title + " 리플레이"])
	add_child(_replay_dialog)
	_replay_dialog.canceled.connect(_close_replay_dialog)
	_replay_dialog.file_selected.connect(_open_replay)
	_replay_dialog.popup_centered_ratio(0.7)


func _close_replay_dialog() -> void:
	if _replay_dialog != null:
		_replay_dialog.queue_free()
		_replay_dialog = null
	_watch.grab_focus()


func _open_replay(path: String) -> void:
	_close_replay_dialog()
	_viewer = Replay.new()
	_viewer.configure(multi_formation)
	_viewer.name = "RedCliffsV2Replay"
	_viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_viewer.theme = UiTheme.build()
	add_child(_viewer)
	var opened := _viewer.open_file(path)
	if not opened.ok:
		_viewer.queue_free()
		_viewer = null
		_notice.text = Host.error_text(opened)
		return
	_notice.text = ""
	_menu.hide()
	_viewer.exit_requested.connect(_replay_closed)


func _replay_closed() -> void:
	_viewer = null
	_menu.show()
	_watch.grab_focus()
