from pathlib import Path
import hashlib
import shutil

out = Path(__file__).resolve().parent
v3 = out / "v3"
v3.mkdir(exist_ok=False)

common = (out / "product-outcome-common.gd").read_text(encoding="utf8")
common = common.replace("/fixture.gd", "/v3/fixture.gd")
start = common.index('\tvar battle := current_scene')
end = common.index('\n\tif is_instance_valid(current_scene):', start)
common = common[:start] + """\tawait direct_product()
""" + common[end:]
start = common.index("func data()")
common = common[:start] + """func button_named(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := button_named(child, label)
		if found != null:
			return found
	return null

func direct_product() -> void:
	var battle := current_scene
	var link := root.get_node("WorldLink")
	if not check(battle != null and battle.name == "FleetBattle3D" and link.routed() and link.brief.seed == 777, "A03 direct routed"):
		return
	var deck = battle.presentation.hud
	if not check(deck.screen == "prologue" and not GameSettings.prologue_seen and not FileAccess.file_exists(GameSettings.PATH), "A03 first-run native prologue"):
		return
	var skip := deck.screens.prologue.skip as Button
	if not check(skip != null and skip.is_visible_in_tree() and not skip.disabled, "A03 native prologue skip"):
		return
	skip.emit_signal("pressed")
	if not check(deck.screen == "brief" and GameSettings.prologue_seen and FileAccess.file_exists(GameSettings.PATH), "A03 native briefing and saved progress"):
		return
	var saved := ConfigFile.new()
	if not check(saved.load(GameSettings.PATH) == OK and saved.get_value("progress", "prologue_seen", false) == true, "A03 persisted progress value"):
		return
	var start := button_named(deck.screens.brief, "자동 편성으로 시작")
	if not check(start != null and start.is_visible_in_tree() and not start.disabled, "A03 native auto-organization start button"):
		return
	start.emit_signal("pressed")
	battle.set_process(false)
	if not check(battle.G.state == "play" and battle.sim.st.tick == 0, "A03 native start"):
		return
	for i in FIXTURE.DIRECT_TICK:
		battle.sim.step()
	var tick: int = battle.sim.st.tick
	if not check(tick == FIXTURE.DIRECT_TICK and not battle.sim.st.over, "A03 fixed terminal injection tick"):
		return
	battle.sim._end(true, "annihilation")
	battle.end_game(true, "테스트")
	battle.set_process(true)
	await create_timer(2.2).timeout
	var btn: Button = deck.screens.result.title_btn
	if not check(deck.screen == "result" and btn.text == "천하로" and btn.is_visible_in_tree() and not btn.disabled, "A03 native result button"):
		return
	btn.emit_signal("pressed")
	await frames(8)
	var returned := current_scene as WorldMapScreen
	if not check(returned != null and returned.outcome != null and returned.outcome.seed == 777, "A03 WorldMap consumed result"):
		return
	rows.A03 = await card(returned, "A03")
	rows.A03.tick = tick
	rows.A03.transitions = ["WorldMap sortie/skip", "FleetBattle3D prologue/skip", "brief auto-organization/start", "native result button", "WorldMap result"]
	rows.A03.consumed = link.brief == null and link.outcome == null and link.take_outcome() == null
	check(rows.A03.consumed, "A03 single consume")

""" + common[start:]
common = common.replace("var profile := brief.profile()",
"""var profile := brief.profile()
	var adapter_script: Script = ADAPTER
	check(adapter_script.resource_path == "res://core/battle/operation_runtime_adapter.gd", "A06 canonical adapter path")
	check(not profile.is_empty() and profile.reinf.is_empty() and not profile.scenario.is_empty(), "A06 original product profile")
	rows.A06_profile_sha = var_to_bytes(profile).hex_encode().sha256_text()""")
common = common.replace("var rows := {}", "var rows := {}\nvar profile_evidence := {}")
common = common.replace('rows.A06_profile_sha = var_to_bytes(profile).hex_encode().sha256_text()',
'''profile_evidence = {"profile": BattleBrief.PROFILE_DEF, "profile_source_sha": FileAccess.get_sha256(BattleBrief.PROFILE_DEF),
		"runtime_profile_sha": var_to_bytes(profile).hex_encode().sha256_text(), "adapter": adapter_script.resource_path}''')
common = common.replace('"version": Engine.get_version_info().string}', '"version": Engine.get_version_info().string, "settings_at_start": FileAccess.file_exists(GameSettings.PATH)}')
common = common.replace('await product()','check(not guard.settings_at_start, "canonical clean-user profile")\n\tawait product()')
common = common.replace('"guard": guard}', '"guard": guard, "profile": profile_evidence}')
(v3 / "product-outcome-common.gd").write_text(common, encoding="utf8")
fixture = (out / "fixture.gd").read_text(encoding="utf8").replace('"unsupported_reinforcement", "path": "profile.reinf"', '"unsupported_scenario", "path": "profile"')
(v3 / "fixture.gd").write_text(fixture, encoding="utf8")
boundary = (out / "product-outcome-boundary.gd").read_text(encoding="utf8").replace("/fixture.gd", "/v3/fixture.gd")
boundary = boundary.replace('await malformed()', '''print("FIFTH_USER ", JSON.stringify({"dir": OS.get_user_data_dir(), "initial_files": DirAccess.get_files_at("user://")}))
	await malformed()''')
(v3 / "product-outcome-boundary.gd").write_text(boundary, encoding="utf8")
(v3 / "returning-settings.cfg").write_bytes(b"[progress]\nprologue_seen=true\n")
assert hashlib.sha256((v3 / "returning-settings.cfg").read_bytes()).hexdigest() == "c8b752aba9f5015889c00c5a45db9fef916af2a1e1be3e68d49b8121b2db721b"

# These wrappers observe process startup then hand off to the exact original tests.
for suite in ("world_link", "p02_worker_adapter", "p02_headless_adapter"):
    (v3 / (suite + "-path-probe.gd")).write_text(f"""extends "res://tests/{suite}.gd"

func _initialize() -> void:
	var settings := "user://settings.cfg"
	var has_settings := FileAccess.file_exists(settings)
	print("FIFTH_USER ", JSON.stringify({{"dir": OS.get_user_data_dir(), "initial_files": DirAccess.get_files_at("user://"),
		"settings_sha": FileAccess.get_sha256(settings) if has_settings else ""}}))
	super._initialize()
""", encoding="utf8")
