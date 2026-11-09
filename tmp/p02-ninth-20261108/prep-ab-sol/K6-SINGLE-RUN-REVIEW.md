# K6 단일 실행 계약 초안

상태는 독립 심사용이다. 제품 검증 실행은 0회다. K1~K5 이력과 K4 175초 실패, K5 GUI 입력 귀속 미증명을 그대로 둔다. 이번 조각의 종료점은 각 행의 입력·oracle·실행 명세를 한 번 검토하고 실행 가능 또는 구체적 미충족으로 판정하는 것이다. 이 초안이 완료되어도 사전 적합성 실측과 최종 실행 manifest의 별도 수용이 필요하다.

## 시작 전 게이트

1. HEAD 0be09755b70378286105972f35ac5b7031715664, index entries SHA 및 staged 상태, 원본 bytes, patch·overlay·fixture·프로젝트 dependency closure·Godot console/GUI EXE SHA, runner 및 Python 환경을 고정한다. Worktree P03 active state의 +9행과 worker suite +2행은 원본 그대로 보호한다. 판정 lane은 HEAD 원문을 baseline으로 삼아 활성 P03 worktree hunk를 제외하는 안이다. 7 suite의 전달 ZIP 원문을 사용하고 worker의 두 빈 줄 및 replay/viewer EOL 차이 SHA를 명시한다. 이는 HEAD 제품 경계 검증이다. 활성 P03 변경과의 결합은 별도 미검증으로 표시한다. 리뷰에서 P03 포함을 결정하면 동일 SHA 사본을 before/after/instrumented에 넣고 역방향 제품 diff가 허용 후보 세 파일에만 맞는지 다시 확인한다.
2. 검증 전·후 index/HEAD/감시 경로 SHA를 채취한다. 다른 작업의 drift가 보이면 복구/스테이징 없이 중단 및 재동결한다. Sample 사이 무변경을 주장하지 않는다. Fresh project/user dir, cwd/env, resolving user://, seed, fixture 경로, 실행 출력 경로, cache copy 해시 및 격리 import 여부를 job별로 고정한다. 제품 import를 포함해 최종 manifest의 최초 제품 프로세스 시작 시 K6이 소진되는 보수적 정의를 적용한다.
3. 제품 없는 최소 Godot 프로젝트의 Job/GUI 관측성은 별도 명세·독립 심사·사전 증거를 요구한다. K6 직전 단계에서 제품 code/fixture로 Q/C/buttons를 실측하는 예비 실행은 없다. 역사 증거로 못 정한 항목은 K6에 동시 독립 관측하거나 미완료다.
4. 21행의 exact commands, job IDs, expected exits, raw stdout/stderr/log·typed output paths, required keys/types/order, oracle sources, timeout 및 ownership 증거를 manifest에 고정한다. Manifest status가 review-only이거나 누락이면 실행기가 fail closed 한다. 58 프로세스와 20,270초는 V5 프로세스 목록의 시간 상한 산술이다. staging/import·원본 검증·정리의 실제 예산을 합산하기 전 총 실행 보장을 할 수 없다. 21행 요구 유지 및 58 이내에서만 구체 명령을 심사한다. 단일 총 deadline, per-job cap, 정리 reserve를 기록한다. 행 17의 175초 제품 한도 및 320초 강제 한도는 유지한다.

## 제품 21행과 계측 계약

| 행 | 고정 case 및 진입점 | 독립 기대와 캡처 |
|---|---|---|
| 1 | 입문 native B/A, direct/auto | legacy effective typed profile, deployment/reinf/controls, raw BattleSim와 제품/public projection 각각 ticks 0/1/10/100, native 사건/순서. |
| 2 | 표준 native B/A, direct/auto | 행 1 계약을 표준 고정 fixture로 분리. mode별 actual publication 및 후발 controls. |
| 3 | 상급 native B/A, direct/auto | 동일 고정 oracle 계층, 상급 전용 seed·profile transform 및 expected reinf. |
| 4 | 극한 native B/A, direct/auto | 동일 고정 oracle 계층, 극한 전용 seed·profile transform 및 expected reinf. |
| 5 | 표준 confirmed org, 실제 배치·같은 틱 move | 출격→조직 게시→배치 +[10,5]→move +[40,0]. 배치 전/후 및 다음 틱 독립 native state, 선택/카메라, 명령/사건 typed trace와 실행 순서. 시간 필드와 경로만 비교 제외. |
| 6 | original PoC, -27182818, direct | 실제 init_game에서 제품 게시를 관측. 독립 PocSetup raw sim과 0/1/10/100, controls와 clock. 준비 DTO만 캡처하면 실패. |
| 7 | invalid org {"fleets":3} | 사용자 경로의 자동 fallback. 기존 native fingerprint, 오류 원문, fallback flag, 게시 횟수. |
| 8 | density / cross-counter / synthetic 분리 | 실제 callback 실행 횟수·순서, source/effective typed bytes, alias 변경 반례, source 보존과 reinf/combat identity; synthetic의 요소 변경 후 분리·증원 및 no re-transform 검증. |
| 9 | direct/auto × -1/4294967296 | 계측·무계측 계약 비교, exact rejection field/path, no owner/no state, factory [1,0,0,0]. |
| 10 | active guard rejection | 기존 scene identity, sim/RNG/clock/controls/selection/camera/trace/route/events/commands 비교, 오류 UI만 허용, 다음 틱 및 실제 재시작 정상. |
| 11 | invalid legacy Brief | 실제 start false, thread/outcome 없음, 동일 brief 및 정확 오류 원문. |
| 12 | initial invalid foe shape | 실제 WorldLink 전환, 오류 버튼으로 돌아옴, 결과 없음, active lane과 독립 fixture. |
| 13 | initial / active mode-only rejection | actual error boundary와 retry. 정상 [1,1,1,0] 및 거절 [1,0,0,0], 10/12의 상태 불변·route 증거를 case별로 재수집. |
| 14 | 출격·skip 버튼 → 실패 주입 → 동일 Brief retry | 원래 Brief와 seed 교체 후 typed values, injected mode만 invalid, browse/no outcome, 명령·시계/결과 관측은 join 이후. 정상/거절 lane 독립 및 seed 교체로 음수 UI 지원을 추정하지 않음. |
| 15 | 실제 OS mouse 출격·배치 | 각 action마다 nonce/PID/HWND/rect/DPI·hit-test·연속 foreground·독립 input provenance·Godot 수신 및 장면 상태가 일치. 증거 부재 시 미완료. |
| 16 | 실제 OS key 그룹 선택, mouse 재시작/복귀 | key 2 press/release와 selection, 두 mouse route의 정확 버튼 이벤트. 키보드만으로 재시작·복귀했다고 집계하지 않는다. 현재 GUI gate 미통과. |
| 17 | 실제 제품 WorldMap complete 버튼 흐름 | marker/mode/standard/sortie/skip, 버튼당 pressed-once, start/join/publish 1회, 두 idempotent polls, main-thread join 후 독립 outcome·fingerprint. 175초 deadline 도달시 먼저 failure 저장 후 cancel/join, 320초 외부 Job 정리. |
| 18 | 실제 WorldMap cancel/reclick | 실제 취소 버튼 → cancel/join/browse/no outcome → 동일 Brief 재출격/skip·새 resolver → 실제 재취소/join/no outcome. 두 cycle 각각 원시 pressed 횟수, 결과 접근 금지, 중복 publish 없음. |
| 19 | 7 suite B/A 14 프로세스 | source-evidence + 분모 문서. 7개 exit 0 및 모든 정적 case ID/필수 guard. Q/C는 아래의 동시 독립 oracle 방식. |
| 20 | BattleFlow 23 / AutoResolve 600 각각 B/A | 23개 ordered labels와 허용 9..11 값만 변동, baseline exit·진단 유형. AutoResolve default argv JSON typed token 대조와 독립 결과 경계. |
| 21 | WorldLink clean/returning 각각 B/A | 43 static + 4개 stage·3 device; 독립 button path 목록. clean 기존 1 false·exit1만 편차, returning exact settings·all true·exit0. raw leak/error 원문과 source map 보존. |

## 동적 oracle과 판정기

- Headless Q는 fixture/seed/tick별 independent raw projection에서 기존 reference_commands의 count와 typed command tuple sequence를 먼저 기록한다. 같은 tick 제품 queue 호출을 다른 source ID와 순번으로 기록한다. 둘의 원문과 pending log의 위치를 연결한다. Tick 0에서 terminal≤1200까지 조기 종료/누락이 있으면 실패다. Historical total 13,417이나 최종 command count는 Q oracle로 사용하지 않는다.
- Service C는 restore 전 fresh native source fixture의 양쪽 contact ID·typed payload를 캡처한다. Reference record IDs와 per-side/ID 순번 및 target detached identity assertion을 일대일 비교한다. Source record와 production restored output이 같은 어댑터 경로에서 파생되면 독립 oracle이 아니다. 기대 fixture에서 record ID 근거 확보가 안 되면 2,202 표시와 상관없이 미완료다.
- WorldLink B는 기존 `_buttons` 호출 자체를 oracle로 복제하지 않는다. 준비한 scene 구조의 stage별 예상 stable NodePath와 visible/enabled 기준을 별도 관측하고, result UI에서 path/instance와 device 0..2의 1:1 order를 확인한다. 표시 문자열만으로 버튼을 식별하지 않는다. 독립 stage 목록이 확보되지 않으면 미완료다.
- Overlay는 격리 프로젝트에서만 적용한다. 원본/변형 SHA, unified diff, source line mapping, 호출 위치와 식 평가 1회 불변을 검토한다. Assertion ID는 row/case/source/site/occurrence 조합으로 로그의 중복·순서 바꿈·누락·false·type 오류를 거부한다. 정상 exit 이전에 evidence flush 및 출력 open을 확인한다. Worker running은 호출별 frame 수를 독립 scheduler 변수로 취급하고 payload와 실제 join은 검증한다. Replay controls별 두 번째 factory 미도달은 실패다. 비교기 합성 반례와 acceptance를 별도 저장한다.

## 실제 OS input의 선행 계약

현재 CUA/Sky에서 확인한 증거만으로 요청별 독립 OS input 귀속을 보증할 수 없다. 수용 가능한 API 조건은 (a) 입력 요청의 원자적으로 기록된 고유 nonce와 송신 대상, (b) Windows OS hook에서 독립 관측되는 동일 이벤트의 요청 표식 또는 그와 동등한 독립 송신 증거, (c) same-desktop 독점성 및 이벤트 손실을 검출할 수 있는 관측 경계다. Windows INPUT extra-info와 LL hook extra-info를 연계하는 방식은 별도 승인된 송신기/OS hook을 전제로 하는 후보일 뿐이다. 다른 프로세스의 태그 위조를 막는 OS 인증 토큰은 아니다. 현재 Sky API가 이런 연결을 노출한다는 근거가 없고 임의 SendInput으로 교체하면 기존 입력 주체 계약이 바뀐다. 같은 시각/키/좌표/flag, foreground 전후 일치, screenshot만으로는 귀속을 확정하지 않는다. API 부재가 해소되지 않으면 15/16을 미완료로 두고 전체 K6을 개시하지 않는다.

비제품 별도 계획은 허용된 격리 데스크톱에서 nonce 창의 read-only owner/foreground 관측부터 시작한다. 활성 사용자 화면에서 global hook·물리 입력은 제외한다. 별도 수용된 관측기 시험에 한해 관측 영역/시간/타 창 이벤트의 내용 미수집/handle·hook 즉시 해제를 명시한다. Synthetic 이벤트 결과는 제품 실제 OS user acceptance에 편입하지 않는다.

## Windows Job 및 실패 정리

최종 runner는 V5 inert broker 방식과 동일한 격리 소유 경계를 유지한다. 정확 broker HANDLE에 Assign 후 positive membership 확인 및 launch barrier 해제, 실제 console/GUI engine tree를 independent process HANDLE·creation time·image SHA로 연결한다. Unassigned broker는 EOF만 받으며, assign 오류를 raw Win32 error와 함께 기록한다. Process tree가 console→GUI로 확인되지 않으면 실제 tree를 기록하고 의도적 synthetic descendant 실험과 구분한다. Timeout/exception/normal join에서 ActiveProcesses=0 및 개별 HANDLE signalled, nonce 창 종료, 비소유 sentinel 생존을 별개로 확인한다. 브로커 반환값만으로 증명하지 않는다. Nested Job 정책 거부가 재현되지 않으면 미검증으로 남긴다. Synthetic timeout 통과로 실제 Godot child 측정을 대체하지 않는다.

최종 manifest가 독립 수용된 뒤 단일 K6을 진행한다. 제품 검증 첫 spawn 시 소진 기록을 먼저 만들며 오류·시간초과·증거 누락·외부 drift에서 즉시 실행을 닫는다. 소유 Job의 자손만 정리하고 원문을 보존한다. 부분 통과를 K6 보충이나 이전 성공과 합산하지 않는다. 예산/실측·제품 path·결과 검증 후 독립 5-b를 통과해야 원본 적용 조각을 검토할 수 있다.

## 독립 심사표

| Gate | 유한 통과 조건 | 현재 |
|---|---|---|
| 입력 | 21행과 각 process의 정확한 immutable argv/env/fixture/overlay/cache·source closure 및 before/after 허용 diff | 최종 manifest 미동결 |
| Oracle | 사례별 static IDs, Q/C/B 독립 캡처 규약, exact types/sequence, false/누락/중복/timeout 반례 | 부분 작성. 최종 계측 코드와 fixture 심사 필요 |
| GUI | per-request provenance 및 반례로 검증된 사용 API, nonce owner·foreground 연속성 | 미증명 |
| Job | 동일 runner와 actual engine의 lifecycle/소유·cleanup 실측, assign 거부 관측 분리 | 실제 시험 미실행 |
| 시간 | 175/320 보존, 58/20,270의 성격, staging/import·cleanup 포함 global cap 및 실패 정책 | 전체 wall budget 미동결 |
| 결과 | 21행 분모와 58 이내 실제 jobs; clean legacy 편차 분리; 0 timeout/missing; raw evidence 및 독립 5-b | K6 미사용 |

이전 정상 분모는 현재 효능의 실측이 아니다. 역사 59/101/148/11,553/2,202/20,099 및 headless 13,417와 이전 PASS는 비교 자료이며, 이번 제품 성공률은 미측정이다.
