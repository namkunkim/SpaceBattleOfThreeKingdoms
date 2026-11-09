# P03 typed context 관측 계획 독립 심사

2026-11-08. **제한 계획 수용**. 구현 gpt-6.1-sol과 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인은 아니다. 심사자는 구현에 참여하지 않는다.

현재 private `_context_same`의 Dictionary 분기는 keys와 값을 재귀 비교하고 자체 typed metadata를 직접 읽지 않는다. `keys()`가 반환하는 배열 타입을 포함한 실제 효과는 실행 전 추정하지 않는다. v2는 typed active→untyped candidate 단방향에서 실제 metadata 차이가 입력·packet·prepare에 보존됨을 필수로 하며 정확 context mismatch와 실패 원자성만 MATCH, 실제 교체만 MISMATCH로 분리한다. 그 외 거부·metadata 손실은 절차 실패다. Array builtin/native class/script 각 단일 변이 대조와 동일 typed 양성 사례도 정했다.

5-b에서는 각 변이가 오직 하나인지, 빈 Array의 타입 생성이 실제 의도대로인지, candidate 독립 준비와 활성 상태·packet 불변/후속 진행, Dictionary 수용 시 새 sim과 기존 context 기록을 확인한다. 판정은 관측 절차와 계약 적합성을 분리한다. 엔진·class map·Script identity 및 입력 전후 SHA와 timeout 격리를 확인한다. 이 시험의 Array class/script는 비어 있어 비어 있지 않은 객체 값은 범위 밖이다. 공유 코드 수정, 전체 저장·운영 Cn·global cursor 결정을 허용하지 않으며 I01/I01b/A04~06 및 전체 P03 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED를 유지한다.
