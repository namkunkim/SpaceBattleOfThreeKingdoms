extends Control

# 결정 카드(EXPERIENCE-DESIGN §5). 코어의 결정 분기가 오면 화면 아래(엄지 영역)에서 올라온다.
# 지금 POC에는 분기가 없어 게임에서는 뜨지 않는다. 자리와 모양만 준비해 둔다(가짜 분기를 만들지 않는다).
#
# open_card(data):
#   {speaker: "제갈량", portrait: 3, line: "참모 대사 한 줄",
#    options: [{label, effects: [[이름, 값]], risk: {level: "low|mid|high", why: "근거 한 줄"}, rec: "추천 참모 이름" 또는 ""}],
#    time: 30.0, queue: 0}
# 예상 결과는 세 층만: 규칙상 확정 효과(숫자) / 관측 위험(낮음·보통·높음 + 근거) / 승률·결말은 보이지 않는다.

signal chosen(index: int)
signal peek   # "전장 보기": 카드를 잠시 내려 전장을 본다

const RISK := {"low": ["낮음", Color("86e39a")], "mid": ["보통", Color("f2b84b")], "high": ["높음", Color("ff7550")]}

var deck: Control
var data := {}
var time_left := 0.0
var _opts: Array = []

func setup(d: Control) -> void:
	deck = d
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false

func open_card(d: Dictionary) -> void:
	data = d
	time_left = float(d.get("time", 30.0))
	for b in _opts:
		b.queue_free()
	_opts.clear()
	var opts: Array = d.get("options", [])
	var w := (size.x - 32.0 - 12.0 * (opts.size() - 1)) / maxf(1.0, opts.size())
	for i in opts.size():
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.position = Vector2(16 + i * (w + 12.0), 70)
		b.size = Vector2(w, size.y - 86)
		b.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		b.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		b.draw.connect(_draw_option.bind(b, opts[i]))
		b.pressed.connect(func(): chosen.emit(i))
		add_child(b)
		_opts.append(b)
	var pk := Button.new()
	pk.text = "전장 보기"
	pk.focus_mode = Control.FOCUS_NONE
	pk.position = Vector2(size.x - 128, 14)
	pk.size = Vector2(112, 40)
	pk.pressed.connect(func(): peek.emit())
	add_child(pk)
	_opts.append(pk)
	visible = true
	queue_redraw()

func close_card() -> void:
	visible = false
	data = {}

func _draw() -> void:
	if data.is_empty():
		return
	var r := Rect2(Vector2.ZERO, size)
	draw_style_box(UiTheme.ornate(), r)
	# 참모 초상과 대사
	var pr := Rect2(16, 12, 46, 46)
	draw_texture_rect(deck.battle._portrait_tex(int(data.get("portrait", 0))), pr, false)
	draw_rect(pr, UiTheme.GOLD, false, 1.0)
	UiDraw.text(self, Vector2(74, 30), str(data.get("speaker", "")), "serif_bold", 14, UiTheme.GOLD_HI)
	UiDraw.text(self, Vector2(74, 52), "“%s”" % data.get("line", ""), "medium", 14, UiTheme.INK)
	if int(data.get("queue", 0)) > 0:
		UiDraw.text(self, Vector2(size.x - 140, 34), "+%d" % int(data.queue), "bold", 13, UiTheme.WARN, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
	# 시간 막대(게임 시계). 다 지나면 추천안이 위임 처리된다.
	var k := clampf(time_left / maxf(1.0, float(data.get("time", 30.0))), 0.0, 1.0)
	draw_rect(Rect2(0, size.y - 4, size.x, 4), UiTheme.SLOT)
	draw_rect(Rect2(0, size.y - 4, size.x * k, 4), UiTheme.WARN if k < 0.3 else UiTheme.GOLD)

func _draw_option(b: Button, o: Dictionary) -> void:
	var r := Rect2(Vector2.ZERO, b.size)
	var hov := b.is_hovered() or b.button_pressed
	b.draw_rect(r, Color(0.09, 0.13, 0.2, 0.95) if hov else Color(0.06, 0.09, 0.14, 0.95))
	var rec := str(o.get("rec", ""))
	b.draw_rect(r.grow(-0.5), UiTheme.GOLD_HI if rec != "" else UiTheme.LINE, false, 1.0)
	UiDraw.text(b, Vector2(12, 24), str(o.get("label", "")), "semibold", 15, UiTheme.INK)
	if rec != "":
		var tw := UiDraw.text_w("추천 · " + rec, "semibold", 10) + 12.0
		b.draw_rect(Rect2(r.end.x - tw - 8, 9, tw, 18), Color(UiTheme.GOLD, 0.25))
		UiDraw.text(b, Vector2(r.end.x - 8 - tw * 0.5, 22), "추천 · " + rec, "semibold", 10, UiTheme.GOLD_HI, HORIZONTAL_ALIGNMENT_CENTER, 0.0)
	var y := 46.0
	for e in o.get("effects", []):
		UiDraw.text(b, Vector2(12, y), str(e[0]), "regular", 12, UiTheme.INK_2)
		UiDraw.text(b, Vector2(r.end.x - 12, y), str(e[1]), "semibold", 12, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT, 0.0)
		y += 18.0
	var risk: Dictionary = o.get("risk", {})
	if not risk.is_empty():
		var rk: Array = RISK.get(risk.level, RISK.mid)
		UiDraw.text(b, Vector2(12, r.end.y - 12), "위험 %s · %s" % [rk[0], risk.get("why", "")], "medium", 11, rk[1])
