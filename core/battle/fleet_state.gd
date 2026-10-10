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
var ranges := {}          # 무기 범주별 최대 사거리 {범주: 거리}. 쏠 플랫폼이 없는 범주는 키가 없다(아군 표시용)
var sq_id := ""           # 시나리오 전대 ID (POC 프로필은 빈 문자열)
var morale_group := ""
var start_morale_bp := 0  # 시작 사기
var faction := ""         # 시나리오 세력 ID (liu_bei, sun_quan, cao_cao)
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

# --- M5 진형과 기동 ---
var form_to := ""             # 전환 중인 목표 진형. ""이면 전환 없음. formation_id는 전환이 끝날 때까지 이전 진형이다(§4.7)
var form_left := 0            # 전환 남은 틱
var route: Array[Vector2] = []   # move_to 다음에 지날 경유점·목적지(§4.2)
var strafe := false           # 평행 이동: 선회 없이 방향을 유지한 채 옆으로 이동
var face_set := false         # 도착 방향 지정
var speed_cap := 0.0          # 그룹 이동 속도 상한(0 = 없음). 함께 이동하는 함대 중 가장 느린 속도
var face_to := 0.0
var traits: Array = []        # 지휘관 특성(팔진 조건)
var shape := -1               # 배치도 번호(BattleRules.formation_offsets의 kind). -1이면 POC(form_id)

# --- M7 지휘관 AI ---
var control := "delegate"     # "delegate"(기본, 지휘관 AI가 이동·표적을 정한다) | "direct"(플레이어가 명령해 AI가 손대지 않는다, §5.4). 적 진영은 항상 AI
var posture := "delegated"    # 전투 방침: aggressive | balanced | cautious | scheming | delegated(지휘관 성향에서 고른다)
var bias_mod := 0.0           # 결정 카드가 건 일시 가중(전황 반응과 같은 축). bias_until 틱까지
var bias_until := -1
var pursue_id := -1           # 결정 카드로 정한 추격 표적. pursue_until 틱까지
var pursue_until := -1
var ai_seen := -1             # 처음 접촉을 안 틱(난이도 반응 지연의 기준). 접촉이 없어지면 -1

# --- M8 보급과 수리 ---
var hit_tick := -1            # 마지막으로 명중을 받은 틱(경파 자연 회복의 기준)
var healed_wound := 0         # 경파 자연 회복으로 무손상이 된 척 수 누계. _wound가 손상 목표에서 뺀다(REVIEW-M8 F-1)
var healed_mod := 0           # 수리로 중파 → 경파가 된 척 수 누계. _wound가 중파 하한에서 뺀다
var sup_src := ""             # 배정된 공급원 키(기지 ID 또는 "f<전대 ID>"). ""이면 배정 없음
var sup_prog := 0             # 이번 주기 진행(bp·틱). 처리량만큼 쌓인다
var sup_since := -1           # 정지를 시작한 틱(처리 순서). 움직이면 -1
var sup_still := false        # 이번 틱에 정지해 있었다
var sup_pos := Vector2.ZERO   # 지난 보급 판정 때 위치
var sup_n := 0                # 보급함 전대: 지난번 보급함 수(재고 손실 계산)
var sup_ammo := 0             # 보급함 전대 재고: 탄약 단위
var sup_mat := 0              # 보급함 전대 재고: 물자
var supplied := 0             # 끝낸 보급 주기 수(통계)

# --- M9 지휘 승계·강습 ---
var level := 1                # 지휘관 레벨(승계 순서. 데이터에 없으면 1)
var vice: Dictionary = {}     # 전대 부지휘관 정의 {id, name, command, might, intellect, traits}. 없으면 빈 사전
var staff: Array = []         # 전대 참모 정의 목록
var cmdr_state := "unhurt"    # 전대 지휘관 상태: unhurt | light | severe | killed | captured (악화 방향으로만, G8-04)
var cmdr_sub := ""            # 지휘관이 지휘 불능이라 능력치를 이은 사람(부지휘관 → 첫 참모). ""이면 없음
var confuse_until := -1       # 이 틱 전까지 명령 혼선(승계). 지휘 공백이면 아주 큰 값
var fr_hits: Array[int] = []  # 최근 측면·후면 명중 틱(강습 진형 붕괴 판정)
var assault_cd := 0           # 이 틱부터 다시 강습할 수 있다
var boarded := false          # 기함 진입을 당해 지휘관 보정이 사라졌다
