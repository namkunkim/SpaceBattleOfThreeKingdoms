# P03 같은 틱 절단점 계획 보완 v4

2026-11-07 KST. attempt-02는 실제 엔진 본체 경로/PID·두 바이너리 SHA를 확인했고 정상 명명 검사 6개/91 checks/실제 exit0이다. timeout은 발생하지 않았다. Windows console wrapper만 kill한 뒤 pipe EOF를 기다리는 기존 timeout 분기는 실제 자식이 pipe를 보유하면 회수 기한을 지킬 수 없다. 이 때문에 독립 5-b는 보류됐다. 두 기존 시도의 증거를 보존한다. K6 사용 2.

stdout/stderr는 두 프로세스가 공유하는 pipe가 아니라 해당 attempt의 exclusive 새 로그 파일에 수집한다. 정상 경로는 동일한 콘솔→본체 실행과 엔진 입력/정본 guard를 유지한다. timeout이면 테스트가 시작한 launcher PID의 프로세스 트리만 Windows `taskkill.exe /PID <launcher> /T /F`로 종료하고, cleanup 명령과 launcher wait 모두 각각 별도 유한 시간 제한을 둔다. cleanup 명령의 actual exit·stdout/stderr 및 launcher actual exit를 기록한다. 알려진 launcher와 engine PID가 Windows 프로세스 조회에서 종료됐음을 별도 확인한다. 회수 실패/미확인도 실패이고 출력을 성공으로 바꾸지 않는다. PID, 경과, 이유, pre/post 입력 SHA와 raw logs를 보존한다. OS 전체/다른 실행을 종료하지 않는다.

보조 실제 timeout probe는 같은 runner의 명시 `--p03-timeout-probe`를 사용한다. Godot가 runtime executable path/PID를 출력한 뒤 startup guard를 통과하고 15초간 정지한다. gate의 timeout은 3초이고 engine 증거가 출력되기 전에 끝나면 probe 실패다. 요구 결과는 진짜 timeout, launch/body identity 일치, 두 프로세스 회수, launcher nonzero, 입력 불변, 정상 결과 마커 없음, gate nonzero다. 보조 probe의 검증 성공은 wrapper에서 별도 `timeout_probe_passed`로 기록하고 실패 실행 자체의 exit를 성공으로 위장하지 않는다. 다른 실행의 프로세스는 종료하지 않는다.

동일 소스와 해시 계약의 정상 실행을 별도 수행한다. 실제 Godot 호출은 probe도 새 K6 분모에 포함한다. 예정 순서 attempt-03 timeout probe, attempt-04 정상 6명명/4 context/2 structure. 준비 version 호출과 cleanup 유틸리티는 실제 headless K6 분모와 분리한다. [v3](PLAN-v3.md)의 양쪽 바이너리·runtime PID/경로, 나머지 fixture와 6명명 기준을 유지한다. 독립 계획 수용 후에만 구현한다.
