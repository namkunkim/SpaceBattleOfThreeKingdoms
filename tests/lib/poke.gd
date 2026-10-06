class_name TestPoke
extends RefCounted

# 테스트가 전투 상태를 직접 만들 때 쓴다. 코어가 유일한 권위이므로 화면 모델이 아니라 코어 상태를 바꾸고 화면 모델을 다시 맞춘다.
# props 키는 코어 전대 필드 이름이다(has_move, move_to, defense, target_id, pos, heading, ships, charge, ...).
static func fleet(battle: Node, view_fleet, props: Dictionary) -> void:
	var f = battle.sim.st.by_id(view_fleet.id)
	for k in props:
		f.set(k, props[k])
	battle._sync()
	# 보간 기준도 맞춘다(다음 틱까지 직전 위치로 되돌아가 보이지 않게)
	view_fleet.ppos = view_fleet.tpos
	view_fleet.pheading = view_fleet.theading
	battle.vm.interpolate(1.0)

# 시나리오 프로필은 안개라 적이 멀리서 시작한다. 가장 가까운 적 전대 하나를 기준 전대 곁으로 옮겨 접촉·교전을 만든다.
static func foe_beside(battle: Node, view_fleet, offset := Vector2(250, 0)) -> void:
	for t in battle.sim.st.fleets:
		if t.side == 1 and not t.dead and t.wait == 0:
			t.pos = view_fleet.pos + offset
			break
	battle._sync()
