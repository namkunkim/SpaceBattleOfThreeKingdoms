extends RefCounted

const DIRECT_TICK := 10
const REJECTION := {"ok": false, "error": "unsupported_reinforcement", "path": "profile.reinf"}
const OUTCOMES := [
	["A09", true, "cao_morale_collapse", 999, ["unhurt", "unhurt"], false, "무승부", "J-D4", ["E1", "E2", "E4", "E5", "E6", "E9"]],
	["A10", true, "cao_morale_collapse", 1000, ["severe", "unhurt"], false, "근소 우세", "J-D4", ["E1", "E2", "E4", "E5", "E6", "E9"]],
	["A11", true, "cao_morale_collapse", 2999, ["killed", "unhurt"], false, "근소 우세", "J-D4", ["E5", "E6", "E9"]],
	["A12", true, "cao_morale_collapse", 3000, ["captured", "unhurt"], false, "우세", "J-D4", ["E5", "E6", "E9"]],
	["A13", true, "cao_morale_collapse", 5999, ["unhurt", "captured"], false, "우세", "J-D4", ["E1", "E2", "E4", "E5", "E6"]],
	["A14", true, "cao_morale_collapse", 6000, ["unhurt", "killed"], false, "결정적 승리", "J-D3", ["E1", "E2", "E4", "E5", "E6"]],
	["A15", true, "cao_flagship_lost", 6000, ["severe", "unhurt"], true, "결정적 승리", "J-D6", ["E1", "E2", "E4", "E9"]],
	["A16", false, "time_limit", 6000, ["unhurt", "unhurt"], false, "패배", "J-D10", ["E11"]],
	["A17", false, "simultaneous", 6000, ["unhurt", "unhurt"], false, "패배", "J-D10", ["E11"]],
	["A18", false, "liu_flagship_lost", 6000, ["unhurt", "killed"], false, "패배", "J-D8", ["E11"]],
]

static func settlement(gap: int, commanders: Array, limited: bool) -> Dictionary:
	return {"cost": {"alliance": {"original": 100, "remaining": 70}, "foe": {"original": 200, "remaining": 50}},
		"army_morale_bp": [9000, 9000 - gap], "commanders": {"foe": commanders[0], "alliance": commanders[1]}, "limited": limited}
