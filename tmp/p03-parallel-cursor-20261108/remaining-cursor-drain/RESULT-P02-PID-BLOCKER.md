# P02 출처 확인과 cursor/drain 재개 조건

기존 gate-k1 before-world-clean 및 before-world-returning 각각에서 command.json, process.json, stdout/stderr 및 trace의 SHA를 읽기 대조했다. process.json의 실제 키는 exit, timeout, user_after이며 양쪽 trace SHA가 user_after와 일치한다. stdout의 TRACE 절대 경로 및 같은 실행 모드의 격리 APPDATA가 경로 귀속을 뒷받침한다. 두 폴더에 pid.json은 없다. 숫자 4008 및 7756은 해당 trace 파일명과 그 경로를 인용한 기록에서 확인된다. 파일명을 만드는 scripts/battle_trace.gd는 자신의 PID를 삽입하지만 이 값은 독립 프로세스 관측을 제공하지 않는다.

gate-k1의 run.py는 subprocess.run의 반환 코드와 캡처 원문 및 user_after를 저장한다. 해당 기록에 엔진 본체 PID나 프로세스 추적 정보는 없다. 별도 GUI runner의 pid.json 기록 코드는 다른 실행 경로이므로 이 두 headless trace의 독립 PID로 대입할 수 없다. P02 eighth 기록에서 대상의 PID를 별도 파일로 연결한 증거를 발견하지 못했다. 증거는 읽기만 했으며 전용 SHA 및 판정만 작성했다.

실제 신규 trace 귀속 재개는 같은 실행의 독립 프로세스 기록이 trace 경로·시간·해시와 연결되고, 해당 기록의 생성 또는 변경이 기존 보호 판정과 충돌하지 않도록 별도 승인되는 경우에 가능하다. 기존 보호 범위에서 독립 기록 자체가 실행 창에 생성되거나 변경되면 현 계획에서는 별도 hard stop이다. 추정 PID나 이미 종료된 동일 PID 숫자의 다른 프로세스로 대체하지 않는다. P02 중단은 요청하지 않는다.

Godot 신규 실행 없음. 기존 실제 3회/K6과 종합 5-a 미통과를 보존한다. 전체 P03/I01/I01b/A04–A06 NOT_READY, O07 OPEN, 외부 저장 schema UNCLASSIFIED.
