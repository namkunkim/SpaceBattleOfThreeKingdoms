# P02 여섯째 조각 구현 및 5-a 원문 안내

## 제품 변경

- FleetBattle3D가 실제 legacy 후보 편성, 시드, 경고/대체 결과, 별도 BattleSim 및 표시용 roster를 지역 값으로 준비한다. Bench patch가 profile을 비우거나 roster를 배열이 아닌 값으로 바꾸면 BattleSim 생성 및 roster 변환 전에 명시 결과를 반환하고 엔진에 기록한다.
- 성공 후에만 기존 함대/VM/FX 정리, 새 sim과 편성, 시계, trace, 카메라 및 HUD 초기화가 진행된다. _ready의 최초 거절은 프레임 처리와 입력을 끄고 presentation을 생성하지 않는다.
- command_deck의 시작·재시작·unrouted 타이틀 전환과 org_screen의 자동 출격·복구가 준비 거절에서 즉시 반환한다. 복구 안내는 기존 오류 목록을 복사한 다음, 성공 후 기존 문구 생성 함수에 복사본을 넘긴다. routed 타이틀의 WorldLink 분기는 유지한다. 거절 진단은 호출 반환과 엔진 로그로 관찰했다. 버튼 사용자를 위한 HUD 오류 표시를 검증 범위에 넣지 않았다.
- 세 제품 파일의 함수별 변경과 역치환 바이트 일치는 [product-hunk-proof.json](product-hunk-proof.json)에 있다. 원본 체크아웃과 index를 공유하는 상태로 작업했다.

## 동결 및 실행 이력

정본 Godot 4.7.2.stable.official.ed1daf0bf, 엔진 SHA c8f0a6bc45a19b33541501e57f6f7cd972ab18453743266339d495cbbe846643, 클래스 캐시 SHA 0eb214ebcc65cd2ca7b9d98dc83f61a9c170ca75b1b23acf4c3c58fdfb550ab1. 실제 프로젝트 리소스 경로를 가진 전후 두 사본으로 실행했다. 입력, 프로필, scene, 캐시와 원본 제품 파일은 [frozen-inputs-v2.json](frozen-inputs-v2.json)에 고정했다. 사후 보강 프로브 입력은 [frozen-inputs-v4.json](frozen-inputs-v4.json), 비교 스크립트와 사전 trace 원문은 [proof-files-v4.json](proof-files-v4.json)에 있다. 프로세스별 명령·환경·stdout·stderr·exit·timeout·결과 SHA는 각 실행 디렉터리에 보관했다. Launcher 시간 제한은 240초다.

| 시도 | 실제 실행 | 기록 |
| --- | ---: | --- |
| before-attempt-01 | 5 | 공통 프로브가 타입 캐스트 없는 Script 상수 경로 접근에서 파서 오류. BattleFlow와 편성 통과, clean WorldLink 기존 실패와 returning 성공 재현. |
| before-attempt-02 | 0 | 병행 경로 목록 변동으로 복사 후 실행 전 보류. 제품 및 실행 입력 변경 없음. |
| before-attempt-03 | 5 | 공통 8행 27단언, BattleFlow, 편성, returning 통과. clean WorldLink의 기존 서막 실패를 분리. 제품 편집 전에 [native-oracle.json](native-oracle.json)으로 고정. |
| after-attempt-01 | 6 | 공통 8행 27단언 및 atomic 10행 546단언 통과. 공통 JSON 바이트 전후 일치. 기존 clean 실패 포함 [5-a 비교](after-attempt-01/comparison.json). 복구 trace 전체 대조를 추가로 요청받아 보강. |
| after-attempt-02 | 6 | 편성 캐시 구별 표식과 복구 시 고정 seed 777을 추가한 사후 프로브. 기존 단언을 유지하며 별도 trace 원문 비교 통과. [5-a 비교](after-attempt-02/comparison.json). |

K6에 전 단계 보류 1회를 포함해 5회 이력을 보존했다. 실제 5-a 프로세스 분모는 시도별이며 22회 실행했다. 누수 조사용 verbose 진단 4프로세스는 이 분모와 별도다.

- 공통 비교는 원본 WorldMap 직행, 서막/자동 편성, 배치 시계, 동틱 명령, 안개 필터를 통과하거나 숨긴 사건, 편성 복구와 fallback, 강제 종료를 통한 결산 1회 인계, 실제 적벽 profile의 제한 operation 거절을 포함한다. 시험 프로필 부재와 편성 테스트의 의도적 난이도 오류는 기대한 엔진 진단으로 분리했다.
- atomic은 실패 시점 현재 세션·UI·시계·trace의 동기 스냅샷을 비교했다. 서로 다른 상태의 직접 거절 2건과 deck의 변경 편성 경로에서 가시 및 비가시 대기 사건을 넣고 별도 native sim과 큐의 내용·순서·필터·2차 drain을 대조했다. 거절 10회는 [사후 stderr](after-attempt-02/atomic/stderr)에 있고 마지막 복구는 구 파일 바이트 prefix, 단일 close/start, 새 뷰와 시계, 정상 카메라/UI, 큐 배제를 확인했다.
- [전체 trace 비교](after-attempt-02/atomic/trace-compare.json)는 변경 전 정본 프로브의 실제 trace 원문 SHA를 확인한 뒤 새 start와 이전 close의 모든 행 필드를 비교한다. wall_time과 mono_ms만 제외했다. 파일 경로는 별도 파일 식별에만 쓰며 데이터 필드 제거에 쓰지 않았다. seed 777, 10Hz, 양쪽 행의 seq/tick/sim_ms/kind, close reason과 start의 fleet_state 순서·지휘 상태·좌표를 대조했다. control 또는 pos를 바꾼 사본은 각각 비교에서 거절됐다.
- Organization UI는 변경 전후 각각 1프로세스에서 완료 마커를 관측했다. 실제 도달 단언 분모 88은 67개 호출 지점에 반복 증분 21을 더한 계산이다. 유비군 3개 반복 두 곳, 2개 함대 슬롯 교환, 표준 난이도 출전 전대 16개, 깨진 함대를 제외한 유비군 2개 반복으로 산정했다. BattleFlow는 23개 호출 지점이 완료 마커까지 도달했다.
- WorldLink clean은 비어 있는 설정에서 기존 line 239 서막 기대가 실패하여 exit 1이다. returning은 원본 설정 SHA c8b752aba9f5015889c00c5a45db9fef916af2a1e1be3e68d49b8121b2db721b로 격리해 exit 0을 확인했다.

## 종료 진단 및 공유 checkout

Common의 ObjectDB/resources가 pre03 318/18, after01 322/20, after02 318/18이었다. Organization UI는 507/18, 511/20, 507/18이었다. 별도 verbose 전후 비교에서 common 322/20과 organization 511/20이 **양쪽** 재현되었고, 객체 유형별 계수와 잔여 리소스 경로가 쌍별 일치했다. 공통 BattleSim 계열 18개 리소스 외의 2개는 stars_stripes.ogg 및 그 OggPacketSequence였다. 이는 기존 누수 및 종료 실행별 편차 관측이며 종료 원인 전체를 확정하지 않았다. [진단 전후 비교](leak-verbose-diagnostics/comparison.json).

계획 원본 baseline은 2,453 tracked와 16,912 nonignored untracked였다. 첫 실제 재관측에서 2,453 + 16,942였고, before-attempt-03 실행 전은 2,453 + 16,975였다. 마지막 재관측은 2,453 + 17,024였다. 기준선 대비 118개 차이 중 제품 3개를 제외한 115개는 미귀속이다. 이 중 106개는 tmp/p03-*에 있고 9개는 output/ship-concepts/industrial-v2 PNG였다. 미귀속 경로가 실행 입력과 겹치지 않았다. 실행 입력과 허용 hunk를 제외한 제품 변경을 귀속하지 않았다. 실행별 workspace JSON에 경로/바이트/SHA 차이를 보존했다.

5-b 독립 판정 대기. P02/I01/I01b/A04~A06 NOT_READY, 외부 save schema UNCLASSIFIED. 이번 인수는 지정 bench patch 두 오류와 제품 동기 호출 경계이며 실제 operation 제품 활성화, GUI·Android 및 성능은 별도다.
