extends SceneTree

const FIXTURE := preload("res://tmp/p02-fifth-20261108/v3/fixture.gd")

class BrokenWorker extends AutoResolver:
	var fault := 0
	var worker_caller := 0

	func _run_legacy() -> Variant:
		worker_caller = OS.get_thread_caller_id()
		# Preserve a valid legacy result while supplying each invalid return.
		sim.st.result = FIXTURE.settlement(3000, ["severe", "unhurt"], false)
		sim.st.win = true
		sim.st.end_reason = "cao_morale_collapse"
		sim.st.over = true
		var facts := BattleOutcome.facts_from_sim(sim)
		match fault:
			0:
				return null
			1:
				facts.erase("win")
				facts["extra"] = true
				facts["t_s"] = "bad"
			2:
				facts.result.cost.foe.remaining = "bad"
		return facts

var checks := 0
var failures := 0
var rows := {}

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FIFTH_FAIL ", label)

func make_brief() -> BattleBrief:
	var b := BattleBrief.new()
	b.seed = 3
	b.difficulty = "입문"
	b.mode = "auto"
	return b

func wait_worker(r: AutoResolver) -> bool:
	if r._thread == null:
		return false
	var deadline := Time.get_ticks_msec() + 120000
	while r._thread.is_alive() and Time.get_ticks_msec() < deadline:
		await process_frame
	return not r._thread.is_alive()

func malformed() -> void:
	for i in 3:
		var key := "B%02d" % (i + 1)
		var b := make_brief()
		var r := BrokenWorker.new(b)
		r.fault = i
		check(r.start(), key + " real start")
		var ready := await wait_worker(r)
		check(ready and r.outcome == null and r._thread != null, key + " worker finished, join pending")
		var published := r.poll()
		check(published and r._thread == null and r.outcome != null, key + " poll joins and publishes fallback")
		if r.outcome:
			var o := r.outcome
			check(o.to_dict() == BattleOutcome.from_sim(r.sim, b).to_dict(), key + " identical legacy result")
			check(o.loss_pct == {"alliance": 30, "foe": 75} and o.grade == "우세" and o.line == "E5", key + " constant fallback values")
			check(r.worker_caller != 0 and r.worker_caller != OS.get_thread_caller_id(), key + " actual worker")
			rows[key] = {"joined": r._thread == null, "worker_caller": r.worker_caller, "main_caller": OS.get_thread_caller_id(), "outcome": o.to_dict()}

func ordering() -> void:
	var r := AutoResolver.new(make_brief())
	check(r.start(), "B04 worker starts")
	var ready := await wait_worker(r)
	check(ready and r._thread != null and r.outcome == null, "B04 finished before cancel")
	r.cancel()
	var polled := r.poll()
	check(r._thread == null and not polled and r.outcome == null, "B04 joined discard")
	rows.B04 = {"ready": ready, "joined": r._thread == null, "poll": polled, "unpublished": r.outcome == null}

	r = AutoResolver.new(make_brief())
	check(r.start(), "B05 worker starts")
	ready = await wait_worker(r)
	check(ready and r._thread != null and r.outcome == null, "B05 finished before poll")
	# Brief metadata is read on the consumer, after the worker has completed.
	r.brief.seed = -4
	r.brief.mode = "direct"
	r.brief.difficulty = "표준"
	polled = r.poll()
	check(polled and r._thread == null and r.outcome != null, "B05 joined and published")
	if r.outcome:
		var first := r.outcome
		var before := first.to_dict()
		check(before.seed == -4 and before.mode == "direct" and before.difficulty == "표준", "B05 current brief")
		r.cancel()
		check(r.poll() and r.poll() and r.outcome == first and r.outcome.to_dict() == before, "B05 repeated poll and cancel preserve outcome")
		rows.B05 = {"joined": r._thread == null, "outcome": before, "repeat": r.poll()}

func mutate(result: Dictionary) -> void:
	result.cost.alliance.remaining = 13
	result.army_morale_bp[1] = 8500
	result.commanders.foe = "captured"

func copies() -> void:
	var sim := BattleSim.new(11)
	var b := make_brief()
	sim.st.win = true
	sim.st.end_reason = "cao_morale_collapse"
	sim.st.result = FIXTURE.settlement(3000, ["severe", "unhurt"], false)
	var original := sim.st.result.duplicate(true)
	var facts := BattleOutcome.facts_from_sim(sim)
	var o := BattleOutcome.from_facts(facts, b)
	var settled := o.to_dict()
	check(settled.loss_pct == {"alliance": 30, "foe": 75} and settled.grade == "우세" and settled.cao_status == "severe" and settled.line == "E5", "B06 fixed original oracle")
	mutate(sim.st.result)
	var changed := BattleOutcome.facts_from_sim(sim)
	check(facts.result == original and o.to_dict() == settled, "B06 original mutation detached")
	check(changed.result == sim.st.result and changed.result != original, "B06 recapture reflects change")
	var changed_o := BattleOutcome.from_facts(changed, b)
	check(changed_o.loss_pct.alliance == 87 and changed_o.grade == "무승부" and changed_o.cao_status == "captured", "B06 new settlement reflects change")
	rows.B06 = {"first": settled, "new": changed_o.to_dict()}

	sim.st.result = original.duplicate(true)
	facts = BattleOutcome.facts_from_sim(sim)
	o = BattleOutcome.from_facts(facts, b)
	mutate(facts.result)
	check(sim.st.result == original and o.to_dict() == settled, "B07 facts mutation detached")
	var again := BattleOutcome.facts_from_sim(sim)
	var new_o := BattleOutcome.from_facts(again, b)
	check(again.result == original and new_o.to_dict() == settled, "B07 fixed original recovered")
	rows.B07 = {"original": sim.st.result, "mutated": facts.result, "outcome": new_o.to_dict()}

func _run() -> void:
	print("FIFTH_USER ", JSON.stringify({"dir": OS.get_user_data_dir(), "initial_files": DirAccess.get_files_at("user://")}))
	await malformed()
	await ordering()
	copies()
	check(rows.size() == 7, "boundary denominator")
	var output := FileAccess.open(OS.get_cmdline_user_args()[0], FileAccess.WRITE)
	output.store_string(JSON.stringify({"rows": rows, "checks": checks, "failures": failures}, "", true, true))
	output.close()
	print("FIFTH_BOUNDARY rows=%d checks=%d failures=%d" % [rows.size(), checks, failures])
	quit(int(failures != 0))
