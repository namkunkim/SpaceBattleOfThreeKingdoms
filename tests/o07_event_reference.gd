extends SceneTree

const Runtime := preload("res://core/battle/operation_runtime_adapter.gd")
const Store := preload("res://scripts/first_operation_save_store.gd")
const SupplyOwner := preload("res://scripts/o07_supply_owner.gd")
const CASES := [
	{"name": "launch_source", "kind": "missile_launch", "field": "sq", "value": 9999},
	{"name": "launch_target", "kind": "missile_launch", "field": "other", "value": 9999},
	{"name": "rejected_side", "kind": "rejected", "field": "other", "value": 2},
]

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[1].is_absolute_path() or not DirAccess.dir_exists_absolute(args[1]):
		printerr("Usage: -- seed|verify ABSOLUTE_FIXTURE_DIRECTORY")
		quit(1)
		return
	match args[0]:
		"seed": _seed(args[1])
		"verify": _verify(args[1])
		_: _expect(false, "unknown mode")
	quit(0 if failures == 0 else 1)


func _seed(root: String) -> void:
	var profile := {"profile_id": "o07-event-reference", "rules": PocSetup.profile().rules,
		"ally": [{"name": "A", "role": "A", "ships": 30, "lv": 1, "x": 500, "y": 500, "p": 0, "flag": true}],
		"foe": [{"name": "B", "role": "B", "ships": 30, "lv": 1, "x": 750, "y": 500, "p": 0, "flag": true}],
		"reinf": []}
	var input := {"mode": "operation", "format": "p02/restricted-headless/1", "profile": profile,
		"seed": 20824, "hz": 10, "initial_controls": [], "policy": "none", "max_ticks": 1000}
	var made := Runtime.create(input)
	if not _expect(made.ok, "create restricted fixture: %s" % made.get("error", "")):
		return
	var owner: OperationPrivateState = made.owner
	var issued := owner.issue(BattleSim.command(0, [1], "missile", 2))
	var rejected := owner.issue(BattleSim.command(0, [], "stop"))
	var observed := owner.observe()
	var events: Array = observed.sim._events
	var launch := _event_index(events, "missile_launch")
	var rejection := _event_index(events, "rejected")
	if not _expect(issued.ok and rejected.ok and launch >= 0 and rejection >= 0
			and events[launch].sq == 1 and events[launch].other == 2 and events[rejection].other == 0
			and not observed.fleets.any(func(fleet): return fleet.id == 9999),
			"native launch and rejection fixture"):
		owner.close()
		return
	var started := SupplyOwner.begin(owner, _slot(root, "control"), made.max_ticks)
	if not _expect(started.ok, "start control: %s" % started.get("error", "")):
		owner.close()
		return
	var session: RefCounted = started.session
	_expect(session.observe() == observed, "control preserves native observation")
	session.close()
	var control := Store.read(_slot(root, "control"))
	if not _expect(control.ok and _snapshot(control.payload).view == observed, "control saved native observation"):
		return
	for fixture: Dictionary in CASES:
		var path := _slot(root, fixture.name)
		if not _expect(not FileAccess.file_exists(path) and not FileAccess.file_exists(path + Store.PREVIOUS),
				"unique slot " + fixture.name):
			continue
		var payload: Dictionary = control.payload.duplicate(true)
		var packet := _snapshot(payload)
		var index := _event_index(packet.view.sim._events, fixture.kind)
		packet.view.sim._events[index][fixture.field] = fixture.value
		payload.snapshot = Marshalls.raw_to_base64(var_to_bytes(packet))
		_expect(Store.write(payload, path).ok, "write checksummed " + fixture.name)


func _verify(root: String) -> void:
	var control_path := _slot(root, "control")
	var stored := Store.read(control_path)
	if not _expect(stored.ok, "read control"):
		return
	var control := _snapshot(stored.payload)
	var before := FileAccess.get_file_as_bytes(control_path)
	var opened := SupplyOwner.open(control_path)
	if _expect(opened.ok, "open healthy control: %s" % opened.get("error", "")):
		var session: RefCounted = opened.session
		_expect(not opened.read_only and session.observe() == control.view
			and session.max_ticks() == int(stored.payload.max_ticks)
			and session.last_key().is_empty() and session.settlement_key().is_empty(),
			"healthy control restores the same current authority")
		session.close()
	_expect(_unchanged(control_path, before, stored.payload), "healthy slot unchanged")
	print("O07_EVENT_REFERENCE control accepted=%s sha256=%s" % [opened.ok, FileAccess.get_sha256(control_path)])
	for fixture: Dictionary in CASES:
		_verify_invalid(root, fixture, stored.payload, control)


func _verify_invalid(root: String, fixture: Dictionary, control_payload: Dictionary, control: Dictionary) -> void:
	var path := _slot(root, fixture.name)
	var stored := Store.read(path)
	if not _expect(stored.ok, "valid envelope " + fixture.name):
		return
	var reverted := _snapshot(stored.payload)
	var event: Dictionary = reverted.view.sim._events[_event_index(control.view.sim._events, fixture.kind)]
	var original: Dictionary = control.view.sim._events[_event_index(control.view.sim._events, fixture.kind)]
	_expect(event[fixture.field] == fixture.value, "intended field changed " + fixture.name)
	event[fixture.field] = original[fixture.field]
	var envelope: Dictionary = stored.payload.duplicate()
	envelope.snapshot = control_payload.snapshot
	_expect(reverted == control and envelope == control_payload, "other fields unchanged " + fixture.name)
	var before := FileAccess.get_file_as_bytes(path)
	var opened := SupplyOwner.open(path)
	print("O07_EVENT_REFERENCE %s accepted=%s error=%s sha256=%s" %
		[fixture.name, opened.ok, opened.get("error", ""), FileAccess.get_sha256(path)])
	_expect(not opened.ok and opened.get("error") == "event_reference" and not opened.has("session"), "refuse authority " + fixture.name)
	if opened.ok:
		opened.session.close()
	_expect(_unchanged(path, before, stored.payload), "invalid slot unchanged " + fixture.name)


func _event_index(events: Array, kind: String) -> int:
	return events.find_custom(func(event): return event.kind == kind)


func _snapshot(payload: Dictionary) -> Dictionary:
	return bytes_to_var(Marshalls.base64_to_raw(payload.snapshot))


func _slot(root: String, name: String) -> String:
	return root.path_join(name + ".save")


func _unchanged(path: String, before: PackedByteArray, payload: Dictionary) -> bool:
	var stored := Store.read(path)
	return FileAccess.get_file_as_bytes(path) == before and stored.ok and stored.payload == payload \
		and not FileAccess.file_exists(path + Store.PREVIOUS)


func _expect(ok: bool, label: String) -> bool:
	if not ok:
		failures += 1
		printerr("O07_EVENT_REFERENCE_FAIL ", label)
	return ok
