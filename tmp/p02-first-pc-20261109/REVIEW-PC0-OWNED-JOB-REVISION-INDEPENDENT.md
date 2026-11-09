# PC0 소유 Job 개정 스펙 독립 심사

판정: **Job 소유와 image 신뢰를 나누는 방향은 조건부 수용한다. 누적 K=3과 즉시 실행은 수용하지 않는다.** `PLAN-PC0-OWNED-JOB-REVISION.md` SHA `56829afd91659f53488411ffee2460157067fcc1cf8b1ce347d4e031e5fe776c` 확인. 심사 모델 gpt-6.1-terra. 제품·Godot·GUI·Job을 실행하지 않았다.

가장 중요한 범위 충돌은 재시도 상한이다. 기존 승인된 `PLAN-V2-PC0.md`는 최초 한 회와 확인된 원인 해결 후 최대 한 회를 정했고 V3가 그 조건을 유지했다. 따라서 run01은 누적 1/2이고 근거 있는 국소 수정 후 별도 독립 수용을 받은 #2 한 회만 기존 범위에서 검토할 수 있다. 새 문서의 K=3·잔여 두 회는 기존 상한을 확대한다. 실패 이력을 지우거나 이 개정만으로 #3을 기존 승인 범위라고 주장하지 않는다. 같은 원인이 반복되면 정지하고 결과를 보존한다. 이전 Python-only K3 세 실패와 여덟째 후보 K1~K5/K6도 별도 보존한다.

`Active(job)==1`을 프로세스 신뢰 정책으로 쓰지 않고, 전용 Job membership을 **수명/정리 범위**, 고정 root exe의 경로·SHA 및 실제 GUI HWND 소유를 **제품 대상 확인**으로 나누는 방향은 실측된 import 중단을 다루는 합리적 스펙 복귀다. 단 Job 소속만으로 임의 image가 신뢰되거나 root가 실제로 생성했다는 의미는 아니다. 정확히 자신이 생성·할당한 unnamed Job, 비상속 handle, breakaway 미허용과 고정 root HANDLE이 확보돼야 하며 이름/PID 검색으로 외부 프로세스를 assign·종료하지 않는다. 알 수 없는 member가 생겨도 실행을 무조건 허용하는 것이 아니라 관측한 경로/identity 및 한계, 해당 단계가 읽고 쓰는 범위·root 정상 종료와 `active=0`을 결과에 남기고 제품 GUI 입력 대상으로 승격하지 않는다. 현 run01의 member가 console host였다는 근거는 없다.

준비물 재심에는 다음의 실현 가능한 구체 계약이 필요하다.

- root 경로·승인 SHA·CreateProcess returned HANDLE/creation·Job membership 및 resume 순서, GUI 입력 시 그 root 소유 HWND/foreground·action 전후를 고정한다. 경로에 있는 현재 파일의 SHA만으로 실행 중 image bytes가 불변이라고 단정하지 않는다. 다른 member HWND나 기존 사용자 창에는 입력하지 않는다.
- PID 목록과 retained HANDLE의 조회 경합·버퍼 부족·권한 거부를 bounded하게 기록한다. 모든 관측 member는 identity를 유지하고 얻은 HANDLE이 종료했는지 확인한다. 짧게 지나간 member의 개별 identity가 없으면 미확인으로 기록하며, OS notification 누락만으로 자손 부재를 주장하지 않는다. root 실제 exit·Job active 0·보유 HANDLE signal 및 log flush는 분리한다. assign 실패는 resume 없이 소유 root만 종료한다. 정상 root 종료 뒤 active child가 남으면 제한된 drain 후 timeout/종료를 실패 처리한다.
- `run-02`는 fresh source/cache/user/output으로 준비하며 run01 부분 import와 `.recovery_mode_lock`, 기존 화면·사용자 데이터는 보존한다. 동일 1,470 source/overlay/oracle, import exit·generated cache 확인 후에만 제품 GUI를 시작한다. stage별 300초·1,920초와 cleanup reserve를 exact runner에서 강제하고 통제 불능일 때만 소유 Job을 종료한다. HEAD/index/P03/worker·원본 user/cache의 전후 hash는 관측 범위와 한계를 기록하고 drift를 복구하지 않는다.
- source 기반 synthetic은 assign 실패 시 resume 0, unknown/reused PID, member 열람 race, root 정상/실패, timeout·cleanup 실패를 검증한다. 합성은 실제 Win32/helper lifecycle 증명이 아니다. 최종 manifest의 코드·argv/env/engine/source SHA, 실제 사용자 화면 행동 및 원문 산출을 독립 재심하기 전 실행하지 않는다.

PC0은 HEAD legacy baseline이며 활성 P03 +9 결합, 실제 적벽 operation, 사람 플레이, P07 목표/철수 및 전체 P02 완료를 입증하지 않는다. GUI 입력·자연 종결·1회 결과 소비는 실제 evidence를 수집한 뒤 별도 5-b로 판정한다. 여덟째 후보는 적용하지 않으며 그 K6 한 회·21행은 바꾸지 않는다.
