# V3 격리 attempt-01 실행 결과

판정 미완료. 조각 한도 1/6 사용. 20개 계획 중 4개 실행, 기준선 3개 확인, 준비 실패 lane에서 정지. 후보 엔진 실행 0회이며 격리 후보와 원본 제품 상태를 구분한다.

| lane | 관측 | 프로세스 |
| --- | --- | --- |
| before/import | 승인 입력 임포트 완료. 예상 밖 진단 없음 | 자연 exit 0, root signal 0, Job active 0 |
| before/result | 13개 ID 통과. 실제 결과 버튼의 WorldMap 전환 거절로 엔진 오류 두 줄이 발생했고 기존 Brief가 null로 바뀌며 이전 대기 결과가 새로운 결산 객체로 바뀜 | 자연 exit 0, root signal 0, Job active 0 |
| before/pause | 13개 ID 통과. 실제 일시정지 버튼의 WorldMap 전환 거절로 엔진 오류 두 줄이 발생했고 기존 Brief와 대기 결과가 null로 바뀜 | 자연 exit 0, root signal 0, Job active 0 |
| before/prepare | 실제 초기 준비 오류 `invalid_candidate_profile at profile` 뒤 검증기 71행이 비어 있는 `G`의 `state`를 직접 읽어 SCRIPT ERROR. WorldMap rename과 복귀 버튼 발화 이전. 60초 감독 상한에서 정리 | wrapper exit 1, root signal 0, root exit 125, Job active 0 |

부분 결과는 `attempt-01/results.json`, 각 lane의 `engine.log` 및 `engine.os.tsv`에 있다. 준비 실패 후 `supervisor-failure.json`은 WorldMap이 있고 held 파일은 없음을 확인한다. 기준선 두 거절 lane에는 종료 누수 진단이 없었고 후보와의 비교는 미실행이다. 종료 뒤 승인 파일 12개, 제품 closure 1,480개, 보호 범위 26개, 브랜치·HEAD·index를 재검증했다. 원본 .godot 디렉터리의 관측된 LastWriteTimeUtc는 전후 동일하다. 디스크 여유 5,020,889,088 bytes. PC0, 기존 여덟째 K6 및 원본 제품에는 실행·적용하지 않았다.

다음 준비 제안은 초기 준비 실패에서 `G.has("state")`가 false임을 명시 판정하고, 값은 존재할 때만 캡처하는 것이다. 거절 전후에는 key 존재와 존재하는 경우 값의 동등성을 각각 확인한다. 결과·일시정지에서는 key 존재 및 기존 상태를 확인한다. 초기 준비 실패에 새 상태 키를 넣거나 사용자 오류 UI를 추가하지 않는다. 정해진 assertion ID와 독립 심사 범위를 재동결하기 전에는 검증 코드 변경과 다음 엔진 실행을 시작하지 않는다.
