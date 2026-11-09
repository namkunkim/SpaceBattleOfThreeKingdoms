# P03 같은 틱 절단점 계획 보완 v5

2026-11-07 KST. [attempt-03](attempt-03/run.json)의 실제 timeout에서 OS taskkill은 exit1 및 사용자 이름/암호 오류를 반환했다. gate는 8.35초에 실패를 반환했으나 당시 콘솔과 본체는 모두 살아 있었다. 두 PID는 probe의 원래 15초 종료 경로 뒤 별도 조회에서 사라졌다. 원문과 이력은 보존한다. K6 사용 3.

이후 gate는 프로세스 이름이나 모든 엔진을 대상으로 하지 않는다. 시도마다 이름 없는 독립 Windows Job Object를 만들고, **console launcher를 CREATE_SUSPENDED로 실행**하여 자식이 생기기 전에 해당 launcher만 job에 할당한다. 새 프로세스의 첫 스레드를 Windows Toolhelp 조회에서 owner PID가 일치하는 유일 스레드로 확인한 뒤 resume한다. Job을 별도 소유하며 breakaway를 허용하지 않는다. Windows/상위 job의 nested membership 제약, 새 프로세스 조회·할당·초기 스레드 단일성·resume 실패면 **suspended launcher를 회수하고 headless 시도를 실패** 처리한다. 다른 작업의 Windows job을 열거나 프로세스 트리를 탐색·종료하지 않는다.

타임아웃은 전용 Job Object에 `TerminateJobObject`를 호출한다. 실패를 숨기지 않고 Win32 결과와 마지막 오류를 기록한다. launcher wait와 job의 active process count=0 확인에 유한 기한을 둔다. timeout probe는 이전과 같은 3초 제한·15초 hold이며 runtime path/PID, launcher distinct PID, actual nonzero, 두 PID 종료 및 active count 0, 결과 마커 부재, 입력 불변을 요구한다. 실제 timeout gate exit는 nonzero이고 별도 probe PASS만 기록한다.

정상 경로는 기존 class guard·engine body/console SHA·6명명/91 체크 기준을 유지한다. 정상 launcher 종료 뒤도 job active process count 0을 확인하고, 종료나 예외 시 전용 job/프로세스/스레드 handle을 해제한다. 가능하면 Job의 kill-on-close를 설정하여 runner 예외에도 전용 자식만 회수한다. Job 할당 실패 등 사전 실행 실패에서 다른 경로로 자동 fallback하지 않는다. 새 exclusive 파일 stdout/stderr와 모든 시도 로그를 보존한다. 예정 K6 호출은 attempt-04 timeout probe 및 attempt-05 정상이다. v5 독립 수용 후 구현한다.
