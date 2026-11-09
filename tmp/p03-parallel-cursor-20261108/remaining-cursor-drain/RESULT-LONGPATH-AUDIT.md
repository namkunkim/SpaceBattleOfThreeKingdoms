# 긴 경로 사전 조사 결과

명령 단위 git -c core.longpaths=true status는 exit0, stderr 0바이트였다. Git 설정 파일을 수정하지 않았다. 기존 경고 두 경로를 일반 Windows 경로와 확장 길이 경로로 각각 직접 재귀 열거했다. 두 경로는 모두 빈 디렉터리였다. 해당 디렉터리 아래 해시를 계산할 파일은 0개다. 증거는 LONGPATH-STATUS*, LONGPATH-TARGETS.json, LONGPATH-EXTENDED-TARGETS.json이다.

보호 루트의 일반 Python 재귀 조사에서 24 디렉터리 루트를 열거했다. 명칭 glob에 포함된 ZIP 5개를 디렉터리로 전달해 WinError 267이 발생했다. ZIP은 Windows 확장 경로로 일반 파일을 직접 열어 5개 모두 SHA와 크기를 기록했다. 합본은 선언 범위 29루트, 중복 제거 파일 79,647개, 디렉터리 2,980개, 미해결 선언 루트 0이다. LONGPATH-DECLARED-SCOPE-AUDIT.json은 각 루트의 분모, 두 긴 경로의 직접 확인, 누락 루트 반례의 거부를 포함한다. 시점이 다른 표본을 합친 읽기 조사이므로 실행 기준선이나 원자적 전체 snapshot으로 쓰지 않는다.

보존 판정 helper의 엔진 없는 합성 반례 8/8이 통과했다. 실제 P02 귀속과 종료/격리 통합은 PLAN-LONGPATH-EXIT-INTEGRATION.md에 남아 있다. P02 자체 command/process/log가 trace 경로·해시를 제공할 수 있지만, 해당 근거 파일이 새로 생기거나 기존 것이 변경되면 현재 trace 전용 허용 목록에 포함되지 않아 별도로 중단한다. Godot 미실행, 실제 시도 3회, 종합 5-a 미통과 상태를 유지한다.

후속 통합 구현은 launch_preserved.py, preservation_exit.py, extended_inventory.py에 있다. Godot 진입점은 독립 수용 대기 상태로 차단했다. 실제 main을 가짜 Process와 Job으로 호출한 6개 검사 및 출처 어댑터·누락 보호 경로의 9개 검사 원문은 PRESERVATION-INTEGRATED-SYNTHETIC.json 및 PRESERVATION-EXIT-SYNTHETIC.json이다. 실제 P02 샘플 process.json에는 trace SHA는 있으나 독립 engine_pid 필드가 없다. 따라서 이름에서 읽은 PID, 로그 경로와 SHA만 있는 실제 신규 trace는 현재 어댑터가 승인하지 않는다. P02 자체 파일은 변경하지 않았다.

전수 확장 경로 비교는 LONGPATH-EXTENDED-COMPARISON.json이다. 디렉터리 순회가 실패한 5개 ZIP 정규 파일은 앞서 계산한 별도 확장 경로 SHA·크기를 합쳤다. 두 조사 창의 목록 차이는 기록하며 동일 시점 동결로 승격하지 않는다.
