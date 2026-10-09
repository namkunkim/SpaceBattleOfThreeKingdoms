class_name AutoResolver
extends RefCounted

# 천하 지도의 자동 해결: 적벽 프로필로 BattleSim을 끝까지 돌린다. 아군 전대는 모두 위임(지휘관 AI, Q2).
# 화면이 멈추지 않게 작업 스레드에서 돌리고, 주 스레드는 progress()·clock_s()만 읽는다.
# 같은 Brief면 같은 결과(결정성). 헤드리스 테스트는 run_blocking()을 쓴다.

const MAX_S := 1800.0
const EVENT_DRAIN := 50   # 사건 목록이 쌓이지 않게 이 틱마다 비운다

var brief: BattleBrief
var sim: BattleSim
var outcome: BattleOutcome
var error := ""
var _thread: Thread
var _cancel := false
var _max_tick := 0
# 작업 스레드가 EVENT_DRAIN 틱마다 써 두는 표시값(주 스레드는 코어 상태를 직접 읽지 않는다)
var _clock_s := 0.0
var _bp := [0, 0]
var _limit_s := 1200.0   # 20분 시계. 프로필의 승패 규칙(time_limit_s)에서 다시 읽는다

func _init(b: BattleBrief) -> void:
	brief = b

func _prepare() -> bool:
	error = brief.validate()
	if error != "":
		return false
	var p := brief.profile()
	if p.is_empty():
		error = "적벽 프로필을 읽지 못했다"
		return false
	sim = BattleSim.new(brief.seed, BattleRules.TICK_HZ, p)
	sim.set_manual_all(false)
	if sim.victory:
		_limit_s = float(sim.victory.V.get("time_limit_s", _limit_s))
	_max_tick = int(MAX_S * sim.st.hz)
	return true

func _loop() -> void:
	while not _cancel and not sim.st.over and sim.st.tick < _max_tick:
		sim.step()
		if sim.st.tick % EVENT_DRAIN == 0:
			sim.drain_events()
			_publish()
	_publish()

func _publish() -> void:
	_clock_s = sim.st.clock_s()
	if sim.morale:
		_bp = [sim.morale.army_bp(0), sim.morale.army_bp(1)]

func run_blocking() -> BattleOutcome:
	if not _prepare():
		return null
	_loop()
	outcome = BattleOutcome.from_sim(sim, brief)
	return outcome

func start() -> bool:
	if not _prepare():
		return false
	_thread = Thread.new()
	_thread.start(_loop)
	return true

# 주 스레드에서 매 프레임 부른다. 끝났으면 결과를 만들고 true.
func poll() -> bool:
	if outcome:
		return true
	if _thread == null or _thread.is_alive():
		return false
	_thread.wait_to_finish()
	_thread = null
	if _cancel:
		return false
	outcome = BattleOutcome.from_sim(sim, brief)
	return true

func cancel() -> void:
	_cancel = true
	if _thread:
		_thread.wait_to_finish()
		_thread = null

# 시계 제한(time_limit_s)을 끝으로 본다. 그보다 먼저 끝나면 결과가 나올 때 1로 뛴다.
func progress() -> float:
	if outcome:
		return 1.0
	return clampf(_clock_s / _limit_s, 0.0, 0.99)

func clock_s() -> float:
	return _clock_s

func limit_s() -> float:
	return _limit_s

func army_bp() -> Array:
	return _bp
