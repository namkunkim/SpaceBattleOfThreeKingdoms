extends SceneTree

const Owner := preload("res://core/battle/operation_private_state.gd")
const Replay := preload("res://scripts/first_operation_replay_codec.gd")

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or not ProjectSettings.load_resource_pack(args[0]):
		printerr("Could not open final Windows executable pack")
		quit(1)
		return
	if Owner._packaged_code().size() != Owner.CODE.size() or Replay._packaged_rules_digest().is_empty():
		printerr("Final Windows executable fingerprint is invalid")
		quit(1)
		return
	print("FINGERPRINT_RUNTIME_VERIFY_PASS")
	quit()

