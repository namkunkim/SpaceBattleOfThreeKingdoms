extends Control

# 명령 되돌리기(EXPERIENCE-DESIGN §6 U2): 플레이어가 명령을 내리면 4초 동안 "되돌리기" 알림을 띄운다.
# 명령은 아군 전대의 명령 상태(이동·표적·방어진형)가 새로 바뀐 것으로 알아챈다. 도착(이동 끝)이나
# 표적 격침처럼 저절로 풀린 것은 명령이 아니다. 돌격·미사일·함재기는 비용을 쓴 명령이라 되돌리지 않는다.

const SHOW := 4.0

var deck: Control
var src: BattleSource
var _last := {}
var _undo := {}       # 되돌릴 직전 상태(바뀐 전대만)
var _left := 0.0
var _what := ""
var _btn: Button

func setup(d: Control, s: BattleSource) -> void:
	deck = d
	src = s
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_btn = Button.new()
	_btn.text = "되돌리기"
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.custom_minimum_size = Vector2(120, 40)
	_btn.position = Vector2(size.x - 128, 6)
	_btn.pressed.connect(undo)
	add_child(_btn)

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	if src.state() != "play":
		_last = {}
		_close()
		return
	var now := src.order_snapshot()
	var charged := false
	for f in deck.battle.fleets:
		if f.side == 0 and f.charge_t > 9.5:
			charged = true
	if not _last.is_empty() and not charged:
		var prev := {}
		for id in now:
			if _last.has(id) and _is_new_order(_last[id], now[id]):
				prev[id] = _last[id]
		if not prev.is_empty():
			_undo = prev
			deck.sound.play("confirm")
			_what = _describe(prev, now)
			_left = SHOW
			visible = true
	_last = now
	if _left > 0.0:
		_left -= delta
		modulate.a = clampf(_left / 0.3, 0.0, 1.0)
		queue_redraw()
		if _left <= 0.0:
			_close()

static func _is_new_order(a: Array, b: Array) -> bool:
	if b[0] and (not a[0] or a[1] != b[1]):
		return true                  # 새 이동
	if b[2] >= 0 and b[2] != a[2]:
		return true                  # 새 표적
	return a[3] != b[3]              # 방어진형 전환

func _describe(prev: Dictionary, now: Dictionary) -> String:
	var id: int = prev.keys()[0]
	var b: Array = now[id]
	var n := prev.size()
	var who := "%d개 함대" % n if n > 1 else "%s 함대" % deck.battle.by_id(id).fname
	if b[2] >= 0:
		return "%s · 공격 명령" % who
	if b[0]:
		return "%s · 이동 명령" % who
	return "%s · 명령 변경" % who

func undo() -> void:
	if _undo.is_empty():
		return
	src.restore_orders(_undo)
	deck.sound.play("undo")
	_last = src.order_snapshot()   # 되돌린 것을 새 명령으로 알아채지 않게
	deck.show_toast("명령을 되돌렸습니다")
	_close()

func _close() -> void:
	_undo = {}
	_left = 0.0
	visible = false

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	draw_rect(r, Color(0.03, 0.05, 0.08, 0.9))
	draw_rect(r.grow(-0.5), Color(UiTheme.GOLD, 0.45), false, 1.0)
	# 남은 시간 막대
	draw_rect(Rect2(0, size.y - 3, size.x * clampf(_left / SHOW, 0.0, 1.0), 3), UiTheme.GOLD)
	UiDraw.text(self, Vector2(16, size.y * 0.5 + 5), _what, "medium", 13, UiTheme.INK)
