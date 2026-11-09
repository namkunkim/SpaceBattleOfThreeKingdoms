# 첫 PC 작전의 fresh 준비 계약

2026-11-09 KST · 1~3단계 제안 · 첫 제품 플레이 **NOT_READY** · 외부 저장 스키마 **UNCLASSIFIED**

## 1. 의도

천하지도 직접 출전 → FleetBattle3D → 천하지도 결산 경로에서 첫 작전 입력과 권위 상태를 연결한다. 첫 조각의 출구는 승인 입력의 fresh 준비, 초기 배치의 공간 판정, 성공 게시와 실패 보존이다. 정면/우회의 진행 중 보급·증원·결산과 Windows 플레이는 뒤 조각에서 인수한다. [통합 체크리스트 §0](../../docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md)

## 2. 경계와 책임

필드와 결과의 이름은 아래 의미를 전달하기 위한 제안이다. 최종 자료형·지원 값·오류 코드는 제품 데이터 동결 시 준비 경계와 함께 고정한다.

| 경계 | 현재 호출과 제한 | 제품 계약과 담당 |
|---|---|---|
| 천하지도 요청 | `WorldMapScreen.make_brief`는 seed·난이도·mode·표시 anchor/edge labels를 넣는다. `BattleBrief`의 기본 scenario_id와 직렬화에는 첫 작전 표식·정의 버전·편성 출처가 없다. [지도](../../view/world/world_map_screen.gd#L541) · [Brief](../../scripts/world/battle_brief.gd#L8) | P02가 직접 출전 확정 시 지원 표식, 정의 ID/버전, 승인 roster/선택의 출처와 식별자, seed, 난이도를 함께 동결한다. 표시용 anchor/edge labels는 그대로 표시용이다. 표식 없는 legacy 입력은 기존 계약을 따른다. 명시한 표식이나 선택이 미지원이면 준비 경계에서 오류 이유와 필드 경로를 돌려준다. |
| 정의 선택과 source → effective | `OperationProfile.build`는 합성 원과 fixture 검증의 준비기다. 기존 adapter의 `p02/restricted-headless/1`은 runtime-ready와 10 Hz, none/attack5만 받으며 definition, checkpoint, 미등록 필드를 거부한다. [정의 준비](../../core/battle/operation_profile.gd#L27) · [adapter](../../core/battle/operation_runtime_adapter.gd#L20) | P05는 버전·출처가 있는 source와 공간/외곽 식별자를 제공한다. P03의 좁은 제품 준비 경계가 지원 표식 및 정확한 정의·편성·난이도 조합을 확인한 뒤 별도 effective와 변환 식별자 및 원본/실효 digest를 만든다. P05 계획의 원점 (0,0)·1700×1150 identity는 승인 source로 확인하고 한 번만 적용한다. 비영 원점, effective 재제출, ID/버전 불일치를 거부한다. 노드·회랑·영역·효과 지형·배치가 같은 effective에 속한다. 작전 경로에는 legacy 확대·튜닝·자동편성·profile_patch·fallback을 적용하지 않는다. |
| fresh 후보 및 배치 | `FleetBattle3D._prepare_game`은 legacy raw BattleSim과 초기 controls를 만들며 `init_game`은 성공만 `_publish_game`에 넘긴다. 제한 owner의 `_profile_error`는 nonempty reinf/scenario/ai, 미지원 combat 및 정본 rules 이탈 등을 거부한다. [전장 준비](../../scripts/FleetBattle3D.gd#L176) · [raw 후보](../../scripts/FleetBattle3D.gd#L283) · [제한 owner](../../core/battle/operation_private_state.gd#L79) | P03이 별도 제품 지원 범위에서 독립 fresh 후보를 생성하고 초기 controls·시계·배치·첫 side 투영을 검사한다. 제한 adapter/owner의 가드 보존, raw sim 직접 변조 금지. E에서 아군 그룹 전체 외곽, C 초기 수비, R의 지정 증원 편성·외곽·자세·배치 가능성을 동일 effective로 검사한다. R은 첫 준비에서 진입 데이터로 검증하며 실제 CAO05 투입은 후속 논리시각과 진입 조건에 따른다. CAO04와 CAO05 ID를 분리한다. 실패하면 후보만 닫는다. |
| 게시·명령·공간 | `_publish_game`은 화면·시계를 재설정하며 `_process`와 `update_sim`은 두 누산 경로에서 raw sim을 전진시킨다. P05 native guard의 권위는 격리 검증 창에 한정된다. [게시](../../scripts/FleetBattle3D.gd#L336) · [진행](../../scripts/FleetBattle3D.gd#L500) · [P05 native](../../docs/battle-core/pc-campaign-design/P05-PC-NATIVE-ACCESS-RESULT-20261109.md) | P02는 후보 성공 뒤 owner·권위 시계 연결·첫 투영/사건 소비를 함께 게시하고 이전 owner를 닫는다. 작전 상태 전진은 P03 경계 하나를 사용하며 호스트는 side-filter 복사 투영을 읽는다. P05 순수 판정은 이전→제안 이동, 동시 그룹 swept 외곽·추종·경계·영역에 연결한다. 실패한 이동의 위치·heading/진형·route/영역 진행은 게시하지 않는다. 데모 이동 루프, 고정 수비 witness, 버튼을 제품 권위로 옮기지 않는다. |
| 전환 실패와 결산 인계 | `WorldLink.go_battle`은 즉시 장면 거절 시 Brief·Outcome·선택 설정을 복원한다. 장면 전환 뒤 최초 준비 실패 때 이전 지도 노드는 사라져 안전 복귀만으로 카드나 대기 결과가 되살아나지 않는다. `FleetBattle3D.back_to_world`는 legacy sim 결과를 읽고 지도는 `take_outcome`으로 꺼낸다. [WorldLink](../../scripts/world_link.gd#L18) · [전장 복귀](../../scripts/FleetBattle3D.gd#L453) · [P02 인계](../p02-pc-next3-20261109/P02-FIRST-OPERATION-HANDOFF-READINESS.md) | P02가 즉시 거절 rollback과 전환 후 준비 거부를 분리한다. 후자의 안전 복귀에 필요한 지도 선택·화면·대기 결과는 메모리 인계로 보존하고 성공한 복귀에서만 소비한다. 실패 후보가 새 결과를 게시하지 않는다. 기존 전장이 있으면 owner·시계·큐·선택을 보존한다. 후속 정상 종료의 결과는 P03이 확정한 동일 결산으로 전장과 지도에 전달하고 지도에 한 번 적용한다. |

### P05 입력의 채택 범위

채택된 논리 외곽은 `p05-layout-disks-v1`, 중심 편차는 2, 안전 여유는 별도 1이다. 측정은 LIU01 39척과 LIU02 21척의 FRM-01↔03 전환과 동시 운용, C 수비 CAO04 45척 FRM-04, R 증원 CAO05 30척 FRM-03에 적용됐다. 이 외곽을 적용할 첫 제품 편성 데이터의 출처를 동결해야 한다.

이격 134, 회랑 반폭 155, E 배치/철수 반경 155/75, A/B 서비스 75, R 배치 60, C 접근 320 및 시험의 좌표·자세·속도·회전 상한은 검증 후보 값이다. E/R 초기 배치 판정은 전체 팽창 외곽의 포함을, A/B 서비스와 E 철수 접근은 정지 조건과 개별 중심의 유효 영역 도달을 따로 확인한다. 채택된 product source에서 경계 포함과 허용 자세·정지·이탈 의미를 명시한다. [P05 제품 계획](../../docs/battle-core/pc-campaign-design/P05-PC-PRODUCT-INTEGRATION-PLAN-20261109.md) · [독립 검토](../../docs/battle-core/pc-campaign-design/REVIEW-P05-PC-PRODUCT-INTEGRATION-PLAN-20261109.md)

## 3. 분해와 출구

1. **제품 입력 동결.** P05/P03이 source ID·버전·필드·자세·배치 및 영역 의미를, P02/P03이 난이도·편성 출처와 선택 규칙을 한 입력 묶음으로 동결한다. P03/P05의 새 준비기나 판정 파일이 공유 호출부 수정 없이 독립 인수 가능한지 그때 판단한다. 본 조각의 제안이 쓰기 예약을 부여하지 않는다. P02 화면·전환, P03 상태·시계, P05 공간, P07 규칙·결산 소유에 따라 파일·함수·선후 및 쓰기 창을 확정한다. [P02 진행표](../../docs/battle-core/pc-campaign-design/P02-PROGRESS-CHECKLIST.md) · [조율안](../../docs/battle-core/pc-campaign-design/P02-P03-WRITE-COORDINATION-20261109.md)
2. **첫 조각 5-a.** 동결한 각 유효 seed에 대해 동일 source·버전·편성·난이도를 두 번 fresh 준비한다. 서로 다른 owner와 분리된 데이터에서 source/effective digest, tick/clock, E 아군과 C 수비의 배치·heading·controls, R 진입 정의와 대기 상태, 순서 있는 첫 투영/사건이 일치해야 한다. 원본 바이트와 첫 owner를 전진·닫기 전후의 둘째 후보를 대조해 공유 변조를 검출한다. 독립 오라클은 동결 입력과 승인 공간 규칙에서 ID·초기 배치·포함 경계를 직접 도출한다.
3. **첫 조각 반례.** 지원 밖 표식·버전·편성·난이도, effective 재제출, 비영 원점, E/R 외곽 수용 실패 및 제품 판정에 연결한 동시 이동 중간 침범/편차 초과에 구조화 거부를 확인한다. 준비 실패 전후 활성 owner·시계/누산기·큐/미소비 사건·UI/카메라·선택·Brief/Outcome을 비교한 뒤 정상 재시도를 확인한다. 이동 거부 시에는 정상적으로 흐르는 시간과 이동의 무게시를 동일 프레임 대조군으로 분리한다. 표식 없는 기존 직접 출전·자동·standalone의 기존 계약과 명시 표식의 fallback 금지를 별도 회귀로 확인한다. 동결 입력, 사례 수, timeout 및 기대 이유는 실행 전에 확정한다. 코드 실행은 K6, 독립 5-b와 기록은 구현 이후다.
4. **후속 작전과 PC 인수.** P07의 입출력을 P03 권위 상태에 적용하고 P02 실제 호스트·결산을 연결한다. 같은 작전 정의의 정면 목표 성공과 우회 후 명시 철수를 Windows 제품에서 확인한다. P04 저장·재개와 P09 BGM·종료 품질은 후속이다.

| 후속 P07 경계 | 입력 | 권위 출력 |
|---|---|---|
| A/B 가동 보급 | 현재 소유·가동·경합, 승인 서비스/정지, 부족량, 유한 재고와 거래 키 | 일반 탄약 지급·재고 차감·완료 사건 일회 커밋. 비가동·이탈·재고 부족 이유와 시각을 공개 범위 내 표시 |
| R 시간 증원 | 논리시계, 승인 임계·동시 규칙, 대기 편성 및 R 공간 수용 | 예정/대기/실제 진입을 분리하고 실제 진입과 사건을 한 번 커밋. legacy strict `>` 및 조기 증원은 기존 동작이며 제품 임계 계약은 별도 확정 |
| C 목표·명시 철수 | C 현재 통제, A/B 아군 통제·가동, 지휘 유효성 또는 명시 철수와 E 실제 생환/투입 원장 | 목표 성공·철수 성과·실패, 이유, terminal 논리시각, 손실·비용·이력 및 안정 결산 ID. 지휘 상실 동시는 실패 우선, 공개 시한과 같은 논리시각의 유효 목표·탈출 인정. 전투 결과와 지도는 같은 결산을 읽고 중복 반영하지 않는다. |

재고·단가·가동 조건, 실제 증원 일정, 생환 기준·시한, 전체 동일시각 순서는 미정이다. 약 20분은 비교 가설이다. [P07 계획](../../docs/battle-core/pc-campaign-design/P07-PC-FIRST-OPERATION-PLAN-20261109.md) · [독립 검토](../../docs/battle-core/pc-campaign-design/REVIEW-P07-PC-FIRST-OPERATION-PLAN-20261109.md)

**첫 구현을 차단하는 결정.** P05가 검증한 후보 지도·배치와 측정 편성을 첫 제품 source/roster v1의 동결 기준으로 채택할까요, 아니면 사용할 정본 지도·편성과 난이도 적용 출처를 지정할까요? 현재 근거는 위 외곽과 격리 접근까지다. 답이 정해지면 담당이 값·자료형·정확한 입력 바이트와 파일별 쓰기 창을 확정한다.
