# P03 Dictionary 회귀 시간 계획 v3 독립 심사

2026-11-08. **수용**. legacy fresh 실제 30초 timeout/exit124와 전용 Job 회수 기록을 실패 이력으로 보존하고, 동일 입력·검사/마커를 유지한 채 fresh 및 active만 180초로 상한을 늘린다. 새 K6 호출로 센다. legacy 자체 engine PID self-report 부재는 console/body SHA 및 Job 근거와 분리해 명시한다. timeout 변경은 기능 PASS로 취급하지 않는다.
