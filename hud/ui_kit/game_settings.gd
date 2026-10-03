class_name GameSettings
extends RefCounted

# 사용자 설정(user://settings.cfg): UI 크기, 전체 화면, 빛 번짐, 조용한 구간 자동 ×4(Q52).

const PATH := "user://settings.cfg"
const UI_SCALES := [0.9, 1.0, 1.15, 1.3]

static var ui_scale := 1.0
static var fullscreen := false
static var glow := true
static var auto_fast := true
static var _loaded := false

static func load_cfg() -> void:
	if _loaded:
		return
	_loaded = true
	var cf := ConfigFile.new()
	if cf.load(PATH) != OK:
		# 처음 실행: 모바일은 터치 목표 크기에 맞춰 UI 크기를 고른다(§7.2).
		ui_scale = TouchMetrics.default_ui_scale(UI_SCALES)
		return
	ui_scale = float(cf.get_value("display", "ui_scale", 1.0))
	fullscreen = bool(cf.get_value("display", "fullscreen", false))
	glow = bool(cf.get_value("display", "glow", true))
	auto_fast = bool(cf.get_value("play", "auto_fast", true))

static func save_cfg() -> void:
	var cf := ConfigFile.new()
	cf.set_value("display", "ui_scale", ui_scale)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.set_value("display", "glow", glow)
	cf.set_value("play", "auto_fast", auto_fast)
	cf.save(PATH)

static func apply(win: Window) -> void:
	load_cfg()
	if win == null:
		return
	win.content_scale_factor = ui_scale
	if DisplayServer.get_name() != "headless":
		var want := Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED
		if win.mode != want and (fullscreen or win.mode == Window.MODE_FULLSCREEN):
			win.mode = want
