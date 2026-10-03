class_name GameSettings
extends RefCounted

# 사용자 설정(user://settings.cfg): UI 크기, 전체 화면, 빛 번짐, 표시 밀도, 음량, 조용한 구간 자동 ×4(Q52), 선택 감속(Q31·Q55).

const PATH := "user://settings.cfg"
const UI_SCALES := [0.9, 1.0, 1.15, 1.3]

static var ui_scale := 1.0
static var fullscreen := false
static var glow := true
static var auto_fast := true
static var slow_select := true
static var vol_master := 0.8
static var vol_sfx := 0.8
static var vol_ui := 0.7
static var ship_density := 1   # 표시 함선 밀도 0 낮음 / 1 보통 / 2 높음(리뷰 C-1·C-4)
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
	slow_select = bool(cf.get_value("play", "slow_select", true))
	ship_density = int(cf.get_value("display", "ship_density", 1))
	vol_master = float(cf.get_value("audio", "master", 0.8))
	vol_sfx = float(cf.get_value("audio", "sfx", 0.8))
	vol_ui = float(cf.get_value("audio", "ui", 0.7))

static func save_cfg() -> void:
	var cf := ConfigFile.new()
	cf.set_value("display", "ui_scale", ui_scale)
	cf.set_value("display", "fullscreen", fullscreen)
	cf.set_value("display", "glow", glow)
	cf.set_value("play", "auto_fast", auto_fast)
	cf.set_value("play", "slow_select", slow_select)
	cf.set_value("display", "ship_density", ship_density)
	cf.set_value("audio", "master", vol_master)
	cf.set_value("audio", "sfx", vol_sfx)
	cf.set_value("audio", "ui", vol_ui)
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
