class_name PocSetup
extends RefCounted

# POC 프로필(적벽 회랑 데모)의 로더. 규칙 수치와 편성은 data/profiles/poc_corridor.json에 있다.
# M3에서 실시간 규칙이 POC 규칙을 대체하기 전까지 M1 기준선과의 동등성을 지키는 프로필이다.

const PATH := "res://data/profiles/poc_corridor.json"

static var _cache := {}

# 프로필 사전: {profile_id, rules, ally, foe, reinf}. 읽은 뒤 복사해서 준다.
static func profile() -> Dictionary:
	if _cache.is_empty():
		_cache = ProfileLoader.read_json(PATH)
	return _cache.duplicate(true)
