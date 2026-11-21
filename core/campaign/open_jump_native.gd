extends BattleSim
## Campaign-specific native tick: all combat systems remain live, but only the
## operation policy may end the battle. No changes to legacy BattleSim rules.
var mission_think: Callable
var escort_id := -1

func _substep(first: bool) -> void:
	st.clock_ms += sub_ms
	st.ai_timer -= sub_ms
	if mission_think.is_valid():
		mission_think.call(st.ai_timer <= 0)
	if st.ai_timer <= 0:
		st.ai_timer += R.ai_period_ms
	_fleet_phase(first)
	if salvo and first:
		if skills:
			skills.step()
		if detect:
			detect.step()
		salvo.step()
		if morale:
			morale.step()
		if chain:
			chain.step()
		if cmd:
			cmd.step()
		if supply:
			supply.step()
	_separate()
	_move_missiles()
	_move_swarms()

func _end(_win: bool, _reason: String) -> void:
	pass # Generic flagship/annihilation/time-limit outcomes cannot commit here.

func finish_campaign(win: bool, reason: String, result: Dictionary) -> void:
	st.result = result.duplicate(true)
	super._end(win, reason)

func enter_reserve(definition: Dictionary, side: int) -> FleetState:
	var data := definition.duplicate(true)
	data.wait = 0
	var fleet := _spawn(data, side)
	fleet.control = "direct"
	for category in fleet.next_fire:
		fleet.next_fire[category] += st.tick
	if morale:
		morale._cost_total[side] += fleet.cost0
	if supply:
		fleet.sup_n = supply.ships_of(fleet)
		fleet.sup_ammo = fleet.sup_n * int(supply.S.per_ship.ammo)
		fleet.sup_mat = fleet.sup_n * int(supply.S.per_ship.materials)
		fleet.sup_pos = fleet.pos
	# Never finish_setup(): that would rotate the existing fleets on every spawn.
	if salvo:
		salvo.face_nearest(fleet)
	return fleet

func remove_fleet(fleet: FleetState, reason: String) -> void:
	# The campaign has one explicit shared extraction. The legacy morale exit
	# must not remove Guan/Huang independently before the shared confirmation.
	if reason == "escaped" and fleet.side == 0:
		return
	super.remove_fleet(fleet, reason)


func _fleet_phase(timers: bool) -> void:
	# Escort signals own Huang's route even at low morale. Only the movement
	# pass bypasses forced retreat; native morale, surrender and firing rules
	# still observe the real morale state in the remainder of the combat tick.
	var escort := st.by_id(escort_id)
	var state := escort.mstate if escort else ""
	if escort and state == "retreat":
		escort.mstate = "shaken"
	super._fleet_phase(timers)
	if escort and state == "retreat":
		escort.mstate = state
