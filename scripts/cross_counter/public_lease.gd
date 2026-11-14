extends RefCounted

const NATIVE := &"O07Win32"
const ERROR_SHARING_VIOLATION := 32

var _handle := 0


static func acquire(path: String) -> Dictionary:
	if not OS.has_feature("windows") or not ClassDB.class_exists(NATIVE):
		return {"ok": false, "error": "cross_counter_windows_unavailable", "path": path}
	var absolute := ProjectSettings.globalize_path(path).simplify_path().replace("/", "\\")
	var handle := int(ClassDB.class_call_static(NATIVE, &"acquire", absolute + ".lock"))
	if handle <= 0:
		return {"ok": false, "error": "cross_counter_slot_busy" if handle == -ERROR_SHARING_VIOLATION
			else "cross_counter_lease_failed", "path": path, "win32_error": -handle}
	var lease := new()
	lease._handle = handle
	return {"ok": true, "lease": lease}


func held() -> bool:
	return _handle > 0


func close() -> void:
	if _handle > 0:
		var handle := _handle
		_handle = 0
		if int(ClassDB.class_call_static(NATIVE, &"release", handle)) != 0:
			push_warning("CROSS_COUNTER_LEASE_RELEASE_FAILED")
