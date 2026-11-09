# P02/P03 현재 경로와 공동 인수

현재 결정, 관측 및 미래 계약을 분리했다. [35셀 원장](POLICY-LEDGER.json)의 decided 필드는 출처가 확정한 제한 동작과 현재 관측을 기록한다. 확정된 운영 정책은 이 필드로 추론하지 않는다.

| 경계 | 현재 책임과 근거 수준 | 공동 인수 |
|---|---|---|
| 제한 worker | P02 worker가 제한 adapter에서 fresh owner를 만들어 소유 스레드에서 전진·drain·종료한다. P03 owner의 역할은 논리 상태·가드·private packet이다. 제품 WorldMap에서 같은 owner를 운용한다는 근거는 없다. | 실제 제품 WorldMap에서 입력, 시작·취소·join, 이전 결과 보존, 게시, 결산 의미를 정해야 한다. |
| 제한 fresh replay | P02 CLI의 fresh owner에 명시 명령을 배열 순서로 적용한다. 지역 소비 수와 결과 DTO는 제한 수용. | 제품 replay 진입과 초기화/명령/사건 소유자, 운영 restore/seq/durable 계약을 별도로 결정한다. |
| legacy WorldMap 결산 | 기존 AutoResolver에서 worker 결과를 받고 main join 뒤 게시한다. BattleOutcome은 결산 사실의 소비 경계다. legacy 사본과 전이만 한정 수용. | 제품 operation worker/owner 결과로 이어지는 배선, WorldLink 처리키·중복/유실과 외부 ack의 실제 경계를 입증한다. |
| legacy FleetBattle3D 후보·실패 | raw host가 후보를 구성하고 자신의 sim/표시를 게시한다. 준비 실패와 최초 탈출의 독립 마감은 legacy에 한정된다. | 제품에서 제한 복원을 제공할지 먼저 결정하고, 제공한다면 성공/실패의 이전 UI·active owner 보존과 전경 상태를 독립 검증한다. |
| 표시용 사건 회수 | 제한 private owner의 filtered drain은 기존 필터와 같은 큐를 소진한다. raw drain은 대안 소비다. side0 UI 격리 결과에서 접촉 표식이 지워져도 none payload에는 실제 숨은 좌표가 존재했다. | projection의 표시 권위, filtered payload 허용 필드, 외부 전달 보장은 독립 결정이다. 선택 제거·drag/ref 수명과 양측 소비를 따로 입증한다. |
| 활성 모듈·오염 packet | 제품 raw constructor와 제한 owner가 별도다. 강제 DecisionBoard 주입 반례와 의미상 이전인 두 Supply 표현의 수용은 제한 관측이다. | 실제 도달과 packet provenance를 확인하고, 지원 밖 active 상태의 원자 거부 또는 지원 확대를 선택한다. 의미상 혼합/오염 입력 허용을 별도 계약화한다. |
| 외부 상태 | D04는 저장 전략, 버전, 원문 표현을 후보로 정리하고 H1의 사용자 결정을 요구한다. K05–K07은 커서·commit에 대한 권고이며 현재 구현을 기술하지 않는다. | D04/O07과 실제 P02 소비자, P03 state owner가 선택 기준을 수용해야 한다. 결합 fixture는 log/pending/projectile까지만 관측했다. |

P02 진행표에서 여섯째와 일곱째 조각의 독립 마감은 한정 수용이다. 여덟째의 격리 후보는 원본 미적용이다. 이후 K6 실행 계약 v2는 행 14/16 계획만 수용했으며, 준비 V2 심사는 manifest·GUI/coverage 보완 전 실행 보류다. 이 기록들은 제품 operation, 제품 UI 또는 확정 운영 계약을 승인하지 않는다. 기존 중단 인계를 대체하는 실행 완료 증거는 동결 범위에서 확인하지 못했다. 근거는 SOURCES.sha256에 고정했다.

우선 인수 순서는 제품 host 지원 범위와 소유권, 현재/실제 접촉 소비와 외부 전달 대상 조사, 공개 권위 및 payload 정책, O07 저장/버전/처리 키 결정이다. 하나의 선택을 다른 축의 대안으로 제시하지 않는다. 예를 들어 projection만 위치 권위로 두면서 filtered payload에 마지막 공개 위치를 명문화하는 조합은 가능하다. 두 선택 각각의 합의와 테스트가 필요하다.
