# P03 증원과 전대 ID 인덱스 검증 계획

전체 P03/I01/I01b/A04~A06 NOT_READY. O07 OPEN. 외부 저장 schema UNCLASSIFIED. 증원과 전대 ID 인덱스의 경계만 검증한다. 생산 코드 변경 없이 전용 폴더에 runner와 결과를 둔다. INPUT-SHA256.txt는 HEAD와 작업 트리 원문을 분리해 동결한다.

| 조사 단위 | 현재 원문에서 관측한 책임 |
|---|---|
| profile.reinf 및 _reinf_def | BattleSim 초기화가 배열을 취한다. private state 설정 진입은 비어 있지 않은 배열을 unsupported_reinforcement로 거부한다. 증원 편성 자료는 운영 복원 정책을 별도 결정해야 한다. |
| BattleState.reinf / reinf_ms | bool과 int. _spawn_reinf가 완료 표지와 clock_ms를 기록한다. 승패·시간 조건에서 증원이 호출될 수 있다. PRIVATE STATE 목록에는 들어가지만 true 또는 -1 이외 시각은 복원 검증에서 지원 밖이다. |
| fleets / next_id / by_id | fleets는 순서 있는 전대 배열이다. _idx는 동적 int ID → FleetState 객체, _idx_n은 캐시의 배열 길이이다. by_id는 길이 변화 시 재구축하고 첫 번째 동일 ID를 취한다. 복원 코드는 캐시를 비우고 _idx_n을 -1로 둔다. |
| reinforcements 사건 | 증원 생성에서 발행하는 사건과 증원 상태를 구분한다. 다음 인수에서 이벤트 큐 복원과 외부 소비를 별개로 다룬다. |
| clock/RNG, 모듈 키, effects | 증원 clock_ms를 관측한다. RNG·모듈·효과 전체 소유권 분류와 자연 운영 Cn은 별도 조각에 남긴다. |

1. 지원 프로필로 제한 런타임을 초기화하고 캐시를 따뜻하게 만든다. 다른 정상 상태를 가진 동일 context snapshot을 복원한 뒤 by_id 반환 객체가 새 배열에 속하는지, 이전 객체와 동일하지 않은지 확인한다.
2. 의도적으로 snapshot의 reinf, reinf_ms를 각각 한 항목씩 변경한다. 기존 정상 packet을 양성 대조로 사용한다. 정확 사유와 old active 객체·상태·이벤트 보존을 검증한다. profile.reinf가 채워진 공개 진입의 거부 경로를 독립 대조한다. 정적 필드 목록만으로 저장 가능 판정하지 않는다.
3. 증원 없이 지원되는 제한 C0/Cn과, 별도 raw sim에서 관측하는 증원 순간을 분리한다. raw sim 증원은 정본 운영 복원 성공으로 집계하지 않는다. runner가 허용 범위를 넘어야 하면 결과를 중단·기록한다.
4. 독립 계획 검토 수용 후 runner 작성. 5a에서 동결 경로 SHA 및 정확한 입력별 예상/실제 판정을 점검한다. 5b에서 다른 모델이 입력·판정 근거 및 가역성 확인. closeout에서 산출물과 동결 보존을 감사한다. 실패 시 로그를 보존하고 수정 근거가 있는 재시도 최대 1회.
