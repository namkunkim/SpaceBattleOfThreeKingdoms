class_name FleetState
extends RefCounted

# 전대 하나의 코어 상태. 다른 전대·미사일은 ID로만 가리킨다.
# 척 수와 경험치는 1/1000척 정수, 시간은 틱 정수. 위치·방향은 매 틱 끝에 0.001 격자로 반올림한다.

var id := 0
var side := 0
var name := ""
var role := ""
var portrait := 0
var form_id := 0
var form: Array[Vector2] = []
var ships := 0            # 1/1000척
var max_ships := 0
var shown := 0            # 손실 사건을 낸 척 수까지 내려간 값(1/1000척, 1000 단위로 줄어든다)
var lv := 1
var xp := 0               # 1/1000척(가한 피해)
var pos := Vector2.ZERO
var heading := 0.0
var target_id := -1
var has_move := false
var move_to := Vector2.ZERO
var missile_cd := 0       # 틱
var fighter_cd := 0
var charge := 0           # 돌격 남은 틱
var flank_msg := 0
var defense := false
var dead := false
var fire_id := -1         # 이번 틱에 쏜 표적
var in_cmd := true
var spd := 1.0
var wait := 0             # 적 AI 대기 틱
var is_flag := false
var home := Vector2.ZERO
var range_r := 0.0
