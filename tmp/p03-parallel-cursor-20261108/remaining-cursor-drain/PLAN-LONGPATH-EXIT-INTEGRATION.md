# 긴 경로 조사와 종료 게이트 후속 계획

이 조사는 Godot을 실행하지 않는다. git -c core.longpaths=true status는 명령 단위 설정이며 저장소 설정에 쓰지 않는다. LONGPATH-STATUS.exit/bin/WARN과 LONGPATH-TARGETS.json에서 기존 경고 경로 두 곳을 직접 확인한다. LONGPATH-PROTECTED.jsonl 및 SUMMARY는 명시 생산·P02·허용 루트의 관측 범위와 파일 SHA-256 및 크기를 기록한다. 탐색이 실패한 루트나 작업 중 변한 파일은 전체 보호 분모 확보 실패로 처리한다.

후속 통합은 아래 순서로 독립 수용을 받은 뒤 진행한다.

1. 기존 보호 루트, 별도 승인 P02 소유 목록, 승인 계획/runner/엔진/프로젝트·캐시를 재고정한다. Python 읽기는 Windows 확장 길이 경로를 적용하고 표시에만 원래 canonical 경로를 사용한다. 시작·종료 양쪽에 Git 명령 단위 longpaths를 적용한다. 여전히 실제 보호 범위 열거를 가리는 오류가 발생하면 중단한다.
2. 이전 미실행 attempt-04는 원문 그대로 보존한다. 다음 미사용 경로를 원자 예약하고 stdout/stderr 및 APPDATA/LOCALAPPDATA/TEMP/TMP를 전용 하위로 지정한 뒤 canonical 실경로와 재분석점 검사를 한다. 승인 게이트와 같은 Godot 콘솔·본체, 전용 Job, 32개 마커와 actual exit을 기록한다.
3. 종료 입력 재해시, 보호 루트 재귀 인벤토리, 고정된 자체 출력 범위 및 Git 상태 차이를 대조한다. 신규 trace는 승인된 두 부모에서만 별도 분류한다. P02의 독립 실행 원문이 같은 생성 경로, 실행 시각과 프로세스 정보를 연결하고 자체 Job PID/실행 환경과 충돌하지 않을 때만 귀속한다. 파일명·수정 시각이나 디렉터리 위치만으로 귀속하지 않는다. 사전 예약, 실행 중 기존 파일 변경, 귀속 불가, 누락·불일치면 hard stop이다. 신규 파일의 추가 표본과 수집 시각을 가능한 범위에서 보존한다.
4. 종료 통합 테스트는 엔진 대신 임시 데이터로 보호 파일 변경·삭제, 승인 신규 trace 귀속/미귀속, 잘못된 모드/링크/새 디렉터리와 자체 경로 충돌을 검사한다. 실제 P02 경로는 읽기만 한다. 조율 및 독립 수용 전 엔진 실행은 없다.

전후 동일성은 순간 변경 후 복원이나 비보호 경로 전체 불변을 입증하지 않는다. 실제 Godot 실행 3회/K6 및 종합 5-a 미통과 판정을 유지한다.

실제 출처 표본은 gate-k1/before-world-clean의 command.json과 process.json, 격리 로그에 있다. command.json은 P02 후보 프로젝트 경로와 APPDATA/LOCALAPPDATA, user_before를 제공한다. process.json user_after는 상대 trace 경로와 SHA를 제공하며 로그는 동일 절대 TRACE 경로를 기록한다. prospective 귀속기는 이 독립 기록의 경로·해시·시각·프로세스 연결을 확인하고 부족하면 미귀속으로 실패한다. 해당 기록 파일이 같은 실행 창에 새로 생기거나 기존 파일이 변경되면 그 기록 자체도 현재 허용 목록 밖이므로 별도의 hard stop이다. 이 제약 아래 동시 trace 귀속을 항상 성공시킬 수 있다고 가정하지 않는다.
