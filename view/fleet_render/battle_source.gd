class_name BattleSource
extends RefCounted

# 표현 계층이 전투 상태를 읽는 유일한 통로.
# 지금은 POC(FleetBattle3D.gd)의 Fleet 객체를 읽는다. M1에서 BattleProjection이 정해지면
# 이 파일만 고쳐 같은 모양의 사전을 돌려주면 된다.
#
# squadron 사전: {id, side, name, role, portrait, pos(px), heading, ships, max_ships, flagship,
#                 dead, target_id, firing_at, formation, defense, charge_t, in_cmd,
#                 missile_cd, fighter_cd, speech, speech_t, has_move, move_to, lv}

var battle: Node

func _init(b: Node) -> void:
	battle = b

func squadrons() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in battle.fleets:
		out.append(_sq(f))
	return out

func squadron(id: int) -> Dictionary:
	var f = battle.by_id(id)
	return _sq(f) if f else {}

func _sq(f) -> Dictionary:
	return {
		"id": f.id, "side": f.side, "name": f.fname, "role": f.role, "portrait": f.portrait,
		"pos": f.pos, "heading": f.heading, "ships": f.ships, "max_ships": f.max_ships,
		"flagship": f.is_flag, "dead": f.dead,
		"target_id": f.target.id if f.target else -1,
		"firing_at": f.fire_t.id if (f.fire_t and not f.fire_t.dead) else -1,
		"formation": f.form_id % battle.FORM_NAMES.size(),
		"formation_name": battle.FORM_NAMES[f.form_id % battle.FORM_NAMES.size()],
		"defense": f.defense, "charge_t": f.charge_t, "in_cmd": f.in_cmd,
		"missile_cd": f.missile_cd, "fighter_cd": f.fighter_cd,
		"speech": f.speech, "speech_t": f.speech_t,
		"has_move": f.has_move, "move_to": f.move_to, "lv": f.lv, "range": f.range_r,
	}

func missiles() -> Array:
	var out := []
	for m in battle.missiles:
		out.append({"key": m, "pos": m.pos, "side": m.side})
	return out

func swarms() -> Array:
	var out := []
	for s in battle.swarms:
		var pts := []
		for p in s.pts:
			pts.append(p.pos)
		out.append({"side": s.side, "pts": pts, "life": s.life})
	return out

func state() -> String:
	return battle.G.get("state", "")

func clock_s() -> float:
	return battle.G.get("t", 0.0)

func speed() -> int:
	return int(battle.G.get("speed", 1))

func zoom() -> float:
	return battle.cam_z

func to3(p: Vector2, y := 0.0) -> Vector3:
	return battle.w3(p, y)

func world_size() -> Vector2:
	return battle.WORLD

func unit_scale() -> float:
	return battle.S
