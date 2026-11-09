# P02 일곱째 조각 계획 v4 — 공통 입력 변경 후 현재 상태 재검사

v1~v3, 이전 동결 프로젝트와 실행 원문을 보존한다. 현재 checkout 판정은 독립 계획 심사 및 새 증거 전까지 보류한다. 전체 P02 NOT_READY, 외부 save schema UNCLASSIFIED.

## 관측과 영향

공통 core/battle/operation_private_state.gd가 이전 project-after-02의 C555099934BDD0A80F4F4D89100E435E621DB6F2F0FE5B98C2BE9B2D63619A6E에서 현재 AC59A7547469C705D33854742E9503B08422770B01956A47861B45735AB8C1C6으로 달라졌다. 바이트 diff는 _context_same Dictionary 분기에 typed key/value builtin/class/script 비교를 추가한다. 직접 호출은 restore_completed의 context 검증이며 정상 legacy BattleSim, 현 준비 실패 UI 및 기존 WorldMap legacy start/poll/cancel은 이 메서드를 직접 사용하지 않는다. 그러나 WorldMap이 참조하는 AutoResolver는 OperationAdapter를 preload하고 OperationPrivateState를 타입으로 참조한다. 따라서 실제 천하로 복귀하는 과정에 파싱·로딩 의존성이 있다. 메서드 단위 직접 호출 부재만으로 현재 제품 검증에서 제외할 수 없다. 공통 코드의 변경 주체와 소유권은 추정하지 않으며 복원·편집하지 않는다. 공통 owner restore 변경 자체의 기능 인수는 별도다.

live-v4-workspace.json은 최초 baseline과 같은 제외 규칙으로 branch/HEAD/index/stage와 tracked/nonignored untracked 파일 바이트를 기록한다. live-v4-inputs.json은 기존 runner 입력 전체 및 새 탐침의 두 연속 관측, 역사적 사후 공통 입력과의 delta, wrapper와 실제 EXE를 담는다. class cache, UID cache, scene groups cache, imported 파일과 suite·fixture를 포함한다. Windows 경로 길이 진단은 본 증거 트리 제외 범위와 대조하고 외부 경로의 누락이면 동결을 보류한다. 반복 일치는 관측 시점 사이의 쓰기 부재나 변경 주체의 증거가 아니다. 실행 준비·복제 직전/직후·실행 후에 다시 검사하고 실제 입력 또는 소유 파일에 변동이 있으면 실행·판정을 보류한다. 공유 checkout에는 읽기 동작만 수행한다.

## 새 동결 쌍과 최소 실행

1. 새 별도 증거/프로젝트 디렉터리에 같은 현 입력 manifest로 before와 after를 구성한다. before의 FleetBattle3D.gd 한 파일만 기존 검증된 before 원문 SHA로 복제하고, after는 현 파일을 복제한다. live 파일이나 기존 스냅숏은 변경하지 않는다. before/after manifest 집합과 경로별 SHA의 차이가 오직 FleetBattle3D.gd임을 검사한다. 새 fixture/runner는 양쪽 동일 해시로 동결하고 격리 user data 및 동일한 엔진·캐시·실행 인자를 사용한다. 출발 시점의 FleetBattle3D.gd가 역사적 최종 after와 다르면 이전 변경 검토부터 다시 한다.
2. 두 스냅숏에서 프로젝트 파싱/실행과 현 common 8행/27단언, v3 동일 고정 시드 보강 trace(동일 fallback 입력, 실제 init_game, 양쪽 단일 start 및 strict 비교)를 실행한다. 기존 7/8 startup strict 이력 및 새 실행의 randomize 관측을 분리한다. wall_time과 mono_ms 외 정규화 금지. control/pos 변조 거절을 다시 확인한다. 사후 atomic 10행/546단언 및 최초 명시 실패에서 두 roster 오류, 상태·clock·queue·trace·정상 재시도 경계를 재확인한다. 사전/사후 BattleFlow, Organization UI와 clean/returning WorldLink를 검사한다. clean은 기존 단일 서막 실패와 exit 1을 별도로 판정하고, 새 parser/scene/resource 오류와 종료 진단 차이는 숨기지 않는다.
3. 현 사후 실제 FleetBattle3D 최초 실패→제품 WorldLink.back_to_world(null)→실제 WorldMap 활성화를 다시 검증한다. 실제 WorldMap의 legacy AutoResolver를 사용하는 제품 경로가 새 입력에서 parse 및 시작/종료·join 가능함은 returning WorldLink suite 또는 해당 실제 경로 관측으로 대조한다. 종료·복귀는 기존 결과 없음, brief null, last 선택값과 user 파일 보존을 확인한다. 이 재검사는 제품 operation 또는 restore_completed의 인수가 아니다.
4. 이전 네이티브 캡처, 03–08 실제 GUI와 네 최초 탈출(두 모드 × 마우스/키보드)은 C555… 입력의 역사적 증거다. after 제품 UI 소스·테마·인셋·씬·엔진·캐시·관련 리소스 해시가 동일하면 레이아웃 및 제품 버튼 관측의 역사적 의미는 보존된다. 현재 입력의 천하 복귀 의존성은 별도이므로 현 after에서 실제 routed 마우스 및 키보드 복귀를 각각 새 프로세스로 재검사한다. 현 renderer에서 최초 오류와 라이브 경고/제거를 캡처해 현재 UI 차이가 없는지 대조한다. 나머지 실제 GUI 기록은 UI·입력 의존 입력 무변경 및 새 headless 제품 회귀를 근거로 5-b가 역사적 증거로만 인용할 수 있다. 다른 UI·입력 관련 delta가 있거나 입력/렌더 결과가 다르면 관련 실제 행을 재실행하거나 현 상태 판정을 보류한다. CUA는 사용자가 해당 창 입력을 승인한 경우에만 사용하고, 승인 범위가 없거나 사용자 입력 교차로 인과를 확인할 수 없으면 독립 검증 보류로 기록한다. 클릭 대상/포커스와 OS 입력 및 화면·복귀 결과를 연결하며 callback 직접 호출로 대체하지 않는다.
5. 이 재동결 조각의 5-a는 최대 6회이며 이전 v1~v3 시도와 프로세스 이력도 별도 표기한다. manifest 불일치·드리프트·입력 교차·실행 전 보류 및 프로세스 수를 각각 보고한다. 사용량 제한 최초 발생 시 재시도 없이 즉시 중단·보고한다. 계획 재심, 구현자와 다른 비Astra 독립 5-b, 독립 마감 순으로 검증하고, session/turn 실제 모델은 권위 원문에서 확인한다. 모델이 unknown이면 차이를 주장하지 않는다. 원본 checkout/브랜치/worktree/commit/push/HTML/browser 금지.

## 계획 작성 시점의 동결 결과

live-v4-inputs.json은 4,248개 경로를 두 번 관측해 변화 0건을 기록했다. 기존 after-attempt-02와 공유하는 경로 중 관측 차이는 operation_private_state.gd 하나다. live-v4-workspace.json의 branch/HEAD/index/stage 전후는 동일했고 2,453 tracked와 20,951 nonignored untracked의 읽기 오류/파일 내 drift는 0건이었다. 다만 output/ship-concepts PNG 13개가 전체 목록 순회 중 변했다. 전역 분모는 변동 상태로 기록하며 원자적 동결로 분류하지 않는다. 13개는 위 실행 입력 목록과 겹치지 않는다. 경로 길이 경고는 이번 증거 폴더 안의 사용자 데이터 shader_cache에서만 관측했다. 다음 검증 담당자는 비교 실행 직전에 이 비중첩 및 입력 바이트를 재확인한다. 복사된 실제 WorldMap 활성화와 AutoResolver 로딩을 실행 산출물로 남겨 정적 참조 조사에 한정하지 않는다.
