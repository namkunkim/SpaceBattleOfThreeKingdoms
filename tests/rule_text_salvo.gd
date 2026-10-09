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
	print("RULE_TEXT_SALVO_PASS")
	quit(0)
