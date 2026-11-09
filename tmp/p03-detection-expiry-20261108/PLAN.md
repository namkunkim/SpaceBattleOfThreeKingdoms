# P03 접촉 만료 사건 좌표 검증 계획

2026-11-08 KST. **독립 계획 심사 대기. 테스트·Godot 미착수. K6=0.** Sol 실행 / Terra 심사 명시 배정, Astra 제외. [Detection 원장](../p03-detection-ledger-20261108/DETECTION-STATE-LEDGER.md)에서 분리한 미실행 가설 하나를 검증한다. P02 공통 owner/Detection/adapter/host/replay/체크리스트는 읽기 전용이다. Dictionary exact context MISMATCH는 그대로 미해결이다.

기존 `tests/detection_rules.gd:57–90`는 confirmed→estimated→lost→none 상태/사건 순서를 검증하지만 none 사건 좌표와 side0 필터 결과를 대조하지 않는다. P02 viewer 결과는 초기/교전 필터 및 소진 동작을 다룬다. 이 후보는 **마지막 공개 위치와 실제 숨은 위치가 다른 만료 사건**에서 raw와 side별 표시 payload를 읽고, 같은 만료 직전 packet 재개에서도 같은 관측을 하는지 제한적으로 검증한다. 공개 정책·수정 요구·보안 판정은 별도다.

## 실제 fixture

P02 viewer의 typed near 제한 profile을 읽기 참조한다. 서비스 입력은 `tests/fixtures/p02/services.json`의 rules/combat, seed0/hz10/direct 두 개, ally x400 및 정찰 3×SHP-03·1×SHP-06, foe x625/4×SHP-04, y500/FRM-01, reinf=[]다. 앞선 P02 typed roster와 동일 값의 1회 실제 advance에서 side0 foe2 confirmed 및 seen=1을 필수로 확인한다. 이후 **테스트 전용 제어**로 foe의 `pos`만 전장 내 먼 점 Vector2(2800,1800)으로 변경한다. 실제 플레이 이동을 입증하는 조작은 아니다. 책/시계/이벤트를 쓰거나 `Detection._eval/_store`를 직접 호출하지 않는다. 같은 typed profile의 raw BattleSim 세 개에 각각 동일 초기 명령·advance·위치 조작을 적용하고 raw/side0/side1 예상만 하나씩 소비한다.

정상 cadence/설정 guard는 eval period 10tick, memory 1800tick, lost 600tick이다. 최대 2411tick까지 실제 advance한다. 최초 confirmed 이후 foe alive, seen=1/pos=마지막 공개 위치 유지와 hidden 실제 좌표의 차이를 확인하며, 예상 첫 평가 11 estimated, 1811 lost, 2411 none 및 개별 원문 사건 tick을 대조한다. 양쪽이 자동 전술 때문에 다른 상태에 도달하거나 false precondition이 생기면 결과를 조용히 대체하지 않고 절차 실패를 보존한다. 과거 사건은 각 step에서 drain하되 2410 이후에는 만료 사건을 관측하기 전에는 drain하지 않는다. 이 시점에 직전 checkpoint를 capture한다. raw reference들에는 capture/restore를 쓰지 않는다.

| 명명 | 실제 판정 |
|---|---|
| expiry_01_last_seen_distinct | 실제 확인 및 상태 전이, 서로 다른 last seen/hidden 현재 pos, 대상 alive, tick2410 lost 및 checkpoint. 전체 projection에서 이 접촉의 위치가 last known임을 확인 |
| expiry_02_native_and_owner_expiry | tick2411 actual step에서 기록 제거·projection에서 제거, raw/side0 contact none 정확 payload 및 side1 제외. side0에 숨은 현재 pos가 정확히 담겼으면 **CURRENT_POS_OBSERVED**, 마지막 위치라면 **LAST_KNOWN_OBSERVED**, 둘 다 아니면 별도 실패. Native의 해당 결과와 독립 수기 좌표를 함께 대조 |
| expiry_03_restore_before_and_repeat | 실제 만료 후 동일 owner에 tick2410 packet 복원, detection book·typed 값/시계/참조 동일. 같은 advance 한 번에만 만료를 재현. raw/side0 분기는 복원한 새 sim 각각에서 소비하고 packet은 불변. side0 출력 및 판정을 최초와 비교 |

명명3과 독립 raw 3개, 제한 fixture1 및 실제 assertion을 별도 기록한다. 측정 절차의 actual exit0을 공개 정책 PASS로 해석하지 않는다. 이벤트 key/type/order, Vector2 값, 책의 int ID 및 exact snapshot, 엔진 console/실제 본체 SHA·PID·경로, 정본 cache/실제 Script identity, 전용 Job timeout, fixture·전이 입력 SHA 직전/직후, Git 시작 분모와 raw stdout/stderr 및 실제 exit/오류/경고/누수를 기록한다. 새 경로에만 runner와 증거를 만들며 Godot editor import는 하지 않는다. 실패는 K6, 범위/오라클 변경 재심, 사용량 제한 즉시 보고 및 반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
