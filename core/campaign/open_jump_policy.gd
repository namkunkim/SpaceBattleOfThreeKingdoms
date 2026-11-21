extends RefCounted
## Pure operation policy. The host supplies authoritative post-combat observations.
## This snapshot is NOT a battle save; the host must pair it with the same battle tick.
const MAX_TICK := 2147483647
const PHASES := ["rendezvous", "escort", "capture", "clash", "extraction"]
const OBS := ["liu_alive", "guan_alive", "huang_alive", "liu_contact", "guan_contact",
	"huang_at_base", "liu_at_base", "guan_at_base", "defenders_cleared", "capture_confirmed",
	"recon_reported", "huang_at_jump", "huang_at_exit", "liu_at_exit", "guan_at_exit"]
var _state := {"version": 1, "phase": "rendezvous", "outcome": "active",
	"huang_order": "wait", "jump_open": false, "main_forces_deployed": false,
	"recon_reported": false, "last_tick": -1, "evacuated": []}

func snapshot() -> Dictionary:
	return _state.duplicate(true)

func restore(packet: Dictionary) -> bool:
	if packet.size() != _state.size():
		return false
	for key in _state:
		if not packet.has(key):
			return false
	if not _integer(packet.version) or packet.version != 1 or not _integer(packet.last_tick) or packet.last_tick < -1 or packet.last_tick > MAX_TICK:
		return false
	if packet.phase not in PHASES or packet.outcome not in ["active", "success", "failed"] or packet.huang_order not in ["wait", "advance"]:
		return false
	for key in ["jump_open", "main_forces_deployed", "recon_reported"]:
		if typeof(packet[key]) != TYPE_BOOL:
			return false
	if typeof(packet.evacuated) != TYPE_ARRAY:
		return false
	if packet.jump_open != (packet.phase in ["clash", "extraction"]) or packet.jump_open != packet.main_forces_deployed:
		return false
	if packet.jump_open and not packet.recon_reported:
		return false
	if packet.phase == "rendezvous" and packet.huang_order != "wait":
		return false
	if packet.last_tick == -1 and (packet.phase != "rendezvous" or packet.outcome != "active" or packet.recon_reported):
		return false
	if packet.outcome == "success":
		if packet.phase != "extraction" or packet.evacuated.is_empty() or packet.huang_order != "wait":
			return false
	elif not packet.evacuated.is_empty():
		return false
	var seen := []
	for id in packet.evacuated:
		if id not in ["liu", "guan"] or id in seen:
			return false
		seen.append(id)
	_state = packet.duplicate(true)
	_state.last_tick = int(_state.last_tick)
	_state.version = 1
	return true

func advance(frame: Dictionary, command: String = "") -> Dictionary:
	if not frame.has("tick") or not _integer(frame.tick) or frame.tick < 0 or frame.tick > MAX_TICK:
		return {"ok": false, "error": "invalid_frame"}
	for key in OBS:
		if not frame.has(key) or typeof(frame[key]) != TYPE_BOOL:
			return {"ok": false, "error": "invalid_frame"}
	if command not in ["", "wait", "advance", "confirm_jump"]:
		return {"ok": false, "error": "invalid_command"}
	if _state.outcome != "active":
		return {"ok": true, "events": [], "state": snapshot()}
	if frame.tick <= _state.last_tick:
		return {"ok": false, "error": "stale_tick"}
	if command in ["wait", "advance"] and _state.phase == "rendezvous" and frame.huang_alive and (frame.liu_alive or frame.guan_alive):
		return {"ok": false, "error": "not_joined"}
	var events: Array = []
	_state.last_tick = int(frame.tick)
	if not frame.huang_alive or not (frame.liu_alive or frame.guan_alive):
		_state.outcome = "failed"
		events.append({"kind": "operation_failed"})
		return {"ok": true, "events": events, "state": snapshot()}
	var recon_before: bool = _state.recon_reported
	_state.recon_reported = _state.recon_reported or frame.recon_reported
	if command in ["wait", "advance"]:
		_state.huang_order = command
	match _state.phase:
		"rendezvous":
			if (frame.liu_alive and frame.liu_contact) or (frame.guan_alive and frame.guan_contact):
				_state.phase = "escort"
				_state.huang_order = "advance"
		"escort":
			if frame.huang_at_base:
				_state.phase = "capture"
		"capture":
			if recon_before and frame.huang_at_base and frame.defenders_cleared and frame.capture_confirmed and ((frame.liu_alive and frame.liu_at_base) or (frame.guan_alive and frame.guan_at_base)):
				_state.phase = "clash"
				_state.jump_open = true
				_state.main_forces_deployed = true
				# One atomic host transaction: key, gate and BOTH deployments.
				events.append({"kind": "base_captured", "transmit_key": true,
					"open_jump": true, "deploy": ["cao", "zhou"]})
		"clash":
			if frame.huang_at_jump:
				_state.phase = "extraction"
		"extraction":
			if frame.huang_at_exit:
				_state.huang_order = "wait"
				if command == "confirm_jump" and ((frame.liu_alive and frame.liu_at_exit) or (frame.guan_alive and frame.guan_at_exit)):
					_state.outcome = "success"
					for id in ["liu", "guan"]:
						if frame[id + "_alive"] and frame[id + "_at_exit"]:
							_state.evacuated.append(id)
					events.append({"kind": "jump_confirmed", "evacuated": _state.evacuated.duplicate()})
	return {"ok": true, "events": events, "state": snapshot()}

static func _integer(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and is_finite(float(value)) and float(value) == floor(float(value))


