# P03 보급 진행량 두 표현의 동시 변형 관측 계획

2026-11-08 KST. **독립 계획 심사 대기, 코드/Godot 미착수, K6=0.** Sol 실행 / Terra 독립 심사 명시 배정, Astra 제외. [한 표현 변경의 실제 거부](../p03-supply-mixed-boundary-20261108/RESULT.md)

기존 C는 service 쪽 `sup_prog`만 바꿔 `restored_state_mismatch`로 거부됐다. `OperationPrivateState.observe`는 같은 FleetState에서 전체 fleet view와 service slice를 모두 만들며 restore는 SUP_FIELDS를 service에 위임한다. 이번 D는 두 표현의 값만 서로 맞추어, 앞선 거부가 중복 표현 일치만 확인한 것인지 시간 혼합까지 판정하는지 관측한다. **직접 조작한 packet** 시험이다. 동기 capture 중 자연스럽게 찢어진 capture가 생성됐다거나 운영의 동시 저장 결함을 실증하는 범위가 아니다.

이전 정상 fixture와 독립 raw twin, 실제 tick599 직전 A와 tick600 repair 후 B의 물자8→7·중파2→1·누계1을 같은 제한 입력으로 다시 만든다. 자동 공격 억제 및 4척 손상 배열의 통제 조건을 유지한다. B는 첫 repair 사건을 drain한 후의 실제 snapshot이다. B의 다음 정상 step은 추가 repair/지출 없이 진행량만 증가해야 한다. A/B와 과거 산출물을 수정하지 않는다.

| 이름 | 입력과 오라클 |
|---|---|
| mirror_prog_01_actual_A_B_control | 실제 A/B와 원시 twin, 정합 B→다음 한 step을 검증. B의 두 표현 모두 progress 0, A의 양쪽 모두 need-rate, 나머지 정상 차이는 기존 fixture의 실제 완료와 동일 |
| mirror_prog_02_two_paths_one_value | D는 B 복제에서 손님2의 `view.fleets[1].sup_prog`와 `view.service.supply.fleets[1].values.sup_prog`만 A의 실제 값으로 변경. 두 ID가 손님2이고 역치환 뒤 B와 exact 일치, A/B/D 불변 |
| mirror_prog_03_restore_and_classify | 실제 restore 응답. 정확 원자 거부면 기존 active/packet/ready/busy와 다음 정상 step을 대조. 수용이면 동일 handle/new sim/정본 binding, actual capture가 D와 exact, 진입 상태에서 두 progress 표현과 B의 시간/자원/누계/사건 유지 |
| mirror_prog_04_one_step_effect | 수용 뒤 실제 advance 한 번의 repair/지출/누계와 typed ordered 사건을 정합 B 분기 및 literal으로 비교. 거부면 B와 같은 다음 step 보존을 확인하고 조기 완료는 미실행으로 분리 |

판정은 `REJECTED_ATOMIC`, `ACCEPTED_EARLY_COMPLETION`, `ACCEPTED_NO_EARLY_COMPLETION` 셋의 실제 결과다. 절차 성공과 운영 checkpoint 정책을 구분하고 사전조건 실패나 관측 외 결과는 actual gate nonzero다. K6는 신규 명명4/fixture1 분모이며 기존 4/K6과 별도다. 엔진 console/본체 SHA와 runtime PID/경로, 정본 class map/실제 Script, 전용 Job, 입력/runner SHA 전후, raw 출력·실제 exit/diagnostics, 새 dirty 분모와 refs/index를 고정한다. 계획/오라클 변경은 독립 재심, 사용량 제한 즉시보고·반복 금지.

P02 실제 화면 초기화의 공유 경로, core Supply/Private/Service, 기존 체크리스트는 읽기만 한다. 새 전용 테스트 폴더만 쓰고 외부 schema/글로벌 cursor/commit/제품 정책을 결정하지 않는다. Dictionary 6 MISMATCH 및 접촉 만료 공개 정책은 별도 열린 항목이다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED.
