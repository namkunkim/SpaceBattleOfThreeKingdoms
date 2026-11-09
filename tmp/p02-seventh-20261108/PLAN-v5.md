# P02 일곱째 조각 계획 v5 — 기존 K 상한 및 실제 WorldMap 작업 경계

PLAN-v4.md 부속 개정이다. 아래 기준으로 v4의 재동결 시도 상한과 WorldMap 증거 항목을 대체한다. v1~v4 및 실행 기록은 보존한다. 독립 계획 재심 전 실행·제품 수정 금지.

## 기존 전체 K=6

재동결로 시도 번호를 초기화하지 않는다. 한 시도는 동일 동결 입력·제품 쌍을 대상으로 사전에 확정한 사례 묶음을 검사하는 단위다. 시도 안의 headless suite, 독립 사용자 디렉터리, GUI 입력 모드, 프로세스와 관측 행은 각각 기록하되 K를 사례마다 추가하지 않는다.

| 시도 | 원문 | 관측 |
| --- | --- | --- |
| K1 | before-attempt-01/processes.json, after-attempt-01/processes.json | 6+6 headless 프로세스. common·atomic·WorldLink 실패/타임아웃 원문 포함 |
| K2 | before-attempt-02/processes.json, after-attempt-02/processes.json, GUI-RESUME-EVIDENCE.md 및 GUI별 process.json | 2+6 headless 프로세스. 기존 GUI와 roster 확인은 같은 동결 제품 쌍의 별도 프로세스 이력으로 집계한다. 모든 GUI 성공/타임아웃/입력 교차를 목록에 남긴다. strict startup 7/8 불일치를 유지한다 |
| K3 | fixed-trace-attempt-03/preflight.json | 공통 owner SHA 변동으로 실행 전 보류, 시작 프로세스 0. 보수적으로 K 한 회를 소비한다 |

K4~K6 총 3회가 남았다. K4는 v4의 새 동결 쌍 및 전체 비교, 현재 routed GUI와 아래 WorldMap 제품 사례를 실행 전 한 묶음으로 동결한다. 각 사례와 프로세스의 결과 및 실행 시점 차이를 분리 기록한다. K5와 K6은 앞 시도에서 실패한 조각의 제한 재시도에만 쓴다. 구현 5-b 반려는 스펙 단계로 돌아가며 K를 재설정하지 않는다. 제품 입력 또는 소유 파일 변동 시 중단/보류한 시도도 기록한다. 사용량 제한 첫 발생 시 즉시 보고·중단하고 반복하지 않는다.

## WorldLink suite가 증명하는 범위와 보강

world-probe.gd는 tests/world_link.gd를 상속한다. 테스트 _determinism은 legacy AutoResolver.new/start, poll 완료, 같은 Brief의 blocking 결과 대조, 별도 resolver 취소 및 poll false를 확인한다. scripts/world/auto_resolver.gd의 poll/cancel은 각각 wait_to_finish를 수행하므로 실제 resolver 경계의 성공/취소 join을 뒷받침한다. 다만 WorldLink _round_trip은 mode=direct, FleetBattle3D 결과에서 WorldMap 복귀만 실행한다. 따라서 legacy resolver의 단위 경로와 WorldMap의 실제 자동 출격·진행·결산 경로는 서로 다른 증거다.

동결 쌍 양쪽의 returning 격리 환경에서 실제 WorldMap 씬의 자동 해결 모드를 선택한 뒤 출격 및 연출 넘김 경로를 제품 컨트롤로 작동시킨다. 하나는 완료를, 별도 하나는 resolve 상태의 “중단하고 돌아가기”를 검사한다. 고정 Brief seed/난이도·mode를 동결해 같은 입력으로 비교한다. 제품 WorldMap의 _finish_sortie→_start_resolve, resolver 및 스레드 생성 확인, _process→poll→_show_result까지 정상 경로를 타게 한다. 완료는 같은 resolver의 _thread가 null, 동일 고정 Brief의 검증된 legacy outcome 및 fingerprint, 실제 결과 화면/결산 1회와 반복 poll 중복 없음으로 관측한다. 취소는 실제 stop 컨트롤→_cancel_resolve, 같은 resolver _thread null과 poll false, 제품 browse·카드 복구와 새 결과/결산 부재를 확인한다. 직접 callback 호출이나 AutoResolver 객체만 만든 검사로 WorldMap 제품 인수를 대신하지 않는다. 이 legacy 경계 회귀에는 씬 트리의 실제 제품 버튼에 전달한 자동 입력을 쓸 수 있으며, v4 routed 실제 OS 마우스·키보드와 네이티브 렌더 근거는 별도로 요구한다. 기존 검증만으로 이 보강 행을 통과 처리하지 않는다.

PLAN-v4의 owner diff, 입력 분모, 공유 변경 보존, 역사적 GUI 한계는 유지한다. 현재 checkout 인수는 재검사와 독립 5-b 전까지 보류. 전체 P02 NOT_READY, 외부 save schema UNCLASSIFIED.
