class_name ProfileLoader
extends RefCounted

# 데이터 파일 읽기. 코어가 파일을 여는 곳은 여기뿐이다.

static func read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("프로필 파일이 없다: %s" % path)
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("프로필 JSON을 읽지 못했다: %s" % path)
		return {}
	return parsed
