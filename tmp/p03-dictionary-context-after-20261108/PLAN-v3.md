# Legacy 회귀 실행 시간 개정

fresh 70사례 attempt-01의 30초 제한은 실제 exit124로 종료됐고 전용 Job active0·total2와 입력 안정성을 보존했다. 이는 기능 수용 자료에 포함하지 않는다. 동일 소스/동일 명명 및 판정, 같은 Job 격리와 제한 종료를 유지하며 legacy fresh 및 active 회귀 상한만 180초로 올린다. 한정 시도의 실제 exit/진단/이전 runner 보존과 K6는 구분한다. viewer/suffix/dictionary 제한은 30초를 유지한다. legacy runner는 자체 engine PID를 출력하지 않는다. console/body SHA와 Job total2·active0 및 버전 증거를 남기며 engine 경로 self-report는 신규 JSON runner에서만 확증한다.
