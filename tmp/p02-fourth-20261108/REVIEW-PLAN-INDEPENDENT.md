# P02 네 번째 조각 독립 계획 심사

2026-11-08. **한정 수용.** 대상 PLAN SHA-256 `b57713b931567f8be7e6bc9e1c958fed74de3bd3ddb28b4d46c5718ca20725a8`. 생산 owner의 표시용 사건 회수 선행조건 계획만 심사했으며 구현·실행·제품 연결 수용이 아니다.

- 실제 FleetBattle3D `_pump`는 투영과 도착 처리 뒤 `BattleSim.drain_events_for(0)`의 결과를 trace와 화면에 사용한다. native 구현은 단일 전체 큐를 먼저 비우고 현재 contacts로 걸러 side 0 contact 조건과 미탐지 salvo/other 가림을 적용한다. 이 경계는 향후 호스트에 필요하지만 자체로 제품 호스트가 아니다. private owner의 raw drain/observe가 남으므로 권한 보안 경계로 해석해서도 안 된다.
- 공통 adapter는 runtime-ready 제한 입력의 정규화와 owner 생성 담당이다. 제한 owner는 제품 적벽 모듈·증원, place/face/posture/delegate, trace/debug 및 기존 live sim 접근을 충족하지 않는다. 계획이 이 제한과 제품 후보 검증 후 게시, clock/controls, 선택·카메라·FX·trace, 실패 시 기존 세션 보존을 미완료로 둔 것은 타당하다. 기존 WorldMap worker는 BattleOutcome 제품 연결이 아니며 CLI replay도 제품 replay가 아니다.
- exact side 검증과 guard 우선, 실패 전 큐 보존, 깊은 사본, raw와 filtered 혼용 시 공유 큐 소거, 단일 스레드 직렬 사용을 native 구현과 대조했다. 탐지 여부와 두 side, 필터 시점·숨김·마스킹의 관측 반례, 독립 직접 native oracle과 부작용 비교가 필요하다. E05/E06 분기가 자연발생하지 않으면 합성 사건과 자연발생 증거를 구분하고 계획의 재심사 조건을 지켜야 한다. 성공 사건이 없는 빈 배열 대조를 통과 근거로 세지 않는다.
- 실행 전 fixture·직접 native 입력과 oracle을 동결하고, 각각 별도 native/owner에서 같은 입력과 controls를 적용해 타입·순서·값을 비교할 것. 반환 사본 검사는 실제 owner의 drain 이전 큐/중첩 참조를 보관해 반환 객체를 변형한 뒤 비교하고, 별도 native 객체와의 비교만으로 alias 부재를 주장하지 말 것. typed array 보존, invalid/busy의 큐와 전체 상태 보존 및 다음 정상 drain, 양방향 side와 raw 혼용, drain 전후 event 소거 외 clock/controls/log/projection 불변을 확인할 것.
- 14 논리 행과 실제 17 프로세스는 별도 분모다. 기존 진단과 실패·재시도 원문을 보존하고 실제 baseline drift와 병행 P03 차이를 실행 직전/후 분리할 것. 기록된 8656 경로는 계획 당시 명세이며 본 심사에서 전수 재해시한 사실이 아니다. 새 소유 hunk와 기존 파일 역제거 검증, class cache 및 fixture 동결과 추후 독립 구현 5-b가 필요하다. 엔진 예외·동시 호출·제품 화면은 이 계획의 증거 밖이다.

전체 P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED. 이 판정은 커밋·병합·배포 승인이 아니다.
