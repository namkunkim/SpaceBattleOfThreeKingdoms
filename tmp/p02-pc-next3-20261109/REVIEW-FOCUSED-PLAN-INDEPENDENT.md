# 첫 PC 우선 난이도 축소 계획 독립 검토

판정: 축소 목표와 격리 실행 명세 작성은 수용한다. 이 문서는 정확한 실행 승인 manifest가 아니므로 실제 엔진 실행·제품 수정·삭제는 아직 하지 않는다. 기존 attempt-01은 파서 오류로 기준선 행이 없었고 최초 승인된 단일 세트는 소진됐다. 별도 축소 시도 예산을 명시적으로 정해 기존 실패를 보존하고 독립 심사해야 한다. 사용자에게 추가 허락을 묻는 뜻은 아니다.

수정 probe SHA 2a343973144c518dcb40e20b8031ca79aa9e331ff1b8c0b8ef07e962684e3107은 기존 line 441의 `var ok: bool` 단 한 줄 변경이다. 이는 관측된 타입 추론 오류에 직접 대응하지만 다른 파서·런타임 오류가 없음을 증명하지 않는다. parser 실패나 조기 종료를 의도된 baseline red로 집계하지 않는다.

기존 manifest를 바탕으로 최소 구체 분모는 before/after 각각 import 1과 D01/D02/D03/D04/D08/D09 각 1, 총 14 프로세스다. 기존 timeout은 import 240초, D01~04와 D09 각 120초, D08 90초로 합계 1860초다(준비·정리 제외). 각 명령은 고정 GUI exe의 `--headless --path <isolated project> --log-file <lane log> --script res://tests/p02_difficulty_probe.gd -- <case> <before|after>`와 독립 user/TEMP 경로를 지정하고 import는 `--editor --import`다. 실제 승인 전에 절대 경로·argv 배열·환경·엔진/runner/probe/oracle/원본/후보 SHA와 Job root exit·timeout/cleanup을 동결한다.

기존 예상 baseline은 D01/D03/D04의 profile.host·profile.rules·roster.full·roster.wait 각 FAIL 및 exit 1, D02/D08/D09 전체 PASS·exit 0이다. D03은 clean prologue 추가 ID, 나머지는 기존 지정 ID와 순서·원문 JSON/sentinel이 모두 있어야 한다. after는 전 행과 exit 0이 필요하다. D08의 의도된 invalid_candidate_profile 오류 1건씩과 다른 lane의 진단 분모를 실제 manifest에 고정하고 SCRIPT ERROR·예상 밖 경고·timeout은 무효다. 특히 D08의 `retry.valid`는 새 sim 성공만 검사하므로 재시도 뒤 선택된 극한 규칙/roster가 실제 반영됐다고 주장하지 않는다. D01~04의 결과는 강제 종료 fixture이고 UI 버튼 signal은 물리 입력이 아니다.

이 축소는 D05 편성·D11 편성 거절 fallback·D12 POC·D13 invalid 변경 정책을 검사하지 않는다. 후보가 실제로 이 분기들과 오류 안내까지 바꾸므로 단지 D01~04/D08/D09만으로 그 동작을 완료 검증했다고 할 수 없다. 첫 PC 필수 범위로 제품 반영을 판단하려면 최소한 변경된 invalid 및 POC/편성 fallback의 실제 영향과 회귀를 별도 확인하거나 명시적 잔여 위험으로 독립 5-b에서 판정해야 한다. 결과 시각·실제 Windows 입력은 별개 미검증이다.

실행 전 현재 source/P03 소유와 기존 미적용 K6 hunk, HEAD/index, 고정 closure 및 현 디스크 여유를 다시 조사한다. 단일 격리 프로젝트의 순차 before/after와 새 캐시의 안전한 정리 여부, 시작/운행 공간 바닥·상한 및 cleanup 오류 보존을 구체적으로 동결한다. 8.306GB는 과거 표본이지 예약된 공간이 아니다. 기존 실패·원본·다른 사용자 파일은 보존한다. PC0 2/2와 여덟째 K6을 새 실행의 재시도로 취급하거나 리셋하지 않는다.
