# Managed sandbox에서 비제품 ABI를 확인하는 제한적 대안

독립 검토용이다. 관리 경계의 강한 읽기 차단은 현재 확인되지 않았다. 이 대안의 목표는 신뢰할 수 있는 고정 엔진으로 무해한 literal 직렬화를 한 번 관측하는 것이다. ABI의 제한된 결과만 판정하며 제품 격리나 최종 K6의 위험 경계를 완화하지 않는다.

## 실행 입력 및 노출

- 기본 sandbox의 exec_command만 사용한다. Escalation과 저장 profile 변경은 하지 않는다. OpenAI Docs가 문서화한 활성 filesystem/network 정책의 자식 상속을 사용한다. 현재 root read/workspace write는 제품 접근의 OS 차단을 의미하지 않는다. [OpenAI Docs Windows sandbox](https://learn.chatgpt.com/docs/windows/windows-sandbox#configure-the-windows-sandbox)
- 후보 명령은 ABI-DRAFT-MANIFEST-v2.json의 동일 engine/path/argv, Python 비교기 SHA와 정확 candidate env를 사용한다. 고정 최소 두 파일에서 새 scratch project를 만들고 TMP/TEMP, APPDATA/LOCALAPPDATA/XDG, cwd 및 logs 전부 그 안에 둔다. Product project/fixture/cache 경로를 전달하지 않으며 Godot editor와 import를 열지 않는다. Source 두 파일에서 autoload, load/FileAccess, network, external references, CLI extra args 및 plugin을 정적 거부한다. 외부 보안 경계를 넘는 파일을 열어 보거나 쓰기 test를 실행하지 않는다.
- 이 대안의 근거는 신뢰된 engine SHA, 최소 source/argv 정적 audit 및 사후 scratch/원본 SHA다. 외부 read가 없음을 완전히 증명할 수 없고 변경·복구가 해시 관측 사이에 일어나지 않았다고 주장하지 않는다. 실제 engine stderr/exit 및 unexpected files/paths가 나오면 중단한다. Product 접근이 관측되면 비제품 통과로 분류하지 않고 K6 정의부터 재심한다.
- 실행 직전에 source·engine·Python/runner 및 다음 경로를 다시 SHA로 확인한다. HEAD/index/staged entries, P03 private state, worker test, 원본 project.godot와 project.godot의 로깅 설정. 실행 뒤 같은 항목, scratch 전체 목록과 생성된 engine logs/cache/user settings를 보고한다. 읽을 수 있다는 이유만으로 실제 user data나 제품 cache를 열지 않는다. 대상 파일이 현재 바뀌면 기존 작업을 복구하지 않고 중단한다.

## 실제 소유 경계

독립 실행 manifest에서 exact OS adapter SHA, 실행 argv와 환경을 추가 고정한 경우에만 진행한다. ABI monitor의 Python CLI는 현재 fail closed다.

1. 짧은 Python controller를 시작하기 전에 outer Job 및 deadline을 만든다. Supervisor는 outer 밖에서 제어한다. Controller는 정확 Popen broker HANDLE을 private inner Job에 넣고 membership 양성 및 최소 설정을 확인한 뒤에만 barrier를 release한다. Child 확인에는 creation time, image SHA, retained process handle과 IsProcessInJob을 사용한다. 실제 console wrapper가 별개 GUI exe를 띄울 수 있으므로 실제 Job member tree를 기록한다. 예상 외 executable 또는 member 관측 실패도 실패다. 짧은 정상 exit에서도 엔진 HANDLE을 놓치면 pass로 처리하지 않는다.
2. ABI monitor는 stdout/stderr 합계 256KiB, 첫 barrier 전부터 20초, owned cleanup 5초를 사용한다. Controller 또는 pipe/fsync가 붙잡히면 outer watchdog이 해당 Job에만 종료를 적용하고, outside journal에 stage/timeout 및 실제 drain 결과를 남긴다. Supervisor 별도 reserve와 tool 종료 여부를 실행 전 manifest에서 고정한다. 기존 Godot 및 다른 프로세스는 조작하지 않는다.
3. 실제 evidence는 before/after engine SHA, Job lifecycle/creation/ownership, raw stdout/stderr exact exit 및 flush, raw logs SHA, scratch diff, 기존 원본 보호 SHA로 구성한다. ABI strict 비교기의 exact banner/10행 이외 자료는 실패다. 정상 exit와 output 통과는 독립적으로 기록한다.

지금 제공된 자료에는 owner adapter와 outer hard watchdog의 실제 실행 검증이 없다. 최소 접근 위험의 대안으로 계획을 독립 심사할 수 있지만 engine을 시작할 상태는 아니다. 기존 제품을 읽지 않는 이 ABI 시험은 K6 소진점이 아니며, W1~W5와 제품 21행 또는 GUI 귀속을 대신하지 않는다.
