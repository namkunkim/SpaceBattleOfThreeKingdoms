extends SceneTree
const Private := preload("res://core/battle/operation_private_state.gd")
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var profile: Dictionary = PocSetup.profile()
	profile.reinf = []
	var created: Dictionary = Private.create(profile, 0, BattleRules.TICK_HZ)
	if not created.ok:
		print("PROBE_CREATE_FAIL ", created)
		quit(1)
		return
	var source: OperationPrivateState = created.owner
	var captured: Dictionary = source.capture_completed()
	var packet: Dictionary = captured.packet
	var normal: Dictionary = Private.prepare(packet)
	print("NORMAL_PREPARE ok=", normal.ok)
	if normal.ok: normal.owner.close()
	packet.view.fleets[0].form.clear()
	var malformed: Dictionary = Private.prepare(packet)
	print("EMPTY_FORM_PREPARE ok=", malformed.ok, " error=", malformed.get("error", ""))
	if malformed.ok:
		var restored: OperationPrivateState = malformed.owner
		var target: int = -1
		for fleet in restored._sim.st.fleets:
			if fleet.side != restored._sim.st.fleets[0].side:
				target = fleet.id
				break
		print("EMPTY_FORM_BEFORE_MISSILE size=", restored._sim.st.fleets[0].form.size(), " target=", target)
		print("EMPTY_FORM_ISSUE result=", restored.issue(BattleSim.command(0, [restored._sim.st.fleets[0].id], "missile", target)))
		restored.close()
	source.close()
	quit(0)
