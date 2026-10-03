class_name BattleFingerprint
extends RefCounted

# 상태 지문(Q40): 정수와 0.001 격자로 양자화한 값만 넣어 sha256을 낸다.

static func of(st: BattleState) -> String:
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
	for m in st.missiles:
		parts.append("m%d:%d,%d,%d,%d,%d,%d" % [m.id, q.call(m.pos.x), q.call(m.pos.y), m.target_id, m.dmg, q.call(m.v), m.age])
	for s in st.swarms:
		var p0: Vector2 = s.pts[0].pos if s.pts.size() > 0 else Vector2.ZERO
		parts.append("s%d:%d,%d,%d,%d,%d,%d" % [s.id, s.target_id, s.life, s.dps, q.call(p0.x), q.call(p0.y), s.pts.size()])
	return "|".join(parts).sha256_text()
