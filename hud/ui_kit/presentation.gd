extends Node

# 상품화 표현 계층의 진입점. FleetBattle3D가 _ready에서 만든다.
# - view/fleet_render: 함대 대량 표시·전투 연출
# - hud/ui_kit: 테마, HUD, 타이틀·브리핑·일시정지·결과 화면
# POC 3D 함대와 POC HUD는 숨기기만 하고 지우지 않는다(전투 규칙·입력은 POC 그대로 쓴다).

var battle: Node
var src: BattleSource
var renderer: FleetRenderer
var hud: Control
var touch: TouchController
var _first_fleet: Object = null

func setup(b: Node) -> void:
	battle = b
	src = BattleSource.new(b)
	var r := FleetRenderer.new()
	r.name = "FleetRenderer"
	battle.add_child(r)
	r.setup(src)
	# 렌더러가 준비된 뒤에만 POC 함대를 숨긴다. 실패하면 POC 화면이 그대로 남는다.
	renderer = r
	_tune_environment()
	touch = TouchController.new()
	touch.name = "TouchController"
	add_child(touch)
	touch.setup(battle)
	var mouse := MouseController.new()
	mouse.name = "MouseController"
	add_child(mouse)
	mouse.setup(battle, touch)
	var hud_script := load("res://hud/ui_kit/command_deck.gd") if ResourceLoader.exists("res://hud/ui_kit/command_deck.gd") else null
	if hud_script and hud_script.can_instantiate():
		var layer := CanvasLayer.new()
		layer.layer = 5
		layer.name = "CommandDeckLayer"
		add_child(layer)
		hud = hud_script.new()
		layer.add_child(hud)
		hud.setup(battle, src, renderer)
		hud.overlay.touch = touch
		_hide_legacy_hud()

func _hide_legacy_hud() -> void:
	if battle.ui and battle.ui.get_parent() is CanvasLayer:
		(battle.ui.get_parent() as CanvasLayer).visible = false

func _tune_environment() -> void:
	for c in battle.get_children():
		if c is WorldEnvironment:
			var env: Environment = (c as WorldEnvironment).environment
			env.glow_enabled = true
			env.glow_intensity = 0.85
			env.glow_strength = 1.05
			env.glow_bloom = 0.04
			env.glow_hdr_threshold = 0.85
			env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
			env.set_glow_level(1, 1.0)
			env.set_glow_level(2, 0.8)
			env.set_glow_level(3, 0.6)
			env.set_glow_level(5, 0.3)
			env.adjustment_enabled = true
			env.adjustment_contrast = 1.08
			env.adjustment_saturation = 1.06

var _fps_t := 0.0

func _process(delta: float) -> void:
	if battle.fleets.is_empty() or renderer == null:
		return
	# 디버그 빌드에서만: 2초마다 FPS·표시 함선 수를 출력한다(태블릿 실측용, adb logcat -s godot)
	if OS.is_debug_build():
		_fps_t += delta
		if _fps_t >= 2.0:
			_fps_t = 0.0
			print("FPS ", Engine.get_frames_per_second(), " ships ", renderer.visible_ship_count(), " state ", src.state(), " speed ", src.speed())
	if not is_same(battle.fleets[0], _first_fleet):
		_first_fleet = battle.fleets[0]
		renderer.reset()
	for f in battle.fleets:
		if f.root and f.root.visible:
			f.root.visible = false
	var st := src.state()
	var dt := 0.0
	if st == "play":
		dt = minf(0.05, delta) * src.speed() * src.slow()
	elif st == "end":
		dt = minf(0.05, delta)
	renderer.update(dt)
