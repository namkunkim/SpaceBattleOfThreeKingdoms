extends SceneTree

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1 or args[0] not in ["normal", "wait"]:
		quit(2)
		return
	print("P02_NONPRODUCT_START ", OS.get_process_id())
	if args[0] == "normal":
		# Short bounded residence for independent process membership observation.
		await create_timer(2.0).timeout
		print("P02_NONPRODUCT_END ", OS.get_process_id())
		quit(0)
	else:
		await create_timer(120.0).timeout
		quit(3)
