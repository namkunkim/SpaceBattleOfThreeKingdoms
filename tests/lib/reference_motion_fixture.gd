class_name ReferenceMotionFixture
extends RefCounted

# 실제 적벽 코어의 정지 자동 교전 fixture. 정본·피해·회피 수치는 바꾸지 않는다.
# 기존 hold_distance 시험처럼 ai_timer만 미뤄 배치/명령을 AI가 덮지 않게 한다.
static func prepare(battle: Node) -> Dictionary:
	battle.set_process(false)
	battle.presentation.set_process(false)
	battle.sim.st.ai_timer = 1 << 40
	var a: FleetState = null
	var b: FleetState = null
	# 기존 편성·센서·전자전·사거리로 160px에서 상호 자연 접촉할 수 있는
	# 비기함 전열만 고른다. 최대 아군 선체, 적 선체 차이, 배열순으로 결정한다.
	for ally in battle.sim.st.fleets:
		if not _front(ally, 0):
			continue
		for enemy in battle.sim.st.fleets:
			if not _front(enemy, 1) or not _mutual_contact(battle, ally, enemy):
				continue
			if a == null or ally.max_hull > a.max_hull or (ally == a and absi(enemy.max_hull - ally.max_hull) < absi(b.max_hull - a.max_hull)):
				a = ally
				b = enemy
	if a == null or b == null:
		push_error("REFERENCE_MOTION_FIXTURE_FAIL no mutually detectable non-flag front pair")
		return {}
	var field: Vector2 = battle.FIELD_SIZE
	var margin: float = float(battle.sim.R.edge) + 10.0
	for f in battle.sim.st.fleets:
		f.pos = field - Vector2.ONE * margin if f.side == 1 else Vector2.ONE * margin
		f.has_move = false
		f.target_id = -1
		f.face_set = false
		f.strafe = false
		f.route.clear()
		f.charge = 0
		f.control = "direct"
		f.wait = 9000
	a.pos = Vector2(650, 450)
	a.heading = 0.0
	b.pos = Vector2(810, 450)
	b.heading = PI
	for f in battle.sim.st.fleets:
		f.home = f.pos
	var fixed := {"ally_id": a.id, "ally_name": a.name, "enemy_id": b.id, "enemy_name": b.name, "battle_seed": battle.battle_seed, "ally_initial_ships": a.ships, "enemy_initial_ships": b.ships, "ally_pos": a.pos, "enemy_pos": b.pos}
	fixed["ally_range"] = a.range_r
	fixed["enemy_range"] = b.range_r
	if battle.sim.detect:
		fixed["ally_sensor"] = battle.sim.detect.sensor_of(a)
		fixed["enemy_sensor"] = battle.sim.detect.sensor_of(b)
		fixed["ally_ew"] = battle.sim.detect.ew_of(a)
		fixed["enemy_ew"] = battle.sim.detect.ew_of(b)
		fixed["ally_detection_score"] = battle.sim.detect.score(battle.sim.detect.sensor_of(a), a, b)
		fixed["enemy_detection_score"] = battle.sim.detect.score(battle.sim.detect.sensor_of(b), b, a)
	print("REFERENCE_MOTION_FIXTURE ", JSON.stringify(fixed))
	battle._sync()
	for f in battle.vm.fleets:
		f.ppos = f.tpos
		f.pheading = f.theading
	battle.vm.interpolate(1.0)
	battle._sim_acc_clock.acc = 0.0
	battle.presentation.renderer.reset()
	battle.presentation.renderer.update(0.0)
	return fixed

static func stationary_ok(battle: Node, fixed: Dictionary) -> bool:
	var a: FleetState = battle.sim.st.by_id(fixed.ally_id)
	var b: FleetState = battle.sim.st.by_id(fixed.enemy_id)
	return not battle.sim.st.over and not a.dead and not b.dead and a.ships > 0 and b.ships > 0 and a.pos == fixed.ally_pos and b.pos == fixed.enemy_pos

static func active(battle: Node, fixed: Dictionary) -> bool:
	var a: FleetState = battle.sim.st.by_id(fixed.ally_id)
	var b: FleetState = battle.sim.st.by_id(fixed.enemy_id)
	return a.fire_id == b.id and b.fire_id == a.id

static func _front(f: FleetState, side: int) -> bool:
	return f.side == side and not f.is_flag and not f.dead and int(f.comp0.get("SHP-04", 0)) > 0 and int(f.comp0.get("SHP-08", 0)) == 0

static func _mutual_contact(battle: Node, a: FleetState, b: FleetState) -> bool:
	if minf(a.range_r, b.range_r) < 160.0:
		return false
	if not battle.sim.detect:
		return true
	var apos := a.pos
	var bpos := b.pos
	a.pos = Vector2(650, 450)
	b.pos = Vector2(810, 450)
	var d: Detection = battle.sim.detect
	var ok := d.level_of(d.score(d.sensor_of(a), a, b)) > 0 and d.level_of(d.score(d.sensor_of(b), b, a)) > 0
	a.pos = apos
	b.pos = bpos
	return ok