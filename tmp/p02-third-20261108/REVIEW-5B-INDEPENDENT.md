# P02 제한 fresh replay 구현 독립 5-b

2026-11-08. **제한 신규 CLI replay 구현 한정 수용.** 계획 SHA `4fe0b4d9137934ecba7d08401fa116ecf138ddc83dbca4db2d1ffc05ce122f9e`. 제품 replay·WorldMap·UI/clock·BattleOutcome이나 외부 save를 수용한 것이 아니다. 전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED. 문서·전달물 마감과 배포·커밋·병합은 이 판정 밖이다.

- 실제 코드를 확인했다. CLI는 opt-in으로 입력 파일을 한 번 읽어 SHA를 산출하고 기존 공통 factory에 input을 전달한다. 제한 명령 구조와 순서를 전체 검증한 뒤 동일 틱 queue→advance→drain한다. 일반 성공과 실패는 owner close 경계를 거친다. 종료 후 미소비 명령은 오류로 반환하여 출력 helper에 도달하지 않는다. 제한 CLI는 새 소비자이고 제품 replay 호출을 변경하지 않았다. OS 동시 writer·디스크 장애·엔진 예외 및 강제 종료는 검증 범위 밖이다.
- 독립 native oracle은 구현의 변환기를 사용하지 않고 BattleSim을 직접 실행한다. 동틱 순서 교환과 마지막 명령 제거가 관측값을 바꾸며 원본 replay fingerprint 비교는 기본 controls·종료 전 공통 구간에 한정한다. 실제 native 이벤트 순서·타입 및 비가시 표적 거부, 마지막 틱과 자연종료/미소비, 명시 direct/delegate, 빈 controls 및 누락 거부를 별도 검사했다는 실행 원문을 확인했다. direct/delegate의 이번 CLI DTO 차이는 관측되지 않아 차이를 주장하지 않는다. 보급 완료는 미관측이다.
- attempt1 replay-api 실패 원문은 기본 controls의 생성 직후 상태와 명령 후 상태를 비교했다. FleetState의 기본 delegate와 player 명령의 direct 전환 코드를 대조하면 2차의 기대 시점 정정은 타당하다. 동결 native oracle의 이후 summary/event/type 검사는 유지됐다. 실패는 지워지지 않았다.
- attempt2 결과 SHA `1cc9c3c01021b25aa4d17ed146e9f77d95e1c24ef4ebe4766cf96c86824b042c`: 75 프로세스 중 74 통과, battle-flow 1건 실패, 비교 36건 통과. exit 0 22건·의도 exit 1 53건. replay API는 14 사례·101 검사 PASS다. 실패 판정 자체는 false로 보존되며 독립적으로 성공으로 바꾸지 않았다.
- battle-flow는 attempt1/2 exit 0 및 PASS였고 두 stderr SHA는 `54388bb9493153c525e5519a3b3bb8c42a600edb11c58048a4c77593e3b0949e`로 동일하다. 10/28 보존 로그에는 PASS 전 TRACE 경고 3건과 PASS 후 153 ObjectDB/18 resources 진단이 있다. attempt2 하네스가 과거 전체 진단과 비교해 불일치한 뒤, attempt3은 과거 PASS 이후 종료 4행을 대조하고 현재 전체 진단 개수도 SCRIPT ERROR 0/WARNING 1/ERROR 1로 검사했다. attempt3 단일 프로세스 PASS, SHA `aac5b89c23ab1ab5328f3eb61daf874d177c5772324f5cadfdabe87b81aa1b7a`. 이것은 과거 로그 비교이며 변경 직전 재실행 기준선이라고 주장하지 않는다. 1/2/3차 실제 프로세스는 각각 74/75/1개다.
- attempt2 동결 파일 281개를 현재 bytes/SHA로 독립 재계산해 불일치 0을 확인했다. baseline 7,967개와 최종 7,973개 비교에서 차이 7경로는 P02 소유 6경로 및 별도 사용자 진행표 1경로이며 P03 추가 차이는 없다. 최종 7,973개를 현재 bytes/SHA로 독립 재계산해 불일치 0. 진행표는 P02 구현 소유로 합치지 않는다. 기존 index/cache 및 diff-check의 실제 실패 진단은 보존 기록에 따라 별도 분류된다. 기존 sync/worker 혼용 오류의 전후 비교 보충 기록도 확인했다.

이 판정은 기록된 정상 제어 경로와 테스트된 입력에 한정된다. 실제 제품 화면·Android·성능, 전체 명령·legacy trace 및 checkpoint/cursor는 별도 인수다.
