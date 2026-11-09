# P02 천하 복귀 실패 안내 격리 검증 결과

독립 승인에 결합된 review-only SHA 0914cf612dc7a6ca90fd8362713c49998e45bb0b144f0a4eeea0065282d2857e로 attempt-01 한 회를 실행했다. Runner exit 0, 엔진 명령 28/28, fixture 단언 728/728, 1600×900 PNG 18/18. results.json SHA b81adfb940ae7e20789252be00e36fbb7a5ef0b9cb5a651ddf656f300ab30aae. 명령별 엔진 exit 0·전용 Job active 0을 확인했다. 종료 후 35개 승인 입력, 1,480개 원본 closure, 26개 보호 원본, HEAD와 index 재대조가 통과했다. 원본 적용은 독립 5-b 이후 단계다.

- 12개 거절 lane에서 실제 WorldMap 로더 거절 24회, 정해진 경고 24줄 및 로더 오류 48줄. 준비 실패 유도에서 기존 profile 오류 8줄. 별도 SCRIPT ERROR와 예기치 않은 진단 없음.
- 두 번 거절과 실제 scene 복구, 종료된 씬 제거, 마지막 결과 DTO의 한 번 소비, rollback identity와 상태 보존 확인. 정상 첫 클릭·standalone 세 흐름·returning 설정도 양쪽 통과.
- PNG는 before/after 아래 native-pause, native-result, native-prepare의 initial, reject-1, reject-2다. 앱이 렌더링한 viewport를 저장했다. 모든 버튼은 프로그램 시그널로 작동했고 실제 OS 입력은 관측하지 않았다. 독립 시각 검토는 별도다.
- 1600×900 native의 버튼/안내 사각형은 아래 표와 같다. 재시도 전후 버튼과 초점 유지 단언이 통과했다. 최초 준비 실패의 42px 예약 슬롯 때문에 후보 버튼은 기준선 y479에서 y504로 25px 아래에 있다.
- 시작 자유 공간 3,999,633,408 bytes, 끝 확인 2,949,001,216 bytes. 테스트와 원시 증거를 보존했고 cache reclaim은 시행하지 않았다.

| 화면 | 기준선 버튼 x,y,w,h | 후보 버튼 x,y,w,h | 후보 안내 x,y,w,h |
|---|---|---|---|
| 일시정지 | 406,541,300,52 | 406,541,300,52 | 406,651,344,32 |
| 결과 | 598,790,150,54 | 598,790,150,54 | 570,852,460,40 |
| 최초 준비 실패 | 576,479,448,48 | 576,504,448,48 | 576,454,448,42 |
