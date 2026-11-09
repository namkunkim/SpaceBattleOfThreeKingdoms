# P02 세 번째 조각 구현 및 5-a 증거

2026-11-08 KST. 전체 P02/I01/I01b/A04~A06 **NOT_READY**, 외부 save schema **UNCLASSIFIED**. 이 실행점은 기존 autoresolve 운용 CLI의 제한 fresh 명령 재생 소비자다. 독립 5-b 판정 전이다.

## 실행점

```powershell
& C:/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . -s tests/autoresolve.gd -- --operation-replay tests/fixtures/p02/replay-commands.json --out <새-절대경로>
```

기존 출력 검사를 먼저 거친 뒤 16 MiB 이내의 입력 파일을 한 번 읽는다. 읽은 바이트의 SHA-256을 메타에 넣는다. envelope 안의 원본 input을 공통 factory에 한 번 전달한다. 명시 []과 유효 초기 controls는 그대로 전달한다. 누락은 factory 분류인 missing_field / input.initial_controls다. 기존 factory가 허용하는 양의 정수 범위에서 18,000틱 초과는 replay_tick_limit이다. factory 자체의 정수 범위·형 오류는 원 분류를 전달한다.

모든 명령 구조를 owner.advance 전에 검증하고, source order에서 같은 현재 tick에 있는 명령을 queue한다. queue 다음 step·drain·summary 순서로 처리한다. 일반 성공과 실패는 하나의 _play_and_close 경계를 거친다. native rejected도 queue 후 step을 거치므로 consumed에 포함된다. 자연종료 뒤 남은 명령은 입력 실패로 반환하고 출력은 생성하지 않는다. 출력 helper는 쓰기 직전 기존 경로를 다시 검사하고 쓴 바이트를 검증한다. 파일 무출력 및 보존 검증 범위는 단일 프로세스의 계약 실패 경로다.

## 독립 오라클과 반례

- 구현 전 oracle.gd는 typed native 명령을 직접 만들고 BattleSim을 생성해 초기 controls를 설정한 뒤 queue·step·drain을 호출했다. 오라클은 replay 모듈, normalizer, DTO에 의존하지 않는다. oracle.native는 Variant 원형이고 oracle.stdout는 동일 관측의 JSON이다. oracle-freeze.json과 oracle-verdict.json은 실행 명령·입력 해시 및 사후 일치 결과다.
- 원거리 3틱 기준 명령의 순서는 0틱 move→stop, 2틱 범위에 없는 함대 attack이다. 동틱 순서를 뒤집으면 say 사건 순서와 최종 fingerprint가 달라졌다. 마지막 행 제거는 2틱의 rejected/no_selection 사건과 consumed count를 제거했다. 기본 controls 공통 3틱 구간에서 BattleSim.replay와 native fingerprint가 일치했다. 전체 사건 또는 자연종료 비교는 직접 native loop로만 판정했다.
- 초기 controls로 direct/delegate를 넣으면 native control 값이 다르다. 이번 제한 services fixture의 3틱 CLI 요약·사건은 동일했다. oracle-first와 oracle-second는 CLI fingerprint 차이를 가정했으나 관측하지 못한 탐색 실행 두 건의 원문이다. 정본은 native fleet control 필드에서 차이를 읽고 CLI는 실제로 공개한 DTO만 대조한다.
- 비가시 표적 보충 검사는 정본 오라클을 고치지 않고 oracle-hidden.gd를 분리했다. distance 2,100의 실제 foe ID를 사용한 attack은 0틱의 native rejected/no_contact를 내며 1행 consumed, tick1/clock100, 미종료다. oracle-hidden-freeze.json 및 원 로그 보존.
- 자연종료 services의 summary 및 순서 있는 전체 events와 event_count는 입력이 같은 sync CLI와 비교한다. tick1 제한은 clock100, over false, end_tick/end_ms -1이다. 보급 완료 사건은 이 fixture에서 관측되지 않았다.

## 시도 이력 및 보존

- 기준선 7,967개에 대한 구현 직전 pre-drift는 0이다. 이전 P02의 3,960/7,078개 분모와 분리한다. 실제 git index 및 cache, 기존 전체 diff-check exit2와 진단 바이트는 전후 동일했다. 소유 diff의 git diff --check exit0 및 CLI 추가 hunk 3개 역적용 시 기존 파일 byte identical. 최종 preservation.json은 소유 6경로, 사용자 별도 승인 진행표 1개, P03 추가 변화 0개를 분리한다.
- 변경 전 주 실행에서 worker에 sync fixture를 사용해 unsupported_worker_policy를 관측했다. before에 그대로 보존했다. before-supplemental은 올바른 worker fixture로 worker POC/services와 동일 입력 sync services를 실행해 exit0과 SHA를 동결했다.
- Attempt 1/K6은 실제 74프로세스였다. 정상/거부 CLI 및 비교는 통과했고 전체 판정은 실패했다. replay-api exit1은 초기 기본 delegate를 명령 적용 이후의 direct와 비교한 검사 시점 오류였다. 원본 검사는 attempt1-replay-api.gd.txt와 attempt1/replay-api.stderr에 있다. 2차에서 기본 초기 controls 배열은 FleetState 기본값과 비교하고, 동일한 동결 native oracle로 명령 이후 summary/event/type을 계속 비교했다.
- Attempt 1의 battle-flow는 BATTLE_FLOW_PASS, exit0, SCRIPT ERROR 0에 ObjectDB 153·resource 18의 종료 진단이 있었다. 첫 하네스의 blanket 진단 실패로 5-a는 실패했다. Attempt 2는 별도 10/28 기존 battle-flow 로그의 WARNING/ERROR 원문 행과 정확히 비교하도록 분류했다. WorldLink는 변경 전 stderr와 바이트를 비교하며, 실제 WorldLink 전후 stderr 154/20은 종료 진단이다.
- 실제 기존 sync/worker 혼용은 동결 이전 CLI 사본과 새 CLI를 각각 실행했다. exit1, conflicting_option / --operation-input, 출력 부재 및 stdout/stderr 바이트 일치. legacy-mixed/results.json은 K6 집계 밖의 보충 관측이다.
- 독립 검토자는 attempt1과 attempt2의 freeze/results 및 원 로그, 오라클 변별력, 보존 감사, 기본 controls 정정을 별도로 판정해야 한다. 판정 전에는 구현 외 인수를 표시하지 않는다.

## 5-a 종합 판정

- Attempt 2/K6 실제 75프로세스, 비교 36건 모두 통과. 유일한 하네스 실패는 BattleFlow 역사 파일의 PASS 앞 진단까지 비교에 섞은 것이다. 원문 attempt2/battle-flow.stderr는 1차와 같은 SHA-256 54388bb9493153c525e5519a3b3bb8c42a600edb11c58048a4c77593e3b0949e. 변경된 제품 코드와 fixtures는 1~3차 사이 동일하다.
- Attempt 3/K6은 실패한 BattleFlow 한 프로세스만 재실행했다. 현재 전체 stdout 및 stderr에서 SCRIPT ERROR 0, WARNING 1, ERROR 1을 확인했다. 실제 exit0과 BATTLE_FLOW_PASS, stderr 전체와 역사 PASS 뒤 4행 일치, 이전 시도의 stderr와 바이트 일치, 2차 동결 파일 동일성을 모두 확인했다. 당시 역사 PASS 앞 별도 진단을 허용 목록에 포함시키지 않았다.
- 최종 케이스 75개는 2차 통과 74개와 3차 재실행 1개로 구성된다. exit0 22개, 예상 exit1 53개, timeout 0. 실제 replay CLI 성공 10회, 새 네이티브 API 14사례·101개 assertion, 외부 비교 36건. 1~3차 실제 K6 실행 수는 74+75+1=150개다. 사전 및 보충 실행은 이 분모에서 제외했다. 2차의 281개 동결 해시와 3차 재사용 검사가 일치했다.
- 반복 성공 파일 SHA-256 25cdc7bf81088ab39493c6e6a087ffc3138f14a653db0187d1f8d1e93f6cd104. 비교는 요약, events의 순서와 사건 수, consumed count, executor/format 및 실제 읽은 입력 SHA를 포함한다. 신규 CLI의 정상·실패 실행에서 SCRIPT ERROR, ERROR, WARNING 0이다.
- WorldLink 전후의 stderr는 바이트가 일치하고 exit0과 WORLD_LINK_PASS가 관측됐다. BattleFlow와 WorldLink의 종료 진단은 결과에서 분리했다. OS 동시 writer, 디스크 장애, 엔진 예외 및 강제 종료는 게이트 범위 밖이다.

증거 SHA-256

- attempt2/results.json 1cc9c3c01021b25aa4d17ed146e9f77d95e1c24ef4ebe4766cf96c86824b042c
- attempt3/results.json aac5b89c23ab1ab5328f3eb61daf874d177c5772324f5cadfdabe87b81aa1b7a
- preservation.json eed512702c20cf5fd7c73c114bd0cad695f076860c9d018d457d32e0d852e485
