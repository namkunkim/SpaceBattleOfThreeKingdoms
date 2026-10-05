class_name BattleViewModel
extends RefCounted

# 공개 투영(BattleProjection 사전)을 화면이 읽기 좋은 객체로 옮긴 것. 화면은 코어 상태를 직접 읽지 않고 이것만 읽는다.
# 객체의 정체성(identity)은 전대 ID로 유지된다(렌더러가 객체 비교로 재시작을 알아챈다).
# 척 수는 투영의 1/1000척 정수를 실수 척으로, 시간은 초로 바꿔 둔다(POC 화면 코드가 쓰던 단위).

class FleetView:
	var id := 0
	var side := 0
	var faction := ""
	var fname := ""
	var role := ""
	var portrait := 0
	var form_id := 0
	var form: Array[Vector2] = []
	var ships := 0.0
	var max_ships := 0.0
	var shown := 0.0
	var lv := 1
	var spd := 1.0
	var pos := Vector2.ZERO          # 화면에 그릴 위치(틱 사이 보간)
	var heading := 0.0
	var tpos := Vector2.ZERO         # 이번 틱 위치
	var ppos := Vector2.ZERO         # 직전 틱 위치
	var theading := 0.0
	var pheading := 0.0
	var target: FleetView = null
	var fire_t: FleetView = null
	var has_move := false
	var move_to := Vector2.ZERO
	var missile_cd := 0.0
	var fighter_cd := 0.0
	var defense := false
	var charge_t := 0.0
	var in_cmd := true
	var is_flag := false
	var dead := false
	var range_r := 300.0
	var control := ""
	var formation_id := ""            # 진형 탭용(salvo 규칙에서만 값이 있다)
	var form_to := ""
	var form_left_s := 0.0
	var form_info := {}
	# 화면 전용
	var speech := ""
	var speech_t := 0.0
	var root: Node3D = null
	var nodes: Array[Node3D] = []

class MissileView:
	var id := 0
	var pos := Vector2.ZERO
	var tpos := Vector2.ZERO
	var ppos := Vector2.ZERO
	var side := 0
	var trail := PackedVector2Array()

class SwarmView:
	var id := 0
	var side := 0
	var pts: Array[Dictionary] = []     # {pos}
	var life := 0.0
	var striking := false
	var target_id := -1
	var src_id := -1

var fleets: Array[FleetView] = []
var missiles: Array[MissileView] = []
var swarms: Array[SwarmView] = []
var by_id := {}
var tick := 0
var hz := 10
var clock_s := 0.0
var cp := 0.0                  # CP 점수(실수). 투영의 bp / 10000
var reinf := false
var killed := 0.0
var lost := 0.0
var outcome := {}
var _missile_map := {}
var alpha := 1.0              # 틱 사이 보간 비율(0~1). 표현 구동기가 프레임마다 정한다
var _last_tick := -1

func reset() -> void:
	fleets.clear()
	missiles.clear()
	swarms.clear()
	by_id.clear()
	_missile_map.clear()
	_last_tick = -1
	tick = 0
	clock_s = 0.0

func fleet(id: int) -> FleetView:
	return by_id.get(id)

# 투영을 반영한다. 새 전대가 생기면 FleetView를 만든다(증원). 새로 생긴 전대 목록을 돌려준다.
func apply(proj: Dictionary) -> Array[FleetView]:
	var fresh: Array[FleetView] = []
	var advanced: bool = proj.tick != _last_tick
	_last_tick = proj.tick
	tick = proj.tick
	hz = proj.hz
	clock_s = proj.clock_s
	cp = proj.cp_bp / 10000.0
	reinf = proj.reinf
	killed = proj.killed_milli / 1000.0
	lost = proj.lost_milli / 1000.0
	outcome = proj.outcome
	for s in proj.squadrons:
		var f: FleetView = by_id.get(s.id)
		if f == null:
			f = FleetView.new()
			f.id = s.id
			f.side = s.side
			f.faction = s.faction
			f.fname = s.name
			f.role = s.role
			f.portrait = s.portrait
			f.form_id = s.form_id
			f.form.assign(s.form)
			f.max_ships = s.max_ships_milli / 1000.0
			f.is_flag = s.flagship
			f.range_r = s.range
			f.spd = s.spd
			f.ppos = s.pos
			f.tpos = s.pos
			f.pheading = s.heading
			f.theading = s.heading
			by_id[f.id] = f
			fleets.append(f)
			fresh.append(f)
		elif advanced:
			f.ppos = f.tpos
			f.pheading = f.theading
		f.tpos = s.pos
		f.theading = s.heading
		f.ships = s.ships_milli / 1000.0
		f.shown = s.shown_milli / 1000.0
		f.lv = s.lv
		f.has_move = s.has_move
		f.move_to = s.move_to
		f.missile_cd = s.missile_cd_s
		f.fighter_cd = s.fighter_cd_s
		f.defense = s.defense
		f.charge_t = s.charge_s
		f.in_cmd = s.in_cmd
		f.dead = s.dead
		f.control = s.control
		f.formation_id = s.get("formation_id", "")
		f.form_to = s.get("form_to", "")
		f.form_left_s = s.get("form_left_s", 0.0)
		f.form_info = s.get("form_info", {})
	# 참조는 모두 생긴 뒤에 잇는다
	for s in proj.squadrons:
		var f: FleetView = by_id[s.id]
		f.target = by_id.get(s.target_id) if s.target_id >= 0 else null
		f.fire_t = by_id.get(s.firing_at) if s.firing_at >= 0 else null
	# 미사일: 식별자로 꼬리(trail)를 이어 간다
	var seen := {}
	missiles.clear()
	for m in proj.missiles:
		var mv: MissileView = _missile_map.get(m.id)
		if mv == null:
			mv = MissileView.new()
			mv.id = m.id
			mv.side = m.side
			mv.ppos = m.pos
			mv.tpos = m.pos
			_missile_map[m.id] = mv
		elif advanced:
			mv.ppos = mv.tpos
		mv.tpos = m.pos
		if mv.trail.is_empty() or mv.trail[mv.trail.size() - 1] != m.pos:
			mv.trail.append(m.pos)
			if mv.trail.size() > 8:
				mv.trail.remove_at(0)
		seen[m.id] = true
		missiles.append(mv)
	for id in _missile_map.keys():
		if not seen.has(id):
			_missile_map.erase(id)
	swarms.clear()
	for w in proj.swarms:
		var sv := SwarmView.new()
		sv.id = w.id
		sv.side = w.side
		sv.life = w.life_s
		sv.striking = w.striking
		sv.target_id = w.target_id
		sv.src_id = w.src_id
		for p in w.pts:
			sv.pts.append({"pos": p})
		swarms.append(sv)
	interpolate(alpha)
	return fresh

# 틱 사이 보간. alpha 0 = 직전 틱, 1 = 이번 틱.
func interpolate(a: float) -> void:
	alpha = a
	for f in fleets:
		f.pos = f.ppos.lerp(f.tpos, a)
		f.heading = lerp_angle(f.pheading, f.theading, a)
	for m in missiles:
		m.pos = m.ppos.lerp(m.tpos, a)

func alive(side: int) -> Array[FleetView]:
	var out: Array[FleetView] = []
	for f in fleets:
		if not f.dead and f.side == side:
			out.append(f)
	return out

func flag(side: int) -> FleetView:
	for f in fleets:
		if f.is_flag and f.side == side and not f.dead:
			return f
	return null

func nearest_foe(f: FleetView, max_r: float) -> FleetView:
	var best: FleetView = null
	var bd := max_r
	for o in fleets:
		if o.dead or o.side == f.side:
			continue
		var d := f.pos.distance_to(o.pos)
		if d < bd:
			bd = d
			best = o
	return best
