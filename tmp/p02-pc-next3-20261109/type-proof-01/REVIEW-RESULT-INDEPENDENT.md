# D02 실제 Variant 타입 진단 독립 결과

판정: 한정된 타입 진단 수용. import actual exit 0, D02 actual exit 1 및 두 Job active 0·root signal 0, import에서 보유한 두 자식 signal 0을 원문에서 확인했다. D02는 지정 12개 중 roster.full/wait 두 실패를 그대로 남겼으며 진단 raw SHA는 1ce548a60b8c8831cb5b4ed720a69e6cc95dcb8999e129da7adad894f89ee7a1이다.

실제와 기대 양측 6개 아군·10개 적군의 ID·진영·대기·시작 사기 값과 순서는 독립 JSON과 일치한다. 원문에서 각 행의 ID/진영은 String이고 실제 wait/morale은 모두 int, 기대는 모두 float다. 해당 엔진 소스의 배열 hash_compare가 서로 다른 Variant 타입을 거절하는 근거와 함께 D02의 두 실패를 설명한다. 이 관측은 원래 focused D02의 별도 실행 결과를 소급 PASS로 바꾸지 않는다.

이번 실행은 정규화된 probe 또는 after 제품 후보를 실행하지 않았다. 이 진단만으로 제품 난이도 수정, 실제 GUI 입력, 자연 종료 또는 P02 전체를 검증할 수 없다. PC0 2/2와 별도 K6 기록은 유지한다.
