extends "res://view/fleet_render/battle_source.gd"

const SQUADRON := "RC-LIU-SQ-01"

var _operation_id: String
var _world: Vector2
var _rows: Array[Dictionary] = []
var _squadrons: Array


func _init(identity: String, extent: Vector2, squadron_ids := [SQUADRON]) -> void:
	super(null)
	_operation_id = identity
	_world = extent
	_squadrons = squadron_ids


func install_frame(frame: Dictionary) -> void:
	_rows.clear()
	for candidate: Dictionary in frame.projection.squadrons:
		if candidate.side != 0 or candidate.get("squadron_id") not in _squadrons or not candidate.get("out", "").is_empty():
			continue
		var row := candidate.duplicate(true)
		row["operation_id"] = _operation_id
		row["tick"] = frame.tick
		row["ships"] = float(candidate.ships_milli) / 1000.0
		row["max_ships"] = float(candidate.max_ships_milli) / 1000.0
		row["contact"] = ""
		if frame.get("phase") == "resume":
			row["formation_resume"] = true
		if not frame.projection.operation.settlement.is_empty():
			row["terminal_tick"] = frame.tick
		_rows.append(row)


func squadrons() -> Array[Dictionary]:
	return _rows


func squadron(id: int) -> Dictionary:
	for row in _rows:
		if row.id == id:
			return row
	return {}


func camera() -> Camera3D:
	return null


func zoom() -> float:
	return 1.0


func to3(point: Vector2, y := 0.0) -> Vector3:
	var local := (point - _world * 0.5) * CameraRig.S
	return Vector3(local.x, y, local.y)


func world_size() -> Vector2:
	return _world


func unit_scale() -> float:
	return CameraRig.S


func drain_salvo_fx() -> Array:
	return []


func missiles() -> Array:
	return []


func swarms() -> Array:
	return []
