# P03 우선순위 및 인수 인계

현재 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED. 이 문서는 전용 읽기 종합 및 다음 계획이다. 공유 체크리스트, 생산 코드, Git은 변경하지 않는다. 실행 모델은 자기 rollout 최신 turn 01a1ba80-c1b5-7882-b81d-17f0391890b6의 gpt-6.1-sol이다.

## 체크리스트와 최신 증거 연결

| 체크리스트 범위 | 현재 수용된 증거와 범위 | 미폐합 조건 |
|---|---|---|
| 선언·갱신·소비·복원 책임 | 기존 31파일/294 선언 감사와 네 파일 172개 누락 검사 독립 마감. S1과 S4 책임표, Detection/Supply/Chain/Skill/Decision 기존 원장, 적벽 기술 19/효과 33/고유 24 및 호출 후보 31행 마감 | 전체 필드·host·동적 record의 생산/소비/복원 disposition 행 단위 폐합. 294와 172는 중첩 분모. Skill 원장은 고정 원문이고 독립 소비 설명은 표본 심사 |
| 시간·ID·증원·투사체 | terminal 2/150, 제한 POC tick5→6/RNG 3주소, reinf_ms 단일 변이, raw 시각 증원, 미사일 target와 Swarm 첫 점 r 각 단일 변이의 독립 마감 | 실 운영 commit 시간·host 누산기, raw 전멸 증원, 활성 효과 및 S06~S12의 운영 복원, 전체 참조·입력 지원표. 두 projectile fixture는 같은 제한 맥락 |
| suffix·cursor·사건 | 제한 suffix 6/91, viewer 소비 전후 및 fresh replay A 소비/B 거부 독립 수용. lifecycle 11 공개 진입점과 반례 3개의 정적 5a 인계 | remaining cursor/drain의 attempt-03은 32 단언 통과·actual exit 0이지만 외부 status 때문에 5a 미통과. attempt-04는 현재 읽을 수 있는 preflight/시작 기록만 있고 결과/종료 증거가 없다. 실제 global cursor와 ack는 별도 계약 |
| 실패 원자성·Variant | 동일 context 교체, 제한 scenario·reinf_ms·projectile·Swarm 거부, Dictionary value metadata 수정과 22입력 회귀 수용 | guard 오류 우선순위 및 동시·비정상 상태 전체, publish 전후·외부 effects 원자성. 활성 DecisionBoard 강제 주입은 capture 거부·교체 소실 반례이며 자연 운영 도달 미입증 |
| P02 연결과 제품 | worker 관측, owner 운영 경계 정적 독립 마감, host 책임 원장. 별도 제품 resume의 Detection 격리 UI는 표식 제거와 side0 raw 숨은 좌표를 구분 | 운영 host–owner 배선·권위·실패 시 기존 UI 및 공개 좌표 정책. touch drag/선택 수명 동작 미실행. supply 자연 torn capture 및 외부 packet 정책 미판정 |
| 작업 절차 | 각 수용 조각에 계획/5a/독립 5b/closeout이 있고 실패 원문과 동시 변화는 범위별 보존 | 새 조각마다 실행 창, 실제 모델·정본 경로·동결 입력·Job·실제 exit를 독립 확인. 이번 종합은 기존 pass 또는 fail의 판정을 바꾸지 않는다 |

정본과 최신 근거

- [전체 체크리스트](../p03-progress-20261108/P03-CHECKLIST-REVISION-20261108.md), [인계](../p03-progress-20261108/HANDOFF-20261108.md), [D04](../../docs/battle-core/pc-campaign-design/D04-STATE.md), [I01 K05–K07·A06](../../docs/battle-core/pc-campaign-design/I01-READINESS-DECISION-20261026.md)
- 상태 세션 [선언](REVIEW-CLOSEOUT.md), [clock/RNG](clock-rng/REVIEW-CLOSEOUT.md), [reinf_ms](reinf-ms/REVIEW-CLOSEOUT.md), [raw 증원](raw-reinf-clock/REVIEW-CLOSEOUT.md), [미사일](projectile-target/REVIEW-CLOSEOUT.md), [Swarm](swarm-point/REVIEW-CLOSEOUT.md), [기술 효과](skill-effect-ledger/REVIEW-CLOSEOUT.md), [S1](STATE-LEDGER-S1.md), [S4](STATE-LEDGER-S4.md)
- 활성 세션 [worker 관측](../p03-parallel-active-20261108/WORKER-RESULT.md), [독립 마감](../p03-parallel-active-20261108/REVIEW-CLOSEOUT.md), [scenario 거부](../p03-parallel-active-20261108/owner-contract/cycle-02/REVIEW-CLOSEOUT.md), [운영 경계](../p03-parallel-active-20261108/owner-operational-boundary/REVIEW-CLOSEOUT.md)
- cursor 세션 [fresh replay 제한 수용](../p03-parallel-cursor-20261108/REVIEW-5B-V2-20261108.md), [attempt-03 보존 및 미통과](../p03-parallel-cursor-20261108/remaining-cursor-drain/REVIEW-ATTEMPT-03-CLOSEOUT-TERRA.md), [attempt-04 사전 기록](../p03-parallel-cursor-20261108/remaining-cursor-drain/attempt-04/preservation-preflight.json), [lifecycle 인계](../p03-parallel-cursor-20261108/remaining-cursor-drain/lifecycle-readonly/HANDOFF.md)
- 제품 세션 [초기 재개 중단](../p03-parallel-product-20261108/RESTART-STOP-20261108.md), [후속 정적 마감](../p03-product-resume-20261108/CLOSEOUT.md), [Detection UI 독립 마감](../p03-product-resume-20261108/DETECTION-UI-CLOSEOUT.md), [참조 수명](../p03-product-resume-20261108/REFERENCE-LIFETIME.md), [P02 공동 책임](../p03-host-responsibility-20261108/HOST-STATE-LEDGER.md)

## 우선순위

1. **필수 인수 조건.** 지원 가능한 C0와 운영 Cn/terminal·issue 완료 경계를 승인 기준에 연결한다. A06의 seq1/2 적용, seq3 pending/suffix, 활성 투사체와 처리키의 조합이 살아 있어야 한다. 현재 조각의 단일 반례를 더하는 것보다 지원/비지원/미분류 전수표와 입력 및 성공 조건의 폐합을 앞세운다. A04 제품 공간·A05 host 논리 시계는 별도 인수다.
2. **정책·소유권.** P02 host와 코어 owner가 게시 이전·이후 경계에서 책임질 인터페이스를 먼저 결정한다. 기존 활성 모듈을 가진 restore, 의미상 오래된/혼합 packet, raw/filtered 접촉 위치, 외부 drain·ack·idempotency·cursor와 durable schema는 이 합의가 선행된다. 자연 도달과 강제 주입 결과를 따로 비교한다. 해당 결정 없이는 운영 변경의 pass/fail 기준이 성립하지 않는다.
3. **독립 검증 우선.** cursor lifecycle 정적 5b 및 remaining-cursor의 정식 실행 창 조율을 분리한다. 후자는 모든 공유 작성 세션의 정지 확인과 long-path/exit 게이트의 사전 수용이 충족돼야 한다. 이미 승인된 단독 조각의 범위 표기를 보존하고 모델 메타가 확인되지 않은 과거 배정은 별도로 표시한다.

## 다음 인수에 직접 기여하는 조각 계획

**K06/K07 운영 체크포인트 경계표 한 장과 A06 조합 인수표**를 읽기 전용으로 만든다. 새 실험을 늘리기 전에 어떤 운영 계약을 결정하고 어떤 fixture가 그 결정을 판정할지 확정하는 조각이다. 소유 경로는 이 전용 폴더 아래 `boundary-closure/`뿐이다. 독립 계획 수용 전 원장 생성기, 자동 gate, 구현·실행은 보류한다.

- 고정 분모는 경계 12행이다. B0/부분 구성, C0 게시 직전, C0 게시 직후 첫 조작 전, 즉시 issue 반환, queue 반환, step 적용 중, step 정상 반환, terminal 하위 걸음 뒤 공개 반환, raw drain 전, raw drain 후, filtered drain 후, busy/종료된 owner 호출을 각각 1행으로 한다. 각 행에 권위자, 지금 관측 가능한 타입/상태, 현 지원 정책/근거, 요구 계약, 실패 원자성 및 독립 인수 기준을 기입한다. closed와 busy는 12번째 행의 별도 하위 상태로 명시한다.
- 외부 경계 4개를 별도 열로 고정한다. active owner/host 교체, UI 게시, 외부 사건·효과 전달, durable 저장/cursor다. 각 셀은 `SUPPORTED_EVIDENCE`, `REJECTED_EVIDENCE`, `POLICY_REQUIRED`, `UNCLASSIFIED` 중 하나와 source anchor를 갖는다. 정적 근거와 실제 관측을 태그로 분리한다. 무근거 정책/기대값은 빈칸 대신 POLICY_REQUIRED 또는 UNCLASSIFIED로 남긴다.
- A06 인수표에는 조합 1개를 고정한다. seq1/2 적용, seq3 대기 또는 suffix, 활성 projectile 및 이미 처리한 외부 효과 키를 같은 절단점에 놓는다. packet capture 직전·직후, 복원 후 suffix, 외부 ack 전에 실패 및 재시도까지 관측할 상태와 소유자/증거를 지정한다. 기존 suffix/투사체/viewer/cursor는 각 부분의 증거로 연결한다. 조합 자체는 미실행이라고 명시한다.
- oracle은 K05–K07/A06의 수기 정본 12행과 위 독립 closeout들의 범위·판정을 별도로 읽어 만든다. 동일 문서에서 주장과 기대값을 자동으로 추출해 자기검증하지 않는다. 5a는 행 ID 12개·경계 4개·조합 1개, 허용 disposition 및 근거 경로를 검사한다. 사전등록 대조는 정상 exit 0, queue 반환 행을 뺀 사본의 정확 누락 exit 1, cursor attempt-03을 승인된 실행으로 표기한 오분류 사본의 정확 거부 exit 1, 근거 경로 부재 exit 2다. PowerShell ErrorActionPreference Stop, 실제 자식 종료코드와 stdout/stderr, SHA/HEAD 전후 기록을 요구한다. 승인 후에만 전용 Python gate와 입력 manifest를 작성한다.
- K=3. 5b는 다른 비-Astra 모델이 12행·4경계·조합의 독립 원문 대조 및 오분류 차집합을 확인한다. 수용은 문서/근거 폐합 범위이며 제품 운영 구현의 승인과 별개다. 사용량 제한 시 즉시 보고하고 반복을 중단한다.
