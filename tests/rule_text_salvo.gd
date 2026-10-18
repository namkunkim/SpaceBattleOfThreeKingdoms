extends SceneTree

# 적벽(salvo) 프로필의 화면 문구 값이 코어 데이터에서 나오는지 확인한다(헤드리스).

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var battle := (load("res://scenes/FleetBattle3D.tscn") as PackedScene).instantiate()
	root.add_child(battle)
	await process_frame
	var src: BattleSource = battle.presentation.src
	var r := src.rules()
	if not TestCheck.ok(self, r.set == "v02", "set v02"): return
	if not TestCheck.ok(self, RuleText.flank_chip(r, "side") == " · 측면 명중 +10%p" and RuleText.flank_chip(r, "rear") == " · 후면 명중 +25%p", "chips %s" % r.flank): return
	if not TestCheck.ok(self, RuleText.cmd_range_rule(r) == "기함 지휘 범위 밖의 함대는 명중률 −10%p", "cmd range"): return
	if not TestCheck.ok(self, RuleText.cost_rule(r).contains("40%") and RuleText.cmd(r, "charge").desc.contains("40%"), "charge"): return
	if not TestCheck.ok(self, not src.has_command("def") and src.has_command("missile") and src.has_command("fighter"), "commands"): return
	if not TestCheck.ok(self, RuleText.evasion_rule(r) == "이동 중인 함대는 전열·요격 명중률 최대 −5%p", "evasion rule %s" % RuleText.evasion_rule(r)): return
	var deck = battle.presentation.hud
	deck.begin_battle()
	await process_frame
	battle.selected.assign([battle.alive(0)[0]])
	deck._set_tab(2)
	deck._refresh_cmds()
	var toggle = null
	for b in deck.cmd_buttons:
		if b.cmd.id == "counter_launch":
			toggle = b
	if not TestCheck.ok(self, toggle != null and toggle.count_text == "꺼짐" and not toggle.blocked, "무장 탭 자동 대응 기본 꺼짐"): return
	var selected_id: int = battle.my_sel()[0].id
	toggle.pressed.emit()
	battle.sim.step()
	battle._sync()
	deck._refresh_cmds()
	if not TestCheck.ok(self, battle.sim.st.by_id(selected_id).counter_launch and toggle.count_text == "켜짐", "버튼 → 명령 → 코어 → 화면 켜짐"): return
	toggle.pressed.emit()
	battle.sim.step()
	battle._sync()
	deck._refresh_cmds()
	if not TestCheck.ok(self, not battle.sim.st.by_id(selected_id).counter_launch and toggle.count_text == "꺼짐", "다시 누르면 해제"): return
	print("RULE_TEXT_SALVO_PASS")
	quit(0)
