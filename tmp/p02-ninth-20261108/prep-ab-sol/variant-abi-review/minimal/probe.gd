extends SceneTree

func emit_case(name: String, value: Variant) -> void:
	print("P02_ABI ", name, " ", var_to_bytes(value).hex_encode())

func _initialize() -> void:
	emit_case("bool", true)
	emit_case("int64", 4294967296)
	emit_case("f32", 1.5)
	emit_case("f64", 1.0 / 10.0)
	emit_case("string-name", &"abi-probe")
	emit_case("vector2", Vector2(4096.0, 1.0))
	var typed_ids: Array[int] = [7, 15]
	emit_case("typed-array", typed_ids)
	var typed_positions: Dictionary[int, Vector2] = {15: Vector2(1500.0, 450.0), 7: Vector2(400.0, 450.0)}
	emit_case("typed-dict", typed_positions)
	var nested := {"active": true, "contacts": [{15: {"seen": 11, "pos": Vector2(500.0, 450.0), "state": "estimated", "conf_bp": 5000, "err_r": 30.0}}, {}]}
	emit_case("ordered-contact", nested)
	var origin := Vector2.ZERO
	emit_case("distance-ordered", [origin.distance_to(Vector2(4096.0, 1.0)),
		origin.distance_to(Vector2(4096.0, 0.0)), origin.distance_to(Vector2(4096.0, 2.0))])
	quit(0)
