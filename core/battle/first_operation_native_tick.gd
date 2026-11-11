extends BattleSim

# Routes own movement in this development slice. Run the same native
# detection, salvo and projectile logic with already-validated poses.
func advance_combat() -> void:
	st.tick += 1
	st.clock_ms += roundi(dt * 1000.0)
	if detect:
		detect.step()
	salvo.step()
	var tick_dt := dt
	var substeps := maxi(1, ceili(dt / BattleRules.REF_DT - 1e-9))
	dt = tick_dt / substeps
	sub_ms = roundi(dt * 1000.0)
	for step in substeps:
		_move_missiles()
		_move_swarms()
	dt = tick_dt

func enter_reserve(definition: Dictionary, pose: Dictionary, position: Vector2) -> FleetState:
	var data := definition.duplicate(true)
	data.x = position.x
	data.y = position.y
	var fleet := _spawn(data, 1)
	initialize_fleet(fleet, pose)
	st.reinf = true
	st.reinf_ms = st.clock_ms
	return fleet

static func initialize_fleet(fleet: FleetState, pose: Dictionary) -> void:
	fleet.heading = pose.heading
	fleet.control = "direct" if fleet.side == 0 else "delegate"
	for category in fleet.ammo:
		fleet.ammo[category] = floori(float(fleet.ammo[category]) * int(pose.ammo_bp) / BattleRules.BP)

# The active bindings are detection and salvo. The latter has no mutable
# tick-local fields, while the former owns the contact table. Cache entries
# in BattleState are derived and rebuilt after rollback.
func checkpoint_tick() -> Dictionary:
	return {
		"state": _fields(st, ["fleets", "missiles", "swarms", "_idx", "_idx_n"]),
		"fleets": _entities(st.fleets), "missiles": _entities(st.missiles), "swarms": _entities(st.swarms),
		"events": _events.duplicate(true), "first_hit_tick": first_hit_tick, "sub_ms": sub_ms,
		"contacts": detect.contacts.duplicate(true) if detect else [],
	}

# A detached witness used to verify replay. Unlike rollback_tick's payload,
# this data contains no entity references and is never applied as state.
func replay_witness() -> Dictionary:
	return {
		"state": _fields(st, ["fleets", "missiles", "swarms", "_idx", "_idx_n"]),
		"fleets": st.fleets.map(func(entity): return _fields(entity)),
		"missiles": st.missiles.map(func(entity): return _fields(entity)),
		"swarms": st.swarms.map(func(entity): return _fields(entity)),
		"events": _events, "command_log": command_log, "queue": _queue,
		"first_hit_tick": first_hit_tick, "sub_ms": sub_ms, "dt": dt,
		"contacts": detect.contacts if detect else [],
		"rng_context": rng.profile_id,
	}

func rollback_tick(checkpoint: Dictionary) -> void:
	_restore(st, checkpoint.state)
	_restore_entities(st.fleets, checkpoint.fleets)
	_restore_entities(st.missiles, checkpoint.missiles)
	_restore_entities(st.swarms, checkpoint.swarms)
	st._idx.clear()
	st._idx_n = -1
	_events = checkpoint.events
	first_hit_tick = checkpoint.first_hit_tick
	sub_ms = checkpoint.sub_ms
	if detect:
		detect.contacts = checkpoint.contacts

static func _fields(object: Object, excluded: Array = []) -> Dictionary:
	var fields := {}
	for property in object.get_property_list():
		if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE) or property.name in excluded:
			continue
		var value: Variant = object.get(property.name)
		fields[property.name] = value.duplicate(true) if value is Array or value is Dictionary else value
	return fields

static func _entities(entities: Array) -> Array:
	var saved := []
	for entity in entities:
		saved.append({"entity": entity, "fields": _fields(entity)})
	return saved

static func _restore(object: Object, fields: Dictionary) -> void:
	for key in fields:
		object.set(key, fields[key])

static func _restore_entities(target: Array, saved: Array) -> void:
	target.clear()
	for row in saved:
		_restore(row.entity, row.fields)
		target.append(row.entity)
