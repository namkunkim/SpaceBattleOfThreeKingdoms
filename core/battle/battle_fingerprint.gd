class_name BattleFingerprint
extends RefCounted

# 상태 지문(Q40): 정수와 0.001 격자로 양자화한 값만 넣어 sha256을 낸다.

static func of(st: BattleState, detect: Detection = null, extra := "") -> String:
	var q := BattleRules.q_int
	var parts := PackedStringArray()
	parts.append("t%d,%d|cp%d,%d,%d,%d|k%d,%d|r%d,%d|ai%d|id%d,%d,%d|o%d,%d,%s" % [
		st.tick, st.clock_ms, st.cp, st.cp_rem, st.ecp, st.ecp_rem, st.killed, st.lost, int(st.reinf), st.reinf_ms,
		st.ai_timer, st.next_id, st.form_counter, st.next_event_id, int(st.over), int(st.win), st.end_reason])
	for f in st.fleets:
		parts.append("f%d:%d,%d,%d,%d,%d|%d,%d,%d|%d,%d,%d,%d|%d,%d,%d,%d,%d,%d,%d,%d" % [
			f.id, f.ships, f.shown, f.lv, f.xp, int(f.dead),
			q.call(f.pos.x), q.call(f.pos.y), q.call(f.heading),
			f.target_id, int(f.has_move), q.call(f.move_to.x), q.call(f.move_to.y),
			f.missile_cd, f.fighter_cd, f.charge, f.flank_msg, int(f.defense), f.fire_id, int(f.in_cmd), f.wait])
	for f in st.fleets:
		if f.max_hull > 0:
			var sg := PackedStringArray()
			for t in f.stages:
				sg.append(",".join(PackedStringArray((f.stages[t] as Array).map(func(n): return str(n)))))
			var nf := PackedStringArray()
			for cat in f.next_fire:
				nf.append("%d.%d" % [f.next_fire[cat], f.ammo[cat]])
			parts.append("h%d:%d,%d,%d,%d,%d,%d,%s|%s|%s" % [f.id, f.hull, f.lost_ships, f.loss_total, f.loss_exposed, f.energy_m, f.heat_m, str(f.wch), ";".join(sg), ",".join(nf)])
	parts.append("ev%d,%d" % [st.army_ev[0], st.army_ev[1]])
	for f in st.fleets:
		if f.max_hull > 0:
			parts.append("m%d:%d,%s,%s,%d,%d,%d,%d,%d,%d" % [f.id, f.morale_bp, f.mstate, f.out, int(f.retreat_order), int(f.retreat_counted), f.loss_mul_until, f.loss_mul_bp, f.cost0, int(f.fired.size()) + (int(f.arrived) << 8)])
	for f in st.fleets:
		if f.max_hull > 0:
			var rt := PackedStringArray()
			for w in f.route:
				rt.append("%d.%d" % [q.call(w.x), q.call(w.y)])
			parts.append("v%d:%s,%d,%d,%d,%d|%s" % [f.id, f.form_to, f.form_left, int(f.strafe), int(f.face_set), q.call(f.face_to), ",".join(rt)])
	for m in st.missiles:
		parts.append("m%d:%d,%d,%d,%d,%d,%d" % [m.id, q.call(m.pos.x), q.call(m.pos.y), m.target_id, m.dmg, q.call(m.v), m.age])
	for s in st.swarms:
		var p0: Vector2 = s.pts[0].pos if s.pts.size() > 0 else Vector2.ZERO
		parts.append("s%d:%d,%d,%d,%d,%d,%d" % [s.id, s.target_id, s.life, s.dps, q.call(p0.x), q.call(p0.y), s.pts.size()])
	if detect:
		for side in 2:
			var ids: Array = detect.contacts[side].keys()
			ids.sort()
			for id in ids:
				var r: Dictionary = detect.contacts[side][id]
				parts.append("c%d:%d,%s,%d,%d,%d,%d" % [side, id, r.state, r.seen, q.call(r.pos.x), q.call(r.pos.y), r.conf_bp])
	if extra != "":
		parts.append(extra)   # M7: 지휘 상태(직접/위임·방침·결정 카드). 없으면 M6 지문과 같다
	return "|".join(parts).sha256_text()
