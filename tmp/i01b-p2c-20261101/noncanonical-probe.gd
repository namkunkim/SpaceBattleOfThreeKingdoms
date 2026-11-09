extends SceneTree
const Private = preload("res://core/battle/operation_private_state.gd")
func _initialize() -> void:
	var result: Dictionary = Private.create({}, 0, BattleRules.TICK_HZ)
	var passed: bool = not result.ok and result.get("error") == "noncanonical_runtime_class" and not result.has("owner")
	print("I01B_P2C_NONCANONICAL_", "PASS" if passed else "FAIL", " result=", result)
	quit(0 if passed else 1)