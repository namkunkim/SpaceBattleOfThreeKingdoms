# C side 1 v9 필수 fixture 및 외부 상태 판정

v8 원문 및 독립 심사를 보존했다. 이 조각은 C detection case 단위 오프라인 의미 판정기다. 실제 Godot이나 제품은 실행하지 않았다.

check_case는 별도 승인 SHA와 fixture pin 파일을 반드시 받는다. Pin 원문 SHA, seed/case, typed context의 seed와 roster를 검사하고 원문 _detection이 사용하는 roster의 두 번째 fleet에서 선택 ID를 도출한다. Candidate reported ID는 이 값과 일치해야 한다. 모든 phase의 raw packet context를 동일 독립 typed context에 결합한다. 처음 selected contact의 state도 case와 일치해야 한다. Pin 누락이나 candidate가 pin 파일과 payload를 함께 교체한 경우는 실패다. 실제 실행기는 승인 SHA를 독립 기록에서 가져와야 한다.

세 phase 모두 actual result true와 pre/post typed target snapshot이 필수다. Phase 내부와 source 간의 profile/seed/hz/tick/clock/roster/typed fleet positions가 모두 보존돼야 한다. 첫 target side 0은 원문대로 비어 있어야 하고, 뒤 phase의 pre 상태는 앞 phase의 post 상태와 이어진다. Wrong-position control은 독립 roster가 지정한 contact의 위치 단독 변경을 허용한다. 다른 selected/외부 변화 및 대상에 적용되지 않은 변이를 거부한다. 독립 capture receipt metadata와 외부 snapshot dictionary 순서 차이는 기존 v8의 좁은 허용 범위다. Scoped snapshot 밖의 원문 _all, detach, alias 및 사건 확인은 별도다.

합성 정상 1세트와 반례 10건을 확인했다. 필수 pin과 독립 승인 SHA 누락, pin 교체, 위조 ID, packet/live fixture 동시 교체, target 외부 위치 변경, 양측 pre/post 동일 변경, phase 사이 drift, 잘못된 bool 및 phase 누락을 거부했다. 양성은 서로 다른 receipt metadata가 같은 상태로 판정되는 경로다.

v9는 실제 producer나 v7 원본 raw sequence 검증에 통합된 실행기가 아니다. 최종 통합은 승인 raw receipt/order → 동일 소유 프로세스의 immutable payload/identity → v9 필수 pin과 pre/post → 별도 전체 원자성·detach oracle 순으로 고정해야 한다. 실제 engine fixture decoder 호환성, 승인된 full closure, producer, C geometry 관측, GUI 및 Job은 미입증이다. 독립 심사 대상은 이 한정 합성 판정기다. 제품/Godot/GUI/Job 실행 0회이며 K6 한 회가 남아 있다.
