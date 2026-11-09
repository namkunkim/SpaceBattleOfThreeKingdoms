# 관리형 자식 sandbox probe 독립 심사

판정: **P1~P4의 증거 해석과 안전 범위는 조건부 수용한다. 다만 제품·비제품 작업 전 전용 read-deny/OS 격리를 일반 필수조건으로 확대하는 것은 근거가 부족하다.** `MANAGED-CHILD-SANDBOX-PROBE-PLAN.md` SHA `226ba59053e6cc9f878871ec5b51a5996e96e31d28f43df4ccb4b69c256d7395` 확인. 실제 심사 모델은 nodeRepl turn metadata에서 확인한 gpt-6.1-terra다. 이 심사는 정적 검토이며 P1~P4, Godot, 제품 및 K6을 실행하지 않았다.

[OpenAI Windows sandbox 문서](https://learn.chatgpt.com/docs/windows/windows-sandbox#configure-the-windows-sandbox)는 활성 filesystem/network 정책이 명령과 자식에 적용된다고 설명한다. 현재 제공된 managed profile은 전체 root 읽기와 두 workspace root 쓰기 및 일부 보호 경로 읽기를 명시한다. 따라서 정상 자식의 scratch 읽기/쓰기(P1)는 해당 접근 가능성만 보여 주며, read-deny나 source read-only의 존재를 입증하지 못한다. P2/P3는 관리 경계가 제공한 무해한 synthetic marker가 없으면 미검증으로 두고, 사용자 파일로 부정 시험을 대체하지 않는 조건이 적절하다. P4는 실제 broker·자손 membership과 제한 시간 정리를 보여 줄 수 있으나 정확 adapter/명령·외부 watcher가 없으므로 현 계획 그대로 실행할 준비는 안 됐다. P1~P4의 미실행은 제품 오류도 아니다.

**범위·필요성:** 이 세션의 사용자 지시 및 저장소 규칙에서 모든 검증에 product read-deny 또는 OS로 강제된 read-only source가 요구된다는 근거는 확인하지 못했다. 앞선 ABI 계획이 스스로 설정한 강한 독립 격리 계약을 충족하려면 그것이 필요하지만, 일반적으로 코드 검토를 마친 최소 Godot probe가 제품을 읽지 않는다는 목적까지 read-deny 강제만으로 입증해야 한다고 보기는 어렵다. 확실한 강제 격리와 통제된 실행·사후 관측은 보장 수준이 다르다. 후자는 외부 쓰기/중간 변경 부재를 증명하지 못한다는 한계를 기록하면, 위험 기반으로 좁은 비제품 실행과 제품으로의 전진 가능성을 별도로 심사할 수 있다. 기존 승인 계약을 조용히 완화하거나 K6/GUI 증거에 합산해서는 안 된다.

현실적 대안은 (1) 실행할 최소 probe·engine·runner를 정적 검토 및 SHA 고정하고, 새 고유 격리 복제/독립 user://·APPDATA·TEMP·cache·로그, 정확 argv/env, bounded output·owned Job/timeout/정리를 준비한다. (2) 제품/P03·index 및 승인 입력을 전후 해시로 확인하고 다른 세션 drift면 정지한다. (3) 운영 중 원본 접근을 OS로 배제하지 못한 한계, 예상치 못한 파일 생성/출력·자손의 관측 범위를 기록한다. 이는 악의적 프로그램의 모든 쓰기나 snapshot 사이 변화를 봉쇄하는 보증이 아니다. 선택한 프로그램의 실제 코드·영향과 병행 작업에 적합한지 독립 심사한 뒤 낮은 위험의 비제품 시험에 한해 적용한다. 강제 격리 계약을 반드시 유지하려면 별도 관리 profile 또는 product/user mount 없는 일회성 환경을 마련한다. 시스템 ACL·보안 설정 변경이나 권한 상승은 하지 않는다.

K6는 위험과 분모가 다른 실제 제품 검증이므로 승인된 immutable 입력, P03 보호 및 시점·결과 관측, ownership·deadline, GUI 입력 귀속 등 기존 조건을 별도 충족해야 한다. 비제품 ABI 또는 P1 양성은 GUI provenance, Job 실패 정리, 제품 성공의 대용이 아니다. 원본 보호의 실제 효과와 비교 범위를 따로 평가하고, 인위적인 추가 시험을 무한정 선행 조건으로 늘리지 않는다. 최초 제품 import/검증 spawn의 K6 소진과 K1~K5 기록은 유지한다.
