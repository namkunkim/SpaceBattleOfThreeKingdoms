class_name TickClock
extends RefCounted

# 고정 틱 누산기. 실제 시간(프레임 delta)을 받아 이번 프레임에 돌릴 틱 수를 돌려준다.
# 속도는 누산기의 소비 속도만 바꾼다(정지 0, ×0.2, ×1, ×2, 자동 ×4). 틱 폭 0.1초는 그대로다.
# 코어 안에 있어서 Node·Time을 쓰지 않는다. 경과 시간은 호출하는 쪽(view/ 구동기)이 넘긴다.

const SPEEDS := [0.0, 0.2, 1.0, 2.0, 4.0]
const MAX_TICKS_PER_FRAME := 8   # 넘치는 시간은 버린다(틱 폭주 방지)

var hz := BattleRules.TICK_HZ
var speed := 1.0
var acc := 0.0                   # 누적 시간(틱 단위, 소수)
var dropped := 0.0               # 상한 때문에 버린 틱 수(진단용)

func set_speed(k: float) -> void:
	speed = maxf(0.0, k)

# real_s: 실제 경과 시간(초). 돌릴 틱 수를 돌려준다.
func advance(real_s: float) -> int:
	if speed <= 0.0:
		return 0
	acc += real_s * speed * hz
	var n := int(acc)
	acc -= n
	if n > MAX_TICKS_PER_FRAME:
		dropped += n - MAX_TICKS_PER_FRAME
		n = MAX_TICKS_PER_FRAME
	return n

# 틱 사이 보간 비율 0~1(표현용)
func alpha() -> float:
	return acc
