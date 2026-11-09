# P03 보급 완료 전후 혼합 packet 관측 계획

2026-11-08 KST. **독립 계획 심사 대기, 테스트/Godot 미착수, K6=0.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외. [Supply 원장](../p03-supply-ledger-20261108/SUPPLY-STATE-LEDGER.md)

P2b는 slice 밖 상태가 맞춰진 준비 대상에 SUP_FIELDS를 복원했다. 기존 활성교체는 일관된 완료 전 packet에서 같은 완료·재고 지출을 재현했다. 이 후보는 **실제 완료 후 상태에 완료 전 진행량만 되돌린** 단일 변이의 허용·거부 및 다음 step 차이를 관측한다. 사전검증은 현재 `sup_prog`의 타입/비음수 등을 검사하지만 완료 시점의 다른 자원과 같은 commit인지 여부는 이 범위의 별도 질문이다. P02 공급 완료 E2E나 외부 저장 정책을 판정하지 않는다.

## 실제 fixture와 한 가지 변이

기존 활성교체 services의 제한 typed profile을 읽기 참조한다. ally 공급함 1번(SHP-05 두 척 포함), 손님 2번(SHP-04 네 척), 상대 3번, seed7/hz10, 같은 진영과 보급 반경 안, 초기 ammo/charge는 가득 찬 상태를 필수 확인한다. fixture에서 기존 테스트처럼 큰 ai_timer/next_fire를 넣어 자동 공격을 억제한다. 손님의 SHP-04 손상 배열만 [2,0,2,0,0]으로 통제하고 hit_tick=-1 및 충분한 재고를 확인한다. 실제 피해 유도나 생산 시작 상태의 증거가 아니다. 보급 step, progress, stock, event와 supplied는 직접 쓰지 않는다. 독립 raw twin도 같은 typed 입력과 초기 통제를 쓴다.

실제 advance로 진행량 `need-rate`의 완료 전 packet A를 capture한다. 실제 다음 한 step에서 첫 repair 완료 및 손님 중파 2→1, supplier 물자 `S.repair.materials`만큼 차감, `supplied=1`, `sup_prog=0`, repair=1인 supply 사건 정확히 하나를 수기/원시 twin과 대조한다. ammo/charge 지급이 관측되거나 수리만 일어나는 전제가 깨지면 절차 실패다. 그때 완료 사건을 drain한 후 같은 시점의 post packet B를 capture한다.

후보 C는 B의 깊은 사본에서 **손님 2의 `view.service.supply.fleets` 내 `values.sup_prog` 한 값만** A의 실제 완료 전 수치로 바꾼다. 나머지 필드와 B 원본의 exact 동일을 독립 오라클로 확인한다. 시간/context, 현재 공급원 ID, stock, stages, 누계·이벤트는 B를 유지한다. 실제 owner에 C의 `restore_completed`를 호출한다. 이 검사에서 제품 계약의 새 거부 정책을 정하지 않는다.

| 명명 | 독립 판정 |
|---|---|
| supply_mix_01_actual_completion | A→실제 첫 완료→B. source/target IDs, 보급금액·중파/경파·누계·사건 순서 및 raw twin 비교 |
| supply_mix_02_consistent_post_control | B를 동일 handle에 복원 후 한 step. 같은 조건에서 정상 진행만 다시 쌓이고 두 번째 즉시 repair/지출/supply 사건은 없다. 처음부터 맞게 진행한 native twin과 exact |
| supply_mix_03_mixed_acceptance | 실제 C 성공/거부와 오류 reason. 거부면 기존 active/packet/busy 보존과 다음 정상 advance 확인. 수용이면 새 sim과 단일 progress 변이, 입력 불변 확인 |
| supply_mix_04_mixed_next_step | C가 수용된 경우 같은 한 step에서 추가 repair/지출/누계/사건을 B와 exact 대조. C가 거부된 경우 정상 경로의 무변이로 명시 분류 |

`REJECTED_ATOMIC`, `ACCEPTED_EARLY_COMPLETION`, `ACCEPTED_NO_EARLY_COMPLETION`은 각각 증거로 입증된 경우만 기록한다. 다른 출력, 정합 B control 실패, ref/packet 불변 실패는 절차 실패다. 측정 절차 actual exit0은 저장 원자성의 전체 PASS가 아니다. 명명4/fixture1/실제 단언을 별도 기록한다. engine console/본체, class map 실제 Script identity, 전용 Job, runner·전이 데이터 SHA 직전/직후 및 actual exit/diagnostics/dirty 분모의 기존 전용 게이트를 따른다.

쓰기 범위는 이 전용 폴더뿐이다. P02 화면 초기화 작업과 공유 SupplyCore/owner/adapter/host/replay/체크리스트를 읽기만 한다. 정책/스키마/글로벌 cursor/커밋 번호는 결정하지 않는다. 독립 계획 수용 전 실행 금지. 새 K6, 실패 로그 보존, 사용량 제한 즉시 보고·반복 금지. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
