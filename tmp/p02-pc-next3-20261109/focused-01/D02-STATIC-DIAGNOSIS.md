# D02 기준선 정적 진단

D02의 표준 난이도 제품 roster는 독립 오라클과 일치한다. 읽기 전용 Python JSON 비교에서 연합 6개와 조조 10개의 ID, 진영, 순서, 대기 틱, 시작 사기가 전부 일치했다. raw에서 실패한 항목은 roster.full과 roster.wait뿐이며 route.difficulty, profile.host, profile.rules 및 나머지 10개 항목은 통과했다. D01도 동일한 표준 roster를 보고했으므로 입문 선택에서 표준이 로드되는 기준선 문제는 별개로 관측됐다.

원인은 프로브의 비교 타입이다. BattleSim._spawn은 wait를 BattleRules.ticks의 int로, start_morale_bp도 int로 저장한다. 프로브 expected_roster는 JSON 오라클에서 wait_s만 제거한다. 실행 엔진과 같은 Godot commit ed1daf0bf의 JSON 숫자 토큰은 double이다. 배열 비교는 원소별 hash_compare를 호출하고 INT/FLOAT 차이를 값 비교 전에 거부한다. 따라서 roster.full의 사기 배열과 roster.wait의 중첩 [ID, 대기] 배열이 숫자값이 같아도 둘 다 거짓이다. 오라클과 동일한 JSON 숫자 경로를 거치는 AI 사전 비교는 통과했다.

- [Godot JSON 숫자 처리](https://github.com/godotengine/godot/blob/ed1daf0bf/core/io/json.cpp#L371-L377)
- [Godot 배열 비교](https://github.com/godotengine/godot/blob/ed1daf0bf/core/variant/array.cpp#L122-L149)
- [Godot Variant 타입 비교](https://github.com/godotengine/godot/blob/ed1daf0bf/core/variant/variant.cpp#L3038-L3049)

수정 제안은 프로브 expected_roster의 두 숫자 필드만 정규화하는 것이다. 원본 오라클의 wait_ticks 및 start_morale_bp 값이 정수 범위와 정수성을 만족하는지 확인한 뒤 기대 사본에 int를 넣는다. 실제 roster와 비교되는 ID·진영·순서·수치 및 AI 검증은 유지한다. 이 경로를 사용하는 D09와 향후 retry/fallback도 타입 차이를 공유한다. D01/D03/D04의 기대 실패 ID와 D02/D09의 기대 성공 조건은 그대로 검토한다. 이번 D02를 통과로 재분류하지 않는다.

기록 원문 SHA256

- D02 raw.json b47efb57676e6e0b03278468e04452f888ab28118aaf9de849f7350e1e90dd95
- D02 engine.log 66cf12f790f451aec8e411c66fdbf3a680c02453e93899dffa55da0f0ed33198
- D02 engine.os.tsv 7755fa4572fd78439fbbd79119844d990165daaafef4ba6802efa59b93b9ec55
- data-oracle-v2.json 688b5329e160050aa5e0e25416cb8ba800b2314c00c76059ea4d711c5127785b

D02는 sentinel 12개 판정 중 2개 실패와 엔진 exit 1, Job cleanup 0을 남겼다. 정적 진단만 수행했다.
