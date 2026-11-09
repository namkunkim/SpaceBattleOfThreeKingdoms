# P02 첫 PC 다음 한 세션 계획 · 직접 출격 장면 전환 거절

상태: 원문 조사 및 계획 초안. 독립 계획 심사 대기. 제품 수정·Godot 실행 0회. 전체 P02/첫 PC/캠페인/I01/I01b NOT_READY, 외부 저장 스키마 UNCLASSIFIED. 구현자 실제 모델 ID는 이 실행 환경에 표시되지 않았다. 조율자가 실제 할당 metadata를 확인할 수 있는 경우에만 기록한다. 독립 계획/5-b 심사자는 작성자와 별도이며 확인 가능한 비-Astra 모델과 실제 할당 근거를 남긴다.

## 현재 제품과 소유 범위

- §0의 순서는 첫 PC → 같은 규칙 버전 저장·재개 → 후속이다. 현재 실제 WorldMap은 `make_brief`에서 seed·difficulty·mode·anchor를 정하고 `_finish_sortie`에서 direct를 WorldLink로 보낸다(540–598). `BattleBrief`는 legacy UI 정보이고 공통 operation 입력이 아니다. `FleetBattle3D.init_game/_prepare_game/_publish_game`(176–183,270–345)은 raw BattleSim을 준비, 성공한 후보를 게시하고 두 시계를 초기화하며 첫 큐를 drain한다.
- 초기 배치에서 `issue`가 move/face를 place로 바꾼다(584–607). 제품 `_process`는 배치 중 틱을 멈추고 같은 raw sim을 전진시키며(478–505), 별도 `update_sim`은 헤드리스 보조 누산기를 사용한다(529–543). `_sync/_pump`는 side 0 투영과 가시 사건을 적용한다(545–567). 종결은 raw sim에서 `BattleOutcome.from_sim`을 만들고(432–436), WorldLink가 WorldMap에 1회 전달한다(26–35, WorldMap 99–101). WorldMap 결과의 지역 소유자 연출은 legacy kind 매핑이다(622–661).
- adapter는 fresh·명시 `p02/restricted-headless/1`, 10Hz 등의 제한을 검증하고 private owner를 만들며 checkpoint와 source definition을 거부한다(20–32,72–79). WorldMap→FleetBattle3D는 이 입력/owner에 연결되지 않았다. 사용자 입력 프로필을 추정하거나 BattleBrief에서 자동 생성하거나 raw sim을 private owner에서 꺼내 호스트에 삽입하는 것은 범위 밖이다.
- P03 실제 채팅 idle/completed 및 bridge 정적 마감 확인. 운영 복원은 공유 쓰기 창, 진입점·지원 프로필·첫 프레임/사건 게시 계약이 선행된다. P05 실제 채팅 idle/completed 및 Windows·headless 각각 19/19 확인. P05 자체 창 버튼 처리기 자동 호출이며 제품 지도/OS 입력 근거로 합산할 수 없다. P07 실제 채팅 idle/completed 및 다른 모델의 문서 한정 PASS 확인. 보급 수치·증원 일정·동틱 전체 처리 순서는 미정이다. P05 이동 가드와 P07 작전 정책·P03 private owner/ledger/복원 코드는 각 소유자가 인수한다. 채팅 상태는 수집 시점 관측이며 쓰기 허락이 아니다.

## 후보 선택과 관측 수준

1. **선택** · 실제 direct PC 진입 경계의 장면 전환 거절 처리. `scripts/world_link.gd:18–24`는 기존 brief/outcome/last_difficulty/last_mode를 바꾼 후 엔진 scene change 결과를 버린다. 유일 production caller `view/world/world_map_screen.gd:588–598`는 먼저 `leaving`에 들어가고 이전에 `sortie`가 잠근 canvas를 해제할 복구 분기가 없다. 엔진이 파일 전환 오류를 반환할 경우의 정적 코드 결함이다. 기존 실행에서 이 오류를 관측했다거나 PC0 장애 원인이라는 근거는 없다.
2. **후속** · 실제 private operation 진입·배치/명령·논리시간/표시/결산 통합. 제품 연결 공백 자체는 확인됐다. 새 public entry 및 실제 지원 프로필, P05 지도와 P07 정책, P03 owner·첫 프레임·공유 쓰기 창이 선행된다. P02 여덟째 후보는 legacy native 공통 생성이며 해당 공백 전체를 닫지 않는다.
3. **후속** · WorldLink 복귀 오류 처리 역시 반환값 무시가 코드에 보인다. 현재 정상 전환에 영향을 주지 않는 앞방향만 한 세션으로 인수한다. 복귀 수정은 FleetBattle3D/P03 공유 경계를 포함하므로 별도 소유 조율을 요구한다.

## 변경 후보 계약과 합격 행

- 허용 제품 hunk는 WorldLink.go_battle와 WorldMap.sortie/_finish_sortie의 direct 실패 복구 및 가까운 상태 필드다. 실제 쓰기 전 staged diff·원본 SHA·P03/P05/P07 최근 작업 상태와 hunk 재대조. 모순이나 대상 변경이 나오면 원본 수정 전 멈추고 재동결한다. FleetBattle3D·private state·adapter·auto resolver 및 기존 P02 owner/test/doc 변경은 보존한다.
- WorldLink는 명시적인 `BattleBrief`를 받아 engine Error를 반환한다. 현재 성공 순서대로 네 필드를 먼저 게시해 전환에 수반되는 lifecycle 조회에 기존 값 가시성을 유지한다. 전환 호출이 즉시 거부되면 이전 네 값/객체 참조를 정확히 복구한다. 정상 OK에서만 기존 장면 전환을 완료로 취급한다. 장면 수락 후 다음 장면의 _ready/전투 준비 실패는 기존 별도 경계다.
- 지도는 입력 lock과 출격 배너를 해제하고 현재 화면 안에서 오류를 표시한다. 기준 정책은 browse 출격 카드에서 시작했으면 재시도 가능한 browse 카드, 기존 result의 같은/새 출격에서 시작했으면 동일 결과 객체·결산 카드와 재시도 버튼으로 돌아가는 것이다. 이를 위해 출격 직전의 논리 화면 종류와 기존 local brief를 보존하는 최소 상태만 고려한다. 결과 반환 시 기존 결산을 다시 소비하거나 소리·타이머·외부 효과를 다시 게시하지 않는다. 카메라 연출의 프레임별 원상 복구는 이 계약 범위 밖이며 기존 좌표/표현을 새로 정의하지 않는다. 실패는 자동 해결로 폴백하지 않는다. WorldLink 부재 시 기존 분기와 명시 auto 선택은 기존 동작을 따른다.
- A. 실제 엔진 즉시 거부 + browse 출발. 이전 WorldLink 네 필드(비어 있지 않은 outcome, 이전 brief·설정 포함), 기존 current scene identity, 입력 잠금 해제, 오류 표시, 재시도 버튼, 자동 작업 미생성 검증.
- B. 동일 오류 + result 출발. 동일 결산 객체와 seed·요약·다시 출격 버튼, 결과를 재소비하지 않음, 기존 local brief/WorldLink 필드 복구, 추가 skip/타이머가 전환이나 worker를 만들지 않음을 확인. 같은 seed와 새 seed 진입은 기존 결산 UI가 사용하는 실제 버튼 연결로 추적한다.
- C. 그 뒤 정상 direct 경로 1회. skip 중복은 한 진입, brief의 명시 seed/설정과 수신 battle 일치, 기존 WorldLink 왕복에서 결산 전달 1회를 확인. 기존 왕복은 `sim._end` 강제 경계이므로 자연 종료 증거가 아니다.
- D. 기존 auto 정상·취소 및 legacy title/재시작 회귀는 해당 소스·정본 결과를 재사용한다. 변경 hunk가 실제로 영향 주는 기존 suite 부분만 사전 고정해 실행한다. 별도 테스트 파일·launcher·GUI probe를 새로 만들지 않는다.

## 검증 계약 초안

- 5-a 설계는 기존 tests/world_link.gd의 왕복 경로에 집중한다. 실제 scene 거부는 격리된 기존 suite 입력에서 재현할 수 있는지 심사한다. 캐시 없는 missing BATTLE_SCENE 또는 실패가 직접 관측되는 다른 최소 fixture를 사용하며, 엔진을 우회해 오류값만 돌려주는 stub을 최종 오라클로 쓰지 않는다. 원본 리소스 이름/파일/캐시에는 손대지 않는다. 격리 fixture에서 동일 프로세스 재시도가 불가능하면 실패 후 재호출 UI와 정상 별도 프로세스의 성공을 별개로 기록하고 동일 프로세스 성공으로 주장하지 않는다. 기존 suite에 결정적이고 간결한 반례를 붙이는 경우에만 추가하며 정확한 fixture·단언 수·실행 명령·개별 timeout·expected diagnostics를 독립 계획심사에서 먼저 확정한다.
- 비교 기준은 코드와 기존 WorldLink의 prechange 정상/결산 판정, 각각의 fixture에서 source와 독립해 정의한 이전/이후 공개 관측 값이다. 실패 oracle은 Error·장면 identity·이전 참조/설정 값·UI/worker 상태를 모두 확인한다. 예상 엔진 오류는 케이스에 귀속해 원문과 일치시킨다. 그 외 SCRIPT ERROR는 PASS/exit 0과 무관하게 무효. clean-user WorldLink의 기존 서막 실패와 returning-user 통과, ObjectDB/리소스 종료 진단 및 기존 전체 diff-check 편차는 현재 실행에서 각각 관찰·분리하며 새 결함을 가리지 않는다.
- PC0 2/2 소진, 동일 실행·상한 리셋 금지. 별도 8th K6은 0회 사용 상태 유지. 새 코드 조각의 5-a 변경 재시도는 계획 승인 후 최대 6회, 매 회 actual exit/타임아웃/중단 및 원문 보존. 구체 실행 전 입력 closure(엔진·클래스맵·상태·fixture), 분모 및 격리 경계를 동결하고 독립 5-b는 전체 diff와 원문·기준선을 대조한다. 사용량 한도 신호 발생 시 즉시 중단하고 조율자에게 보고한다.
- 이번 조각은 기존 제품 경계의 코드 및 viewport/headless 회귀 한정이다. OS 입력·창 활성화·제품 실행 보조 도구는 범위에 없다. 이전 run02의 HWND/foreground 불일치 및 첫 조회/캡처 정체 원인은 미상이다. 향후 GUI 인수에는 실제 인터페이스에서 지원하는 PID/창 귀속·전경·취소·지속 근거와 실제 입력/자연종료가 필요하다. 새로운 GUI 실행으로 이 기록을 덮지 않는다.

## 근거 위치

- 상위 순서: docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md §0 및 P02-PROGRESS-CHECKLIST.md.
- PC0: tmp/p02-first-pc-20261109/REVIEW-PC0-RUN-02-INDEPENDENT.md, TOOLING-REVIEW-PC0-READONLY.md.
- P03: tmp/p03-product-restore-bridge-20261109/PLAN.md 및 REVIEW-STATIC-CLOSEOUT-6SOL.md, tmp/p02-ninth-20261108/P02-P03-OWNERSHIP-20261109.md.
- P05/P07: docs/battle-core/pc-campaign-design/P05-PC-NATIVE-ACCESS-RESULT-20261109.md, P07-PC-FIRST-OPERATION-PLAN-20261109.md 및 P07-PC-FIRST-OPERATION-EVIDENCE-20261109.md.
- 같은 디렉터리 baseline.json, chat-status.json 및 p05-chat-status.json. 원본 파일 내용 해시의 순차 수집이며 파일시스템 전체의 원자적 스냅샷은 아니다. 제품 변경 전 대상 경로 재확인이 필요하다.
