# 제한 owner lifecycle 정적 원장

승인 계획의 11개 공개 진입점과 3개 교차 반례를 읽기 대조했다. 공통 원문은 core/battle/operation_private_state.gd다. 함수 시작 행을 표에 기록했다. _guard(165–168행)는 busy를 먼저 검사하고, 다음으로 _ready=false 또는 _sim=null이면 unprepared_owner를 반환한다. B는 정확한 두 키 {ok:false,error:E}, P는 정확한 세 키 {ok:false,error:E,path:owner}다. E는 해당 guard 값 busy 또는 unprepared_owner다. _fail은 26–27행에서 B를 반환한다.

| 진입점 | 원문 행 | 순서와 가드 응답 | 가드 통과 후 읽기·변이 |
|---|---:|---|---|
| issue | 206 | _command(212)에서 guard → 명령 구조 검사. B | 명령 사본 생성 후 busy 설정, _sim.issue로 즉시 적용, busy 해제 |
| queue | 209 | _command(212)에서 guard → 명령 구조 검사. B | 명령 사본 생성 후 busy 설정, _sim.queue로 enqueue, busy 해제 |
| advance | 223 | guard. B | busy 설정 후 _sim.step, busy 해제 |
| drain_events | 231 | guard. B | busy 설정 후 raw queue drain과 깊은 복사, busy 해제 |
| drain_events_for | 240 | guard → 정수 side 0/1 검사. P. 잘못된 side는 {ok:false,error:invalid_side,path:side} | busy 설정 후 공용 queue의 표시용 소비와 깊은 복사, busy 해제 |
| read_projection | 250 | guard → 정수 side 0/1 검사. P. 잘못된 side는 {ok:false,error:invalid_side,path:side} | projection을 읽고 깊은 복사. 이 진입점에서 busy 설정 및 사건 소비 없음 |
| summary | 256 | guard. P | _sim.st와 fingerprint, log 길이 등 DTO 구성. 이 진입점에서 busy 설정 및 사건 소비 없음 |
| observe | 272 | guard. B | fleet·missile·swarm·service 상태 추출, view 구성 또는 service 오류 반환. 이 진입점에서 busy 설정 및 사건 소비 없음 |
| capture_completed | 285 | guard → _bindings → observe의 별도 guard → packet 지원 값 검사. 최초 guard는 B | profile/controls 복사와 정본 packet 조립. observe 실패는 그대로 전달하며 사건을 소비하지 않음 |
| restore_completed | 361 | guard → busy 설정 → prepare → context 검사. 최초 guard는 B | prepare/context 실패에서 busy 해제, 기존 sim 유지. 성공 시 sim 이전, candidate 정리, retired 모듈 참조 해제, busy 해제 |
| close | 479 | guard 없음, void. B/P 응답 없음 | _ready와 _busy를 false로 내리고 모듈의 sim 참조와 _sim을 비움 |

## 교차 반례 3개

1. **busy와 잘못된 side**. drain_events_for(false) 및 read_projection(false)는 _guard에서 P의 busy로 종료한다. side 검사와 사건 drain에는 도달하지 않는다. 실제 기존 viewer는 tests/p02_viewer_events.gd:232–237에서 첫 경우를 시험했고 viewer.stdout E13 및 총 14/148 PASS를 남겼다. 기존 adapter의 tests/p02_headless_adapter.gd:323–328과 attempt3의 8/13417/32 PASS 원문은 read 계열 busy DTO의 겹치는 근거다. 이번 조사는 새 실행을 추가하지 않았다.
2. **busy와 잘못된 command 또는 packet**. issue/queue의 _command_error 및 restore_completed의 prepare보다 _guard가 먼저 실행된다. 세 경우 정확 B의 busy이며 원문의 초기 반환 이전에 _sim·_busy에 쓰지 않는다. 기존 active_replace의 busy+기존 packet과 private_state의 busy+일반 command는 겹치는 경로의 근거다. 잘못된 payload를 함께 전달하는 두 분기 조합은 여기서 정적 결론이며 해당 조합의 과거 runtime 원문은 미확인이다.
3. **close 뒤 restore와 잘못된 read side**. close가 _ready=false, _busy=false, _sim=null을 설정한다. 이후 restore_completed는 정확 B의 unprepared_owner이며 prepare에 도달하지 않는다. read_projection(false)는 정확 P의 unprepared_owner이며 side 검사를 건너뛴다. 기존 active_replace는 tests/i01b_active_replace.gd:274–277의 closed restore를 확인했다. 기존 viewer E13은 drain_events_for(false)의 closed 우선도 확인했다(tests/p02_viewer_events.gd:240–242). read_projection(false)의 closed+invalid side 조합은 정적 결론이며 그 조합의 실행 원문은 미확인이다.

## 근거 범위

viewer, adapter, active replacement의 기존 결과 문서와 실제 captured/exit 원문을 INPUT-BEFORE/AFTER에 경로·SHA·크기로 남겼다. 이전 결과에서 언급된 케이스를 이 조사의 새 런타임 분모로 집계하지 않는다. create·prepare는 공개 11행 분모에서 제외했으며 restore의 호출 순서에만 인용했다. 소스의 serial 분기 순서는 실제 동시성, 재진입, 제품 UI 및 외부 ACK의 검증이 아니다. cursor/drain 실제 실행 3/K6 및 종합 5-a 미통과와 분리한다. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
