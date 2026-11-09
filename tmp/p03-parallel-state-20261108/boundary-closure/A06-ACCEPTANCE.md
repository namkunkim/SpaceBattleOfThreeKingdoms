# A06 단일 조합 인수표

**UNEXECUTED.** 이 표는 K05–K07 및 A06 원문의 운영 조건을 다음 단계에서 받아들이기 위한 검사 분해다. 12행은 이 조각의 설계 단위이며 정본이 같은 이름을 정의하지는 않는다. raw drain과 filtered drain은 동일 큐를 소비하는 대안적 경로다. 양쪽을 비교할 때 같은 소비 전 상태에서 각각 출발한다.

| 고정 절단점 | 검사할 상태 | 책임과 현재 경계 |
|---|---|---|
| capture 직전 | seq1·2 반영, 마지막 적용 seq=2의 계약, seq3만 pending 또는 동일 seq3을 suffix로 받는 대조, 활성 projectile의 ID/src/target/남은 진행, 이미 처리한 외부 효과 키 한 개 | core owner가 논리 상태와 사건 큐를 제공. 전역 seq 및 처리키의 저장 권위는 POLICY_REQUIRED |
| capture 직후 | 원자적 snapshot과 live 상태·순서 동일, pending/suffix 이중 반영 없음, 이미 외부 소비한 효과의 식별자와 권위 유지 | host/owner 경계에서 packet 발행 및 오염 판정 계약 필요. 저장/외부 키 범위는 O07에 남김 |
| 복원 후 동일 suffix | seq1/2 재적용 없음, seq3 한 번 적용, projectile의 src/target이 새 roster로 해석되고 후속 결과·사건의 순서가 이어짐 | 제한 owner의 개별 suffix·projectile은 구성 근거. 이 조합과 외부 cursor는 미실행 |
| 외부 ack 전 실패 | 내부 효과가 만들어졌으나 ack 전이라는 사실을 보존, 이전 active host/UI 및 외부 전달 이력과 다음 시도 가능 상태를 비교 | P02 host와 외부 delivery/저장 소유자 공동 인수 필요. 처리·게시·ack 중 어느 지점이 commit인지 POLICY_REQUIRED |
| 재시도 | 누락/중복 없이 의도한 효과 한 번, durable cursor와 applied/pending의 일관성, 종료·공개 결과의 안정성 | 외부 ack/idempotency key·승자 결정·스키마 합의 후 별도 독립 fixture. 현재 외부 효과를 주입한 실험은 없음 |

[정본 K05–K07와 A06](../../../docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md)의 권고와 현재 구현을 구분한다. [제한 suffix](../../p03-command-suffix-20261107/REVIEW-5B-attempt-05.md), [미사일](../projectile-target/REVIEW-CLOSEOUT.md), [viewer 큐](../../p03-viewer-checkpoint-20261108/REVIEW-CLOSEOUT.md), [cursor attempt-03](../../p03-parallel-cursor-20261108/remaining-cursor-drain/REVIEW-ATTEMPT-03-CLOSEOUT-TERRA.md)는 부분 근거다. cursor attempt-03의 32 확인과 actual exit 0은 공식 5a 통과가 아니다. P03 NOT_READY, O07 OPEN, 외부 스키마 UNCLASSIFIED.
