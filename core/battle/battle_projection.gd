class_name BattleProjection
extends RefCounted

# 공개 투영 v0(IMPLEMENTATION-HANDOFF §4). 화면(view/·hud/)과 입력은 이 사전만 읽는다.
# 단위: 척 수 1/1000척 정수(ships_milli), 시간은 틱과 초를 같이 준다. 위치는 전장 px.
# M1은 안개가 없다(POC 규칙). 보는 진영(side)은 자원(CP)과 앞으로의 안개(M6)를 가르는 데 쓴다.
# 사건은 투영에 넣지 않고 BattleSim.drain_events()로 따로 받는다(한 프레임에 여러 틱이 돌 수 있어서).

static func build(sim: BattleSim, side: int) -> Dictionary:
	var st := sim.st
	var sqs: Array[Dictionary] = []
	var fog := sim.detect != null
	for f in st.fleets:
		if not fog or f.side == side:
			var q := squadron(st, f)
			if sim.supply and f.side == side:
				q.supply = sim.supply.squadron_state(f)   # M8: 배정 공급원·진행·재고. 적 항목에는 넣지 않는다
			if sim.salvo and f.side == side:
				# 진형 탭용: 진형 ID마다 이 전대의 선택 불가 사유 코드("" = 가능)와 전환 시간(초). 규칙은 salvo가 판정한다
				var fi := {}
				for fid in sim.salvo.formation_ids():
					fi[fid] = {"block": sim.salvo.form_block(f, fid), "secs": float(sim.salvo.transition_ticks(f, fid)) / st.hz}
				q.form_info = fi
			if f.side == side:
				q.ranges = f.ranges.duplicate()   # 아군 전용: 범주별 사거리(적 접촉에는 넣지 않는다)
			if sim.cmd and f.side == side:
				# M9: 지휘관 상태·이은 사람·혼선 남은 초(지휘 공백이면 -1)·불이익 단계
				q.commander_state = f.cmdr_state
				q.commander_sub = f.cmdr_sub
				q.confusion_s = (-1.0 if f.confuse_until >= CommandCore.FOREVER else maxf(0.0, float(f.confuse_until - st.tick) / st.hz)) if sim.cmd.confused(f) else 0.0
				q.penalty_stages = sim.cmd.stages(f)
			sqs.append(q)
	if fog:
		# 안개(M6): 적은 진영 접촉표의 확인·추정·상실 접촉만, 줄인 형태로 준다. 미탐지 적은 어디에도 없다.
		for c in sim.detect.foes(side):
			sqs.append(contact(sim, c))
	var ms := []
	for m in st.missiles:
		if fog and m.side != side:
			continue   # salvo 규칙에는 미사일이 없다. 생기면 접촉 규칙으로 다시 정한다
		ms.append({"id": m.id, "pos": m.pos, "side": m.side, "target_id": m.target_id})
	var sw := []
	for s in st.swarms:
		if fog and s.side != side:
			continue
		var pts := []
		for p in s.pts:
			pts.append(p.pos)
		sw.append({"id": s.id, "side": s.side, "src_id": s.src_id, "target_id": s.target_id, "pts": pts,
			"life_s": float(s.life) / st.hz, "striking": s.striking})
	var d := {
		"side": side,
		"tick": st.tick,
		"hz": st.hz,
		"clock_s": st.clock_s(),
		"reinf": st.reinf,
		"killed_milli": st.killed if side == 0 else st.lost,
		"lost_milli": st.lost if side == 0 else st.killed,
		"outcome": {"over": st.over, "win": st.win if side == 0 else (st.over and not st.win), "reason": st.end_reason, "end_tick": st.end_tick,
			"limited": bool(st.result.get("limited", false)), "result": st.result},
		"squadrons": sqs,
		"missiles": ms,
		"swarms": sw,
	}
	if sim.decisions and side == 0:
		d.pending_decisions = sim.decisions.pending()    # 열린 결정 카드. time_left는 게임 초(V-3)
		d.upcoming_decisions = sim.decisions.upcoming()  # 예고 중인 카드(약 3초 전, V-4)
	else:
		d.pending_decisions = []
		d.upcoming_decisions = []
	d.supply_sources = sim.supply.public_sources(side) if sim.supply else []   # M8: 자기 진영 보급 영역(기지·보급함 전대)만
	if sim.salvo == null:
		d.cp_bp = st.cp if side == 0 else st.ecp   # CP는 POC 규칙에만 있다(M4: salvo 규칙은 CP를 쓰지 않는다)
	if sim.morale:
		d.army_morale_bp = {"own": sim.morale.army_bp(side), "foe": sim.morale.army_bp(1 - side)}
		d.morale_crisis = sim.morale.army_bp(side) < sim.morale.crisis_bp()
		d.time_limit_s = int(sim.salvo.C.victory.time_limit_s)
	if sim.chain:
		d.chain_op = sim.chain.view(side)   # M9 화공: 상태·의심·기류 창(공개), 운용 진영에는 자산·불붙은 전대
	return d

# 적 접촉의 공개 형태. 확인: 이름·역할·초상·방향과 전력 구간. 추정·상실: 위치(마지막으로 안 곳)와 오차 반경, 신뢰도뿐이다.
# 함종·척 수·선체·사기·표적·진형은 어느 상태에서도 공개하지 않는다.
# 세력 표시 키(shu/wu/wei). 시나리오 세력 ID가 정본이고, 없으면(POC) 진영으로 나눈다. 손권군(side 0)이 촉으로 나오던 원인(2026-10-05).
const FACTION_KEY := {"liu_bei": "shu", "sun_quan": "wu", "cao_cao": "wei"}

static func faction_key(f: FleetState) -> String:
	return FACTION_KEY.get(f.faction, "wei" if f.side == 1 else "shu")

static func contact(sim: BattleSim, c: Dictionary) -> Dictionary:
	var t := sim.st.by_id(c.id)
	var d := {"id": c.id, "side": t.side, "contact": c.state, "pos": c.pos, "err_r": c.err_r, "conf_bp": c.conf_bp,
		"faction": faction_key(t)}
	if c.state == "confirmed":
		d.name = t.name
		d.role = t.role
		d.portrait = t.portrait
		d.commander_id = t.name
		d.faction_id = t.faction
		d.pos = t.pos   # 확인 접촉은 실제 위치(§4.9). 평가 시점(1초 주기) 위치를 쓰면 적이 1초마다 멈췄다 점프한다
		d.heading = t.heading
		d.strength_band = sim.detect.strength_band(t)
		if sim.chain:
			d.dense = sim.chain.dense(t)   # 화공 표적 조건(밀집 여부)만 공개한다. 진형 ID는 공개하지 않는다(M9)
			d.feigning = sim.chain.truce_id(t.id)
		d.max_strength_band = int(sim.detect.D.strength_bands)
	return d

static func squadron(st: BattleState, f: FleetState) -> Dictionary:
	var hz := float(st.hz)
	return {
		"id": f.id, "side": f.side, "faction": faction_key(f), "name": f.name, "role": f.role,
		"portrait": f.portrait, "commander_id": f.name,
		"pos": f.pos, "heading": f.heading,
		"ships_milli": f.ships, "max_ships_milli": f.max_ships, "shown_milli": f.shown,
		"lv": f.lv, "spd": f.spd, "flagship": f.is_flag, "dead": f.dead,
		"target_id": f.target_id if not f.dead else -1,
		"firing_at": f.fire_id if not f.dead else -1,
		"form_id": f.form_id, "formation": f.shape if f.shape >= 0 else f.form_id % BattleRules.FORM_COUNT,
		"formation_id": f.formation_id, "form_to": f.form_to, "form_left_s": f.form_left / hz,
		"route": f.route, "strafe": f.strafe, "face_set": f.face_set, "face_to": f.face_to,
		"has_move": f.has_move, "move_to": f.move_to,
		"defense": f.defense, "charge_s": f.charge / hz, "in_cmd": f.in_cmd,
		"missile_cd_s": f.missile_cd / hz, "fighter_cd_s": f.fighter_cd / hz,
		"range": f.range_r,
		"form": f.form,
		"control": f.control, "posture": f.posture,   # 직접·위임(Q20), 전투 방침(§5.2). posture "delegated"는 인물 위임
		"morale_bp": f.morale_bp, "mstate": f.mstate, "out": f.out, "retreat_order": f.retreat_order,
		"faction_id": f.faction,
		"counts": f.stages.duplicate(true),   # 함종 × 손상 단계 [무손상, 경파, 중파, 대파, 격침]. POC 규칙이면 빈 사전
		"hull": f.hull, "max_hull": f.max_hull,
		"charges": f.wch.duplicate(), "charges_max": f.wmax.duplicate(),   # Q69: 아군 전용 표시
		"energy_milli": f.energy_m, "heat_milli": f.heat_m, "ammo": f.ammo.duplicate(), "suppressed": f.supp.duplicate(),
		"next_fire_s": _next_fire_s(f, hz),
	}

static func _next_fire_s(f: FleetState, hz: float) -> Dictionary:
	var out := {}
	for cat in f.next_fire:
		out[cat] = f.next_fire[cat] / hz
	return out
