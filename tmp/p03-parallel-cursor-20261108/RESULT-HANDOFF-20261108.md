# P03 fresh replay 부분 처리 — 결과 및 5-b 인계

상태: 실행 증거 작성, 독립 최종 5-b 대기. 계획 승인 SHA 186D68D56785176DBF19AEC9A4CD3A851623759E8F073B876400D7963B92786A와 실제 일치. 기록 REVIEW-PLAN-REPLAY-PARTIAL-V2-20261108.md. P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.

독립 raw BattleSim oracle attempt-02 actual exit0, terminal tick/end_tick 1221 및 clock/end_ms 122050, no_selection rejection·battle_end·A log를 확인했다. oracle-a.native SHA256 B9EC4B9C2E5AC1C3D9CBA60D4211384A3B0594B1A7885380FBD419E8CB2AA49B. attempt-01은 실행 전 타입 추론 parse error 2건/ERROR 1건, actual exit1; 소스 수정 후 attempt-02 성공, 두 원문 모두 보존. 이 오류는 종료 전제 실패가 아니다. 재시도 K=6 내 oracle 2회, 대상 1회.

대상 probe-attempt-01 actual exit0, 4개 이름 각각 8개, 총 32개 PASS. input-before/after 60여 입력 SHA는 실행별 전체 일치, 원문 manifest에서 정확 개수를 확인한다. 엔진 본체 identity 일치, 전용 Windows Job active0/total2, timeout 아님, SCRIPT ERROR/ERROR/WARNING/ObjectDB/종료 리소스 진단 각 0. 실행마다 별도 로그 및 run.json, 입력 전후 목록을 보존했다. 계획의 사전조건 A 포함 oracle 성공 후 대상 실행했다.

- 선행 A가 log에 남고 종료 후 B 미소비이면 정확히 `replay_unconsumed_command` / `commands[1].tick`, packet의 pending 빈 배열, raw drain 비어 있음. 이는 fresh 내부 동작이며 외부 효과의 완료·게시·ack 원자성을 뜻하지 않는다.
- 뒤 행 B의 kind만 무효화하면 구조 사전검증이 먼저 실패해 A log/queue/clock 및 초기 이벤트가 그대로였다.
- A만 처리한 정상 결과는 독립 raw oracle summary와 순서 있는 사건에 타입 포함 일치하고 consumed=1. 별도 내부 `_play_and_close` 오류 시 owner 분리/닫힘을 확인했다. 공개 run/CLI를 새로 검증하지 않았다.

증거 및 한계: REVIEW-MANIFEST.json, 각 attempt의 input-before/after.json·stdout.bin·stderr.bin·run.json, INDEPENDENT-DENOMINATOR-CHECK.json을 대조한다. 검사 ID는 명시적 각 CHECK 행과 최종 PROBE_RESULT를 통해 판독되지만 별도 CASE_START/CASE_END 표식은 없다. launcher는 고유 ID 총수·경우 수를 확인하고, 외부 사후 대조는 정확한 32개 이름을 확인했다. 계획의 별도 시작/종료 마커 요구를 완전 충족했는지는 독립 심사가 판정해야 하며 자체적으로 숨기지 않는다. launch.py는 timeout 시 Job terminate와 accounting active0을 기록하나 이번엔 timeout이 없었고 종료 확인 실패 반례를 재실행하지 않았다. 실제 사용 engine과 class map은 SHA 고정했으나 입력 의존성 완전성 및 리소스 경로 가드는 5-b에서 별도 심사한다.

HEAD는 시작과 동일 fb660cea69207fd332e26128643007694910a253. START/END-GIT-STATUS와 STATUS-DELTA에 기록했고, 양쪽 status에는 P02 긴 경로 2건 열거 경고가 있어 완전한 원자 스냅샷이 아니다. 같은 기간 P02-seventh의 다수 새 evidence와 별도 P03 병렬 작업 파일이 생겼다. 이들은 동시 타 작업으로 분리하며 삭제·수정하지 않았다. 개별 실행의 동결 입력 전후 SHA 일치가 그 외 전체 트리 불변을 뜻하지 않는다. 공유 생산물 및 체크리스트는 수정하지 않았다.

5-b 심사 순서: 승인 계획 해시와 각 검사 ID/조건을 probe.gd 및 stdout에 대조 → raw oracle 원문·생성 로그와 A/B 내용·종료 확인 → 각 실행 실제 종료/오류·Job·전체 입력 SHA 전후 검증 → status 변화에서 P02/별도 작업 분리 → 범위와 상기 표식/의존성 한계 판정. 재실행이 필요하면 승인 계획의 시간제한·동결 조건과 K 상한을 적용하고 기존 파일을 덮지 않는다. 독립 심사 전 결과를 최종 수용으로 표기하지 않는다.
