# C side 1 합성 판정기 v7 및 K6 인계

v4~v6과 각 독립 심사를 보존했다. 이 조각의 완료 조건은 이전 raw order 판정기에 payload 결합을 추가하고 유한한 정상/반례 자료를 재현하는 것이다. 제품 수준 C 판정이나 K6 수행 가능성을 완료로 보지 않는다.

## 이번 조각

`c_side1_payload_v7.py`는 v6의 원본 사건 순서와 v4의 조건부 geometry를 유지한다. Launcher가 제공한 lane별 원본 파일 SHA와 동일 process identity를 확인한다. Event의 run ID, PID·creation time, producer SHA를 launcher receipt와 일치시킨 뒤 lane 내 monotonic 값을 검사한다. 각 eval의 authoritative tick 및 geometry를 side 1 증인과 정확한 타입 및 값으로 연결하고, 초기 빈 contact와 모든 ordered cases를 요구한다. 같은 시점의 다른 restore 요청을 이름으로만 허용하지 않는다. Source capture 및 restore request의 packet bytes를 독립 재해시하고 phase-specific request ID와 result를 연결한다. Result의 실제 자료 형태는 {"ok":true}만 수용하며 target capture의 raw state bytes와 digest를 결과에 맞춘다. Wrong-position control의 packet은 첫 packet과 달라야 하고 source state는 두 restore 단계 사이 동일해야 한다.

정상 9,600개의 합성 사건에 대해 10개 반례를 거부했다. False result, 같은 tick의 wrong request, bytes와 함께 교체한 packet, raw bytes/hash 불일치, geometry 차이, tick 불일치, monotonic 역전·재사용, process identity 교체, simulation ID 중복, 결과 뒤 상태 변경이다. 원본 합성 스크립트와 로그가 재현 자료다. 합성 packet/state bytes는 임의 바이트이며 실제 Godot Variant payload의 내용과 의미까지 검증하지 않는다.

## 실제 실행 전에 남은 유한 게이트

1. **실제 C 생산기.** 독립 심사 후에만 제품이 아닌 probe로 collector schema를 검토하고, 본 게임 fixture의 실제 관측은 최종 K6 안에서 수행한다. 승인된 isolated overlay에 실제 `_eval` 진입 직전 raw geometry, tick 0 초기값, 평가 actor·run-scoped sim ID, actual restore 반환값과 packet/state 원문을 직접 기록한다. Launcher가 다른 경로에서 process identity·원본 stream SHA·전체 source/engine/cache closure를 고정한다. v7은 입력이 거짓이거나 동일 producer가 양쪽 증인을 함께 꾸민 경우까지 판별하지 못한다. Raw evidence, approved producer SHA, exact path/argv, stream loss와 overflow, original ordinal, independently observed stage/closure를 실제로 연결해야 한다. C side 1의 실제 부재는 현재 미입증이다.
2. **Q와 B.** Q policy와 typed fields/binary 일관성은 합성 검토만 완료했다. K6 안에서 fixture/tick, native projection과 제품 호출 대응, 실제 engine precision 및 near tie를 관측한다. B는 소스 기반 label/device 순서가 보조 기준이다. 같은 label의 다른 handler, 동적 absolute NodePath, 실제 전환과 109회는 미확정이다. 21행에서 실제 action 및 상태 전환을 독립적으로 연결한다.
3. **GUI 및 Job.** 문서화된 Sky에서 per-request OS receipt나 독점 귀속이 입증되지 않았다. 행 15/16과 전체 K6은 대기한다. 비제품 Job 시험의 supervisor 및 outer/inner membership, actual engine lifecycle, watchdog global/inner deadline, OS-backed filesystem isolation은 미구현 또는 미실측이다. W4는 55초 계획이고 실적용이 아니다. 별도 독립 실행 명세에서 비제품 W1~W5를 고정하고 수용받은 뒤 시험한다.
4. **최종 21행 계약.** 독립 적합성 결과, immutable before/after source/fixture/cache/overlay/engine, actual argv/env, 행별 case/oracle/expected exit, 시간·Job·중단 계약을 수용받는다. staging·검증·로그 flush를 포함해 전체 예산을 동결하고 제품 175/320초를 유지한다. HEAD lane은 활성 P03 +9와의 결합을 검증하지 않는다. HEAD/index/P03/worker 원문 전후 보호와 허용 diff를 다시 확인한다.
5. **단일 K6 및 5-b.** 최초 제품 import/검증 spawn에서 마지막 K6을 소진한다. 부분 실행·실패 후 재시도하지 않으며 원본을 보존한다. 21행 제품 실행과 별도 독립 5-b 수용이 제품 원본 연결을 검토하기 위한 조건이다. 기존 K1~K5 및 K4/K5 실패 기록은 유지한다.

정적 판정기만 반복해서 보강해 실제 producer 및 Job/GUI의 외부 의존성을 대신하지 않는다. 위 실행 게이트가 확인될 때 다음 검토로 넘어간다. 이번에 제품·Godot·GUI·Job은 각각 0회 실행했으며 K6 한 회가 남아 있다.
