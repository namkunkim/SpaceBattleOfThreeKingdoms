# P02 K6 재개 선행계획

판정은 준비 단계다. K1~K5 기록과 마지막 K6 한 회를 유지한다. 현재 HEAD 0be09755b70378286105972f35ac5b7031715664에는 일곱 수용 조각이 들어갔고 여덟째 후보는 미적용이다. 다음 유효 조각은 여덟째 후보의 실행 전 근거 확정이다. 제품 replay 진입점과 공동 소비자 인수는 남아 있으나, 지금 replay 호스트를 정하면 미수용 초기화·clock·controls 소유 경계를 전제하게 된다. 신규 제품 코드는 별도 분해가 필요하다.

## 1. 원문 인벤토리

행 19는 tests/p02_headless_adapter.gd, tests/p02_worker_adapter.gd, tests/p02_replay_adapter.gd, tests/p02_viewer_events.gd, tests/i01b_private_state.gd, tests/i01b_service_state.gd, tests/i01b_active_replace.gd다. P02 정본 tracked 파일은 HEAD 원문 blob과 각 독립 5-b 전달 원문을 맞대고, P03/I01b untracked 세 테스트는 실제 이전 수용 패키지와 현재 bytes를 맞댄다. 일치하지 않는 bytes는 두 provenance로 분리한다. 특히 worker 테스트의 작업 트리 변경은 HEAD와 별개다. Godot script와 fixture, 선언/파라미터별 호출경로, runner args·env·expected exit·assertion denominator를 연결한다. 루프·조건·조기 실패·제품 실행기 자식 및 fixture 누락을 별도 행으로 기록한다. stdout 요약과 grep 개수로 분모를 대체하지 않는다. source inventory 자체는 실행으로 집계하지 않는다. BattleFlow·AutoResolve와 WorldLink clean/returning은 행 20/21의 독립 분모와 허용 편차로 유지한다.

HEAD, 현재 index, worktree에 존재하는 P03 active private state와 두 P02 원문 후보를 구분한다. 원본 P03 현재 bytes는 보존용이며 실제 새 검증의 사전 합의된 입력인지 별도로 판정한다. P03이 테스트 대상이면 frozen snapshot을 before/after 양쪽에 같은 내용으로 포함하고 둘 사이 변경 범위는 후보 patch 세 제품 파일로 한정한다. P03을 입력에서 제외하려면 이전 승인 원문과 재현 가능성을 확인하고 P03 현재본 검증 범위를 명시한다. 상대 세션 drift가 발생하면 기록·재동결하고 변경 파일 복원이나 스테이징을 하지 않는다.

## 2. 비제품 사전 적합성

사전 실행 명세 자체를 비Astra 독립 심사에 보낸 뒤, 별도 전용 sandbox에 engine SHA 고정한 최소 Godot 프로젝트만 사용한다. 승인 없이 실제 K6 테스트·제품 경로를 실행하거나 기존 project를 import하지 않는다. 가능한 경우 기존 유효 cache를 SHA 검증해 복제하고 아니면 신선한 격리 import를 baseline/candidate당 명시한다. Job은 실제 console parent와 GUI child를 suspended 생성·할당·resume하고 PID·creation time·image SHA·job membership을 검증한다. 자손을 띄운 채 한도 만료시 자손 전체 종료 및 원본 프로세스 비침범을 검사한다. 기존 Job의 제한으로 assign 실패하는 실환경에서 실제 실패 오류와 resume 미실행을 검사한다. 합성 플래그는 API 실패 근거가 아니다.

GUI 적합성에서는 제목 nonce와 OS 창 소유 PID, PID 생성시각, executable SHA, DPI 및 client rect를 대조한다. Sky의 고유 창 및 foreground 조회의 지속성은 활성화 이벤트 스트림과 polling heartbeat로 각각 확인한다. 입력 전후 HWND와 전경, monotonic timestamp, 종류·client 좌표/키/누름 해제, Win32 low-level hook의 injected flag와 다른 입력의 부재, Godot input callback sequence를 대조한다. injected flag 자체는 송신 주체 근거가 아니다. Sky의 per-request 독점 귀속을 독립적으로 설명하고 모호하거나 heartbeat/event 손실, foreground 이탈, 외부 입력, elevated/UIPI로 관측 누락 시 fail closed. Sky 근거가 충분하지 않으면 GUI 항목 보류다. 이 적합성 검증의 PASS를 제품 실행 결과로 편입하지 않는다.

## 3. 제품 판정 분모

V5의 행 1~18은 native profile/source transform·배치·PoC·alias, 제품 실패 원자성, GUI 입력, WorldMap complete/cancel을 나눈 의미 있는 판정 집합이다. 19~21은 이전 계약 회귀다. 21행은 요구 보존을 위한 기본 분모다. 58개 프로세스와 20,270초는 V5 구현의 시작·타임아웃 최대 합이며 제품 인수 요구 수치 자체는 아니다. 우선 58개를 안전한 상한으로 간주하고, 더 간결한 실행기는 독립적 상태/fixture/seed, join·time-out의 물리적 격리, 각 케이스 exit와 원문 로그가 보존됨을 행별 매핑한 후에만 채택한다. GUI mouse/key와 WorldMap cancel/reclick을 한 세션에 합쳐서 startup·failure 상태를 공유하거나, 이전 일부 성공을 마지막 실행의 누락 케이스에 소급 적용하지 않는다. 별도 일회성 환경 적합성에서 수집한 관측량으로 시간 예산을 산정하고 175초 제품 deadline 및 320초 강제 종료를 독립 재심 없이 변경하지 않는다.

Oracle은 동일 adapter 산출물을 재호출해 비교하는 구조를 배제한다. native는 변경 전 소비자 경로와 independent BattleSim legacy 생성 및 동결 fixture 기준을 병용한다. alias/변환은 source/effective typed 원문, callback의 동작·요소 변경 후 분리·증원, 순서 고정 및 transform 재적용 금지를 별도로 검사한다. FleetBattle3D에서 실패 전후 scene identity, sim/clock/controls/선택/카메라/trace 및 event 로그를 비교하고 initial/active·retry를 분리한다. WorldMap은 실제 버튼으로 작업을 띄우고 main-thread join 이후만 결산·fingerprint 접근을 인정한다. timeout은 실패를 먼저 기록하고 취소·join 및 결과 부재를 확인한다. 독립적으로 완료/취소/재출격을 관측한다. 행별 명령과 입력·source hashes·expected exit·허용 편차·결과 파일·Job ID·분모를 수정 manifest에서 명시한다.

## 게이트

선행계획 심사 → 원문 inventory와 비제품 사전 적합성 명세 독립 심사 → 승인된 선행 검증 → 제품 입력·검증기·manifest 재동결 → 독립 실행 계획 심사 → 단일 K6 → 독립 5-b. 제품 변경 허용 hunk는 core/battle/operation_runtime_adapter.gd, scripts/FleetBattle3D.gd, scripts/world/auto_resolver.gd의 기존 후보와 정확히 대조한다. 테스트 overlay는 격리 lane에서만 쓰고 별도 hash 및 diff를 남긴다. 실패시 evidence를 닫고 원본 트리에는 적용하지 않는다. K6의 부분 실행이나 실패를 다음 시도의 예산으로 바꾸지 않는다. 원본 커밋, push, HTML/browser, P03 작업 및 기존 ZIP 보존 조건을 따른다.
