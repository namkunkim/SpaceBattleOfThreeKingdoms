# P03 같은 틱 suffix 계획 v5 심사

2026-11-07. **수용**. attempt-03은 timeout 실패 경로가 제한 시간 안에 실패를 보고했으나 taskkill 권한 오류로 자식을 즉시 회수하지 못한 사실을 보존한다. v5는 새 launcher를 suspended로 격리 Job에 넣어 자식 생성 전 소유 경계를 만들고 해당 Job만 종료하며 active count와 양 PID 종료를 검증한다. 배정·권한·resume 실패는 대체 경로 없이 실패한다. 실제 Windows 권한/중첩 Job 환경의 동작은 새 timeout probe로 검증하며, 실패하면 성공으로 간주하지 않는다. 계획상 K6=3/6, probe와 정상 실행을 각각 한 번씩 센다.
