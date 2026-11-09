# P03 같은 틱 suffix 독립 5-b — attempt-02

2026-11-07. 판정: **제한 fixture 수용**. 심사자는 구현에 참여하지 않았다. 구현 gpt-6.1-sol / 심사 gpt-6.1-terra는 spawn의 명시 배정이며 실제 내부 런타임 모델명이나 차이를 확인한 것은 아니다.

실행 기록은 Godot actual exit0, 6명명/91 assertions, 예상 context 거부 4·구조 거부 2, 오류·경고 0이다. 콘솔 PID 26136과 본체 PID 18792 및 실제 본체 경로가 분리 기록됐다. 콘솔과 본체를 포함한 46개 입력의 전후 기록이 같고 현재 SHA도 독립 재계산 결과 차이 0이며 runner snapshot과 실제 코드도 같다. class map SHA 및 runtime script/binding guard를 코드와 기록에서 확인했다. attempt-01의 엔진 본체 누락 반려는 보존한다.

코드 대조에서 독립 raw twin은 별도 구성한 명령을 받으며, T=2에서 Q/Q/S 대기와 이미 적용된 I, 동일 T B/R, 첫 실제 advance의 I/B/R/Q/Q/S 로그 및 ordered 사건을 비교한다. 실제 두 번 전진 후 같은 owner에 복원하고 동일 suffix만 재실행해 첫 실행의 단계별 independent 관측과 사건을 비교한다. 비교에는 Variant 타입·값, Dictionary 키 타입/순서, Array 순서·typed metadata가 포함되며 객체의 script property와 binding은 별도 확인한다. malformed issue/queue의 불변과 네 standalone 준비 가능한 context mismatch의 기존 상태·packet 불변 및 후속 정상 진행을 확인한다. 테스트는 tick 절단과 내용 dedup 반례를 계산하며 이를 운영 cursor로 채택하지 않는다.

수용은 이 제한 POC fixture의 메모리 owner 경계에 한정한다. 실제 외부 저장 schema, 글로벌 cursor/commit, host clock·worker 실패 원자성, 외부 사건 exactly-once와 모든 활성 모듈 및 typed class/script 배열의 비어 있지 않은 경우를 입증하지 않는다. 전체 P03/I01/I01b/A04~06 NOT_READY, O07 OPEN, save schema UNCLASSIFIED 유지. 최종 5162 보존·manifest/압축 검사는 별도 closeout이다.

## 정정 — 최종 수용 보류

위 판정은 실행 담당이 뒤이어 제보한 timeout 회수 결함 때문에 **보류**한다. 콘솔만 kill한 뒤 자식 본체가 pipe를 보유하면 communicate가 제한 없이 기다릴 수 있어 계획상 timeout 종료·기록을 보장하지 못한다. attempt-02는 실제 timeout이 없어 위 46개 입력과 실행 관측은 유지하되 최종 5-b 수용은 아니다. 실행 트리의 제한된 종료와 회수, 오류 기록 및 입력 보존을 독립 반례로 검증한 뒤 재판정한다.
