extends RefCounted

const NATIVE := &"O07Win32"
const ERROR_SHARING_VIOLATION := 32


static func with_lock(path: String, action: Callable) -> Dictionary:
	if not ClassDB.class_exists(NATIVE):
		return {"ok": false, "error": "supply_win32_unavailable"}
	var lock_path := _absolute(path) + ".lock"
	if DirAccess.dir_exists_absolute(lock_path):
		return {"ok": false, "error": "supply_slot_busy"}
	var lease := int(ClassDB.class_call_static(NATIVE, &"acquire", lock_path))
	if lease <= 0:
		var busy := lease == -ERROR_SHARING_VIOLATION or DirAccess.dir_exists_absolute(lock_path)
		return {"ok": false, "error": "supply_slot_busy" if busy else "supply_lock_failed",
			"win32_error": -lease}
	var result: Dictionary = action.call()
	if int(ClassDB.class_call_static(NATIVE, &"release", lease)) != 0:
		push_warning("SUPPLY_LOCK_RELEASE_FAILED")
	return result


static func publish(staged: String, path: String, existing: bool) -> Dictionary:
	var error := int(ClassDB.class_call_static(NATIVE, &"publish", _absolute(staged), _absolute(path), int(existing)))
	if error != 0:
		return {"ok": false, "error": "replace_failed", "path": path, "win32_error": error}
	return {"ok": true}


static func has_pending(path: String) -> bool:
	var slot := _absolute(path)
	var parent := DirAccess.open(slot.get_base_dir())
	if parent == null:
		return true
	for entry in parent.get_files():
		if entry.to_lower().begins_with(slot.get_file().to_lower() + ".pending-"):
			return true
	return false


static func _absolute(path: String) -> String:
	return ProjectSettings.globalize_path(path).simplify_path().replace("/", "\\")

