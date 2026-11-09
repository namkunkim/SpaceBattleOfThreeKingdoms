extends "res://tmp/p02-third-20261108/oracle.gd"

func _run() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/p02/worker-services.json"))
	var profile: Dictionary = data.profile
	profile.ally[0].ships = 4
	profile.foe[0].ships = 40
	for fleet in profile.ally + profile.foe:
		fleet.lv = 1
		fleet.p = 0
		fleet.command = 70
		fleet.start_morale_bp = 10000
	profile.ally[0].composition[0].count = 1
	profile.ally[0].composition[1].count = 1
	profile.ally[0].composition[2].count = 2
	profile.foe[0].composition[0].count = 40
	profile.foe[0].x = 2500
	var command := BattleSim.command(0, [1], "attack", 2)
	command.tick = 0
	var hidden := run_native(profile, [command], ["delegate", "delegate"], 1)
	var last: Dictionary = hidden.events[-1]
	print("P02_HIDDEN_ORACLE " + JSON.stringify(hidden))
	var passed: bool = last.kind == "rejected" and last.value == "no_contact" and last.tick == 0 and hidden.commands_consumed == 1
	quit(0 if passed else 1)
