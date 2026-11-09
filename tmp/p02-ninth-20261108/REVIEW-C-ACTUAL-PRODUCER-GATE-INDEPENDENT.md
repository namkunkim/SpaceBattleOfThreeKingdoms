# Actual C producer 경계 독립 심사

판정: **한 세션의 격리 overlay·validator 구현 계획은 조건부 수용한다. 동결된 control 자체나 제품 실행은 아직 수용하지 않는다.** `C-ACTUAL-PRODUCER-REVIEW-GATE.md` SHA `55cf8320cc696e788b68f4b4ad2288bbb4dfb0f85d53b5ad3ce6180c38a88940` 확인. 심사 모델 gpt-6.1-terra. 제품/Godot/GUI/Job 실행 없음.

원문의 `_restore`는 첫 적용에서 root contacts와 양 side 및 record의 target/packet 분리, target/source root 분리, module·fleet identity 및 repeat 무효과를 검사한다. 계획의 target/source side·record까지 별도 비교는 원문의 합성·변이 검사를 보강하는 새 요구이므로, 원문이 이미 해당 모든 쌍을 직접 검사한다고 말하지 않는다. 비교할 ID와 container 존재는 승인된 fixture 및 packet의 typed 원문에서 도출하고 빈 쪽은 독립적으로 예상된 경우에만 허용한다. 성공한 기존 호출의 결과·_check 순서와 5회 호출/segment를 유지한다.

원문의 기존 변이는 `packet.detection.contacts[0][id].pos = Vector2.ZERO` 한 번이다. 그 전후 source/target `_all` 및 packet raw를 같은 request·tick에 묶고 값 동등성 외 별도 `is_same` 결과를 수집하는 계획은 목적에 부합한다. `_suffix`는 각 반복마다 A/B `step` 후 fingerprint와 `_all`을 비교한 다음 A/B의 `drain_events`를 각각 한 번 호출한다. 새 관측은 이 정확한 순서를 보존해야 하며 기존 반환 배열을 한 번만 잡아 비교하고 추가 drain/step/command를 금지한다. command-log와 queue는 관측만 하며 의미 있는 예상값 또는 비교 기준을 별도로 명시한다. 기록량·직렬화/호출 부작용·실제 시간 상한과 실패/출력 누락은 실행 전 검토 및 실행 시 실패 조건이다.

제시된 문서는 **control manifest 자체가 아니라 그것을 만들기 위한 요건**이다. typed fixture/roster·기대 pair/period·mutation path 및 값, 외부 control과 hand-authored boundary transcript의 정확 bytes/SHA가 아직 없으므로 ‘동결된 control 수용’은 지금 할 수 없다. 먼저 구현자와 독립인 control 작성자가 그 유한 산출물을 고정한다. 그 다음 한 격리 변경 세트에서 overlay/schema/validator를 만들고 요청된 same-wrong-config·alias true·변이/외부 상태·suffix/event/command·false result 반례를 실제 해당 게이트로 거부하는지 검토한다. Synthetic generator와 candidate가 control literals나 예상 transcript를 공유해 같은 오류를 재생산하지 않게 한다. 이는 실제 producer와 엔진 결과의 대용이 아니다.

기존 Python K3 실패 및 K6 한 회를 보존한다. 제품 fixture/import 사전 실행은 하지 않으며 실제 product producer 최초 실행이 K6 소진점이다. 21행·GUI provenance·프로세스 소유·실행 비용이 미완성이므로 이 설계 수용은 제품 launch 허가가 아니다. HEAD/index와 P03 +9·worker +2 등 보호 입력은 직전 재확인하고, HEAD lane은 P03 활성본 결합을 증명하지 않는다. 단일 세션의 구현·정적/합성 검토는 이 범위에서 진행 가능하다.
