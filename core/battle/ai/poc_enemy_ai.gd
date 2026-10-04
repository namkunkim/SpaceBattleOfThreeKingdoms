class_name PocEnemyAi
extends RefCounted

# POC 적 AI(0.5초마다). 결정은 모두 명령으로 내고 코어가 같은 경로로 적용한다.
# M1에서는 규칙을 바꾸지 않으므로 상태 전체를 본다(전지적 시야). 공개 투영만 쓰는 것은 M6·M7에서 고친다.

func think(sim: BattleSim) -> void:
	var st := sim.st
	var pl := st.alive(0)
	if pl.is_empty():
		return
	var t_s := st.clock_s()
	for f in st.alive(1):
		if f.dead:
			continue
		var eid := st.new_event_id()
		var n: FleetState = null
		var nd := 1e9
		for p in pl:
			var d := f.pos.distance_to(p.pos)
			if d < nd:
				nd = d
				n = p
		if f.is_flag:
			if nd < sim.R.ai_flag_engage_r:
				_do(sim, f, "ai_target", n.id)
			else:
				_do(sim, f, "ai_target", -1)
				if f.pos.distance_to(f.home) > sim.R.ai_flag_home_r:
					_do(sim, f, "ai_move", -1, f.home)
		elif st.tick >= f.wait or nd < sim.R.ai_engage_r:
			if st.live_target(f) == null or sim.rng.bp(st.tick, eid, 1) < sim.R.ai_retarget_bp:
				var best: FleetState = null
				var bs := 1e9
				for p in pl:
					if p.dead:
						continue
					var sc: float = f.pos.distance_to(p.pos) * (sim.R.ai_score_base + float(p.ships) / p.max_ships * sim.R.ai_score_span)
					if sc < bs:
						bs = sc
						best = p
				_do(sim, f, "ai_target", best.id if best else -1)
		else:
			_do(sim, f, "ai_target", -1)
			_do(sim, f, "ai_move", -1, Vector2(f.home.x - t_s * sim.R.ai_advance_speed, f.home.y))
		if f.ships < f.max_ships * sim.R.ai_defend_share and not f.defense:
			_do(sim, f, "def_on")
		var t := st.live_target(f)
		if t:
			var d := f.pos.distance_to(t.pos)
			if f.missile_cd <= 0 and st.ecp >= sim.R.missile_cost_bp and d <= sim.R.missile_r and sim.rng.bp(st.tick, eid, 2) < sim.R.ai_missile_bp:
				_do(sim, f, "missile", t.id)
			elif f.fighter_cd <= 0 and st.ecp >= sim.R.fighter_cost_bp and d <= sim.R.fighter_r and sim.rng.bp(st.tick, eid, 3) < sim.R.ai_fighter_bp:
				_do(sim, f, "fighter", t.id)

func _do(sim: BattleSim, f: FleetState, kind: String, target_id := -1, point := Vector2.ZERO) -> void:
	sim.apply(BattleSim.command(f.side, [f.id], kind, target_id, point))
