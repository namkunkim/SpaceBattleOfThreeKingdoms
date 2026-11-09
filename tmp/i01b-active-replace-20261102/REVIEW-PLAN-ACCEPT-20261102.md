# 제한 활성 owner 교체 — 독립 1~3 계획 수용

2026-11-02 KST / **R1~R4 보완본 계획 수용**. 구현·실행·최종5-b 수용은 아직 아니다. 검토자는 구현 비참여 `/root/independent_review` (`gpt-6-astra`)다. 생산 코드·검사를 수정하지 않았다.

대상은 `PLAN.md`의 read-only I/O·busy/lifecycle·typed context·packet시점 사건·실제 활성 전제를 보강한 본문이다. 첫 검토 [REVIEW-PLAN-REVISION-20261102.md](REVIEW-PLAN-REVISION-20261102.md)를 대체 삭제하지 않고 보완 이력으로 연결한다.

실제 FleetBattle3D의 raw sim 생성/시계/표시와 AutoResolver의 스레드 경로를 연결하지 않는 이유가 현재 P2c 지원 경계와 일치한다. 이미 명령·진행·사건 경계를 소유한 OperationPrivateState handle을 소비자로 사용하고 새 facade 없이 한 instance 메서드를 추가한다. 이 범위를 제품 host 또는 공통 adapter 완료로 확대하지 않는다는 조건이 명확하다.

보완된 계약을 다음과 같이 수용한다.

- 기존 prepare의 코드 SHA/설정 파일 **읽기**를 재사용한다는 사실을 명시했다. 신규 파일 쓰기나 callback/await를 추가하지 않고 단일 동기 호출에서 교체한다.
- guard 뒤 현재 owner busy를 세우고 candidate prepare·맥락 검사를 마친 뒤 한 번 sim을 이전한다. candidate의 sim 소유권을 비우고 닫으며 이전 sim만 retire한다. 실패는 candidate만 정리하고 현재 busy/참조를 복구한다. old/new bindings와 실패 뒤 정상 호출을 검사한다.
- 국소 동일 context는 타입/값·사전 키 타입/삽입 순서·배열 원소 순서·typed builtin/class/script identity까지 비교한다. [] controls와 명시 delegate 배열은 다른 원입력이다. 별도 전용 비교의 허용 hunk와 typed metadata-only 유효 반례가 있어 Service._same만 쓰는 누락을 검출할 수 있다. 이것은 이번 메서드의 보수적인 제한이며 전역 저장 호환 정책이 아니다.
- 사건은 packet 시점 기준으로 복원한다. 이미 전달된 외부 효과의 전역 중복억제는 제외한다. 동일 packet의 반복 복원은 준비 자체가 명령/보급/사건을 추가 실행하지 않음을 의미하며 과거 timeline의 모든 소비를 기억한다는 주장이 아니다.
- 정상20은 각10seed의 POC 실제 진행 공격/타이머와 Salvo-D/S 실제 기억/보급진행·완료재고·평가/완료 경계 suffix를 포함한다. 모듈 객체 존재만으로 효과를 주장하지 않는다. first/late 상태오류·다른유효context·busy/closed/unprepared 등 명명8개, owner/sim identity·typed oracle·old/new module 정리·packet 불변 검사로 실제 통합 근거를 만든다.

초기 fixture 준비를 위해 상태를 설정할 경우 실제 효과 발생과 구분해 기록해야 한다는 기존 P2c 원칙도 유지한다. 구체 fixture 편성/초기값은 실행자의 구현 선택이며 새 게임 수치가 아니다. runtime 예외를 정상 오류로 감추거나 예외 안전성을 검증 없이 주장하지 않는다.

허용 변경은 P2c owner의 restore_completed 및 작은 전용 비교/정리 helper와 신규 검사뿐이다. 기존 검사·P2b·host·데이터·HTML 불변, P2c 회귀 OUT-only 역치환 증거, core/data와 정본 cache/입력/기존3879/source35/격리77 보존 감사는 이 범위에 적절하다. 원 P2c zip/관측은 유지하고 새 단계 runner는0/K6에서 시작한다. 범위 확대나 추가 실패가 없으면 무관한 통과 검사를 반복할 필요가 없다.

따라서 합의된 작은 구현과5-a로 진행할 수 있다. 완료 후 실제 diff·20/8 완결·활성 전제·실패 원자성·lifecycle·원문 로그·SHA·보존에 대해 별도 최종5-b가 필요하다. 전체 I01b/A04~A06 NOT_READY, 외부 schema UNCLASSIFIED, host/headless/replay·운영 Cn/global cursor·제품 공간·화면/성능 미완료는 유지한다. 커밋/푸시/병합/브랜치 전환·새worktree·editor import를 허용하는 판정이 아니다.
