extends SceneTree

# Actual legacy BattleSim/TickClock partial-substep regression. No save/adapter/operation integration.
const EXPECTED_TRACE := [[1, 50], [1, 100], [2, 150]]
const SEEDS := [0, 1, 20824, 20825, 20826, 90210, 123456789, 2147483647, 2147483648, 4294967295]

class PartialStopSim extends BattleSim:
	var trace: Array = []
	var natural_end := false

	func _substep(first: bool) -> void:
		super._substep(first)
		trace.append([st.tick, st.clock_ms])
		if st.over:
			natural_end = true
		if st.clock_ms == 150:
			_end(true, "i01b_partial_clock_fixture")

func _initialize() -> void:
	call_deferred("_run")

func _case(seed_id: int, speed: float, paused: bool) -> Dictionary:
	var sim := PartialStopSim.new(seed_id, BattleRules.TICK_HZ)
	var clock := TickClock.new()
	clock.set_speed(speed)
	if not TestCheck.ok(self, not sim.endless and not sim.st.over and sim.st.tick == 0 and sim.st.clock_ms == 0, "initial clock fixture"): return {}
	var frames := 0
	var pause_done := false
	var paused_frames := 0
	while not sim.st.over and frames < 1000:
		frames += 1
		var n := clock.advance(0.025)
		if not TestCheck.ok(self, n >= 0 and n <= 1, "frame at most one tick"): return {}
		for i in n:
			if not TestCheck.ok(self, not sim.st.over, "never step after end"): return {}
			sim.step()
			if paused and not pause_done and sim.st.tick == 1:
				if not TestCheck.ok(self, sim.st.clock_ms == 100 and sim.trace == [[1, 50], [1, 100]], "first complete tick before pause"): return {}
				var frozen_fp := sim.fingerprint()
				var frozen_acc := clock.acc
				clock.set_speed(0.0)
				for p in 20:
					paused_frames += 1
					if not TestCheck.ok(self, clock.advance(0.025) == 0 and sim.st.tick == 1 and sim.st.clock_ms == 100 and sim.fingerprint() == frozen_fp and clock.acc == frozen_acc, "paused frame unchanged"): return {}
				clock.set_speed(speed)
				pause_done = true
	if not TestCheck.ok(self, frames < 1000 and sim.st.over and not sim.natural_end, "injected end reached without natural end"): return {}
	if not TestCheck.ok(self, sim.trace == EXPECTED_TRACE and sim.trace.size() == 3, "actual substep trace 50/100/150"): return {}
	if not TestCheck.ok(self, sim.st.tick == 2 and sim.st.clock_ms == 150 and sim.st.end_tick == 2 and sim.st.end_ms == 150, "partial tick preserves clock150 independently of tick2"): return {}
	if not TestCheck.ok(self, is_equal_approx(sim.dt, 0.1) and sim.sub_ms == 50 and clock.dropped == 0.0, "dt restored, substep50, no dropped ticks"): return {}
	if not TestCheck.ok(self, pause_done == paused and paused_frames == (20 if paused else 0), "pause coverage"): return {}
	var ends := 0
	for event in sim.drain_events():
		if event.kind == "battle_end":
			ends += 1
			if not TestCheck.ok(self, event.value == "i01b_partial_clock_fixture", "actual end event reason"): return {}
	if not TestCheck.ok(self, ends == 1, "one actual end event"): return {}
	return {"fingerprint": sim.fingerprint(), "trace": sim.trace.duplicate(true), "frames": frames, "paused_frames": paused_frames}

func _run() -> void:
	var cases := 0
	for seed_id in SEEDS:
		var baseline := {}
		for speed in [1.0, 2.0, 4.0]:
			for paused in [false, true]:
				var result := _case(seed_id, speed, paused)
				if result.is_empty(): return
				if baseline.is_empty():
					baseline = result
				elif not TestCheck.ok(self, result.fingerprint == baseline.fingerprint and result.trace == baseline.trace, "same seed logical result independent of speed/pause"): return
				cases += 1
	if not TestCheck.ok(self, cases == 60, "clock fixture cases60"): return
	print("I01B_P1_PARTIAL_CLOCK_PASS cases=60 seeds=10 speeds=3 pause_variants=2 trace=50,100,150 tick=2 end_ms=150")
	print("ORIGINAL_I01_A04_A05_A06=NOT_READY; no host/replay adapters, checkpoint restore, or product geometry validation")
	quit(0)