# S4 모듈과 동적 효과 읽기 원장

상태는 NOT_READY / UNCLASSIFIED다. 생산 원문은 READONLY-SOURCES.sha256, 기존 원장은 같은 파일의 Detection, Supply, ChainOp, SkillCore, DecisionBoard 항목으로 식별한다. 본문은 producer 및 핵심 소비 경로를 읽은 결과다. 전체 제품 소비 경로, 동적 로드, 프로필별 키 집합, 활성 모듈 복원과 런타임 fixture는 미검증이다.

| 소유자·필드 | 초기화·갱신 | 소비·재결합 및 현재 제한 |
|---|---|---|
| CommandCore.sim | command.gd:24–28에서 현재 sim | tick 및 roster 읽기. 지원 확대 시 후보 sim에 연결할 참조. 현재 owner UNSUPPORTED |
| CommandCore.K | combat.command | command.gd:29–72에서 부상·단계·확률·페널티 |
| CommandCore.S | commander_succession | command.gd:87–100에서 대리자·혼선 기한 |
| CommandCore.stats.succession | 0 → 대리 승계마다 증가 | command.gd:87–100. 통계 소비 전체 미분류 |
| CommandCore.stats.leaderless | 0 → 대리자 없음 증가 | command.gd:87–93. 무기한 혼선과 별도 값 |
| CommandCore.stats.severe | 0 → _worsen의 ns 조건 증가 | command.gd:76–82. 상태 문자열이 키를 선택 |
| CommandCore.stats.light | 위와 같은 별도 키 | command.gd:76–82. killed/captured는 이 초기 키 집합 밖 |
| FleetState.cmdr_state | command.gd:76–82 악화 | command.gd:29–72, victory.gd:170–209 |
| FleetState.cmdr_sub | command.gd:87–100에서 부지휘관/참모의 인물 ID 문자열 | UI/결산 및 무지휘 판단. fleet ID가 아님 |
| FleetState.confuse_until | command.gd:87–100에 기한 또는 FOREVER | command.gd:33–34에서 tick < 기한 |
| AssaultCore.sim | assault.gd:17–19 현재 sim | roster, clock, RNG, emit. 지원 확대 시 후보 sim 연결, 현재 UNSUPPORTED |
| AssaultCore.A | combat.assault | assault.gd:34–116의 성공·개방·쿨다운 |
| AssaultCore.stats.unit | 배열 [시도, 성공] 초기화 후 attempt 증가 | assault.gd:86–117. 위치가 의미를 부여 |
| AssaultCore.stats.flagship | 배열 [시도, 성공] 초기화 후 attempt 증가 | assault.gd:86–117. 종류가 키를 선택 |
| AssaultCore.stats.forced | 배열 [시도, 성공] 초기화 후 attempt 증가 | assault.gd:86–117. 강제 조건 키 |
| FleetState.fr_hits | salvo.gd:692–694에서 최근 틱 append와 길이 제한 | assault.gd:43–47에서 창 안의 개수. 순서 보존 |
| FleetState.assault_cd | assault.gd:96에 다음 시도 가능 틱 | assault.gd:64에서 비교 |
| FleetState.boarded | assault.gd:110에서 진입 성공 표지 | salvo.gd:373–382에서 지휘관 피해 보정 |
| MoraleCore.sim | morale.gd:22–24에서 현재 sim | roster와 tick 참조. 현재 UNSUPPORTED |
| MoraleCore.M | morale 설정 사전 | morale.gd:70–136 피해·결집 |
| MoraleCore.plague_ticks | morale.gd:27, hz로 interval 환산 | morale.gd:138–141에서 나머지 0 판정 |
| MoraleCore.crisis_sent | [false,false] → 진영별 한 번 true | morale.gd:146–151의 사건 중복 억제 |
| MoraleCore.rally_uses | morale.gd:28–29에서 profile rally ID→남은 횟수, 성공 시 감소 | morale.gd:110–136의 존재·횟수·source 참조. 키 전체는 프로필별 동적 |
| MoraleCore.plague_bp_total | 0 → 실제 차감 사기 합 | morale.gd:152–159. 전역 집계 소비 미분류 |
| MoraleCore.recoveries | 0 → 결집 성공 때 증가 | morale.gd:134. 전역 집계 소비 미분류 |
| MoraleCore._cost_total | init에서 진영별 초기 cost0 합 | morale.gd:41–48의 분모. 재계산 시 roster 시점 보존 필요 |
| MoraleCore._dispersed | init에서 formation_classes.dispersed | 역병의 진형 eligibility |
| MoraleCore._plague | init에서 linked_ships_and_plague | 전염 대상/간격/피해 설정 |
| SalvoCombat.sim | salvo.gd:20–24에서 소유 sim | owner._bindings에서 인스턴스 연결 검증 |
| SalvoCombat.C | init의 combat 사전 | 전투/형성/무기 설정. owner에서 새 프로필로 재생성 |
| SalvoCombat.terr | 지형 연결 | 사거리·각도; terrain은 후보 지형 인스턴스, 설정/구역 derived 비교 |
| SalvoCombat.terrain_class | init에서 전장 지형 등급 | terrain_allowed에서 제한, derived 정확 비교 |
| Victory.sim / V | victory.gd:20–22에서 참조/설정 | check/settle. 현재 UNSUPPORTED |
| Victory.period | victory.gd:23에서 hz와 설정 환산 | victory.gd:120–138에서 주기 |
| Victory.anchor_faction | victory.gd:24–26에서 초기 0측 기함 세력 | victory.gd:51–67,79–118 손실/탈출 대상 |

## Victory 결산과 참조

- victory.gd:139–167의 producer가 BattleState.result에 쓰고 _end가 종료값을 기록한다. top key는 `win,winner_side,reason,limited,t_s,tick,cost,army_morale_bp,conditions,commanders,captured_in_retreat,casualties,fleets` 13개다. 제한 owner에서 result는 STATE 복사 대상이지만 활성 Victory 객체는 지원 밖이다. 외부 결과 출판 경계는 P02 원장과 별도다.
- cost의 alliance/anchor/foe 각각 `original,remaining,loss_bp`, conditions의 alliance/foe는 순서 있는 사유 배열, commanders의 alliance/foe는 상태 문자열이다. army_morale_bp는 [진영 0, 진영 1] 순이다. 조건 계산 중간 사전의 `limited`는 결산에서 top level이다.
- fleets는 현재 roster 순서, 각 행은 `sq,side,out,mstate,morale_bp,ships_left,cost_left,cost0`. captured_in_retreat는 실패한 squadron 문자열 ID 배열. casualties는 `sq,person,state,sub` 행으로 인물 ID 및 대리자 문자열을 참조한다. 숫자 fleet ID로 재결합하지 않는다. 근거 victory.gd:143–167,197–209.
- 동적 키 열거는 위 모듈의 init/settle 리터럴을 읽고 변수 인덱스 `stats[ns]`, `stats[key]`, `rally_uses[r.id]`를 소비 호출과 대조하는 방식이다. 설정 사전 키와 런타임 생성 키를 분리했다. 구체 프로필의 rally ID 집합과 외부 소비는 미분류다.
- 기존 Detection은 접촉과 위치, Supply는 repair와 회복·재고, ChainOp는 격침·참조·효과, SkillCore는 기간/즉시 효과, DecisionBoard는 카드 효과와 AI override를 담당한다. 이 원장의 분모에 기존 선언·하위 record를 다시 더하지 않는다.
