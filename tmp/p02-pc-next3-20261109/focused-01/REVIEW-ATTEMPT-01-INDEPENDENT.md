# 축소 난이도 실행 중단 독립 분석

판정: 승인된 단일 세트는 before D02에서 실패로 중단됐다. before import 및 D01만 runner가 완료 기록했고 D02 actual exit 1은 예상 exit 0과 달라 supervisor가 오류를 기록한 뒤 Job active 0으로 정리했다. candidate after, 이후 행 및 GUI는 시작하지 않았다. 기존 실패와 이 시도는 보존하며 재실행·수정·삭제는 하지 않았다.

D01은 예상한 profile.host/profile.rules/roster.full/roster.wait 네 red를 기록했다. D02는 12개 중 roster.full 및 roster.wait만 false, profile.host와 profile.rules·경로·결산 등 나머지 10개는 true다. SCRIPT ERROR는 D02 로그에 없다. 실패한 두 단언의 원시 실제 roster와 독립 JSON의 표준 기대 roster를 별도 비교하면 양측의 ID·진영·시작 사기·대기 tick 값과 순서는 모두 일치한다. 따라서 단순한 값 차이만으로 실제 제품 roster가 잘못됐다고 결론 낼 수 없다.

probe의 expected_roster와 roster_facts는 독립 JSON을 로드해 GDScript 배열/사전과 람다로 비교한다. 실제 런타임의 비교 피연산자·Variant 타입 및 변환 결과가 raw에 출력되지 않아 이 결과만으로 oracle 해석·비교 구현·숨은 타입 차이 중 어느 것이 원인인지 확정할 수 없다. 프로파일 데이터 JSON 자체의 기대 추출 오류나 실제 제품 문제도 추가 반례 전 전면 배제하지 않는다. 다음 계획은 동일 실행 데이터를 읽기 전용으로 확인하고 피연산자의 값·순서·타입을 독립 검증하는 소규모 진단을 먼저 정해야 한다. 예상 red를 임의 확대하거나 D02를 PASS로 바꾸지 않는다.

D02 raw SHA b47efb57676e6e0b03278468e04452f888ab28118aaf9de849f7350e1e90dd95, engine.log SHA 66cf12f790f451aec8e411c66fdbf3a680c02453e93899dffa55da0f0ed33198, OS TSV SHA 7755fa4572fd78439fbbd79119844d990165daaafef4ba6802efa59b93b9ec55. 이전 PC0 2/2, 여덟째 K6과 구분한다. 물리 입력·첫 PC·제품 후보 성공은 미검증이다.
