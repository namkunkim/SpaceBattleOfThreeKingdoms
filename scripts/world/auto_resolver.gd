class_name AutoResolver
extends RefCounted

# 천하 지도의 자동 해결: 적벽 프로필로 BattleSim을 끝까지 돌린다. 아군 전대는 모두 위임(지휘관 AI, Q2).
# 화면이 멈추지 않게 작업 스레드에서 돌리고, 주 스레드는 progress()·clock_s()만 읽는다.
# 같은 Brief면 같은 결과(결정성). 헤드리스 테스트는 run_blocking()을 쓴다.

const OperationAdapter := preload("res://core/battle/operation_runtime_adapter.gd")
const OperationData := preload("res://core/battle/operation_service_state.gd")
const OPERATION_MAX_TICKS := 18000

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

var _operation_thread: Thread
var _operation_mutex := Mutex.new()
var _operation_cancelled := false
var _operation_result: Dictionary = {}

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
	if _operation_thread != null:
		return null
	if not _prepare():
		return null
	_loop()
	outcome = BattleOutcome.from_sim(sim, brief)
	return outcome

func start() -> bool:
	if _operation_thread != null:
		return false
	if not _prepare():
		return false
	_thread = Thread.new()
	_thread.start(_run_legacy)
	return true

func _run_legacy() -> Variant:
	_loop()
	if _cancel:
		return null
	return BattleOutcome.facts_from_sim(sim)

# 주 스레드에서 매 프레임 부른다. 끝났으면 결과를 만들고 true.
func poll() -> bool:
	if outcome:
		return true
	if _thread == null or _thread.is_alive():
		return false
	var facts: Variant = _thread.wait_to_finish()
	_thread = null
	if _cancel:
		return false
	if _valid_legacy_facts(facts):
		outcome = BattleOutcome.from_facts(facts, brief)
	else:
		# After join the live legacy simulation is safe to read again.
		outcome = BattleOutcome.from_sim(sim, brief)
	return true

static func _valid_legacy_facts(facts: Variant) -> bool:
	if not facts is Dictionary or facts.size() != 5:
		return false
	if not facts.get("win") is bool or not facts.get("reason") is String or not facts.get("fingerprint") is String:
		return false
	if not facts.get("t_s") is float or not is_finite(facts.t_s) or not facts.get("result") is Dictionary:
		return false
	var result: Dictionary = facts.result
	var cost: Variant = result.get("cost", {})
	var morale: Variant = result.get("army_morale_bp", [0, 0])
	var commanders: Variant = result.get("commanders", {})
	if not result.get("limited", false) is bool or not cost is Dictionary or not commanders is Dictionary:
		return false
	if not morale is Array or morale.size() < 2:
		return false
	for i in 2:
		if not _legacy_number(morale[i]):
			return false
	for side in ["alliance", "foe"]:
		var side_cost: Variant = cost.get(side, {})
		if not side_cost is Dictionary or not commanders.get(side, "") is String:
			return false
		if not _legacy_number(side_cost.get("original", 0)) or not _legacy_number(side_cost.get("remaining", 0)):
			return false
	return true

static func _legacy_number(value: Variant) -> bool:
	return value is int or (value is float and is_finite(value))

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

# The starting main-thread caller must finish with poll or cancel.
func start_operation(input: Variant) -> Dictionary:
	if _thread != null or _operation_thread != null:
		return OperationAdapter.fail("busy", "worker")
	if not OperationData._data(input):
		return OperationAdapter.fail("invalid_worker_input", "input")
	var snapshot: Variant = input.duplicate(true) if input is Array or input is Dictionary else input
	var thread := Thread.new()
	_operation_mutex.lock()
	_operation_cancelled = false
	_operation_mutex.unlock()
	var code := thread.start(_run_operation.bind(snapshot))
	if code != OK:
		var failure := OperationAdapter.fail("worker_start_failed", "worker")
		failure["godot_error"] = code
		return failure
	_operation_thread = thread
	_operation_result = {}
	return {"ok": true, "status": "running"}

func poll_operation() -> Dictionary:
	if _operation_thread != null:
		if _operation_thread.is_alive():
			return {"ok": true, "status": "running"}
		_operation_result = _operation_thread.wait_to_finish()
		_operation_thread = null
	if _operation_result.is_empty():
		return {"ok": true, "status": "idle"}
	return _operation_result.duplicate(true)

func cancel_operation() -> void:
	if _operation_thread == null:
		return
	_operation_mutex.lock()
	_operation_cancelled = true
	_operation_mutex.unlock()
	_operation_thread.wait_to_finish()
	_operation_thread = null

func _operation_should_cancel() -> bool:
	_operation_mutex.lock()
	var cancelled := _operation_cancelled
	_operation_mutex.unlock()
	return cancelled

func _run_operation(snapshot: Variant) -> Dictionary:
	if _operation_should_cancel():
		return OperationAdapter.fail("cancelled", "worker")
	var created := OperationAdapter.create(snapshot)
	if not created.ok:
		return created
	var owner: OperationPrivateState = created.owner
	var result := _advance_operation(owner, snapshot.initial_controls, created.policy, created.max_ticks)
	owner.close()
	if _operation_should_cancel():
		return OperationAdapter.fail("cancelled", "worker")
	if result.ok:
		result["meta"] = created.meta
		result.meta["executor"] = "worker"
	return result

func _advance_operation(owner: OperationPrivateState, controls: Array, policy: String, max_ticks: int) -> Dictionary:
	if policy != "none":
		return OperationAdapter.fail("unsupported_worker_policy", "policy")
	if controls.is_empty() or controls.count("delegate") != controls.size():
		return OperationAdapter.fail("worker_requires_delegate", "initial_controls")
	if max_ticks > OPERATION_MAX_TICKS:
		return OperationAdapter.fail("worker_tick_limit", "max_ticks")
	var events: Array = []
	var read := owner.summary()
	if not read.ok:
		return read
	while not read.summary.over and read.summary.tick < max_ticks:
		if _operation_should_cancel():
			return OperationAdapter.fail("cancelled", "worker")
		var advanced := owner.advance()
		if not advanced.ok:
			return advanced
		var drained := owner.drain_events()
		if not drained.ok:
			return drained
		events.append_array(drained.events)
		read = owner.summary()
		if not read.ok:
			return read
	return {"ok": true, "summary": read.summary, "events": events, "event_count": events.size()}
