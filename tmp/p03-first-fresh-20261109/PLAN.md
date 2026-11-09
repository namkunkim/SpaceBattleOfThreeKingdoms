# P03 첫 PC 작전 fresh capability 사전 계획

2026-11-09 KST. [첫 작전 계약](../pc-first-operation-contract-20261109/CONTRACT.md)과 [통합 체크리스트](../../docs/battle-core/pc-campaign-design/SESSION-REQUIREMENTS-CHECKLIST-20261031.md)를 재사용한다. 이 계획의 합성 준비와 제품 데이터 채택을 별도로 판정한다. 제품 첫 플레이 NOT_READY, 외부 저장 스키마 UNCLASSIFIED.

## 확정된 경계

P03은 source 입력의 독립 fresh 후보 준비, 권위 상태와 논리 시계, 초기 배치의 검사 근거를 제공한다. P05는 동일 effective의 공간 및 승인 외곽 판정, P02는 WorldMap 입력과 FleetBattle3D 게시·전환·기존 화면 상태, P07은 진행 중 보급·증원·결산 계약을 담당한다. 제품 fresh의 성공은 같은 시점의 owner·시계·첫 투영/사건을 함께 게시하는 인수이며, 격리 후보 결과는 이 중 준비 증거다.

현재 제한 adapter와 제한 owner의 입력 거부를 유지한다. 제품 경로에 legacy 확대·튜닝·자동편성·profile patch·fallback을 섞지 않는다. raw sim의 비공개 필드를 외부에서 대입해 지원을 가장하지 않는다. E는 실제 아군 초기 배치, C는 실제 초기 수비이며 R은 유효한 증원 대기 정의다. CAO04와 CAO05는 서로 다른 ID를 사용한다. 초기 준비에서 R을 실제로 투입하거나 시간 증원을 완료 처리하지 않는다.

## 최소 입출력 제안

입력은 명시적 operation 표식, source ID와 버전 및 정의 바이트/digest, 선택된 승인 roster ID 및 출처, seed, 난이도 ID와 적용 출처의 묶음이다. roster는 E 두 아군 그룹, C 수비 그룹, R 대기 그룹을 식별한다. 별도의 공간/외곽 버전과 시작 pose·controls·논리 주파수는 이 입력에서 재현 가능하게 한다. 지도 표시 anchor와 edge label은 논리 위치 입력으로 사용하지 않는다. 제품 키 이름과 직렬 형식, 타입과 허용값은 채택 전 미정이다.

준비기는 source 원본과 별개 객체로 effective를 만들고 source/effective digest와 변환 식별자를 기록한다. 후보 범위의 승인된 identity 변환은 `(0,0)`과 `1700×1150`에서 한 번만 적용한다. 표식 불일치, 미지원 버전/roster/난이도, 비영 원점, effective 재제출을 구분해 경로가 있는 거부를 제공한다. 원본 source와 입력을 변조하지 않는다.

성공 결과 후보는 별도 owner 한 개, 논리 tick/clock과 초기 controls, E/C 배치의 ID·중심·heading·formation 및 첫 side-filter 복사 투영, R의 대기 기록·pose/외곽 검증 결과, 첫 ordered 사건과 source/effective digest를 전달한다. 준비기에서 이전 live owner를 읽거나 닫을 필요가 없다. 부분 준비 또는 검증 실패에서는 생성한 후보만 닫고 구조화 오류를 반환한다. 성공 후보는 준비기에서 P02의 게시 트랜잭션으로 소유권을 한 번 넘기며, 게시 실패·취소 시 후보 정리를 책임질 소유자를 반환 계약에 명시한다.

## 합성으로 준비 가능한 독립 조각

전용 경로에서만 사용할 명시적 synthetic source·roster를 사전등록한다. E/C/R 공간과 그룹의 순서는 독립 기대값에서 직접 계산하고, P05 채택 외곽 모델의 경계·자세 의미는 정본을 대조한다. 제품 측정 숫자나 배치 좌표를 합성 fixture의 제품 증거로 승격하지 않는다. 첫 합성 계획의 종료는 아래 표의 비교 방법, 거부 종류, 예상 결과와 실패의 정리 책임까지다. 엔진이나 원본 import를 하지 않는다.

| 사례 | 기대값과 독립 비교 |
|---|---|
| same_source_seed_independent_fresh | 같은 source·버전·roster·난이도·seed로 후보 A/B를 독립 생성. owner identity가 다르고 source/effective digest·초기 tick/clock·controls·ordered projection/events가 일치. A를 전진하고 닫은 뒤 B의 초기 상태·사건 및 source 바이트가 불변 |
| effective_resubmit_rejected | 성공에서 나온 effective를 source 위치에 재제출. 첫 변환 전 정확한 경로의 구조화 거부, 기존 source digest 및 A/B 불변 |
| placement_E_C_R | E 아군 두 그룹과 C 수비의 예상 ID·pose·초기 실제 존재, 승인 외곽의 영역 포함을 비교. R 지정 증원은 pose/외곽 수용 판정과 대기 상태만 확인하고 roster 내 부재 및 C/R ID 불일치를 대조 |
| invalid_input_and_placement | 지원 표식/버전/roster/난이도·비영 원점·E/R 경계 한 항목만 각각 변이. 최초 실패 위치와 반환 및 부분 후보 정리를 확인 |
| failed_prepare_keeps_live | 기존 owner, 논리 clock, 두 host 누산기, 대기 명령, 미소비 사건, 선택·표시 및 Brief/Outcome을 준비 거부 전후와 정상 재시도에서 대조. 실패로 기존 owner를 닫거나 사건을 소비하지 않는지 확인 |
| successful_publish_handoff | 검증된 후보만 한 번 게시. 기존 owner는 성공 게시 뒤에만 닫히며 다음 명령이 새 owner에만 도달. 시계와 첫 투영/사건의 기준 tick 일치 및 초기 raw drain에서 packet 사건을 지우지 않는지 비교 |

마지막 두 항목은 합성 host 대조군 또는 준비 반환의 수명 검증으로 설계할 수 있으나 실제 FleetBattle3D/WorldMap 인수는 P02 공개 제품 경로와 쓰기 창이 선행한다. 같은 frame에서 시간의 정상 경과와 거부 이동의 무게시를 분리하는 이동 oracle은 이 초기 준비 조각과 별도다.

## 데이터 결정과 다음 인계

- **확정 근거**는 외곽 ID `p05-layout-disks-v1`, 중심 편차 2와 별도 안전 여유 1 및 제한 합성 검증의 측정 범위다. 첫 제품 source/roster v1과 후보 좌표·반경·자세·난이도 채택은 대기 중이다.
- **제안**은 E의 LIU01 39/LIU02 21, C의 CAO04 45, R의 CAO05 30 측정 편성을 채택 후보로 삼고, 독립 geometry oracle에서 해당 외곽·heading을 동결하는 방식이다. 지도·편성·난이도 정본이 따로 지정되면 그 승인 입력에서 다시 기대값을 도출한다.
- **착수 조건**은 사용자가 제품 source/roster 및 난이도 출처를 채택한 기록, P02/P03/P05/P07 파일·함수 소유와 쓰기 창, 입력 형식과 오류 이름·우선순위, 첫 게시의 owner·clock·사건 인수 계약이다. 이후 명명 사례별 정확한 단언 분모, 모든 입력 바이트/SHA, 실행 엔진과 fixture, 실제 exit·timeout·진단·보존 범위를 고정한다. 코드 실행 상한 K6.

GPT-6 Sol 독립 계획 수용 전 구현과 실행은 시작하지 않는다. 이 계획에서는 전용 문서만 작성하며 공유 제품 파일, 엔진·원본 import, Git 커밋·푸시는 범위 밖이다. 외부 저장과 P04, P09 및 이후 P07 효과·결산은 각각 별도 인수다.
