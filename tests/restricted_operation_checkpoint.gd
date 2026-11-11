extends SceneTree

const Store := preload("res://scripts/first_operation_save_store.gd")
const Ops := preload("res://scripts/restricted_operation_checkpoint.gd")
var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var profile := {"profile_id": "operating-checkpoint-poc", "rules": PocSetup.profile().rules,
		"ally": [{"name":"A","role":"A","ships":30,"lv":1,"x":500,"y":500,"p":0,"flag":true}],
		"foe": [{"name":"B","role":"B","ships":30,"lv":1,"x":750,"y":500,"p":0,"flag":true}], "reinf":[]}
	var input := {"mode":"operation","format":"p02/restricted-headless/1","profile":profile,
		"seed":20824,"hz":10,"initial_controls":[],"policy":"none","max_ticks":1000}
	var created := Ops.create(input)
	if not created.ok:
		printerr(created)
		quit(1)
		return
	var op: RefCounted = created.session
	var missile := BattleSim.command(0,[1],"missile",2)
	var fighter := BattleSim.command(1,[2],"fighter",1)
	var stop := BattleSim.command(0,[1],"stop")
	expect(op.issue(1,missile).ok and op.issue(2,fighter).ok and op.advance().ok, "actual projectiles")
	expect(op.queue(3,stop).ok and not op.issue(4,stop).ok, "pending prefix")
	var before: Dictionary = op.observe()
	expect(not before.missiles.is_empty() and not before.swarms.is_empty() and before.state.clock_ms == 100,
		"active missiles, swarms and actual logical clock")
	var path := "user://operating.pcopstate"
	expect(op.write_checkpoint(path).ok, "operating checkpoint file")
	expect(op.advance().ok, "uninterrupted suffix")
	var after: Dictionary = op.observe()
	expect(after.sim.command_log.size()==3 and after.sim._queue.is_empty(), "suffix applied once")
	var duplicate := [{"seq":3,"command":stop}]
	var restored: Dictionary = op.restore_checkpoint(path,duplicate)
	expect(restored.ok, "same-context restore: %s" % restored)
	expect(op.observe()==before, "exact restored projectile, clock, events and pending state")
	expect(op.advance().ok and op.observe()==after, "pending plus duplicate suffix resolves once")
	var active: Dictionary = op.observe()
	expect(op.restore_checkpoint(path,[{"seq":2,"command":fighter}]).get("error")=="invalid_checkpoint_suffix"
		and op.observe()==active, "already applied prefix cannot replay")
	expect(op.restore_checkpoint(path,[{"seq":3,"command":fighter}]).get("error")=="conflicting_pending_command"
		and op.observe()==active, "conflicting duplicate preserves active state")
	var incompatible := input.duplicate(true)
	incompatible.seed += 1
	var other: RefCounted = Ops.create(incompatible).session
	var other_before: Dictionary = other.observe()
	expect(other.restore_checkpoint(path).get("error")=="replacement_context_mismatch"
		and other.observe()==other_before, "different context leaves active state unchanged")
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	expect(not op.restore_checkpoint(path).ok and op.observe()==active, "damaged file preserves active state")
	op._owner._sim._end(false, "fixture_terminal")
	expect(op.write_checkpoint("user://terminal.pcopstate").get("error") == "unsupported_terminal_settlement",
		"terminal settlement lacks a durable effect key")
	op.close()
	other.close()
	_service_round_trip(input)
	_event_reference_round_trip(input)
	print("K08_RESTRICTED %d/%d" % [checks-failures,checks])
	quit(0 if failures==0 else 1)


func _service_round_trip(input: Dictionary) -> void:
	var fixture := input.duplicate(true)
	var combat := SalvoFixture.combat()
	for key in ["morale", "victory", "command", "stratagem", "assault", "terrain"]:
		combat.erase(key)
	fixture.profile.combat = combat
	fixture.profile.ally = [SalvoFixture.def("S", 800, 450, [["SHP-05", 2], ["SHP-04", 2]], true),
		SalvoFixture.def("C", 925, 450, [["SHP-04", 2]])]
	fixture.profile.foe = [SalvoFixture.def("F", 1000, 450, [["SHP-02", 4]], true)]
	for fleet in fixture.profile.ally:
		fleet.faction_id = "liu_bei"
	fixture.profile.foe[0].faction_id = "cao_cao"
	var made := Ops.create(fixture)
	expect(made.ok, "active service fixture: %s" % made.get("error",""))
	if not made.ok:
		return
	var session: RefCounted = made.session
	var sim: BattleSim = session._owner._sim
	# Fixture initial conditions suppress unrelated attacks. Supply and
	# Detection still advance through their ordinary native module steps.
	sim.st.ai_timer = 1 << 40
	sim.endless = true
	for fleet in sim.st.fleets:
		for category in fleet.next_fire:
			fleet.next_fire[category] = 1 << 40
	for category in sim.st.fleets[1].ammo:
		sim.st.fleets[1].ammo[category] = 0
	var stock: int = sim.st.fleets[0].sup_ammo
	for i in 599:
		session.advance()
		session.drain_events()
	var before: Dictionary = session.observe()
	expect(before.service.supply.active and before.service.detection.active
		and not before.service.detection.contacts[0].is_empty()
		and before.fleets[1].sup_prog > 0 and before.fleets[1].supplied == 0, "active service and pending payment")
	var path := "user://service.pcopstate"
	expect(session.write_checkpoint(path).ok, "service checkpoint file")
	for i in 70:
		session.advance()
	var after: Dictionary = session.observe()
	var events: Array = session.drain_events().events
	var paid := events.filter(func(event): return event.kind == "supply")
	expect(after.fleets[1].supplied == 1 and after.fleets[0].sup_ammo < stock and paid.size() == 1,
		"native stock spent and one supply completion")
	var restored: Dictionary = session.restore_checkpoint(path)
	expect(restored.ok and session.observe() == before, "service file restores source, progress and contacts")
	for i in 70:
		session.advance()
	expect(session.observe() == after and session.drain_events().events == events,
		"same supply payment, updated contacts and ordered events after restore")
	session.close()



func _event_reference_round_trip(input: Dictionary) -> void:
	var created := Ops.create(input)
	expect(created.ok, "event fixture prepared")
	if not created.ok:
		return
	var session: RefCounted = created.session
	var missile := BattleSim.command(0, [1], "missile", 2)
	var no_selection := BattleSim.command(0, [], "stop")
	expect(session.issue(1, missile).ok and session.issue(2, no_selection).ok, "emit launch and command rejection")
	var saved: Dictionary = session.observe()
	var events: Array = saved.sim._events
	var launch_index := events.find_custom(func(event): return event.kind == "missile_launch")
	var rejected_index := events.find_custom(func(event): return event.kind == "rejected" and event.other == 0)
	expect(launch_index >= 0 and rejected_index >= 0, "real event references and rejection side are present")
	if launch_index < 0 or rejected_index < 0:
		session.close()
		return
	var path := "user://event-reference.pcopstate"
	expect(session.write_checkpoint(path).ok, "save the live event fixture")
	var stored := Store.read(path)
	expect(stored.ok, "read the saved envelope")
	if not stored.ok:
		session.close()
		return
	session.drain_events()
	expect(session.restore_checkpoint(path).ok and session.observe() == saved,
		"valid fleet IDs and rejection side zero restore exactly")
	session.drain_events()
	var active: Dictionary = session.observe()

	for case in [
		{"index": launch_index, "field": "sq", "value": 9999},
		{"index": launch_index, "field": "other", "value": 9999},
		{"index": launch_index, "field": "sq", "value": -2},
		{"index": rejected_index, "field": "other", "value": 2},
	]:
		var payload: Dictionary = stored.payload.duplicate(true)
		var snapshot: Dictionary = bytes_to_var(Marshalls.base64_to_raw(payload.snapshot))
		snapshot.view.sim._events[case.index][case.field] = case.value
		payload.snapshot = Marshalls.raw_to_base64(var_to_bytes(snapshot))
		expect(Store.write(payload, path).ok, "rewrite envelope with a valid checksum")
		var result: Dictionary = session.restore_checkpoint(path)
		expect(result.get("error") == "event_reference" and result.get("path") == "snapshot.sim._events",
			"reject unresolved event reference %s=%s: %s" % [case.field, case.value, result])
		expect(session.observe() == active, "unresolved event reference preserves live state")
	session.close()


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("K08_FAIL ",label)

