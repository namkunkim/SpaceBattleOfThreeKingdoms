# 전장 → 천하 복귀 격리 실행 2회차

자동 검증 20/20 통과, 독립 구현 5-b 대기. 이 조각 2/6 사용. 원본 제품에 후보 미적용이며 PC0와 별도 여덟째 K6은 실행하지 않았다.

| 범위 | 기준선 | 후보 |
| --- | --- | --- |
| 결과 화면 복귀 거절 | 실제 로더 거절 1회. 이전 Brief 제거, 대기 결산 교체 | 실제 로더 거절 2회. Brief와 대기 Outcome 참조, 화면·sim·state 키와 값을 보존. 동일 전장과 버튼에서 WorldMap 복원 뒤 결과와 시드·모드·난이도·시간·fingerprint 전달 및 1회 소비 |
| 일시정지 복귀 거절 | 실제 로더 거절 1회. 이전 Brief와 대기 결산 제거 | 실제 로더 거절 2회 뒤 상태 보존. 동일 전장과 버튼에서 결과 없이 복귀 |
| 최초 준비 실패 복귀 거절 | 실제 후보 준비 오류와 로더 거절 1회. 이전 Brief와 대기 결산 제거 | 실제 후보 준비 오류와 로더 거절 2회 뒤 상태 보존. 준비 실패 전후 `G`가 빈 Dictionary이며 state 키 부재 유지. 동일 전장과 버튼에서 결과 없이 복귀 |
| 별도 정상 복귀 | 세 호출부 모두 통과 | 세 호출부 모두 통과 |
| 기존 회귀 | returning WorldLink·직접 출격 왕복 통과. clean WorldLink는 기존 서막 편차 1건 | 기준선과 동일 |

검증 probe의 정해진 ID·순서 210개가 일치했다. 후보의 실제 거절은 `Cannot open file`과 `Failed loading resource` 각 6건, `WORLD_RETURN_REJECTED error=19` 6건이다. 기준선은 각각 로더 진단 3건, 후보 경고 0건이었다. 양쪽 각 실제 초기 준비 오류 2건과 기존 clean 서막 진단 1건이 있었다. raw engine 로그에서 새 예외 및 종료 누수 진단은 관측되지 않았다. raw 비교 최종 판정은 독립 5-b에 속한다.

실행 래퍼 exit 0. 양쪽 각각 실제 자연 root exit 0 아홉 개와 예정된 clean root exit 1 하나이며, 20개 모두 root signal 0·Job active 0을 확인했다. 두 복제본 모두 WorldMap 파일이 복구됐고 held 파일은 없다. 실행 후 승인 파일 38개, 원본 closure 1,480개와 보호 26개, 브랜치·HEAD·index 재대조가 통과했다. 원본 .godot 디렉터리의 관측된 수정 시각은 전후 동일했다. 관측된 디스크 여유는 2,996,539,392바이트다.

근거는 `attempt-02/results.json`, 각 실행의 `command.json`, `engine.log`, `engine.os.tsv`, 감독기 표준 출력·오류에 있다. 실제 Windows OS 입력, 자연 전투 종료, 제품 operation, 사용자 오류 안내는 이 실행의 인수 범위에 포함되지 않는다.
