extends RefCounted

# The caller owns this worker on the main thread and must poll or cancel_and_join.
const Adapter := preload("res://scripts/first_operation_adapter.gd")
const POLICY := "pc-first-operation-auto/1"
const LIMIT_TICKS := 12000
const PROGRESS_INTERVAL := 20
const ORDERS := {
	"front": {0: ["move", 2], 900: ["move", 3]},
	"flank": {0: ["move", 2], 1500: ["withdraw"], 2150: ["finalize_withdrawal"]},
}

var _thread: Thread
var _mutex := Mutex.new()
var _cancelled := false
var _progress := {}

func start(request: Dictionary) -> Dictionary:
	if _thread != null:
		return _fail("busy", "worker")
	var snapshot := {}
	for key in request:
		if typeof(key) not in [TYPE_STRING, TYPE_STRING_NAME] or typeof(request[key]) not in [TYPE_STRING, TYPE_INT]:
			return _fail("invalid_auto_request", "request")
		snapshot[String(key)] = request[key]
	var thread := Thread.new()
	_mutex.lock()
	_cancelled = false
	_progress = {"tick": 0, "clock_ms": 0, "limit_ticks": LIMIT_TICKS}
	_mutex.unlock()
	var code := _start_thread(thread, _run.bind(snapshot))
	if code != OK:
		var failure := _fail("worker_start_failed", "worker")
		failure.godot_error = code
		return failure
	_thread = thread
	return {"ok": true, "status": "running"}

func _start_thread(thread: Thread, action: Callable) -> Error:
	return thread.start(action)

func poll() -> Dictionary:
	if _thread == null:
		return {"ok": true, "status": "idle"}
	if _thread.is_alive():
		_mutex.lock()
		var progress := _progress.duplicate()
		var cancelled := _cancelled
		_mutex.unlock()
		return {"ok": true, "status": "cancelling" if cancelled else "running", "progress": progress}
	var result: Variant = _join()
	if _should_cancel():
		return {"ok": true, "status": "cancelled"}
	if not result is Dictionary:
		return _fail("invalid_worker_result", "worker")
	return result

func request_cancel() -> void:
	if _thread == null:
		return
	_mutex.lock()
	_cancelled = true
	_mutex.unlock()

func cancel_and_join() -> void:
	if _thread != null:
		request_cancel()
		_join()

func _join() -> Variant:
	var result: Variant = _thread.wait_to_finish()
	_thread = null
	return result

func _should_cancel() -> bool:
	_mutex.lock()
	var result := _cancelled
	_mutex.unlock()
	return result

func _report(tick: int, clock_ms: int) -> void:
	_mutex.lock()
	_progress.tick = tick
	_progress.clock_ms = clock_ms
	_mutex.unlock()

func _run(request: Dictionary) -> Dictionary:
	if _should_cancel():
		return {"ok": true, "status": "cancelled"}
	var prepared := Adapter.prepare_fresh(request)
	if not prepared.ok:
		return prepared
	var owner: RefCounted = prepared.owner
	var result := _run_owner(owner, request.route_id)
	owner.close()
	return result

func _run_owner(owner: RefCounted, route: String) -> Dictionary:
	if _should_cancel():
		return {"ok": true, "status": "cancelled"}
	var published: Dictionary = owner.publish()
	if not published.ok:
		return published
	var orders: Dictionary = ORDERS[route]
	var projection: Dictionary = published.frame.projection
	var points: Array = projection.operation.route_points
	for tick in LIMIT_TICKS:
		if _should_cancel():
			return {"ok": true, "status": "cancelled"}
		if orders.has(tick):
			var issued := _issue(owner, orders[tick], points, projection)
			if not issued.ok:
				return issued
		var advanced := Adapter.advance(owner)
		if not advanced.ok:
			return advanced
		if advanced.has("movement_error"):
			return _fail(str(advanced.movement_error), "worker.movement")
		projection = advanced.frame.projection
		var summary: Dictionary = advanced.summary
		if summary.over or summary.tick % PROGRESS_INTERVAL == 0:
			_report(summary.tick, summary.clock_ms)
		if summary.over:
			var settlement: Dictionary = summary.settlement
			var terminal: Array = advanced.frame.events.filter(func(event): return event.kind == "operation_settled")
			if terminal.size() != 1 or terminal[0].fact != settlement \
					or settlement.get("tick") != summary.tick or settlement.get("clock_ms") != summary.clock_ms:
				return _fail("invalid_worker_settlement", "worker.settlement")
			return {"ok": true, "status": "completed", "settlement": settlement, "policy": POLICY}
	return _fail("worker_tick_limit", "worker.tick")

func _issue(owner: RefCounted, order: Array, points: Array, projection: Dictionary) -> Dictionary:
	var command := {"side": 0, "kind": order[0]}
	if order[0] == "move":
		var ids := []
		for row in projection.squadrons:
			if row.side == 0 and not row.get("dead", false) and not row.get("out", ""):
				ids.append(row.id)
		command.ids = ids
		command.point = points[order[1]]
	return Adapter.queue(owner, command)

static func _fail(error: String, path: String) -> Dictionary:
	return {"ok": false, "error": error, "path": path}

