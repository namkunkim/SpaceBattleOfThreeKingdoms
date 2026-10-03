extends Node

# 전투 시간 진행(결정 Q52): 조용한 구간 자동 ×4, "다음 분기까지 건너뛰기".
# - 조용함 판정은 BattleSource.quiet()가 한다(지금은 거리 기반 임시 판정, 코어가 생기면 그쪽 판정).
# - 플레이어가 고른 배속(×1·×2)은 user_speed로 따로 기억하고, 교전이 시작되면 그 배속으로 돌아온다.
# - 조용한 구간에서 플레이어가 배속 버튼을 누르면 그 구간 동안은 자동 ×4를 쓰지 않는다.

const AUTO_SPEED := 4
const SKIP_SPEED := 8
const QUIET_HOLD := 1.0   # 조용한 상태가 이만큼(실제 초) 이어져야 자동 ×4로 바꾼다(깜빡임 방지)
# 건너뛰기를 멈추는 교신 종류: 경보(sys), 적 쪽 사건(foe). 코어의 분기 알림이 생기면 그 신호로 바꾼다.
const STOP_KINDS := ["sys", "foe"]

enum Mode { USER, AUTO, SKIP }

var deck: Control
var src: BattleSource
var mode := Mode.USER
var user_speed := 1
var quiet := false
var _quiet_t := 0.0
var _suppressed := false   # 이번 조용한 구간에서 자동 ×4를 쓰지 않는다
var _last_state := ""

func setup(d: Control, s: BattleSource) -> void:
	deck = d
	src = s
	deck.battle.battle_event.connect(_on_event)

func auto_enabled() -> bool:
	return GameSettings.auto_fast

# 배속 버튼(×1·×2). 건너뛰기를 멈추고, 조용한 구간이면 그 구간 동안 자동 ×4를 끈다.
func set_user_speed(n: int) -> void:
	user_speed = n
	if quiet:
		_suppressed = true
	_set_mode(Mode.USER)

func can_skip() -> bool:
	return src.state() == "play" and quiet and mode != Mode.SKIP

func skip() -> void:
	if can_skip():
		_set_mode(Mode.SKIP)

func cancel_skip() -> void:
	if mode == Mode.SKIP:
		_set_mode(Mode.USER)

func _set_mode(m: int) -> void:
	mode = m
	match m:
		Mode.AUTO: src.set_speed(AUTO_SPEED)
		Mode.SKIP: src.set_speed(SKIP_SPEED)
		_: src.set_speed(user_speed)

func _process(delta: float) -> void:
	var st := src.state()
	if st != _last_state:
		# 새 전투(브리핑 → 전투)는 ×1부터 시작한다.
		if _last_state == "brief" and st == "play":
			user_speed = 1
			_suppressed = false
			_quiet_t = 0.0
			_set_mode(Mode.USER)
		_last_state = st
	if st != "play":
		return
	quiet = src.quiet()
	if not quiet:
		_quiet_t = 0.0
		_suppressed = false
		if mode != Mode.USER:
			_set_mode(Mode.USER)
		return
	_quiet_t += delta
	if mode == Mode.USER and auto_enabled() and not _suppressed and _quiet_t >= QUIET_HOLD:
		_set_mode(Mode.AUTO)
	elif mode == Mode.AUTO and not auto_enabled():
		_set_mode(Mode.USER)

func _on_event(kind: String, _text: String, _fleet_id: int) -> void:
	if mode == Mode.SKIP and kind in STOP_KINDS:
		_set_mode(Mode.USER)

# 건너뛰는 중에 전장을 만지거나 키를 누르면 멈춘다(이벤트는 소비하지 않는다).
func _input(event: InputEvent) -> void:
	if mode != Mode.SKIP:
		return
	if (event is InputEventMouseButton or event is InputEventScreenTouch or event is InputEventKey) and event.is_pressed():
		cancel_skip()

# 상단 상태 문구
func status_tag() -> String:
	match mode:
		Mode.AUTO: return "정 찰 · 자동 ×%d" % AUTO_SPEED
		Mode.SKIP: return "건 너 뛰 는 중 · ×%d" % SKIP_SPEED
	if quiet:
		return "정 찰" + (" · ×%d" % user_speed if user_speed > 1 else "")
	return "교 전 중" + (" · ×%d" % user_speed if user_speed > 1 else "")
