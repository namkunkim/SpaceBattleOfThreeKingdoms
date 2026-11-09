# P02 선행 A/B 정적 결과

상태는 검토 대기다. 이 산출물에서 실행한 제품 suite와 비제품 엔진 시험은 각각 0회다. K6 사용량은 0회다. 실행 모델은 nodeRepl 요청의 `x-codex-turn-metadata.model`에서 직접 확인한 `gpt-6.1-sol`이다.

## A. 출처와 판정 단위

`source-evidence.json`은 7개 source, HEAD 및 ZIP 바이트, 함수별 분기·호출·단언 원문 위치, 경로별 로컬 SHA와 V5 행 19의 14개 before/after argv·env·expected exit 원문을 결합한다. 독립 심사에 제출하는 정적 자료다. 스크립트 출력의 assertion count는 oracle이 아니다.

- Headless는 두 배포 ZIP과 HEAD 및 worktree가 byte-identical이다.
- Worker의 ZIP은 worktree와 byte-identical이다. HEAD를 LF로 비교하면 끝 두 빈 줄 차이다. Replay는 ZIP의 69 CRLF, viewer는 혼합 EOL 중 4 CRLF를 LF로 정규화하면 HEAD와 일치한다. 변환 전 SHA를 유지한다.
- I01b private/service는 P2C 및 active replacement ZIP의 해당 member와 현재 원문이 일치하고, active는 active ZIP과 일치한다. 세 파일은 HEAD 밖에 있다. Service의 독립 P2B 실행본과 후속 전달본의 동일성은 별도 추적 항목이다.
- 정적 자료는 P03 active file의 동일 before/after 입력 선택을 대신하지 않는다. HEAD 0be09755b70378286105972f35ac5b7031715664, staged 없음, P03 +9 및 worker +2로 시작했다. inventory 채취 직전·직후 기록한 HEAD, index entries, tracked diff, 상태 및 감시 SHA는 일치했다. 샘플 사이 변경의 부재는 입증하지 않는다.

| Suite | 진입 및 도달 분모 | 독립 oracle과 실패 경로 |
|---|---|---|
| headless | _initialize → _run → policy_microcases(9), timeout_case(2), normal(2 seeds × 2 profiles × 2 policies), negatives(32 rejection IDs). 루프 normal은 각 tick마다 기본 6회, tick 1의 6회와 tick 5/10/15의 각 2회, 정책 명령마다 1회를 더한다. 종료 tick과 정책 큐 길이는 fixture별로 계산해야 한다. | 원본 BattleSim, typed oracle, 정책 hardcoded 9개, twins. Private._classes 실패 즉시 1. factory 실패 때 해당 경로 후속 단언 건너뜀. close 모듈 존재 여부, pure.ok 분기 별도. |
| worker | _initialize → _run. 초기·거부·취소 단언 14회, 성공 경로 3종 각 14회, services의 사건 종류 3회로 총 59회. `got.ok` false이면 해당 fixture의 마지막 8회 및 services 추가 3회를 건너뜀. | native BattleSim summary/events typed bytes, join 전 상태 불변, 취소 및 결과 복제. `joined`의 frame마다 running에 결과가 없음을 추가 검사하며 printed checks에 포함되지 않는다. 실제 worker join과 running frame 수는 실측 필수. |
| replay | _initialize → _run → 8 성공 케이스 × (check_closed 7 + 초기 controls 1) + 6 부정 케이스 × 5 + oracle 교차검사 7 = 101. factory 실패 때 check_closed의 첫 검사 이후 반환. 성공으로 기대했는데 replay 실패 시 세 상세 비교 생략. 초기 controls용 별도 factory 실패 시 해당 검사 자체 생략. | 고정 oracle.native와 matrix JSON 14개 원문 SHA는 JSON에 있다. oracle 미존재/열기 실패는 스크립트 quit(1) 보장과 별개로 runner failure로 다룬다. 이 suite 자체는 외부 CLI 자식을 생성하지 않는다. 이전 CLI subprocess 증거는 이 분모와 독립이다. |
| viewer | _initialize → test_matrix(2 scenarios × 2 sides), test_contact_and_masks, test_shared_queue, test_errors(4 잘못된 side 값), test_copy_and_state(2 sides). Fixture 없으면 quit(1). `mini(salvo_raw.size(), salvo_mask.size())` 반복 횟수, projection event 배열 및 helper 가드 분기에 의존한다. | native projection 과 이벤트 typed 동치, 숨김/공유큐/반환 복제. 이전 14행·148회는 비교용 실측이다. 고정 길이/이벤트 수 oracle 없이 148을 정적 도달 수로 확정할 수 없다. |
| I01b private | _initialize → _run → 10 seeds × 7 kinds _roundtrip(70) 및 _negative. _suffix의 입력별 횟수, 매 tick drain 여부, 초기 owner 또는 restore 준비 실패 경로를 함수별 JSON에 보존한다. | direct private snapshot oracle·copy 및 branch-specific sim 상태. 이전 11,553회, 45 refusal 사례는 비교용 실측이다. |
| I01b service | _initialize → _run → 10 seeds × 4 cases(_detection 2, _supply 2) + _refusals + _inactive. _restore에서 fleet 수와 contact 수로 반복한다. _suffix 반복과 restore/precondition early return 분리 필요. | selected fields vs unrelated state와 독립 fixture. 이전 2,202회, 33 refusal 사례는 비교용 실측이다. |
| I01b active | _initialize → _run → 10 seeds × 2 kinds _normal(20), _negative. _normal suffix는 PoC 110×4, services 70×4이며 _advance는 tick당 1 또는 2회, retired/bindings는 있는 module 수, fleet identity는 fleet 수에 비례한다. 총 8 refusal names/9 calls의 분모를 코드가 검사한다. null owner와 준비 실패 조기 반환이 있다. | fresh reference와 independent direct checkpoint oracle, instance identity, 이벤트·명령·보급. 이전 20,099회는 비교용 실측이다. |

V5의 성공 exit 기대는 0이다. 종료 지연·엔진 오류·출력 폴더 누락·자식 남음은 quit 값과 별도 결과다. I01b/headless의 `OUT` 폴더와 runtime class cache, project 및 data dependencies는 replay JSON과 다른 종류의 전제다. 원문 정적 수집에서는 디렉터리 생성, import 또는 fixture 보완을 하지 않았다. 행 20의 BattleFlow·AutoResolve와 행 21의 WorldLink clean/returning은 이 분모에 합산하지 않는다. 현재 A 산출물은 함수별 원문과 주요 분기를 제공한다. 나머지 다섯 suite의 분기 가중식을 독립적으로 완결하고 행 20/21 허용 편차를 연결하기 전에는 row 19 oracle 동결을 선언할 수 없다.

## B. 비제품 사전 적합성 제안

아래는 독립 명세 심사용이다. 실제 Godot, CUA/Sky, 입력, hook 설치, Job 생성 시험은 실행 전이다.

### Job 분모 3행

1. 정상 종료. V5의 runner_v5.py가 쓰는 owned_job_v3.py를 hash 고정한다. 최소 전용 프로젝트에서 stdin 차단된 broker 생성 → broker HANDLE을 Job에 할당 → pipe release → 고정 console Godot이 최소 GUI Godot child 생성 → 각 PID/생성시각/image SHA 및 `IsProcessInJob` → GUI와 console 종료 코드 → broker 종료 및 active count 0을 순서대로 기록한다. 관측에 쓰는 process HANDLE은 생성 시점에 열고 PID 재사용을 배제한다.
2. 한도 종료. 같은 경로에서 parent·child 둘 다 살아 있는 것을 확인한 뒤 설정 deadline을 통과시킨다. Job terminate 이후 active count 0에 더해 두 HANDLE이 signalled이고 nonce 창 소멸까지 확인한다. 별개 비소유 sentinel을 전후 동일 HANDLE/creation time으로 확인하며 외부 Godot을 정리 대상에 포함하지 않는다.
3. assign 거부. 실제 nested Job 정책으로 assign이 실패하는 환경에서 Win32 반환값과 GetLastError, pipe write 0, EOF 이후 broker 123 및 child launch 0을 기록한다. 오류 유도 플래그나 다른 API 거부는 이 행에 편입하지 않는다. 환경에서 실제 재현할 수 없으면 미검증이다.

V5의 barrier는 Python broker가 시작한 뒤 newline을 받기까지 target의 생성만 차단한다. Godot 자체를 CREATE_SUSPENDED로 만든 뒤 할당하고 ResumeThread 하는 방식과 다르다. V5를 채택하면 위 세 행은 broker 방식으로만 실행한다. suspended 방식 채택 시 신규 harness의 생성/할당/resume 및 실패 경계를 별도 심사 후 검증한다. V5 runner의 반환 `active_at_join: 0` 리터럴만으로 소유 프로세스를 증명할 수 없어, parent/child 각각의 독립 관측과 종료 후 HANDLE이 필요하다.

### GUI 관측 4행

1. 동일 창 정체성. 임의 nonce, HWND, 창 owner PID, PID 생성시각·image SHA, monitor DPI 및 물리 좌표와 client rect를 독립 관측한다. read-only 검사만으로 창 소유자 정체성은 검증 가능하다. 실제 환경 확인은 미실행이다.
2. 연속 foreground. activation WinEvent 및 독립 polling heartbeat를 동일 monotonic 축에서 대조한다. 장시간 heartbeat gap, 이벤트 큐 오류나 타 HWND 활성화는 판정 불가로 처리한다. polling만으로 샘플 사이 전경 변화의 부재를 입증할 수 없다.
3. 입력 수신. isolated test HWND의 OS input 관측과 Godot callback의 종류·좌표·down/up·순서를 대조한다. 합성 이벤트로 수집기 연결만 시험할 경우 별도 synthetic으로 표시한다. injected flag와 시각·좌표 일치만으로 Sky 요청 귀속은 증명되지 않는다.
4. 귀속 반례. 동일 창에 동일 종류/좌표를 보내는 다른 주체, 동일 제목 다른 PID, 전경 변경과 복귀, 누락된 down/up, elevation/UIPI 차이 및 heartbeat gap을 각각 거부해야 한다. Sky 요청별 독점 제어 또는 검증 가능한 per-request 표식이 현재 근거에서 확인되지 않았다. GUI 인수는 미증명이다. 활성 화면에서 물리 입력이나 global hook 설치는 이번 범위에서 하지 않았다.

실행은 독립 명세 심사 후 사용자 세션과 분리된 최소 Godot project, 엔진 고정 SHA와 신규 증거 경로가 정해진 상태에서만 검토한다. Job 합성 시험은 K6 제품 작업과 분리하며 GUI physical 입력을 대신하지 않는다. K4 175초 실패와 K5 귀속 미확인은 이전 판정 그대로 둔다.
