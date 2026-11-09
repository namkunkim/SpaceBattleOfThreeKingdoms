# K6 준비 자료와 판정 경계

상태는 **독립 재심용, 실행 금지**다. K1~K5를 모두 산입한다. 이후 Godot 제품 프로세스가 처음 시작되면 K6을 소진한다. Godot이나 editor import, OS 입력, 원본 적용은 수행하지 않았다.

행별 프로세스 및 정확 인자는 MANIFEST-REVIEW-ONLY.json에 있다. 여러 행을 공유하는 프로세스는 한 번만 센다. stdout/stderr와 원본 파일은 모두 보존하고, 아래 비교 제외만 적용한다. 동일 프로세스 내 단언 중복·누락·false, parse/runtime 오류, 시간 초과, 예상 결과 미생성 또는 SHA 차이는 실패다. suite가 출력하지 않는 단언은 출력을 추가할 별도 검토 사항이다.

| 행 | 기대 및 비교 |
|---|---|
| 1~4 | 입문/표준/상급/극한. 각 두 제품 프로세스 및 프로세스 내 독립 native. effective·reinf-alias·auto-effective, 모드별 0/1/10/100 tick, 독립 viewer/0·1·10·100, reinf-before/first가 true. B/A typed 원문 비교. natural/debug 경로 일치 및 후발 controls 보존. 제품 raw와 viewer는 별도 인스턴스. |
| 5 | confirmed-org-valid, published-confirmed-org, pre-action-native, place-state, same-tick-command, trace-command-record, next-tick-native. 표준 데이터 자동 생성 편성을 확정 편성 fixture로 사용. 시작 위치에서 배치 +[10,5], 이동 +[40,0]. source fleet·확정 편성·명령 및 typed state/투영/선택·카메라 B/A 대조. Trace는 wall_time, mono_ms 및 파일 이름만 비교 제외. 현재 native viewer와 제품 trace의 사건을 독립 typed로 짝지어 판정하는 자동 비교는 미구현이다. |
| 6 | POC p=original PocSetup.profile, seed -27182818, direct; poc/0,1,10,100. 기존 prepared lane은 실제 init_game 게시가 아니라 제품 준비만 관측하므로 게시 보완이 필요하다. |
| 7 | 표준 invalid org {"fleets":3}; invalid-org-auto-fallback. 자동 편성 native fingerprint, 오류/메시지 및 load fallback 별도 플래그 확인. |
| 8 | density/cross-counter/synthetic 각각 prepared-seed, typed-effective, alias-reinf-combat, initial. synthetic element-alias, after-mutation-name-and-id, after-mutation-state-events. 실제 callback과 사후 alias 주입을 구분한다. |
| 9 | direct/auto × -1/4294967296 shape/state/calls, reject invalid/empty exact 사전 및 [1,0,0,0]. 현재 계측 lane 포함, 무계측 A direct 계약 비교는 보완 대상이다. |
| 10 | active-exact-rejection/identity/snapshot/error-visibility/next-tick/restart, 계측에서 normal/rejection/recovery-counts. 기존 시뮬레이션 객체/시간/RNG/명령·사건 큐/trace/선택/route 보존. |
| 11 | legacy-invalid-brief. 오류 원문, started false, thread null, outcome null, 동일 brief. |
| 12 | initial-rejected/returned-without-result. 고유 fixture가 기존 profile_patch에 비배열 foe만 주입한다. 실제 WorldLink 전환과 viewport 오류 버튼, 결과 0. |
| 13 | 10행 active 상태/대조를 새 오류에서 확인하고 active-mode-only를 추가. 최초 오류는 12행과 다른 프로세스에서 initial-counts [1,0,0,0] 및 route. 정상 대조는 [1,1,1,0]. 기존 표시를 위한 오류 UI만 변경 허용. |
| 14 | 동일 WorldMap 출격 버튼→sortie 상태→seed만 -27182818 fixture 교체→skip 버튼. 교체 전후 typed Brief 전체 및 동일 비교 저장. UI의 음수 입력 지원을 주장하지 않는다. I의 첫 유효 시도에서 adapter mode만 invalid, injected-reject/valid-profile; 오류 칩, browse, 결과 없음. 주입 해제 뒤 동일 Brief 및 retry-start-counts. B/A/I terminal/started/joined/one-visible-outcome/poll-idempotent. progress는 공개 clock, 실시간 비교 제외. terminal typed tick/clock/fingerprint/outcome/게시 횟수 정확 일치. |
| 15 | 독립 외부 마우스 출격/배치 기록과 mouse-placement-observed, foreground·렌더·focus. 장면/버튼 합성 없음. GUI 소유 확인 게이트에 의존. |
| 16 | 실제 OS 키 2로 그룹 선택 및 focus를 입증하고 실제 OS 마우스 재시작/천하 복귀를 개별 action으로 관측하는 제안. pause 메뉴 재시작·복귀에 focus_mode NONE이고 제품 키 라우트가 없다. 키보드만으로 재시작/복귀 성공을 집계할 수 없다. 계약 개정과 독립 수용 전 실행 불가. |
| 17 | viewport WorldMap marker/mode/standard/sortie/skip, resolver-start/result-join/poll-idempotent 및 버튼당 pressed-once. 두 원문 종료 결과 일치. |
| 18 | 동일 start, viewport 중단 버튼 및 cancel-join, browse/outcome 0. |
| 19 | 명시된 7 suite 전후 각각 exit 0, 모든 출력 단언 및 결과 원문. |
| 20 | battle_flow 및 autoresolve 전후 exit 0, 모든 출력 단언 및 결과 원문. |
| 21 | returning exit 0, clean은 양쪽의 기존 “천하에서 오면 브리핑부터 (prologue)” 단일 FAIL 및 나머지 실패 0일 때만 기존 편차로 분리. |

준비 단계의 원자성은 게시 전에 한한다. 거절 후 오류 UI 표시를 제외한 active 데이터와 다음 명령/틱을 독립 control과 비교한다. 이후 게시 중 예외의 롤백은 이 계약 범위 밖이다.

## GUI 관찰 게이트

window_identity.py는 foreground HWND·소유 PID/TID·유일 제목·client rect·DPI·선택 좌표의 hit-test 및 소유 exe 경로/SHA/생성 시간을 읽는다. 화면 좌표는 같은 DPI 좌표 공간임을 별도 검증한다. 기존 비대상 창 관측만 존재하며 Godot 대상 대응의 증거는 없다.

각 실행용 고유 nonce, 실제 Godot PID/native HWND, OS 조회, 최신 Sky list_windows의 일치 제목 단일 결과, Sky screenshot의 대상 장면, hit-test를 action마다 묶는다. Sky ID는 opaque 값이다. 입력 전부터 전환까지 foreground WinEvent의 heartbeat·gap/overflow, 제한된 대상 범위의 OS 입력 이벤트, Sky action 시각, Godot 수신 이벤트와 장면 전환을 같은 기준으로 기록해야 한다. 전경 변화, 타 입력, 타깃/정확도/출처 불명, 로깅 권한 부재는 중단 및 미집계다. 수동 입력 또는 별도 입력 엔진을 동원하지 않는다. injected flag 하나로 독점 귀속을 판단할 수 없다.

이 패키지에는 연속 WinEvent와 source provenance를 독립 확인한 실행 원문이나 승인된 입력 도구의 action ID 상관 수단이 없다. GUI nonce도 검토 후 동결해야 한다. 창 스냅샷의 전후 일치만으로 실행을 허용할 수 없다.

## 격리와 보존

각 프로세스는 fresh copy 및 독립 user data를 사용한다. 실행 입력은 기존 4,203경로 per-lane 동결에 이어 추가 probe/fixture와 승인 차이 SHA를 대조한다. 원본, 기존 후보, Git, P03에 대한 쓰기는 금지한다. P03 차이는 실행 입력과 분리해 관측 시점 기준으로 남긴다. 현재 manifest는 읽기 전용 생성기로 만들며 제품 프로세스를 실행할 runner 승인과 완전한 단언 인덱스가 남아 있다.
