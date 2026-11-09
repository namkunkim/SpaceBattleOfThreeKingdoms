# FX-S A06 증거 분모와 미결 전제

I01-ACCEPTANCE-PREREG-20261026.md:83의 A06과 PR02/PR05(92,95행)는 통합 FX-S 상태·효과 인수의 정본 요구다. I01-READINESS-DECISION-20261026.md:19–22의 K05~K08은 준비 경계와 규약 권고다. H2-DECISION.md:12의 H2-02는 저장·재개 방향을 확정했고 저장 커서·커밋·호환 기술은 미결이다. D04-STATE.md:50,66의 ST02/ST18은 논리 시간, 적용 커서, 효과 및 게시/지급 커서의 책임을 구분한다.

| ID | 정본 요구 | 증거 분류와 실제 출처 | 미결 전제와 다음 소유 판단 |
|---|---|---|---|
| FXS1 | ST 필드사전 및 snapshot/suffix/ID 참조표 | 독립 제한 관측. p03-state-checkpoint-20261105/REVIEW-CLOSEOUT.md의 선언 감지와 분모 대조. 선언 존재 및 감지는 모든 필드의 운영 복원 수용과 다르다. | 운영 Cn 지원 모듈·파생 재생성·host 필드와 자료형/참조를 포함한 ST 전수 동결은 미확인이다. 코어·호스트 소유자가 지원 범위를 공동 확정한다. |
| FXS2 | seq1/2 적용, last_applied_seq=2, pending/suffix seq3 한 번 적용 | 독립 제한 관측. REVIEW-5B-ATTEMPT-05-TERRA.md의 순서·중복·누락 fixture. command-packet-integrity/REVIEW-5B-TERRA.md는 정적 구조·시간 검사 경계를 다룬다. | 제품 명령 식별자, 전역 적용 커서, 대기열과 외부 suffix의 절단점/권위가 미결이다. 명령 ingress/적용 소유자가 seq3의 이중 출처를 한 번 적용하는 실제 fixture를 정의한다. |
| FXS3 | 논리 clock 보존과 완료 경계 | 독립 제한 관측. p03-terminal-boundary-20261108/REVIEW-CLOSEOUT.md의 첫 하위걸음 종료와 복원. K07은 step 반환 또는 step 밖 issue 완료와 별도 commit_seq 권고를 구분한다. | host clock과 코어 논리 시간의 계약, 운영 적용/효과/게시의 커밋 관측점을 합의해야 한다. |
| FXS4 | 활성 투사체와 ID 참조 재결합 | 정적 관측. operation_private_state.gd:444–446의 ID 범위·중복, src_id/target_id 및 side 검사. 독립 제한 역사 실행 근거로 I01B-P2C-RESULT-20261101.md와 I01B-ACTIVE-REPLACE-RESULT-20261104.md가 있다. tests/i01b_private_state.gd:146–151,238–242,313–317의 실제 missile/swarm·lifetime 및 후보 결함 입력과 tests/i01b_active_replace.gd:129–133,187–198의 활성 교체 범위를 연결한다. | 더 넓은 모듈·외부 참조의 소유자와 제품 Cn 전체 참조표는 미확인이다. 제한 src/target 사례를 전체 관계의 독립 커버리지로 집계하지 않는다. |
| FXS5 | owner_epoch, 호환 거부, 활성 owner 보존 | 독립 제한 관측. I01B-ACTIVE-REPLACE-RESULT-20261104.md의 동일 context 교체 및 거부. lifecycle-readonly/REVIEW-5B-TERRA.md는 가드/DTO의 정적 대조다. | context 비교는 운영 epoch 발급·대체·오래된 입력 거부 계약을 제공하지 않는다. 제품 runtime과 host 소유자가 epoch 수명 및 활성 호스트 교체 경계를 합의한다. |
| FXS6 | event 효과 키 및 실제 완료 | 독립 제한 관측. REVIEW-5B-ATTEMPT-05-TERRA.md의 외부 Array 재수신. 정적 관측. a06-outcome-ownership/INDEPENDENT-CLOSEOUT-TERRA.md의 반환·표시. 가상 모델. a06-effect-completion/INDEPENDENT-CLOSEOUT-TERRA.md의 표식만 남은 실패와 중복 효과. | 실제 운영 효과 소유자, 완료 원장·원자성 또는 복구, 재시도/ACK 계약은 미결이다. 제품 지급 또는 실제 ACK 실행 관측이 없다. |
| FXS7 | 필수 누락·중복·참조·호환 거부 및 상태·효과의 독립 비교 | 제한 역사 실행. I01B-P2C-RESULT-20261101.md와 I01B-ACTIVE-REPLACE-RESULT-20261104.md의 정상/거부 분모 및 REVIEW-5B-ATTEMPT-05-TERRA.md의 순서·상태 비교가 별개로 있다. | 확정 ST, 실제 seq3 이중 출처, 운영 owner/효과를 같은 FX-S에 넣어 정상·실패·재시도 후 활성 상태와 실제 지급을 독립 관측해야 한다. 해당 통합 fixture는 미확인이다. |

## 과대 집계 반례 3개

1. **지역 log 길이를 적용 커서로 대입**. FXS2의 fixture에서 log/pending/suffix 순서는 증거가 있다. 전역 seq3의 동일성을 판단하려면 제품 seq 발급 및 pending/suffix 이중 전달을 넣고 실제 적용 횟수와 활성 상태를 비교해야 한다.
2. **표시 또는 처리 표식을 실제 지급으로 대입**. FXS6의 실제 Array와 정적 표시 흐름, 가상 효과 결과는 각각 범위가 다르다. 효과 소유자의 권위 있는 결과·누락/중복의 관측 및 처리 키와 함께 커밋되는지 확인할 오라클이 필요하다.
3. **동일-context 거부와 투사체 guard를 운영 epoch 및 전수 참조로 대입**. FXS4/5는 일부 로컬 참조와 기존 sim 보존을 다룬다. 명시 owner epoch와 지원 관계 전체를 담은 입력 및 교체 후 실제 host와 참조를 독립 확인해야 한다.

## 다음 최소 결정

첫 결정은 제품에서 하나의 대표 효과를 지정하고, 어느 소유자와 어떤 결과 기록이 그 효과의 완료를 증명하는지 합의하는 것이다. 이 결정 뒤 실제 표식만 남음/효과만 남음/재시도를 단일 FX-S 결과로 관측하는 사전등록안을 검토할 수 있다. 이 문서에서 효과를 선택하거나 저장·키·ACK·epoch·커밋 정책을 채택하지 않는다. 전체 A06 수용에는 나머지 FXS1~7의 운영 계약 및 단일 결합 fixture가 추가로 필요하다. P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
