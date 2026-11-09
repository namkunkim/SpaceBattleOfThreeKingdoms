# Cn 독립 5b 및 보존 심사

판정: **마감 보류**. `attempt-02`의 개별 exit 기록은 정상/누락/승격/근거 누락 순서로 0/1/1/2이며 before/after stdout SHA-256은 둘 다 `8f08554ec1b7809f5f5351fb7d39a86608b0381c838c7fea116272f73c287836`이다. 그러나 같은 디렉터리 `result.json`은 `codes: [2,2,2,2], stable: false`라고 적는다. 개별 파일과 집계의 생성 경위와 실제 동일 실행의 관계가 해명되지 않아 실행 마감 근거로 수용하지 않는다. 재실행하지 않았다.

원문 확인: WorldMap은 legacy resolver를 시작·poll하고, 제한 worker는 복제 입력을 bind해 worker에서 owner를 만들고 close 후 결과를 반환한다. owner `_busy`와 worker 시작의 `busy`는 다른 검사이고 mutex는 취소 플래그를 보호한다. 제한된 정적 탐색 내 미발견은 자연 경쟁의 불가능성 증명이 아니다. 6/4 ID와 gate의 변이 분류는 확인했으나 gate는 문자열 anchor 존재만 검사하므로 전달 경로의 의미나 자연 경합의 부재를 증명하지 않는다. 비교 행의 공통 end 문구는 raw/legacy 쌍에도 replay close를 쓰므로 정확한 경로별 종료 설명으로 사용하기 어렵다.

첫 조사 시 전수 해시 및 전체 Git 전후 감사 부재는 RESULT에 명시되어 있으며 보존 증거 범위를 넘겨 무변경을 주장할 수 없다. attempt-01 실패 보존은 확인했다. attempt-02 집계 모순의 원본 생성 경위와 필요한 정정 기록을 확인한 뒤 별도 재심사한다. 기존 로그를 덮어쓰지 않는다.
