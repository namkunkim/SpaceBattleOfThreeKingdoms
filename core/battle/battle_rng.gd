class_name BattleRng
extends RefCounted

# 규칙 난수(제안서 §3.3): sha256(profile_id|tick|event_id) 앞 8자리.
# 상태가 없다. 같은 (프로필, 틱, 사건 ID, 하위 번호)는 언제나 같은 값을 준다.
# 사건 ID는 BattleState.next_event_id(상태 안의 증가 카운터)로 붙인다. 한 사건 안의 여러 추첨은 하위 번호로 나눈다.
# 연출 난수는 여기를 쓰지 않는다(view/ 전용 생성기).

var profile_id := ""

func _init(profile: String) -> void:
	profile_id = profile

func u32(tick: int, event_id: int, sub: int = 0) -> int:
	var key := "%s|%d|%d" % [profile_id, tick, event_id]
	if sub != 0:
		key += ":%d" % sub
	return key.sha256_text().substr(0, 8).hex_to_int()

# 0~9999 정수(bp 추첨). 확률 p는 bp(...) < p × 10000으로 판정한다.
func bp(tick: int, event_id: int, sub: int = 0) -> int:
	return u32(tick, event_id, sub) % 10000

# [0, 1) 실수. 연속값(속도, 흔들림 등)에만 쓴다.
func unit(tick: int, event_id: int, sub: int = 0) -> float:
	return u32(tick, event_id, sub) / 4294967296.0

# [0, n) 정수
func index(n: int, tick: int, event_id: int, sub: int = 0) -> int:
	return u32(tick, event_id, sub) % maxi(1, n)
