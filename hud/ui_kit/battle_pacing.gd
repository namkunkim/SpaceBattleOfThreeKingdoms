extends Node

# 전투 시간 진행
# - 선택 감속(Q31·Q36·Q55): 아군 전대를 선택하면 ×0.2. 명령이 확정되거나, 선택한 채 5초(실제 시간) 동안
#   입력이 없으면 원래 속도로 돌아간다(선택 강조는 유지). 다시 만지면 다시 감속한다. 설정에서 끈다.
# - 조용한 구간(Q52): 자동 ×4, "다음 교전·경보까지 건너뛰기". 조용함 판정은 BattleSource.quiet()
#   (지금은 거리 기반 임시 판정, 코어가 생기면 그쪽 판정).
# - 플레이어가 고른 배속(×1·×2·×4)은 user_speed로 따로 기억하고, 교전이 시작되면 그 배속으로 돌아온다.
# - 조용한 구간에서 플레이어가 배속 버튼을 누르면 그 구간 동안은 자동 ×4를 쓰지 않는다.
# 모든 시간 판정은 실제 시간(UiDraw.real_dt)으로 한다. 감속 중에도 5초는 5초다.

signal changed   # 상단 상태 문구가 바뀔 때(반짝임, 리뷰 U8)
signal incoming  # 곧 분기(리뷰 V-4): 예고가 처음 들어올 때 한 번

const AUTO_SPEED := 4
const SKIP_SPEED := 8
const SLOW := 0.2
const IDLE := 5.0         # 선택 유휴 해제(Q55)
const QUIET_HOLD := 1.0   # 조용한 상태가 이만큼 이어져야 자동 ×4로 바꾼다(깜빡임 방지)
# 건너뛰기를 멈추는 교신 종류: 경보(sys), 적 쪽 사건(foe). 코어의 분기 알림이 생기면 그 신호로 바꾼다.
const STOP_KINDS := ["sys", "foe"]

enum Mode { USER, AUTO, SKIP }

var deck: Control
var src: BattleSource
var mode := Mode.USER
var user_speed := 1
var quiet := false
var slow := false
var _quiet_t := 0.0
var _suppressed := false   # 이번 조용한 구간에서 자동 ×4를 쓰지 않는다
var _last_state := ""
var _idle := 0.0
var _order_done := false
var _sig := ""
var _tag := ""
var _incoming := false
var _held := false          # 포인터를 누르고 있다(조작 중에만 감속)
var forced_slow := false    # 빠른 선택 알림이 떠 있는 동안 감속(리뷰 W-5)

func setup(d: Control, s: BattleSource) -> void:
	deck = d
	src = s
	deck.battle.battle_event.connect(_on_event)

func auto_enabled() -> bool:
	return GameSettings.auto_fast

# 배속 버튼(×1·×2·×4). 건너뛰기를 멈추고, 조용한 구간이면 그 구간 동안 자동 ×4를 끈다.
func set_user_speed(n: int) -> void:
	user_speed = n
	if quiet:
		_suppressed = true
	mode = Mode.USER

func can_skip() -> bool:
	return src.state() == "play" and quiet and mode != Mode.SKIP and not _incoming

func skip() -> void:
	if can_skip():
		mode = Mode.SKIP
		_order_done = true   # 건너뛰기는 선택 감속보다 우선한다(다음 입력까지)

func cancel_skip() -> void:
	if mode == Mode.SKIP:
		mode = Mode.USER

func _process(delta: float) -> void:
	delta = UiDraw.real_dt(delta)
	var st := src.state()
	if st != _last_state:
		# 새 전투(브리핑 → 전투)는 ×1부터 시작한다.
		if _last_state == "brief" and st == "play":
			user_speed = 1
			_suppressed = false
			_quiet_t = 0.0
			mode = Mode.USER
		_last_state = st
	if st != "play":
		slow = false
		src.set_time_scale(1.0)
		_emit_if_changed()
		return
	# 곧 분기(V-4): 자동 ×4와 건너뛰기를 멈추고, 이번 조용한 구간에서는 다시 켜지 않는다
	var inc := not src.decision_incoming().is_empty()
	if inc and not _incoming:
		incoming.emit()
	_incoming = inc
	if inc:
		_suppressed = true
		mode = Mode.USER
	# 조용한 구간
	quiet = src.quiet()
	if not quiet:
		_quiet_t = 0.0
		_suppressed = false
		mode = Mode.USER
	else:
		_quiet_t += delta
		if mode == Mode.USER and auto_enabled() and not _suppressed and _quiet_t >= QUIET_HOLD:
			mode = Mode.AUTO
		elif mode == Mode.AUTO and not auto_enabled():
			mode = Mode.USER
	# 선택 감속
	_idle += delta
	var sig := src.order_signature()
	if sig != _sig:
		# 같은 선택에서 명령이 바뀌면 확정으로 본다. 선택 자체가 바뀐 것은 입력(_input)이 이미 다시 켰다.
		if _sig != "" and sig != "" and _ids(sig) == _ids(_sig):
			_order_done = true
		_sig = sig
	match GameSettings.slow_mode:
		GameSettings.SLOW_ON_SELECT:
			slow = src.has_selection() and _idle < IDLE and not _order_done
		GameSettings.SLOW_WHILE_HANDLING:
			slow = src.has_selection() and ((_held and deck.overlay.touch.mode != "ignore") or deck.overlay.touch.mode == "order")
		_:
			slow = false
	slow = false   # 선택·터치·알림으로 시간이 느려지지 않는다(정지는 일시정지 버튼만)
	_apply()

func _apply() -> void:
	if slow:
		src.set_speed(1)
		src.set_time_scale(SLOW)
	else:
		src.set_time_scale(1.0)
		match mode:
			Mode.AUTO: src.set_speed(AUTO_SPEED)
			Mode.SKIP: src.set_speed(SKIP_SPEED)
			_: src.set_speed(user_speed)
	_emit_if_changed()

func _emit_if_changed() -> void:
	var t := status_tag()
	if t != _tag:
		_tag = t
		changed.emit()

static func _ids(sig: String) -> String:
	var out := PackedStringArray()
	for p in sig.split(";"):
		out.append(p.get_slice(":", 0))
	return ",".join(out)

func _on_event(kind: String, _text: String, _fleet_id: int) -> void:
	if mode == Mode.SKIP and kind in STOP_KINDS:
		mode = Mode.USER

# 누르기·끌기·키·휠은 입력으로 친다: 선택 감속을 다시 켜고, 건너뛰기는 멈춘다(이벤트는 소비하지 않는다).
func _input(event: InputEvent) -> void:
	var pressed := (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.is_pressed()
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		_held = event.is_pressed()
	if pressed or event is InputEventScreenDrag or (event is InputEventMouseMotion and event.button_mask != 0):
		_idle = 0.0
		_order_done = false
		if pressed:
			cancel_skip()

# 상단 상태 문구
func status_tag() -> String:
	if src and src.state() == "pause":
		return "일 시 정 지"
	if _incoming:
		return "결 정 임 박"
	if slow:
		return "선 택 · 감 속 ×0.2"
	match mode:
		Mode.AUTO: return "정 찰 · 자동 ×%d" % AUTO_SPEED
		Mode.SKIP: return "건 너 뛰 는 중 · ×%d" % SKIP_SPEED
	if quiet:
		return "정 찰" + (" · ×%d" % user_speed if user_speed > 1 else "")
	return "교 전 중" + (" · ×%d" % user_speed if user_speed > 1 else "")

# 조용한 구간의 다음 멈춤 사유와 예상 시간(리뷰 U8). 게임 시계 기준.
func next_stop_hint() -> String:
	if not quiet:
		return ""
	var eta := src.engage_eta()
	if eta < 1.0:
		return "접적 임박"
	return "접적까지 약 %d초" % (ceili(eta / 5.0) * 5)
