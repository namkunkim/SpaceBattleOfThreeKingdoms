# 난이도 격리 attempt-01 독립 결과

판정: 최초 실행 세트 1회 소진·실패. before import는 실제 root exit 0/Job cleanup 0이나 D01의 probe 전체가 line 441에서 정적 타입 추론 Parse Error로 로딩되지 않았다. 실제 root exit 1/cleanup 0은 기대한 난이도 기준선 실패가 아니며 실제 assertion·후보 및 GUI lane은 0이다. 물리 입력 미검증, PC0 2/2와 별도 K6 미사용은 그대로다.

오류 원문은 ok의 타입을 추론할 수 없다는 내용이며 physical_events의 Variant 필드에서 추론된 식이 원인 위치다. var ok: bool의 명시가 최소 후보이지만 다음 GDScript 파서 오류나 fixture 의미적 결함이 없는지 이 오류만으로 보장할 수 없다. probe 수정, 기대 경고·정확 ID 및 관련 입력 SHA를 새 명세로 동결하고 독립 심사 전 엔진을 재실행하지 않는다. 새 실행 예산은 최초 세트와 명시적으로 구분하여 심사하며 기존 실패/한도를 지우지 않는다. D01 engine.log SHA fc4c2a39a7ddcb33fc817b2e63bc44aa40aae657464f466952497b763f61eeb9, OS TSV SHA c51a50d8ac5ad482988c924000eb85afe693be1fb02fb77974437f449835d7b7이다.

현재 source closure drift 0, 자유 공간 약 2.246GB이며 2.9GB 시작 바닥 아래다. 격리 attempt-01/project/.godot는 1336파일/334714530 bytes, inventory SHA cca0ebe29a36a90de463b4a98ed4c20faf7f5045ae83e8e2814a79b9512661e5로 이것만 삭제하면 시작 바닥에 못 미친다. 격리 attempt-01/project 전체는 2827파일/1004460742 bytes, inventory SHA 85f91da7912a4299b8cc7d94c9550447bcfd4428f8618b872ae1d465478e632b다. 두 SHA 모두 상대 POSIX 경로로 정렬한 [경로,크기,파일 SHA] compact UTF-8 JSON의 SHA다.

사용자가 디스크 정리를 요청한 범위에서 project 전체는 실패한 격리 복제본의 정리 후보이지만 원문 로그·승인/manifest·입력 source·cache inventory와 held 여부를 먼저 보존하고, 정규 절대 경로 및 reparse/활성 소유 Job이 없음을 재검사한 후에만 별도 정리한다. 실제 삭제는 이 심사에서 하지 않았다. 원본 project/.godot나 다른 시도의 증거를 대상으로 삼지 않는다.
