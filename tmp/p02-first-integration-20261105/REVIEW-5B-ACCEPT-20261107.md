# P02 첫 실제 headless 소비자 — 독립 최종5b

2026-11-07 KST. 판정: **제한 fresh headless opt-in 연결을 수용한다.** 아래 오류코드 분류 편차를 공개한 제한 수용이며 전체 P02/I01/I01b/A04~A06 완료가 아니다. 전체 NOT_READY, 외부 save schema UNCLASSIFIED를 유지한다. 다음6단계 기록·최종 보존감사·manifest/ZIP·독립 closeout은 아직 별도다.

심사자 `/root/independent_review`는 생산 코드·검사·fixture 구현과 Godot 실행에 참여하지 않았다. 수용 계획/v2·attempt1 보완계획과 심사, 실제 source/diff, 원문 로그·관측·입력 동결, 보존 원자료를 대조하고 읽기 전용 재해시·Git 상태/공백 검사를 수행했다. 이 새 심사문만 작성했다.

## 실제 구현과 소비자 경계

`operation_runtime_adapter.gd`는 엄격한 opt-in 입력 컨테이너·필드·mode/format·정수·controls·policy 검증과 한 번의 깊은 복사 정규화를 수행한다. int 변환 전 bool/비유한/분수/범위초과를 거부하고 composition 합산도 overflow 전 검사한다. pure normalize 결과와 factory 성공 metadata를 분리했으며 factory는 완성된 private owner 하나만 반환한다. 입력 profile이나 runtime을 임의 기본값으로 교체하지 않는다.

기존 private owner에 추가한 read_projection/summary는 guard 및 side 타입·범위 검증, detached public projection/요약만 제공한다. raw sim을 생산 소비자에 노출하지 않는다. 원래 create/restore/context/codec는 추가 hunk 역제거 시 이전 바이트로 정확히 복구된다. read 추가로 코드 해시가 변했으므로 과거 packet 호환을 보장한 변경으로 해석하지 않는다.

실제 `tests/autoresolve.gd`의 `_run`은 --operation-input이 존재할 때만 신규 parser·파일읽기·factory·실행 loop·결과쓰기로 연결한다. 기존 기본 parser/play/play_rc/정책/통계 본문은 바이트 보존했다. CLI의 owner는 초기 출력경로 실패와 실행 성공/실패에서 close되고 파일쓰기 전에는 이미 닫힌다. 기존 파일/디렉터리를 열지 않는 no-clobber, 출력 직전 재확인, write/flush 오류 및 재읽기 크기·SHA 검증을 확인했다. 지원하지 않는 OS 경합·디스크 장애 복구 원자성을 주장하지 않는다.

정책은 public side0 projection만 읽는다. none 즉시 반환, copied 정책뷰의 confirmed/estimated contact에만 dead=false 보완, lost 제외는 기존 Detection.foes/can_target 공개 의미와 일치한다. 비공개 좌표·체력·척수를 조회하지 않는다. 생산 정책과 독립 raw reference는 각자 명령을 생성해 서로 다른 runtime에 queue한다. 수제 P9 기대명령으로 두 정책을 별도 검사하며 strict tie·순서·주기·lost·dead 누락 반례를 포함한다.

fixtures3개의 rules가 현재 POC 정본과 같고 reinf=[]는 명시 authoring임을 직접 대조했다. services의 각 combat 내용도 현재 정본의 대응 내용과 일치했다. 미지원 모듈은 입력 작성 시 명시 제외한 제한 구성이지 runtime 삭제나 stock POC/적벽 대체 성공이 아니다. I01a source/effective 변환·제품 공간 지원으로 확대하지 않는다.

## 실행 증거·oracle 대조

attempt3 입력42항과 실제 디스크 SHA를 직접 비교해 불일치0이었다. 그중 source snapshot33개도 동결 SHA와 일치했다. API·CLI·회귀 합계21개 프로세스의 captured/engine 로그 SHA를 actual-exit 기록과 대조했고 불일치0, 모든 captured 로그의 SCRIPT ERROR/ERROR0을 확인했다. 실제 기대 exit는 API/성공/legacy/회귀0, 명명 CLI 거부1이다.

| 구분 | 직접 확인한 결과 |
|---|---|
| 신규 API runner | actual exit0, 정상matrix8 / checks13417 / APInegative32 |
| 정책·timeout 보완 | P01~P09 실제/reference/하드코딩 기대값 일치9, T01/T02 각각 tick1/clock100/over=false/end=-1/commands0 |
| 전체 명명 거부 | API32 + 실제 CLI14 = 고유46, 각 error/path 대조 |
| 실제 CLI | 거부14개 각각 exit1·OPERATION_REJECT1건·PASS없음, 성공2개 exit0 |
| legacy | 실행 전 원문 복사와 변경후1쌍 actual exit0, 출력 JSON 바이트까지 동일 |
| 최소 회귀 | private70/11553/45와 core 실제 exit0, 원문 PASS 및 SCRIPT ERROR/ERROR0 |

API OUT-only 실행본과 private OUT-only 회귀본을 직접 역치환하여 원본 바이트와 정확히 같음을 확인했다. legacy baseline 실행본은 보존된 원문과 바이트 exact이며 별도 로직 변경이 없다. 실제 CLI 거부14개는 원문 OPERATION_REJECT의 error/path를 직접 추출해 확인했고 sentinel의 `preserve-existing-output\r\n`도 그대로다. CLI2성공 summary는 독립 raw 비교를 거친 consumer_summary와 일치하며 events 길이/순서 보존은 runner의 별도 실제 consumer/raw 비교가 뒷받침한다.

관측에는 POC seed0 attack5의 tick2/clock150/end150, services seed0 attack5의 tick621/clock62050이 있다. tick×100으로 실제 종료시각을 재생성하지 않는다. matrix natural7/timeout1은 결과 관측이며 성공 목표가 아니다. 조기 종료한 POC attack5 두 경우에는 5/10/15tick 중간 체크포인트가 없고 나머지6개에는 각3개가 있다. 모든8개가 그 중간시점까지 진행했다고 주장하지 않는다. 각 프로필에서 명령 즉시적용/대기·거부원자성·다음호출·이벤트1회 drain과 close bindings를 확인했다.

CLI POC 실제 결과에는 missile_launch/volley/missile_hit와 종료가, services에는 contact/salvo/ship_lost와 종료가 있다. services에 Supply 모듈이 포함되지만 이번 CLI 관측에는 supply 완료 사건이 없으므로 새로운 보급 완료 E2E 증거라고 표현하지 않는다. 전체 runtime 필드/자원·상태 비교와 기존 P2c 회귀의 범위만 인정한다.

attempt1 actual exit1의 dead SCRIPT ERROR8112/timeout assertion1은 그대로 실패다. 독립 보완계획 수용 뒤 수정했다. attempt2 actual exit1/SCRIPT ERROR0/assertion2는 typed raw drain Array와 untyped consumer aggregate의 표현 비교 오류다. attempt3는 raw 사건을 별도 untyped aggregate에 누적하여 비교하며 strict same의 타입·순서·값 검사를 없애지 않았다. 이는 정당한 oracle 표현 보정이며 생산코드 변경·allowlist/skip 완화가 아니다. 주 API runner 새 단계3/K6, 이전 P2c5/active2와 별도다.

## 독립 보존·모델 확인

기존 baseline3960을 직접 전량 재해시했다. 누락0, 변화는 허용 private helper1개뿐이다. 원래 clean tracked였던 autoresolve는 별도 사전 원문과 비교했다. private의 추가19행, autoresolve의 opt-in 분기3행 및 전용129행을 각각 역제거하면 사전 바이트 SHA가 정확히 복구된다. 기존 줄 삭제0이며 legacy 본문·restore/context 보존을 직접 확인했다.

원 source35 변경0, 가역격리77의 SHA/원경로부재 정합, active test·cache·HTML·과거ZIP2 보존을 직접 확인했다. pre-review manifest235항을 재해시해 불일치0이었다. manifest SHA는 `ee8e558df476617ddbd13d46fb435cd6dc52dd18b43d688d1995044788588dde`다. 이235는 심사 전 시점 분모이며 앞으로 작성할 이 심사문·6단계 문서·압축까지 포함하지 않는다.

| 최종 코드 | SHA256 |
|---|---|
| core/battle/operation_runtime_adapter.gd | `0c0cad3e6e4e15887dcd75f9d5b57dbbe2690bfdcafd1caac163909b5421173a` |
| core/battle/operation_private_state.gd | `dd47ceebaad2c5139bd8012deb841815cf0707c2231de202a00756913c0fa427` |
| tests/autoresolve.gd | `a6c3ee903e2365569a31aa0194acb426d87c5856a74a9c7dcaaedeaeea18b5b8` |
| tests/p02_headless_adapter.gd | `e44e964ed76f4d7d2edab8ebffa238672c70717670b6d82738120c72dfea9583` |

private 역제거 SHA는 `6be2adeb64bec7c9a89040cab5c9558219e063272df1a9e5fd00cf1dd9111441`, autoresolve 역제거 SHA는 `6359e508c1c005b0517731616b3ec6d9f04f38958e91df3275111e0804d83555`다. branch `codex/feature-i01b-not_remove`, HEAD `fb660cea69207fd332e26128643007694910a253`, index 빈 상태를 직접 확인했다.

이전 계획심사에서는 요청 모델만 알려져 실제 모델을 확인하지 못했다고 구분했다. 이번에는 model-independence-evidence.json의 원출처 JSONL에서 **session_meta/turn_context 메타만 직접 읽었다.** 같은 parent `01a1ac09-125c-71d0-b13b-721727506c85`의 reviewer session `01a1ac0c-e780-7e71-9a6a-6ff6fe3898a6`는 `/root/independent_review`·gpt-6-astra, implementation session `01a1ac1c-0e03-7903-b5fa-d3bc46e11d1d`는 `/root/implementation`·gpt-6.1-sol로 구분된다. 같은 이름의 다른 parent agent 기록을 혼합하지 않았다. 원 JSONL은 appendable이며 관측 SHA를 영구 고정 파일 SHA로 해석하지 않는다.

전체 git diff --check를 직접 subprocess로 실행한 actual exit는 **2**다. 기존 상위 CHECKLIST33행 CRLF/trailing 진단과 기존 줄바꿈 경고를 확인했으며 새 소유4코드는 trailing0/최종 newline 있음이다. stdout SHA `91be8367860019a1e276a52b8cd1f1542ff5439ce163f2f84cdd326e0ac08255`, stderr SHA `9383227f23e362399d837fdb9c3c96bbd55d9aa7b4797dccb087af7227ca50c7`. 전체 게이트 PASS로 표현하지 않는다. data_rules를 이번에 재실행하지 않았고 기존 ObjectDB/resources/TRACE 진단을 해소했다고 주장하지 않는다.

## 비차단 편차와 수용의 한계

계획은 모든 기존 legacy 옵션 혼합을 conflicting_option으로 분류했지만, 새 parser 목록에 --no-chain/--no-m9/--wind가 없어 이 세 옵션은 **unknown_option**으로 거부된다. 실제 소스에서 확인한 진단코드 분류 편차다. 세 경로를 이번14 CLI 실증에 포함했다고 세지 않는다. 어느 분류든 option 파싱 단계에서 명시 실패하며 owner 생성·legacy fallback·출력 쓰기로 진행하지 않으므로 첫 제한 연결의 기능 수용을 차단하지 않는다. 이 편차를 정확히 기록한 현재 코드로 수용하며 조용히 계약을 모두 충족했다고 표시하지 않는다.

write/flush/재읽기 실패 분기는 source로 검토했지만 디스크 fault injection은 미실행이다. 기존out sentinel·없는 부모·Windows 금지 leaf open 실패만 실제 실증했다. 신규 입력의 지원 범위는 현 제한 profile과 명령 subset이며, 이 결과가 임의 profile의 모든 자원 규모·스레드·UI/host·replay·외부 저장/호환·전체 ST/Cn/global cursor·제품 공간·Android·성능·사람플레이를 보장하지 않는다.

추가 코드 수정·무관 검사 반복을 요구하지 않는다. 수용된 범위의6단계 결과/체크리스트·인계·최종 감사/압축으로 진행할 수 있다. 그 문서와 최종 ZIP의 독립 closeout은 이후 따로 확인한다. 커밋/푸시/병합/브랜치 전환·새 worktree·HTML/editor import 승인이 아니다.
