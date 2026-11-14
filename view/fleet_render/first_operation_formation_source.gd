extends "res://view/fleet_render/battle_source.gd"

const SQUADRON := "RC-LIU-SQ-01"

var _operation_id: String
var _world: Vector2
var _row: Dictionary


func _init(identity: String, extent: Vector2) -> void:
	super(null)
	_operation_id = identity
	_world = extent


func install_frame(frame: Dictionary) -> void:
	_row = {}
	for candidate: Dictionary in frame.projection.squadrons:
		if candidate.side != 0 or candidate.get("squadron_id") != SQUADRON or not candidate.get("out", "").is_empty():
			continue
		_row = candidate.duplicate(true)
		_row["operation_id"] = _operation_id
		_row["tick"] = frame.tick
		_row["ships"] = float(candidate.ships_milli) / 1000.0
		_row["max_ships"] = float(candidate.max_ships_milli) / 1000.0
		_row["contact"] = ""
		if not frame.projection.operation.settlement.is_empty():
			_row["terminal_tick"] = frame.tick
		break


func squadrons() -> Array[Dictionary]:
	var visible: Array[Dictionary] = []
	if not _row.is_empty():
		visible.append(_row)
	return visible


func squadron(id: int) -> Dictionary:
	return _row if _row.get("id") == id else {}


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
