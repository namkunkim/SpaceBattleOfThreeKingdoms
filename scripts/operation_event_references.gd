extends RefCounted

enum Scope { RESTRICTED, O07 }


# Call only after Private.prepare has checked the roster and event shapes.
static func valid(view: Dictionary, scope := Scope.RESTRICTED) -> bool:
	var fleet_ids := {}
	for fleet: Dictionary in view.fleets:
		fleet_ids[fleet.id] = true
	for event: Dictionary in view.sim._events:
		if scope == Scope.O07 and event.kind not in ["missile_launch", "rejected"]:
			continue
		# Missile launches always record both fleet IDs. The roster retains
		# fleets after sinking, surrender, or escape.
		if scope == Scope.O07 and event.kind == "missile_launch":
			if not fleet_ids.has(event.sq) or not fleet_ids.has(event.other):
				return false
			continue
		if event.sq != -1 and not fleet_ids.has(event.sq):
			return false
		# Command rejection stores the issuing side in other.
		if event.kind == "rejected":
			if event.other not in [0, 1]:
				return false
		elif event.other != -1 and not fleet_ids.has(event.other):
			return false
	return true
