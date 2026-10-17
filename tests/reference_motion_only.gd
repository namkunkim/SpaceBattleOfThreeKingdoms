extends SceneTree

# 30/60fps × 1/4배속: 정지 교전·사망·격침·슬롯 복귀·이동/선회/평행 후퇴.
# 가짜 공개 투영으로 기동 불간섭을 분리하고, 실제 적벽 코어 자동 교전도 별도로 확인한다.
class MotionSource extends BattleSource:
	var rows: Array[Dictionary] = []
	func _init(b: Node) -> void:
		super(b)
	func squadrons() -> Array[Dictionary]:
		return rows
	func squadron(id: int) -> Dictionary:
		for row in rows:
			if row.id == id:
				return row
		return {}

var fails := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, text: String) -> void:
	if not ok:
		fails += 1
		print("FAIL ", text)

func _snapshot(v: FleetRenderer.FleetVis) -> Dictionary:
	var out := {}
	for s in v.slots:
		if s.alive:
			out[s] = {"pos": s.pos, "home": s.home, "yaw": s.yaw}
	_check(not out.is_empty(), "생존 슬롯 1개 이상")
	return out

func _drift(v: FleetRenderer.FleetVis, before: Dictionary) -> Vector2:
	var result := Vector2.ZERO
	var living := 0
	for s in v.slots:
		if s.alive:
			living += 1
			_check(before.has(s) and s.home == before[s].home, "생존 슬롯 정체성/목표 유지")
			if before.has(s):
				result.x = maxf(result.x, s.pos.distance_to(before[s].pos))
				result.y = maxf(result.y, absf(angle_difference(s.yaw, before[s].yaw)))
	_check(living > 0, "빈 함대의 0오차 PASS 금지")
	return result if living > 0 else Vector2.INF

func _visual_cases(battle: Node, fps: int, speed: int) -> void:
	var source := MotionSource.new(battle)
	var base: BattleSource = battle.presentation.src
	var a: Dictionary = base.squadron(battle.vm.alive(0)[0].id).duplicate(true)
	var b: Dictionary = base.squadron(battle.vm.alive(0)[1].id).duplicate(true)
	a.pos = Vector2(650, 450)
	a.heading = 0.0
	a.under_fire = false
	a.firing_at = -1
	b.pos = Vector2(810, 450)
	b.heading = PI
	b.side = 1
	b.under_fire = false
	b.firing_at = -1
	source.rows.assign([a, b])
	var r := FleetRenderer.new()
	root.add_child(r)
	r.setup(source)
	r.update(0.0)
	var v: FleetRenderer.FleetVis = r.vis[a.id]
	var points := r.formation_points(a.formation, v.slots.size())
	for i in v.slots.size():
		_check(v.slots[i].home.y == points[i].y, "슬롯 높이에 임의 난수 편차 없음")
	var before := _snapshot(v)
	var dt: float = float(speed) / float(fps)
	var worst := Vector2.ZERO
	# 표적/under_fire/시계 변화가 정지 슬롯에 반복 기동을 만들면 실패한다.
	b.firing_at = a.id
	a.target_id = b.id
	a.under_fire = true
	for i in ceili(30.0 / dt):
		r.update(dt)
		worst = worst.max(_drift(v, before))
	_check(worst.x < 0.0001 and worst.y < 0.0001, "%dfps x%d 정지 교전 30초 위치/방향 불변 %s" % [fps, speed, worst])
	# 공격 함대 사망과 실제 격침 경로도 다른 생존 함선의 슬롯을 바꾸지 않는다.
	b.dead = true
	r._kill_one(v)
	a.ships = float(a.max_ships) * v.alive_n / v.slots.size()
	for i in ceili(10.0 / dt):
		r.update(dt)
		worst = worst.max(_drift(v, before))
	_check(worst.x < 0.0001 and worst.y < 0.0001, "격침·공격자 사망 뒤 정지 슬롯 유지")
	# 보간의 복귀 보정만으로 선체가 뒤를 향하지 않는다. 위치는 원래 슬롯으로 수렴한다.
	var first: FleetRenderer.Slot = before.keys()[0]
	if not first.alive:
		first = v.slots.filter(func(s): return s.alive)[0]
	first.pos += Vector3(3, 0, 0)
	v.rest = 0
	var yaw0 := first.yaw
	var previous := first.pos.distance_to(before[first].pos)
	for i in ceili(8.0 / dt):
		r._follow(v, a, dt)
		var distance := first.pos.distance_to(before[first].pos)
		_check(distance <= previous + 0.00001 and absf(angle_difference(first.yaw, yaw0)) < 0.0001, "정지 복귀 보정은 단조 수렴·함수 유지")
		previous = distance
	_check(previous < 0.02, "복귀 보정 완료")
	# 직선 이동 중 슬롯의 가로/세로 잡음이 없고, 정지하면 도착 방향으로 정돈한다.
	var target_sq := a.duplicate(true)
	var start: Vector2 = a.pos
	for i in ceili(4.0 / dt):
		target_sq.pos = start + Vector2(20.0 * (i + 1) * dt, 0)
		r._follow(v, target_sq, dt)
		for s in v.slots:
			if s.alive:
				_check(absf(s.pos.z - before[s].pos.z) < 0.0001 and absf(s.pos.y - before[s].pos.y) < 0.0001, "직선 슬롯의 임의 가로/높이 흔들림 없음")
	target_sq.heading = PI * 0.5
	for i in ceili(8.0 / dt):
		r._follow(v, target_sq, dt)
	var h := -float(target_sq.heading) - PI
	for s in v.slots:
		if s.alive:
			_check(absf(angle_difference(s.yaw, h)) < 0.003, "90도 선회 후 방향 정돈")
	target_sq.strafe = true
	start = target_sq.pos
	for i in ceili(4.0 / dt):
		target_sq.pos = start - Vector2(0, 20.0 * (i + 1) * dt)
		r._follow(v, target_sq, dt)
		for s in v.slots:
			if s.alive:
				_check(absf(angle_difference(s.yaw, h)) < 0.003, "평행 후퇴 중 함수 방향 유지")
	r.queue_free()

# 실제 VM의 마지막 이동 틱→정지 플래그→alpha 보간을 Source가 그대로 읽는 경계.
# 중심/슬롯 위치 차이가 있어도 yaw는 공유 heading만 기술 보간해야 한다.
func _vm_end_cases(battle: Node, fps: int, speed: float) -> void:
	var src: BattleSource = battle.presentation.src
	var dt: float = speed / float(fps)
	for kind in ["arrival", "stop", "strafe_end", "micro", "face90", "face180", "wrap"]:
		var model := BattleViewModel.new()
		var proj: Dictionary = battle.sim.projection(0).duplicate(true)
		var row: Dictionary = proj.squadrons[0].duplicate(true)
		row.pos = Vector2(650, 450)
		row.heading = PI - 0.01 if kind == "wrap" else 0.0
		row.has_move = true
		row.strafe = kind == "strafe_end"
		row.target_id = -1
		row.firing_at = -1
		proj.squadrons = [row]
		model.apply(proj)
		model.interpolate(1.0)
		var r := FleetRenderer.new()
		root.add_child(r)
		r.setup(src)
		var f: BattleViewModel.FleetView = model.fleet(row.id)
		var v := r._make_vis(src._sq(f))
		var expected_yaw: float = -float(f.heading) - PI
		for i in v.slots.size():
			v.slots[i].pos += Vector3(2.0, 0.0, 1.0 if i % 2 == 0 else -1.0)
		proj.tick += 1
		row.has_move = false
		row.strafe = false
		if kind in ["arrival", "stop", "strafe_end", "micro"]:
			row.pos += Vector2(0.02 if kind == "micro" else 16.0, 0)
		else:
			row.heading = -PI + 0.01 if kind == "wrap" else (PI * 0.5 if kind == "face90" else PI)
		model.apply(proj)
		_check(not f.has_move and (f.ppos != f.tpos if kind in ["arrival", "stop", "strafe_end", "micro"] else f.pheading != f.theading), "VM 종료/공유 선회 틱 보간 재현 " + kind)
		var maxerr := 0.0
		var spread := 0.0
		var fixed_yaw := expected_yaw
		var fixed_error := 0.0
		for i in ceili(6.0 / dt):
			model.interpolate(minf((i + 1) * dt * model.hz, 1.0))
			var sq: Dictionary = src._sq(f)
			expected_yaw = lerp_angle(expected_yaw, -float(sq.heading) - PI, 1.0 - exp(-dt / 0.35))
			r._follow(v, sq, dt)
			var shared_yaw := INF
			for s in v.slots:
				if s.alive:
					maxerr = maxf(maxerr, absf(angle_difference(s.yaw, expected_yaw)))
					if is_inf(shared_yaw):
						shared_yaw = s.yaw
					spread = maxf(spread, absf(angle_difference(s.yaw, shared_yaw)))
					if kind in ["arrival", "stop", "strafe_end", "micro"]:
						fixed_error = maxf(fixed_error, absf(angle_difference(s.yaw, fixed_yaw)))
		var live := 0
		var poserr := 0.0
		var final_yaw := 0.0
		for s in v.slots:
			if s.alive:
				live += 1
				poserr = maxf(poserr, s.pos.distance_to(r._target(s, src.to3(f.pos), -f.heading - PI * 0.5)))
				final_yaw = maxf(final_yaw, absf(angle_difference(s.yaw, -f.heading - PI)))
		_check(spread < 0.0001 and fixed_error < 0.0001 and final_yaw < 0.003, "공유 heading 고정이면 yaw 불변·선회면 슬롯간 편차 없이 최종 방향 수렴 " + kind)
		# 기존 정지 최적화는 yaw오차0.002 이내에서 멈춘다. 기존 정돈 허용치0.003을 사용한다.
		_check(live > 0 and maxerr < 0.003 and poserr < 0.02, "%dfps x%.1f VM %s: 공유 방향만 보간·위치 정돈 yaw=%f pos=%f" % [fps, speed, kind, maxerr, poserr])
		r.queue_free()

# 실제 코어 명령의 stop/자연 도착도 같은 마지막 틱 경계를 만든다.
func _core_end_cases(battle: Node, fps: int, speed: int) -> void:
	var fixed := ReferenceMotionFixture.prepare(battle)
	if fixed.is_empty():
		_check(false, "교전 fixture 선택 실패")
		quit(1)
		return
	var a: FleetState = battle.sim.st.by_id(fixed.ally_id)
	var b: FleetState = battle.sim.st.by_id(fixed.enemy_id)
	b.pos = battle.FIELD_SIZE - Vector2(50, 50)
	b.home = b.pos
	battle.G.state = "play"
	battle.G.speed = speed
	battle.G.slow = 1.0
	var r: FleetRenderer = battle.presentation.renderer
	var src: BattleSource = battle.presentation.src
	for kind in ["stop", "arrival"]:
		a.pos = Vector2(650, 450)
		a.heading = 0.0
		a.has_move = false
		a.target_id = -1
		a.face_set = false
		battle._sync()
		for f in battle.vm.fleets:
			f.ppos = f.tpos
			f.pheading = f.theading
		battle.vm.interpolate(1.0)
		battle.clock.acc = 0.0
		r.reset()
		r.update(0.0)
		var v: FleetRenderer.FleetVis = r.vis[a.id]
		for i in v.slots.size():
			v.slots[i].pos += Vector3(2.0, 0, 1.0 if i % 2 == 0 else -1.0)
		var tick0: int = battle.sim.st.tick
		battle.issue(BattleCommands.make("move", [a.id], -1, a.pos + Vector2(300 if kind == "stop" else 24, 0)))
		var ended := false
		var expected_yaw := -PI
		var maxerr := 0.0
		var dt: float = float(speed) / float(fps)
		for i in ceili(6.0 / dt):
			battle._process(1.0 / float(fps))
			if kind == "stop" and not ended and battle.sim.st.tick > tick0:
				battle.issue(BattleCommands.make("stop", [a.id]))
				ended = true
			if kind == "arrival" and not a.has_move:
				ended = true
			var sq: Dictionary = src.squadron(a.id)
			expected_yaw = lerp_angle(expected_yaw, -float(sq.heading) - PI, 1.0 - exp(-dt / 0.35))
			r.update(dt)
			for s in v.slots:
				if s.alive:
					maxerr = maxf(maxerr, absf(angle_difference(s.yaw, expected_yaw)))
		_check(ended and not a.has_move and v.alive_n > 0 and maxerr < 0.0001, "%dfps x%d 실제 core %s→VM→Source→renderer 공유 방향 유지 %f" % [fps, speed, kind, maxerr])

func _run() -> void:
	for fps in [30, 60]:
		for speed in [1, 4]:
			var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
			root.add_child(battle)
			for i in 6:
				await process_frame
			battle.set_process(false)
			battle.presentation.set_process(false)
			var fingerprint: String = battle.sim.fingerprint()
			_visual_cases(battle, fps, speed)
			_vm_end_cases(battle, fps, float(speed))
			if speed == 1:
				_vm_end_cases(battle, fps, 0.2)
			_check(battle.sim.fingerprint() == fingerprint, "표현 교전/이동이 코어 지문 불변")
			var fixed := ReferenceMotionFixture.prepare(battle)
			if fixed.is_empty():
				_check(false, "교전 fixture 선택 실패")
				quit(1)
				return
			var r: FleetRenderer = battle.presentation.renderer
			var v: FleetRenderer.FleetVis = r.vis[fixed.ally_id]
			var before := _snapshot(v)
			var peak := Vector2.ZERO
			var active_frames := 0
			var dt: float = float(speed) / float(fps)
			for i in ceili(12.0 / dt):
				battle.update_sim(dt)
				battle.vm.interpolate(1.0)
				r.update(dt)
				_check(ReferenceMotionFixture.stationary_ok(battle, fixed), "실제 교전 core 정지·생존")
				if ReferenceMotionFixture.active(battle, fixed):
					active_frames += 1
				peak = peak.max(_drift(v, before))
			_check(active_frames > 0 and peak.x < 0.0001 and peak.y < 0.0001, "%dfps x%d 실제 core 양방향 자동 사격 위치/방향 불변 %s" % [fps, speed, peak])
			_core_end_cases(battle, fps, speed)
			battle.queue_free()
			await process_frame
	print("REFERENCE_MOTION_ONLY_", "PASS" if fails == 0 else "FAIL")
	quit(1 if fails else 0)
