class_name PocEnemyAi
extends RefCounted

# POC 적 AI(0.5초마다). 결정은 모두 명령으로 내고 코어가 같은 경로로 적용한다.
# M6: 안개가 있으면(sim.detect) 적에 대해서는 진영 접촉표(확인·추정)만 본다. 위치는 접촉이 아는 값이고,
# 확인이 아닌 접촉은 약해졌는지 모르므로 온전한 전력으로 본다. 안개가 없으면 살아 있는 적 전체(POC, 완전 정보).

# 적 목록: [{id, pos, share}] — share는 남은 척 수 비율(0~1)
static func _foes(sim: BattleSim, side: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if sim.detect == null:
		for p in sim.st.alive(1 - side):
			out.append({"id": p.id, "pos": p.pos, "share": float(p.ships) / p.max_ships})
		return out
	for c in sim.detect.foes(side):
		if c.state == "lost":
			continue
		out.append({"id": c.id, "pos": c.pos, "share": float(c.ships_milli) / c.max_ships_milli if c.ships_milli >= 0 else 1.0})
	return out

func think(sim: BattleSim) -> void:
	var st := sim.st
	var pl := _foes(sim, 1)
	if pl.is_empty() and sim.detect == null:
		return
	var t_s := st.clock_s()
	for f in st.alive(1):
		if f.dead:
			continue
		var eid := st.new_event_id()
		var n := -1
		var nd := 1e9
		for p in pl:
			var d := f.pos.distance_to(p.pos)
			if d < nd:
				nd = d
				n = p.id
		if f.is_flag:
			if nd < sim.R.ai_flag_engage_r:
				_do(sim, f, "ai_target", n)
			else:
				_do(sim, f, "ai_target", -1)
				if f.pos.distance_to(f.home) > sim.R.ai_flag_home_r:
					_do(sim, f, "ai_move", -1, f.home)
		elif st.tick >= f.wait or nd < sim.R.ai_engage_r:
			if sim.sight_target(f) == null or sim.rng.bp(st.tick, eid, 1) < sim.R.ai_retarget_bp:
				var best := -1
				var bs := 1e9
				for p in pl:
					var sc: float = f.pos.distance_to(p.pos) * (sim.R.ai_score_base + p.share * sim.R.ai_score_span)
					if sc < bs:
						bs = sc
						best = p.id
				_do(sim, f, "ai_target", best)
				if best < 0 and sim.detect:
					# 접촉이 없으면 정찰 전진(본편 AI 규칙 no_contact_action=patrol). 안개 속에서 적을 찾아 나선다
					var off: Array = sim.detect.D.no_contact_patrol.offset
					_do(sim, f, "ai_move", -1, f.pos + Vector2(float(off[0]), float(off[1])))
		else:
			_do(sim, f, "ai_target", -1)
			_do(sim, f, "ai_move", -1, Vector2(f.home.x - t_s * sim.R.ai_advance_speed, f.home.y))
		if f.ships < f.max_ships * sim.R.ai_defend_share:
			if sim.salvo == null:
				if not f.defense:
					_do(sim, f, "def_on")
			elif f.formation_id != sim.salvo.C.formation_rules.defense_id and f.form_to != sim.salvo.C.formation_rules.defense_id:
				sim.apply(BattleSim.command(f.side, [f.id], "formation", -1, Vector2.ZERO, {"id": sim.salvo.C.formation_rules.defense_id}))   # 방어진형 대신 방원진(§9)
		var t := sim.sight_target(f)
		if t and sim.salvo == null:   # 미사일·함재기는 POC 규칙. salvo 규칙은 범주별 주기로 스스로 쏜다
			var d := f.pos.distance_to(t.pos)
			if f.missile_cd <= 0 and st.ecp >= sim.R.missile_cost_bp and d <= sim.R.missile_r and sim.rng.bp(st.tick, eid, 2) < sim.R.ai_missile_bp:
				_do(sim, f, "missile", t.id)
			elif f.fighter_cd <= 0 and st.ecp >= sim.R.fighter_cost_bp and d <= sim.R.fighter_r and sim.rng.bp(st.tick, eid, 3) < sim.R.ai_fighter_bp:
				_do(sim, f, "fighter", t.id)

func _do(sim: BattleSim, f: FleetState, kind: String, target_id := -1, point := Vector2.ZERO) -> void:
	sim.apply(BattleSim.command(f.side, [f.id], kind, target_id, point))
