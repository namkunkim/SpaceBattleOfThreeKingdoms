class_name BattleState
extends RefCounted

# 전투 한 판의 코어 상태 전체. 저장 = 초기 설정(시드, 틱 폭) + 명령 기록 + 현재 틱.

class Missile:
	var id := 0
	var pos := Vector2.ZERO
	var target_id := -1
	var src_id := -1
	var dmg := 0          # 1/1000척
	var v := 260.0
	var wob := 0.0
	var age := 0          # ms
	var side := 0
	var dead := false

class Swarm:
	var id := 0
	var src_id := -1
	var target_id := -1
	var life := 0         # ms
	var side := 0
	var dps := 0          # 1/1000척 / 초
	var pts: Array[Dictionary] = []   # {pos: Vector2, a: float, r: float, w: float}
	var striking := false # 이번 틱에 피해를 줬다(연출용)

var hz := BattleRules.TICK_HZ
var seed_id := 0
var tick := 0
var clock_ms := 0         # 하위 걸음 단위 게임 시계(ms)
var fleets: Array[FleetState] = []
var missiles: Array[Missile] = []
var swarms: Array[Swarm] = []
var cp := 0
var ecp := 0
var cp_rem := 0
var ecp_rem := 0
var killed := 0           # 1/1000척
var lost := 0
var reinf := false
var reinf_ms := -1
var ai_timer := 0
var next_id := 1
var form_counter := 0
var next_event_id := 1
var over := false
var win := false
var end_reason := ""      # "annihilation" | "flagship_lost"
var end_tick := -1
var end_ms := -1

func clock_s() -> float:
	return clock_ms / 1000.0

func by_id(id: int) -> FleetState:
	for f in fleets:
		if f.id == id:
			return f
	return null

func alive(side: int) -> Array[FleetState]:
	var out: Array[FleetState] = []
	for f in fleets:
		if not f.dead and f.side == side:
			out.append(f)
	return out

func flag(side: int) -> FleetState:
	for f in fleets:
		if f.is_flag and f.side == side and not f.dead:
			return f
	return null

func live_target(f: FleetState) -> FleetState:
	if f.target_id < 0:
		return null
	var t := by_id(f.target_id)
	return t if (t and not t.dead) else null

func nearest_foe(f: FleetState, max_r: float) -> FleetState:
	var best: FleetState = null
	var bd := max_r
	for o in fleets:
		if o.dead or o.side == f.side:
			continue
		var d := f.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best

func new_event_id() -> int:
	next_event_id += 1
	return next_event_id - 1
