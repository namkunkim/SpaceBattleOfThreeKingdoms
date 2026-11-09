from pathlib import Path
import sys
p=Path('scripts/FleetBattle3D.gd')
src=p.read_bytes()
d=Path(__file__).resolve().parent
expected=__import__('json').loads((d/'baseline.json').read_bytes())['paths'][p.as_posix()]['sha256']
if __import__('hashlib').sha256(src).hexdigest()!=expected:
 assert src==(d/'FleetBattle3D.gd.proposed.txt').read_bytes()
 src=(d/'FleetBattle3D.gd.before.txt').read_bytes()
nl='\r\n' if b'\r\n' in src else '\n'
s=src.decode('utf8').replace(nl,'\n')
def insert(a,b):
 global s
 assert s.count(a)==1,a
 s=s.replace(a,b)
insert('var ui: FleetLabels\n','var ui: FleetLabels\nvar _legacy_canvas: CanvasLayer\nvar _prepare_error_layer: CanvasLayer\nvar _prepare_error_reason: Label\n')
insert('var canvas := CanvasLayer.new()\n\tadd_child(canvas)','var canvas := CanvasLayer.new()\n\t_legacy_canvas = canvas\n\tadd_child(canvas)')
insert('push_error("[FleetBattle3D] %s at %s" % [candidate.error, candidate.path])\n\t\treturn candidate','push_error("[FleetBattle3D] %s at %s" % [candidate.error, candidate.path])\n\t\t_show_prepare_error(candidate.path)\n\t\treturn candidate')
insert('_publish_game(candidate, candidate_org)\n\treturn {"ok": true}', '_publish_game(candidate, candidate_org)\n\t_clear_prepare_error()\n\treturn {"ok": true}')
insert('func _prepare_game(candidate_org: Dictionary) -> Dictionary:', '''func _show_prepare_error(path: String) -> void:
	if _prepare_error_layer == null:
		_build_prepare_error(sim == null)
	_prepare_error_reason.text = ("전투 프로필이 비어 있습니다." if path == "profile"
		else "함대 편성 데이터가 올바르지 않습니다.")

func _build_prepare_error(initial: bool) -> void:
	_prepare_error_layer = CanvasLayer.new()
	_prepare_error_layer.name = "BattlePrepareError"
	_prepare_error_layer.layer = 6
	_prepare_error_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_prepare_error_layer)
	if initial:
		_legacy_canvas.hide()
		_legacy_canvas.process_mode = Node.PROCESS_MODE_DISABLED
		ui.hide()
		var backdrop := ColorRect.new()
		backdrop.color = UiTheme.BG_DEEP
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_prepare_error_layer.add_child(backdrop)
		backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe_root := MarginContainer.new()
	safe_root.name = "SafeContent"
	safe_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	safe_root.theme = UiTheme.build()
	for edge in ["left", "top", "right", "bottom"]:
		safe_root.add_theme_constant_override("margin_" + edge, 16)
	_prepare_error_layer.add_child(safe_root)
	safe_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var safe := SafeArea.new()
	safe_root.add_child(safe)
	safe.setup(safe_root)
	var card := PanelContainer.new()
	card.name = "PrepareErrorCard"
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER if initial else Control.SIZE_SHRINK_BEGIN
	card.custom_minimum_size.x = minf(480.0, get_viewport().get_visible_rect().size.x * 0.44)
	var style := UiTheme.flat(UiTheme.BG_DEEP, UiTheme.WARN, 1, 6)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)
	safe_root.add_child(card)
	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_theme_constant_override("separation", 8)
	card.add_child(content)
	var heading := UiTheme.label("전투를 준비하지 못했습니다.", "Heading", 22, UiTheme.WARN)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	_prepare_error_reason = UiTheme.label("", "Body", 17)
	_prepare_error_reason.name = "Reason"
	_prepare_error_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_prepare_error_reason)
	var in_world := initial and routed()
	var guidance := "기존 전투는 유지됩니다. 다시 시도해 주세요."
	if initial:
		guidance = "전투 결과 없이 천하로 돌아갑니다." if in_world else "전투를 시작하지 않고 게임을 종료합니다."
	var hint := UiTheme.label(guidance, "Body", 17)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(hint)
	if initial:
		var exit := Button.new()
		exit.name = "ExitBattlePrepareError"
		exit.theme_type_variation = "PrimaryButton"
		exit.text = "천하로" if in_world else "종료"
		exit.custom_minimum_size.y = 48
		exit.add_theme_stylebox_override("focus", UiTheme.flat(Color.TRANSPARENT, UiTheme.GOLD_HI, 2, 4))
		content.add_child(exit)
		if in_world:
			var link := get_node("/root/WorldLink")
			exit.pressed.connect(func(): link.back_to_world(null))
		else:
			exit.pressed.connect(_quit)
		exit.grab_focus()

func _clear_prepare_error() -> void:
	if _prepare_error_layer == null:
		return
	_prepare_error_layer.hide()
	_prepare_error_layer.queue_free()
	_prepare_error_layer = null
	_prepare_error_reason = null

func _prepare_game(candidate_org: Dictionary) -> Dictionary:''')
(d/'FleetBattle3D.gd.before.txt').write_bytes(src)
(d/'FleetBattle3D.gd.proposed.txt').write_bytes(s.replace('\n',nl).encode('utf8'))
if '--apply' in sys.argv:p.write_bytes(s.replace('\n',nl).encode('utf8'))



