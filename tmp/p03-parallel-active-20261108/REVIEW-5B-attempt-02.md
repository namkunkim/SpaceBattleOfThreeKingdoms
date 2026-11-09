# P03 제품 생성·제한 owner 경계 독립 5-b

2026-11-08. **제한 관측 수용.** 심사자는 구현에 참여하지 않았다. attempt-02의 runner snapshot, 원문 stdout/stderr, run.json, 동결 전후 목록과 현재 파일, 계획 및 기존 강제 주입 fixture의 독립 심사를 대조했다.

attempt-02는 Godot 4.7.2 actual exit 0, gate 통과, 명명 3개·24 checks이며 원문 stderr는 비어 있고 오류·경고·누수 진단 0이다. Job 총 2, active 0, timeout 없음이다. 동결 입력 70개의 전후 SHA와 현재 파일 SHA를 독립 재계산하여 차이 0, runner snapshot과 현재 runner SHA가 일치했다. HEAD 전후는 `fb660cea69207fd332e26128643007694910a253`이다. attempt-01은 actual exit 0이지만 ObjectDB 54개 및 resource 18개 종료 진단으로 gate 실패했으며 원문을 보존한다.

runner는 3D 호스트의 기본 적벽 profile·표준 난이도와 같은 `Organization.load_auto` 입력을 사용하여 fallback 없이 정본 `BattleSim`을 직접 생성했다. 카드 8개, 정본 DecisionBoard identity와 sim 역참조를 검사했다. 이는 실제 호스트의 준비·게시를 실행한 결과가 아니다. 제한 adapter 대조군에서는 C0 capture 후 tick 1로 전진하고 같은 context restore가 성공하여 sim 교체, tick 0, decisions null 및 ready/idle을 확인했다. 같은 입력에 카드 scenario만 추가한 경우 정확히 `unsupported_scenario`/`profile`로 거부했고 owner 부재와 입력 보존을 검사했다.

이 결과는 정상 생성자의 활성 DecisionBoard와 제한 owner의 생성 거부 경계를 구분한다. 정상 제품에서 제한 owner가 활성 DecisionBoard를 보유한 채 restore에 도달한다는 뜻이 아니다. 기존 별도 fixture는 강제 주입 후 capture 거부와 restore의 모듈 소실을 관측했으며, 자연 도달과 운영 정책은 여전히 미확인이다. 본 심사는 실행 관측에 한정하며 보존·패키지 closeout은 별도다. 전체 P03/I01/I01b/A04~A06 NOT_READY, O07 OPEN, 외부 저장 스키마 UNCLASSIFIED.
