# P03 Dictionary 값 metadata 계획 독립 심사

2026-11-08. **제한 관측 계획 수용**. 실행 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn 명시 배정이며 실제 내부 런타임 모델 확인은 아니다. 심사자는 구현에 참여하지 않는다.

기존 관측에서 keys()의 typed Array 차이가 거부를 설명하므로, 이번 계획의 동일 key metadata·keys 배열 및 int7 값 아래 value builtin만 int→Variant로 바꾸는 단방향 반례가 필요하다. 동일 typed 양성 및 key 차이 거부 대조와 실제 create/capture/prepare/restore, 활성 상태·packet 불변 또는 실제 sim 교체 비교가 사전등록됐다. 정확한 mismatch와 원자성만 MATCH, 성공적 교체만 MISMATCH, 다른 거부·metadata 손실·prepare 실패는 절차 실패로 구분한다. Godot가 해당 타입을 보존하지 않으면 기대를 조정하지 않고 결과를 보고한다.

5-b에서 양측 metadata가 value builtin 하나만 다른지 원소 및 keys 배열까지 독립 확인하고, 두 분기에서 owner context·binding/packet과 다음 호출 또는 교체된 runtime을 확인한다. 엔진·canonical class map/identity·전이 입력 SHA와 Job 격리를 별도 심사한다. 이 시험은 역방향·object metadata·전체 Cn/스키마/글로벌 cursor를 결정하지 않으며 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, 외부 save schema UNCLASSIFIED를 유지한다.
