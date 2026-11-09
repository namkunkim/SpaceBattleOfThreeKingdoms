# P03 SupplyCore 상태 책임 원장

2026-11-08 KST. 읽기 조사. [계획](PLAN.md) · [입력 원문 SHA](input-manifest.json). 이하 소스 경로는 `core/battle/` 기준이다. P02 화면 초기화 작업과 공통 owner를 변경하지 않는다. 현 보급 기지의 무한 공급과 미래 작전의 유한 시설 재고는 다른 계약이다. [D07](../../docs/battle-core/pc-campaign-design/D07-SUPPLY.md)

| 선언 | 타입·소유 및 갱신/소비 | 현재 복원 책임 |
|---|---|---|
| M01 `sim` | BattleSim 참조. `supply.gd:16,24–25`에서 공급 모듈을 만든 sim에 결합. `115–125,158–231` fleet·시계 및 `294–307` 사건 소비 | 새 sim을 생성해 참조 재결합. `battle_sim.gd:77–78`, `operation_service_state.gd:110–112` identity 확인 |
| M02 `S` | Dictionary, `supply.gd:17,24–26`의 combat.supply 별칭. `45–155,245–294`에서 함종·동맹·자원/시설 비용을 읽음 | 설정 내용 재구성, 새 SalvoCombat.C.supply에 재결합. service `111–121,136–146`의 내용·identity 근거 |
| M03 `ship` | String 보급함 함종 ID, `supply.gd:18,27,45–46`에서 설정의 함종을 정하고 유효 보급함을 셈 | 생성 시 재계산, service `121` 검증. fleet 내 실제 보급함 수와 다름 |
| M04 `need` | int bp·tick, `supply.gd:19,28`에서 정지 시간의 tick과 BP 곱. `225–231`의 완료 문턱 | 생성 시 재계산, service `122,145`. 실제 진행량은 `sup_prog`에 capture |
| M05 `light_ticks` | int tick, `supply.gd:20,29,296–307`의 마지막 피격 이후 자연 회복 문턱 | 생성 시 재계산, service `123` 검증. 마지막 피격 및 repair 상태는 별도 capture |
| M06 `still_eps` | float 거리/tick. `supply.gd:21,30,169–175`가 설정 거리/초를 hz로 나눠 지난 관측 위치와 비교 | 새 hz/config에서 재계산, service `124`. `sup_pos`/정지 시작 tick을 대체하지 않음 |
| M07 `bases` | Array 순서 있는 기지 record. `supply.gd:22,31–37`에서 config 순서로 key:String, faction:String, side:int, pos:Vector2 생성. `115–128,311–322`의 후보 순회/투영 | 순서·설정·roster로 재구성하고 service `125–133`에서 비교. 현재 기지에는 별도 유한 재고가 없다 |

## FleetState slice

`fleet_state.gd:115–124`의 아래 10개를 Service가 같은 roster 순서와 ID로 capture하고 detached 사본을 준비된 대상에 넣는다. Service의 사전검증 범위는 소스 존재 후보, 우선대상 ID, 정지 tick 범위, 비음수 재고/진행 및 필드 타입이다. `operation_service_state.gd:9,12–41,158–195`. 현재 배정이 다음 tick에도 유효하다는 보장은 아니다.

| 필드 | 타입·단위 및 갱신/소비 |
|---|---|
| S01 `sup_src` | String, 비어 있음 또는 기지 key/`f<id>`. `supply.gd:177–224`의 유지·실패 해제·배정. `225–231,324–326`에서 완료 및 표시 |
| S02 `sup_prog` | int bp·tick. `177–184,221–231`에서 취소/새 배정/완료 후 0, 활성 공급원 rate만큼 증가. `324–326`은 초로 투영 |
| S03 `sup_since` | int 논리 tick, 이동 중 -1. `169–175` 정지 시작, `192–201` 정지 우선순위. 벽시간이나 현재 tick으로 교체 금지 |
| S04 `sup_still` | bool. `169–175`에서 이번 판정 결과 저장, `138–143,186–190`가 서비스 자격/후보 조건으로 읽음 |
| S05 `sup_pos` | Vector2 직전 판정 위치. `41–42,169–170` 초기화/갱신. 현재 f.pos와 독립적으로 다음 정지 판정에 필요 |
| S06 `sup_n` | int 직전 보급함 수. `38–42,162–168`에서 초기화 및 감소 시 재고 비례 축소 분모. `133–136,288–290` 재적재 한도 |
| S07 `sup_ammo` | int 공급원 탄약. `39–40,165–168` 초기/손실, `245–290` 지출 및 기지 재적재, `311–326` 자기 진영 투영 |
| S08 `sup_mat` | int 공급원 물자. S07과 초기/손실 경로 공유. `245–290`에서 refill/charge/repair 비용 차감, 재적재, 자기 진영 투영 |
| S09 `sup_hold` | bool 공급 중지. `383–387` 및 `battle_sim.gd:634` 수동 적용, `138–146,233–238` 자격/우선순위 |
| S10 `sup_first` | int 우선 대상 fleet ID 또는 -1. `372–381` 지정, `213–216,233–238` 선택, `292–293` 해당 주기 종료 시 해제 |

공급원은 매 step에서 `bases` 순서 다음 `st.fleets` 순서로 만든다. `sources()`는 살아 있고 보급함이 있는 함대를 `f<id>` key와 현재 객체로 결합한다. 기존 배정부터 자리표 `used`를 채우고, 빈자리 후보를 우선권→탄약 비율→정지 시작→fleet ID로 정렬한다. 가까운 공급원은 거리 strict 비교를 써 동률이면 선행 후보가 남는다. `used`와 `ratio`는 step 지역 파생값으로 지속 상태에 추가하지 않는다. `supply.gd:115–131,158–231`

## 완료에서 같이 바뀌는 네 묶음

| 묶음 | 실제 완료·소비 | 현재 복원 경계 |
|---|---|---|
| C01 탄약·charge | `supply.gd:245–272`가 손님 `ammo/wch` 상한을 읽고 공급원 탄약/물자를 차감. 에너지·열은 이 함수의 직접 지급 대상이 아님 | 손님 자원은 SUP_FIELDS 밖이며 제한 private fleet capture의 책임. 공급원 지출과 동일 경계 필요 |
| C02 손상·repair | `supply.gd:273–286`이 정렬된 함종에서 중파를 경파로 옮기고 `healed_mod` 누적. `296–307` 자연회복은 `hit_tick/healed_wound/stages`를 별도로 읽고 변경. `salvo.gd:690,810–811`의 다음 피격·손상 계산에 영향 | fleet 비대상 slice에 모두 복원. progress만 되돌린 뒤 치료를 다시 실행하면 상태가 달라질 수 있음 |
| C03 공급원·우선권 | `supply.gd:245–294`의 함대 공급원 지출, 동세력 기지에서의 보급함 재적재, `sup_first` 해제. 현재 기지 공급은 fleet=null 경로 | SUP_FIELDS의 stock/priority와 실제 자격·순서의 결합이 필요. 새 작전 유한 기지의 시설 재고/예약/환불 원장 없음 |
| C04 사건·누계 | `supply.gd:291–294`의 `supplied` 증가 및 typed event payload, `battle_sim.gd:214–215,974`의 step 생성·큐. `battle_projection.gd:16–20,79`의 자기 진영 표시와 별도 | `supplied`는 FleetState 비대상 slice, `_events`는 sim capture. 외부 게시/지급 ack 또는 영속 transaction은 별도 |

제한 private owner는 비대상 fleet/state/sim을 먼저 넣고 서비스 slice를 위임한다. Service의 restore는 복제·재할당이며 보급 step, 소비, 지출을 실행하지 않는다. `operation_private_state.gd:11,14,452–469` 및 service `30–41`. P2b 부분 복원과 P2c fresh 복원, 활성교체의 제한 실제 완료 재현을 근거로 삼는다. P02 첫 headless의 공급 완료 E2E는 별도 미관측이다. [P2b](../../docs/battle-core/pc-campaign-design/I01B-P2B-RESULT-20261031.md) · [P2c](../../docs/battle-core/pc-campaign-design/I01B-P2C-RESULT-20261101.md) · [활성교체](../../docs/battle-core/pc-campaign-design/I01B-ACTIVE-REPLACE-RESULT-20261104.md) · [P02 headless](../../docs/battle-core/pc-campaign-design/P02-FIRST-HEADLESS-RESULT-20261107.md)

1. **완료 지출과 진행의 엇갈림.** 완료 전 `sup_prog`에 완료 후 재고/손상을 섞은 후보는 다음 step에서 치료/지출을 다시 하거나 자격을 잃을 수 있다. 기존 활성교체는 일관된 packet의 완료를 재현했다. 혼합 packet/독립 지급 원장의 결과는 미실행이다.
2. **같은 거리의 공급원.** 같은 용량·거리·우선권이면 `sources` 배열의 선행 후보가 남는다. 기지/함대 순서만 변경했을 때 같은 ID·수치로도 결과가 바뀌는지 제한 fixture로 확인할 수 있다. 이번 조각은 소스만 조사했다.
3. **이탈 뒤의 stale 배정.** Service preflight는 roster 기반 `f<id>` 후보를 유지하고, 다음 step의 `sources/serviceable`은 사망·이동·중지 등을 다시 판단한다. 존재하는 ID와 지금 쓸 수 있는 공급원은 다르다. 이동/격침 직전·직후 packet과 다음 해제/재배정의 actual 시험은 별도다.

[D04 ST11/ST18](../../docs/battle-core/pc-campaign-design/D04-STATE.md)의 자원 지출·진행·사건 공동 경계는 전체 운영 계약에서 더 넓다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED. Godot 실행 및 제품 수정 없음.
