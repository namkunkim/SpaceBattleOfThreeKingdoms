extends SceneTree

# 화면 문구의 규칙 값(BattleSource.rules)이 POC의 실제 동작과 같은지 대조한다(헤드리스).
# POC 리터럴이 바뀌었는데 rules()를 안 고치면 여기서 실패한다. 확정 규칙(v02) 문구 틀도 만들어 본다.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var deck = battle.presentation.hud
	var src: BattleSource = battle.presentation.src
	deck.begin_battle()
	await process_frame
	var r := src.rules()
	var a = battle.fleets[1]
	var t = battle.fleets[8]
	a.lv = 1
	a.charge_t = 0.0
	a.in_cmd = true
	a.defense = false
	# 방향 배율: 표적 정면·측면·배후에 공격자를 놓아 본다
	t.heading = 0.0
	var res := {}
	for k in [["front", 0.0], ["side", PI / 2.0], ["rear", PI]]:
		a.pos = t.pos + Vector2(cos(k[1]), sin(k[1])) * 200.0
		res[k[0]] = battle.flank_mul(a, t)
		if not TestCheck.ok(self, src.attack_dir(a.id, t.id) == k[0], "attack_dir %s" % k[0]): return
	if not TestCheck.ok(self, is_equal_approx(res.side, r.flank.side) and is_equal_approx(res.rear, r.flank.rear), "flank values %s" % res): return
	# 화력 배율: 돌격, 지휘 범위 밖, 방어진형
	var base: float = battle.power(a)
	a.charge_t = 5.0
	if not TestCheck.ok(self, is_equal_approx(battle.power(a) / base, r.charge.fire), "charge fire"): return
	a.charge_t = 0.0
	a.in_cmd = false
	if not TestCheck.ok(self, is_equal_approx(battle.power(a) / base, r.out_of_cmd_fire), "out of command fire"): return
	a.in_cmd = true
	a.defense = true
	if not TestCheck.ok(self, is_equal_approx(battle.power(a) / base, r.defense.fire), "defense fire"): return
	# 받는 피해
	TestPoke.fleet(battle, t, {"defense": true})
	var s0: float = t.ships
	battle.apply_dmg(null, t, 10.0)
	if not TestCheck.ok(self, is_equal_approx(s0 - t.ships, 10.0 * r.defense.taken), "defense taken"): return
	# 재장전
	battle.fire_missiles(a, t)
	battle.launch_fighters(a, t)
	if not TestCheck.ok(self, is_equal_approx(a.missile_cd, r.missile.cd) and is_equal_approx(a.fighter_cd, r.fighter.cd), "cooldowns"): return
	# 명령 비용
	for c in battle.CMDS:
		if c.id in ["missile", "fighter", "charge"] and c.cost != r[c.id].cost:
			TestCheck.ok(self, false, "cost %s" % c.id)
			return
	# 문구: POC 값 그대로
	if not TestCheck.ok(self, RuleText.flank_chip(r, "side") == " · 측면 +30%" and RuleText.flank_chip(r, "rear") == " · 배후 +60%", "poc chip text"): return
	# 확정 규칙 틀(v02): 방어진형 없음, 측면·후면 명중률
	var v := {"set": "v02", "flank": {"model": "hit", "side": {"hit": 10, "morale": 1.25}, "rear": {"hit": 25, "morale": 1.5}},
		"out_of_cmd_fire": 0.75, "charge": {"heat": 0.4, "cost": 0}, "missile": r.missile, "fighter": r.fighter}
	if not TestCheck.ok(self, RuleText.flank_chip(v, "rear") == " · 후면 명중 +25%p", "v02 chip"): return
	if not TestCheck.ok(self, RuleText.flank_rule(v) == "측면 명중 +10%p·적 사기 타격 ×1.25, 후면 +25%p·×1.5", "v02 rule %s" % RuleText.flank_rule(v)): return
	if not TestCheck.ok(self, RuleText.defense_rule(v) == "" and RuleText.cmd(v, "charge").desc.contains("40%"), "v02 defense/charge"): return
	print("RULE_TEXT_PASS")
	quit(0)
