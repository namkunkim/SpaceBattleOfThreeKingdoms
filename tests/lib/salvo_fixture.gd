class_name SalvoFixture
extends RefCounted

# M3 테스트용 소규모 전장. 규칙은 data/profiles/combat_m3.json의 실제 값이고, 편성만 테스트가 정한다.
# AI는 끄고(ai_timer를 크게) 위치는 명령으로만 바꾼다. 전대 정의 d는 ScenarioProfile이 만드는 것과 같은 키를 쓴다.

static func combat() -> Dictionary:
	return ProfileLoader.read_json("res://data/profiles/combat_m3.json").combat

static func def(name: String, x: float, y: float, comp: Array, flag := false, form := "FRM-01", cmd := 70) -> Dictionary:
	var n := 0
	var c := []
	for e in comp:
		n += int(e[1])
		var entry := {"ship_type_id": e[0], "count": e[1]}
		if e.size() > 2:
			entry.mission_equipment_id = e[2]
		c.append(entry)
	return {"name": name, "role": name, "ships": n, "lv": 1, "x": x, "y": y, "flag": flag, "p": 0, "wait": 0,
		"composition": c, "formation_id": form, "command": cmd, "start_morale_bp": 10000}

static func sim(ally: Array, foe: Array, seed_id := 1, mode := "") -> BattleSim:
	var rules: Dictionary = PocSetup.profile().rules
	rules.world_w = 1600.0
	rules.world_h = 900.0
	var cb := combat()
	if mode != "":
		cb.damage_mode = mode
	var s := BattleSim.new(seed_id, BattleRules.TICK_HZ, {
		"profile_id": "salvo-test", "rules": rules, "ally": ally, "foe": foe, "reinf": [], "combat": cb})
	s.st.ai_timer = 1 << 40
	return s

static func run(s: BattleSim, max_s: float) -> void:
	var max_tick := int(max_s * s.st.hz)
	while not s.st.over and s.st.tick < max_tick:
		s.step()
		s.drain_events()
