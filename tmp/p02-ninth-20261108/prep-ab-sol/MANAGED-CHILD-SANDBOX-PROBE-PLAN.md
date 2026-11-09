# Managed Windows 자식 프로세스 sandbox 비제품 최소 검증

실행 전 독립 심사용이다. 제품과 Godot은 시작하지 않는다. 시스템 보안 설정, 사용자 ACL, Codex 저장 설정과 managed profile은 수정하지 않는다.

OpenAI Docs는 Windows sandbox가 명령과 자식의 활성 filesystem/network 권한을 집행한다고 명시한다. MXC, elevated, unelevated는 지원 및 읽기/네트워크 경계가 다르며 문서만으로 이 turn의 실제 backend를 식별할 수 없다. 현재 turn의 managed profile은 광범위 root read와 workspace write를 제공한다. 따라서 상속이 확인되더라도 제품 read-deny, 최소 프로젝트의 읽기 전용 보장, 전체 외부 경로 차단까지 입증되는 것은 아니다. [OpenAI Docs Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox#configure-the-windows-sandbox)

## 한정 probe

- 기본 sandbox가 적용되는 exec_command를 사용한다. Escalation, 저장 설정 변경, 새 ACL 또는 사용자 데이터 접근을 하지 않는다. 기존 C:/Python314/python.exe와 새 prep-ab-sol/sandbox-inheritance-review 코드만 사용한다. 독립 검토 후 root 안에 무작위 nonce를 포함한 신규 빈 경로를 만든다. 이 경로만 scratch로 쓰고 모든 marker는 exclusive-create 한다.
- P1 parent 및 child positive witness는 지정된 동일 benign marker를 읽고 서로 다른 새 scratch 파일에 고정 bytes를 쓴다. Parent/child PID, parent relationship, creation time/identity, bytes SHA 및 결과를 기록한다. Child도 default sandbox의 직접 자손으로 만든다. Shell 간 우회, cmdlet로 제3 경로 이동/삭제, 실제 product/cache/credential 접근은 없다.
- P2 write-denied witness는 **관리 경계가 사전에 제공한 별도의 폐기 가능한 synthetic read-only marker**가 있고 경로/내용/normal-ACL baseline이 합의된 경우에만 포함한다. Approved 기존 synthetic 파일에 OPEN_EXISTING write access만 요청하고, 성공해도 아무 바이트도 쓰지 않으며 truncate/create/delete하지 않는다. 단지 access denied 하나로 sandbox attribution을 하지 않는다. 현재 profile에서 독립된 synthetic deny marker를 안전하게 준비할 수 있는 도구 증거가 없으므로 P2는 실행 전 미확정이다. 사용자나 시스템 실제 파일을 대신 사용하지 않는다.
- P3 read-denied witness는 단 하나의 전용 synthetic marker를 별도 managed deny-read profile이 제공할 때만 한다. 현재 root read profile 아래서는 그 기능을 검증할 수 없다. 고의 product read, credentials, network test는 하지 않는다. P2/P3를 관측하지 못하면 전체 ABI confinement를 통과시킬 수 없다.
- P4 process lifecycle은 현재 ABI 와 같은 V5 broker의 기존 private Windows Job을 쓰되 Python child가 stdout marker 후 짧게 정상 종료하는 케이스와 timer보다 오래 기다리는 별도 케이스만 포함한다. Exact command/env/adapter SHA 및 OS metadata가 동결될 때만 실행한다. Broker Job membership과 inherited child membership을 실제 HANDLE로 관측, 4초 process cap/2초 drain 및 별도 outside watchdog에서 기록한다. GUI 또는 다른 프로세스는 조회하거나 종료하지 않는다. Any Job assign refusal·identity 관측 실패·watchdog/EOF 오류는 미완료다. watchdog adapter의 실제 구현과 승인 manifest는 미제공이다.

P1만 가능한 현재 가장 작은 범위는 child가 scratch 읽기·쓰기를 수행할 수 있는 양성 확인이다. 그 양성은 ACL 차단·상속 강제의 증거가 아니다. 결손인 negative read/write boundary 또는 watchdog을 제공할 수 없으면 실제 ABI engine을 실행하지 않는다. 대안은 승인된 disposable Windows VM/호스트에서 product 및 user mount가 없는 접근 범위와 read-only input/scratch를 운영자가 제공하고, 동일 frozen probe와 lifecycle oracle을 검토받는 것이다. MXC 또는 별도 환경이 실제 제공됐다고 단정하지 않는다. 최초 제품 import/검증 spawn부터 K6 한 회가 소진된다.
