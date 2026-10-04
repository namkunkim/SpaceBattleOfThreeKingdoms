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
var sq_id := ""           # 시나리오 전대 ID (POC 프로필은 빈 문자열)
var morale_group := ""
var start_morale_bp := 0  # 시작 사기
var faction := ""         # 시나리오 세력 ID (liu_bei, sun_quan, cao_cao)
var group_id := ""        # 시나리오 함대 ID (RC-LIU-FLT-01 …)
var commander_id := ""

# --- M3 사격·피해 상태(전투 규칙이 salvo일 때만 쓴다. max_hull == 0이면 POC 규칙이다) ---
var cmd_stat := 0         # 지휘관 통솔
var morale_bp := 10000    # 전대 사기(bp). 명중·이탈·역병으로 줄고 사건으로만 늘어난다(M4)
var stats: Dictionary = {}    # 지휘관 능력치 {command, might, intellect}
var formation_id := ""
var equip := ""           # 고속정 임무장비
var comp0: Dictionary = {}    # 함종 → 처음 척 수(상수)
var stages: Dictionary = {}   # 함종 → [무손상, 경파, 중파, 대파, 격침] 척 수
var hull := 0                 # 선체 점수
var max_hull := 0
var lost_ships := 0           # 이탈(대파·격침)한 척 수의 누계
var loss_total := 0           # 이탈 배분에 쓴 척 수(60/40 배분 카운터)
var loss_exposed := 0
var ammo: Dictionary = {}     # 범주 → 남은 탄약(뇌격은 특수 충전)
var energy_m := 0             # 1/1000
var energy_rem := 0
var heat_m := 0
var heat_rem := 0
var sorties_m := 0
var sorties_rem := 0
var next_fire: Dictionary = {}   # 범주 → 다음 일제사격 틱
var supp: Dictionary = {}        # 범주 → 보류 사유(없으면 "")
var speed := 0.0              # px/초

# --- M4 사기와 승패 ---
var mstate := "stable"        # 사기 상태: stable(6000+) | shaken(3000~5999) | retreat(1~2999). 항복(0)은 out == "surrender"
var out := ""                 # 전투에서 빠진 사유: "" | "sunk" | "surrender" | "escaped". 빠지면 dead도 참이다
var retreat_order := false    # 플레이어가 후퇴 명령을 내렸다(탈출 지점으로 이동)
var retreat_counted := false  # 퇴각·항복 사건을 군 사기에 한 번 반영했다
var loss_mul_until := -1      # 이 틱 전까지 사기 감소 배율(결집 효과)
var loss_mul_bp := 10000
var cost0 := 0               # 처음 코스트(함종 비용 합, 임무장비 제외)
var chain_sunk := false      # 연쇄 폭발로 격침됐다(M9)
var died_pos := Vector2.ZERO
var arrived := false         # 자기 탈출 지점 반경에 한 번 닿았다(전대 간격 때문에 한 점에 모두 서 있을 수 없어 래치한다)
var fired: Dictionary = {}   # 범주 → 첫 일제를 쐈다(첫 일제 엇갈림용)
